import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pivot_controller.dart';
import 'pivot_header.dart';
import 'pivot_motion.dart';

/// Bundled OFL-licensed fallback for Segoe WP. See assets/fonts/OFL.txt.
const wpPivotFontFamily = 'packages/wp_pivot_flutter/Selawik';

/// A complete Pivot: native-sized cyclic headers and separate content transitions.
///
/// Unlike a WpPivot app bar paired with PageView, the header follows the drag while
/// only the current page moves. Selection commits on release, then outgoing and
/// incoming content animate in sequence. Children keep their state while hidden.
/// Dimensions scale from a 480-unit WP reference viewport; text scaling remains
/// available for accessibility. Selawik is bundled under the OFL; proprietary
/// Segoe WP fonts are not included.
class WpPivotView extends StatefulWidget {
  const WpPivotView({
    super.key,
    required this.title,
    required this.tabTitles,
    required this.children,
    this.controller,
    this.onChanged,
    this.backgroundColor = Colors.black,
    this.selectedTabColor = Colors.white,
    this.unselectedTabColor = const Color(0xff666666),
    this.headerFontFamily = wpPivotFontFamily,
    this.titleFontFamily = wpPivotFontFamily,
    this.headerFontWeight = FontWeight.w300,
    this.titleFontWeight = FontWeight.w600,
    this.referenceWidth = 480,
    this.motion = const PivotMotion(),
    this.wrap = true,
    this.safeArea = true,
  }) : assert(referenceWidth > 0);

  final String title;
  final List<String> tabTitles;
  final List<Widget> children;
  final PivotController? controller;
  final ValueChanged<int>? onChanged;
  final Color backgroundColor, selectedTabColor, unselectedTabColor;
  final String? headerFontFamily, titleFontFamily;
  final FontWeight headerFontWeight, titleFontWeight;
  final double referenceWidth;
  final PivotMotion motion;
  final bool wrap, safeArea;

  @override
  State<WpPivotView> createState() => _WpPivotViewState();
}

