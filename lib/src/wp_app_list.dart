import 'package:flutter/material.dart';

import 'wp_phone_theme.dart';
import 'wp_tilt_effect.dart';

/// Measured Windows Phone 8.1 WVGA app-list geometry.
///
/// Values are reference units in a 480-unit-wide coordinate space. The study
/// measured rendered pixels rather than source assets or universal OS tokens.
@visibleForTesting
abstract final class WpAppListGeometry {
  static const rowHeight = 74.0;
  static const iconSize = 62.0;
  static const iconTop = 6.0;
  static const iconLabelGap = 16.0;
  static const labelLeft = iconSize + iconLabelGap;
  static const labelFontSize = 25.0;
  static const contentLeft = 86.0;
  static const firstSlotTop = 51.0;
  static const leadingLeft = 24.0;
  static const leadingTop = 56.0;
  static const leadingSize = 44.0;
}

/// A caller-populated app-list surface using the measured WVGA layout.
///
/// At 480 logical pixels the content column starts at x=86. Slot origins use
/// a 74-pixel pitch beginning at y=51; the 6-pixel inset built into
/// [WpAppListHeader] and [WpAppListRow] therefore places their 62-pixel visual
/// frames at y=57, 131, 205, and so on. [leadingAction] is independently
/// positioned at x=24, y=56 in a 44-pixel square.
///
/// The caller supplies the rows, header order, leading action and callbacks.
/// This widget does not enumerate, sort, search, or launch applications.
class WpAppListView extends StatelessWidget {
  const WpAppListView({
    super.key,
    required this.children,
    this.leadingAction,
    this.controller,
    this.physics,
    this.referenceRightPadding = 24,
    this.referenceBottomPadding = 24,
  })  : assert(referenceRightPadding >= 0),
        assert(referenceBottomPadding >= 0);

  final List<Widget> children;
  final Widget? leadingAction;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double referenceRightPadding;
  final double referenceBottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth && constraints.hasBoundedHeight,
          'WpAppListView requires a bounded viewport.',
        );
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : theme.referenceWidth;
        final scale = width / theme.referenceWidth;
        return Stack(
          children: <Widget>[
            ListView.builder(
              controller: controller,
              physics: physics,
              padding: EdgeInsets.only(
                left: WpAppListGeometry.contentLeft * scale,
                top: WpAppListGeometry.firstSlotTop * scale,
                right: referenceRightPadding * scale,
                bottom: referenceBottomPadding * scale,
              ),
              itemExtent: WpAppListGeometry.rowHeight * scale,
              itemCount: children.length,
              itemBuilder: (context, index) => _WpAppListScale(
                scale: scale,
                child: children[index],
              ),
            ),
            if (leadingAction != null)
              Positioned(
                left: WpAppListGeometry.leadingLeft * scale,
                top: WpAppListGeometry.leadingTop * scale,
                width: WpAppListGeometry.leadingSize * scale,
                height: WpAppListGeometry.leadingSize * scale,
                child: leadingAction!,
              ),
          ],
        );
      },
    );
  }
}

/// A measured Windows Phone app-list row.
///
/// The row occupies 74 reference units at a 480-unit width. Its caller-provided
/// icon occupies a 62-unit square, starts 6 units below the row's top edge, and
/// leaves a 16-unit gap before [label]. The caller owns app discovery, sorting,
/// navigation, and list scrolling.
class WpAppListRow extends StatelessWidget {
  const WpAppListRow({
    super.key,
    required this.icon,
    required this.label,
    this.semanticLabel,
    this.onTap,
    this.iconBackgroundColor,
    this.iconForegroundColor,
    this.labelColor,
    this.backgroundColor,
    this.focusNode,
    this.autofocus = false,
  });

  final Widget icon;
  final String label;

  /// Accessibility label. Falls back to [label] when omitted.
  final String? semanticLabel;

  /// Activates this row. A null callback exposes a disabled row.
  final VoidCallback? onTap;

