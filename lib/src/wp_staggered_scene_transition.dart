import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Whether a staggered scene is entering its resting plane or leaving it.
enum WpSceneTransitionDirection { enter, exit }

/// Geometry helpers for [WpStaggeredSceneTransition].
abstract final class WpStaggeredSceneGeometry {
  /// Returns a right-to-left exit order for an item on a column grid.
  ///
  /// A tile touching the right edge has order zero and begins exiting first.
  static double gridExitOrder({
    required int column,
    required int columnSpan,
    required int columns,
    int row = 0,
    double rowWeight = 0.5,
  }) {
    assert(column >= 0);
    assert(columnSpan > 0);
    assert(columns > 0);
    assert(row >= 0);
    assert(rowWeight >= 0);
    assert(column + columnSpan <= columns);
    return columns - column - columnSpan + row * rowWeight;
  }

  /// Returns an entry delay order that favors right and lower grid items.
  static double gridEntryOrder({
    required int column,
    required int columnSpan,
    required int columns,
    int row = 0,
    double rowWeight = 0.5,
  }) {
    assert(column >= 0);
    assert(columnSpan > 0);
    assert(columns > 0);
    assert(row >= 0);
    assert(rowWeight >= 0);
    assert(column + columnSpan <= columns);
    return column + columnSpan - 1 + row * rowWeight;
  }

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

/// Applies the observed staggered right-edge 3-D scene treatment to one item.
///
/// The Windows Phone evidence shows Start tiles leaving from the rightmost
/// column first, and the inverse order while returning. This primitive keeps
/// application navigation outside the package: callers own the shared
/// [animation], decide when a route may change, and assign each item's [order].
/// Use [WpStaggeredSceneGeometry.gridExitOrder] for a tile grid or provide an
/// arbitrary order for rows and other scene elements.
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
    this.alignment = Alignment.centerRight,
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

  /// Optional independent entry delay. The observed grid entry is not a
  /// strict reversal of exit: right and lower tiles can settle earlier.
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

  /// Horizontal travel at the fully-away entry pose. Native entry keeps tile
  /// right edges close to, and slightly left of, their resting anchors.
  final double entryTranslation;

  /// Perspective entry at matrix row 3, column 2.
  final double perspective;
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
