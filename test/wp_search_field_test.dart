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
  testWidgets('field reproduces measured 480-unit geometry', (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpSearchField(controller: controller, onChanged: (_) {}),
        ),
      ),
    );

    expect(tester.getSize(find.byType(WpSearchField)), const Size(480, 74));
    expect(
      tester.getSize(find.byKey(const ValueKey('wp-search-field-inner'))),
      const Size(480, 62),
    );

    final field =
        tester.widget<TextField>(find.byKey(const ValueKey('wp-search-field')));
    expect(field.style?.fontSize, 25);
    expect(field.style?.color, Colors.white);
    expect(field.style?.fontFamily, const WpPhoneThemeData.dark().fontFamily);
    expect(field.cursorColor, const Color(0xff3e65ff));
    expect(field.decoration?.hintText, 'search');
    final enabledBorder =
        field.decoration?.enabledBorder! as UnderlineInputBorder;
    expect(enabledBorder.borderSide.color, Colors.white);
    expect(enabledBorder.borderSide.width, 1);
    final focusedBorder =
        field.decoration?.focusedBorder! as UnderlineInputBorder;
    expect(focusedBorder.borderSide.color, const Color(0xff3e65ff));
    expect(focusedBorder.borderSide.width, 2);
  });

  testWidgets('field scales proportionally with available width',
      (tester) async {
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 240,
          child: WpSearchField(onChanged: (_) {}),
        ),
      ),
    );

    expect(tester.getSize(find.byType(WpSearchField)), const Size(240, 37));
    expect(
      tester.getSize(find.byKey(const ValueKey('wp-search-field-inner'))),
      const Size(240, 31),
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('wp-search-field')))
          .style
          ?.fontSize,
      12.5,
    );
  });

  testWidgets('field exposes search semantics and forwards edits only',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final seen = <String>[];
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpSearchField(controller: controller, onChanged: seen.add),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Search apps'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('wp-search-field')),
      'cal',
    );
    expect(controller.text, 'cal');
    expect(seen, <String>['cal']);

    // The widget performs no filtering itself; it only forwards edits.
    await tester.enterText(
      find.byKey(const ValueKey('wp-search-field')),
      'calc',
    );
    expect(seen, <String>['cal', 'calc']);
    expect(find.byType(WpSearchField), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('field supports autofocus and external focus nodes',
      (tester) async {
    final autoNode = FocusNode(debugLabel: 'auto-search');
    addTearDown(autoNode.dispose);
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpSearchField(
            key: const ValueKey('autofocus-search'),
            focusNode: autoNode,
            autofocus: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(autoNode.hasFocus, isTrue);

    final idleNode = FocusNode(debugLabel: 'idle-search');
    addTearDown(idleNode.dispose);
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpSearchField(
            key: const ValueKey('idle-search'),
            focusNode: idleNode,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(idleNode.hasFocus, isFalse);
  });

  testWidgets('field consumes theme colors and explicit overrides',
      (tester) async {
    const theme = WpPhoneThemeData.dark(
      accentColor: Color(0xff112233),
      foregroundColor: Color(0xffeeeeee),
    );
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpSearchField(onChanged: (_) {}),
        ),
        theme: theme,
      ),
    );

    var field =
        tester.widget<TextField>(find.byKey(const ValueKey('wp-search-field')));
    expect(field.cursorColor, const Color(0xff112233));
    expect(field.style?.color, const Color(0xffeeeeee));
    expect(
      (field.decoration?.enabledBorder! as UnderlineInputBorder)
          .borderSide
          .color,
      const Color(0xffeeeeee),
    );
    expect(
      (field.decoration?.focusedBorder! as UnderlineInputBorder)
          .borderSide
          .color,
      const Color(0xff112233),
    );
    expect(
      field.decoration?.hintStyle?.color,
      const Color(0xffeeeeee).withAlpha(138),
    );

    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpSearchField(
            hintText: 'find apps',
            foregroundColor: const Color(0xffaa3300),
            accentColor: const Color(0xff00ff00),
            hintColor: const Color(0xff0000ff),
            onChanged: (_) {},
          ),
        ),
        theme: theme,
      ),
    );

    field =
        tester.widget<TextField>(find.byKey(const ValueKey('wp-search-field')));
    expect(field.decoration?.hintText, 'find apps');
    expect(field.style?.color, const Color(0xffaa3300));
    expect(field.cursorColor, const Color(0xff00ff00));
    expect(field.decoration?.hintStyle?.color, const Color(0xff0000ff));
    expect(
      (field.decoration?.focusedBorder! as UnderlineInputBorder)
          .borderSide
          .color,
      const Color(0xff00ff00),
    );
  });

  testWidgets('disabled field uses the disabled underline', (tester) async {
    await tester.pumpWidget(
      _scene(
        const SizedBox(
          width: 480,
          child: WpSearchField(onChanged: null),
        ),
      ),
    );

    final field =
        tester.widget<TextField>(find.byKey(const ValueKey('wp-search-field')));
    expect(field.enabled, isFalse);
    expect(
      (field.decoration?.disabledBorder! as UnderlineInputBorder)
          .borderSide
          .color,
      const Color(0xff202020),
    );
  });

  testWidgets('field honors reduced motion for the cursor', (tester) async {
    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpSearchField(onChanged: (_) {}),
        ),
      ),
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('wp-search-field')))
          .cursorOpacityAnimates,
      isTrue,
    );

    await tester.pumpWidget(
      _scene(
        SizedBox(
          width: 480,
          child: WpSearchField(onChanged: (_) {}),
        ),
        disableAnimations: true,
      ),
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('wp-search-field')))
          .cursorOpacityAnimates,
      isFalse,
    );
  });
}
