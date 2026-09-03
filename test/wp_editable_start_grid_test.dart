import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

Widget _scene(
  Widget child, {
  WpPhoneThemeData theme = const WpPhoneThemeData.dark(),
  bool disableAnimations = false,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(disableAnimations: disableAnimations),
          child: WpPhoneTheme(
            data: theme,
            child: Scaffold(
              body: Align(alignment: Alignment.topLeft, child: child),
            ),
          ),
        );
      },
    ),
  );
}

WpEditableStartPlacement _tile(
  Object key, {
  int rowSpan = 1,
  int columnSpan = 1,
  Widget? child,
}) {
  return WpEditableStartPlacement(
    key: key,
    rowSpan: rowSpan,
    columnSpan: columnSpan,
    child: child ?? ColoredBox(key: ValueKey('content-$key'), color: Colors.blue),
  );
}

void main() {
  group('WpEditableStartGridGeometry', () {
    test('packs in order using first-fit placement', () {
      final slots = WpEditableStartGridGeometry.pack([
        _tile('medium', rowSpan: 2, columnSpan: 2),
        _tile('a'),
        _tile('b'),
        _tile('c'),
        _tile('d'),
      ]);
      expect(slots[0].row, 0);
      expect(slots[0].column, 0);
      // Two small tiles fill row 0 columns 2 and 3.
      expect(slots[1].row, 0);
      expect(slots[1].column, 2);
      expect(slots[2].row, 0);
      expect(slots[2].column, 3);
      // Next small tiles flow to row 1 columns 2 and 3.
      expect(slots[3].row, 1);
      expect(slots[3].column, 2);
      expect(slots[4].row, 1);
      expect(slots[4].column, 3);
    });

    test('slotRect matches 99-cell 12-gutter math', () {
      final small = WpEditableStartGridGeometry.slotRect(
        row: 0,
        column: 1,
        rowSpan: 1,
        columnSpan: 1,
      );
      expect(small, const Rect.fromLTWH(111, 0, 99, 99));
      final medium = WpEditableStartGridGeometry.slotRect(
        row: 1,
        column: 0,
        rowSpan: 2,
        columnSpan: 2,
      );
      expect(medium, const Rect.fromLTWH(0, 111, 210, 210));
      final wide = WpEditableStartGridGeometry.slotRect(
        row: 0,
        column: 0,
        rowSpan: 2,
        columnSpan: 4,
      );
      expect(wide, const Rect.fromLTWH(0, 0, 432, 210));
    });

    test('overlapFraction rejects 1-2px tremor and accepts quarter overlap', () {
      const moving = Rect.fromLTWH(0, 0, 99, 99);
      const candidate = Rect.fromLTWH(111, 0, 99, 99);
      expect(
        WpEditableStartGridGeometry.overlapFraction(
          moving.shift(const Offset(2, 0)),
          candidate,
        ),
        0,
      );
      // Quarter overlap of the smaller tile meets the 0.25 activation gate.
      // Candidate starts at x=111; a 99-wide tile shifted by 36.75 overlaps
      // by 24.75 units, exactly one quarter.
      final quarter = WpEditableStartGridGeometry.overlapFraction(
        moving.shift(const Offset(36.75, 0)),
        candidate,
      );
      expect(quarter, closeTo(0.25, 0.001));
      expect(
        WpEditableStartGridGeometry.overlapFraction(moving, moving),
        1,
      );
    });

    test('ambientPhase is deterministic per key', () {
      expect(
        WpEditableStartGridGeometry.ambientPhase('a'),
        WpEditableStartGridGeometry.ambientPhase('a'),
      );
      expect(
        WpEditableStartGridGeometry.ambientPhase('a'),
        isNot(WpEditableStartGridGeometry.ambientPhase('b')),
      );
    });

    test('exit and entry orders match Start sequencing capped at 8', () {
      expect(
        WpEditableStartGridGeometry.exitOrder(row: 0, column: 0, columnSpan: 1),
        3,
      );
      expect(
        WpEditableStartGridGeometry.entryOrder(row: 0, column: 0, columnSpan: 1),
        0,
      );
      expect(
        WpEditableStartGridGeometry.exitOrder(row: 20, column: 0, columnSpan: 1),
        8,
      );
      expect(
        WpEditableStartGridGeometry.entryOrder(row: 20, column: 3, columnSpan: 1),
        8,
      );
    });
  });

  testWidgets('matches exact four-column WVGA geometry at width 480',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          height: 800,
          child: WpEditableStartGrid(
            placements: [
              _tile('medium', rowSpan: 2, columnSpan: 2),
              _tile('a'),
              _tile('b'),
              _tile('c'),
              _tile('d'),
              _tile('wide', rowSpan: 2, columnSpan: 4),
            ],
          ),
        ),
      ),
    );

    // Margin 24, field top 56, 99 cells with 12 gutters.
    expect(
      tester.getRect(find.byKey(const ValueKey('tile-position-medium'))),
      const Rect.fromLTWH(24, 56, 210, 210),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('tile-position-a'))),
      const Rect.fromLTWH(24 + 2 * 111, 56, 99, 99),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('tile-position-b'))),
      const Rect.fromLTWH(24 + 3 * 111, 56, 99, 99),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('tile-position-wide'))),
      const Rect.fromLTWH(24, 56 + 2 * 111, 432, 210),
    );
  });

  testWidgets('scales cell, gutter, margin, and field top to bounded width',
      (tester) async {
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 240,
          height: 800,
          child: WpEditableStartGrid(
            placements: [
              _tile('small'),
              _tile('medium', rowSpan: 2, columnSpan: 2),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getRect(find.byKey(const ValueKey('tile-position-small'))),
      const Rect.fromLTWH(12, 28, 49.5, 49.5),
    );
    // Medium packs at row 0 columns 1-2 in a 4-column grid.
    expect(
      tester.getRect(find.byKey(const ValueKey('tile-position-medium'))),
      const Rect.fromLTWH(12 + 111 * 0.5, 28, 105, 105),
    );
  });

  testWidgets('edit selection scales and dims while ambient wiggles peers',
      (tester) async {
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          height: 800,
          child: WpEditableStartGrid(
            placements: [_tile('a'), _tile('b')],
            editingKey: 'a',
            onReorder: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final selectedScale = tester.widget<AnimatedScale>(
      find.byKey(const ValueKey('tile-edit-scale-a')),
    );
    expect(selectedScale.scale, 1.06);
    final dimmedScale = tester.widget<AnimatedScale>(
      find.byKey(const ValueKey('tile-edit-scale-b')),
    );
    expect(dimmedScale.scale, 0.92);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('tile-edit-opacity-b')),
          )
          .opacity,
      0.72,
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('tile-edit-opacity-a')),
          )
          .opacity,
      1,
    );
    // Only non-selected peers wiggle.
    expect(
      find.byKey(const ValueKey('tile-edit-wiggle-b')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tile-edit-wiggle-a')),
      findsNothing,
    );
  });

  testWidgets('theme reference width drives proportional scale',
      (tester) async {
    const theme = WpPhoneThemeData.dark(referenceWidth: 240);
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          height: 800,
          child: WpEditableStartGrid(
            placements: [_tile('a')],
          ),
        ),
        theme: theme,
      ),
    );

    // Scale 480/240 = 2, so a 99-unit cell renders at 198.
    expect(
      tester.getRect(find.byKey(const ValueKey('tile-position-a'))),
      const Rect.fromLTWH(48, 112, 198, 198),
    );
  });

  testWidgets('disabled reorder ignores drag without committing',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          height: 800,
          child: WpEditableStartGrid(
            placements: [_tile('a'), _tile('b')],
            editingKey: 'a',
            onReorder: null,
          ),
        ),
      ),
    );

    final from = tester.getCenter(find.byKey(const ValueKey('tile-position-a')));
    final to = tester.getCenter(find.byKey(const ValueKey('tile-position-b')));
    final gesture = await tester.startGesture(from);
    await tester.pump();
    await gesture.moveTo(to);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(calls, 0);
    // Tiles remain in packed order.
    expect(
      tester.getRect(find.byKey(const ValueKey('tile-position-a'))).left,
      24,
    );
  });

  testWidgets('drag past activation commits list-index reorder', (tester) async {
    var oldIndex = -1;
    var newIndex = -1;
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          height: 800,
          child: WpEditableStartGrid(
            placements: [_tile('a'), _tile('b'), _tile('c')],
            editingKey: 'a',
            onReorder: (oldIdx, newIdx) {
              oldIndex = oldIdx;
              newIndex = newIdx;
            },
          ),
        ),
      ),
    );

    final from = tester.getCenter(find.byKey(const ValueKey('tile-position-a')));
    final to = tester.getCenter(find.byKey(const ValueKey('tile-position-b')));
    final gesture = await tester.startGesture(from);
    await tester.pump();
    await gesture.moveTo(to);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(oldIndex, 0);
    expect(newIndex, 1);
  });

  testWidgets('1-2px tremor does not commit a reorder', (tester) async {
    var committed = false;
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          height: 800,
          child: WpEditableStartGrid(
            placements: [_tile('a'), _tile('b')],
            editingKey: 'a',
            onReorder: (_, __) => committed = true,
          ),
        ),
      ),
    );

    final from = tester.getCenter(find.byKey(const ValueKey('tile-position-a')));
    final gesture = await tester.startGesture(from);
    await tester.pump();
    await gesture.moveTo(from + const Offset(2, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(committed, isFalse);
  });

  testWidgets('exposes child semantics for the packed tiles', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          height: 800,
          child: WpEditableStartGrid(
            placements: [
              WpEditableStartPlacement(
                key: 'calendar',
                child: Semantics(
                  button: true,
                  label: 'Calendar tile',
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Calendar tile'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('reduced motion uses zero durations and no ambient wiggle',
      (tester) async {
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          height: 800,
          child: WpEditableStartGrid(
            placements: [_tile('a'), _tile('b')],
            editingKey: 'a',
            onReorder: (_, __) {},
          ),
        ),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const ValueKey('tile-edit-scale-a')),
          )
          .duration,
      Duration.zero,
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('tile-edit-opacity-b')),
          )
          .duration,
      Duration.zero,
    );
    expect(
      tester
          .widget<AnimatedPositioned>(
            find.byKey(const ValueKey('tile-position-a')),
          )
          .duration,
      Duration.zero,
    );
    expect(find.byKey(const ValueKey('tile-edit-wiggle-b')), findsNothing);
    // Edit scale and dim still apply without motion.
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const ValueKey('tile-edit-scale-a')),
          )
          .scale,
      1.06,
    );
  });

  test('reference height includes field top and bottom padding', () {
    expect(
      WpEditableStartGridGeometry.referenceHeight(rows: 0),
      56 + 32,
    );
    expect(
      WpEditableStartGridGeometry.referenceHeight(rows: 1),
      56 + 99 + 32,
    );
    expect(
      WpEditableStartGridGeometry.referenceHeight(rows: 2),
      56 + 2 * 99 + 12 + 32,
    );
    expect(
      WpEditableStartGridGeometry.referenceHeight(rows: 3),
      56 + 3 * 99 + 2 * 12 + 32,
    );
    expect(
      math.min(8.0, 4 - 0 - 1 + 0 * 0.5),
      WpEditableStartGridGeometry.exitOrder(row: 0, column: 0, columnSpan: 1),
    );
  });
}
