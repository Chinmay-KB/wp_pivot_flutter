import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:example/component_gallery_shell.dart';
import 'package:example/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';

Widget _gallery({bool disableAnimations = false}) {
  return ComponentGallery(disableAnimations: disableAnimations);
}

void _phoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Duration _homeToAppBarDuration() {
  final timing = WpTurnstileFeatherTiming(
    outgoingMaxIndex: 8,
    incomingMaxIndex: WpTurnstileFeather.detailPageMaxIndex,
  );
  return timing.routeDuration();
}

Finder _hardwareBackIn(Type demoType) {
  return find.descendant(
    of: find.byType(demoType),
    matching: find.byKey(const ValueKey('wp-preview-hardware-back')),
  );
}

Future<void> _tapGalleryEntry(WidgetTester tester, String title) async {
  final tapKey = switch (title) {
    'application bar' => const ValueKey('wp-phone-entry-tap-3'),
    'panorama' => const ValueKey('wp-phone-entry-tap-4'),
    'toggle switch' => const ValueKey('wp-phone-entry-tap-5'),
    _ => throw ArgumentError('Unknown gallery entry: $title'),
  };
  final finder = find.byKey(tapKey);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  final origin = tester.getTopLeft(finder);
  await tester.tapAt(origin + const Offset(8, 8));
  await tester.pump();
}

