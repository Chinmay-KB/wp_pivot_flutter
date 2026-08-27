import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
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
  group('WpPivotView native interaction', () {
    for (final collection in ['core-01', 'confirmation-01', 'header-01']) {
      testWidgets('matches selection outcomes for recorded $collection inputs',
          (tester) async {
        final fonts = FontLoader(wpPivotFontFamily);
        for (final name in ['selawksl.ttf', 'selawk.ttf', 'selawksb.ttf']) {
          fonts.addFont(Future.value(ByteData.sublistView(
              File('assets/fonts/$name').readAsBytesSync())));
        }
        await fonts.load();
        tester.view.physicalSize = const Size(480, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final mismatches = <String>[];
        final files = Directory('research/pivot/$collection')
            .listSync()
            .whereType<Directory>()
            .map((d) => File('${d.path}/replay.json'))
            .where((f) => f.existsSync())
            .toList();
        expect(files.length, collection == 'header-01' ? 9 : 21);
        for (final file in files) {
          final data =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
          final controller = PivotController(length: 4);
          final actual = <int>[];
          controller.addListener(() => actual.add(controller.index));
          await tester.pumpWidget(MaterialApp(
              home: WpPivotView(
            key: ValueKey(file.path),
            title: 'PIVOT RESEARCH',
            controller: controller,
            tabTitles: const ['first', 'second', 'third', 'fourth'],
            children: List.generate(4, (_) => const SizedBox.expand()),
          )));
          await tester.pumpAndSettle();
          var previous = 0;
          TestGesture? gesture;
          for (final e in data['events'] as List) {
            final us = ((e['t_ms'] as num) * 1000).round();
            await tester.pump(Duration(microseconds: us - previous));
            previous = us;
            final point =
                Offset((e['x'] as num).toDouble(), (e['y'] as num).toDouble());
            final time = Duration(microseconds: us);
            switch (e['event']) {
              case 'down':
                gesture = await tester.createGesture();
                await gesture.down(point, timeStamp: time);
              case 'move':
                await gesture!.moveTo(point, timeStamp: time);
              case 'up':
                await gesture!.up(timeStamp: time);
                gesture = null;
            }
            // Start scheduled tickers at this event's time. Without this frame,
            // a long gap before the next contact incorrectly starts the previous
            // animation at that later contact rather than letting it complete.
            await tester.pump();
          }
          await tester.pumpAndSettle();
          final expected = [
            for (final s in data['selection_events'] as List) s['index'] as int
          ];
          if (actual.join(',') != expected.join(',')) {
            mismatches.add(
                '${data['source_trial']}: expected $expected, got $actual');
          }
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
        }
        expect(mismatches, isEmpty, reason: mismatches.join('\n'));
      });
    }

    Widget scene(
            {PivotController? controller,
            bool reduced = false,
            int length = 3,
            Key? key}) =>
        MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: child!),
          home: WpPivotView(
              key: key,
              title: 'research',
              controller: controller,
              tabTitles: ['a', 'b', 'c'].take(length).toList(),
              children: List.generate(
                  length, (i) => SizedBox.expand(key: ValueKey('page-$i')))),
        );

    Future<void> viewport(WidgetTester tester) async {
      tester.view.physicalSize = const Size(480, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('header tap commits once and exits before incoming content',
        (tester) async {
      await viewport(tester);
      final controller = PivotController(length: 3);
      var changes = 0;
      controller.addListener(() => changes++);
      await tester.pumpWidget(scene(controller: controller));
      await tester.tap(find.text('b'));
      await tester.pump();
      expect(controller.index, 1);
      expect(changes, 1);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
      expect(tester.getTopLeft(find.byKey(const ValueKey('page-0'))).dx,
          lessThan(0));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
      expect(tester.getTopLeft(find.byKey(const ValueKey('page-1'))).dx,
          greaterThan(0));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const ValueKey('page-1'))).dx, 0);
    });

    testWidgets('drag tracks without selecting early, then cancels',
        (tester) async {
      await viewport(tester);
      final controller = PivotController(length: 3);
      await tester.pumpWidget(scene(controller: controller));
      final initialHeader = tester.getTopLeft(find.text('a')).dx;
      final gesture = await tester.startGesture(const Offset(350, 500));
      await gesture.moveTo(const Offset(325, 500),
          timeStamp: const Duration(milliseconds: 100));
      await tester.pump();
      await gesture.moveTo(const Offset(290, 500),
          timeStamp: const Duration(milliseconds: 400));
      await gesture.moveTo(const Offset(275, 500),
          timeStamp: const Duration(milliseconds: 500));
      await tester.pump();
      expect(controller.index, 0);
      expect(tester.getTopLeft(find.text('a')).dx, lessThan(initialHeader));
      expect(tester.getTopLeft(find.byKey(const ValueKey('page-0'))).dx,
          lessThan(0));
      await gesture.up(timeStamp: const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(controller.index, 0);
      expect(tester.getTopLeft(find.byKey(const ValueKey('page-0'))).dx, 0);
    });

    testWidgets('long drag commits on release and previous wraps',
        (tester) async {
      await viewport(tester);
      final controller = PivotController(length: 3);
      await tester.pumpWidget(scene(controller: controller));
      final gesture = await tester.startGesture(const Offset(420, 500));
      await gesture.moveTo(const Offset(390, 500),
          timeStamp: const Duration(milliseconds: 100));
      await gesture.moveTo(const Offset(80, 500),
          timeStamp: const Duration(milliseconds: 800));
      await tester.pump();
      expect(controller.index, 0);
      await gesture.up(timeStamp: const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      expect(controller.index, 1);
      controller.animateTo(0);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(controller.index, 2);
    });

    testWidgets('reduced motion keeps selection but removes spatial travel',
        (tester) async {
      await viewport(tester);
      final controller = PivotController(length: 3);
      await tester.pumpWidget(scene(controller: controller, reduced: true));
      await tester.tap(find.text('b'));
      await tester.pump();
      expect(controller.index, 1);
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
      expect(tester.getTopLeft(find.byKey(const ValueKey('page-1'))).dx, 0);
    });

    testWidgets(
        'controller replacement and shrinking an owned collection are safe',
        (tester) async {
      await viewport(tester);
      final first = PivotController(length: 3);
      final second = PivotController(length: 3, initialIndex: 2);
      final key = GlobalKey();
      await tester.pumpWidget(scene(key: key, controller: first));
      await tester.pumpWidget(scene(key: key, controller: second));
      first.animateTo(1);
      await tester.pumpAndSettle();
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 2);
      await tester.pumpWidget(scene(key: key));
      await tester.pumpWidget(scene(key: key, length: 1));
      await tester.pumpAndSettle();
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('vertical scrolling retains its position across page selection',
        (tester) async {
      await viewport(tester);
      final pivot = PivotController(length: 2);
      final scroll = ScrollController();
      await tester.pumpWidget(MaterialApp(
          home: WpPivotView(
        title: 'research',
        controller: pivot,
        tabTitles: const ['a', 'b'],
        children: [
          ListView.builder(
              controller: scroll,
              itemExtent: 80,
              itemCount: 30,
              itemBuilder: (_, i) => Text('row $i')),
          const SizedBox.expand()
        ],
      )));
      await tester.drag(find.byType(ListView), const Offset(0, -280));
      await tester.pumpAndSettle();
      final position = scroll.offset;
      expect(position, greaterThan(100));
      expect(pivot.index, 0);
      pivot.animateTo(1);
      await tester.pumpAndSettle();
      pivot.animateTo(0);
      await tester.pumpAndSettle();
      expect(scroll.offset, position);
      await tester.pumpWidget(const SizedBox());
      scroll.dispose();
      pivot.dispose();
    });

    testWidgets('compact viewport and enlarged text do not break header layout',
        (tester) async {
      await viewport(tester);
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 480,
              height: 30,
              child: WpPivotView(
                  title: 'research',
                  tabTitles: ['a', 'b'],
                  children: [SizedBox(), SizedBox()]),
            )),
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('custom long header motion is not truncated by body completion',
        (tester) async {
      await viewport(tester);
      await tester.pumpWidget(const MaterialApp(
          home: WpPivotView(
        title: 'research',
        tabTitles: ['a', 'b'],
        motion: PivotMotion(
            headerDuration: Duration(milliseconds: 900),
            exitDuration: Duration(milliseconds: 50),
            enterDuration: Duration(milliseconds: 50)),
        children: [SizedBox(), SizedBox()],
      )));
      await tester.tap(find.text('b'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getTopLeft(find.text('b')).dx, greaterThan(21));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('b')).dx, closeTo(21, .01));
    });

    testWidgets('non-wrapping keyboard navigation stops at each boundary',
        (tester) async {
      await viewport(tester);
      final pivot = PivotController(length: 2);
      await tester.pumpWidget(MaterialApp(
          home: WpPivotView(
        title: 'research',
        controller: pivot,
        wrap: false,
        tabTitles: const ['a', 'b'],
        children: const [SizedBox(), SizedBox()],
      )));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(pivot.index, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(pivot.index, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(pivot.index, 1);
    });
  });

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
