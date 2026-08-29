// Opt-in multi-viewport PNG capture of actual gallery demo widgets.
// Not part of the default test suite; requires --dart-define=OUTPUT=...
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:example/component_gallery_shell.dart';
import 'package:example/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';

/// Logical viewport matrix for responsiveness checks (width × height, DPR 1).
const _viewports = <({String name, double width, double height})>[
  (name: 'compact-portrait', width: 320, height: 533),
  (name: 'baseline', width: 480, height: 800),
  (name: 'tall-portrait', width: 480, height: 853),
  (name: 'wide-short', width: 800, height: 480),
];

const _states = <String>[
  'application-bar-collapsed',
  'application-bar-expanded',
  'panorama-rest',
  'panorama-swiped',
  'toggle-switch-activated',
];

String _repoPath(String relative) {
  final fromExample = File('../$relative');
  if (fromExample.existsSync()) return '../$relative';
  return relative;
}

void main() {
  const outputPath = String.fromEnvironment('OUTPUT');
  if (outputPath.isEmpty) {
    testWidgets('skipped without OUTPUT dart-define', (tester) async {});
    return;
  }

  testWidgets('capture gallery demo widgets at viewport matrix',
      (tester) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    expect(outputPath, isNotEmpty);
    final output = Directory(outputPath);
    if (output.existsSync()) {
      throw StateError('Use a fresh output directory.');
    }
    output.createSync(recursive: true);

    final sources = _recoverableSourcePaths();
    for (final entry in sources) {
      final copy = File('$outputPath/source-snapshot/${entry.snapshotPath}');
      copy.parent.createSync(recursive: true);
      File(entry.sourcePath).copySync(copy.path);
    }

    await _loadBundledFonts();

    final boundary = GlobalKey();
    final captures = <Map<String, dynamic>>[];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final viewport in _viewports) {
      final viewportDir = Directory(
        '${output.path}/${viewport.width.round()}x${viewport.height.round()}',
      );
      viewportDir.createSync(recursive: true);

      await _setLogicalViewport(
        tester,
        width: viewport.width,
        height: viewport.height,
      );

      for (final state in _states) {
        await _pumpGalleryScene(
          tester,
          boundary: boundary,
          state: state,
          width: viewport.width,
          height: viewport.height,
        );
        final fileName = '$state.png';
        final pngPath = '${viewportDir.path}/$fileName';
        await _writePng(tester, boundary, pngPath);
        final overflow = tester.takeException();
        captures.add({
          'viewport_name': viewport.name,
          'logical_width': viewport.width,
          'logical_height': viewport.height,
          'device_pixel_ratio': 1,
          'state': state,
          'png': pngPath,
          'overflow_or_error': overflow?.toString(),
        });
        if (overflow != null) {
          fail(
              'Layout overflow or error in $viewport.name / $state: $overflow');
        }
      }
    }

    await _setLogicalViewport(tester, width: 480, height: 800);
    final navDir = Directory('${output.path}/navigation-480x800');
    navDir.createSync(recursive: true);

    for (final phase in _navigationPhases) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: const ComponentGallery(),
        ),
      );
      await tester.pumpAndSettle();

      switch (phase) {
        case 'forward-out-mid':
          await _tapGalleryEntry(tester, 'application bar');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(
              find.byKey(const ValueKey('wp-phone-entry-3')), findsOneWidget);
          expect(find.text('windows phone'), findsOneWidget);
          break;
        case 'forward-wait-boundary':
          await _tapGalleryEntry(tester, 'application bar');
          await tester.pump();
          await tester.pump(
            Duration(milliseconds: WpTurnstileFeather.forwardOutPhaseMsFor(5)),
          );
          _assertGalleryHomeVisible(tester);
          break;
        case 'forward-in-stagger':
          await _tapGalleryEntry(tester, 'application bar');
          await tester.pump();
          await tester.pump(
            Duration(
              milliseconds: WpTurnstileFeather.forwardOutPhaseMsFor(5) + 50,
            ),
          );
          expect(find.byType(ApplicationBarDemo), findsOneWidget);
          break;
        case 'forward-settled':
          await _tapGalleryEntry(tester, 'application bar');
          await tester.pumpAndSettle();
          _assertApplicationBarDemoSettled(tester);
          break;
        case 'back-out-mid':
          await _tapGalleryEntry(tester, 'application bar');
          await tester.pumpAndSettle();
          _assertApplicationBarDemoSettled(tester);
          await _tapHardwareBack(tester, ApplicationBarDemo);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 165));
          expect(find.byType(ApplicationBarDemo), findsOneWidget);
          break;
        case 'back-wait-boundary':
          await _tapGalleryEntry(tester, 'application bar');
          await tester.pumpAndSettle();
          _assertApplicationBarDemoSettled(tester);
          await _tapHardwareBack(tester, ApplicationBarDemo);
          await tester.pump();
          await tester.pump(
            Duration(
              milliseconds: WpTurnstileFeather.backwardOutPhaseMsFor(2),
            ),
          );
          expect(find.byType(ApplicationBarDemo), findsOneWidget);
          break;
        case 'back-in-stagger':
          await _tapGalleryEntry(tester, 'application bar');
          await tester.pumpAndSettle();
          _assertApplicationBarDemoSettled(tester);
          await _tapHardwareBack(tester, ApplicationBarDemo);
          await tester.pump();
          await tester.pump(
            Duration(
              milliseconds: WpTurnstileFeather.backwardOutPhaseMsFor(2) + 100,
            ),
          );
          _assertGalleryHomePainted(tester);
          expect(find.byType(WpApplicationBar), findsNothing);
          break;
        case 'back-settled':
          await _tapGalleryEntry(tester, 'application bar');
          await tester.pumpAndSettle();
          _assertApplicationBarDemoSettled(tester);
          await _tapHardwareBack(tester, ApplicationBarDemo);
          await tester.pumpAndSettle();
          _assertGalleryHomeVisible(tester);
          break;
      }

      final pngPath = '${navDir.path}/$phase.png';
      await _writePng(tester, boundary, pngPath);
      final overflow = tester.takeException();
      captures.add({
        'viewport_name': 'baseline',
        'logical_width': 480,
        'logical_height': 800,
        'device_pixel_ratio': 1,
        'state': 'navigation-$phase',
        'png': pngPath,
        'overflow_or_error': overflow?.toString(),
      });
      if (overflow != null) {
        fail('Layout overflow or error in navigation/$phase: $overflow');
      }
    }

    File('$outputPath/manifest.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'source': 'deterministic gallery demo viewport capture',
        'harness': 'example/test/viewport_capture_test.dart',
        'viewports': _viewports
            .map((v) => {
                  'name': v.name,
                  'logical_width': v.width,
                  'logical_height': v.height,
                })
            .toList(),
        'states': _states,
        'navigation_phases': _navigationPhases,
        'capture_count': captures.length,
        'captures': captures,
        'fonts':
            'Bundled OFL Selawik via FontLoader; differs from native Segoe WP.',
        'timing':
            'State matrix uses pumpAndSettle; navigation uses fatal missed-tap checks, ensureVisible taps, and route-state assertions.',
        'fidelity_verified': false,
        'recoverable_source_files': sources.map((e) => e.snapshotPath).toList(),
        'inspection_notes':
            'Inspect PNGs at native logical size; do not stretch to simulate adaptivity.',
      }),
    );
  });
}

