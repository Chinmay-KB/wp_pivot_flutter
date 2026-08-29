import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Authoritative 89×38 ToggleSwitch chrome from batch-04 grok-toggle-audit-01.
@visibleForTesting
class WpToggleSwitchGeometry {
  static const trackWidth = 89.0;
  static const trackHeight = 38.0;
  static const frameTop = 2.0;
  static const frameHeight = 34.0;
  static const strokeWidth = 3.0;
  static const thumbWhiteWidth = 20.0;
  static const thumbSideWidth = 4.0;
  static const thumbOffWhiteLeft = 0.0;
  static const thumbOnWhiteLeft = 69.0;
  static const fillLeft = 7.0;
  static const fillTop = 9.0;
  static const fillRight = 65.0;
  static const fillBottom = 29.0;
  static const gutterOffLeft = 20.0;
  static const gutterOffRight = 24.0;
  static const gutterOnLeft = 65.0;
  static const gutterOnRight = 69.0;
}

/// A controlled, Windows Phone Toolkit-inspired on/off control.
///
/// [value] remains the source of truth: callers must update it after
/// [onChanged] is invoked. The visual proportions and animation are
/// provisional until they are calibrated against an emulator capture.
class WpToggleSwitch extends StatefulWidget {
  const WpToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.header,
    this.onLabel = 'On',
    this.offLabel = 'Off',
    this.accentColor,
    this.duration = const Duration(milliseconds: 50),
    this.autofocus = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? header;
  final String onLabel;
  final String offLabel;

  /// The active Metro color. Defaults to the historical Phone blue.
  final Color? accentColor;
  final Duration duration;

  /// When true, requests focus on mount. Defaults to false so lists of switches
  /// do not compete for initial focus.
  final bool autofocus;

  @override
  State<WpToggleSwitch> createState() => _WpToggleSwitchState();
}

@visibleForTesting
class ToggleTrackPainter extends CustomPainter {
  ToggleTrackPainter({
    required this.value,
    required this.enabled,
    required this.thumbPosition,
    required this.accentColor,
  });

  final bool value;
  final bool enabled;
  final double thumbPosition;
  final Color accentColor;

  static const Color _disabledChrome = Color(0xff484848);

  double get thumbWhiteLeft =>
      WpToggleSwitchGeometry.thumbOffWhiteLeft +
      thumbPosition *
          (WpToggleSwitchGeometry.thumbOnWhiteLeft -
              WpToggleSwitchGeometry.thumbOffWhiteLeft);

  (double left, double right) get gutterRange {
    final center = thumbWhiteLeft + WpToggleSwitchGeometry.thumbWhiteWidth / 2;
    if (center < WpToggleSwitchGeometry.trackWidth / 2) {
      return (
        thumbWhiteLeft + WpToggleSwitchGeometry.thumbWhiteWidth,
        thumbWhiteLeft +
            WpToggleSwitchGeometry.thumbWhiteWidth +
            WpToggleSwitchGeometry.thumbSideWidth,
      );
    }
    return (
      thumbWhiteLeft - WpToggleSwitchGeometry.thumbSideWidth,
      thumbWhiteLeft,
    );
  }

  Color get _chromeColor => enabled ? Colors.white : _disabledChrome;

  Color get _fillColor => enabled ? accentColor : _disabledChrome;

