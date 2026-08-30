import 'package:flutter/material.dart';

import 'wp_phone_theme.dart';
import 'wp_tilt_effect.dart';

/// A reusable Windows Phone tile surface.
///
/// The parent determines the tile's width and height, so the same primitive can
/// represent square or rectangular tiles. [editing] is controlled by the
/// caller; this widget does not persist, pin, unpin, or resize application data.
class WpTile extends StatefulWidget {
  const WpTile({
    super.key,
    required this.child,
    this.label,
    this.semanticLabel,
    this.color,
    this.onTap,
    this.onLongPress,
    this.editing = false,
    this.onUnpin,
    this.onResize,
  });

  final Widget child;

  /// Optional text rendered along the tile's lower edge.
  final String? label;

  /// Accessibility label. Falls back to [label] when omitted.
  final String? semanticLabel;

  /// Tile surface color. Defaults to [WpPhoneThemeData.accentColor].
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Whether caller-controlled edit affordances are visible.
  final bool editing;

  /// Called from the 45-reference-unit unpin affordance when provided.
  final VoidCallback? onUnpin;

  /// Called from the 46-reference-unit resize affordance when provided.
  final VoidCallback? onResize;

  @override
  State<WpTile> createState() => _WpTileState();
}

class _WpTileState extends State<WpTile> {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();
  bool _syncScheduled = false;

  bool get _showsEditOverlay =>
      widget.editing && (widget.onUnpin != null || widget.onResize != null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleOverlaySync();
  }

  @override
  void didUpdateWidget(covariant WpTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleOverlaySync();
  }

  void _scheduleOverlaySync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      if (_showsEditOverlay) {
        _overlayController.show();
      } else {
        _overlayController.hide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    final effectiveLabel = widget.semanticLabel ?? widget.label;
    final interactive = widget.onTap != null || widget.onLongPress != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth && constraints.hasBoundedHeight,
          'WpTile requires a parent-provided width and height.',
        );
        final referenceScale = constraints.maxWidth / 210;
        return OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (context) => Stack(
            children: <Widget>[
              if (widget.onUnpin != null)
                _editFollower(
                  center: const Offset(226, -22) * referenceScale,
                  visualSize: 45 * referenceScale,
                  semanticLabel: _editLabel('Unpin', effectiveLabel),
                  foregroundColor: theme.foregroundColor,
                  glyphColor: theme.backgroundColor,
                  onPressed: widget.onUnpin!,
                  glyph: _TileEditGlyph.unpin,
                ),
              if (widget.onResize != null)
                _editFollower(
                  center: const Offset(226, 214) * referenceScale,
                  visualSize: 46 * referenceScale,
                  semanticLabel: _editLabel('Resize', effectiveLabel),
                  foregroundColor: theme.foregroundColor,
                  glyphColor: theme.backgroundColor,
                  onPressed: widget.onResize!,
                  glyph: _TileEditGlyph.resize,
                ),
            ],
          ),
          child: CompositedTransformTarget(
            link: _layerLink,
            child: WpTiltEffect(
              enabled: interactive,
              child: Semantics(
                container: true,
                button: interactive,
                enabled: interactive,
                label: effectiveLabel,
                excludeSemantics: effectiveLabel != null,
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                child: Material(
                  color: widget.color ?? theme.accentColor,
                  child: InkWell(
                    excludeFromSemantics: true,
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    hoverColor: theme.foregroundColor.withAlpha(18),
                    focusColor: theme.foregroundColor.withAlpha(38),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        widget.child,
                        if (widget.label != null)
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 6,
                            child: Text(
                              widget.label!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.foregroundColor,
                                fontFamily: theme.fontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                height: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _editFollower({
    required Offset center,
    required double visualSize,
    required String semanticLabel,
    required Color foregroundColor,
    required Color glyphColor,
    required VoidCallback onPressed,
    required _TileEditGlyph glyph,
  }) {
    final hitSize = visualSize < 44 ? 44.0 : visualSize;
    return CompositedTransformFollower(
      link: _layerLink,
      showWhenUnlinked: false,
      offset: center - Offset(hitSize / 2, hitSize / 2),
      child: _TileEditButton(
        hitSize: hitSize,
        visualSize: visualSize,
        semanticLabel: semanticLabel,
        foregroundColor: foregroundColor,
        glyphColor: glyphColor,
        onPressed: onPressed,
        glyph: glyph,
      ),
    );
  }

  static String _editLabel(String action, String? tileLabel) {
    return tileLabel == null ? action : '$action $tileLabel';
  }
}

enum _TileEditGlyph { unpin, resize }

class _TileEditButton extends StatelessWidget {
  const _TileEditButton({
    required this.hitSize,
    required this.visualSize,
    required this.semanticLabel,
    required this.foregroundColor,
    required this.glyphColor,
    required this.onPressed,
    required this.glyph,
  });

  final double hitSize;
  final double visualSize;
  final String semanticLabel;
  final Color foregroundColor;
  final Color glyphColor;
  final VoidCallback onPressed;
  final _TileEditGlyph glyph;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: hitSize,
        child: Center(
          child: Material(
            color: glyphColor,
            shape: CircleBorder(
              side: BorderSide(color: foregroundColor, width: 3),
            ),
            child: InkWell(
              onTap: onPressed,
              excludeFromSemantics: true,
              customBorder: const CircleBorder(),
              splashFactory: NoSplash.splashFactory,
              child: SizedBox.square(
                key: ValueKey('wp-tile-edit-visual-${glyph.name}'),
                dimension: visualSize,
                child: CustomPaint(
                  painter: _TileEditGlyphPainter(glyph, foregroundColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TileEditGlyphPainter extends CustomPainter {
  const _TileEditGlyphPainter(this.glyph, this.color);

  final _TileEditGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;
    final center = Offset(size.width / 2, size.height / 2);
    if (glyph == _TileEditGlyph.unpin) {
      canvas
        ..drawLine(center.translate(-6, -7), center.translate(6, 5), paint)
        ..drawLine(center.translate(-7, 6), center.translate(7, -8), paint)
        ..drawLine(center.translate(-3, -10), center.translate(9, 2), paint)
        ..drawLine(center.translate(2, 4), center.translate(-6, 12), paint);
      return;
    }
    canvas
      ..drawLine(center.translate(-7, 7), center.translate(7, -7), paint)
      ..drawLine(center.translate(1, -7), center.translate(7, -7), paint)
      ..drawLine(center.translate(7, -7), center.translate(7, -1), paint)
      ..drawLine(center.translate(-1, 7), center.translate(-7, 7), paint)
      ..drawLine(center.translate(-7, 7), center.translate(-7, 1), paint);
  }

  @override
  bool shouldRepaint(covariant _TileEditGlyphPainter oldDelegate) {
    return glyph != oldDelegate.glyph || color != oldDelegate.color;
  }
}
