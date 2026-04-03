import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

// 로컬 알림 플러그인 전역 초기화
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  // 플러터 엔진과 위젯 바인딩 초기화 보장 (비동기 작업을 위해 필수)
  WidgetsFlutterBinding.ensureInitialized();

  // 타임존 및 알림 설정 초기화
  tz.initializeTimeZones();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DotLive*',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true, // Material 3 최신 디자인 적용
      ),
      home: const MyHomePage(title: 'DotLive*'),
    );
  }
}

// 아이돌 멤버 데이터 모델
class IdolMember {
  final String name;
  final int birthMonth;
  final int birthDay;
  final String image;

  IdolMember({
    required this.name,
    required this.birthMonth,
    required this.birthDay,
    required this.image,
  });

  // JSON 파싱용 팩토리 생성자
  factory IdolMember.fromJson(Map<String, dynamic> json) {
    return IdolMember(
      name: json['name'],
      birthMonth: json['month'],
      birthDay: json['day'],
      image: json['image'],
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> birthWeekday = ['월', '화', '수', '목', '금', '토', '일'];

  List<IdolMember> nijidongList = [];
  bool isLoading = true; // JSON 로딩 상태 관리

  late PageController _pageController;
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  final ValueNotifier<DateTime> _currentTimeNotifier = ValueNotifier<DateTime>(DateTime.now());
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadMembersData(); // 비동기로 데이터 불러오기 시작
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _currentPageNotifier.dispose();
    _currentTimeNotifier.dispose();
    super.dispose();
  }

  // JSON 파일에서 데이터를 읽어오고 초기 설정을 진행하는 함수
  Future<void> _loadMembersData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/members.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);

      nijidongList = jsonData.map((data) => IdolMember.fromJson(data)).toList();

      // 가장 가까운 생일 인덱스를 찾아 첫 화면으로 설정
      int nearestIndex = _getNearestBirthdayIndex();
      _pageController = PageController(initialPage: nearestIndex);
      _currentPageNotifier.value = nearestIndex;

      setState(() {
        isLoading = false;
      });