  @override
  void paint(Canvas canvas, Size size) {
    final black = Paint()..color = Colors.black;
    final chrome = Paint()..color = _chromeColor;
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        WpToggleSwitchGeometry.trackWidth,
        WpToggleSwitchGeometry.trackHeight,
      ),
      black,
    );

    final (gutterLeft, gutterRight) = gutterRange;
    final frameBottom =
        WpToggleSwitchGeometry.frameTop + WpToggleSwitchGeometry.frameHeight;

    void rect(
      Paint paint,
      double left,
      double top,
      double right,
      double bottom,
    ) {
      if (right > left && bottom > top) {
        canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);
      }
    }

    for (final yRange in <(double, double)>[
      (2, 5),
      (frameBottom - 3, frameBottom)
    ]) {
      rect(chrome, 0, yRange.$1, gutterLeft, yRange.$2);
      rect(
        chrome,
        gutterRight,
        yRange.$1,
        WpToggleSwitchGeometry.trackWidth,
        yRange.$2,
      );
    }

    rect(
      chrome,
      0,
      WpToggleSwitchGeometry.frameTop,
      WpToggleSwitchGeometry.strokeWidth,
      frameBottom,
    );
    rect(
      chrome,
      WpToggleSwitchGeometry.trackWidth - WpToggleSwitchGeometry.strokeWidth,
      WpToggleSwitchGeometry.frameTop,
      WpToggleSwitchGeometry.trackWidth,
      frameBottom,
    );

    if (value) {
      rect(
        Paint()..color = _fillColor,
        WpToggleSwitchGeometry.fillLeft,
        WpToggleSwitchGeometry.fillTop,
        WpToggleSwitchGeometry.fillRight,
        WpToggleSwitchGeometry.fillBottom,
      );
    }

    rect(
      black,
      gutterLeft,
      0,
      gutterRight,
      WpToggleSwitchGeometry.trackHeight,
    );
    rect(
      chrome,
      thumbWhiteLeft,
      0,
      thumbWhiteLeft + WpToggleSwitchGeometry.thumbWhiteWidth,
      WpToggleSwitchGeometry.trackHeight,
    );
  }

  @override
  bool shouldRepaint(covariant ToggleTrackPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.enabled != enabled ||
      oldDelegate.thumbPosition != thumbPosition ||
      oldDelegate.accentColor != accentColor;
}

class _WpToggleSwitchState extends State<WpToggleSwitch> {
  static const _tapSlop = 18.0;

  bool _dragging = false;
  double _dragValue = 0;
  double _dragStartX = 0;
  double _dragLatestX = 0;
  bool _pointerMoved = false;
  bool _pointerCancelled = false;
  late final FocusNode _focusNode;
  bool _showFocusHighlight = false;
  bool _keyboardInteraction = false;
  bool _suppressKeyboardFocusHighlight = false;

