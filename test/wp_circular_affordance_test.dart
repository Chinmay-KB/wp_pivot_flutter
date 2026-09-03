import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

Widget _scene(
  Widget child, {
  WpPhoneThemeData theme = const WpPhoneThemeData.dark(),
  bool disableAnimations = false,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(disableAnimations: disableAnimations),
          child: WpPhoneTheme(
            data: theme,
            child: Scaffold(
              backgroundColor: theme.backgroundColor,
              body: Align(alignment: Alignment.topLeft, child: child),
            ),
          ),
        );
      },
    ),
  );
}

Material _affordanceMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(
      of: find.byType(WpCircularAffordance),
      matching: find.byType(Material),
    ),
  );
}

WpSearchGlyphPainter _glyphPainter(WidgetTester tester) {
  return tester.widget<CustomPaint>(
    find.byKey(const ValueKey('wp-search-glyph')),
  ).painter! as WpSearchGlyphPainter;
}

void main() {
  testWidgets('affordance reproduces measured 44-unit geometry',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scene(WpCircularAffordance(searching: false, onPressed: () {})),
    );

    expect(
      tester.getSize(find.byType(WpCircularAffordance)),
      const Size(44, 44),
    );
    final material = _affordanceMaterial(tester);
    expect(material.color, Colors.transparent);
    final ring = material.shape! as CircleBorder;
    expect(ring.side.color, Colors.white);
    expect(ring.side.width, 2);
    expect(
      tester.getSize(find.byKey(const ValueKey('wp-search-glyph'))),
      const Size(28, 28),
    );

    final painter = _glyphPainter(tester);
    expect(painter.close, isFalse);
    expect(painter.color, Colors.white);
    expect(painter.strokeWidth, 2.8);
  });

  testWidgets('affordance scales ring and glyph proportionally',
      (tester) async {
    await tester.pumpWidget(
      _scene(WpCircularAffordance(searching: true, onPressed: () {}, size: 88)),
    );

    expect(
      tester.getSize(find.byType(WpCircularAffordance)),
      const Size(88, 88),
    );
    expect(
      (_affordanceMaterial(tester).shape! as CircleBorder).side.width,
      4,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('wp-search-glyph'))),
      const Size(56, 56),
    );
  });

  testWidgets('glyph exposes source-aligned defaults standalone',
      (tester) async {
    await tester.pumpWidget(
      _scene(const WpSearchGlyph(close: true)),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('wp-search-glyph'))),
      const Size(28, 28),
    );
    final painter = _glyphPainter(tester);
    expect(painter.close, isTrue);
    expect(painter.color, Colors.white);
    expect(painter.strokeWidth, 2.8);
  });

  testWidgets('affordance exposes search/close semantics and activates',
      (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _scene(WpCircularAffordance(searching: false, onPressed: () => taps++)),
    );

    final search = find.bySemanticsLabel('Search apps');
    expect(search, findsOneWidget);
    expect(
      tester.getSemantics(search).getSemanticsData().hasAction(
            SemanticsAction.tap,
          ),
      isTrue,
    );
    await tester.tap(search);
    expect(taps, 1);

    await tester.pumpWidget(
      _scene(WpCircularAffordance(searching: true, onPressed: () => taps++)),
    );
    expect(find.bySemanticsLabel('Close app search'), findsOneWidget);
    expect(find.bySemanticsLabel('Search apps'), findsNothing);
    semantics.dispose();
  });

  testWidgets('disabled affordance exposes disabled semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _scene(const WpCircularAffordance(searching: false, onPressed: null)),
    );

    final node = find.bySemanticsLabel('Search apps');
    expect(node, findsOneWidget);
    expect(
      tester.getSemantics(node).getSemanticsData().hasAction(
            SemanticsAction.tap,
          ),
      isFalse,
    );
    await tester.tap(node);
    await tester.pump();
    semantics.dispose();
  });

  testWidgets('affordance supports keyboard activation', (tester) async {
    final focusNode = FocusNode(debugLabel: 'test-affordance');
    addTearDown(focusNode.dispose);
    var taps = 0;
    await tester.pumpWidget(
      _scene(
        WpCircularAffordance(
          searching: false,
          onPressed: () => taps++,
          focusNode: focusNode,
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 2);
  });

  testWidgets('affordance consumes theme colors and explicit overrides',
      (tester) async {
    const theme = WpPhoneThemeData.dark(
      foregroundColor: Color(0xffeeeeee),
    );
    await tester.pumpWidget(
      _scene(
        WpCircularAffordance(searching: false, onPressed: () {}),
        theme: theme,
      ),
    );

    expect(
      (_affordanceMaterial(tester).shape! as CircleBorder).side.color,
      const Color(0xffeeeeee),
    );
    expect(_glyphPainter(tester).color, const Color(0xffeeeeee));

    await tester.pumpWidget(
      _scene(
        WpCircularAffordance(
          searching: true,
          onPressed: () {},
          ringColor: const Color(0xffaa3300),
          glyphColor: const Color(0xff00ff00),
        ),
        theme: theme,
      ),
    );

    expect(
      (_affordanceMaterial(tester).shape! as CircleBorder).side.color,
      const Color(0xffaa3300),
    );
    expect(_glyphPainter(tester).color, const Color(0xff00ff00));
  });

  testWidgets('reduced motion keeps affordance tappable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _scene(
        WpCircularAffordance(searching: false, onPressed: () => taps++),
        disableAnimations: true,
      ),
    );

    final inkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byType(WpCircularAffordance),
        matching: find.byType(InkWell),
      ),
    );
    expect(inkWell.splashFactory, NoSplash.splashFactory);
    await tester.tap(find.bySemanticsLabel('Search apps'));
    expect(taps, 1);
  });
}
