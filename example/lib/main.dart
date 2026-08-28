import 'package:flutter/material.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';

void main() => runApp(const PivotExample());

class PivotExample extends StatelessWidget {
  const PivotExample({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Pivot research',
        theme: ThemeData(
            fontFamily: wpPivotFontFamily, brightness: Brightness.dark),
        home: const ColoredBox(
          color: Colors.black,
          child: Center(
            child: SizedBox(width: 480, child: ResearchPivot()),
          ),
        ),
      );
}

class ResearchPivot extends StatelessWidget {
  const ResearchPivot({super.key, this.onChanged});
  final ValueChanged<int>? onChanged;
  static const names = ['first', 'second', 'third', 'fourth'];
  static const colors = [
    Color(0xff1ba1e2),
    Color(0xff60a917),
    Color(0xfff09609),
    Color(0xffa200ff)
  ];

  @override
  Widget build(BuildContext context) => WpPivotView(
        title: 'PIVOT RESEARCH',
        onChanged: onChanged,
        tabTitles: names,
        children: [
          for (var i = 0; i < names.length; i++)
            LayoutBuilder(builder: (context, constraints) {
              final scale = constraints.maxWidth / 480;
              return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 6 * scale, color: colors[i]),
                        SizedBox(height: 24 * scale),
                        Text('${names[i]} page',
                            style: TextStyle(
                                fontSize: 32 * scale,
                                height: 1.3301,
                                color: Colors.white)),
                        SizedBox(height: 12 * scale),
                        Text('Swipe to explore',
                            style: TextStyle(
                                fontSize: 24 * scale,
                                height: 1.3301,
                                color: const Color(0xffa6a6a6))),
                        SizedBox(height: 32 * scale),
                        Container(
                            width: 64 * scale,
                            height: 64 * scale,
                            color: colors[i]),
                      ]));
            })
        ],
      );
}
