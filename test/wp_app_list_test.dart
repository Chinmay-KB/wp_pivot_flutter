import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              backgroundColor: theme.backgroundColor,
              body: Align(alignment: Alignment.topLeft, child: child),
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets('row reproduces measured 480-unit geometry', (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpAppListRow(
            icon: const Icon(Icons.calculate),
            label: 'Calculator',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(WpAppListRow)), const Size(480, 74));
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-app-list-icon-frame'))),
      const Rect.fromLTWH(0, 6, 62, 62),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-app-list-label-slot'))).left,
      78,
    );
    expect(find.byType(WpTiltEffect), findsOneWidget);

    final text = tester.widget<Text>(find.text('Calculator'));
    expect(text.style?.fontFamily, const WpPhoneThemeData.dark().fontFamily);
    expect(text.style?.fontSize, 25);
  });

  testWidgets('row geometry scales proportionally with available width',
      (tester) async {
    await tester.pumpWidget(
      _scene(
        const SizedBox(
          width: 240,
          child: WpAppListRow(
            icon: SizedBox(),
            label: 'Half scale',
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(WpAppListRow)), const Size(240, 37));
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-app-list-icon-frame'))),
      const Rect.fromLTWH(0, 3, 31, 31),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-app-list-label-slot'))).left,
      39,
    );
  });

  testWidgets(
      'row exposes one semantic button and supports keyboard activation',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var taps = 0;
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpAppListRow(
            icon: const Text('duplicate icon semantics'),
            label: 'Visual label',
            semanticLabel: 'Open Calculator',
            focusNode: focusNode,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    final row = find.bySemanticsLabel('Open Calculator');
    expect(row, findsOneWidget);
    expect(find.bySemanticsLabel('duplicate icon semantics'), findsNothing);
    expect(
      tester.getSemantics(row).getSemanticsData().hasAction(
            SemanticsAction.tap,
          ),
      isTrue,
    );

    await tester.tap(row);
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 2);
    semantics.dispose();
  });

  testWidgets('row consumes theme colors and explicit overrides',
      (tester) async {
    const theme = WpPhoneThemeData.dark(
      accentColor: Color(0xff112233),
      foregroundColor: Color(0xffeeeeee),
    );
    const override = Color(0xffaa3300);
    await tester.pumpWidget(
      _scene(
        const SizedBox(
          width: 480,
          child: WpAppListRow(
            icon: Icon(Icons.calculate),
            label: 'Calculator',
            iconBackgroundColor: override,
            labelColor: Color(0xff00ff00),
          ),
        ),
        theme: theme,
      ),
    );

    final iconBox = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byKey(const ValueKey('wp-app-list-icon-frame')),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(iconBox.color, override);
    expect(tester.widget<Text>(find.text('Calculator')).style?.color,
        const Color(0xff00ff00));
  });

  testWidgets('header is a controlled outlined 62-unit frame in a 74-unit slot',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var taps = 0;
    await tester.pumpWidget(
      _scene(
        WpAppListHeader(
          letter: 'c',
          semanticLabel: 'Choose app-list section',
          focusNode: focusNode,
          onTap: () => taps++,
        ),
      ),
    );

    final header = find.bySemanticsLabel('Choose app-list section');
    expect(tester.getSize(find.byType(WpAppListHeader)), const Size(62, 74));
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-app-list-header-frame'))),
      const Rect.fromLTWH(0, 6, 62, 62),
    );
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const ValueKey('wp-app-list-header-frame')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, Colors.black);
    expect((material.shape! as Border).top.color, const Color(0xff3e65ff));
    expect(
      tester.getSemantics(header).getSemanticsData().hasAction(
            SemanticsAction.tap,
          ),
      isTrue,
    );
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('reduced motion leaves row tilt at rest', (tester) async {
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpAppListRow(
            icon: const SizedBox(),
            label: 'Calculator',
            onTap: () {},
          ),
        ),
        disableAnimations: true,
      ),
    );

    final gesture = await tester.startGesture(const Offset(2, 2));
    await tester.pump();
    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('wp-tilt-transform')),
    );
    expect(transform.transform, Matrix4.identity());
    await gesture.up();
  });

  testWidgets('view composes measured search, header, icon and label positions',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _scene(
        WpAppListView(
          leadingAction: const ColoredBox(
            key: ValueKey('leading-action'),
            color: Colors.white,
          ),
          children: <Widget>[
            WpAppListHeader(letter: 'a', onTap: () {}),
            WpAppListRow(
              icon: const Icon(Icons.alarm),
              label: 'Alarms',
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    expect(
      tester.getRect(find.byKey(const ValueKey('leading-action'))),
      const Rect.fromLTWH(24, 56, 44, 44),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-app-list-header-frame'))),
      const Rect.fromLTWH(86, 57, 62, 62),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-app-list-icon-frame'))),
      const Rect.fromLTWH(86, 131, 62, 62),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('wp-app-list-label-slot'))).left,
      164,
    );
  });
}
