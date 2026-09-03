import 'dart:ui' show SemanticsAction, SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

Widget _host(
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
              body: SizedBox(
                width: 480,
                height: 800,
                child: Stack(children: <Widget>[child]),
              ),
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets('setup panel reproduces rule offsets sizing typography at 480x800',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(
        const WpSetupPanel(
          actions: <WpSetupAction>[
            WpSetupAction(label: 'set as home', onPressed: null),
            WpSetupAction(label: 'enable live tiles', onPressed: null),
          ],
        ),
      ),
    );

    final positioned = tester.widget<Positioned>(find.byType(Positioned));
    expect(positioned.left, 24);
    expect(positioned.right, 24);
    expect(positioned.bottom, 24);

    final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.border?.top.color, Colors.white);
    expect(decoration.border?.top.width, 2);

    final padding = tester.widget<Padding>(
      find.ancestor(
        of: find.byType(Wrap),
        matching: find.byType(Padding),
      ),
    );
    expect(padding.padding, const EdgeInsets.only(top: 10));

    for (final label in <String>['set as home', 'enable live tiles']) {
      final button =
          tester.widget<TextButton>(find.widgetWithText(TextButton, label));
      expect(
        button.style?.minimumSize?.resolve(const <WidgetState>{}),
        const Size(48, 48),
      );
      final shape = button.style?.shape?.resolve(const <WidgetState>{});
      expect(shape, isA<RoundedRectangleBorder>());
      expect(
        (shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.zero,
      );
      expect(
        button.style?.textStyle?.resolve(const <WidgetState>{})?.fontSize,
        18,
      );
      expect(
        button.style?.textStyle?.resolve(const <WidgetState>{})?.fontWeight,
        FontWeight.w400,
      );
      expect(tester.getSize(find.widgetWithText(TextButton, label)).width,
          greaterThanOrEqualTo(48));
      expect(tester.getSize(find.widgetWithText(TextButton, label)).height,
          greaterThanOrEqualTo(48));
    }
  });

  testWidgets('setup actions expose button semantics invoke callbacks honor theme',
      (tester) async {
    final semantics = tester.ensureSemantics();
    const theme = WpPhoneThemeData.dark(
      backgroundColor: Color(0xff010101),
      foregroundColor: Color(0xfffafafa),
    );
    var homes = 0;
    var tiles = 0;
    await tester.pumpWidget(
      _host(
        WpSetupPanel(
          actions: <WpSetupAction>[
            WpSetupAction(label: 'set as home', onPressed: () => homes++),
            WpSetupAction(label: 'enable live tiles', onPressed: () => tiles++),
          ],
        ),
        theme: theme,
      ),
    );

    expect(
      tester
          .widget<ColoredBox>(
            find.descendant(
              of: find.byType(WpSetupPanel),
              matching: find.byType(ColoredBox),
            ),
          )
          .color,
      theme.backgroundColor,
    );

    for (final label in <String>['set as home', 'enable live tiles']) {
      final node = tester
          .getSemantics(find.widgetWithText(TextButton, label))
          .getSemanticsData();
      // ignore: deprecated_member_use
      expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(node.hasAction(SemanticsAction.tap), isTrue);
    }

    await tester.tap(find.text('set as home'));
    await tester.tap(find.text('enable live tiles'));
    expect(homes, 1);
    expect(tiles, 1);

    await tester.pumpWidget(_host(const WpSetupPanel(actions: <WpSetupAction>[])));
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(Positioned), findsNothing);
    semantics.dispose();
  });

  testWidgets('transient notice reproduces text fade liveRegion ignorePointer tokens',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    expect(
      const WpTransientNotice(text: 'hello').visibleDuration,
      const Duration(milliseconds: 1600),
    );
    expect(
      const WpTransientNotice(text: 'hello').fadeDuration,
      const Duration(milliseconds: 120),
    );

    await tester.pumpWidget(_host(const WpTransientNotice(text: 'Pinned')));
    expect(find.text('Pinned'), findsOneWidget);
    Finder noticeScope() => find.byType(WpTransientNotice);
    var opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: noticeScope(),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, 1);
    expect(opacity.duration, const Duration(milliseconds: 120));
    expect(
      tester
          .widget<IgnorePointer>(
            find.descendant(
              of: noticeScope(),
              matching: find.byType(IgnorePointer),
            ),
          )
          .ignoring,
      isFalse,
    );
    final positioned = tester.widget<Positioned>(
      find.ancestor(
        of: find.text('Pinned'),
        matching: find.byType(Positioned),
      ).first,
    );
    expect(positioned.left, 24);
    expect(positioned.right, 24);
    expect(positioned.bottom, 24);

    final message = tester.widget<Text>(find.text('Pinned'));
    expect(message.style?.fontSize, 19);
    expect(message.style?.color, Colors.white);

    final node = tester
        .getSemantics(find.bySemanticsLabel('Pinned'))
        .getSemanticsData();
    // ignore: deprecated_member_use
    expect(node.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
    expect(node.label, 'Pinned');

    await tester.pumpWidget(_host(const WpTransientNotice()));
    expect(find.text(''), findsOneWidget);
    opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: noticeScope(),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, 0);
    expect(
      tester
          .widget<IgnorePointer>(
            find.descendant(
              of: noticeScope(),
              matching: find.byType(IgnorePointer),
            ),
          )
          .ignoring,
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets('notice fade collapses to zero under reduced-motion and honors theme',
      (tester) async {
    const theme = WpPhoneThemeData.dark(
      backgroundColor: Color(0xff020202),
      foregroundColor: Color(0xfffafafa),
    );
    await tester.pumpWidget(
      _host(const WpTransientNotice(text: 'Pinned'), theme: theme),
    );
    expect(
      tester
          .widget<ColoredBox>(
            find.descendant(
              of: find.byType(WpTransientNotice),
              matching: find.byType(ColoredBox),
            ),
          )
          .color,
      theme.backgroundColor,
    );
    expect(
      tester.widget<Text>(find.text('Pinned')).style?.color,
      theme.foregroundColor,
    );
    expect(
      tester.widget<Text>(find.text('Pinned')).style?.fontFamily,
      theme.fontFamily,
    );

    await tester.pumpWidget(
      _host(
        const WpTransientNotice(text: 'Pinned'),
        disableAnimations: true,
      ),
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: find.byType(WpTransientNotice),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .duration,
      Duration.zero,
    );
  });
}
