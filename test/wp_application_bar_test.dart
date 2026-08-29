import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/src/wp_application_bar.dart';

Widget _scene({
  List<WpApplicationBarAction> actions = const <WpApplicationBarAction>[],
  List<WpApplicationBarMenuItem> menuItems = const <WpApplicationBarMenuItem>[],
  WpApplicationBarMode mode = WpApplicationBarMode.defaultMode,
  bool reducedMotion = false,
  double textScale = 1,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: WpApplicationBar(
              actions: actions,
              menuItems: menuItems,
              mode: mode,
              reducedMotion: reducedMotion,
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  const menu = <WpApplicationBarMenuItem>[
    WpApplicationBarMenuItem(label: 'settings'),
    WpApplicationBarMenuItem(label: 'about'),
  ];

  testWidgets('ellipsis expands and collapses the menu', (tester) async {
    await tester.pumpWidget(_scene(menuItems: menu));
    expect(find.text('settings'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsOneWidget);
    expect(find.text('about'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close application menu'));
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsNothing);
  });

  testWidgets('ellipsis expands action labels when no menu items exist',
      (tester) async {
    await tester.pumpWidget(_scene(
      actions: const <WpApplicationBarAction>[
        WpApplicationBarAction(label: 'save', icon: Icon(Icons.save)),
      ],
    ));
    expect(find.text('save'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pumpAndSettle();
    expect(find.text('save'), findsOneWidget);
  });

  testWidgets('action and menu callbacks work while disabled actions do not',
      (tester) async {
    var actionCalls = 0;
    var menuCalls = 0;
    await tester.pumpWidget(_scene(
      actions: <WpApplicationBarAction>[
        WpApplicationBarAction(
          label: 'save',
          icon: const Icon(Icons.save),
          onPressed: () => actionCalls++,
        ),
        const WpApplicationBarAction(label: 'delete', icon: Icon(Icons.delete)),
      ],
      menuItems: <WpApplicationBarMenuItem>[
        WpApplicationBarMenuItem(
          label: 'settings',
          onPressed: () => menuCalls++,
        ),
      ],
    ));

    await tester.tap(find.bySemanticsLabel('save'));
    await tester.tap(find.bySemanticsLabel('delete'));
    expect(actionCalls, 1);
    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('settings'));
    expect(menuCalls, 1);
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsNothing);
  });

  testWidgets('minimized mode hides actions until the ellipsis expands',
      (tester) async {
    await tester.pumpWidget(_scene(
      mode: WpApplicationBarMode.minimized,
      actions: const <WpApplicationBarAction>[
        WpApplicationBarAction(label: 'save', icon: Icon(Icons.save)),
      ],
      menuItems: menu,
    ));

    expect(find.bySemanticsLabel('save'), findsNothing);
    expect(find.bySemanticsLabel('Open application menu'), findsOneWidget);
    final ellipsis =
        tester.getSize(find.bySemanticsLabel('Open application menu'));
    expect(ellipsis.height, 30);

    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pumpAndSettle();
    expect(find.text('save'), findsOneWidget);
  });

  testWidgets(
      'keyboard toggles ellipsis and reduced motion settles immediately',
      (tester) async {
    await tester.pumpWidget(_scene(menuItems: menu, reducedMotion: true));
    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pump();
    expect(find.text('settings'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close application menu'));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(find.text('settings'), findsOneWidget);
  });

  testWidgets(
      'pointer activation clears the highlight while keyboard restores it',
      (tester) async {
    await tester.pumpWidget(_scene(menuItems: menu, reducedMotion: true));
    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pumpAndSettle();
    Color? highlightColor(String label) {
      final highlight = find.descendant(
        of: find.bySemanticsLabel(label),
        matching: find.byType(AnimatedContainer),
      );
      return (tester.widget<AnimatedContainer>(highlight).decoration!
              as BoxDecoration)
          .color;
    }

    expect(highlightColor('Close application menu'), Colors.transparent);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(highlightColor('Close application menu'), Colors.transparent);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(
      highlightColor('Open application menu'),
      Colors.white.withAlpha(46),
    );
  });

  testWidgets('short viewport and large text scale keep a bounded menu',
      (tester) async {
    tester.view.physicalSize = const Size(240, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_scene(
      textScale: 2.5,
      menuItems: const <WpApplicationBarMenuItem>[
        WpApplicationBarMenuItem(label: 'a very long application command'),
        WpApplicationBarMenuItem(label: 'another command with long words'),
        WpApplicationBarMenuItem(label: 'third command'),
      ],
    ));
    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomRight(find.bySemanticsLabel('Close application menu')).dy,
      lessThanOrEqualTo(180),
    );
  });

  testWidgets('expanded two-item menu band matches WVGA pilot geometry',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_scene(menuItems: menu));
    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.bySemanticsLabel('Close application menu')).height,
      closeTo(102, 2),
    );
    final menuList = find.descendant(
      of: find.byType(WpApplicationBar),
      matching: find.byType(ListView),
    );
    expect(tester.getSize(menuList).height, closeTo(225, 2));
  });

  testWidgets('menu expansion keeps the command row above the first item',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_scene(menuItems: menu));
    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    expect(find.text('settings'), findsOneWidget);
    final ellipsis =
        tester.getRect(find.bySemanticsLabel('Close application menu'));
    final settings = tester.getRect(find.text('settings'));
    expect(ellipsis.top, greaterThan(0));
    expect(ellipsis.bottom, lessThanOrEqualTo(settings.top + 1));
    expect(ellipsis.bottom, lessThanOrEqualTo(800));
  });

  testWidgets('menu collapse does not drop the command row to the bottom',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_scene(menuItems: menu));
    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Close application menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    expect(find.text('settings'), findsOneWidget);
    final ellipsis =
        tester.getRect(find.bySemanticsLabel('Open application menu'));
    final settings = tester.getRect(find.text('settings'));
    expect(ellipsis.bottom, lessThanOrEqualTo(settings.top + 1));
    expect(ellipsis.bottom, lessThan(800 - 20));
  });

  testWidgets('system back closes the overflow before popping the route',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push<void>(
            PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondary) => Scaffold(
                body: const SizedBox.expand(),
                bottomNavigationBar: WpApplicationBar(menuItems: menu),
              ),
              transitionsBuilder: (context, animation, secondary, child) =>
                  child,
            ),
          ),
          child: const Text('open-bar'),
        ),
      ),
    ));
    await tester.tap(find.text('open-bar'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsNothing);
    expect(find.byType(WpApplicationBar), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(WpApplicationBar), findsNothing);
    expect(find.text('open-bar'), findsOneWidget);
  });

  testWidgets('four actions do not overlap the ellipsis at 240 and 320 widths',
      (tester) async {
    const actions = <WpApplicationBarAction>[
      WpApplicationBarAction(label: 'one', icon: Icon(Icons.looks_one)),
      WpApplicationBarAction(label: 'two', icon: Icon(Icons.looks_two)),
      WpApplicationBarAction(label: 'three', icon: Icon(Icons.looks_3)),
      WpApplicationBarAction(label: 'four', icon: Icon(Icons.looks_4)),
    ];
    for (final width in [240.0, 320.0, 480.0]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_scene(actions: actions, menuItems: menu));
      final ellipsis =
          tester.getRect(find.bySemanticsLabel('Open application menu'));
      for (final label in ['one', 'two', 'three', 'four']) {
        final rect = tester.getRect(find.bySemanticsLabel(label));
        expect(rect.right, lessThanOrEqualTo(ellipsis.left + 0.5),
            reason: '$label overlaps ellipsis at width $width');
        expect(rect.left, greaterThanOrEqualTo(-0.5));
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('reduced motion focus wash does not animate', (tester) async {
    await tester.pumpWidget(_scene(menuItems: menu, reducedMotion: true));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final highlight = find.descendant(
      of: find.bySemanticsLabel('Open application menu'),
      matching: find.byType(AnimatedContainer),
    );
    expect(
      tester.widget<AnimatedContainer>(highlight).duration,
      Duration.zero,
    );
  });
}
