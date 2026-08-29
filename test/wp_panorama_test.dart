import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/src/wp_panorama.dart';

List<WpPanoramaItem> items(int count) => List.generate(
      count,
      (index) => WpPanoramaItem(
        header: 'item $index',
        child: ColoredBox(
          color: Colors.primaries[index % Colors.primaries.length],
          child: Center(child: Text('page $index')),
        ),
      ),
    );

Widget scene({
  int count = 3,
  ValueChanged<int>? onChanged,
  bool reducedMotion = false,
  String title = 'panorama',
}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: SizedBox.expand(
          child: WpPanorama(
            title: title,
            items: items(count),
            onChanged: onChanged,
          ),
        ),
      ),
    );

Future<void> viewport(WidgetTester tester,
    {double width = 480, double height = 800}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Rect itemRect(WidgetTester tester, int index) =>
    tester.getRect(find.byKey(ValueKey('wp-panorama-item-$index')));

Rect contentRect(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey('panorama-content-marker')));

void main() {
  testWidgets('drag commits once and leaves the next item partially visible',
      (tester) async {
    await viewport(tester);
    final changes = <int>[];
    await tester.pumpWidget(scene(onChanged: changes.add));

    expect(find.text('item 1'), findsOneWidget);
    final gesture = await tester.startGesture(const Offset(410, 500));
    await gesture.moveTo(const Offset(80, 500));
    await gesture.up();
    await tester.pump();

    expect(changes, [1]);
    await tester.pumpAndSettle();
    expect(find.text('page 1'), findsOneWidget);
  });

  testWidgets('small drag cancels and flicks and wraps commit', (tester) async {
    await viewport(tester);
    final changes = <int>[];
    await tester.pumpWidget(scene(onChanged: changes.add));

    await tester.dragFrom(const Offset(320, 500), const Offset(-35, 0));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);

    final previous = await tester.startGesture(const Offset(80, 500));
    await previous.moveTo(const Offset(430, 500),
        timeStamp: const Duration(milliseconds: 80));
    await previous.up(timeStamp: const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(changes, [2]);
  });

  testWidgets('a substantial cancelled drag does not commit selection',
      (tester) async {
    await viewport(tester);
    final changes = <int>[];
    await tester.pumpWidget(scene(onChanged: changes.add));

    final gesture = await tester.startGesture(const Offset(410, 500));
    await gesture.moveTo(const Offset(80, 500));
    await gesture.cancel();
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(find.text('page 0'), findsOneWidget);
  });

  testWidgets('both pan directions travel toward their incoming item',
      (tester) async {
    await viewport(tester);
    await tester.pumpWidget(scene());

    final next = await tester.startGesture(const Offset(410, 500));
    await next.moveTo(const Offset(80, 500));
    await next.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('wp-panorama-item-0'))).dx,
        lessThan(24));
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('wp-panorama-item-1'))).dx,
        greaterThan(24));
    await tester.pumpAndSettle();

    final previous = await tester.startGesture(const Offset(80, 500));
    await previous.moveTo(const Offset(410, 500));
    await previous.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('wp-panorama-item-1'))).dx,
        greaterThan(24));
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('wp-panorama-item-0'))).dx,
        lessThan(24));
    await tester.pumpAndSettle();

    final wrap = await tester.startGesture(const Offset(80, 500));
    await wrap.moveTo(const Offset(410, 500));
    await wrap.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('wp-panorama-item-0'))).dx,
        greaterThan(24));
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('wp-panorama-item-2'))).dx,
        lessThan(24));
  });

  testWidgets('visible next-panel sliver is tappable', (tester) async {
    await viewport(tester);
    final changes = <int>[];
    await tester.pumpWidget(scene(onChanged: changes.add));

    await tester.tapAt(const Offset(468, 500));
    await tester.pumpAndSettle();
    expect(changes, [1]);
  });

  testWidgets('keyboard arrows navigate cyclically', (tester) async {
    await viewport(tester);
    final changes = <int>[];
    await tester.pumpWidget(scene(onChanged: changes.add));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(changes, [2]);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(changes, [2, 0]);
  });

  testWidgets('reduced motion commits without waiting for spatial animation',
      (tester) async {
    await viewport(tester);
    final changes = <int>[];
    await tester.pumpWidget(scene(reducedMotion: true, onChanged: changes.add));

    await tester.dragFrom(const Offset(410, 500), const Offset(-280, 0));
    await tester.pump();
    expect(changes, [1]);
    expect(find.text('page 1'), findsOneWidget);
  });

  testWidgets('a new drag interrupts an in-flight transition safely',
      (tester) async {
    await viewport(tester);
    final changes = <int>[];
    await tester.pumpWidget(scene(onChanged: changes.add));

    await tester.dragFrom(const Offset(410, 500), const Offset(-280, 0));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.dragFrom(const Offset(80, 500), const Offset(280, 0));
    await tester.pumpAndSettle();

    expect(changes, [1, 0]);
    expect(find.text('page 0'), findsOneWidget);
  });

  testWidgets('parent rebuild from onChanged does not cancel the pan',
      (tester) async {
    await viewport(tester);
    await tester.pumpWidget(const _RebuildingPanorama());

    final gesture = await tester.startGesture(const Offset(410, 500));
    await gesture.moveTo(const Offset(80, 500));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
        tester.getTopLeft(find.byKey(const ValueKey('wp-panorama-item-0'))).dx,
        lessThan(24));
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('wp-panorama-item-1'))).dx,
        greaterThan(24));
  });

  testWidgets('item child state survives forward, backward, and a full cycle',
      (tester) async {
    await viewport(tester);
    await tester.pumpWidget(MaterialApp(
      home: WpPanorama(
        title: 'panorama',
        items: [
          WpPanoramaItem(
              header: 'first',
              child: _CounterPage(
                  key: const ValueKey('ordinary-counter-0'), id: 0)),
          WpPanoramaItem(
              header: 'second',
              child: _CounterPage(
                  key: const ValueKey('ordinary-counter-1'), id: 1)),
          WpPanoramaItem(
              header: 'third',
              child: _CounterPage(
                  key: const ValueKey('ordinary-counter-2'), id: 2)),
        ],
      ),
    ));
    final firstFinder =
        find.byKey(const ValueKey('ordinary-counter-0'), skipOffstage: false);
    final firstState = tester.state<_CounterPageState>(firstFinder);
    await tester.tap(find.byKey(const ValueKey('counter-0')));
    await tester.pump();
    expect(firstState.count, 1);

    Future<void> swipe(Offset from, Offset to) async {
      final gesture = await tester.startGesture(from);
      await gesture.moveTo(to);
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await swipe(const Offset(410, 700), const Offset(80, 700));
    await swipe(const Offset(80, 700), const Offset(410, 700));
    expect(tester.state<_CounterPageState>(firstFinder), same(firstState));
    expect(firstState.count, 1);

    await swipe(const Offset(410, 700), const Offset(80, 700));
    await swipe(const Offset(410, 700), const Offset(80, 700));
    await swipe(const Offset(410, 700), const Offset(80, 700));
    expect(tester.state<_CounterPageState>(firstFinder), same(firstState));
    expect(firstState.count, 1);
    expect(find.text('counter 0: 1'), findsOneWidget);
  });

  testWidgets('title and background remain continuous when a pan settles',
      (tester) async {
    await viewport(tester);
    await tester.pumpWidget(MaterialApp(
      home: WpPanorama(
        title: 'panorama',
        background: const SizedBox(key: ValueKey('panorama-background')),
        items: items(3),
      ),
    ));
    final initialTitle = tester.getTopLeft(find.text('panorama')).dx;

    final gesture = await tester.startGesture(const Offset(410, 500));
    await gesture.moveTo(const Offset(80, 500));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    final titleBeforeSettle = tester.getTopLeft(find.text('panorama')).dx;
    final backgroundBeforeSettle =
        tester.getTopLeft(find.byKey(const ValueKey('panorama-background'))).dx;
    await tester.pump(const Duration(milliseconds: 20));

    expect(tester.getTopLeft(find.text('panorama')).dx,
        closeTo(titleBeforeSettle, 2));
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('panorama-background'))).dx,
        closeTo(backgroundBeforeSettle, 2));
    expect(tester.getTopLeft(find.text('panorama')).dx, lessThan(initialTitle));
  });

  testWidgets('many forward cycles retain a visible title segment',
      (tester) async {
    await viewport(tester);
    await tester.pumpWidget(scene());

    for (var i = 0; i < 9; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }

    final title = tester.getRect(find.text('panorama'));
    expect(title.right, greaterThan(0));
    expect(title.left, lessThan(480));
  });

  testWidgets('nondefault content parallax reaches its exact item rest',
      (tester) async {
    await viewport(tester);
    await tester.pumpWidget(MaterialApp(
      home: WpPanorama(
        title: 'panorama',
        motion: const WpPanoramaMotion(contentParallax: 1.5),
        items: items(3),
      ),
    ));

    final gesture = await tester.startGesture(const Offset(410, 500));
    await gesture.moveTo(const Offset(80, 500));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    final incomingBeforeSettle =
        tester.getTopLeft(find.byKey(const ValueKey('wp-panorama-item-1'))).dx;
    expect(incomingBeforeSettle, closeTo(24, 2));
    await tester.pump(const Duration(milliseconds: 20));
    final incomingAfterSettle =
        tester.getTopLeft(find.byKey(const ValueKey('wp-panorama-item-1'))).dx;
    expect(incomingAfterSettle, closeTo(24, 2));
    expect(incomingAfterSettle, closeTo(incomingBeforeSettle, 2));
  });

  testWidgets('empty and one-item panoramas stay bounded', (tester) async {
    await viewport(tester, width: 320);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(scene(count: 0));
      expect(find.bySemanticsLabel('panorama, empty panorama'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(scene(count: 1));
      await tester.dragFrom(const Offset(260, 500), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(find.text('page 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('shrinking items clamps an active selection', (tester) async {
    await viewport(tester);
    final key = GlobalKey<_DynamicPanoramaState>();
    await tester.pumpWidget(_DynamicPanorama(key: key));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    key.currentState!.setCount(1);
    await tester.pumpAndSettle();

    expect(find.text('page 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact width and enlarged text keep the title bounded',
      (tester) async {
    await viewport(tester, width: 320, height: 533);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: SizedBox.expand(
          child: WpPanorama(
            title: 'a deliberately long panorama title',
            items: [
              WpPanoramaItem(
                header: 'a long header',
                child: ColoredBox(
                  key: const ValueKey('panorama-content-marker'),
                  color: Colors.blue,
                  child: const SizedBox(height: 64, width: double.infinity),
                ),
              ),
            ],
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    final title =
        tester.getRect(find.text('a deliberately long panorama title'));
    expect(title.right, greaterThan(0));
    expect(title.left, lessThan(320));
    final header = tester.getRect(find.text('a long header'));
    expect(header.top, greaterThanOrEqualTo(72));
    final content = contentRect(tester);
    expect(content.height, greaterThanOrEqualTo(32));
    expect(content.bottom, lessThanOrEqualTo(533));
  });

  testWidgets('reference viewport matches native header and peek geometry',
      (tester) async {
    await viewport(tester);
    await tester.pumpWidget(MaterialApp(
      home: WpPanorama(
        title: 'panorama',
        items: items(3),
      ),
    ));

    expect(itemRect(tester, 0).left, closeTo(24, 2));
    expect(itemRect(tester, 0).top, closeTo(191, 4));
    expect(itemRect(tester, 1).left, closeTo(456, 4));
    expect(itemRect(tester, 0).width, closeTo(396, 4));
  });

  testWidgets('narrow and wide viewports keep proportional panel geometry',
      (tester) async {
    await viewport(tester, width: 320, height: 533);
    await tester.pumpWidget(MaterialApp(
      home: WpPanorama(title: 'panorama', items: items(3)),
    ));
    expect(itemRect(tester, 0).left, closeTo(16, 2));
    expect(itemRect(tester, 0).width, closeTo(264, 4));
    expect(
        itemRect(tester, 1).left - itemRect(tester, 0).left, closeTo(288, 4));

    await viewport(tester, width: 640, height: 800);
    await tester.pumpWidget(MaterialApp(
      home: WpPanorama(title: 'panorama', items: items(3)),
    ));
    expect(itemRect(tester, 0).left, closeTo(24, 2));
    expect(itemRect(tester, 0).width, closeTo(556, 4));
  });

  testWidgets('landscape and short heights preserve usable child space',
      (tester) async {
    await viewport(tester, width: 800, height: 480);
    await tester.pumpWidget(MaterialApp(
      home: WpPanorama(
        title: 'panorama',
        items: [
          WpPanoramaItem(
            header: 'first',
            child: ColoredBox(
              key: const ValueKey('panorama-content-marker'),
              color: Colors.blue,
              child: const SizedBox(height: 64, width: double.infinity),
            ),
          ),
        ],
      ),
    ));

    final content = contentRect(tester);
    expect(content.height, greaterThanOrEqualTo(48));
    expect(content.bottom, lessThanOrEqualTo(480));
    final itemTop = itemRect(tester, 0).top;
    // Main title band ends ~110 logical px at 800×480 with layoutScale 0.6.
    expect(itemTop, greaterThan(108));
    final header = tester.getRect(find.text('first'));
    expect(header.top, greaterThanOrEqualTo(itemTop - 1));
    expect(header.top, lessThan(itemTop + 24));

    await viewport(tester, width: 480, height: 320);
    await tester.pumpWidget(MaterialApp(
      home: WpPanorama(
        title: 'panorama',
        items: [
          WpPanoramaItem(
            header: 'first',
            child: ColoredBox(
              key: const ValueKey('panorama-content-marker'),
              color: Colors.blue,
              child: const SizedBox(height: 64, width: double.infinity),
            ),
          ),
        ],
      ),
    ));
    expect(contentRect(tester).height, greaterThanOrEqualTo(32));
  });

  testWidgets(
      'backward wrap from first page reveals the last item from the left',
      (tester) async {
    await viewport(tester);
    final changes = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: WpPanorama(
        title: 'panorama',
        background: const SizedBox(key: ValueKey('panorama-background')),
        items: items(3),
        onChanged: changes.add,
      ),
    ));

    final initialTitle = tester.getTopLeft(find.text('panorama')).dx;
    final gesture = await tester.startGesture(const Offset(85, 500));
    await gesture.moveTo(const Offset(405, 500),
        timeStamp: const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
        tester.getTopLeft(find.byKey(const ValueKey('wp-panorama-item-2'))).dx,
        lessThan(24));
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('wp-panorama-item-0'))).dx,
        greaterThan(24));
    final titleMidDrag = tester.getTopLeft(find.text('panorama')).dx;
    expect(titleMidDrag, greaterThan(initialTitle));

    await gesture.up(timeStamp: const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(changes, [2]);
    expect(find.text('page 2'), findsOneWidget);
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('wp-panorama-item-2'))).dx,
        closeTo(24, 2));
    final settledTitle = tester.getTopLeft(find.text('panorama')).dx;
    expect(
      settledTitle,
      lessThan(initialTitle - 40),
      reason: 'last-item title rest shows the tail, not the first-page phase',
    );
    expect(settledTitle, lessThan(50));
    final settledBackground =
        tester.getTopLeft(find.byKey(const ValueKey('panorama-background'))).dx;
    expect(
      settledBackground,
      lessThan(0),
      reason: 'background must share the last-item layer phase after wrap',
    );
  });

  testWidgets('intentional title crop does not remove all visible glyphs',
      (tester) async {
    await viewport(tester);
    await tester.pumpWidget(MaterialApp(
      home: WpPanorama(
        title: 'panorama',
        items: items(1),
      ),
    ));

    final title = tester.getRect(find.text('panorama'));
    expect(title.right, greaterThan(12));
    expect(title.left, lessThan(200));
  });
}

class _DynamicPanorama extends StatefulWidget {
  const _DynamicPanorama({super.key});

  @override
  State<_DynamicPanorama> createState() => _DynamicPanoramaState();
}

class _DynamicPanoramaState extends State<_DynamicPanorama> {
  int count = 3;

  void setCount(int value) => setState(() => count = value);

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: WpPanorama(title: 'panorama', items: items(count)),
      );
}

class _RebuildingPanorama extends StatefulWidget {
  const _RebuildingPanorama();

  @override
  State<_RebuildingPanorama> createState() => _RebuildingPanoramaState();
}

class _RebuildingPanoramaState extends State<_RebuildingPanorama> {
  var callbacks = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: WpPanorama(
          title: 'panorama',
          items: items(3),
          onChanged: (_) => setState(() => callbacks++),
        ),
      );
}

class _CounterPage extends StatefulWidget {
  const _CounterPage({super.key, required this.id});

  final int id;

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  var count = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
        key: ValueKey('counter-${widget.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => count++),
        child: Center(child: Text('counter ${widget.id}: $count')),
      );
}
