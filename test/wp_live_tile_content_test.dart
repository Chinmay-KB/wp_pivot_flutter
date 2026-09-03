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

Widget _icon({double size = 64}) {
  return SizedBox.square(
    key: const ValueKey('live-icon'),
    dimension: size,
    child: const ColoredBox(color: Colors.white),
  );
}

void main() {
  testWidgets('wide content matches measured padding, gap, and type',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 432,
          height: 210,
          child: WpLiveTileContent(
            icon: _icon(),
            title: 'Calendar',
            body: 'Team standup at 9 in room 4B',
            count: 3,
          ),
        ),
      ),
    );

    // Icon frame starts at the 18-unit left padding and is vertically
    // centered in the 158-unit content height (210 - 18 - 34).
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('live-icon'))),
      const Offset(18, 65),
    );
    // Gap between icon and text column is 18 units.
    final iconRight =
        tester.getRect(find.byKey(const ValueKey('live-icon'))).right;
    final titleLeft = tester.getRect(find.text('Calendar')).left;
    expect(titleLeft - iconRight, 18);

    final title = tester.widget<Text>(find.text('Calendar'));
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(title.style?.fontSize, 19);
    final body = tester.widget<Text>(
      find.text('Team standup at 9 in room 4B'),
    );
    expect(body.maxLines, 2);
    expect(body.overflow, TextOverflow.ellipsis);
    expect(body.style?.fontSize, 16);
    expect(body.style?.height, 1.12);
    final count = tester.widget<Text>(find.text('3'));
    expect(count.style?.fontSize, 25);
    expect(count.style?.fontWeight, FontWeight.w300);
  });

  testWidgets('scales padding, gap, and type via parent constraints',
      (tester) async {
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 216,
          height: 105,
          child: WpLiveTileContent(
            icon: const SizedBox.square(
              key: ValueKey('live-icon'),
              dimension: 32,
            ),
            title: 'Calendar',
            body: 'Standup',
            count: 5,
          ),
        ),
      ),
    );

    // Half scale: 9-unit left padding, vertically centered in the
    // 79-unit content height (105 - 9 - 17).
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('live-icon'))),
      const Offset(9, 32.5),
    );
    expect(tester.widget<Text>(find.text('Calendar')).style?.fontSize, 9.5);
    expect(tester.widget<Text>(find.text('Standup')).style?.fontSize, 8);
    expect(tester.widget<Text>(find.text('5')).style?.fontSize, 12.5);
  });

  testWidgets('uses phone theme colors and font family', (tester) async {
    const theme = WpPhoneThemeData.dark(
      foregroundColor: Color(0xfffafafa),
      accentColor: Color(0xff112233),
    );
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 432,
          height: 210,
          child: WpLiveTileContent(
            icon: _icon(),
            title: 'Mail',
            body: 'Two new messages',
            count: 2,
          ),
        ),
        theme: theme,
      ),
    );

    for (final label in ['Mail', 'Two new messages', '2']) {
      final style = tester.widget<Text>(find.text(label)).style;
      expect(style?.color, theme.foregroundColor);
      expect(style?.fontFamily, theme.fontFamily);
    }
  });

  testWidgets('centers bare icons and hides count at zero or one',
      (tester) async {
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 432,
          height: 210,
          child: WpLiveTileContent(icon: _icon()),
        ),
      ),
    );
    // No live text: the icon is centered like the non-wide fallback.
    final iconRect = tester.getRect(find.byKey(const ValueKey('live-icon')));
    expect(iconRect.center, const Offset(216, 105));

    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 432,
          height: 210,
          child: WpLiveTileContent(icon: _icon(), title: 'Mail', count: 1),
        ),
      ),
    );
    expect(find.text('1'), findsNothing);

    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 432,
          height: 210,
          child: WpLiveTileContent(icon: _icon(), title: 'Mail', count: 2),
        ),
      ),
    );
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('exposes title, body, and count semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 432,
          height: 210,
          child: WpLiveTileContent(
            icon: _icon(),
            title: 'Calendar live',
            body: 'Standup at 9',
            count: 4,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Calendar live'), findsOneWidget);
    expect(find.bySemanticsLabel('Standup at 9'), findsOneWidget);
    expect(find.bySemanticsLabel('4'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('builds unchanged with reduced motion enabled', (tester) async {
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 432,
          height: 210,
          child: WpLiveTileContent(
            icon: _icon(),
            title: 'Calendar',
            body: 'Standup',
            count: 2,
          ),
        ),
        disableAnimations: true,
      ),
    );

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Standup'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Calendar')).style?.fontSize, 19);
  });
}
