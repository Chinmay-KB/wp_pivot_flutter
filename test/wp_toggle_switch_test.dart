import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/src/wp_toggle_switch.dart';

Widget scene({
  required bool value,
  ValueChanged<bool>? onChanged,
  bool reducedMotion = false,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  String? header = 'Wi-Fi',
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: reducedMotion,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox(
            width: 280,
            child: WpToggleSwitch(
              value: value,
              onChanged: onChanged,
              header: header,
            ),
          ),
        ),
      ),
    ),
  );
}

Finder semanticsFor(String header, bool value) =>
    find.bySemanticsLabel('$header, ${value ? 'On' : 'Off'}');

ToggleTrackPainter trackPainter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(WpToggleSwitch),
      matching: find.byKey(const ValueKey('wp-toggle-track')),
    ),
  );
  return paint.painter! as ToggleTrackPainter;
}

double thumbWhiteLeft(WidgetTester tester) =>
    trackPainter(tester).thumbWhiteLeft;

Rect trackOuterRect(WidgetTester tester) {
  final trackFinder = find.descendant(
    of: find.byType(WpToggleSwitch),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is SizedBox && widget.width == 89.0 && widget.height == 38.0,
    ),
  );
  return tester.getRect(trackFinder);
}

Rect thumbRect(WidgetTester tester) {
  final track = trackOuterRect(tester);
  final left = thumbWhiteLeft(tester);
  return Rect.fromLTWH(
    track.left + left,
    track.top,
    WpToggleSwitchGeometry.thumbWhiteWidth,
    WpToggleSwitchGeometry.trackHeight,
  );
}

