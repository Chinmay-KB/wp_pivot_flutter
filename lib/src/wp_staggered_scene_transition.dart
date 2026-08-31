import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Whether a staggered scene is entering its resting plane or leaving it.
enum WpSceneTransitionDirection { enter, exit }

/// Progress helpers for [WpStaggeredSceneTransition].
abstract final class WpStaggeredSceneGeometry {
  /// Maps the shared scene progress to one item's normalized away progress.
  static double awayProgress({
    required double progress,
    required double order,
    required double maxOrder,
    required double staggerFraction,
    required WpSceneTransitionDirection direction,
    double? entryOrder,
    double? maxEntryOrder,
  }) {
    assert(progress >= 0 && progress <= 1);
    assert(order >= 0 && order <= maxOrder);
    assert(maxOrder >= 0);
    assert(staggerFraction >= 0);
    assert(maxOrder * staggerFraction < 1);
    final resolvedOrder = direction == WpSceneTransitionDirection.exit
        ? order
        : entryOrder ?? maxOrder - order;
    final resolvedMaxOrder = direction == WpSceneTransitionDirection.exit
        ? maxOrder
        : maxEntryOrder ?? maxOrder;
    assert(resolvedOrder >= 0 && resolvedOrder <= resolvedMaxOrder);
    assert(resolvedMaxOrder * staggerFraction < 1);
    final sharedAway =
        direction == WpSceneTransitionDirection.exit ? progress : 1 - progress;
    final itemWindow = 1 - resolvedMaxOrder * staggerFraction;
    return ((sharedAway - resolvedOrder * staggerFraction) / itemWindow)
        .clamp(0.0, 1.0);
  }
}

/// Applies a staggered perspective transition to one item in a larger scene.
///
/// The caller owns the shared [animation], layout, transform origin, item
/// ordering, timing, and any navigation or state change that follows. That
/// keeps this widget useful for grids, lists, pages, and other composed scenes
/// without embedding policy from any one surface.
///
/// Exact native timing curves remain caller-tunable because the emulator
/// captures expose host capture intervals, not guest presentation timestamps.
class WpStaggeredSceneTransition extends StatelessWidget {
  const WpStaggeredSceneTransition({
    super.key,
    required this.animation,
    required this.order,
    required this.maxOrder,
    required this.child,
    this.entryOrder,
    this.maxEntryOrder,
    this.direction = WpSceneTransitionDirection.exit,
    this.staggerFraction = 0.08,
    this.maxRotation = math.pi * 0.42,
    this.exitTranslation = 64,
    this.entryTranslation = -12,
    this.perspective = 0.0018,
    this.alignment = Alignment.center,
  })  : assert(order >= 0),
        assert(maxOrder >= order),
        assert(entryOrder == null || entryOrder >= 0),
        assert(maxEntryOrder == null || maxEntryOrder >= (entryOrder ?? 0)),
        assert(staggerFraction >= 0),
        assert(maxOrder * staggerFraction < 1),
        assert((maxEntryOrder ?? maxOrder) * staggerFraction < 1),
        assert(maxRotation >= 0),
        assert(exitTranslation >= 0),
        assert(perspective >= 0);

  final Animation<double> animation;

  /// Exit order, where zero begins first.
  final double order;
  final double maxOrder;

  /// Optional independent entry delay when entry is not a strict reversal.
  final double? entryOrder;
  final double? maxEntryOrder;
  final Widget child;
  final WpSceneTransitionDirection direction;

  /// Delay between adjacent orders in normalized scene time.
  final double staggerFraction;

  /// Maximum Y-axis rotation in radians.
  final double maxRotation;

  /// Horizontal travel at the fully-away pose, in logical pixels.
  final double exitTranslation;

  /// Horizontal travel at the fully-away entry pose.
  final double entryTranslation;

  /// Perspective entry at matrix row 3, column 2.
  final double perspective;

  /// Origin used by the perspective transform. Callers should choose the
  /// alignment that matches the scene they are composing.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final away = WpStaggeredSceneGeometry.awayProgress(
          progress: animation.value.clamp(0.0, 1.0),
          order: order,
          maxOrder: maxOrder,
          staggerFraction: staggerFraction,
          direction: direction,
          entryOrder: entryOrder,
          maxEntryOrder: maxEntryOrder,
        );
        final fade = 1 -
            Curves.easeIn.transform(
              ((away - 0.92) / 0.08).clamp(0.0, 1.0),
            );
        final matrix = Matrix4.identity();
        if (!reduceMotion && away > 0) {
          final translation = direction == WpSceneTransitionDirection.exit
              ? exitTranslation
              : entryTranslation;
          matrix
            ..setEntry(3, 2, perspective)
            // Matrix4.translate is retained for the declared Flutter 3.22
            // minimum; translateByDouble is not available in every supported
            // SDK.
            // ignore: deprecated_member_use
            ..translate(translation * away)
            ..rotateY(-maxRotation * away);
        }
        return IgnorePointer(
          ignoring: away > 0.001,
          child: Semantics(
            hidden: fade <= 0.001,
            child: Opacity(
              key: const ValueKey<String>('wp-scene-opacity'),
              opacity: fade,
              child: Transform(
                key: const ValueKey<String>('wp-scene-transform'),
                alignment: alignment,
                transform: matrix,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
