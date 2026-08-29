// Opt-in deterministic rendering of SDK receipt events, not a live benchmark.
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
  const component = String.fromEnvironment('COMPONENT');
  const eventsPath = String.fromEnvironment('EVENTS');
  const outputPath = String.fromEnvironment('OUTPUT');
  testWidgets('render experimental component from SDK receipt inputs',
      (tester) async {
    expect(
        ['application-bar', 'panorama', 'toggle-switch'], contains(component));
    expect(eventsPath, isNotEmpty);
    expect(outputPath, isNotEmpty);
    final output = Directory(outputPath);
    if (output.existsSync()) throw StateError('Use a fresh output.');
    output.createSync(recursive: true);
    Directory('$outputPath/frames').createSync();
    // Keep recoverable source bytes with every attempt, including failed ones.
    final sources = <String>[
      'tools/components/render_test.dart',
      'pubspec.yaml',
      'pubspec.lock',
      ...Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path),
      ...Directory('assets/fonts')
          .listSync()
          .whereType<File>()
          .map((f) => f.path),
    ];
    for (final path in sources) {
      final copy = File('$outputPath/source-snapshot/$path');
      copy.parent.createSync(recursive: true);
      File(path).copySync(copy.path);
    }
    final loader = FontLoader(wpPivotFontFamily);
    for (final name in ['selawksl.ttf', 'selawk.ttf', 'selawksb.ttf']) {
      loader.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync())));
    }
    await loader.load();
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final changes = <Object>[];
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            fontFamily: wpPivotFontFamily),
        home: _ReferenceScene(component: component, changes: changes),
      ),
    ));
    await tester.pumpAndSettle();
    final events = File(eventsPath)
        .readAsLinesSync()
        .where((line) => line.isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .where((event) => event['event'] == 'pointer')
        .toList();
    expect(events, isNotEmpty);
    final steps = <({int us, Map<String, dynamic>? event})>[];
    var previousEventTime = -1;
    var pressed = false;
    for (final event in events) {
      final us = ((event['host_received_ms'] as num) * 1000).round();
      expect(us, inInclusiveRange(0, 119000000));
      expect(us, greaterThanOrEqualTo(previousEventTime));
      previousEventTime = us;
      switch (event['phase']) {
        case 'down':
          expect(pressed, isFalse);
          pressed = true;
        case 'move':
          expect(pressed, isTrue);
        case 'up':
          expect(pressed, isTrue);
          pressed = false;
        default:
          fail('Unsupported pointer phase');
      }
      steps.add((us: us, event: event));
    }
    expect(pressed, isFalse);
    final end = previousEventTime + 1000000;
    for (var us = 0; us <= end; us += 33333) {
      steps.add((us: us, event: null));
    }
    steps.sort((a, b) => a.us != b.us
        ? a.us.compareTo(b.us)
        : a.event == null
            ? 1
            : -1);
    var previous = 0;
    var frame = 0;
    TestGesture? gesture;
    final frameRows = StringBuffer('frame,t_ms\n');
    for (final step in steps) {
      await tester.pump(Duration(microseconds: step.us - previous));
      previous = step.us;
      final event = step.event;
      if (event != null) {
        final point = Offset(
            (event['x'] as num).toDouble(), (event['y'] as num).toDouble());
        final timestamp = Duration(microseconds: step.us);
        switch (event['phase']) {
          case 'down':
            gesture = await tester.createGesture();
            await gesture.down(point, timeStamp: timestamp);
          case 'move':
            await gesture!.moveTo(point, timeStamp: timestamp);
          case 'up':
            await gesture!.up(timeStamp: timestamp);
            gesture = null;
        }
      } else {
        final render = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$outputPath/frames/${frame.toString().padLeft(6, '0')}.png')
              .writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
        frameRows.writeln('$frame,${step.us / 1000}');
        frame++;
      }
    }
    expect(tester.takeException(), isNull);
    File('$outputPath/frames.csv').writeAsStringSync(frameRows.toString());
    File('$outputPath/manifest.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'component': component,
      'source': 'deterministic Flutter widget replay',
      'input_events_path': eventsPath,
      'input_events': events,
      'frame_count': frame,
      'resolution': [480, 800],
      'selection_or_commands': changes,
      'timing':
          'SDK host receipt intervals replayed in test clock. Not calibrated guest time or live performance.',
      'fonts': 'Bundled OFL Selawik; differs from native Segoe WP.',
      'fidelity_verified': false,
      'recoverable_source_files': sources,
    }));
  });
}

