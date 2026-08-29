import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One section in [WpPanorama].
@immutable
class WpPanoramaItem {
  const WpPanoramaItem({required this.header, required this.child});

  final String header;
  final Widget child;
}

/// Explicit experimental values for [WpPanorama]'s three panning layers.
///
/// These are deliberately exposed because no native Panorama measurements have
/// yet been accepted for this package. They are useful for experimentation, not
/// recovered Windows Phone constants.
@immutable
class WpPanoramaMotion {
  const WpPanoramaMotion({
    this.duration = const Duration(milliseconds: 260),
    this.curve = Curves.easeOutCubic,
    this.commitFraction = .24,
    this.flingVelocity = 700,
    this.titleParallax = .42,
    this.backgroundParallax = .14,
    this.contentParallax = 1,
    this.nextPanelPeek = 24,
    this.panelGap = 36,
  })  : assert(commitFraction >= 0 && commitFraction <= 1),
        assert(flingVelocity >= 0),
        assert(titleParallax >= 0),
        assert(backgroundParallax >= 0),
        assert(contentParallax > 0),
        assert(nextPanelPeek >= 0),
        assert(panelGap >= 0);

  final Duration duration;
  final Curve curve;
  final double commitFraction;
  final double flingVelocity;
  final double titleParallax;
  final double backgroundParallax;
  final double contentParallax;
  final double nextPanelPeek;
  final double panelGap;
}

/// An experimental, Metro-inspired Panorama surface.
///
/// This is a custom adapter, not a claim of native Panorama geometry or motion
/// fidelity. The title, background and item canvas move at independently
/// configurable rates. At rest, a portion of the next item remains visible.
class WpPanorama extends StatefulWidget {
  const WpPanorama({
    super.key,
    required this.title,
    required this.items,
    this.background,
    this.initialIndex = 0,
    this.onChanged,
    this.motion = const WpPanoramaMotion(),
  });

  final String title;
  final List<WpPanoramaItem> items;
  final Widget? background;
  final int initialIndex;
  final ValueChanged<int>? onChanged;
  final WpPanoramaMotion motion;

  @override
  State<WpPanorama> createState() => _WpPanoramaState();
}

