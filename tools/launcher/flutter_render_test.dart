// Opt-in deterministic WVGA rendering for the Start-screen component adapter.
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
  testWidgets('render Start tile geometry adapter fixture', (tester) async {
    expect(outputPath, isNotEmpty);
    final output = Directory(outputPath);
    if (output.existsSync()) throw StateError('Use a fresh output directory.');
    output.createSync(recursive: true);

    final sourceFiles = <String>[
      'tools/launcher/flutter_render_test.dart',
      'pubspec.yaml',
      'pubspec.lock',
      ...Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path),
      ...Directory('assets/fonts')
          .listSync()
          .whereType<File>()
          .map((file) => file.path),
    ];
    for (final path in sourceFiles) {
      final copy = File('$outputPath/source-snapshot/$path');
      copy.parent.createSync(recursive: true);
      File(path).copySync(copy.path);
    }

    final loader = FontLoader(wpPivotFontFamily);
    for (final name in ['selawksl.ttf', 'selawk.ttf', 'selawksb.ttf']) {
      loader.addFont(Future.value(
        ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync()),
      ));
    }
    await loader.load();

    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final boundary = GlobalKey();
    Future<void> render({required bool editing, required String name}) async {
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
              child: _StartFixture(editing: editing),
            ),
          ),
        ),
      );
      await tester.pump();
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$outputPath/$name.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await render(editing: false, name: 'rest');
    await render(editing: true, name: 'edit');
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
          home: const WpPhoneTheme(
            data: WpPhoneThemeData.dark(),
            child: _AppListFixture(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => _writeBoundary(boundary, '$outputPath/app-list.png'),
    );
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
          home: const WpPhoneTheme(
            data: WpPhoneThemeData.dark(),
            child: _AlphabetFixture(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => _writeBoundary(boundary, '$outputPath/alphabet.png'),
    );
    expect(tester.takeException(), isNull);

    final revision =
        Process.runSync('git', ['rev-parse', 'HEAD']).stdout.toString().trim();
    File('$outputPath/manifest.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'adapter_id': 'start-screen-wp81-wvga-rest-geometry-v1',
        'source': 'deterministic Flutter widget render',
        'resolution': [480, 800],
        'candidate_revision': revision,
        'candidate_has_source_snapshot': true,
        'frames': [
          'rest.png',
          'edit.png',
          'app-list.png',
          'alphabet.png',
        ],
        'font': 'Bundled OFL Selawik; differs from native Segoe WP.',
        'claims': [
          'resting tile surface geometry',
          'controlled edit-affordance presentation',
          'resting app-list slot geometry',
          'resting alphabet-grid surface geometry',
        ],
        'limits': [
          'No Microsoft icons or artwork are reproduced.',
          'This deterministic render is not live Android runtime evidence.',
          'No native timing, curve, typography, or physical-latency claim.',
        ],
        'recoverable_source_files': sourceFiles,
      }),
    );
  });
}

Future<void> _writeBoundary(GlobalKey boundary, String path) async {
  final render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await render.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(data!.buffer.asUint8List());
  image.dispose();
}

class _StartFixture extends StatelessWidget {
  const _StartFixture({required this.editing});

  final bool editing;

  static const accent = Color(0xff3e65ff);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: 56,
            width: 480,
            child: WpTileGrid(
              placements: [
                _tile('Phone', 0, 0, rowSpan: 2, columnSpan: 2),
                _tile('Messaging', 0, 2),
                _tile('Browser', 0, 3),
                _tile('Mail', 1, 2),
                _tile('Store', 1, 3),
                WpTilePlacement(
                  row: 2,
                  column: 0,
                  rowSpan: 2,
                  columnSpan: 2,
                  child: WpTile(
                    label: 'People',
                    color: const Color(0xff9dafff),
                    child: CustomPaint(painter: _PeoplePlanePainter()),
                  ),
                ),
                _tile('Music', 2, 2, color: const Color(0xff107c10)),
                _tile('Games', 2, 3, color: const Color(0xff107c10)),
                _tile('Office', 3, 2, color: const Color(0xffeb3c00)),
                _tile('Notes', 3, 3, color: const Color(0xff80397b)),
                _tile(
                  'Calendar',
                  4,
                  0,
                  rowSpan: 2,
                  columnSpan: 2,
                  editing: editing,
                ),
                _tile(
                  "Kid's Corner",
                  4,
                  2,
                  rowSpan: 2,
                  columnSpan: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  WpTilePlacement _tile(
    String label,
    int row,
    int column, {
    int rowSpan = 1,
    int columnSpan = 1,
    Color color = accent,
    bool editing = false,
  }) {
    return WpTilePlacement(
      row: row,
      column: column,
      rowSpan: rowSpan,
      columnSpan: columnSpan,
      child: WpTile(
        label: label,
        semanticLabel: label,
        color: color,
        editing: editing,
        onUnpin: editing ? () {} : null,
        onResize: editing ? () {} : null,
        child: const Center(
          child: SizedBox.square(
            dimension: 28,
            child: ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _PeoplePlanePainter extends CustomPainter {
  const _PeoplePlanePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xff9dafff),
      const Color(0xff6d88f8),
      const Color(0xff3e65ff),
    ];
    final cell = size.width / 3;
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 3; column++) {
        canvas.drawRect(
          Rect.fromLTWH(column * cell, row * cell, cell, cell),
          Paint()..color = colors[(row + column) % colors.length],
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PeoplePlanePainter oldDelegate) => false;
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: WpAppListView(
        leadingAction: const CustomPaint(painter: _SearchPainter()),
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

class _SearchPainter extends CustomPainter {
  const _SearchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(size.center(Offset.zero), 19, paint);
    canvas.drawCircle(size.center(Offset.zero) - const Offset(3, 3), 5, paint);
    canvas.drawLine(
      size.center(Offset.zero) + const Offset(1, 1),
      size.center(Offset.zero) + const Offset(8, 8),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SearchPainter oldDelegate) => false;
}

class _AlphabetFixture extends StatelessWidget {
  const _AlphabetFixture();

  static const letters = <String>[
    '#',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '◎',
  ];

  static const enabled = <String>{
    'a',
    'b',
    'c',
    'd',
    'f',
    'g',
    'h',
    'i',
    'm',
    'n',
    'o',
    'p',
    's',
    't',
    'v',
    'w',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: WpAlphabetGrid(
        letters: letters,
        enabledLetters: enabled,
        onSelected: (_) {},
      ),
    );
  }
}