class _WpPivotViewState extends State<WpPivotView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  PivotController? _owned;
  PivotController get _controller => widget.controller ?? _owned!;
  int _selected = 0, _displayed = 0, _anchor = 0, _direction = 1;
  bool _dragging = false,
      _changing = false,
      _cancelling = false,
      _syncing = false;
  bool _headerDragStarted = false;
  double _width = 480, _scale = 1, _bodyX = 0, _headerX = 0;
  double _bodyStart = 0, _headerStart = 0;
  List<double> _widths = [];
  List<String> _measuredTitles = [];
  TextStyle? _measuredStyle;
  TextScaler? _measuredScaler;
  int? _pointer;
  Offset _current = Offset.zero;
  Duration _lastMotionTime = Duration.zero, _lastPointerTime = Duration.zero;
  Duration? _stationaryMoveTime;
  double _segmentVelocity = 0;
  double _bodyOrigin = 0, _headerOrigin = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _owned = widget.controller == null
        ? PivotController(length: widget.children.length)
        : null;
    _selected = _displayed = _anchor = _controller.index;
    _controller.addListener(_externalSelection);
    _clock = AnimationController(vsync: this)
      ..addListener(_tick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce && !_reduceMotion && _clock.isAnimating) _finish();
    _reduceMotion = reduce;
  }

  @override
  void didUpdateWidget(covariant WpPivotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.children.length != widget.children.length) {
      (oldWidget.controller ?? _owned)?.removeListener(_externalSelection);
      final previous = _selected;
      _owned?.dispose();
      _owned = widget.controller == null
          ? PivotController(
              length: widget.children.length, initialIndex: previous)
          : null;
      _controller.addListener(_externalSelection);
      _selected = _controller.index;
      _finish();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_externalSelection);
    _owned?.dispose();
    _clock.dispose();
    super.dispose();
  }

  int _wrapped(int value) => value % widget.children.length;
  double _span(int index) =>
      _widths.isEmpty ? 0 : PivotHeader.span(_widths[_wrapped(index)], _scale);

  void _externalSelection() {
    if (!_syncing && _controller.index != _selected) _select(_controller.index);
  }

  void _finish() {
    _clock.stop();
    _changing = _cancelling = _dragging = false;
    _displayed = _anchor = _selected;
    _bodyX = _headerX = 0;
    if (mounted) setState(() {});
  }

  void _select(int target, {int? direction}) {
    if (widget.children.isEmpty || target == _selected) return;
    target = target.clamp(0, widget.children.length - 1);
    if (_clock.isAnimating) _finish();
    final old = _selected;
    _direction = direction ?? (target > old ? 1 : -1);
    _bodyStart = _bodyX;
    // Non-adjacent taps rearrange the headers before the final one-slot slide.
    _headerStart = _direction > 0
        ? _span(target - 1) + _headerX
        : -_span(target) + _headerX;
    _anchor = _selected = target;
    _displayed = old;
    _dragging = false;
    _changing = true;
    _cancelling = false;
    _headerX = _headerStart;
    _syncing = true;
    _controller.animateTo(target);
    _syncing = false;
    widget.onChanged?.call(target);
    if (_reduceMotion) {
      _finish();
    } else {
      final bodyDuration =
          widget.motion.exitDuration + widget.motion.enterDuration;
      _clock.duration = widget.motion.headerDuration > bodyDuration
          ? widget.motion.headerDuration
          : bodyDuration;
      _clock.forward(from: 0);
      setState(() {});
    }
  }

  void _tick() {
    final ms = _clock.value * _clock.duration!.inMicroseconds / 1000;
    final spec = widget.motion;
    double phase(Duration duration, double elapsed) => duration == Duration.zero
        ? 1
        : (elapsed / (duration.inMicroseconds / 1000)).clamp(0, 1);
    final h = spec.headerCurve.transform(phase(spec.headerDuration, ms));
    _headerX = _headerStart * (1 - h);
    if (_cancelling) {
      _bodyX = _bodyStart *
          (1 - spec.contentCurve.transform(phase(spec.headerDuration, ms)));
    } else if (_changing) {
      final exitMs = spec.exitDuration.inMicroseconds / 1000;
      if (ms < exitMs) {
        final p = spec.contentCurve.transform(phase(spec.exitDuration, ms));
        _bodyX = _bodyStart + (-_direction * _width - _bodyStart) * p;
      } else {
        _displayed = _selected;
        final p =
            spec.contentCurve.transform(phase(spec.enterDuration, ms - exitMs));
        _bodyX = _direction * _width * (1 - p);
      }
    }
    setState(() {});
  }

  void _cancelDrag() {
    if (!_dragging) return;
    _dragging = false;
    _cancelling = true;
    _bodyStart = _bodyX;
    _headerStart = _headerX;
    if (_reduceMotion) {
      _finish();
      return;
    }
    _clock.duration = widget.motion.headerDuration;
    _clock.forward(from: 0);
  }

  void _startDrag(DragStartDetails details) {
    if (_changing || widget.children.length < 2) return;
    if (_clock.isAnimating) _finish();
    _dragging = true;
    // Native consumes the threshold-crossing sample, then starts body travel.
    // Header travel starts one delivered sample after that (core-01 drag logs).
    _bodyOrigin = _current.dx;
    _headerOrigin = _current.dx;
    _headerDragStarted = false;
    _updateDrag();
  }

  void _updateDrag() {
    if (!_dragging) return;
    final delta = _current.dx - _bodyOrigin;
    if (!_headerDragStarted && delta != 0) {
      _headerOrigin = _current.dx;
      _headerDragStarted = true;
    }
    final headerDelta = _current.dx - _headerOrigin;
    final blocked = !widget.wrap &&
        ((_selected == 0 && delta > 0) ||
            (_selected == widget.children.length - 1 && delta < 0));
    _bodyX = delta.clamp(-_width, _width) * (blocked ? .2 : 1);
    _headerX = headerDelta /
        _width *
        _span(headerDelta > 0 ? _selected - 1 : _selected);
    if (blocked) _headerX *= .2;
    setState(() {});
  }

  void _endDrag(DragEndDetails details) {
    if (!_dragging) return;
    // The native stream includes a same-position Move immediately before Up.
    // Ignore that co-timed release sample, but honor a separate stationary Move
    // as a stop (core-01/flick_next_r02 versus reverse_after_release_r03).
    final stopped = _stationaryMoveTime != null &&
        _lastPointerTime - _stationaryMoveTime! >=
            const Duration(milliseconds: 1);
    final velocity = stopped ||
            _lastPointerTime - _lastMotionTime > widget.motion.flingStopTimeout
        ? 0.0
        : _segmentVelocity;
    final isFling = velocity.abs() >= widget.motion.flingVelocity * _scale;
    final sign = isFling ? velocity.sign : _bodyX.sign;
    final direction = sign < 0 ? 1 : -1;
    final target = _selected + direction;
    if ((_bodyX.abs() >= _width * widget.motion.commitFraction || isFling) &&
        (widget.wrap || (target >= 0 && target < widget.children.length))) {
      _select(_wrapped(target), direction: direction);
    } else {
      _cancelDrag();
    }
  }

  void _navigate(int delta) {
    if (_changing || widget.children.length < 2) return;
    final target = _selected + delta;
    if (widget.wrap || (target >= 0 && target < widget.children.length)) {
      _select(_wrapped(target), direction: delta);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.children.length == widget.tabTitles.length,
        'WpPivotView needs one child per tab title.');
    assert(_controller.length == widget.children.length,
        'WpPivotView controller length must match its children.');
    assert(
        !widget.motion.headerDuration.isNegative &&
            !widget.motion.exitDuration.isNegative &&
            !widget.motion.enterDuration.isNegative &&
            !widget.motion.flingStopTimeout.isNegative,
        'Pivot motion durations must not be negative.');
    Widget surface = LayoutBuilder(builder: (context, constraints) {
      _width = constraints.maxWidth;
      assert(constraints.hasBoundedWidth && constraints.hasBoundedHeight,
          'WpPivotView requires a bounded viewport.');
      if (_width <= 0 || constraints.maxHeight <= 0) {
        return const SizedBox.shrink();
      }
      _scale = _width / widget.referenceWidth;
      final scaler = MediaQuery.textScalerOf(context);
      final headerStyle = TextStyle(
          fontFamily: widget.headerFontFamily ??
              Theme.of(context).textTheme.bodyMedium?.fontFamily,
          fontSize: 72 * _scale,
          height: 1.3301,
          fontWeight: widget.headerFontWeight);
      final inherited = Theme.of(context).textTheme.bodyMedium!;
      final effective = inherited.merge(headerStyle);
      if (!listEquals(_measuredTitles, widget.tabTitles) ||
          _measuredStyle != effective ||
          _measuredScaler != scaler) {
        _measuredTitles = List.of(widget.tabTitles);
        _measuredStyle = effective;
        _measuredScaler = scaler;
        _widths = widget.tabTitles.map((title) {
          final painter = TextPainter(
              text: TextSpan(text: title, style: effective),
              textDirection: TextDirection.ltr,
              textScaler: scaler)
            ..layout();
          final width = painter.width;
          painter.dispose();
          return width;
        }).toList();
      }
      final extra =
          math.max(0.0, scaler.scale(72 * _scale) - 72 * _scale) * 1.3301;
      final headerHeight =
          math.min(165 * _scale + extra, constraints.maxHeight);
      return Material(
          color: widget.backgroundColor,
          child: Column(children: [
            PivotHeader(
                title: widget.title,
                titles: widget.tabTitles,
                selected: _selected,
                anchor: _anchor,
                translation: _headerX,
                scale: _scale,
                widths: _widths,
                headerStyle: headerStyle,
                titleStyle: TextStyle(
                    fontFamily: widget.titleFontFamily,
                    fontSize: 22.667 * _scale,
                    height: 1.3301,
                    fontWeight: widget.titleFontWeight,
                    color: widget.selectedTabColor),
                selectedColor: widget.selectedTabColor,
                unselectedColor: widget.unselectedTabColor,
                height: headerHeight,
                onSelected: _changing ? null : _select),
            Expanded(
                child: ClipRect(
                    child: Listener(
              onPointerDown: (event) {
                if (_pointer != null) return;
                _pointer = event.pointer;
                _current = event.localPosition;
                _lastMotionTime = _lastPointerTime = event.timeStamp;
                _segmentVelocity = 0;
                _stationaryMoveTime = null;
              },
              onPointerMove: (event) {
                if (_pointer != event.pointer) return;
                final dx = event.localPosition.dx - _current.dx;
                if (dx != 0) {
                  final elapsed =
                      (event.timeStamp - _lastMotionTime).inMicroseconds;
                  _segmentVelocity = elapsed > 0 ? dx * 1000000 / elapsed : 0;
                  _lastMotionTime = event.timeStamp;
                  _stationaryMoveTime = null;
                } else {
                  _stationaryMoveTime = event.timeStamp;
                }
                _lastPointerTime = event.timeStamp;
                _current = event.localPosition;
              },
              onPointerUp: (event) {
                if (_pointer == event.pointer) {
                  _lastPointerTime = event.timeStamp;
                  _pointer = null;
                }
              },
              onPointerCancel: (event) {
                if (_pointer == event.pointer) _pointer = null;
              },
              child: RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: {
                  HorizontalDragGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                              HorizontalDragGestureRecognizer>(
                          () => HorizontalDragGestureRecognizer(),
                          (recognizer) {
                    recognizer
                      ..onlyAcceptDragOnThreshold = true
                      ..gestureSettings = DeviceGestureSettings(
                          touchSlop: widget.motion.dragThreshold * _scale)
                      ..onStart = _startDrag
                      ..onUpdate = (_) {
                        _updateDrag();
                      }
                      ..onEnd = _endDrag
                      ..onCancel = _cancelDrag;
                  })
                },
                child: IgnorePointer(
                    ignoring: _changing,
                    child: Transform.translate(
                        offset: Offset(_bodyX, 0),
                        child: RepaintBoundary(
                            child: IndexedStack(
                          index: widget.children.isEmpty ? null : _displayed,
                          sizing: StackFit.expand,
                          children: [
                            for (var i = 0; i < widget.children.length; i++)
                              TickerMode(
                                  enabled: i == _displayed,
                                  child: KeyedSubtree(
                                      key: ValueKey(i),
                                      child: widget.children[i]))
                          ],
                        )))),
              ),
            ))),
          ]));
    });
    if (widget.safeArea) surface = SafeArea(child: surface);
    return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _navigate(1),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _navigate(-1),
        },
        child: Focus(
            autofocus: true,
            child: ColoredBox(color: widget.backgroundColor, child: surface)));
  }
}
