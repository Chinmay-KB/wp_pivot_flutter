import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

void main() {
  test('grid order starts at the right edge', () {
    expect(
      WpStaggeredSceneGeometry.gridExitOrder(
        column: 3,
        columnSpan: 1,
        columns: 4,
      ),
      0,
    );
    expect(
      WpStaggeredSceneGeometry.gridExitOrder(
        column: 0,
        columnSpan: 2,
        columns: 4,
      ),
      2,
    );
    expect(
      WpStaggeredSceneGeometry.gridExitOrder(
        column: 0,
        columnSpan: 2,
        columns: 4,
        row: 4,
      ),
      4,
    );
    expect(
      WpStaggeredSceneGeometry.gridEntryOrder(
        column: 3,
        columnSpan: 1,
        columns: 4,
      ),
      3,
    );
  });

  test('exit and entry reverse their stagger order', () {
    final rightExit = WpStaggeredSceneGeometry.awayProgress(
      progress: 0.2,
      order: 0,
      maxOrder: 3,
      staggerFraction: 0.08,
      direction: WpSceneTransitionDirection.exit,
    );
    final leftExit = WpStaggeredSceneGeometry.awayProgress(
      progress: 0.2,
      order: 3,
      maxOrder: 3,
      staggerFraction: 0.08,
      direction: WpSceneTransitionDirection.exit,
    );
    expect(rightExit, greaterThan(leftExit));

    final rightEntry = WpStaggeredSceneGeometry.awayProgress(
      progress: 0.8,
      order: 0,
      maxOrder: 3,
      staggerFraction: 0.08,
      direction: WpSceneTransitionDirection.enter,
    );
    final leftEntry = WpStaggeredSceneGeometry.awayProgress(
      progress: 0.8,
      order: 3,
      maxOrder: 3,
      staggerFraction: 0.08,
      direction: WpSceneTransitionDirection.enter,
    );
    expect(rightEntry, lessThan(leftEntry));
  });

  testWidgets('rest pose is identity and fully visible', (tester) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 400),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: WpStaggeredSceneTransition(
          animation: controller,
          order: 0,
          maxOrder: 3,
          child: const SizedBox.square(dimension: 99),
        ),
      ),
    );

    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('wp-scene-transform')),
    );
    final opacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('wp-scene-opacity')),
    );
    expect(transform.transform, Matrix4.identity());
    expect(opacity.opacity, 1);
  });

  testWidgets('reduced motion uses opacity without a 3-D transform',
      (tester) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      value: 0.99,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: WpStaggeredSceneTransition(
            animation: controller,
            order: 0,
            maxOrder: 0,
            child: const SizedBox.square(dimension: 99),
          ),
        ),
      ),
    );

    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('wp-scene-transform')),
    );
    final opacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('wp-scene-opacity')),
    );
    expect(transform.transform, Matrix4.identity());
    expect(opacity.opacity, lessThan(1));
  });
}