      // 데이터 로드 완료 후 백그라운드 작업 시작
      _startTimer();
      _scheduleBirthdayNotifications();
      if (nijidongList.isNotEmpty) {
        _updateHomeWidget(nijidongList[nearestIndex]);
      }
    } catch (e) {
      debugPrint('데이터를 불러오는데 실패했습니다: $e');
    }
  }

  // 다가오는 가장 가까운 생일의 인덱스를 계산하는 함수
  int _getNearestBirthdayIndex() {
    if (nijidongList.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int nearestIndex = 0;
    int minDays = 9999;

    for (int i = 0; i < nijidongList.length; i++) {
      final member = nijidongList[i];
      DateTime nextBirthday = DateTime(now.year, member.birthMonth, member.birthDay);

      // 이미 생일이 지났다면 내년으로 계산
      if (nextBirthday.isBefore(today)) {
        nextBirthday = DateTime(now.year + 1, member.birthMonth, member.birthDay);
      }

      final difference = nextBirthday.difference(today).inDays;

      if (difference < minDays) {
        minDays = difference;
        nearestIndex = i;
      }
    }
    return nearestIndex;
  }

  // 1초마다 현재 시간을 갱신하는 타이머
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTimeNotifier.value = DateTime.now();
    });
  }

  // D-Day 남은 시간을 계산하여 문자열로 반환하는 함수
  String _getDDayString(IdolMember member, DateTime now) {
    var birthday = DateTime(now.year, member.birthMonth, member.birthDay);
    var difference = now.difference(birthday);

    if (difference.inSeconds >= 0 && difference.inSeconds < 86400) {
      return '생일이에요!\n축하합니다!';
    }

    if (difference.inSeconds >= 86400) {
      birthday = DateTime(now.year + 1, member.birthMonth, member.birthDay);
      difference = now.difference(birthday);
    }

    int diffDay = difference.inDays.abs();
    int diffHour = 23 - (now.hour);
    int diffMinute = 59 - (now.minute);
    int diffSecond = 59 - (now.second);

    return '${diffDay}일 ${diffHour.toString().padLeft(2, '0')}:${diffMinute.toString().padLeft(2, '0')}:${diffSecond.toString().padLeft(2, '0')}';
  }

  // 홈 위젯 데이터 갱신 함수
  Future<void> _updateHomeWidget(IdolMember member) async {
    final now = DateTime.now();
    final dDayString = _getDDayString(member, now).replaceAll('\n', ' ');

    if (!kIsWeb) {
      try {
        await HomeWidget.saveWidgetData<String>('member_name', member.name);
        await HomeWidget.saveWidgetData<String>('d_day_text', dDayString);

        await HomeWidget.updateWidget(
          androidName: 'DotgasakiWidgetProvider',
          iOSName: 'DotgasakiWidget',
        );
      } on Exception catch (e) {
        debugPrint('위젯 데이터 저장 실패: $e');
      }
    }
  }

  // 매년 반복되는 생일 축하 푸시 알림 예약 함수
  Future<void> _scheduleBirthdayNotifications() async {
    // 웹 환경에서는 로컬 네이티브 푸시를 스케줄링하지 않고 넘깁니다. (웹 빌드 충돌 방지)
    if (kIsWeb) return;

    for (int i = 0; i < nijidongList.length; i++) {
      final member = nijidongList[i];
      final now = tz.TZDateTime.now(tz.local);

      var scheduledDate = tz.TZDateTime(tz.local, now.year, member.birthMonth, member.birthDay, 0, 0);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = tz.TZDateTime(tz.local, now.year + 1, member.birthMonth, member.birthDay, 0, 0);
      }

      // v21 최신 문법에 맞춰 모든 인자를 Named Parameter로 변경하고,
      // 삭제된 uiLocalNotificationDateInterpretation 파라미터를 제거했습니다.
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: i,
        title: '오늘은 생일입니다!',
        body: '니지동의 ${member.name} 멤버의 생일을 축하해주세요! 🎉',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'birthday_channel', 'Birthday Notifications',
            importance: Importance.max, priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime, // 매년 지정된 날짜/시간에 반복
      );
    }
  }

  // 하단 점(Dot) 인디케이터 위젯
  Widget _buildCircleIndicator() {
    return ValueListenableBuilder<int>(
      valueListenable: _currentPageNotifier,
      builder: (context, currentPage, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(nijidongList.length + 1, (index) {
            bool isSelected = currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: isSelected ? 12.0 : 8.0,
              height: isSelected ? 12.0 : 8.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.redAccent : Colors.white70,
              ),
            );
          }),
        );
      },
    );
  }

  // 개발자 프로필 페이지 위젯
  Widget _buildProfilePage() {
    return Container(
      color: const Color.fromARGB(255, 23, 63, 123),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset('assets/images/nijidong_yuu1@2x.png'),
          const Text(
            'tomriddle7',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 45),
          ),
          InkWell(
            onTap: () async {
              final url = Uri.parse('https://x.com/tomriddle7');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text(
              '@tomriddle7',
              style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.w700, fontSize: 32),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 데이터 로딩 중 화면
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.lightBlueAccent,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _pageController,
            itemCount: nijidongList.length + 1,
            onPageChanged: (int index) {
              _currentPageNotifier.value = index;
              if (index < nijidongList.length) {
                _updateHomeWidget(nijidongList[index]);
              }
            },
            itemBuilder: (context, index) {
              if (index == nijidongList.length) {
                return _buildProfilePage();
              }

              final member = nijidongList[index];
              final dummyDate = DateTime(2024, member.birthMonth, member.birthDay);
              final weekdayStr = birthWeekday[dummyDate.weekday - 1];

              return Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(
                    member.image,
                    fit: BoxFit.cover,
                    color: const Color.fromRGBO(255, 255, 255, 0.5),
                    colorBlendMode: BlendMode.modulate,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(member.image),
                          Text(
                            '${member.birthMonth}월\n${member.birthDay}일\n($weekdayStr)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 45),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      // 남은 시간 텍스트만 1초마다 부분 리렌더링
                      ValueListenableBuilder<DateTime>(
                        valueListenable: _currentTimeNotifier,
                        builder: (context, now, child) {
                          return Text(
                            _getDDayString(member, now),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 48),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 50.0,
            left: 0,
            right: 0,
            child: _buildCircleIndicator(),
          ),
        ],
      ),
    );
  }
}
