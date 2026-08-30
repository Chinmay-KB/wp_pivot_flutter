// Deterministic pose sweep for the package staggered scene primitive.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';

void main() {
  const outputPath = String.fromEnvironment('OUTPUT');
  testWidgets('render staggered scene pose sweep', (tester) async {
    expect(outputPath, isNotEmpty);
    final output = Directory(outputPath);
    if (output.existsSync()) throw StateError('Use a fresh output directory.');
    output.createSync(recursive: true);

    final loader = FontLoader(wpPivotFontFamily);
    for (final name in <String>['selawksl.ttf', 'selawk.ttf', 'selawksb.ttf']) {
      loader.addFont(Future<ByteData>.value(
        ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync()),
      ));
    }
    await loader.load();
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    final frames = <String>[];
    for (final direction in WpSceneTransitionDirection.values) {
      for (final progress in <double>[0.25, 0.4, 0.55, 0.7, 0.85]) {
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                brightness: Brightness.dark,
                scaffoldBackgroundColor: Colors.black,
                fontFamily: wpPivotFontFamily,
              ),
              home: WpPhoneTheme(
                data: const WpPhoneThemeData.dark(),
                child: _Scene(progress: progress, direction: direction),
              ),
            ),
          ),
        );
        await tester.pump();
        final name = '${direction.name}-${(progress * 100).round()}.png';
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$outputPath/$name')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
        frames.add(name);
      }
    }
    File('$outputPath/manifest.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object>{
        'schema_version': 1,
        'adapter_id': 'wp-staggered-scene-pose-sweep-v1',
        'source': 'deterministic Flutter widget render',
        'resolution': <int>[480, 800],
        'frames': frames,
        'claims': <String>[
          'actual package transform pose sweep for visual inspection',
        ],
        'limits': <String>[
          'Pose sweep is not a runtime timing or physical latency claim.',
          'Native host capture timing does not qualify an exact default curve.',
          'Fixture icons are non-Microsoft placeholders.',
        ],
      }),
    );
  });
}

class _Scene extends StatelessWidget {
  const _Scene({required this.progress, required this.direction});

  final double progress;
  final WpSceneTransitionDirection direction;

  @override
  Widget build(BuildContext context) {
    final specs = <_TileSpec>[
      const _TileSpec('Phone', 0, 0, rowSpan: 2, columnSpan: 2),
      const _TileSpec('Messaging', 0, 2),
      const _TileSpec('Browser', 0, 3),
      const _TileSpec('Mail', 1, 2),
      const _TileSpec('Store', 1, 3),
      const _TileSpec('People', 2, 0, rowSpan: 2, columnSpan: 2),
      const _TileSpec('Music', 2, 2, color: Color(0xff107c10)),
      const _TileSpec('Games', 2, 3, color: Color(0xff107c10)),
      const _TileSpec('Office', 3, 2, color: Color(0xffeb3c00)),
      const _TileSpec('Notes', 3, 3, color: Color(0xff80397b)),
      const _TileSpec('Calendar', 4, 0, rowSpan: 2, columnSpan: 2),
      const _TileSpec("Kid's Corner", 4, 2, rowSpan: 2, columnSpan: 2),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned(
            top: 56,
            width: 480,
            child: WpTileGrid(
              placements: <WpTilePlacement>[
                for (final spec in specs)
                  WpTilePlacement(
                    row: spec.row,
                    column: spec.column,
                    rowSpan: spec.rowSpan,
                    columnSpan: spec.columnSpan,
                    child: WpStaggeredSceneTransition(
                      animation: AlwaysStoppedAnimation<double>(progress),
                      direction: direction,
                      order: WpStaggeredSceneGeometry.gridExitOrder(
                        column: spec.column,
                        columnSpan: spec.columnSpan,
                        columns: 4,
                        row: spec.row,
                      ),
                      maxOrder: 4,
                      entryOrder: WpStaggeredSceneGeometry.gridEntryOrder(
                        column: spec.column,
                        columnSpan: spec.columnSpan,
                        columns: 4,
                        row: spec.row,
                      ),
                      maxEntryOrder: 5,
                      child: WpTile(
                        label: spec.label,
                        color: spec.color,
                        child: const Center(
                          child: SizedBox.square(
                            dimension: 28,
                            child: ColoredBox(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TileSpec {
  const _TileSpec(
    this.label,
    this.row,
    this.column, {
    this.rowSpan = 1,
    this.columnSpan = 1,
    this.color = const Color(0xff3e65ff),
  });

  final String label;
  final int row;
  final int column;
  final int rowSpan;
  final int columnSpan;
  final Color color;
}
