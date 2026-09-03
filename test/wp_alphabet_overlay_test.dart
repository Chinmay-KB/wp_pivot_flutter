import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

class _Harness extends StatefulWidget {
  const _Harness({
    this.useSafeArea = true,
    this.withDurations = true,
    this.plainAlphabet = false,
  });

  final bool useSafeArea;
  final bool withDurations;
  final bool plainAlphabet;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration:
        widget.withDurations ? const Duration(milliseconds: 440) : null,
    reverseDuration:
        widget.withDurations ? const Duration(milliseconds: 340) : null,
  );

  bool open = false;
  bool hold = false;
  int appTaps = 0;
  final List<String> selected = <String>[];
  int cancels = 0;

  void setOpen(bool value) => setState(() => open = value);
  void setHold(bool value) => setState(() => hold = value);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WpAlphabetOverlay(
      open: open,
      controller: controller,
      holdBlackOnSelect: hold,
      useSafeArea: widget.useSafeArea,
      onCancel: widget.plainAlphabet ? () => setState(() => cancels++) : null,
      appListChild: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => appTaps++),
        child: const SizedBox.expand(
          child: Center(child: Text('App A')),
        ),
      ),
      alphabetChild: widget.plainAlphabet
          ? const SizedBox.expand(
              child: TextField(autofocus: true),
            )
          : WpAlphabetGrid(
              letters: const <String>['a', 'b'],
              enabledLetters: const <String>{'b'},
              onSelected: selected.add,
              onCancel: () => setState(() => cancels++),
            ),
    );
  }
}

Widget _scene(
  _Harness harness, {
  bool reducedMotion = false,
  EdgeInsets padding = EdgeInsets.zero,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        final data = MediaQuery.of(context);
        return WpPhoneTheme(
          data: const WpPhoneThemeData.dark(),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: MediaQuery(
              data: data.copyWith(
                disableAnimations: reducedMotion,
                padding: padding,
              ),
              child: SizedBox(
                width: 480,
                height: 800,
                child: harness,
              ),
            ),
          ),
        );
      },
    ),
  );
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

double _opacityOf(WidgetTester tester, String text) {
  final opacities = tester.widgetList<Opacity>(
    find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
  );
  return opacities.first.opacity;
}

bool _appListIgnoring(WidgetTester tester) {
  final gates = tester.widgetList<IgnorePointer>(
    find.ancestor(
      of: find.text('App A'),
      matching: find.byType(IgnorePointer),
    ),
  );
  return gates.first.ignoring;
}

bool _gridIgnoring(WidgetTester tester) {
  final gates = tester.widgetList<IgnorePointer>(
    find.ancestor(
      of: find.byType(WpAlphabetGrid),
      matching: find.byType(IgnorePointer),
    ),
  );
  return gates.first.ignoring;
}

