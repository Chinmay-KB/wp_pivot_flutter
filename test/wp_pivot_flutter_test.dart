import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';

Widget _wrap(GlobalKey<WpPivotState> key) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      appBar: WpPivot(
        key: key,
        tabTitles: const ['one', 'two', 'three'],
        title: 'title',
      ),
    ),
  );
}

void main() {
  testWidgets('renders all tab titles and uppercased pivot title',
      (tester) async {
    final key = GlobalKey<WpPivotState>();
    await tester.pumpWidget(_wrap(key));

    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
    expect(find.text('three'), findsOneWidget);
    expect(find.text('TITLE'), findsOneWidget);
  });

  testWidgets('handlePagechange highlights the target tab', (tester) async {
    final key = GlobalKey<WpPivotState>();
    await tester.pumpWidget(_wrap(key));

    Color colorOf(String label) =>
        tester.widget<Text>(find.text(label)).style!.color!;

    expect(colorOf('one'), Colors.white);
    expect(colorOf('two'), Colors.white54);

    key.currentState!.handlePagechange(1);
    await tester.pumpAndSettle();

    expect(colorOf('one'), Colors.white54);
    expect(colorOf('two'), Colors.white);

    key.currentState!.handlePagechange(0);
    await tester.pumpAndSettle();

    expect(colorOf('one'), Colors.white);
    expect(colorOf('two'), Colors.white54);
  });
}
