import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'wp_phone_theme.dart';

/// Measured alphabet-jump motion envelope shared by [WpAlphabetOverlay].
///
/// The values mirror the launcher picker choreography: the catalog fades with
/// [Curves.easeIn] across the first 18% of progress while sliding -12 logical
/// pixels, and the letter plane fades in with [Curves.easeOutCubic] between
/// 20% and 60% of progress. Plane input is ignored while closing or below 35%
/// progress. The controller runs 440 ms forward and 340 ms in reverse, jumping
/// straight to 1/0 when animations are disabled.
@visibleForTesting
abstract final class WpAlphabetOverlayGeometry {
  /// Forward (open) duration.
  static const forwardDuration = Duration(milliseconds: 440);

  /// Reverse (dismiss) duration.
  static const reverseDuration = Duration(milliseconds: 340);

  /// End of the app-list fade window, as a fraction of controller progress.
  static const appFadeEnd = 0.18;

  /// App-list travel at full fade, in logical pixels (slides left).
  static const appSlideDistance = 12.0;

  /// Start of the letter-plane fade window, as a fraction of progress.
  static const gridFadeStart = 0.20;

  /// End of the letter-plane fade window, as a fraction of progress.
  static const gridFadeEnd = 0.60;

  /// Progress below which the letter plane ignores input.
  static const inputProgressThreshold = 0.35;

  /// Catalog opacity for a normalized [progress] in 0..1.
  static double appOpacity(double progress) {
    final t = (progress / appFadeEnd).clamp(0.0, 1.0).toDouble();
    return (1.0 - Curves.easeIn.transform(t)).clamp(0.0, 1.0).toDouble();
  }

  /// Horizontal offset for a catalog at [opacity] (0 when fully visible).
  static double appSlideOffset(double opacity) =>
      -appSlideDistance * (1.0 - opacity);

  /// Letter-plane opacity for a normalized [progress] in 0..1.
  static double gridOpacity(double progress) {
    final t = ((progress - gridFadeStart) / (gridFadeEnd - gridFadeStart))
        .clamp(0.0, 1.0)
        .toDouble();
    return Curves.easeOutCubic.transform(t);
  }

  /// Whether the letter plane ignores input at [progress] while [closing].
  static bool ignoresAlphabetInput({
    required double progress,
    required bool closing,
  }) =>
      closing || progress < inputProgressThreshold;
}

/// Choreographs the alphabet-jump overlay between an app list and a letter
/// plane.
///
/// The widget owns only the motion envelope and surface chrome. The caller
/// supplies the catalog ([appListChild]), the letter plane ([alphabetChild],
/// typically a `WpAlphabetGrid`), and the [controller] that drives both
/// layers. Letters, enabled state, selection mapping, list scrolling, and cell
/// styling stay with the caller; cell visuals remain owned by
/// `WpAlphabetGrid`.
///
/// When [open] flips, the overlay drives [controller] forward (440 ms) or in
/// reverse (340 ms), defaulting a duration-less controller to
/// [WpAlphabetOverlayGeometry.forwardDuration] and
/// [WpAlphabetOverlayGeometry.reverseDuration]. When
/// [MediaQuery.disableAnimationsOf] is true the controller jumps straight to
/// 1/0 instead. The plane stays mounted until the reverse settles at 0, so
/// dismissal reads as a clean reversal of the open envelope.
///
/// While [holdBlackOnSelect] is true the catalog is held fully black so the
/// caller can apply the selected scroll destination before revealing it; the
/// caller clears the flag once the destination offset is in place. The whole
/// surface renders over the theme background behind a transparent, light-icon
/// status bar, with the plane optionally inset below the status bar via
/// [useSafeArea].
class WpAlphabetOverlay extends StatefulWidget {
  const WpAlphabetOverlay({
    super.key,
    required this.open,
    required this.controller,
    required this.appListChild,
    required this.alphabetChild,
    this.holdBlackOnSelect = false,
    this.onCancel,
    this.useSafeArea = true,
    this.backgroundColor,
  });

  /// Whether the letter plane is shown. Flipping this drives [controller].
  final bool open;

  /// Caller-owned progress controller for the open/dismiss envelope.
  final AnimationController controller;

  /// The app catalog surface. The caller owns its rows and scrolling.
  final Widget appListChild;

  /// The letter plane. The caller owns letters, selection, and cell styling.
  final Widget alphabetChild;

