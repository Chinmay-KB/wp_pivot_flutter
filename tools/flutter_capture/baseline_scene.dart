// Frozen baseline adapter for the unmodified 2.0.0 widget + example controller
// wiring. Only titles/content, viewport and locally loaded font are standardized
// for this study. Keep this adapter when the production widget improves.
import 'package:flutter/material.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';

const pageNames = ['first', 'second', 'third', 'fourth'];
const pageColors = [
  Color(0xff1ba1e2),
  Color(0xff60a917),
  Color(0xfff09609),
  Color(0xffa200ff)
];

class BaselineScene extends StatefulWidget {
  const BaselineScene({super.key});

  @override
  State<BaselineScene> createState() => _BaselineSceneState();
}

class _BaselineSceneState extends State<BaselineScene> {
  final pivot = PivotController(length: 4);
  final pages = PageController();

  @override
  void initState() {
    super.initState();
    pivot.addListener(sync);
  }

  void sync() {
    if (pages.hasClients && pages.page?.round() != pivot.index) {
      pages.animateToPage(pivot.index,
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastLinearToSlowEaseIn);
    }
  }

  @override
  void dispose() {
    pivot.removeListener(sync);
    pivot.dispose();
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: WpPivot(
          controller: pivot,
          tabTitles: pageNames,
          title: 'PIVOT RESEARCH',
          fontSize: 36.2,
          fontWeight: FontWeight.w400,
          unselectedTabColor: Colors.white38,
          titleFontSize: 14,
          titleFontWeight: FontWeight.bold,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: PageView(
            controller: pages,
            onPageChanged: pivot.animateTo,
            children: [for (var i = 0; i < 4; i++) ReferenceContent(index: i)],
          ),
        ),
      );
}

class ReferenceContent extends StatelessWidget {
  const ReferenceContent({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 6, color: pageColors[index]),
          const SizedBox(height: 24),
          Text('${pageNames[index]} page',
              style: const TextStyle(fontSize: 32, color: Colors.white)),
          const SizedBox(height: 12),
          const Text('Swipe to explore',
              style: TextStyle(fontSize: 24, color: Color(0xffa6a6a6))),
          const SizedBox(height: 32),
          Container(
              key: ValueKey('marker-$index'),
              width: 64,
              height: 64,
              color: pageColors[index]),
        ],
      );
}