  bool get _enabled => widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'WpToggleSwitch');
  }

  @override
  void didUpdateWidget(covariant WpToggleSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onChanged == null || oldWidget.value != widget.value) {
      _dragging = false;
      _dragValue = widget.value ? 1 : 0;
      _pointerMoved = false;
      _pointerCancelled = false;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _request(bool next) {
    if (!_enabled || next == widget.value) return;
    widget.onChanged!(next);
  }

  void _dragStart(DragStartDetails details, TextDirection direction) {
    if (!_enabled) return;
    setState(() {
      _dragging = true;
      _dragValue = widget.value ? 1 : 0;
    });
  }

  double _valueAtX(double x, TextDirection direction) {
    final sign = direction == TextDirection.rtl ? -1.0 : 1.0;
    final startValue = widget.value ? 1.0 : 0.0;
    return (startValue +
            (x - _dragStartX) * sign / WpToggleSwitchGeometry.trackWidth)
        .clamp(0.0, 1.0);
  }

  void _dragUpdate(DragUpdateDetails details, TextDirection direction) {
    if (!_enabled || !_dragging) return;
    setState(() {
      _dragLatestX = details.globalPosition.dx;
      _dragValue = _valueAtX(_dragLatestX, direction);
    });
  }

  void _dragEnd(TextDirection direction, {bool cancelled = false}) {
    if (!_dragging) return;
    final target = _valueAtX(_dragLatestX, direction) >= .5;
    setState(() => _dragging = false);
    if (!cancelled && !_pointerCancelled) _request(target);
  }

  Widget _buildTrack({
    required double thumbPosition,
    required Color accentColor,
  }) {
    final painter = ToggleTrackPainter(
      value: widget.value,
      enabled: _enabled,
      thumbPosition: thumbPosition,
      accentColor: accentColor,
    );
    return CustomPaint(
      key: const ValueKey('wp-toggle-track'),
      size: const Size(
        WpToggleSwitchGeometry.trackWidth,
        WpToggleSwitchGeometry.trackHeight,
      ),
      painter: painter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final activeColor = widget.accentColor ?? const Color(0xff3b5fff);
    final thumbPosition = _dragging ? _dragValue : (widget.value ? 1.0 : 0.0);
    final duration =
        reducedMotion || _dragging ? Duration.zero : widget.duration;
    final label = widget.value ? widget.onLabel : widget.offLabel;
    final headerStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 20,
          height: 1.1,
          fontWeight: FontWeight.w300,
          color: _enabled ? const Color(0xffa6a6a6) : const Color(0xff282828),
        );
    final valueStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 32,
          height: 1.05,
          fontWeight: FontWeight.w300,
          color: _enabled ? const Color(0xfff8f8f8) : const Color(0xff484848),
        );

    Widget switchVisual;
    if (duration == Duration.zero) {
      switchVisual = _buildTrack(
        thumbPosition: thumbPosition,
        accentColor: activeColor,
      );
    } else {
      switchVisual = TweenAnimationBuilder<double>(
        tween: Tween<double>(
          end: widget.value ? 1.0 : 0.0,
        ),
        duration: duration,
        curve: Curves.easeOutExpo,
        builder: (context, position, child) => _buildTrack(
          thumbPosition: position,
          accentColor: activeColor,
        ),
      );
    }

    switchVisual = SizedBox(
      width: WpToggleSwitchGeometry.trackWidth,
      height: WpToggleSwitchGeometry.trackHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          switchVisual,
          if (_showFocusHighlight && _keyboardInteraction)
            const Positioned.fill(
              child: IgnorePointer(
                child: SizedBox(
                  key: ValueKey('wp-toggle-focus-ring'),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: textScaler.scale(76)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.header != null) Text(widget.header!, style: headerStyle),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle,
                ),
              ),
              const SizedBox(width: 16),
              switchVisual,
            ],
          ),
        ],
      ),
    );

    return FocusableActionDetector(
      focusNode: _focusNode,
      enabled: _enabled,
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        if (!focused) {
          if (_showFocusHighlight || _keyboardInteraction) {
            setState(() {
              _keyboardInteraction = false;
              _showFocusHighlight = false;
            });
          }
          return;
        }
        if (_suppressKeyboardFocusHighlight) return;
        if (FocusManager.instance.highlightMode ==
            FocusHighlightMode.traditional) {
          setState(() {
            _keyboardInteraction = true;
            _showFocusHighlight = _focusNode.hasFocus;
          });
        }
      },
      onShowFocusHighlight: (show) {
        final visible = show && _keyboardInteraction;
        if (_showFocusHighlight != visible) {
          setState(() => _showFocusHighlight = visible);
        }
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (!_keyboardInteraction) {
              setState(() {
                _keyboardInteraction = true;
                _showFocusHighlight = _focusNode.hasFocus;
              });
            }
            _request(!widget.value);
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled
            ? () {
                if (!_pointerMoved) _request(!widget.value);
              }
            : null,
        onHorizontalDragStart:
            _enabled ? (details) => _dragStart(details, direction) : null,
        onHorizontalDragUpdate:
            _enabled ? (details) => _dragUpdate(details, direction) : null,
        onHorizontalDragEnd: _enabled ? (_) => _dragEnd(direction) : null,
        onHorizontalDragCancel:
            _enabled ? () => _dragEnd(direction, cancelled: true) : null,
        child: Listener(
          onPointerDown: _enabled
              ? (event) {
                  _suppressKeyboardFocusHighlight = true;
                  _keyboardInteraction = false;
                  if (_showFocusHighlight) {
                    setState(() => _showFocusHighlight = false);
                  }
                  _focusNode.requestFocus();
                  _dragStartX = event.position.dx;
                  _dragLatestX = _dragStartX;
                  _pointerMoved = false;
                  _pointerCancelled = false;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _suppressKeyboardFocusHighlight = false;
                  });
                }
              : null,
          onPointerCancel: _enabled ? (_) => _pointerCancelled = true : null,
          onPointerMove: _enabled
              ? (event) {
                  _dragLatestX = event.position.dx;
                  _pointerMoved = _pointerMoved ||
                      (_dragLatestX - _dragStartX).abs() > _tapSlop;
                }
              : null,
          child: Semantics(
            container: true,
            toggled: widget.value,
            enabled: _enabled,
            label: widget.header == null ? label : '${widget.header}, $label',
            onTap: _enabled ? () => _request(!widget.value) : null,
            child: ExcludeSemantics(child: content),
          ),
        ),
      ),
    );
  }
}
