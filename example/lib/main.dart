import 'package:flutter/material.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _tabTitles = [
    'Tab 1',
    'Tab 2',
    'Tab 3',
    'Tab 4',
    'Tab 5',
    'Tab 6',
    'Tab 7',
    'Tab 8',
  ];

  final PivotController _pivotController =
      PivotController(length: _tabTitles.length);
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Pivot -> PageView
    _pivotController.addListener(_syncPageToPivot);
  }

  @override
  void dispose() {
    _pivotController.removeListener(_syncPageToPivot);
    _pivotController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _syncPageToPivot() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page?.round();
    if (page != _pivotController.index) {
      _pageController.animateToPage(
        _pivotController.index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastLinearToSlowEaseIn,
      );
    }
  }

  // PageView -> Pivot
  void _onPageChanged(int value) {
    if (_pivotController.index != value) {
      _pivotController.animateTo(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: WpPivot(
        controller: _pivotController,
        backgroundColor: Colors.black,
        fontSize: 36.2,
        fontWeight: FontWeight.w400,
        selectedTabColor: Colors.white,
        unselectedTabColor: Colors.white38,
        tabTitles: _tabTitles,
        title: "Title",
        titleColor: Colors.white,
        titleFontSize: 14,
        titleFontWeight: FontWeight.bold,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: <Widget>[
            for (final title in _tabTitles)
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'This is ${title.toLowerCase()} page',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