  /// Holds the catalog black while the caller applies a selection target.
  final bool holdBlackOnSelect;

  /// Escape dismissal for planes that do not handle it themselves.
  /// `WpAlphabetGrid` already maps Escape to its own `onCancel`.
  final VoidCallback? onCancel;

  /// Whether the letter plane is inset below the status bar via [SafeArea].
  final bool useSafeArea;

  /// Surface color behind both layers. Defaults to the phone theme background.
  final Color? backgroundColor;

  @override
  State<WpAlphabetOverlay> createState() => _WpAlphabetOverlayState();
}

class _WpAlphabetOverlayState extends State<WpAlphabetOverlay> {
  bool? _syncedOpen;
  bool? _syncedReduced;
  late bool _planeVisible;

  AnimationController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _defaultDurations(_controller);
    _planeVisible = widget.open || _controller.value > 0;
    _controller.addListener(_handleTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant WpAlphabetOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTick);
      _defaultDurations(widget.controller);
      widget.controller.addListener(_handleTick);
      _syncedOpen = null;
      _syncedReduced = null;
      _planeVisible = widget.open || widget.controller.value > 0;
    }
    _sync();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTick);
    super.dispose();
  }

  static void _defaultDurations(AnimationController controller) {
    controller.duration ??= WpAlphabetOverlayGeometry.forwardDuration;
    controller.reverseDuration ??= WpAlphabetOverlayGeometry.reverseDuration;
  }

  void _handleTick() {
    if (!mounted) return;
    final visible = widget.open || _controller.value > 0;
    if (visible != _planeVisible) {
      setState(() => _planeVisible = visible);
    }
  }

  void _sync() {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_syncedOpen == widget.open && _syncedReduced == reduced) {
      return;
    }
    _syncedOpen = widget.open;
    _syncedReduced = reduced;
    // Mount the plane synchronously so the first open frame already carries
    // the (transparent, untouchable) letter layer. Unmounting still waits for
    // the reverse to settle at 0 via [_handleTick].
    if (widget.open && !_planeVisible) {
      setState(() => _planeVisible = true);
    }
    if (widget.open) {
      if (reduced) {
        if (_controller.value != 1) _controller.value = 1;
      } else {
        _controller.forward();
      }
    } else {
      if (reduced) {
        if (_controller.value != 0) _controller.value = 0;
      } else {
        if (_controller.value > 0) _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: ColoredBox(
        color: widget.backgroundColor ?? theme.backgroundColor,
        child: Stack(
          children: <Widget>[
            IgnorePointer(
              ignoring: _planeVisible || widget.holdBlackOnSelect,
              child: AnimatedBuilder(
                animation: _controller,
                child: widget.appListChild,
                builder: (context, child) {
                  if (widget.holdBlackOnSelect) {
                    return Opacity(opacity: 0, child: child);
                  }
                  final opacity =
                      WpAlphabetOverlayGeometry.appOpacity(_controller.value);
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(
                        WpAlphabetOverlayGeometry.appSlideOffset(opacity),
                        0,
                      ),
                      child: child,
                    ),
                  );
                },
              ),
            ),
            if (_planeVisible)
              Positioned.fill(
                key: const ValueKey<String>('wp-alphabet-overlay-plane'),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final progress = _controller.value;
                    return Opacity(
                      opacity:
                          WpAlphabetOverlayGeometry.gridOpacity(progress),
                      child: IgnorePointer(
                        ignoring:
                            WpAlphabetOverlayGeometry.ignoresAlphabetInput(
                          progress: progress,
                          closing: !widget.open,
                        ),
                        child: _AlphabetPlane(
                          onCancel: widget.onCancel,
                          useSafeArea: widget.useSafeArea,
                          child: widget.alphabetChild,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlphabetPlane extends StatelessWidget {
  const _AlphabetPlane({
    required this.child,
    required this.onCancel,
    required this.useSafeArea,
  });

  final Widget child;
  final VoidCallback? onCancel;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    Widget plane = child;
    if (useSafeArea) {
      plane = SafeArea(
        top: true,
        bottom: false,
        left: false,
        right: false,
        child: plane,
      );
    }
    final onCancel = this.onCancel;
    if (onCancel == null) return plane;
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              onCancel();
              return null;
            },
          ),
        },
        child: plane,
      ),
    );
  }
}
