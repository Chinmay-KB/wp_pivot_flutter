import 'package:flutter/material.dart';

import 'wp_phone_theme.dart';

/// Measured Windows Phone 8.1 app-list search/close affordance geometry.
///
/// Values are reference units: a 44-unit circular control with a 2-unit ring
/// and a 28-unit glyph. The 44-unit diameter satisfies the minimum touch
/// target at the 480-unit reference width.
@visibleForTesting
abstract final class WpCircularAffordanceGeometry {
  /// Reference diameter of the circular control.
  static const size = 44.0;

  /// Reference width of the white ring.
  static const ringWidth = 2.0;

  /// Reference size of the search/close glyph box.
  static const glyphSize = 28.0;

  /// Reference stroke width of the glyph.
  static const strokeWidth = 2.8;

  /// Reference radius of the magnifier lens.
  static const lensRadius = 7.5;

  /// Reference half-extent of the close X arms.
  static const closeHalf = 7.0;
}

/// A reusable circular app-list search/close affordance.
///
/// The transparent circle carries a 2-unit ring and a 28-unit glyph: a
/// magnifier while browsing and a close X while [searching]. The glyph and
/// ring scale proportionally with [size]; keep [size] at 44 or above so the
/// control remains a 44-unit minimum touch target.
///
/// The widget owns presentation and activation only. The caller owns search
/// state, query text, and list updates.
class WpCircularAffordance extends StatelessWidget {
  const WpCircularAffordance({
    super.key,
    required this.searching,
    required this.onPressed,
    this.size = WpCircularAffordanceGeometry.size,
    this.semanticLabel,
    this.ringColor,
    this.glyphColor,
    this.focusNode,
    this.autofocus = false,
  }) : assert(size > 0);

  /// Whether the app-list search is open (shows the close glyph).
  final bool searching;

  /// Activates the affordance. A null callback exposes a disabled control.
  final VoidCallback? onPressed;

  /// Reference-unit diameter. The ring and glyph scale proportionally.
  final double size;

  /// Accessibility label. Defaults to `Close app search`/`Search apps`.
  final String? semanticLabel;

  /// Ring color. Defaults to the theme foreground.
  final Color? ringColor;

  /// Glyph color. Defaults to the theme foreground.
  final Color? glyphColor;

  /// Focus for keyboard activation. The ink response uses its own default
  /// when omitted.
  final FocusNode? focusNode;

  /// When true, requests focus on mount.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    final ring = ringColor ?? theme.foregroundColor;
    final glyph = glyphColor ?? theme.foregroundColor;
    final label =
        semanticLabel ?? (searching ? 'Close app search' : 'Search apps');
    final enabled = onPressed != null;
    final scale = size / WpCircularAffordanceGeometry.size;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: CircleBorder(
          side: BorderSide(
            color: ring,
            width: WpCircularAffordanceGeometry.ringWidth * scale,
          ),
        ),
        child: InkWell(
          focusNode: focusNode,
          autofocus: autofocus,
          canRequestFocus: enabled,
          onTap: onPressed,
          excludeFromSemantics: true,
          customBorder: const CircleBorder(),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: glyph.withAlpha(18),
          focusColor: glyph.withAlpha(38),
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: WpSearchGlyph(
                close: searching,
                color: glyph,
                dimension: WpCircularAffordanceGeometry.glyphSize * scale,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The source-aligned search/close glyph, independent of the Material icon
/// font so it has the same silhouette in test and production.
class WpSearchGlyph extends StatelessWidget {
  const WpSearchGlyph({
    super.key,
    required this.close,
    this.color,
    this.strokeWidth = WpCircularAffordanceGeometry.strokeWidth,
    this.dimension = WpCircularAffordanceGeometry.glyphSize,
  })  : assert(strokeWidth > 0),
        assert(dimension > 0);

  /// Whether to draw the close X (true) or the magnifier (false).
  final bool close;

  /// Glyph color. Defaults to the theme foreground.
  final Color? color;

  /// Reference-unit stroke width, scaled with [dimension].
  final double strokeWidth;

  /// Reference-unit glyph box size.
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    return SizedBox.square(
      dimension: dimension,
      child: CustomPaint(
        key: const ValueKey('wp-search-glyph'),
        painter: WpSearchGlyphPainter(
          close: close,
          color: color ?? theme.foregroundColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

/// Paints [WpSearchGlyph]: a magnifier (circle r7.5 plus handle) or a close X
/// (arms at plus-or-minus 7), drawn with a 2.8-unit square-capped stroke in a
/// 28-unit box. Metrics scale proportionally when the box differs from 28
/// reference units.
@visibleForTesting
class WpSearchGlyphPainter extends CustomPainter {
  const WpSearchGlyphPainter({
    required this.close,
    required this.color,
    required this.strokeWidth,
  });

  /// Whether to draw the close X (true) or the magnifier (false).
  final bool close;

  /// Glyph color.
  final Color color;

  /// Reference-unit stroke width.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / WpCircularAffordanceGeometry.glyphSize;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.square;
    final center = Offset(size.width / 2, size.height / 2);
    if (close) {
      final half = WpCircularAffordanceGeometry.closeHalf * scale;
      canvas.drawLine(
        center.translate(-half, -half),
        center.translate(half, half),
        paint,
      );
      canvas.drawLine(
        center.translate(half, -half),
        center.translate(-half, half),
        paint,
      );
      return;
    }
    canvas.drawCircle(
      center.translate(-3 * scale, -3 * scale),
      WpCircularAffordanceGeometry.lensRadius * scale,
      paint,
    );
    canvas.drawLine(
      center.translate(3 * scale, 3 * scale),
      center.translate(10 * scale, 10 * scale),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant WpSearchGlyphPainter oldDelegate) =>
      oldDelegate.close != close ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
