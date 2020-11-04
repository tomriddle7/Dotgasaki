import 'package:flutter/material.dart';
import 'dart:async';
import 'package:page_view_indicators/page_view_indicators.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DotLive*',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'DotLive*'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer _timer;

  List<String> diffBirth = [];

  final _pageController = PageController();
  final _currentPageNotifier = ValueNotifier<int>(0);

  var nijidongList = [
    {
      'name': 'Nakasu Kasumi',
      'birthM': 1,
      'birthD': 23,
      'image': 'assets/nijidong_kasumi1@2x.png'
    },
    {
      'name': 'Emma Berde',
      'birthM': 2,
      'birthD': 5,
      'image': 'assets/nijidong_emma1@2x.png'
    },
    {
      'name': 'Uehara Ayumu',
      'birthM': 3,
      'birthD': 1,
      'image': 'assets/nijidong_ayumu1@2x.png'
    },
    {
      'name': 'Osaka Shizuku',
      'birthM': 4,
      'birthD': 3,
      'image': 'assets/nijidong_shizuku1@2x.png'
    },
    {
      'name': 'Miyashita Ai',
      'birthM': 5,
      'birthD': 30,
      'image': 'assets/nijidong_ai1@2x.png'
    },
    {
      'name': 'Asaka Karin',
      'birthM': 6,
      'birthD': 29,
      'image': 'assets/nijidong_karin1@2x.png'
    },
    {
      'name': 'Yuuki Setsuna',
      'birthM': 8,
      'birthD': 8,
      'image': 'assets/nijidong_setsuna1@2x.png'
    },
    {
      'name': 'Mifune Shioriko',
      'birthM': 10,
      'birthD': 5,
      'image': 'assets/nijidong_shioriko1@2x.png'
    },
    {
      'name': 'Tennoji Rina',
      'birthM': 11,
      'birthD': 13,
      'image': 'assets/nijidong_rina1@2x.png'
    },
    {
      'name': 'Konoe Kanata',
      'birthM': 12,
      'birthD': 16,
      'image': 'assets/nijidong_kanata1@2x.png'
    }
  ];

  void BetweenDate() {
    diffBirth = [];
    var tempString = '';
    for (int i = 0; i < nijidongList.length; i++) {
      final year = DateTime.now().year;
      final date2 = DateTime.now();
      var birthday = DateTime(year, nijidongList[i]['birthM'], nijidongList[i]['birthD']);
      var difference = date2.difference(birthday);
      var diffDay = difference.inDays;
      var diffHour = difference.inHours % 24 == 0 ? 0 : 24 - (difference.inHours % 24);
      var diffMinute = difference.inMinutes % 60 == 0 ? 0 : 60 - (difference.inMinutes % 60);
      var diffSecond = difference.inSeconds % 60 == 0 ? 0 : 60 - (difference.inSeconds % 60);
      if (difference.inHours <= 24 && difference.inHours >= 0) {
        tempString = '생일이에요!\n축하합니다!';
      }
      else if (difference.inHours < 24) {
        diffDay *= -1;

        tempString = diffDay.toString() + '일 ' + diffHour.toString().padLeft(2, '0') + ':' + diffMinute.toString().padLeft(2, '0') + ':' + diffSecond.toString().padLeft(2, '0');
      }
      else if (difference.inHours > 0) {
        birthday = DateTime(year + 1, nijidongList[i]['birthM'], nijidongList[i]['birthD']);
        difference = date2.difference(birthday);
        diffDay = difference.inDays * -1;
        diffHour = difference.inHours % 24 == 0 ? 0 : 24 - (difference.inHours % 24);
        diffMinute = difference.inMinutes % 60 == 0 ? 0 : 60 - (difference.inMinutes % 60);
        diffSecond = difference.inSeconds % 60 == 0 ? 0 : 60 - (difference.inSeconds % 60);

        tempString = diffDay.toString() + '일 ' + diffHour.toString().padLeft(2, '0') + ':' + diffMinute.toString().padLeft(2, '0') + ':' + diffSecond.toString().padLeft(2, '0');
      }
      setState(() {
        diffBirth.add(tempString);
      });
    }
  }

  @override
  initState() {
    super.initState();
    BetweenDate();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      BetweenDate();
    });
  }

  List<Center> WidgetList() {
    List<Center> res = [];
    for (int i = 0; i < nijidongList.length; i++) {
      Center box = Center(
          child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Image.asset(
                    nijidongList[i]['image'],
                    width: 1000,
                    height: 1000,
                    fit:BoxFit.cover,
                    color: Color.fromRGBO(255, 255, 255, 0.5),
                    colorBlendMode: BlendMode.modulate
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Image.asset(
                            nijidongList[i]['image']
                        ),
                        Text(
                          nijidongList[i]['birthM'].toString() + '월\n' + nijidongList[i]['birthD'].toString() + '일',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 48,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      diffBirth[i],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 48,
                      ),
                    ),
                  ],
                )
              ]
          )
      );
      res.add(box);
    }
    return res;
  }

  _buildCircleIndicator() {
    return Positioned(
      left: 0.0,
      right: 0.0,
      bottom: 50.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CirclePageIndicator(
          dotColor: Colors.white70,
          selectedDotColor: Colors.redAccent,
          itemCount: nijidongList.length,
          currentPageNotifier: _currentPageNotifier,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Stack(
          children: <Widget>[
            PageView(
              children: WidgetList(),
              onPageChanged: (int index) {
                _currentPageNotifier.value = index;
              },
            ),
            _buildCircleIndicator(),
          ],
        ),
      ),
    );
  }
}
