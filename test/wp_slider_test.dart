import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 456, child: child),
      ),
    ),
  );
}

void main() {
  test('geometry matches the WP8 PhoneSlider template', () {
    expect(WpSliderGeometry.height, 84);
    expect(WpSliderGeometry.horizontalMargin, 12);
    expect(WpSliderGeometry.trackTop, 22);
    expect(WpSliderGeometry.trackHeight, 12);
    expect(WpSliderGeometry.thumbTop, 16);
    expect(WpSliderGeometry.thumbWidth, 12);
    expect(WpSliderGeometry.thumbHeight, 24);
  });

  testWidgets('native fixture tap coordinate maps to its recorded value',
      (tester) async {
    double? requested;
    await tester.pumpWidget(
      _host(
        WpSlider(
          min: 0,
          max: 100,
          value: 35,
          onChanged: (value) => requested = value,
        ),
      ),
    );
    final origin = tester.getTopLeft(find.byType(WpSlider));
    await tester.tapAt(origin + const Offset(368, 42));
    expect(requested, closeTo(83.3333, .001));
  });

  testWidgets('drag clamps and reports continuously while remaining controlled',
      (tester) async {
    final requested = <double>[];
    await tester.pumpWidget(
      _host(
        WpSlider(
          min: 0,
          max: 100,
          value: 35,
          onChanged: requested.add,
        ),
      ),
    );
    final origin = tester.getTopLeft(find.byType(WpSlider));
    await tester.timedDragFrom(
      origin + const Offset(162, 42),
      const Offset(231, 0),
      const Duration(seconds: 1),
    );
    expect(requested, isNotEmpty);
    expect(requested.last, closeTo(89.2857, .001));
    final painter = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('wp-slider-track')))
        .painter as WpSliderPainter;
    expect(painter.normalizedValue, .35);
  });

  testWidgets('disabled slider ignores input and uses disabled painter state',
      (tester) async {
    await tester.pumpWidget(
      _host(const WpSlider(value: 5, onChanged: null)),
    );
    await tester.tap(find.byType(WpSlider));
    final painter = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('wp-slider-track')))
        .painter as WpSliderPainter;
    expect(painter.enabled, isFalse);
  });

  testWidgets('keyboard and semantics expose value changes', (tester) async {
    double? requested;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        WpSlider(
          value: 5,
          semanticLabel: 'Volume',
          autofocus: true,
          onChanged: (value) => requested = value,
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(requested, 6);
    final node = tester.getSemantics(find.byType(WpSlider));
    expect(node.label, 'Volume');
    expect(node.value, '5');
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    semantics.dispose();
  });

  testWidgets('RTL reverses pointer-to-value direction', (tester) async {
    double? requested;
    await tester.pumpWidget(
      _host(
        WpSlider(
          min: 0,
          max: 100,
          value: 35,
          onChanged: (value) => requested = value,
        ),
        direction: TextDirection.rtl,
      ),
    );
    final origin = tester.getTopLeft(find.byType(WpSlider));
    await tester.tapAt(origin + const Offset(438, 42));
    expect(requested, 0);
  });

  testWidgets('semantic increase remains numeric in RTL', (tester) async {
    double? requested;
    await tester.pumpWidget(
      _host(
        WpSlider(
          value: 5,
          onChanged: (value) => requested = value,
        ),
        direction: TextDirection.rtl,
      ),
    );
    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(WpSlider),
            matching: find.byType(Semantics),
          )
          .first,
    );
    semantics.properties.onIncrease!();
    expect(requested, 6);
  });
}