const _navigationPhases = <String>[
  'forward-out-mid',
  'forward-wait-boundary',
  'forward-in-stagger',
  'forward-settled',
  'back-out-mid',
  'back-wait-boundary',
  'back-in-stagger',
  'back-settled',
];

class _SnapshotEntry {
  const _SnapshotEntry({required this.sourcePath, required this.snapshotPath});
  final String sourcePath;
  final String snapshotPath;
}

List<_SnapshotEntry> _recoverableSourcePaths() {
  final entries = <_SnapshotEntry>[
    _SnapshotEntry(
      sourcePath: 'test/viewport_capture_test.dart',
      snapshotPath: 'example/test/viewport_capture_test.dart',
    ),
    _SnapshotEntry(
      sourcePath: 'test/components_gallery_test.dart',
      snapshotPath: 'example/test/components_gallery_test.dart',
    ),
    _SnapshotEntry(
      sourcePath: _repoPath('pubspec.yaml'),
      snapshotPath: 'pubspec.yaml',
    ),
    _SnapshotEntry(
      sourcePath: _repoPath('pubspec.lock'),
      snapshotPath: 'pubspec.lock',
    ),
    _SnapshotEntry(
      sourcePath: 'pubspec.yaml',
      snapshotPath: 'example/pubspec.yaml',
    ),
    _SnapshotEntry(
      sourcePath: _repoPath('tools/components/render_test.dart'),
      snapshotPath: 'tools/components/render_test.dart',
    ),
    _SnapshotEntry(
      sourcePath: 'lib/components.dart',
      snapshotPath: 'example/lib/components.dart',
    ),
    _SnapshotEntry(
      sourcePath: 'lib/component_gallery_shell.dart',
      snapshotPath: 'example/lib/component_gallery_shell.dart',
    ),
  ];
  _addDirectoryEntries(
    entries,
    directoryPath: _repoPath('lib'),
    snapshotPrefix: 'lib',
  );
  _addDirectoryEntries(
    entries,
    directoryPath: _repoPath('test'),
    snapshotPrefix: 'test',
  );
  _addDirectoryEntries(
    entries,
    directoryPath: 'lib',
    snapshotPrefix: 'example/lib',
  );
  _addDirectoryEntries(
    entries,
    directoryPath: 'test',
    snapshotPrefix: 'example/test',
  );
  final fontsDir = Directory(_repoPath('assets/fonts'));
  if (fontsDir.existsSync()) {
    for (final file in fontsDir.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      entries.add(_SnapshotEntry(
        sourcePath: file.path,
        snapshotPath: 'assets/fonts/$name',
      ));
    }
  }
  final seen = <String>{};
  return entries
      .where((e) => File(e.sourcePath).existsSync())
      .where((e) => seen.add(e.snapshotPath))
      .toList();
}

