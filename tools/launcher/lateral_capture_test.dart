// Deterministic replay adapter for WpSplitSurfaceView.
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
  const replayPath = String.fromEnvironment('REPLAY');
  const outputPath = String.fromEnvironment('OUTPUT');

  testWidgets('replay native lateral input through package components',
      (tester) async {
    expect(replayPath, isNotEmpty);
    expect(outputPath, isNotEmpty);
    final replay =
        jsonDecode(File(replayPath).readAsStringSync()) as Map<String, dynamic>;
    expect(replay['viewport'], <int>[480, 800]);
    final output = Directory(outputPath);
    if (output.existsSync()) throw StateError('Use a fresh output directory.');
    output.createSync(recursive: true);
    Directory('$outputPath/frames').createSync();

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
    final initialSurface = replay['initial_surface'] as int;
    final expectedSurface = replay['expected_surface'] as int;
    final controller = PageController(initialPage: initialSurface);
    addTearDown(controller.dispose);
    final changes = <({double tMs, int surface})>[];
    var replayClockMs = 0.0;
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            fontFamily: wpPivotFontFamily,
            platform: TargetPlatform.android,
          ),
          home: WpPhoneTheme(
            data: const WpPhoneThemeData.dark(),
            child: WpSplitSurfaceView(
              controller: controller,
              onSurfaceChanged: (surface) {
                changes.add((tMs: replayClockMs, surface: surface));
              },
              first: const _StartFixture(),
              second: const _AppListFixture(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final events =
        (replay['events'] as List<dynamic>).cast<Map<String, dynamic>>();
    final steps = <({int us, Map<String, dynamic>? event, bool capture})>[];
    for (final event in events) {
      steps.add((
        us: ((event['t_ms'] as num) * 1000).round(),
        event: event,
        capture: false,
      ));
    }
    final end = ((replay['end_ms'] as num) * 1000).round();
    for (var frame = 0; (frame * 1000000 / 60).round() <= end; frame++) {
      steps.add((
        us: (frame * 1000000 / 60).round(),
        event: null,
        capture: true,
      ));
    }
    steps.sort((a, b) {
      final time = a.us.compareTo(b.us);
      return time != 0 ? time : (a.capture ? 1 : -1);
    });

    var previous = 0;
    var number = 0;
    TestGesture? gesture;
    final frames = StringBuffer(
      'frame,t_ms,first_left,second_left,page\n',
    );
    for (final step in steps) {
      await tester.pump(Duration(microseconds: step.us - previous));
      previous = step.us;
      replayClockMs = step.us / 1000;
      final event = step.event;
      if (event != null) {
        final point = Offset(
          (event['x'] as num).toDouble(),
          (event['y'] as num).toDouble(),
        );
        final time = Duration(microseconds: step.us);
        switch (event['event']) {
          case 'down':
            gesture = await tester.createGesture();
            await gesture.down(point, timeStamp: time);
          case 'move':
            await gesture!.moveTo(point, timeStamp: time);
          case 'up':
            await gesture!.up(timeStamp: time);
            gesture = null;
          default:
            throw StateError('Unsupported pointer event ${event['event']}');
        }
      }
      if (step.capture) {
        final offset = controller.position.pixels;
        frames.writeln(
          '$number,${step.us / 1000},${-offset},${480 - offset},${controller.page}',
        );
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$outputPath/frames/${number.toString().padLeft(6, '0')}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
        number++;
      }
      expect(tester.takeException(), isNull);
    }
    expect(gesture, isNull);
    expect(controller.page, closeTo(expectedSurface, 0.001));

    File('$outputPath/frames.csv').writeAsStringSync(frames.toString());
    File('$outputPath/replay.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(replay),
    );
    File('$outputPath/changes.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object>{
        'changes': <Map<String, Object>>[
          for (final change in changes)
            <String, Object>{'t_ms': change.tMs, 'surface': change.surface},
        ],
      }),
    );
    File('$outputPath/manifest.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object>{
        'schema_version': 1,
        'adapter_id': 'wp-split-surface-flutter-replay-v1',
        'source': 'flutter-test-engine',
        'component': 'WpSplitSurfaceView with WpTileGrid and WpAppListView',
        'native_trial': replay['source_trial'] as String,
        'viewport': <int>[480, 800],
        'device_pixel_ratio': 1,
        'platform': 'android physics in deterministic Flutter test engine',
        'frame_count': number,
        'sample_fps': 60,
        'clock': 'deterministic tester pump; not wall-clock performance',
        'input': replay['timestamp_semantics'] as String,
        'font': 'Bundled OFL Selawik; not native Segoe WP',
        'initial_surface': initialSurface,
        'expected_surface': expectedSurface,
        'claims': <String>[
          'delivered pointer replay response',
          'surface separation and release outcome',
        ],
        'limits': <String>[
          'Not live Android runtime or physical touch-latency evidence.',
          'Fixture icons and labels are non-Microsoft placeholders.',
        ],
      }),
    );
  });
}

class _StartFixture extends StatelessWidget {
  const _StartFixture();

  static const accent = Color(0xff3e65ff);

  @override
  Widget build(BuildContext context) {
    WpTilePlacement tile(
      String label,
      int row,
      int column, {
      int rowSpan = 1,
      int columnSpan = 1,
      Color color = accent,
    }) {
      return WpTilePlacement(
        row: row,
        column: column,
        rowSpan: rowSpan,
        columnSpan: columnSpan,
        child: WpTile(
          label: label,
          color: color,
          child: const Center(
            child: SizedBox.square(
              dimension: 28,
              child: ColoredBox(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 56,
            width: 480,
            child: WpTileGrid(
              placements: <WpTilePlacement>[
                tile('Phone', 0, 0, rowSpan: 2, columnSpan: 2),
                tile('Messaging', 0, 2),
                tile('Browser', 0, 3),
                tile('Mail', 1, 2),
                tile('Store', 1, 3),
                tile('People', 2, 0, rowSpan: 2, columnSpan: 2),
                tile('Music', 2, 2, color: const Color(0xff107c10)),
                tile('Games', 2, 3, color: const Color(0xff107c10)),
                tile('Office', 3, 2, color: const Color(0xffeb3c00)),
                tile('Notes', 3, 3, color: const Color(0xff80397b)),
                tile('Calendar', 4, 0, rowSpan: 2, columnSpan: 2),
                tile("Kid's Corner", 4, 2, rowSpan: 2, columnSpan: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppListFixture extends StatelessWidget {
  const _AppListFixture();

  @override
  Widget build(BuildContext context) {
    Widget row(String label) => WpAppListRow(
          icon: const Center(
            child: SizedBox.square(
              dimension: 28,
              child: ColoredBox(color: Colors.white),
            ),
          ),
          label: label,
          onTap: () {},
        );
    Widget header(String letter) =>
        WpAppListHeader(letter: letter, onTap: () {});
    return ColoredBox(
      color: Colors.black,
      child: WpAppListView(
        children: <Widget>[
          header('a'),
          row('Alarms'),
          header('b'),
          row('Battery Saver'),
          header('c'),
          row('Calculator'),
          row('Calendar'),
          row('Camera'),
          row('Cortana'),
          header('d'),
        ],
      ),
    );
  }
}
