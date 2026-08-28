import 'package:flutter/material.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';
import 'baseline_scene.dart' show pageNames, pageColors;

class ImprovedScene extends StatelessWidget {
  const ImprovedScene({super.key});

  @override
  Widget build(BuildContext context) => WpPivotView(
        title: 'PIVOT RESEARCH',
        tabTitles: pageNames,
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 6, color: pageColors[i]),
                    const SizedBox(height: 24),
                    Text('${pageNames[i]} page',
                        style: const TextStyle(
                            fontSize: 32, height: 1.3301, color: Colors.white)),
                    const SizedBox(height: 12),
                    const Text('Swipe to explore',
                        style: TextStyle(
                            fontSize: 24,
                            height: 1.3301,
                            color: Color(0xffa6a6a6))),
                    const SizedBox(height: 32),
                    Container(
                        key: ValueKey('marker-$i'),
                        width: 64,
                        height: 64,
                        color: pageColors[i]),
                  ]),
            )
        ],
      );
}
