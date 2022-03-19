import 'package:flutter/material.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'Segoe',
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey<WpPivotState> globalKey = GlobalKey();
  PageController pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: WpPivot(
          key: globalKey,
          backgroundColor: Colors.black,
          fontSize: 36.2,
          fontWeight: FontWeight.w400,
          selectedTabColor: Colors.white,
          unselectedTabColor: Colors.white38,
          tabTitles: [
            "Tab 1",
            "Tab 2",
            "Tab 3",
            "Tab 4",
            "Tab 5",
            "Tab 6",
            "Tab 7",
            "Tab 8",
          ],
          title: "Title",
          titleColor: Colors.white,
          titleFontSize: 14,
          titleFontWeight: FontWeight.bold,
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: PageView(
            controller: pageController,
            onPageChanged: (value) =>
                globalKey.currentState?.handlePagechange(value),
            children: <Widget>[
              Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "This is first page",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  )),
              Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "This is second page",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  )),
              Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "This is third page",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  )),
              Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "This is fourth page",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  )),
              Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "This is fifth page",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  )),
              Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "This is sixth page",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  )),
              Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "This is seventh page",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  )),
              Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "This is eigth page",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  )),
            ],
          ),
        ));
  }
}
