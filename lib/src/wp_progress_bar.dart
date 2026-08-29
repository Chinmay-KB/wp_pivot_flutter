import 'package:flutter/material.dart';

/// A Windows Phone 8 determinate or indeterminate progress line.
///
/// A null [value] selects the five-mark indeterminate presentation. The 4 px
/// marks and 12 px horizontal padding come from the native WP8 control
/// template; the loop is refined by the component fidelity study.
class WpProgressBar extends StatefulWidget {
  const WpProgressBar({
    super.key,
    this.value,
    this.color = const Color(0xff3e65ff),
    this.backgroundColor = const Color(0x19ffffff),
    this.horizontalPadding = 12,
    this.indeterminateDuration = const Duration(milliseconds: 4500),
    this.semanticLabel,
  }) : assert(value == null || (value >= 0 && value <= 1));

  final double? value;
  final Color color;
  final Color backgroundColor;
  final double horizontalPadding;
  final Duration indeterminateDuration;
  final String? semanticLabel;

  @override
  State<WpProgressBar> createState() => _WpProgressBarState();
}

class _WpProgressBarState extends State<WpProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.indeterminateDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant WpProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indeterminateDuration != widget.indeterminateDuration) {
      _controller.duration = widget.indeterminateDuration;
    }
    _syncAnimation();
  }

  void _syncAnimation() {
    final animate = widget.value == null &&
        !MediaQuery.disableAnimationsOf(context) &&
        widget.indeterminateDuration > Duration.zero;
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final semanticValue =
        value == null ? 'In progress' : '${(value * 100).round()}%';
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      value: semanticValue,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
        child: SizedBox(
          height: 4,
          child: value == null
              ? AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => CustomPaint(
                    key: const ValueKey('wp-progress-indeterminate'),
                    painter: WpIndeterminateProgressPainter(
                      phase: _controller.value,
                      color: widget.color,
                      reducedMotion: MediaQuery.disableAnimationsOf(context),
                      loopDuration: widget.indeterminateDuration,
                    ),
                  ),
                )
              : CustomPaint(
                  key: const ValueKey('wp-progress-determinate'),
                  painter: WpDeterminateProgressPainter(
                    value: value,
                    color: widget.color,
                    backgroundColor: widget.backgroundColor,
                  ),
                ),
        ),
      ),
    );
  }
}

@visibleForTesting
class WpDeterminateProgressPainter extends CustomPainter {
  const WpDeterminateProgressPainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final double value;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * value.clamp(0.0, 1.0), size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant WpDeterminateProgressPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor;
}

@visibleForTesting
class WpIndeterminateProgressPainter extends CustomPainter {
  const WpIndeterminateProgressPainter({
    required this.phase,
    required this.color,
    required this.reducedMotion,
    this.loopDuration = const Duration(milliseconds: 4500),
  });

  final double phase;
  final Color color;
  final bool reducedMotion;
  final Duration loopDuration;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final rect in markRects(size)) {
      final x = rect.left;
      if (x + 4 >= 0 && x <= size.width) {
        canvas.drawRect(rect, paint);
      }
    }
  }

  List<Rect> markRects(Size size) => <Rect>[
        for (var index = 0; index < 5; index++)
          Rect.fromLTWH(
            reducedMotion
                ? size.width * .5 - 2 + (index - 2) * 10
                : _markX(size.width, index, phase),
            0,
            4,
            4,
          ),
      ];

  double _markX(double width, int index, double animation) {
    // The native capture shows a burst of five marks, staggered by about
    // 200 ms, followed by an empty interval. A full repeat was not observed,
    // so the 4.5 s loop is deliberately conservative rather than presented as
    // a measured period. The normalized positions below are pooled from the
    // complete r01-r02 trajectories; r03 remains held out.
    const activeMs = 2500.0;
    const staggerMs = 200.0;
    const samples = <double>[
      0,
      .205,
      .327,
      .389,
      .443,
      .505,
      .564,
      .621,
      .686,
      .817,
      1,
    ];
    final elapsedMs = animation * loopDuration.inMicroseconds / 1000;
    final local = (elapsedMs - index * staggerMs) / activeMs;
    if (local < 0 || local > 1) return -8;
    final scaled = local * (samples.length - 1);
    final lower = scaled.floor().clamp(0, samples.length - 1);
    final upper = (lower + 1).clamp(0, samples.length - 1);
    final fraction = scaled - lower;
    final position =
        samples[lower] + (samples[upper] - samples[lower]) * fraction;
    return position * (width - 4);
  }

  @override
  bool shouldRepaint(covariant WpIndeterminateProgressPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.color != color ||
      oldDelegate.reducedMotion != reducedMotion ||
      oldDelegate.loopDuration != loopDuration;
}
