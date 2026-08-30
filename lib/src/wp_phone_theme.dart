import 'package:flutter/material.dart';

import 'wp_pivot_view.dart' show wpPivotFontFamily;

/// Shared visual tokens for Windows Phone inspired components.
///
/// The default values are grounded in the Windows Phone 8.1 WVGA Start-screen
/// study. They describe component presentation only; applications remain
/// responsible for navigation, persistence, and launcher state.
@immutable
class WpPhoneThemeData {
  const WpPhoneThemeData({
    this.backgroundColor = const Color(0xff000000),
    this.foregroundColor = const Color(0xffffffff),
    this.accentColor = const Color(0xff3e65ff),
    this.disabledColor = const Color(0xff202020),
    this.referenceWidth = 480,
    this.fontFamily = wpPivotFontFamily,
  }) : assert(referenceWidth > 0);

  /// The dark Windows Phone palette observed in the reference study.
  const WpPhoneThemeData.dark({
    this.backgroundColor = const Color(0xff000000),
    this.foregroundColor = const Color(0xffffffff),
    this.accentColor = const Color(0xff3e65ff),
    this.disabledColor = const Color(0xff202020),
    this.referenceWidth = 480,
    this.fontFamily = wpPivotFontFamily,
  }) : assert(referenceWidth > 0);

  final Color backgroundColor;
  final Color foregroundColor;
  final Color accentColor;
  final Color disabledColor;

  /// Width of the coordinate space used by measured WVGA geometry.
  final double referenceWidth;

  /// Package-qualified OFL Selawik font family.
  final String fontFamily;

  WpPhoneThemeData copyWith({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? accentColor,
    Color? disabledColor,
    double? referenceWidth,
    String? fontFamily,
  }) {
    return WpPhoneThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      accentColor: accentColor ?? this.accentColor,
      disabledColor: disabledColor ?? this.disabledColor,
      referenceWidth: referenceWidth ?? this.referenceWidth,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WpPhoneThemeData &&
            backgroundColor == other.backgroundColor &&
            foregroundColor == other.foregroundColor &&
            accentColor == other.accentColor &&
            disabledColor == other.disabledColor &&
            referenceWidth == other.referenceWidth &&
            fontFamily == other.fontFamily;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        foregroundColor,
        accentColor,
        disabledColor,
        referenceWidth,
        fontFamily,
      );
}

/// Supplies [WpPhoneThemeData] to descendant Windows Phone components.
///
/// Descendants without a [WpPhoneTheme] use [WpPhoneThemeData.dark].
class WpPhoneTheme extends InheritedTheme {
  const WpPhoneTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final WpPhoneThemeData data;

  /// Returns the nearest theme, or the measured dark defaults.
  static WpPhoneThemeData of(BuildContext context) {
    return maybeOf(context) ?? const WpPhoneThemeData.dark();
  }

  /// Returns the nearest theme, if one exists.
  static WpPhoneThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WpPhoneTheme>()?.data;
  }

  @override
  bool updateShouldNotify(WpPhoneTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return WpPhoneTheme(data: data, child: child);
  }
}
