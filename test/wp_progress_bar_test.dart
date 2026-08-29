import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

Widget _host(Widget child, {bool reducedMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 456, child: child),
        ),
      ),
    );

void main() {
  testWidgets('determinate geometry is 4 px with native horizontal padding',
      (tester) async {
    await tester.pumpWidget(_host(const WpProgressBar(value: .42)));
    final paint = find.byKey(const ValueKey('wp-progress-determinate'));
    expect(tester.getSize(paint), const Size(432, 4));
    final painter = tester.widget<CustomPaint>(paint).painter
        as WpDeterminateProgressPainter;
    expect(painter.value, .42);
    expect(painter.backgroundColor, const Color(0x19ffffff));
  });

  test('indeterminate anatomy is five 4x4 marks', () {
    const painter = WpIndeterminateProgressPainter(
      phase: .4,
      color: Color(0xff1ba1e2),
      reducedMotion: false,
    );
    final rects = painter.markRects(const Size(432, 4));
    expect(rects, hasLength(5));
    expect(rects.every((rect) => rect.size == const Size(4, 4)), isTrue);
  });

  test('indeterminate burst has a blank interval before its conservative loop',
      () {
    const painter = WpIndeterminateProgressPainter(
      phase: .9,
      color: Color(0xff1ba1e2),
      reducedMotion: false,
    );
    expect(
      painter.markRects(const Size(432, 4)).every((rect) => rect.left < 0),
      isTrue,
    );
  });

  testWidgets('semantics distinguish determinate and indeterminate values',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const WpProgressBar(value: .42, semanticLabel: 'Download')),
    );
    var node = tester.getSemantics(find.byType(WpProgressBar));
    expect(node.label, 'Download');
    expect(node.value, '42%');
    await tester.pumpWidget(
      _host(const WpProgressBar(semanticLabel: 'Download')),
    );
    node = tester.getSemantics(find.byType(WpProgressBar));
    expect(node.value, 'In progress');
    handle.dispose();
  });

  testWidgets('reduced motion freezes a centered five-mark status motif',
      (tester) async {
    await tester.pumpWidget(
      _host(const WpProgressBar(), reducedMotion: true),
    );
    final paint = find.byKey(const ValueKey('wp-progress-indeterminate'));
    final before = tester.widget<CustomPaint>(paint).painter
        as WpIndeterminateProgressPainter;
    expect(before.reducedMotion, isTrue);
    final beforeRects = before.markRects(const Size(432, 4));
    await tester.pump(const Duration(seconds: 1));
    final after = tester.widget<CustomPaint>(paint).painter
        as WpIndeterminateProgressPainter;
    expect(after.markRects(const Size(432, 4)), beforeRects);
  });

  testWidgets('switching modes starts and stops without stale frames',
      (tester) async {
    await tester.pumpWidget(_host(const WpProgressBar()));
    final before = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('wp-progress-indeterminate')),
        )
        .painter as WpIndeterminateProgressPainter;
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('wp-progress-indeterminate')),
        findsOneWidget);
    final after = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('wp-progress-indeterminate')),
        )
        .painter as WpIndeterminateProgressPainter;
    expect(after.phase, greaterThan(before.phase));
    await tester.pumpWidget(_host(const WpProgressBar(value: 1)));
    expect(
        find.byKey(const ValueKey('wp-progress-determinate')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
