import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

Widget _scene(
  Widget tile, {
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
              body: Align(alignment: Alignment.topLeft, child: tile),
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets('uses parent size, theme color, label style, and tilt wrapper',
      (tester) async {
    const theme = WpPhoneThemeData.dark(
      accentColor: Color(0xff112233),
      foregroundColor: Color(0xfffafafa),
    );
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 210,
          height: 99,
          child: WpTile(
            label: 'Calendar',
            onTap: () {},
            child: const SizedBox(),
          ),
        ),
        theme: theme,
      ),
    );

    expect(tester.getSize(find.byType(WpTile)), const Size(210, 99));
    expect(find.byType(WpTiltEffect), findsOneWidget);
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(WpTile),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, theme.accentColor);
    final label = tester.widget<Text>(find.text('Calendar'));
    expect(label.style?.fontFamily, theme.fontFamily);
    expect(label.style?.color, theme.foregroundColor);
  });

  testWidgets('exposes one semantic tile and invokes tap and long press',
      (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    var longPresses = 0;
    await tester.pumpWidget(
      _scene(
        SizedBox.square(
          dimension: 210,
          child: WpTile(
            label: 'Visual label',
            semanticLabel: 'Calendar live tile',
            onTap: () => taps++,
            onLongPress: () => longPresses++,
            child: const Text('duplicate child semantics'),
          ),
        ),
      ),
    );

    final tile = find.bySemanticsLabel('Calendar live tile');
    expect(tile, findsOneWidget);
    expect(find.bySemanticsLabel('duplicate child semantics'), findsNothing);
    final data = tester.getSemantics(tile).getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.hasAction(SemanticsAction.longPress), isTrue);

    await tester.tap(tile);
    await tester.longPress(tile);
    expect(taps, 1);
    expect(longPresses, 1);
    semantics.dispose();
  });

  testWidgets('editing is controlled and edit controls keep measured sizes',
      (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var unpins = 0;
    var resizes = 0;
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          height: 800,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 24,
                top: 500,
                width: 210,
                height: 210,
                child: WpTile(
                  label: 'Calendar',
                  editing: true,
                  onUnpin: () => unpins++,
                  onResize: () => resizes++,
                  child: const SizedBox(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final unpin = find.bySemanticsLabel('Unpin Calendar');
    final resize = find.bySemanticsLabel('Resize Calendar');
    expect(tester.getSize(unpin), const Size.square(45));
    expect(tester.getSize(resize), const Size.square(46));
    expect(tester.getCenter(unpin), const Offset(250, 478));
    expect(tester.getCenter(resize), const Offset(250, 714));
    expect(
      tester.getRect(unpin),
      const Rect.fromLTWH(227.5, 455.5, 45, 45),
    );
    expect(
      tester.getRect(resize),
      const Rect.fromLTWH(227, 691, 46, 46),
    );
    final unpinMaterial = tester.widget<Material>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('wp-tile-edit-visual-unpin')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(unpinMaterial.color, Colors.black);
    final circle = unpinMaterial.shape! as CircleBorder;
    expect(circle.side.color, Colors.white);
    expect(circle.side.width, 3);

    await tester.tap(unpin);
    await tester.tap(resize);
    expect(unpins, 1);
    expect(resizes, 1);

    await tester.pumpWidget(
      _scene(
        const SizedBox.square(
          dimension: 210,
          child: WpTile(
            label: 'Calendar',
            editing: false,
            child: SizedBox(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Unpin Calendar'), findsNothing);
    expect(find.bySemanticsLabel('Resize Calendar'), findsNothing);
  });

  testWidgets('edit visuals scale while hit targets remain accessible',
      (tester) async {
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          height: 800,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 20,
                top: 200,
                width: 140,
                height: 140,
                child: WpTile(
                  label: 'Scaled',
                  editing: true,
                  onUnpin: () {},
                  onResize: () {},
                  child: const SizedBox(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final unpin = find.bySemanticsLabel('Unpin Scaled');
    final resize = find.bySemanticsLabel('Resize Scaled');
    expect(tester.getSize(unpin), const Size.square(44));
    expect(tester.getSize(resize), const Size.square(44));
    expect(
      tester.getSize(
        find.byKey(const ValueKey('wp-tile-edit-visual-unpin')),
      ),
      const Size.square(30),
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('wp-tile-edit-visual-resize')),
          )
          .width,
      closeTo(46 * 2 / 3, .001),
    );
    expect(tester.getCenter(unpin).dx, closeTo(20 + 226 * 2 / 3, .001));
    expect(tester.getCenter(unpin).dy, closeTo(200 - 22 * 2 / 3, .001));
    expect(tester.getCenter(resize).dx, closeTo(20 + 226 * 2 / 3, .001));
    expect(tester.getCenter(resize).dy, closeTo(200 + 214 * 2 / 3, .001));
  });

  testWidgets('system reduced motion leaves the tilt transform at rest',
      (tester) async {
    await tester.pumpWidget(
      _scene(
        SizedBox.square(
          dimension: 210,
          child: WpTile(
            semanticLabel: 'Tile',
            onTap: () {},
            child: const SizedBox(),
          ),
        ),
        disableAnimations: true,
      ),
    );

    final gesture = await tester.startGesture(const Offset(30, 30));
    await tester.pump();
    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('wp-tilt-transform')),
    );
    expect(transform.transform, Matrix4.identity());
    await gesture.up();
  });

  testWidgets('explicit color overrides the inherited accent', (tester) async {
    const override = Color(0xffcc4400);
    await tester.pumpWidget(
      _scene(
        const SizedBox.square(
          dimension: 99,
          child: WpTile(
            color: override,
            child: SizedBox(),
          ),
        ),
      ),
    );

    expect(
      tester.widget<Material>(find.byType(Material).last).color,
      override,
    );
  });
}
