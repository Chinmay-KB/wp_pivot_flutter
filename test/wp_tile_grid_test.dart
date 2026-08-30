import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

Widget _host(Widget child, {double width = 480, double height = 800}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, height: height, child: child),
      ),
    ),
  );
}

WpTilePlacement _placement(
  String key, {
  required int row,
  required int column,
  int rowSpan = 1,
  int columnSpan = 1,
}) {
  return WpTilePlacement(
    row: row,
    column: column,
    rowSpan: rowSpan,
    columnSpan: columnSpan,
    child: ColoredBox(key: ValueKey(key), color: Colors.blue),
  );
}

void main() {
  testWidgets('matches exact four-column WVGA geometry at width 480',
      (tester) async {
    await tester.pumpWidget(
      _host(
        WpTileGrid(
          placements: <WpTilePlacement>[
            for (var column = 0; column < 4; column++)
              _placement('small-$column', row: 0, column: column),
            _placement(
              'large-left',
              row: 1,
              column: 0,
              rowSpan: 2,
              columnSpan: 2,
            ),
            _placement(
              'large-right',
              row: 1,
              column: 2,
              rowSpan: 2,
              columnSpan: 2,
            ),
          ],
        ),
      ),
    );

    for (var column = 0; column < 4; column++) {
      final rect = tester.getRect(find.byKey(ValueKey('small-$column')));
      expect(rect.left, 24 + column * 111);
      expect(rect.top, 0);
      expect(rect.size, const Size.square(99));
    }
    expect(
      tester.getRect(find.byKey(const ValueKey('large-left'))),
      const Rect.fromLTWH(24, 111, 210, 210),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('large-right'))),
      const Rect.fromLTWH(246, 111, 210, 210),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('large-right'))).bottom,
      321,
    );
  });

  testWidgets('scales cell, gutter, and margin geometry to bounded width',
      (tester) async {
    await tester.pumpWidget(
      _host(
        WpTileGrid(
          placements: <WpTilePlacement>[
            _placement('small', row: 0, column: 0),
            _placement(
              'large',
              row: 0,
              column: 2,
              rowSpan: 2,
              columnSpan: 2,
            ),
          ],
        ),
        width: 240,
      ),
    );

    expect(
      tester.getRect(find.byKey(const ValueKey('small'))),
      const Rect.fromLTWH(12, 0, 49.5, 49.5),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('large'))),
      const Rect.fromLTWH(123, 0, 105, 105),
    );
  });

  testWidgets('optional scrolling exposes tall explicit layouts',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        WpTileGrid(
          scrollable: true,
          controller: controller,
          placements: <WpTilePlacement>[
            _placement('first', row: 0, column: 0),
            _placement('last', row: 5, column: 0),
          ],
        ),
        height: 150,
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(controller.hasClients, isTrue);
    expect(controller.position.maxScrollExtent, greaterThan(0));
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    expect(controller.offset, controller.position.maxScrollExtent);
  });

  testWidgets('asserts when a placement extends beyond the grid',
      (tester) async {
    await tester.pumpWidget(
      _host(
        WpTileGrid(
          placements: <WpTilePlacement>[
            _placement(
              'outside',
              row: 0,
              column: 3,
              columnSpan: 2,
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('asserts when placements overlap', (tester) async {
    await tester.pumpWidget(
      _host(
        WpTileGrid(
          placements: <WpTilePlacement>[
            _placement(
              'large',
              row: 0,
              column: 0,
              rowSpan: 2,
              columnSpan: 2,
            ),
            _placement('overlap', row: 1, column: 1),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isA<AssertionError>());
  });
}
