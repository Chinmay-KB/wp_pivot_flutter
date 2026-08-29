import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';

/// Silverlight `ExponentialEase` used by WPtoolkit TurnstileFeather
/// (`Exponent` 6). EaseIn is `(e^(n t)-1)/(e^n-1)`; EaseOut is `1 - EaseIn(1-t)`.
/// Source: `Microsoft.Phone.Controls.Toolkit` 4.2013.8.16
/// `TurnstileFeatherEffect` cctor. Not a capture-fitted curve.
class WpToolkitExponentialEase extends Curve {
  const WpToolkitExponentialEase({this.exponent = 6, this.easeOut = true});

  final double exponent;
  final bool easeOut;

  @override
  double transformInternal(double t) {
    final easeIn = (math.exp(exponent * t) - 1) / (math.exp(exponent) - 1);
    return easeOut
        ? 1 - ((math.exp(exponent * (1 - t)) - 1) / (math.exp(exponent) - 1))
        : easeIn;
  }
}

/// Toolkit `TurnstileFeatherEffect` literals (WP8 DLL). ContinuumTransition is
/// not in this assembly. Capture cadence cannot fit these clocks.
class WpTurnstileFeather {
  static const double centerOfRotationX = -0.2;
  static const int forwardInDurationMs = 350;
  static const double forwardInAngle = -80;
  static const int forwardInDelayMs = 40;
  static const int forwardOutDurationMs = 250;
  static const double forwardOutAngle = 50;
  static const int forwardOutDelayMs = 50;
  static const int backwardInDurationMs = 350;
  static const double backwardInAngle = 50;
  static const int backwardInDelayMs = 50;
  static const int backwardOutDurationMs = 250;
  static const double backwardOutAngle = -80;
  static const int backwardOutDelayMs = 40;

  /// DetailPage-style pages (header / title / content indices 0–2).
  static const int detailPageMaxIndex = 2;

  static int forwardOutPhaseMsFor(int maxIndex) =>
      forwardOutDurationMs + forwardOutDelayMs * maxIndex;

  static int forwardInPhaseMsFor(int maxIndex) =>
      forwardInDurationMs + forwardInDelayMs * maxIndex;

  static int backwardOutPhaseMsFor(int maxIndex) =>
      backwardOutDurationMs + backwardOutDelayMs * maxIndex;

  static int backwardInPhaseMsFor(int maxIndex) =>
      backwardInDurationMs + backwardInDelayMs * maxIndex;

  static int routeDurationMsFor({
    required int outgoingMaxIndex,
    required int incomingMaxIndex,
  }) =>
      forwardOutPhaseMsFor(outgoingMaxIndex) +
      forwardInPhaseMsFor(incomingMaxIndex);

  static int reverseRouteDurationMsFor({
    required int leavingMaxIndex,
    required int returningMaxIndex,
  }) =>
      backwardOutPhaseMsFor(leavingMaxIndex) +
      backwardInPhaseMsFor(returningMaxIndex);

  /// Same-page detail transition (max index 2): 350 ms out + 430 ms in = 780 ms.
  static const Duration routeDuration = Duration(milliseconds: 780);
}

/// Per-navigation clocks derived from each page's highest FeatheringIndex.
class WpTurnstileFeatherTiming {
  const WpTurnstileFeatherTiming({
    required this.outgoingMaxIndex,
    required this.incomingMaxIndex,
  });

  final int outgoingMaxIndex;
  final int incomingMaxIndex;

  int forwardOutPhaseMs() =>
      WpTurnstileFeather.forwardOutPhaseMsFor(outgoingMaxIndex);

  int forwardInPhaseMs() =>
      WpTurnstileFeather.forwardInPhaseMsFor(incomingMaxIndex);

  int backwardOutPhaseMs() =>
      WpTurnstileFeather.backwardOutPhaseMsFor(incomingMaxIndex);

  int backwardInPhaseMs() =>
      WpTurnstileFeather.backwardInPhaseMsFor(outgoingMaxIndex);

  int routeDurationMs() => forwardOutPhaseMs() + forwardInPhaseMs();

  int reverseRouteDurationMs() => backwardOutPhaseMs() + backwardInPhaseMs();

  Duration routeDuration() => Duration(milliseconds: routeDurationMs());

  Duration reverseRouteDuration() =>
      Duration(milliseconds: reverseRouteDurationMs());
}

