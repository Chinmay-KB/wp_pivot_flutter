import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/src/wp_split_surface_view.dart';

Widget _fixture({
  PageController? controller,
  int initialSurface = 0,
  ValueChanged<int>? onSurfaceChanged,
}) {
  return MaterialApp(
    home: SizedBox.expand(
      child: WpSplitSurfaceView(
        controller: controller,
        initialSurface: initialSurface,
        onSurfaceChanged: onSurfaceChanged,
        first: const ColoredBox(
          key: ValueKey<String>('first'),
          color: Colors.blue,
        ),
        second: const ColoredBox(
          key: ValueKey<String>('second'),
          color: Colors.green,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('keeps surfaces exactly one viewport apart during a drag',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_fixture());

    final gesture = await tester.startGesture(const Offset(420, 400));
    await gesture.moveTo(const Offset(240, 400));
    await tester.pump();

    final firstLeft = tester.getRect(find.byKey(const ValueKey('first'))).left;
    final secondLeft =
        tester.getRect(find.byKey(const ValueKey('second'))).left;
    expect(firstLeft, closeTo(-180, 0.01));
    expect(secondLeft - firstLeft, closeTo(480, 0.01));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('commits a long drag and reports the settled surface',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final changes = <int>[];
    await tester.pumpWidget(_fixture(onSurfaceChanged: changes.add));

    await tester.timedDragFrom(
      const Offset(420, 400),
      const Offset(-360, 0),
      const Duration(milliseconds: 900),
    );
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(const ValueKey('second'))).left, 0);
    expect(changes, <int>[1]);
  });

  testWidgets('cancels a short slow drag', (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final changes = <int>[];
    await tester.pumpWidget(_fixture(onSurfaceChanged: changes.add));

    await tester.timedDragFrom(
      const Offset(420, 400),
      const Offset(-80, 0),
      const Duration(milliseconds: 900),
    );
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(const ValueKey('first'))).left, 0);
    expect(changes, isEmpty);
  });

  testWidgets('supports an externally owned controller and inverse navigation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = PageController(initialPage: 1);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_fixture(controller: controller));

    expect(tester.getRect(find.byKey(const ValueKey('second'))).left, 0);
    await tester.timedDragFrom(
      const Offset(60, 400),
      const Offset(360, 0),
      const Duration(milliseconds: 900),
    );
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(const ValueKey('first'))).left, 0);
    expect(controller.page, 0);
  });
}
