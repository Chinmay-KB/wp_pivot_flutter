// Opt-in artifact generator, not part of the normal unit-test suite.
// Renders the actual Flutter widget tree using a deterministic test clock.
// This is neither a desktop screen recording nor a GPU performance benchmark.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';
import 'baseline_scene.dart';
import 'improved_scene.dart';

void main() {
  const replayPath = String.fromEnvironment('REPLAY');
  const outputPath = String.fromEnvironment('OUTPUT');
  const regularPath = String.fromEnvironment('FONT_REGULAR');
  const lightPath = String.fromEnvironment('FONT_LIGHT');
  const boldPath = String.fromEnvironment('FONT_BOLD');
  const variant = String.fromEnvironment('VARIANT', defaultValue: 'baseline');

  testWidgets('render measured guest input through the baseline widget',
      (tester) async {
    expect(replayPath, isNotEmpty);
    expect(outputPath, isNotEmpty);
    final replay =
        jsonDecode(File(replayPath).readAsStringSync()) as Map<String, dynamic>;
    final output = Directory(outputPath);
    if (output.existsSync()) {
      throw StateError('Choose a fresh output directory.');
    }
    output.createSync(recursive: true);
    Directory('$outputPath/frames').createSync();
    final fontPaths = variant == 'improved'
        ? [
            'assets/fonts/selawksl.ttf',
            'assets/fonts/selawk.ttf',
            'assets/fonts/selawksb.ttf'
          ]
        : [regularPath, lightPath, boldPath];
    final loader = FontLoader(
        variant == 'improved' ? wpPivotFontFamily : 'EvidenceSegoeUI');
    for (final path in fontPaths) {
      loader.addFont(
          Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
    }
    await loader.load();
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            fontFamily:
                variant == 'improved' ? wpPivotFontFamily : 'EvidenceSegoeUI',
            platform: TargetPlatform.windows),
        home: variant == 'improved'
            ? const ImprovedScene()
            : const BaselineScene(),
      ),
    ));
    await tester.pumpAndSettle();
    final events = (replay['events'] as List).cast<Map<String, dynamic>>();
    final steps = <({int us, Map<String, dynamic>? event, bool capture})>[];
    for (final event in events) {
      steps.add((
        us: ((event['t_ms'] as num) * 1000).round(),
        event: event,
        capture: false
      ));
    }
    final end = ((replay['end_ms'] as num) * 1000).round();
    for (var frame = 0; (frame * 1000000 / 60).round() <= end; frame++) {
      steps.add(
          (us: (frame * 1000000 / 60).round(), event: null, capture: true));
    }
    steps.sort((a, b) {
      final time = a.us.compareTo(b.us);
      return time != 0 ? time : (a.capture ? 1 : -1);
    });
    var previous = 0;
    var number = 0;
    TestGesture? gesture;
    final frames = StringBuffer('frame,t_ms\n');
    final positions = StringBuffer('t_ms,item,x,y\n');
    for (final step in steps) {
      await tester.pump(Duration(microseconds: step.us - previous));
      previous = step.us;
      final event = step.event;
      if (event != null) {
        final point = Offset(
            (event['x'] as num).toDouble(), (event['y'] as num).toDouble());
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
        final t = step.us / 1000 - 500;
        frames.writeln('$number,$t');
        for (var i = 0; i < 4; i++) {
          final marker = find.byKey(ValueKey('marker-$i'));
          if (marker.evaluate().isNotEmpty) {
            final point = tester.getTopLeft(marker);
            positions.writeln('$t,$i,${point.dx},${point.dy}');
          }
        }
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage();
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
    File('$outputPath/frames.csv').writeAsStringSync(frames.toString());
    File('$outputPath/positions.csv').writeAsStringSync(positions.toString());
    File('$outputPath/replay.json').writeAsStringSync(jsonEncode(replay));
    File('$outputPath/manifest.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'source': 'flutter-test-engine',
      'variant': variant == 'baseline'
          ? 'unmodified-2.0.0-baseline'
          : 'native-motion-implementation',
      'native_trial': replay['source_trial'],
      'viewport': [480, 800],
      'device_pixel_ratio': 1,
      'platform': 'windows',
      'frame_count': number,
      'sample_fps': 60,
      'clock': 'deterministic tester pump; not wall-clock performance',
      'input': 'guest touch events replayed at their recorded relative times',
      'font': variant == 'improved'
          ? 'Bundled Selawik 1.01 (OFL), the actual package default; not native Segoe WP'
          : 'locally installed Segoe UI; not native Segoe WP; font files not distributed',
      'font_paths': fontPaths,
      'positions_note':
          'Element transforms can include hidden IndexedStack children; use image observations for visible trajectories.',
      'scene_style': variant == 'baseline'
          ? 'Existing example header sizes, weights, colors and PageView wiring; standardized research page content'
          : 'WpPivotView package defaults with native-reference page content',
    }));
    await tester.pumpWidget(const SizedBox());
  });
}