/// Supplies feather layers and transition clocks to descendants (hub rows, etc.).
class WpPhoneFeatherScope extends InheritedWidget {
  const WpPhoneFeatherScope({
    super.key,
    required this.maxIndex,
    required this.timing,
    required this.featherLayer,
    required super.child,
  });

  final int maxIndex;
  final WpTurnstileFeatherTiming? timing;
  final Widget Function({
    required Key key,
    required int index,
    required Widget child,
  }) featherLayer;

  static WpPhoneFeatherScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WpPhoneFeatherScope>();

  @override
  bool updateShouldNotify(WpPhoneFeatherScope oldWidget) =>
      maxIndex != oldWidget.maxIndex || timing != oldWidget.timing;
}

/// WP body type. WidgetsApp's debug fallback is red + yellow double-underline
/// (`debugLabel: fallback style`) and is inherited when no Material/DefaultTextStyle
/// sits between the navigator and [WpPhonePage].
const TextStyle wpPhoneDefaultTextStyle = TextStyle(
  fontFamily: wpPivotFontFamily,
  fontSize: 20,
  height: 1.2,
  fontWeight: FontWeight.w300,
  color: Colors.white,
  decoration: TextDecoration.none,
  decorationColor: Colors.transparent,
);

/// PhoneApplicationPage title panel from the WP8 SDK page template
/// (`TitlePanel` Margin 12,17,0,28) plus ThemeResources.xaml type sizes.
///
/// Participating layers use Toolkit TurnstileFeather (RotationY, sequential
/// TransitionFrame out-then-in, FeatheringIndex delays). ApplicationBar and
/// preview hardware Back are not feather targets. See
/// `artifacts/components-batch-02/grok/TOOLKIT-MOTION.md`.
class WpPhonePage extends StatelessWidget {
  const WpPhonePage({
    super.key,
    required this.applicationTitle,
    required this.pageTitle,
    required this.body,
    this.applicationBar,
    this.showTitlePanel = true,
    this.featherMaxIndex = WpTurnstileFeather.detailPageMaxIndex,
    this.featherBodyAsLayer = true,
  });

  final String applicationTitle;
  final String pageTitle;
  final Widget body;
  final Widget? applicationBar;
  final bool showTitlePanel;
  final int featherMaxIndex;

  /// When false, [body] supplies its own per-index feather layers (gallery hub).
  final bool featherBodyAsLayer;

  WpTurnstileFeatherTiming _timingFor(ModalRoute<dynamic>? route) {
    if (route is WpPhonePageRoute<void>) return route.timing;
    return WpActiveTransition.current ??
        WpTurnstileFeatherTiming(
          outgoingMaxIndex: featherMaxIndex,
          incomingMaxIndex: featherMaxIndex,
        );
  }

  Widget _buildLayer({
    required ModalRoute<dynamic>? route,
    required WpTurnstileFeatherTiming timing,
    required bool reduced,
    required Key key,
    required int index,
    required Widget child,
  }) {
    if (reduced || route == null) {
      return Opacity(key: key, opacity: 1, child: child);
    }
    return _TurnstileFeatherLayer(
      layerKey: key,
      index: index,
      timing: timing,
      route: route,
      animation: route.animation ?? const AlwaysStoppedAnimation(1),
      secondary: route.secondaryAnimation ?? const AlwaysStoppedAnimation(0),
      child: child,
    );
  }

