import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';

Widget _wrap(GlobalKey key, {PivotController? controller}) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      appBar: WpPivot(
        key: key,
        controller: controller,
        tabTitles: const ['one', 'two', 'three'],
        title: 'title',
      ),
    ),
  );
}

void main() {
  group('PivotController', () {
    test('starts at initialIndex and tracks previousIndex', () {
      final controller = PivotController(length: 3, initialIndex: 2);
      expect(controller.index, 2);
      expect(controller.previousIndex, 0);

      expect(controller.previous(), isTrue);
      expect(controller.index, 1);
      expect(controller.previousIndex, 2);
    });

    test('next and previous respect bounds', () {
      final controller = PivotController(length: 3);

      expect(controller.next(), isTrue);
      expect(controller.next(), isTrue);
      expect(controller.canGoNext, isFalse);
      expect(controller.next(), isFalse);
      expect(controller.index, 2);

      expect(controller.previous(), isTrue);
      expect(controller.previous(), isTrue);
      expect(controller.canGoPrevious, isFalse);
      expect(controller.previous(), isFalse);
      expect(controller.index, 0);
    });

    test('animateTo clamps out-of-range indices', () {
      final controller = PivotController(length: 3);

      expect(controller.animateTo(99), isTrue);
      expect(controller.index, 2);

      expect(controller.animateTo(-5), isTrue);
      expect(controller.index, 0);
    });

    test('notifies listeners only on actual changes', () {
      final controller = PivotController(length: 3);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.animateTo(1);
      controller.animateTo(1);
      controller.next();
      expect(notifications, 2);
    });
  });

  group('WpPivot', () {
    testWidgets('renders all tab titles and uppercased pivot title',
        (tester) async {
      await tester.pumpWidget(_wrap(GlobalKey()));

      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
      expect(find.text('three'), findsOneWidget);
      expect(find.text('TITLE'), findsOneWidget);
    });

    testWidgets('follows an external controller without a GlobalKey',
        (tester) async {
      final controller = PivotController(length: 3);
      await tester.pumpWidget(_wrap(GlobalKey(), controller: controller));

      Color colorOf(String label) =>
          tester.widget<Text>(find.text(label)).style!.color!;

      expect(colorOf('one'), Colors.white);
      expect(colorOf('two'), Colors.white54);

      controller.animateTo(1);
      await tester.pumpAndSettle();

      expect(colorOf('one'), Colors.white54);
      expect(colorOf('two'), Colors.white);
    });

    testWidgets('asserts when controller length mismatches tab titles',
        (tester) async {
      final controller = PivotController(length: 5);

      await tester.pumpWidget(_wrap(GlobalKey(), controller: controller));

      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('scrolls tab bar to keep selection visible', (tester) async {
      final controller = PivotController(length: 8);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: WpPivot(
            controller: controller,
            tabTitles: const [
              'one',
              'two',
              'three',
              'four',
              'five',
              'six',
              'seven',
              'eight',
            ],
            title: 'title',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Off-screen tabs are not built by the lazy list.
      expect(find.text('eight'), findsNothing);

      controller.animateTo(7);
      await tester.pumpAndSettle();

      expect(find.text('eight'), findsOneWidget);
    });
  });
}