class _WpPanoramaState extends State<WpPanorama>
    with SingleTickerProviderStateMixin {
  // Native pilot resting geometry at 480 by 800 (state.csv / scene-contract).
  static const _refWidth = 480.0;
  static const _refHeight = 800.0;
  static const _nativeItemLeft = 24.0;
  static const _nativeHeaderY = 191.0;
  static const _nativeContentY = 317.0;
  static const _nativeHeaderHeight = 87.79;
  static const _nativePeek = 24.0;
  static const _nativeGap = 36.0;
  static const _nativeMinContent = 64.0;

  late final AnimationController _clock;
  int _index = 0;
  int _displayed = 0;
  int? _target;
  int _travelDirection = 1;
  bool _pointerCancelled = false;
  // Item positions are rebased after each cyclic commit. The title and
  // background instead retain this accumulated canvas travel so completing a
  // selection cannot visibly reset either panning layer.
  double _layerOffset = 0;
  double _drag = 0;
  double _start = 0;
  double _end = 0;
  bool _reducedMotion = false;

  int get _length => widget.items.length;

  @override
  void initState() {
    super.initState();
    _index = _displayed = _clamp(widget.initialIndex);
    _clock = AnimationController(vsync: this)
      ..addListener(_tick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _complete();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced && !_reducedMotion && _clock.isAnimating) _complete();
    _reducedMotion = reduced;
  }

  @override
  void didUpdateWidget(covariant WpPanorama oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Callers commonly create a fresh list while handling onChanged. That is
    // content replacement, not an instruction to cancel an in-flight pan.
    // Only a changed cardinality needs index/bounds recovery.
    if (oldWidget.items.length != widget.items.length) {
      _clock.stop();
      _target = null;
      _layerOffset += _drag * widget.motion.contentParallax;
      _drag = _start = _end = 0;
      _index = _displayed = _clamp(_index);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  int _clamp(int value) => _length == 0 ? 0 : value.clamp(0, _length - 1);

  int _wrap(int value) => _length == 0 ? 0 : value % _length;

  /// Resting title/background travel for [index] after forward steps from 0.
  double _canonicalRestLayerOffset(int index, double distance) =>
      -index * distance * widget.motion.contentParallax;

  bool _isWrapCommit(int direction, int from, int to) {
    if (_length < 2) return false;
    if (direction > 0 && from == _length - 1 && to == 0) return true;
    if (direction < 0 && from == 0 && to == _length - 1) return true;
    return false;
  }

  void _tick() {
    _drag =
        _start + (_end - _start) * widget.motion.curve.transform(_clock.value);
    setState(() {});
  }

  void _complete() {
    _clock.stop();
    _layerOffset += _drag * widget.motion.contentParallax;
    final target = _target;
    if (target != null) {
      _index = _displayed = target;
    }
    _target = null;
    _drag = _start = _end = 0;
    if (mounted) setState(() {});
  }

  void _settle({required int? target, required double end}) {
    if (_clock.isAnimating) _complete();
    _target = target;
    _start = _drag;
    _end = end;
    if (_reducedMotion || widget.motion.duration == Duration.zero) {
      _complete();
      return;
    }
    _clock.duration = widget.motion.duration;
    _clock.forward(from: 0);
  }

  void _commit(int direction, double distance) {
    if (_length < 2) return;
    final target = _wrap(_displayed + direction);
    _travelDirection = direction;
    if (target != _index) {
      _index = target;
      widget.onChanged?.call(target);
    }
    // Next items start to the right, so their canvas settles left; previous
    // items start to the left, so their canvas settles right.
    final end =
        (direction > 0 ? -distance : distance) / widget.motion.contentParallax;
    // Cyclic wrap must settle title/background at the destination item's rest
    // phase (native backward wrap shows the title tail, not a finger-direction
    // leftover). Pre-adjust so the settle animation ends at the canonical offset.
    if (_isWrapCommit(direction, _displayed, target)) {
      _layerOffset = _canonicalRestLayerOffset(target, distance) -
          end * widget.motion.contentParallax;
    }
    _settle(target: target, end: end);
  }

  void _navigate(int direction, double distance) {
    if (_length < 2) return;
    if (_clock.isAnimating) _complete();
    _commit(direction, distance);
  }

  void _onStart(DragStartDetails details) {
    if (_length < 2) return;
    _pointerCancelled = false;
    if (_clock.isAnimating) _complete();
  }

  void _onUpdate(DragUpdateDetails details, double distance) {
    if (_length < 2 || _clock.isAnimating) return;
    setState(() {
      final logicalLimit = distance / widget.motion.contentParallax;
      _drag = (_drag + details.delta.dx)
          .clamp(-logicalLimit, logicalLimit)
          .toDouble();
    });
  }

  void _onEnd(DragEndDetails details, double distance) {
    if (_length < 2 || _clock.isAnimating) return;
    // In the Flutter 3.22 recognizer, an accepted PointerCancelEvent reaches
    // DragGestureRecognizer.onEnd rather than onCancel. The raw Listener below
    // latches that event first so a cancelled drag can never commit selection.
    if (_pointerCancelled) {
      _pointerCancelled = false;
      _settle(target: null, end: 0);
      return;
    }
    final velocity = details.velocity.pixelsPerSecond.dx;
    final direction = velocity.abs() >= widget.motion.flingVelocity
        ? (velocity < 0 ? 1 : -1)
        : (_drag < 0 ? 1 : -1);
    final commit = _drag.abs() * widget.motion.contentParallax >=
            distance * widget.motion.commitFraction ||
        velocity.abs() >= widget.motion.flingVelocity;
    if (commit) {
      _commit(direction, distance);
    } else {
      _settle(target: null, end: 0);
    }
  }

  Widget _item({
    required int index,
    required double left,
    required double width,
    required double height,
    required double titleSize,
    required double contentGap,
    required bool active,
    VoidCallback? onTap,
  }) {
    final item = widget.items[_wrap(index)];
    return Positioned(
      key: ValueKey('wp-panorama-item-${_wrap(index)}'),
      left: left,
      top: 0,
      width: width,
      height: height,
      child: Offstage(
        offstage: !active,
        child: TickerMode(
          enabled: active,
          child: ExcludeFocus(
            excluding: !active,
            child: IgnorePointer(
              ignoring: !active,
              child: Semantics(
                container: true,
                selected: _wrap(index) == _index,
                label: item.header,
                child: GestureDetector(
                  behavior: onTap == null
                      ? HitTestBehavior.deferToChild
                      : HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Text(
                          item.header,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            height: 1.28,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      SizedBox(height: contentGap),
                      Expanded(child: item.child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.initialIndex >= 0, 'initialIndex must not be negative.');
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      if (width <= 0 || height <= 0) return const SizedBox.shrink();
      // The native pilot exported Segoe WP Light 170 for the title and Segoe
      // WP SemiLight 66 for item headers at 480 logical pixels. These values
      // are source observations; Selawik's rasterization remains different.
      final textScaler = MediaQuery.textScalerOf(context);
      final widthScale = width / _refWidth;
      final heightScale = height / _refHeight;
      // Couple typography to the tighter axis so landscape keeps title below
      // item headers. Text applies [textScaler] once; do not pre-scale here.
      final layoutScale = math.min(widthScale, heightScale);
      final itemHeaderFontSize =
          math.min(66.0, math.max(44.0, 66.0 * layoutScale));
      final mainTitleFontSize =
          math.min(170.0, math.max(113.0, 170.0 * layoutScale));
      final scaledItemHeader = textScaler.scale(itemHeaderFontSize);
      final scaledMainTitle = textScaler.scale(mainTitleFontSize);
      final titleStyle = TextStyle(
        color: Colors.white,
        fontSize: mainTitleFontSize,
        height: 1,
        fontWeight: FontWeight.w300,
        letterSpacing: -.8,
      );
      final titlePainter = TextPainter(
        text: TextSpan(text: widget.title, style: titleStyle),
        textScaler: textScaler,
        textDirection: Directionality.of(context),
      )..layout();
      final titleWidth = titlePainter.width;
      titlePainter.dispose();
      // Native pilot layout: 24 px leading edge, 432 px pitch, header y=191,
      // content y=317 at 480 by 800. Width/height scale independently; short
      // viewports clamp itemTop so the child canvas keeps usable height.
      final contentGap =
          (_nativeContentY - _nativeHeaderY - _nativeHeaderHeight) *
              heightScale;
      final headerBandHeight = scaledItemHeader * 1.28 + 18 + contentGap;
      const mainTitleTop = 8.0;
      final mainTitleBottom = mainTitleTop + scaledMainTitle;
      final nominalItemTop = _nativeHeaderY * heightScale;
      final maxItemTop =
          height - _nativeMinContent * heightScale - headerBandHeight;
      final minItemTopForTitle = mainTitleBottom + 4;
      final itemTop = math.max(
        math.min(
          nominalItemTop,
          math.max(72.0 * heightScale, maxItemTop),
        ),
        minItemTopForTitle,
      );
      final itemLeft =
          (_nativeItemLeft * widthScale).clamp(12.0, _nativeItemLeft);
      final peek = _length < 2
          ? 0.0
          : math.min(
              widget.motion.nextPanelPeek, width * (_nativePeek / _refWidth));
      final gap =
          math.min(widget.motion.panelGap, width * (_nativeGap / _refWidth));
      final panelWidth = math.max(1.0, width - itemLeft - peek - gap);
      final distance = panelWidth + gap;
      final canvasDrag = _drag * widget.motion.contentParallax;
      final layerTravel = _layerOffset + canvasDrag;
      // A caller can cycle forever. Generic background widgets cannot safely be
      // cloned as tiles, so cap their panning inside the supplied over-wide
      // canvas. The title gets the same bounded experimental policy, preserving
      // a visible glyph segment without a wrap-time snap.
      final backgroundTravel = (layerTravel * widget.motion.backgroundParallax)
          .clamp(-width * .35, 0.0)
          .toDouble();
      final visibleTitle = math.min(titleWidth, width * .35);
      final titleTravel = (layerTravel * widget.motion.titleParallax)
          .clamp(math.min(0.0, -titleWidth + visibleTitle),
              math.max(0.0, width - visibleTitle))
          .toDouble();
      final dragDirection = _drag < 0 ? 1 : -1;
      final direction =
          _target != null ? _travelDirection : (_drag == 0 ? 1 : dragDirection);
      final incoming = _target ?? _wrap(_displayed + direction);

      Widget layers = Stack(fit: StackFit.expand, children: [
        if (widget.background != null)
          Transform.translate(
            offset: Offset(backgroundTravel, 0),
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: width * 1.35,
              maxWidth: width * 1.35,
              child: widget.background!,
            ),
          ),
        Positioned.fill(child: ColoredBox(color: Colors.black.withAlpha(46))),
        ClipRect(
          child: Transform.translate(
            offset: Offset(titleTravel, 0),
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxWidth: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: ExcludeSemantics(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: titleStyle,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: itemTop,
          left: itemLeft,
          right: 0,
          bottom: 0,
          child: ClipRect(
            child: Stack(children: [
              if (_length == 0)
                const SizedBox.expand()
              else ...[
                for (var itemIndex = 0; itemIndex < _length; itemIndex++)
                  _item(
                    index: itemIndex,
                    left: itemIndex == _displayed
                        ? canvasDrag
                        : itemIndex == incoming
                            ? (direction > 0
                                ? distance + canvasDrag
                                : -distance + canvasDrag)
                            : 0,
                    width: panelWidth,
                    height: height - itemTop,
                    titleSize: itemHeaderFontSize,
                    contentGap: contentGap,
                    active: itemIndex == _displayed || itemIndex == incoming,
                    onTap: itemIndex == incoming
                        ? () => _navigate(direction, distance)
                        : null,
                  ),
              ],
            ]),
          ),
        ),
      ]);

      layers = Semantics(
        container: true,
        label: _length == 0
            ? '${widget.title}, empty panorama'
            : '${widget.title}, item ${_index + 1} of $_length',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onStart,
          onHorizontalDragUpdate: (details) => _onUpdate(details, distance),
          onHorizontalDragEnd: (details) => _onEnd(details, distance),
          onHorizontalDragCancel: () => _settle(target: null, end: 0),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _pointerCancelled = false,
            onPointerCancel: (_) => _pointerCancelled = true,
            child: layers,
          ),
        ),
      );
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _navigate(1, distance),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _navigate(-1, distance),
        },
        child: Focus(autofocus: true, child: layers),
      );
    });
  }
}