void main() {
  test('overlay geometry matches the measured envelope', () {
    expect(
      WpAlphabetOverlayGeometry.forwardDuration,
      const Duration(milliseconds: 440),
    );
    expect(
      WpAlphabetOverlayGeometry.reverseDuration,
      const Duration(milliseconds: 340),
    );
    expect(WpAlphabetOverlayGeometry.appFadeEnd, 0.18);
    expect(WpAlphabetOverlayGeometry.gridFadeStart, 0.20);
    expect(WpAlphabetOverlayGeometry.gridFadeEnd, 0.60);
    expect(WpAlphabetOverlayGeometry.inputProgressThreshold, 0.35);

    expect(WpAlphabetOverlayGeometry.appOpacity(0), moreOrLessEquals(1));
    expect(WpAlphabetOverlayGeometry.appOpacity(0.09), lessThan(1));
    expect(WpAlphabetOverlayGeometry.appOpacity(0.18), moreOrLessEquals(0));
    expect(WpAlphabetOverlayGeometry.appOpacity(1), moreOrLessEquals(0));
    expect(WpAlphabetOverlayGeometry.appSlideOffset(1), moreOrLessEquals(0));
    expect(WpAlphabetOverlayGeometry.appSlideOffset(0), moreOrLessEquals(-12));
    expect(WpAlphabetOverlayGeometry.gridOpacity(0.20), moreOrLessEquals(0));
    expect(WpAlphabetOverlayGeometry.gridOpacity(0.60), moreOrLessEquals(1));
    expect(
      WpAlphabetOverlayGeometry.ignoresAlphabetInput(
        progress: 0.20,
        closing: false,
      ),
      isTrue,
    );
    expect(
      WpAlphabetOverlayGeometry.ignoresAlphabetInput(
        progress: 0.90,
        closing: false,
      ),
      isFalse,
    );
    expect(
      WpAlphabetOverlayGeometry.ignoresAlphabetInput(
        progress: 0.90,
        closing: true,
      ),
      isTrue,
    );
  });

  testWidgets('controller durations default to the measured envelope',
      (tester) async {
    _usePhoneViewport(tester);
    const harness = _Harness(withDurations: false);
    await tester.pumpWidget(_scene(harness));
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(state.controller.duration, const Duration(milliseconds: 440));
    expect(state.controller.reverseDuration, const Duration(milliseconds: 340));
  });

  testWidgets('open envelope slides the app list out and fades the grid in',
      (tester) async {
    _usePhoneViewport(tester);
    const harness = _Harness();
    await tester.pumpWidget(_scene(harness));
    final state = tester.state<_HarnessState>(find.byType(_Harness));

    expect(find.text('App A'), findsOneWidget);
    expect(find.byType(WpAlphabetGrid), findsNothing);
    expect(_appListIgnoring(tester), isFalse);

    state.setOpen(true);
    await tester.pump();
    expect(state.controller.value, moreOrLessEquals(0));
    expect(_opacityOf(tester, 'App A'), moreOrLessEquals(1));
    expect(_opacityOf(tester, 'b'), moreOrLessEquals(0));
    expect(_gridIgnoring(tester), isTrue);

    // The catalog clears across the first 18% of the 440 ms forward run.
    await tester.pump(const Duration(milliseconds: 79));
    expect(_opacityOf(tester, 'App A'), moreOrLessEquals(0, epsilon: 0.05));
    expect(_opacityOf(tester, 'b'), moreOrLessEquals(0));

    // The letter plane arrives between 20% and 60% of progress.
    await tester.pump(const Duration(milliseconds: 200));
    expect(_opacityOf(tester, 'b'), moreOrLessEquals(1));

    await tester.pumpAndSettle();
    expect(state.controller.value, moreOrLessEquals(1));
    expect(_opacityOf(tester, 'App A'), moreOrLessEquals(0));
    expect(_opacityOf(tester, 'b'), moreOrLessEquals(1));

    final slide = tester
        .widget<Transform>(
          find
              .ancestor(
                of: find.text('App A'),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform;
    expect(slide.storage[12], moreOrLessEquals(-12));
    expect(slide.storage[13], moreOrLessEquals(0));

    // The catalog ignores input while the plane is up...
    expect(_appListIgnoring(tester), isTrue);
    // ...and the settled plane accepts selection.
    expect(_gridIgnoring(tester), isFalse);
    await tester.tap(find.text('b'));
    await tester.pump();
    expect(state.selected, const <String>['b']);
  });

  testWidgets('close envelope reverses the layers and unmounts the plane',
      (tester) async {
    _usePhoneViewport(tester);
    const harness = _Harness();
    await tester.pumpWidget(_scene(harness));
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    state.setOpen(true);
    await tester.pumpAndSettle();

    state.setOpen(false);
    await tester.pump();
    // The plane stays mounted through the 340 ms reverse.
    expect(find.byType(WpAlphabetGrid), findsOneWidget);
    expect(_gridIgnoring(tester), isTrue);

    await tester.pumpAndSettle();
    expect(state.controller.value, moreOrLessEquals(0));
    expect(find.byType(WpAlphabetGrid), findsNothing);
    expect(_opacityOf(tester, 'App A'), moreOrLessEquals(1));
    expect(_appListIgnoring(tester), isFalse);

    await tester.tap(find.text('App A'));
    await tester.pump();
    expect(state.appTaps, 1);
  });

  testWidgets('selection hold keeps the catalog black until the jump lands',
      (tester) async {
    _usePhoneViewport(tester);
    const harness = _Harness();
    await tester.pumpWidget(_scene(harness));
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    state.setOpen(true);
    await tester.pumpAndSettle();

    state.setHold(true);
    state.setOpen(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_opacityOf(tester, 'App A'), moreOrLessEquals(0));

    await tester.pumpAndSettle();
    expect(find.byType(WpAlphabetGrid), findsNothing);
    expect(_opacityOf(tester, 'App A'), moreOrLessEquals(0));

    state.setHold(false);
    await tester.pump();
    expect(_opacityOf(tester, 'App A'), moreOrLessEquals(1));
  });

  testWidgets('reduced motion jumps straight to the settled progress',
      (tester) async {
    _usePhoneViewport(tester);
    const harness = _Harness();
    await tester.pumpWidget(_scene(harness, reducedMotion: true));
    final state = tester.state<_HarnessState>(find.byType(_Harness));

    state.setOpen(true);
    await tester.pump();
    expect(state.controller.value, 1);
    expect(find.byType(WpAlphabetGrid), findsOneWidget);
    expect(_opacityOf(tester, 'App A'), moreOrLessEquals(0));
    expect(_opacityOf(tester, 'b'), moreOrLessEquals(1));

    state.setOpen(false);
    await tester.pump();
    expect(state.controller.value, 0);
    expect(find.byType(WpAlphabetGrid), findsNothing);
    expect(_opacityOf(tester, 'App A'), moreOrLessEquals(1));
  });

  testWidgets('alphabet semantics and Escape cancellation pass through',
      (tester) async {
    _usePhoneViewport(tester);
    final semantics = tester.ensureSemantics();
    const harness = _Harness();
    await tester.pumpWidget(_scene(harness));
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    state.setOpen(true);
    await tester.pumpAndSettle();

    final grid = find.bySemanticsLabel('Alphabet jump list');
    expect(grid, findsOneWidget);
    expect(
      tester.getSemantics(grid).getSemanticsData().hasAction(
            SemanticsAction.dismiss,
          ),
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.selected, const <String>['b']);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(state.cancels, 1);
    semantics.dispose();
  });

  testWidgets('overlay Escape dismissal covers plain alphabet children',
      (tester) async {
    _usePhoneViewport(tester);
    const harness = _Harness(plainAlphabet: true);
    await tester.pumpWidget(_scene(harness));
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    state.setOpen(true);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(state.cancels, 1);
  });

  testWidgets('letter plane starts below the status bar padding',
      (tester) async {
    _usePhoneViewport(tester);
    const harness = _Harness();
    await tester.pumpWidget(
      _scene(harness, padding: const EdgeInsets.only(top: 24)),
    );
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    state.setOpen(true);
    await tester.pumpAndSettle();

    final cellTop = tester
        .getTopLeft(find.byKey(const ValueKey<String>('wp-alphabet-cell-b')))
        .dy;
    expect(cellTop, moreOrLessEquals(24 + 19));
  });

  testWidgets('top inset can be disabled', (tester) async {
    _usePhoneViewport(tester);
    const harness = _Harness(useSafeArea: false);
    await tester.pumpWidget(
      _scene(harness, padding: const EdgeInsets.only(top: 24)),
    );
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    state.setOpen(true);
    await tester.pumpAndSettle();

    final cellTop = tester
        .getTopLeft(find.byKey(const ValueKey<String>('wp-alphabet-cell-b')))
        .dy;
    expect(cellTop, moreOrLessEquals(19));
  });
}
