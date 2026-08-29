import 'dart:async';

import 'package:flutter/material.dart';

/// Source constants from Windows Phone Toolkit `TiltEffect` (MS-PL).
@visibleForTesting
abstract final class WpTiltGeometry {
  static const maxAngleRadians = .3;
  static const maxDepression = 25.0;
  static const returnDelay = Duration(milliseconds: 200);
  static const returnDuration = Duration(milliseconds: 100);

  static WpTiltPose poseFor(Offset normalizedPosition) {
    final nx = normalizedPosition.dx.clamp(0.0, 1.0);
    final ny = normalizedPosition.dy.clamp(0.0, 1.0);
    final xMagnitude = (nx - .5).abs();
    final yMagnitude = (ny - .5).abs();
    final angleMagnitude = xMagnitude + yMagnitude;
    final xContribution =
        angleMagnitude == 0 ? 0.0 : xMagnitude / angleMagnitude;
    final xDirection = -(nx - .5).sign;
    final yDirection = (ny - .5).sign;
    final angle = angleMagnitude * maxAngleRadians;
    return WpTiltPose(
      rotationX: angle * (1 - xContribution) * yDirection,
      rotationY: angle * xContribution * xDirection,
      depression: (1 - angleMagnitude) * maxDepression,
    );
  }
}

@visibleForTesting
@immutable
class WpTiltPose {
  const WpTiltPose({
    required this.rotationX,
    required this.rotationY,
    required this.depression,
  });

  final double rotationX;
  final double rotationY;
  final double depression;
}

/// Adds the touch-position-dependent Windows Phone Toolkit tilt to [child].
///
/// The effect is immediate while a pointer is held. On release it waits 200 ms
/// and returns over 100 ms, matching the archived Toolkit source. Pointer
/// handling remains transparent to the wrapped control.
class WpTiltEffect extends StatefulWidget {
  const WpTiltEffect({
    super.key,
    required this.child,
    this.enabled = true,
    this.returnDelay = WpTiltGeometry.returnDelay,
    this.returnDuration = WpTiltGeometry.returnDuration,
    this.perspective = -.001,
  });

  final Widget child;
  final bool enabled;
  final Duration returnDelay;
  final Duration returnDuration;
  final double perspective;

  @override
  State<WpTiltEffect> createState() => _WpTiltEffectState();
}

class _WpTiltEffectState extends State<WpTiltEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _returnController;
  Timer? _returnTimer;
  double _rotationX = 0;
  double _rotationY = 0;
  double _depression = 0;
  double _startRotationX = 0;
  double _startRotationY = 0;
  double _startDepression = 0;

  @override
  void initState() {
    super.initState();
    _returnController = AnimationController(
      vsync: this,
      duration: widget.returnDuration,
    )..addListener(_tickReturn);
  }

  @override
  void didUpdateWidget(covariant WpTiltEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    _returnController.duration = widget.returnDuration;
    if (!widget.enabled && oldWidget.enabled) _clearPose();
  }

  @override
  void dispose() {
    _returnTimer?.cancel();
    _returnController.dispose();
    super.dispose();
  }

  void _tickReturn() {
    final t = _returnController.value;
    setState(() {
      _rotationX = _startRotationX * (1 - t);
      _rotationY = _startRotationY * (1 - t);
      _depression = _startDepression * (1 - t);
    });
  }

  bool get _motionEnabled =>
      widget.enabled && !MediaQuery.disableAnimationsOf(context);

  void _clearPose() {
    _returnTimer?.cancel();
    _returnController.stop();
    if (_rotationX == 0 && _rotationY == 0 && _depression == 0) return;
    setState(() {
      _rotationX = 0;
      _rotationY = 0;
      _depression = 0;
    });
  }

  void _apply(Offset localPosition) {
    if (!_motionEnabled) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize || renderBox.size.isEmpty) {
      return;
    }
    _returnTimer?.cancel();
    _returnController.stop();
    final pose = WpTiltGeometry.poseFor(
      Offset(
        localPosition.dx / renderBox.size.width,
        localPosition.dy / renderBox.size.height,
      ),
    );
    setState(() {
      _rotationX = pose.rotationX;
      _rotationY = pose.rotationY;
      _depression = pose.depression;
    });
  }

  void _scheduleReturn() {
    if (!_motionEnabled) {
      _clearPose();
      return;
    }
    _returnTimer?.cancel();
    _returnTimer = Timer(widget.returnDelay, () {
      if (!mounted) return;
      _startRotationX = _rotationX;
      _startRotationY = _rotationY;
      _startDepression = _depression;
      if (widget.returnDuration == Duration.zero) {
        _clearPose();
      } else {
        _returnController.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_motionEnabled &&
        (_rotationX != 0 || _rotationY != 0 || _depression != 0)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _clearPose();
      });
    }
    final transform = Matrix4.identity();
    if (_rotationX != 0 || _rotationY != 0 || _depression != 0) {
      transform
        ..setEntry(3, 2, widget.perspective)
        ..translateByDouble(0, 0, -_depression, 1)
        ..rotateX(_rotationX)
        // PlaneProjection and Matrix4 use opposite visual Y-rotation signs.
        ..rotateY(-_rotationY);
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _apply(event.localPosition),
      onPointerMove: (event) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null ||
            !renderBox.size.contains(event.localPosition)) {
          _scheduleReturn();
        } else {
          _apply(event.localPosition);
        }
      },
      onPointerUp: (_) => _scheduleReturn(),
      onPointerCancel: (_) => _scheduleReturn(),
      child: Transform(
        key: const ValueKey('wp-tilt-transform'),
        alignment: Alignment.center,
        transform: transform,
        child: widget.child,
      ),
    );
  }
}