void main() {
  testWidgets('gallery home has no Material chevron or AppBar chrome',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.bySemanticsLabel('Hardware back'), findsNothing);
    expect(find.text('components'), findsOneWidget);
  });

  testWidgets('opening a demo uses WpPhonePageRoute not MaterialPageRoute',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());
    await _tapGalleryEntry(tester, 'application bar');
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ApplicationBarDemo), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    final route =
        ModalRoute.of(tester.element(find.byType(ApplicationBarDemo)));
    expect(route, isA<WpPhonePageRoute<void>>());
    expect(route, isNot(isA<MaterialPageRoute<void>>()));
    expect(route!.transitionDuration, _homeToAppBarDuration());
    expect(route.opaque, isFalse);
  });

  testWidgets(
      'TurnstileFeather forward-in shows title before later content index',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());
    await _tapGalleryEntry(tester, 'application bar');
    await tester.pump();
    final outPhase = WpTurnstileFeather.forwardOutPhaseMsFor(8);
    await tester.pump(Duration(milliseconds: outPhase + 50));
    final title = tester.widget<Opacity>(find.descendant(
      of: find.byType(ApplicationBarDemo),
      matching: find.byKey(const ValueKey('wp-phone-title')),
    ));
    final content = tester.widget<Opacity>(find.descendant(
      of: find.byType(ApplicationBarDemo),
      matching: find.byKey(const ValueKey('wp-phone-content')),
    ));
    final header = tester.widget<Opacity>(find.descendant(
      of: find.byType(ApplicationBarDemo),
      matching: find.byKey(const ValueKey('wp-phone-header')),
    ));
    expect(header.opacity, 1);
    expect(title.opacity, 1);
    expect(content.opacity, 0);
  });

  testWidgets('incoming ApplicationBar stays hidden during outgoing phase',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());
    await _tapGalleryEntry(tester, 'application bar');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(WpApplicationBar), findsNothing);
    expect(
        find.byKey(const ValueKey('wp-preview-hardware-back')), findsNothing);
  });

  testWidgets('hub rows feather independently during forward out',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());
    await _tapGalleryEntry(tester, 'application bar');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final toggleTransform = tester.widget<Transform>(find.descendant(
      of: find.byKey(const ValueKey('wp-phone-entry-5')),
      matching: find.byType(Transform),
    ));
    final appBarTransform = tester.widget<Transform>(find.descendant(
      of: find.byKey(const ValueKey('wp-phone-entry-3')),
      matching: find.byType(Transform),
    ));
    expect(
      appBarTransform.transform.entry(0, 0).abs(),
      lessThan(toggleTransform.transform.entry(0, 0).abs()),
    );
  });

  testWidgets('escape returns to gallery home via sendKeyEvent',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());
    await _tapGalleryEntry(tester, 'toggle switch');
    await tester.pumpAndSettle();
    expect(find.byType(ToggleSwitchDemo), findsOneWidget);
    await tester.tap(find.text('connections'));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ToggleSwitchDemo), findsNothing);
    expect(find.text('components'), findsOneWidget);
  });

  testWidgets('system back returns to the gallery home', (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());
    await _tapGalleryEntry(tester, 'panorama');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PanoramaDemo), findsNothing);
    expect(find.text('components'), findsOneWidget);
  });

  testWidgets('preview hardware back pops a demo without Material chevrons',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());
    await _tapGalleryEntry(tester, 'toggle switch');
    await tester.pumpAndSettle();
    expect(find.byType(ToggleSwitchDemo), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    await tester.tap(_hardwareBackIn(ToggleSwitchDemo));
    await tester.pumpAndSettle();
    expect(find.byType(ToggleSwitchDemo), findsNothing);
    expect(find.text('components'), findsOneWidget);
    expect(find.bySemanticsLabel('Hardware back'), findsNothing);
  });

  testWidgets(
      'gallery overflow Back closes menu first then pops ApplicationBarDemo',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());
    await _tapGalleryEntry(tester, 'application bar');
    await tester.pumpAndSettle();
    expect(find.byType(ApplicationBarDemo), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsNothing);
    expect(find.byType(ApplicationBarDemo), findsOneWidget);
    expect(find.byType(WpApplicationBar), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ApplicationBarDemo), findsNothing);
    expect(find.text('components'), findsOneWidget);
  });

  testWidgets('preview hardware back stays visible when overflow is open',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());
    await _tapGalleryEntry(tester, 'application bar');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsOneWidget);
    expect(_hardwareBackIn(ApplicationBarDemo), findsOneWidget);
    expect(find.bySemanticsLabel('Hardware back'), findsOneWidget);
  });

  testWidgets('preview hardware back closes overflow first then pops the page',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());
    await _tapGalleryEntry(tester, 'application bar');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Open application menu'));
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsOneWidget);

    await tester.tap(_hardwareBackIn(ApplicationBarDemo));
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsNothing);
    expect(find.byType(ApplicationBarDemo), findsOneWidget);

    await tester.tap(_hardwareBackIn(ApplicationBarDemo));
    await tester.pumpAndSettle();
    expect(find.byType(ApplicationBarDemo), findsNothing);
    expect(find.text('components'), findsOneWidget);
  });

  testWidgets('reduced motion presents settled title and content',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery(disableAnimations: true));
    await _tapGalleryEntry(tester, 'application bar');
    await tester.pump();
    final title = tester.widget<Opacity>(find.descendant(
      of: find.byType(ApplicationBarDemo),
      matching: find.byKey(const ValueKey('wp-phone-title')),
    ));
    final content = tester.widget<Opacity>(find.descendant(
      of: find.byType(ApplicationBarDemo),
      matching: find.byKey(const ValueKey('wp-phone-content')),
    ));
    expect(title.opacity, 1);
    expect(content.opacity, 1);
    expect(find.byType(WpApplicationBar), findsOneWidget);
  });

  testWidgets('reverse incoming paints home and hides leaving ApplicationBar',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());
    await _tapGalleryEntry(tester, 'application bar');
    await tester.pumpAndSettle();
    expect(find.byType(WpApplicationBar), findsOneWidget);
    await tester.tap(_hardwareBackIn(ApplicationBarDemo));
    await tester.pump();
    await tester.pump(Duration(
      milliseconds: WpTurnstileFeather.backwardOutPhaseMsFor(2) + 100,
    ));
    expect(find.text('windows phone').hitTestable(), findsOneWidget);
    expect(find.text('application bar').hitTestable(), findsOneWidget);
    expect(find.byType(WpApplicationBar), findsNothing);
  });

  testWidgets('gallery text does not inherit WidgetsApp error typography',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());

    TextStyle inherited(Finder finder) =>
        DefaultTextStyle.of(tester.element(finder)).style;

    final header = inherited(find.text('windows phone'));
    expect(header.decoration, TextDecoration.none);
    expect(header.color, Colors.white);
    expect(header.fontFamily, wpPivotFontFamily);
    expect(header.fontWeight, FontWeight.w300);
    expect(header.debugLabel ?? '', isNot(contains('fallback')));

    final intro =
        tester.widget<Text>(find.textContaining('Experimental Flutter'));
    expect(intro.style?.decoration, TextDecoration.none);
    expect(intro.style?.color, const Color(0x99ffffff));

    final row = tester.widget<Text>(find.text('application bar'));
    expect(row.style?.decoration, TextDecoration.none);
    expect(row.style?.color, Colors.white);

    await _tapGalleryEntry(tester, 'application bar');
    await tester.pumpAndSettle();
    final message =
        tester.widget<Text>(find.text('Tap a command or open the menu.'));
    expect(message.style?.color, Colors.white);
    expect(message.style?.decoration, TextDecoration.none);
    expect(
      DefaultTextStyle.of(
              tester.element(find.text('Tap a command or open the menu.')))
          .style
          .decoration,
      TextDecoration.none,
    );
  });

  testWidgets(
      'view focus plus semantics on home does not read unlaid-out boxes',
      (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_gallery());
    await tester.pumpAndSettle();
    expect(find.text('windows phone'), findsOneWidget);
    expect(find.text('toggle switch'), findsOneWidget);

    final semantics = tester.ensureSemantics();
    try {
      tester.binding.handleViewFocusChanged(
        ViewFocusEvent(
          viewId: tester.view.viewId,
          state: ViewFocusState.focused,
          direction: ViewFocusDirection.forward,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('windows phone'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
