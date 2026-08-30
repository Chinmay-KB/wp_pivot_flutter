import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

Widget _scene(
  Widget child, {
  WpPhoneThemeData theme = const WpPhoneThemeData.dark(),
}) {
  return MaterialApp(
    home: WpPhoneTheme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
}

List<String> get _alphabet => List<String>.generate(
      26,
      (index) => String.fromCharCode('a'.codeUnitAt(0) + index),
    );

void main() {
  testWidgets('grid reproduces measured 480-unit geometry', (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpAlphabetGrid(
            letters: _alphabet,
            enabledLetters: _alphabet.toSet(),
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(WpAlphabetGrid)), const Size(480, 784));
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-alphabet-cell-a'))),
      const Rect.fromLTWH(24, 19, 99, 99),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-alphabet-cell-b'))),
      const Rect.fromLTWH(135, 19, 99, 99),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-alphabet-cell-d'))),
      const Rect.fromLTWH(357, 19, 99, 99),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-alphabet-cell-e'))),
      const Rect.fromLTWH(24, 130, 99, 99),
    );
  });

  testWidgets('grid scales cells, margins, and gutters proportionally',
      (tester) async {
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 240,
          child: WpAlphabetGrid(
            letters: const <String>['a', 'b', 'c', 'd', 'e'],
            enabledLetters: const <String>{'a', 'b', 'c', 'd', 'e'},
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(WpAlphabetGrid)), const Size(240, 114.5));
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-alphabet-cell-a'))),
      const Rect.fromLTWH(12, 9.5, 49.5, 49.5),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-alphabet-cell-b'))),
      const Rect.fromLTWH(67.5, 9.5, 49.5, 49.5),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-alphabet-cell-e'))),
      const Rect.fromLTWH(12, 65, 49.5, 49.5),
    );
  });

  testWidgets(
      'enabled cells select and disabled cells expose disabled semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final selected = <String>[];
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpAlphabetGrid(
            letters: const <String>['a', 'b'],
            enabledLetters: const <String>{'b'},
            onSelected: selected.add,
          ),
        ),
      ),
    );

    final disabled =
        tester.getSemantics(find.bySemanticsLabel('a')).getSemanticsData();
    final enabled =
        tester.getSemantics(find.bySemanticsLabel('b')).getSemanticsData();
    expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
    expect(disabled.hasAction(SemanticsAction.tap), isFalse);
    expect(enabled.flagsCollection.isEnabled, Tristate.isTrue);
    expect(enabled.hasAction(SemanticsAction.tap), isTrue);

    await tester.tap(find.bySemanticsLabel('a'));
    await tester.tap(find.bySemanticsLabel('b'));
    expect(selected, const <String>['b']);
    semantics.dispose();
  });

  testWidgets('keyboard selects enabled cells and Escape cancels',
      (tester) async {
    final selected = <String>[];
    var cancels = 0;
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpAlphabetGrid(
            letters: const <String>['a', 'b'],
            enabledLetters: const <String>{'b'},
            onSelected: selected.add,
            onCancel: () => cancels++,
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(selected, const <String>['b']);
    expect(cancels, 1);
  });

  testWidgets('background tap and dismiss semantics cancel without selection',
      (tester) async {
    final semantics = tester.ensureSemantics();
    var cancels = 0;
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpAlphabetGrid(
            letters: const <String>['a'],
            enabledLetters: const <String>{'a'},
            onSelected: (_) {},
            onCancel: () => cancels++,
          ),
        ),
      ),
    );

    final grid = find.bySemanticsLabel('Alphabet jump list');
    expect(
      tester.getSemantics(grid).getSemanticsData().hasAction(
            SemanticsAction.dismiss,
          ),
      isTrue,
    );
    await tester.tapAt(const Offset(10, 10));
    expect(cancels, 1);
    semantics.dispose();
  });

  testWidgets('theme colors and custom cell contents are reusable',
      (tester) async {
    const theme = WpPhoneThemeData.dark(
      accentColor: Color(0xff112233),
      disabledColor: Color(0xff334455),
    );
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpAlphabetGrid(
            letters: const <String>['a', 'b'],
            enabledLetters: const <String>{'a'},
            onSelected: (_) {},
            cellBuilder: (context, letter, enabled) => Text(
              '$letter:${enabled ? 'on' : 'off'}',
            ),
          ),
        ),
        theme: theme,
      ),
    );

    expect(find.text('a:on'), findsOneWidget);
    expect(find.text('b:off'), findsOneWidget);
    final enabledMaterial = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const ValueKey('wp-alphabet-cell-a')),
            matching: find.byType(Material),
          )
          .first,
    );
    final disabledMaterial = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const ValueKey('wp-alphabet-cell-b')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(enabledMaterial.color, theme.accentColor);
    expect(disabledMaterial.color, theme.disabledColor);
  });
}
