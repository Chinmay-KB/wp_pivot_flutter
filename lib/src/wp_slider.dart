import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Geometry from the WP8 dark-theme `PhoneSlider` control template.
@visibleForTesting
abstract final class WpSliderGeometry {
  static const height = 84.0;
  static const horizontalMargin = 12.0;
  static const trackTop = 22.0;
  static const trackHeight = 12.0;
  static const thumbTop = 16.0;
  static const thumbWidth = 12.0;
  static const thumbHeight = 24.0;
}

/// A controlled slider using the Windows Phone 8 track and thumb anatomy.
class WpSlider extends StatefulWidget {
  const WpSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 10,
    this.divisions,
    this.accentColor = const Color(0xff1ba1e2),
    this.trackColor = const Color(0xff1f1f1f),
    this.thumbColor = Colors.white,
    this.semanticLabel,
    this.autofocus = false,
  })  : assert(max > min),
        assert(value >= min && value <= max),
        assert(divisions == null || divisions > 0);

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final Color accentColor;
  final Color trackColor;
  final Color thumbColor;
  final String? semanticLabel;
  final bool autofocus;

  @override
  State<WpSlider> createState() => _WpSliderState();
}

class _WpSliderState extends State<WpSlider> {
  late final FocusNode _focusNode;

  bool get _enabled => widget.onChanged != null;
  double get _range => widget.max - widget.min;
  double get _normalized => (widget.value - widget.min) / _range;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'WpSlider');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  double _quantize(double value) {
    final clamped = value.clamp(widget.min, widget.max).toDouble();
    final divisions = widget.divisions;
    if (divisions == null) return clamped;
    final step = _range / divisions;
    return widget.min + ((clamped - widget.min) / step).round() * step;
  }

  void _setFromX(double x, double width, TextDirection direction) {
    if (!_enabled) return;
    final firstCenter =
        WpSliderGeometry.horizontalMargin + WpSliderGeometry.thumbWidth / 2;
    final usable = math.max(
      1.0,
      width -
          WpSliderGeometry.horizontalMargin * 2 -
          WpSliderGeometry.thumbWidth,
    );
    var t = ((x - firstCenter) / usable).clamp(0.0, 1.0);
    if (direction == TextDirection.rtl) t = 1 - t;
    final next = _quantize(widget.min + t * _range);
    if (next != widget.value) widget.onChanged!(next);
  }

  void _step(double direction) {
    if (!_enabled) return;
    final amount = _range / (widget.divisions ?? 10);
    final next = _quantize(widget.value + amount * direction);
    if (next != widget.value) widget.onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final visualValue =
        direction == TextDirection.rtl ? 1 - _normalized : _normalized;
    final valueText = widget.value.toStringAsFixed(
      widget.value == widget.value.roundToDouble() ? 0 : 2,
    );
    return Semantics(
      container: true,
      slider: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      value: valueText,
      increasedValue: _quantize(
        widget.value + _range / (widget.divisions ?? 10),
      ).toString(),
      decreasedValue: _quantize(
        widget.value - _range / (widget.divisions ?? 10),
      ).toString(),
      onIncrease: _enabled ? () => _step(1) : null,
      onDecrease: _enabled ? () => _step(-1) : null,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        enabled: _enabled,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowRight):
              DirectionalFocusIntent(TraversalDirection.right),
          SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(
            TraversalDirection.left,
          ),
        },
        actions: <Type, Action<Intent>>{
          DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
            onInvoke: (intent) {
              final visualDirection =
                  intent.direction == TraversalDirection.right ? 1.0 : -1.0;
              _step(direction == TextDirection.rtl
                  ? -visualDirection
                  : visualDirection);
              return null;
            },
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.hasBoundedWidth ? constraints.maxWidth : 480.0;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _enabled
                  ? (details) =>
                      _setFromX(details.localPosition.dx, width, direction)
                  : null,
              onHorizontalDragStart: _enabled
                  ? (details) =>
                      _setFromX(details.localPosition.dx, width, direction)
                  : null,
              onHorizontalDragUpdate: _enabled
                  ? (details) =>
                      _setFromX(details.localPosition.dx, width, direction)
                  : null,
              child: CustomPaint(
                key: const ValueKey('wp-slider-track'),
                size: Size(width, WpSliderGeometry.height),
                painter: WpSliderPainter(
                  normalizedValue: visualValue,
                  enabled: _enabled,
                  accentColor: widget.accentColor,
                  trackColor: widget.trackColor,
                  thumbColor: widget.thumbColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

@visibleForTesting
class WpSliderPainter extends CustomPainter {
  const WpSliderPainter({
    required this.normalizedValue,
    required this.enabled,
    required this.accentColor,
    required this.trackColor,
    required this.thumbColor,
  });

  final double normalizedValue;
  final bool enabled;
  final Color accentColor;
  final Color trackColor;
  final Color thumbColor;

  @override
  void paint(Canvas canvas, Size size) {
    final left = WpSliderGeometry.horizontalMargin;
    final width = math.max(0.0, size.width - left * 2);
    final thumbTravel = math.max(0.0, width - WpSliderGeometry.thumbWidth);
    final thumbLeft = left + thumbTravel * normalizedValue.clamp(0.0, 1.0);
    final thumbCenter = thumbLeft + WpSliderGeometry.thumbWidth / 2;
    final track = Rect.fromLTWH(
      left,
      WpSliderGeometry.trackTop,
      width,
      WpSliderGeometry.trackHeight,
    );
    final disabled = const Color(0x66ffffff);
    canvas.drawRect(
      track,
      Paint()..color = enabled ? trackColor : trackColor.withValues(alpha: .1),
    );
    canvas.drawRect(
      Rect.fromLTRB(left, track.top, thumbCenter, track.bottom),
      Paint()..color = enabled ? accentColor : disabled,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        thumbLeft,
        WpSliderGeometry.thumbTop,
        WpSliderGeometry.thumbWidth,
        WpSliderGeometry.thumbHeight,
      ),
      Paint()..color = thumbColor,
    );
  }

  @override
  bool shouldRepaint(covariant WpSliderPainter oldDelegate) =>
      oldDelegate.normalizedValue != normalizedValue ||
      oldDelegate.enabled != enabled ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.thumbColor != thumbColor;
}