  final Color? iconBackgroundColor;
  final Color? iconForegroundColor;
  final Color? labelColor;
  final Color? backgroundColor;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    final enabled = onTap != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth,
          'WpAppListRow requires a bounded width.',
        );
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : theme.referenceWidth;
        final scale =
            _WpAppListScale.maybeOf(context) ?? width / theme.referenceWidth;
        final rowHeight = WpAppListGeometry.rowHeight * scale;
        final iconSize = WpAppListGeometry.iconSize * scale;
        final foreground = iconForegroundColor ?? theme.foregroundColor;

        return SizedBox(
          width: width,
          height: rowHeight,
          child: WpTiltEffect(
            enabled: enabled,
            child: Semantics(
              container: true,
              button: true,
              enabled: enabled,
              label: semanticLabel ?? label,
              onTap: onTap,
              excludeSemantics: true,
              child: Material(
                color: backgroundColor ?? Colors.transparent,
                child: InkWell(
                  focusNode: focusNode,
                  autofocus: autofocus,
                  canRequestFocus: enabled,
                  onTap: onTap,
                  excludeFromSemantics: true,
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  hoverColor: theme.foregroundColor.withAlpha(18),
                  focusColor: theme.foregroundColor.withAlpha(38),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Positioned(
                        key: const ValueKey('wp-app-list-icon-frame'),
                        left: 0,
                        top: WpAppListGeometry.iconTop * scale,
                        width: iconSize,
                        height: iconSize,
                        child: ColoredBox(
                          color: iconBackgroundColor ?? theme.accentColor,
                          child: IconTheme(
                            data: IconThemeData(
                              color: foreground,
                              size: 42 * scale,
                            ),
                            child: DefaultTextStyle(
                              style: TextStyle(
                                color: foreground,
                                fontFamily: theme.fontFamily,
                              ),
                              child: Center(child: icon),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        key: const ValueKey('wp-app-list-label-slot'),
                        left: WpAppListGeometry.labelLeft * scale,
                        top: 0,
                        right: 0,
                        height: rowHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: labelColor ?? theme.foregroundColor,
                              fontFamily: theme.fontFamily,
                              fontSize: WpAppListGeometry.labelFontSize * scale,
                              fontWeight: FontWeight.w400,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A reusable 74-unit app-list slot with a 62-unit letter frame at y=6.
///
/// [onTap] controls activation; the widget contains no alphabet-overlay state.
class WpAppListHeader extends StatelessWidget {
  const WpAppListHeader({
    super.key,
    required this.letter,
    this.semanticLabel,
    this.onTap,
    this.referenceScale = 1,
    this.color,
    this.foregroundColor,
    this.focusNode,
    this.autofocus = false,
  })  : assert(letter.length > 0),
        assert(referenceScale > 0);

  final String letter;
  final String? semanticLabel;
  final VoidCallback? onTap;

  /// Scale applied to the measured 62-unit square.
  final double referenceScale;

  final Color? color;
  final Color? foregroundColor;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    final enabled = onTap != null;
    final inheritedScale = _WpAppListScale.maybeOf(context) ?? 1;
    final scale = inheritedScale * referenceScale;
    final size = WpAppListGeometry.iconSize * scale;
    final accent = color ?? theme.accentColor;
    return SizedBox(
      width: size,
      height: WpAppListGeometry.rowHeight * scale,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(top: WpAppListGeometry.iconTop * scale),
          child: SizedBox.square(
            key: const ValueKey('wp-app-list-header-frame'),
            dimension: size,
            child: WpTiltEffect(
              enabled: enabled,
              child: Semantics(
                container: true,
                button: true,
                enabled: enabled,
                label: semanticLabel ?? letter,
                onTap: onTap,
                excludeSemantics: true,
                child: Material(
                  color: theme.backgroundColor,
                  shape: Border.all(color: accent, width: 3 * scale),
                  child: InkWell(
                    focusNode: focusNode,
                    autofocus: autofocus,
                    canRequestFocus: enabled,
                    onTap: onTap,
                    excludeFromSemantics: true,
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    hoverColor: theme.foregroundColor.withAlpha(18),
                    focusColor: theme.foregroundColor.withAlpha(38),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8 * scale),
                        child: Text(
                          letter,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            color: foregroundColor ?? accent,
                            fontFamily: theme.fontFamily,
                            fontSize: 40 * scale,
                            fontWeight: FontWeight.w300,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WpAppListScale extends InheritedWidget {
  const _WpAppListScale({required this.scale, required super.child});

  final double scale;

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_WpAppListScale>()?.scale;

  @override
  bool updateShouldNotify(_WpAppListScale oldWidget) =>
      scale != oldWidget.scale;
}