void _addDirectoryEntries(
  List<_SnapshotEntry> entries, {
  required String directoryPath,
  required String snapshotPrefix,
}) {
  final dir = Directory(directoryPath);
  if (!dir.existsSync()) return;
  final root = dir.absolute.path;
  final rootPrefix = root.endsWith(Platform.pathSeparator)
      ? root
      : '$root${Platform.pathSeparator}';
  for (final file in dir.listSync(recursive: true).whereType<File>()) {
    final filePath = file.absolute.path;
    if (!filePath.startsWith(rootPrefix)) continue;
    final rel = filePath.substring(rootPrefix.length).replaceAll('\\', '/');
    entries.add(_SnapshotEntry(
      sourcePath: file.path,
      snapshotPath: '$snapshotPrefix/$rel',
    ));
  }
}

Future<void> _loadBundledFonts() async {
  final loader = FontLoader(wpPivotFontFamily);
  for (final name in ['selawksl.ttf', 'selawk.ttf', 'selawksb.ttf']) {
    loader.addFont(Future.value(ByteData.sublistView(
        File(_repoPath('assets/fonts/$name')).readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _tapGalleryEntry(WidgetTester tester, String title) async {
  final tapKey = switch (title) {
    'application bar' => const ValueKey('wp-phone-entry-tap-3'),
    'panorama' => const ValueKey('wp-phone-entry-tap-4'),
    'toggle switch' => const ValueKey('wp-phone-entry-tap-5'),
    _ => throw ArgumentError('Unknown gallery entry: $title'),
  };
  final finder = find.byKey(tapKey);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  final origin = tester.getTopLeft(finder);
  await tester.tapAt(origin + const Offset(8, 8));
  await tester.pump();
}

Future<void> _tapHardwareBack(WidgetTester tester, Type demoType) async {
  final finder = find.descendant(
    of: find.byType(demoType),
    matching: find.byKey(const ValueKey('wp-preview-hardware-back')),
  );
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  final origin = tester.getTopLeft(finder);
  await tester.tapAt(origin + const Offset(8, 8));
  await tester.pump();
}

void _assertGalleryHomeVisible(WidgetTester tester) {
  expect(find.text('windows phone'), findsOneWidget);
  expect(find.text('components'), findsWidgets);
}

void _assertGalleryHomePainted(WidgetTester tester) {
  _assertGalleryHomeVisible(tester);
  expect(find.text('windows phone').hitTestable(), findsOneWidget);
  expect(find.text('application bar').hitTestable(), findsOneWidget);
}

void _assertApplicationBarDemoSettled(WidgetTester tester) {
  expect(find.byType(ApplicationBarDemo), findsOneWidget);
  expect(find.byType(WpApplicationBar), findsOneWidget);
}

Future<void> _setLogicalViewport(
  WidgetTester tester, {
  required double width,
  required double height,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
}

Widget _galleryShell(Widget demo) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      fontFamily: wpPivotFontFamily,
      colorScheme: const ColorScheme.dark(primary: Color(0xff1ba1e2)),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {}),
    ),
    home: DefaultTextStyle(
      style: wpPhoneDefaultTextStyle,
      child: demo,
    ),
  );
}

Future<void> _pumpGalleryScene(
  WidgetTester tester, {
  required GlobalKey boundary,
  required String state,
  required double width,
  required double height,
}) async {
  final Widget demo;
  switch (state) {
    case 'application-bar-collapsed':
    case 'application-bar-expanded':
      demo = const ApplicationBarDemo();
      break;
    case 'panorama-rest':
    case 'panorama-swiped':
      demo = const PanoramaDemo();
      break;
    case 'toggle-switch-activated':
      demo = const ToggleSwitchDemo();
      break;
    default:
      throw ArgumentError('Unknown state: $state');
  }

  await tester.pumpWidget(
    RepaintBoundary(
      key: boundary,
      child: _galleryShell(demo),
    ),
  );
  await tester.pumpAndSettle();

  switch (state) {
    case 'application-bar-expanded':
      await tester.tap(find.bySemanticsLabel('Open application menu'));
      await tester.pumpAndSettle();
      break;
    case 'panorama-swiped':
      final start = Offset(width * 405 / 480, height * 500 / 800);
      final delta = Offset(-width * 320 / 480, 0);
      await tester.dragFrom(start, delta);
      await tester.pumpAndSettle();
      break;
    case 'toggle-switch-activated':
      await tester.tap(find.bySemanticsLabel('Wi-Fi, Off'));
      await tester.pumpAndSettle();
      break;
    default:
      break;
  }
}

Future<void> _writePng(
  WidgetTester tester,
  GlobalKey boundary,
  String pngPath,
) async {
  final render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(pngPath).writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}
