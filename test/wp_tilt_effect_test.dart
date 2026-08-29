import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

Widget _host(Widget child, {bool reducedMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Center(child: child),
      ),
    );

Matrix4 _matrix(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(const ValueKey('wp-tilt-transform')))
    .transform;

void main() {
  test('center, edge and corner poses follow the Toolkit formula', () {
    final center = WpTiltGeometry.poseFor(const Offset(.5, .5));
    expect(center.rotationX, 0);
    expect(center.rotationY, 0);
    expect(center.depression, 25);

    final edge = WpTiltGeometry.poseFor(const Offset(0, .5));
    expect(edge.rotationX, 0);
    expect(edge.rotationY, closeTo(.15, 1e-12));
    expect(edge.depression, 12.5);

    final corner = WpTiltGeometry.poseFor(Offset.zero);
    expect(corner.rotationX, closeTo(-.15, 1e-12));
    expect(corner.rotationY, closeTo(.15, 1e-12));
    expect(corner.depression, 0);
  });

  test('native fixture press coordinates reproduce recorded plateau poses', () {
    // The TiltEffect wraps the native Button's 456x72 outer control at (12,412).
    final center = WpTiltGeometry.poseFor(
      const Offset((234 - 12) / 456, (448 - 412) / 72),
    );
    expect(center.rotationX * 180 / 3.141592653589793, closeTo(0, .0001));
    expect(center.rotationY * 180 / 3.141592653589793, closeTo(.2262, .0001));
    expect(center.depression, closeTo(24.6711, .0001));

    final corner = WpTiltGeometry.poseFor(
      const Offset((40 - 12) / 456, (434 - 412) / 72),
    );
    expect(corner.rotationX * 180 / 3.141592653589793, closeTo(-3.3423, .0001));
    expect(corner.rotationY * 180 / 3.141592653589793, closeTo(7.5389, .0001));
    expect(corner.depression, closeTo(9.1740, .0001));
  });

  testWidgets('held center press depresses immediately then returns 200+100 ms',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const WpTiltEffect(
          child: SizedBox(width: 240, height: 72),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getRect(find.byType(WpTiltEffect)).center,
    );
    await tester.pump();
    expect(_matrix(tester).storage[14], closeTo(-25, .001));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 199));
    expect(_matrix(tester).storage[14], closeTo(-25, .001));
    await tester.pump(const Duration(milliseconds: 1));
    expect(_matrix(tester).storage[14], closeTo(-25, .001));
    await tester.pump(const Duration(milliseconds: 50));
    expect(_matrix(tester).storage[14], closeTo(-12.5, 1));
    await tester.pump(const Duration(milliseconds: 50));
    expect(_matrix(tester), Matrix4.identity());
  });

  testWidgets('reduced motion keeps the identity transform', (tester) async {
    await tester.pumpWidget(
      _host(
        const WpTiltEffect(child: SizedBox(width: 240, height: 72)),
        reducedMotion: true,
      ),
    );
    final gesture = await tester.startGesture(
      tester.getRect(find.byType(WpTiltEffect)).topLeft + const Offset(2, 2),
    );
    await tester.pump();
    expect(_matrix(tester), Matrix4.identity());
    await gesture.up();
  });

  testWidgets('pointer observation does not consume the child tap',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        WpTiltEffect(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox(width: 240, height: 72),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(GestureDetector));
    expect(taps, 1);
  });
}
