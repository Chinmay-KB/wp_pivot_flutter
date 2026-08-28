import 'dart:math' as math;
import 'package:flutter/animation.dart';

/// Measured starting points for the WP8.1 emulator reference, not OS constants.
/// See research/pivot for samples, uncertainty and held-out comparisons.
class PivotMotion {
  const PivotMotion({
    this.headerDuration = const Duration(milliseconds: 258),
    this.exitDuration = const Duration(milliseconds: 350),
    this.enterDuration = const Duration(milliseconds: 400),
    this.headerCurve = const PivotPowerCurve(1.13),
    this.contentCurve = const PivotExponentialCurve(5),
    this.dragThreshold = 20,
    this.commitFraction = .5,
    this.flingVelocity = 500,
    this.flingStopTimeout = const Duration(milliseconds: 75),
  })  : assert(dragThreshold >= 0),
        assert(commitFraction > 0 && commitFraction <= 1),
        assert(flingVelocity > 0);

  final Duration headerDuration, exitDuration, enterDuration;
  final Curve headerCurve, contentCurve;

  /// Gesture distances/velocities use the reference width's coordinate system.
  /// Flick threshold remains provisional pending physical-device validation.
  final double dragThreshold, commitFraction, flingVelocity;

  /// A held endpoint must not retain the speed of an earlier movement sample.
  final Duration flingStopTimeout;
}

class PivotPowerCurve extends Curve {
  const PivotPowerCurve(this.exponent) : assert(exponent > 0);
  final double exponent;
  @override
  double transformInternal(double t) =>
      1 - math.pow(1 - t, exponent).toDouble();
}

class PivotExponentialCurve extends Curve {
  const PivotExponentialCurve(this.exponent) : assert(exponent > 0);
  final double exponent;
  @override
  double transformInternal(double t) =>
      (1 - math.exp(-exponent * t)) / (1 - math.exp(-exponent));
}