class _ReferenceScene extends StatefulWidget {
  const _ReferenceScene({required this.component, required this.changes});
  final String component;
  final List<Object> changes;
  @override
  State<_ReferenceScene> createState() => _ReferenceSceneState();
}

class _ReferenceSceneState extends State<_ReferenceScene> {
  bool wifi = false;
  bool bluetooth = true;
  bool minimized = false;

  @override
  Widget build(BuildContext context) {
    if (widget.component == 'panorama') {
      return Scaffold(
          body: WpPanorama(
        title: 'panorama',
        onChanged: widget.changes.add,
        items: [
          for (final item in const [
            ('first', Color(0xff1ba1e2)),
            ('second', Color(0xff60a917)),
            ('third', Color(0xfff09609))
          ])
            WpPanoramaItem(
                header: item.$1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 6, color: item.$2),
                    const SizedBox(height: 24),
                    Text('${item.$1} page',
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 12),
                    const Text('Swipe to explore',
                        style:
                            TextStyle(fontSize: 24, color: Color(0xffa6a6a6))),
                    const SizedBox(height: 32),
                    Container(width: 64, height: 64, color: item.$2),
                  ],
                )),
        ],
      ));
    }
    if (widget.component == 'toggle-switch') {
      return Scaffold(
          body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TOGGLE SWITCH',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: TextStyle(fontSize: 64, fontWeight: FontWeight.w300)),
          const SizedBox(height: 34),
          SizedBox(
              height: 111,
              child: WpToggleSwitch(
                  value: wifi,
                  header: 'Wi-Fi',
                  onChanged: (value) => setState(() {
                        wifi = value;
                        widget.changes.add({'wifi': value});
                      }))),
          SizedBox(
              height: 111,
              child: WpToggleSwitch(
                  value: bluetooth,
                  header: 'Bluetooth',
                  onChanged: (value) => setState(() {
                        bluetooth = value;
                        widget.changes.add({'bluetooth': value});
                      }))),
          const SizedBox(
              height: 111,
              child: WpToggleSwitch(
                  value: true, header: 'Disabled', onChanged: null)),
        ]),
      ));
    }
    return Scaffold(
      body: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('APPLICATION BAR', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 24),
            Text(minimized ? 'minimized' : 'default',
                style: const TextStyle(fontSize: 24, color: Color(0xffa6a6a6))),
            const SizedBox(height: 48),
            SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 3),
                      shape: const RoundedRectangleBorder(),
                      textStyle: const TextStyle(
                          fontSize: 24, fontFamily: wpPivotFontFamily),
                    ),
                    onPressed: () => setState(() => minimized = !minimized),
                    child: const Text('toggle minimized'))),
          ])),
      bottomNavigationBar: WpApplicationBar(
        mode: minimized
            ? WpApplicationBarMode.minimized
            : WpApplicationBarMode.defaultMode,
        actions: [
          WpApplicationBarAction(
              icon: const _ReferenceArrow(forward: false),
              label: 'previous',
              onPressed: () => widget.changes.add('previous')),
          WpApplicationBarAction(
              icon: const _ReferenceArrow(forward: true),
              label: 'next',
              onPressed: () => widget.changes.add('next')),
        ],
        menuItems: [
          WpApplicationBarMenuItem(
              label: 'settings',
              onPressed: () => widget.changes.add('settings')),
          WpApplicationBarMenuItem(
              label: 'about', onPressed: () => widget.changes.add('about')),
        ],
      ),
    );
  }
}

// Scene-only substitute glyph: no proprietary native icon or font is copied.
class _ReferenceArrow extends StatelessWidget {
  const _ReferenceArrow({required this.forward});
  final bool forward;
  @override
  Widget build(BuildContext context) => CustomPaint(
      size: const Size(26, 26),
      painter:
          _ArrowPainter(forward, IconTheme.of(context).color ?? Colors.white));
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.forward, this.color);
  final bool forward;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (!forward) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(2, 13), const Offset(23, 13), paint);
    canvas.drawPath(
        Path()
          ..moveTo(13, 3)
          ..lineTo(23, 13)
          ..lineTo(13, 23),
        paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.forward != forward || old.color != color;
}
