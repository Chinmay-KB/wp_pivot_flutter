import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wp_pivot_flutter/wp_components.dart';

void main() {
  test('dark defaults expose the measured WVGA tokens', () {
    const data = WpPhoneThemeData.dark();

    expect(data.backgroundColor, const Color(0xff000000));
    expect(data.foregroundColor, const Color(0xffffffff));
    expect(data.accentColor, const Color(0xff3e65ff));
    expect(data.disabledColor, const Color(0xff202020));
    expect(data.referenceWidth, 480);
    expect(data.fontFamily, 'packages/wp_pivot_flutter/Selawik');
  });

  testWidgets('of falls back to dark defaults without an inherited theme',
      (tester) async {
    late WpPhoneThemeData data;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            data = WpPhoneTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(data, const WpPhoneThemeData.dark());
    expect(WpPhoneTheme.maybeOf(tester.element(find.byType(SizedBox))), isNull);
  });

  testWidgets('nearest WpPhoneTheme overrides individual tokens',
      (tester) async {
    const custom = WpPhoneThemeData.dark(
      accentColor: Color(0xffaa00cc),
      referenceWidth: 360,
      fontFamily: 'Example',
    );
    late WpPhoneThemeData data;
    await tester.pumpWidget(
      MaterialApp(
        home: WpPhoneTheme(
          data: custom,
          child: Builder(
            builder: (context) {
              data = WpPhoneTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(data, custom);
    expect(data.backgroundColor, Colors.black);
  });

  test('copyWith preserves unspecified theme tokens', () {
    const original = WpPhoneThemeData.dark();
    final changed = original.copyWith(accentColor: const Color(0xff00aa00));

    expect(changed.accentColor, const Color(0xff00aa00));
    expect(changed.backgroundColor, original.backgroundColor);
    expect(changed.referenceWidth, original.referenceWidth);
    expect(changed.fontFamily, original.fontFamily);
  });
}