  Widget _buildTitlePanel(
    Widget Function({
      required Key key,
      required int index,
      required Widget child,
    }) layer,
  ) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 17, 0, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            layer(
              key: const ValueKey('wp-phone-header'),
              index: 0,
              child: Text(
                applicationTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: wpPivotFontFamily,
                  fontSize: 20,
                  height: 1.2,
                  color: Color(0x99ffffff),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            layer(
              key: const ValueKey('wp-phone-title'),
              index: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 9, top: 0),
                child: Text(
                  pageTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: wpPivotFontFamily,
                    fontSize: 72,
                    height: 1.1,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _animatedChrome({
    required ModalRoute<dynamic>? route,
    required WpTurnstileFeatherTiming timing,
    required bool reduced,
    required Widget child,
  }) =>
      ListenableBuilder(
        listenable: route?.animation ?? const AlwaysStoppedAnimation(1),
        builder: (context, _) {
          final visible =
              reduced || _incomingShellVisible(route, timing, reduced);
          return visible ? child : const SizedBox.shrink();
        },
      );

  Widget _buildPageColumn({
    required ModalRoute<dynamic>? route,
    required WpTurnstileFeatherTiming timing,
    required bool reduced,
    required Widget Function({
      required Key key,
      required int index,
      required Widget child,
    }) layer,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitlePanel) _buildTitlePanel(layer),
          Expanded(
            child: featherBodyAsLayer
                ? layer(
                    key: const ValueKey('wp-phone-content'),
                    index: showTitlePanel ? 2 : 0,
                    child: body,
                  )
                : body,
          ),
          if (applicationBar != null)
            _animatedChrome(
              route: route,
              timing: timing,
              reduced: reduced,
              child: applicationBar!,
            ),
          if (route != null && !route.isFirst)
            _animatedChrome(
              route: route,
              timing: timing,
              reduced: reduced,
              child: const WpPreviewHardwareBack(),
            ),
        ],
      );

  Widget _buildShell({
    required BuildContext context,
    required ModalRoute<dynamic>? route,
    required WpTurnstileFeatherTiming timing,
    required bool reduced,
    required Widget child,
  }) =>
      _WpPhoneDeferredFocus(
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
            SingleActivator(LogicalKeyboardKey.browserBack): DismissIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (intent) {
                  Navigator.maybeOf(context)?.maybePop();
                  return null;
                },
              ),
            },
            child: ListenableBuilder(
              listenable: route?.animation ?? const AlwaysStoppedAnimation(1),
              builder: (context, _) {
                final shellPainted =
                    _incomingShellVisible(route, timing, reduced);
                return DefaultTextStyle(
                  style: wpPhoneDefaultTextStyle,
                  child: Semantics(
                    explicitChildNodes: true,
                    child: ColoredBox(
                      color:
                          shellPainted ? Colors.black : const Color(0x00000000),
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

  bool _incomingShellVisible(
    ModalRoute<dynamic>? route,
    WpTurnstileFeatherTiming? timing,
    bool reduced,
  ) {
    if (reduced || route == null || timing == null) return true;
    final animation = route.animation;
    if (animation == null) return false;
    if (animation.status == AnimationStatus.forward) {
      final ms = animation.value * timing.routeDurationMs();
      return ms >= timing.forwardOutPhaseMs();
    }
    if (animation.status == AnimationStatus.reverse) {
      final ms = (1 - animation.value) * timing.reverseRouteDurationMs();
      return ms < timing.backwardOutPhaseMs();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final timing = _timingFor(route);

    Widget layer({
      required Key key,
      required int index,
      required Widget child,
    }) =>
        _buildLayer(
          route: route,
          timing: timing,
          reduced: reduced,
          key: key,
          index: index,
          child: child,
        );
    final pageColumn = _buildPageColumn(
      route: route,
      timing: timing,
      reduced: reduced,
      layer: layer,
    );

    return WpPhoneFeatherScope(
      maxIndex: featherMaxIndex,
      timing: route is WpPhonePageRoute<void> ? timing : null,
      featherLayer: layer,
      child: _buildShell(
        context: context,
        route: route,
        timing: timing,
        reduced: reduced,
        child: pageColumn,
      ),
    );
  }
}

/// Requests focus after the first layout so web [showOnScreen] does not read
/// a [RenderBox] that HeroController/overlay has not laid out yet.
class _WpPhoneDeferredFocus extends StatefulWidget {
  const _WpPhoneDeferredFocus({required this.child});

  final Widget child;

  @override
  State<_WpPhoneDeferredFocus> createState() => _WpPhoneDeferredFocusState();
}

class _WpPhoneDeferredFocusState extends State<_WpPhoneDeferredFocus> {
  final FocusNode _node = FocusNode(debugLabel: 'WpPhonePage');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) return;
      _node.requestFocus();
    });
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.escape ||
            event.logicalKey == LogicalKeyboardKey.browserBack) {
          Navigator.maybeOf(context)?.maybePop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}

class WpActiveTransition {
  static WpTurnstileFeatherTiming? _timing;

  static void start(WpTurnstileFeatherTiming timing) => _timing = timing;

  static void end() => _timing = null;

  static WpTurnstileFeatherTiming? get current => _timing;
}

/// Tracks whether a route's secondary animation is revealing after a pop.
class WpRevealTracker {
  static final _reveal = <int, bool>{};

  static void markObscured(ModalRoute<dynamic> route) {
    _reveal[route.hashCode] = false;
  }

  static void markReveal(ModalRoute<dynamic> route) {
    _reveal[route.hashCode] = true;
  }

  static bool isReveal(ModalRoute<dynamic>? route) =>
      route != null && (_reveal[route.hashCode] ?? false);
}

class _FeatherPose {
  const _FeatherPose({required this.opacity, required this.rotationY});
  final double opacity;
  final double rotationY;
}

class _TurnstileFeatherLayer extends StatelessWidget {
  const _TurnstileFeatherLayer({
    required this.layerKey,
    required this.index,
    required this.timing,
    required this.route,
    required this.animation,
    required this.secondary,
    required this.child,
  });

  final Key layerKey;
  final int index;
  final WpTurnstileFeatherTiming timing;
  final ModalRoute<dynamic> route;
  final Animation<double> animation;
  final Animation<double> secondary;
  final Widget child;

  static const _easeOut = WpToolkitExponentialEase(easeOut: true);
  static const _easeIn = WpToolkitExponentialEase(easeOut: false);

  int _totalDuration(AnimationStatus status, bool revealing) =>
      status == AnimationStatus.reverse || revealing
          ? timing.reverseRouteDurationMs()
          : timing.routeDurationMs();

  _FeatherPose _primaryForward(double milliseconds, int outPhase) {
    if (milliseconds < outPhase) {
      return const _FeatherPose(
          opacity: 0, rotationY: WpTurnstileFeather.forwardInAngle);
    }
    return _forwardIn(milliseconds - outPhase);
  }

  _FeatherPose _secondaryForward(
    double milliseconds,
    bool revealing,
    int outPhase,
    int backOutPhase,
  ) {
    if (revealing) {
      if (milliseconds < backOutPhase) {
        return const _FeatherPose(
            opacity: 0, rotationY: WpTurnstileFeather.backwardInAngle);
      }
      return _backwardIn(milliseconds - backOutPhase);
    }
    if (milliseconds < outPhase) return _forwardOut(milliseconds);
    return const _FeatherPose(
        opacity: 0, rotationY: WpTurnstileFeather.forwardOutAngle);
  }

  _FeatherPose _primaryReverse(double milliseconds, int backOutPhase) {
    if (milliseconds < backOutPhase) return _backwardOut(milliseconds);
    return const _FeatherPose(
        opacity: 0, rotationY: WpTurnstileFeather.backwardOutAngle);
  }

  _FeatherPose _secondaryReverse(double milliseconds, int backOutPhase) {
    if (milliseconds < backOutPhase) {
      return const _FeatherPose(
          opacity: 0, rotationY: WpTurnstileFeather.backwardInAngle);
    }
    return _backwardIn(milliseconds - backOutPhase);
  }

  _FeatherPose _pose() {
    final aStatus = animation.status;
    final sStatus = secondary.status;
    final revealing = WpRevealTracker.isReveal(route);
    final total = _totalDuration(aStatus, revealing);
    final a = animation.value;
    final s = secondary.value;
    final outPhase = timing.forwardOutPhaseMs();
    final backOutPhase = timing.backwardOutPhaseMs();

    if (aStatus == AnimationStatus.completed &&
        sStatus == AnimationStatus.dismissed) {
      return const _FeatherPose(opacity: 1, rotationY: 0);
    }

    if (aStatus == AnimationStatus.forward) {
      return _primaryForward(a * total, outPhase);
    }

    if (sStatus == AnimationStatus.forward) {
      return _secondaryForward(s * total, revealing, outPhase, backOutPhase);
    }

    if (aStatus == AnimationStatus.reverse) {
      return _primaryReverse((1 - a) * total, backOutPhase);
    }

    if (sStatus == AnimationStatus.reverse) {
      return _secondaryReverse((1 - s) * total, backOutPhase);
    }

    return const _FeatherPose(opacity: 1, rotationY: 0);
  }

  _FeatherPose _forwardIn(double localMs) {
    final begin = WpTurnstileFeather.forwardInDelayMs * index;
    if (localMs < begin) {
      return const _FeatherPose(
          opacity: 0, rotationY: WpTurnstileFeather.forwardInAngle);
    }
    final t = ((localMs - begin) / WpTurnstileFeather.forwardInDurationMs)
        .clamp(0.0, 1.0);
    final e = _easeOut.transform(t);
    return _FeatherPose(
      opacity: 1,
      rotationY: WpTurnstileFeather.forwardInAngle * (1 - e),
    );
  }

  _FeatherPose _forwardOut(double localMs) {
    final begin = WpTurnstileFeather.forwardOutDelayMs * index;
    if (localMs < begin) {
      return const _FeatherPose(opacity: 1, rotationY: 0);
    }
    final t = ((localMs - begin) / WpTurnstileFeather.forwardOutDurationMs)
        .clamp(0.0, 1.0);
    final e = _easeIn.transform(t);
    final done = localMs >= begin + WpTurnstileFeather.forwardOutDurationMs;
    return _FeatherPose(
      opacity: done ? 0 : 1,
      rotationY: WpTurnstileFeather.forwardOutAngle * e,
    );
  }

  _FeatherPose _backwardIn(double localMs) {
    final begin = WpTurnstileFeather.backwardInDelayMs * index;
    if (localMs < begin) {
      return const _FeatherPose(
          opacity: 0, rotationY: WpTurnstileFeather.backwardInAngle);
    }
    final t = ((localMs - begin) / WpTurnstileFeather.backwardInDurationMs)
        .clamp(0.0, 1.0);
    final e = _easeOut.transform(t);
    return _FeatherPose(
      opacity: 1,
      rotationY: WpTurnstileFeather.backwardInAngle * (1 - e),
    );
  }

  _FeatherPose _backwardOut(double localMs) {
    final begin = WpTurnstileFeather.backwardOutDelayMs * index;
    if (localMs < begin) {
      return const _FeatherPose(opacity: 1, rotationY: 0);
    }
    final t = ((localMs - begin) / WpTurnstileFeather.backwardOutDurationMs)
        .clamp(0.0, 1.0);
    final e = _easeIn.transform(t);
    final done = localMs >= begin + WpTurnstileFeather.backwardOutDurationMs;
    return _FeatherPose(
      opacity: done ? 0 : 1,
      rotationY: WpTurnstileFeather.backwardOutAngle * e,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondary]),
      builder: (context, _) {
        final pose = _pose();
        return Opacity(
          key: layerKey,
          opacity: pose.opacity,
          child: Transform(
            alignment: const Alignment(-1.4, 0),
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(pose.rotationY * math.pi / 180),
            child: child,
          ),
        );
      },
    );
  }
}

/// Gallery-preview analog of the phone hardware Back key.
///
/// Not a Material [BackButton] or in-page chevron. Native Frame Back is the
/// chassis key below the app, not an ApplicationBar glyph. Tapping this calls
/// [Navigator.maybePop] so an open ApplicationBar overflow still closes first.
class WpPreviewHardwareBack extends StatelessWidget {
  const WpPreviewHardwareBack({super.key});

  void _pop(BuildContext context) {
    Navigator.maybeOf(context)?.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('wp-preview-hardware-back'),
      button: true,
      label: 'Hardware back',
      container: true,
      excludeSemantics: true,
      child: FocusableActionDetector(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              _pop(context);
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _pop(context),
          child: const ColoredBox(
            color: Color(0xff1f1f1f),
            child: SizedBox(
              height: 48,
              child: Center(
                child: CustomPaint(
                  size: Size(18, 18),
                  painter: _HardwareBackGlyphPainter(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HardwareBackGlyphPainter extends CustomPainter {
  const _HardwareBackGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.square;
    final path = Path()
      ..moveTo(size.width * 0.66, size.height * 0.18)
      ..lineTo(size.width * 0.28, size.height * 0.5)
      ..lineTo(size.width * 0.66, size.height * 0.82);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Opaque page route without [MaterialPageRoute], zoom, or a back chevron.
///
/// Duration is Toolkit TurnstileFeather out-then-in (TransitionFrame sequential
/// exit then entrance). Source clocks, not a 21 fps curve fit. Zero when the
/// platform asks for reduced motion so [HeroController] does not leave the
/// route [Offstage]. Non-opaque during the outgoing phase so the previous page
/// rotation is visible (not masked by a black incoming shell).
class WpPhonePageRoute<T> extends PageRoute<T> {
  WpPhonePageRoute({
    required this.builder,
    required this.incomingMaxIndex,
    required this.outgoingMaxIndex,
    this.belowRoute,
    super.settings,
    // Incoming non-opaque routes can be Offstage on frame 0 (HeroController /
    // overlay). Default Route.requestFocus then showOnScreen-s a box that has
    // not been laid out — the live web `RenderBox was not laid out` error.
    super.requestFocus = false,
  });

  final WidgetBuilder builder;
  final int incomingMaxIndex;
  final int outgoingMaxIndex;
  final ModalRoute<dynamic>? belowRoute;

  WpTurnstileFeatherTiming get timing => WpTurnstileFeatherTiming(
        outgoingMaxIndex: outgoingMaxIndex,
        incomingMaxIndex: incomingMaxIndex,
      );

  bool get _reducedMotion {
    final nav = navigator;
    return nav != null && MediaQuery.disableAnimationsOf(nav.context);
  }

  @override
  Duration get transitionDuration =>
      _reducedMotion ? Duration.zero : timing.routeDuration();

  @override
  Duration get reverseTransitionDuration =>
      _reducedMotion ? Duration.zero : timing.reverseRouteDuration();

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  /// HeroController sets [offstage] for one frame (animation forced to 1.0) even
  /// when there are no [Hero]s. That Offstage subtree is what web [showOnScreen]
  /// hits as `RenderBox was not laid out`. This gallery has no heroes.
  @override
  bool get offstage => false;

  @override
  set offstage(bool value) {}

  @override
  // This route deliberately bypasses Route.didPush; see the explanation below.
  // ignore: must_call_super
  TickerFuture didPush() {
    assert(controller != null);
    assert(!debugTransitionCompleted());
    // Skip ModalRoute/Route.didPush: Navigator.requestFocus setFirstFocus
    // showOnScreen-s the new FocusScope before overlay layout (web RenderBox).
    return controller!.forward();
  }

  @override
  // This route deliberately bypasses Route.didAdd for the same focus behavior.
  // ignore: must_call_super
  void didAdd() {
    assert(controller != null);
    assert(!debugTransitionCompleted());
    controller!.value = controller!.upperBound;
  }

  @override
  void install() {
    super.install();
    final animation = this.animation;
    if (animation != null) {
      animation.addStatusListener(_onPrimaryStatus);
    }
  }

  @override
  void dispose() {
    final animation = this.animation;
    if (animation != null) {
      animation.removeStatusListener(_onPrimaryStatus);
    }
    super.dispose();
  }

  void _onPrimaryStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse && belowRoute != null) {
      WpRevealTracker.markReveal(belowRoute!);
      WpActiveTransition.start(timing);
    }
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      WpActiveTransition.end();
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class WpPhoneListEntry extends StatefulWidget {
  const WpPhoneListEntry({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.featherIndex,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final int? featherIndex;

  @override
  State<WpPhoneListEntry> createState() => _WpPhoneListEntryState();
}

class _WpPhoneListEntryState extends State<WpPhoneListEntry> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final scope = WpPhoneFeatherScope.maybeOf(context);
    final labels = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontFamily: wpPivotFontFamily,
            fontSize: 42.667,
            height: 1.15,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.subtitle,
          style: const TextStyle(
            fontFamily: wpPivotFontFamily,
            fontSize: 20,
            color: Color(0x99ffffff),
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
    final body = widget.featherIndex != null && scope != null
        ? scope.featherLayer(
            key: ValueKey('wp-phone-entry-${widget.featherIndex}'),
            index: widget.featherIndex!,
            child: labels,
          )
        : labels;

    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.subtitle}',
      child: FocusableActionDetector(
        onShowFocusHighlight: (focused) => setState(() => _focused = focused),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: GestureDetector(
          key: widget.featherIndex != null
              ? ValueKey('wp-phone-entry-tap-${widget.featherIndex}')
              : null,
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration:
                reduced ? Duration.zero : const Duration(milliseconds: 80),
            color: _focused ? const Color(0x2effffff) : Colors.transparent,
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
            child: body,
          ),
        ),
      ),
    );
  }
}

void pushWpPhonePage(
  BuildContext context,
  Widget page, {
  required int featherMaxIndex,
}) {
  final below = ModalRoute.of(context);
  if (below != null) {
    WpRevealTracker.markObscured(below);
  }
  final outgoingMax =
      WpPhoneFeatherScope.maybeOf(context)?.maxIndex ?? featherMaxIndex;
  final timing = WpTurnstileFeatherTiming(
    outgoingMaxIndex: outgoingMax,
    incomingMaxIndex: featherMaxIndex,
  );
  WpActiveTransition.start(timing);
  Navigator.of(context)
      .push<void>(
        WpPhonePageRoute<void>(
          incomingMaxIndex: featherMaxIndex,
          outgoingMaxIndex: outgoingMax,
          belowRoute: below,
          builder: (_) => page,
        ),
      )
      .whenComplete(WpActiveTransition.end);
}
