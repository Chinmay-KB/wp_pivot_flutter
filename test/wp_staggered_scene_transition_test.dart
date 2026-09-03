import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

void main() {
  test('exit and entry reverse their stagger order', () {
    final firstExit = WpStaggeredSceneGeometry.awayProgress(
      progress: 0.2,
      order: 0,
      maxOrder: 3,
      staggerFraction: 0.08,
      direction: WpSceneTransitionDirection.exit,
    );
    final delayedExit = WpStaggeredSceneGeometry.awayProgress(
      progress: 0.2,
      order: 3,
      maxOrder: 3,
      staggerFraction: 0.08,
      direction: WpSceneTransitionDirection.exit,
    );
    expect(firstExit, greaterThan(delayedExit));

    final firstEntry = WpStaggeredSceneGeometry.awayProgress(
      progress: 0.8,
      order: 0,
      maxOrder: 3,
      staggerFraction: 0.08,
      direction: WpSceneTransitionDirection.enter,
    );
    final delayedEntry = WpStaggeredSceneGeometry.awayProgress(
      progress: 0.8,
      order: 3,
      maxOrder: 3,
      staggerFraction: 0.08,
      direction: WpSceneTransitionDirection.enter,
    );
    expect(firstEntry, lessThan(delayedEntry));
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
    expect(transform.alignment, Alignment.center);
    expect(opacity.opacity, 1);
  });

  testWidgets('uses a caller-selected transform origin', (tester) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      value: 0.5,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: WpStaggeredSceneTransition(
          animation: controller,
          order: 0,
          maxOrder: 0,
          alignment: Alignment.centerLeft,
          child: const SizedBox.square(dimension: 99),
        ),
      ),
    );

    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('wp-scene-transform')),
    );
    expect(transform.alignment, Alignment.centerLeft);
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

  testWidgets('page-level entry stays opaque through the swing', (tester) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      value: 0,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: WpStaggeredSceneTransition(
          animation: controller,
          direction: WpSceneTransitionDirection.enter,
          order: 0,
          maxOrder: 0,
          alignment: Alignment.centerRight,
          fade: false,
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
    expect(transform.transform, isNot(Matrix4.identity()));
    expect(transform.alignment, Alignment.centerRight);
    expect(opacity.opacity, 1);
  });
}
