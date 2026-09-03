import 'dart:ui' show SemanticsAction, SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

Widget _shellHost(
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
          child: WpPhoneTheme(data: theme, child: child),
        );
      },
    ),
  );
}

Widget _scaffoldHost(
  Widget child, {
  WpPhoneThemeData theme = const WpPhoneThemeData.dark(),
  bool disableAnimations = false,
}) {
  return _shellHost(
    Scaffold(body: child),
    theme: theme,
    disableAnimations: disableAnimations,
  );
}

void main() {
  testWidgets('loading reproduces 160x3 accent-on-dark geometry at 480x800',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_shellHost(const WpLoadingSurface()));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xff000000));

    final indicator =
        tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(indicator.minHeight, 3);
    expect(indicator.color, const Color(0xff3e65ff));
    expect(indicator.backgroundColor, const Color(0xff202020));
    expect(indicator.borderRadius, BorderRadius.zero);
    // Animated by default.
    expect(indicator.value, isNull);

    expect(
      tester.getSize(find.byType(LinearProgressIndicator)),
      const Size(160, 3),
    );
  });

  testWidgets('loading honors theme override and reduced-motion static',
      (tester) async {
    const theme = WpPhoneThemeData.dark(
      backgroundColor: Color(0xff010101),
      accentColor: Color(0xffaa00cc),
      disabledColor: Color(0xff333333),
    );
    await tester.pumpWidget(
      _shellHost(const WpLoadingSurface(), theme: theme),
    );
    var indicator =
        tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(indicator.color, theme.accentColor);
    expect(indicator.backgroundColor, theme.disabledColor);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      theme.backgroundColor,
    );

    await tester.pumpWidget(
      _shellHost(
        const WpLoadingSurface(),
        theme: theme,
        disableAnimations: true,
      ),
    );
    indicator =
        tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    // Static determinate fill instead of an indeterminate animation.
    expect(indicator.value, 0.5);
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.5,
    );
  });

  testWidgets('failure reproduces padding headline detail retry tokens',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var retries = 0;
    await tester.pumpWidget(
      _shellHost(
        WpFailureSurface(
          headline: 'Headline',
          detail: 'Detail',
          onRetry: () => retries++,
        ),
      ),
    );

    final padding = tester.widget<Padding>(
      find.ancestor(
        of: find.text('Headline'),
        matching: find.byType(Padding),
      ).first,
    );
    expect(padding.padding, const EdgeInsets.all(24));

    final headline = tester.widget<Text>(find.text('Headline'));
    expect(headline.style?.fontSize, 34);
    expect(headline.style?.fontWeight, FontWeight.w300);
    expect(headline.style?.color, Colors.white);

    final detail = tester.widget<Text>(find.text('Detail'));
    expect(detail.style?.fontSize, 18);
    expect(detail.style?.color, Colors.white70);

    final retry = tester.widget<TextButton>(find.widgetWithText(TextButton, 'retry'));
    final minSize = retry.style?.minimumSize?.resolve(const <WidgetState>{});
    expect(minSize, const Size(96, 48));
    final shape = retry.style?.shape?.resolve(const <WidgetState>{});
    expect(shape, isA<RoundedRectangleBorder>());
    expect(
      (shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.zero,
    );
    expect(
      retry.style?.backgroundColor?.resolve(const <WidgetState>{}),
      const Color(0xff3e65ff),
    );
    expect(
      retry.style?.foregroundColor?.resolve(const <WidgetState>{}),
      Colors.white,
    );

    await tester.tap(find.widgetWithText(TextButton, 'retry'));
    expect(retries, 1);
  });

  testWidgets('failure and empty expose button semantics and theme colors',
      (tester) async {
    final semantics = tester.ensureSemantics();
    const theme = WpPhoneThemeData.dark(
      foregroundColor: Color(0xfffafafa),
      accentColor: Color(0xff112233),
    );

    var retries = 0;
    await tester.pumpWidget(
      _shellHost(
        WpFailureSurface(onRetry: () => retries++),
        theme: theme,
      ),
    );
    final retryNode = tester
        .getSemantics(find.widgetWithText(TextButton, 'retry'))
        .getSemanticsData();
    // ignore: deprecated_member_use
    expect(retryNode.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(retryNode.hasAction(SemanticsAction.tap), isTrue);
    final headline = tester.widget<Text>(find.text('Something could not start'));
    expect(headline.style?.color, theme.foregroundColor);
    expect(headline.style?.fontFamily, theme.fontFamily);

    var opens = 0;
    await tester.pumpWidget(
      _scaffoldHost(WpEmptyStart(onOpen: () => opens++), theme: theme),
    );
    final emptyNode = tester
        .getSemantics(find.bySemanticsLabel('Open apps to pin your first tile'))
        .getSemanticsData();
    // ignore: deprecated_member_use
    expect(emptyNode.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(emptyNode.hasAction(SemanticsAction.tap), isTrue);
    await tester.tap(find.bySemanticsLabel('Open apps to pin your first tile'));
    expect(opens, 1);

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.size, 44);
    expect(icon.color, theme.foregroundColor);
    semantics.dispose();
  });

  testWidgets('empty reproduces icon message geometry and reduced-motion splash',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_scaffoldHost(WpEmptyStart(onOpen: () {})));

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.size, 44);
    expect(icon.icon, Icons.arrow_forward);

    final message = tester.widget<Text>(
      find.text('swipe to apps\nthen hold an app to pin it'),
    );
    expect(message.style?.fontSize, 21);
    expect(message.style?.fontWeight, FontWeight.w300);
    expect(message.style?.height, 1.25);
    expect(message.textAlign, TextAlign.center);

    var inkwell =
        tester.widget<InkWell>(find.byType(InkWell));
    expect(inkwell.borderRadius, BorderRadius.zero);
    expect(inkwell.splashFactory, isNot(NoSplash.splashFactory));

    await tester.pumpWidget(
      _scaffoldHost(
        WpEmptyStart(onOpen: () {}),
        disableAnimations: true,
      ),
    );
    inkwell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkwell.splashFactory, NoSplash.splashFactory);
    expect(inkwell.highlightColor, Colors.transparent);
  });
}