Widget twoSwitchScene({
  required bool first,
  required bool second,
  required ValueChanged<bool> onFirstChanged,
  required ValueChanged<bool> onSecondChanged,
}) {
  return MaterialApp(
    home: Center(
      child: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            WpToggleSwitch(
              key: const ValueKey('first-switch'),
              value: first,
              onChanged: onFirstChanged,
              header: 'First',
            ),
            WpToggleSwitch(
              key: const ValueKey('second-switch'),
              value: second,
              onChanged: onSecondChanged,
              header: 'Second',
            ),
            const WpToggleSwitch(
              key: ValueKey('disabled-switch'),
              value: false,
              onChanged: null,
              header: 'Disabled',
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('is controlled and allows a deliberate retry after rejection',
      (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(scene(value: false, onChanged: changes.add));
    await tester.tap(find.byType(WpToggleSwitch));
    await tester.tap(find.byType(WpToggleSwitch));
    expect(changes, <bool>[true, true]);

    await tester.pumpWidget(scene(value: true, onChanged: changes.add));
    await tester.tap(find.byType(WpToggleSwitch));
    expect(changes, <bool>[true, true, false]);
  });

  testWidgets('drag commits only after crossing its midpoint', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(scene(value: false, onChanged: changes.add));
    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(WpToggleSwitch)));
    await gesture.moveBy(const Offset(30, 0));
    await gesture.moveBy(const Offset(50, 0));
    await gesture.up();
    expect(changes, <bool>[true]);
  });

  testWidgets(
      'cancelled drag and a short drag leave controlled state untouched',
      (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(scene(value: false, onChanged: changes.add));
    final short = await tester
        .startGesture(tester.getCenter(find.byType(WpToggleSwitch)));
    await short.moveBy(const Offset(30, 0));
    await short.up();
    expect(changes, isEmpty, reason: 'short horizontal movement is not a tap');
    final cancelled = await tester
        .startGesture(tester.getCenter(find.byType(WpToggleSwitch)));
    await cancelled.moveBy(const Offset(60, 0));
    await cancelled.cancel();
    expect(changes, isEmpty);
    await tester.tap(find.byType(WpToggleSwitch));
    expect(changes, <bool>[true],
        reason: 'the next independent tap remains available after a drag');
  });

  testWidgets('disabled switch rejects tap and drag', (tester) async {
    await tester.pumpWidget(scene(value: true));
    expect(
        tester.getSemantics(semanticsFor('Wi-Fi', true)),
        matchesSemantics(
          hasEnabledState: true,
          isEnabled: false,
          hasToggledState: true,
          isToggled: true,
        ));
    await tester.tap(find.byType(WpToggleSwitch));
    await tester.drag(find.byType(WpToggleSwitch), const Offset(-80, 0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard activation and semantics expose a toggle',
      (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(scene(value: false, onChanged: changes.add));
    await tester.tap(find.byType(WpToggleSwitch));
    await tester.pumpWidget(scene(value: true, onChanged: changes.add));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpWidget(scene(value: false, onChanged: changes.add));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(changes, <bool>[true, false, true]);
    expect(
        tester.getSemantics(semanticsFor('Wi-Fi', false)),
        matchesSemantics(
          hasEnabledState: true,
          isEnabled: true,
          hasToggledState: true,
          hasTapAction: true,
        ));
  });

  testWidgets('pointer focus directs keyboard input to that switch',
      (tester) async {
    final firstChanges = <bool>[];
    final secondChanges = <bool>[];
    Future<void> pump({required bool first, required bool second}) =>
        tester.pumpWidget(twoSwitchScene(
          first: first,
          second: second,
          onFirstChanged: firstChanges.add,
          onSecondChanged: secondChanges.add,
        ));

    await pump(first: false, second: false);
    await tester.tap(find.byKey(const ValueKey('second-switch')));
    expect(firstChanges, isEmpty);
    expect(secondChanges, <bool>[true]);
    expect(find.byKey(const ValueKey('wp-toggle-focus-ring')), findsNothing);

    await pump(first: false, second: true);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(firstChanges, isEmpty);
    expect(secondChanges, <bool>[true, false]);
    expect(find.byKey(const ValueKey('wp-toggle-focus-ring')), findsOneWidget);

    await pump(first: false, second: false);
    await tester.tap(find.byKey(const ValueKey('disabled-switch')));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(firstChanges, isEmpty);
    expect(secondChanges, <bool>[true, false, true]);
  });

  testWidgets('reconciles an in-progress drag across disable and value updates',
      (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(scene(value: false, onChanged: changes.add));
    final disabledDrag = await tester
        .startGesture(tester.getCenter(find.byType(WpToggleSwitch)));
    await disabledDrag.moveBy(const Offset(30, 0));
    await tester.pumpWidget(scene(value: false));
    await tester.pumpAndSettle();
    expect(thumbWhiteLeft(tester), WpToggleSwitchGeometry.thumbOffWhiteLeft);
    await disabledDrag.up();
    expect(changes, isEmpty);

    await tester.pumpWidget(scene(value: false, onChanged: changes.add));
    await tester.tap(find.byType(WpToggleSwitch));
    expect(changes, <bool>[true]);

    await tester.pumpWidget(scene(value: true, onChanged: changes.add));
    await tester.pumpAndSettle();
    expect(thumbWhiteLeft(tester), WpToggleSwitchGeometry.thumbOnWhiteLeft);
    final externalUpdateDrag = await tester
        .startGesture(tester.getCenter(find.byType(WpToggleSwitch)));
    await externalUpdateDrag.moveBy(const Offset(-30, 0));
    await tester.pumpWidget(scene(value: false, onChanged: changes.add));
    await externalUpdateDrag.moveBy(const Offset(-20, 0));
    await tester.pumpAndSettle();
    expect(thumbWhiteLeft(tester), WpToggleSwitchGeometry.thumbOffWhiteLeft);
    await externalUpdateDrag.up();
    expect(changes, <bool>[true]);

    await tester.tap(find.byType(WpToggleSwitch));
    expect(changes, <bool>[true, true]);
  });

  testWidgets('RTL, reduced motion and enlarged text remain laid out',
      (tester) async {
    final changes = <bool>[];
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(scene(
      value: false,
      onChanged: changes.add,
      reducedMotion: true,
      direction: TextDirection.rtl,
      textScale: 2,
      header: 'Wireless network availability',
    ));
    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(WpToggleSwitch)));
    await gesture.moveBy(const Offset(-30, 0));
    await gesture.moveBy(const Offset(-50, 0));
    await gesture.up();
    await tester.pump();
    expect(changes, <bool>[true]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pointer tap does not show the default focus rectangle',
      (tester) async {
    await tester.pumpWidget(scene(value: false, onChanged: (_) {}));
    await tester.tap(find.byType(WpToggleSwitch));
    await tester.pump();
    expect(find.byKey(const ValueKey('wp-toggle-focus-ring')), findsNothing);
  });

  testWidgets('tab focus shows keyboard ring without pointer chrome',
      (tester) async {
    await tester.pumpWidget(scene(value: false, onChanged: (_) {}));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.byKey(const ValueKey('wp-toggle-focus-ring')), findsOneWidget);
  });

  testWidgets('narrow width keeps the switch track width and ellipsizes labels',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 240,
          child: WpToggleSwitch(
            value: false,
            onChanged: (_) {},
            header: 'Wireless network availability',
            offLabel: 'Unavailable for the current profile',
          ),
        ),
      ),
    ));
    expect(tester.getSize(find.byType(WpToggleSwitch)).width, 240);
    final track = tester.getSize(find.descendant(
      of: find.byType(WpToggleSwitch),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 89.0 && widget.height == 38.0,
      ),
    ));
    expect(track.width, 89);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'enlarged text grows row height without shrinking the switch track',
      (tester) async {
    await tester.pumpWidget(scene(
      value: true,
      onChanged: (_) {},
      textScale: 2,
      header: 'Wi-Fi',
    ));
    expect(tester.getSize(find.byType(WpToggleSwitch)).height, greaterThan(76));
    final track = tester.getSize(find.descendant(
      of: find.byType(WpToggleSwitch),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 89.0 && widget.height == 38.0,
      ),
    ));
    expect(track.width, 89);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OFF and ON rest geometry match native frame, fill, and thumb',
      (tester) async {
    await tester.pumpWidget(scene(value: false, onChanged: (_) {}));
    await tester.pumpAndSettle();
    final offTrack = trackOuterRect(tester);
    final offPainter = trackPainter(tester);
    expect(offTrack.width, WpToggleSwitchGeometry.trackWidth);
    expect(offTrack.height, WpToggleSwitchGeometry.trackHeight);
    expect(
      thumbWhiteLeft(tester),
      WpToggleSwitchGeometry.thumbOffWhiteLeft,
    );
    expect(offPainter.gutterRange.$1, WpToggleSwitchGeometry.gutterOffLeft);
    expect(offPainter.gutterRange.$2, WpToggleSwitchGeometry.gutterOffRight);

    await tester.pumpWidget(scene(value: true, onChanged: (_) {}));
    await tester.pumpAndSettle();
    final onTrack = trackOuterRect(tester);
    final onPainter = trackPainter(tester);
    expect(onTrack.width, WpToggleSwitchGeometry.trackWidth);
    expect(onTrack.height, WpToggleSwitchGeometry.trackHeight);
    expect(
      thumbWhiteLeft(tester),
      WpToggleSwitchGeometry.thumbOnWhiteLeft,
    );
    expect(onPainter.gutterRange.$1, WpToggleSwitchGeometry.gutterOnLeft);
    expect(onPainter.gutterRange.$2, WpToggleSwitchGeometry.gutterOnRight);
    expect(onPainter.value, isTrue);
  });

  testWidgets('disabled ON keeps enabled anatomy with faded chrome',
      (tester) async {
    await tester
        .pumpWidget(scene(value: true, onChanged: null, header: 'Disabled'));
    await tester.pumpAndSettle();
    final painter = trackPainter(tester);
    expect(painter.enabled, isFalse);
    expect(painter.value, isTrue);
    expect(
      thumbWhiteLeft(tester),
      WpToggleSwitchGeometry.thumbOnWhiteLeft,
    );
    expect(painter.gutterRange.$1, WpToggleSwitchGeometry.gutterOnLeft);
    expect(painter.gutterRange.$2, WpToggleSwitchGeometry.gutterOnRight);
  });

  testWidgets('rendered OFF mid-row has thumb flush left and 4px gutter',
      (tester) async {
    await tester.pumpWidget(
      RepaintBoundary(
        child: CustomPaint(
          size: const Size(
            WpToggleSwitchGeometry.trackWidth,
            WpToggleSwitchGeometry.trackHeight,
          ),
          painter: ToggleTrackPainter(
            value: false,
            enabled: true,
            thumbPosition: 0,
            accentColor: const Color(0xff3b5fff),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary),
    );
    final capture = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
      return (image.width, bytes!.buffer.asUint8List());
    });
    expect(capture, isNotNull);
    final width = capture!.$1;
    final data = capture.$2;
    final midY = WpToggleSwitchGeometry.trackHeight ~/ 2;

    int rgba(int x, int y) {
      final i = (y * width + x) * 4;
      return data[i] + data[i + 1] + data[i + 2];
    }

    expect(rgba(0, midY), greaterThan(600));
    expect(rgba(3, midY), greaterThan(600));
    expect(rgba(22, midY), lessThan(48));
    expect(rgba(87, midY), greaterThan(600));
  });

  testWidgets('rendered ON fill is 58x20 inset inside frame recess',
      (tester) async {
    await tester.pumpWidget(
      RepaintBoundary(
        child: CustomPaint(
          size: const Size(
            WpToggleSwitchGeometry.trackWidth,
            WpToggleSwitchGeometry.trackHeight,
          ),
          painter: ToggleTrackPainter(
            value: true,
            enabled: true,
            thumbPosition: 1,
            accentColor: const Color(0xff3b5fff),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary),
    );
    final capture = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
      return (image.width, bytes!.buffer.asUint8List());
    });
    expect(capture, isNotNull);
    final width = capture!.$1;
    final data = capture.$2;

    int rgba(int x, int y) {
      final i = (y * width + x) * 4;
      return data[i] + data[i + 1] + data[i + 2];
    }

    expect(
      rgba(
        WpToggleSwitchGeometry.fillLeft.toInt(),
        WpToggleSwitchGeometry.fillTop.toInt(),
      ),
      greaterThan(200),
    );
    expect(
      rgba(
        WpToggleSwitchGeometry.fillRight.toInt() - 1,
        WpToggleSwitchGeometry.fillBottom.toInt() - 1,
      ),
      greaterThan(200),
    );
    expect(rgba(36, 5), lessThan(48));
    expect(rgba(36, 32), lessThan(48));
    expect(rgba(5, 19), lessThan(48));
    expect(rgba(66, 19), lessThan(48));
  });
}
