import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The two display states provided by the Windows Phone application bar.
enum WpApplicationBarMode { defaultMode, minimized }

/// An icon command displayed in a [WpApplicationBar].
@immutable
class WpApplicationBarAction {
  const WpApplicationBarAction({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
}

/// A text command shown when a [WpApplicationBar] is expanded.
@immutable
class WpApplicationBarMenuItem {
  const WpApplicationBarMenuItem({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;
}

/// A Windows Phone inspired command bar for [Scaffold.bottomNavigationBar].
///
/// Default 72, minimized 30, and expanded command 102 plus a two-item menu of
/// 225 logical pixels come from the WVGA native ApplicationBar pilots
/// (`research/components/application-bar/README.md`). [animationDuration] is
/// still provisional — not a fitted native curve. Set it to zero, or set
/// [reducedMotion], to suppress expansion and focus-wash animation.
class WpApplicationBar extends StatefulWidget {
  const WpApplicationBar({
    super.key,
    this.actions = const <WpApplicationBarAction>[],
    this.menuItems = const <WpApplicationBarMenuItem>[],
    this.mode = WpApplicationBarMode.defaultMode,
    this.backgroundColor = const Color(0xff1f1f1f),
    this.foregroundColor = Colors.white,
    this.disabledColor = const Color(0xff737373),
    this.menuBackgroundColor,
    this.animationDuration = const Duration(milliseconds: 180),
    this.reducedMotion = false,
  }) : assert(actions.length <= 4,
            'WpApplicationBar supports at most 4 actions.');

  final List<WpApplicationBarAction> actions;
  final List<WpApplicationBarMenuItem> menuItems;
  final WpApplicationBarMode mode;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color disabledColor;
  final Color? menuBackgroundColor;

  /// Provisional until a calibrated ApplicationBar storyboard exists.
  final Duration animationDuration;

  /// Overrides the platform reduced-motion setting when true.
  final bool reducedMotion;

  @override
  State<WpApplicationBar> createState() => _WpApplicationBarState();
}

class _WpApplicationBarState extends State<WpApplicationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expand;
  bool _menuOpen = false;

  bool get _hasMenu => widget.menuItems.isNotEmpty;
  bool get _canExpand => _hasMenu || widget.actions.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _expand = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      reverseDuration: widget.animationDuration,
    );
  }

  @override
  void dispose() {
    _expand.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WpApplicationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_canExpand && _menuOpen) {
      _menuOpen = false;
      _expand.value = 0;
    }
  }

  bool _reducedMotion(BuildContext context) =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);

  Duration _duration(BuildContext context) =>
      _reducedMotion(context) ? Duration.zero : widget.animationDuration;

  void _setMenuOpen(bool open) {
    if (open && !_canExpand) return;
    if (_menuOpen == open) return;
    setState(() => _menuOpen = open);
    final duration = _duration(context);
    _expand.duration = duration;
    _expand.reverseDuration = duration;
    if (open) {
      _expand.forward();
    } else {
      _expand.reverse();
    }
  }

  void _toggleMenu() => _setMenuOpen(!_menuOpen);

  @override
  Widget build(BuildContext context) {
    final duration = _duration(context);
    if (_expand.duration != duration) {
      _expand.duration = duration;
      _expand.reverseDuration = duration;
    }
    if (duration == Duration.zero && _expand.isAnimating) {
      _expand.value = _menuOpen ? 1 : 0;
    }
    final mediaHeight = MediaQuery.sizeOf(context).height;
    final view = View.of(context);
    final screenHeight = mediaHeight > 0
        ? mediaHeight
        : view.physicalSize.height / view.devicePixelRatio;
    final textScaler = MediaQuery.textScalerOf(context);
    final menuColor = widget.menuBackgroundColor ?? widget.backgroundColor;
    final closedHeight =
        widget.mode == WpApplicationBarMode.minimized ? 30.0 : 72.0;
    final expandedActionHeight =
        math.max(102.0, textScaler.scale(102)).clamp(102.0, 160.0);
    final menuItemCount = widget.menuItems.length;
    // WVGA pilot: two-item menu band is 225 logical px (112.5 each) at text scale 1.
    final menuItemHeight = menuItemCount == 2
        ? math.max(112.5, textScaler.scale(112.5))
        : math.max(72.0, textScaler.scale(72.0));

    return PopScope(
      canPop: !_menuOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _menuOpen) _setMenuOpen(false);
      },
      child: Material(
        color: widget.backgroundColor,
        child: AnimatedBuilder(
          animation: _expand,
          builder: (context, child) {
            final t = _expand.value;
            final actionHeight =
                closedHeight + (expandedActionHeight - closedHeight) * t;
            final desiredMenu =
                _hasMenu ? widget.menuItems.length * menuItemHeight : 0.0;
            final menuMax =
                (screenHeight - actionHeight).clamp(0.0, desiredMenu);
            // Keep the menu mounted while the height factor is in flight so
            // collapse does not pop the command row to the bottom (MN-1).
            final showMenu = _hasMenu &&
                (t > 0 || _expand.status != AnimationStatus.dismissed);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: actionHeight,
                  child: _CommandRow(
                    actions: widget.actions,
                    canExpand: _canExpand,
                    expanded: t > 0,
                    menuOpen: _menuOpen,
                    height: actionHeight,
                    foregroundColor: widget.foregroundColor,
                    disabledColor: widget.disabledColor,
                    reducedMotion: _reducedMotion(context),
                    onToggleMenu: _toggleMenu,
                  ),
                ),
                if (showMenu)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: t,
                      child: SizedBox(
                        height: menuMax,
                        child: ColoredBox(
                          color: menuColor,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: widget.menuItems.length,
                            itemBuilder: (context, index) {
                              final item = widget.menuItems[index];
                              return _ApplicationBarButton(
                                label: item.label,
                                onPressed: item.onPressed == null
                                    ? null
                                    : () {
                                        _setMenuOpen(false);
                                        item.onPressed!();
                                      },
                                foregroundColor: widget.foregroundColor,
                                disabledColor: widget.disabledColor,
                                reducedMotion: _reducedMotion(context),
                                height: menuItemHeight,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily:
                                            'packages/wp_pivot_flutter/Selawik',
                                        fontSize: 28,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  const _CommandRow({
    required this.actions,
    required this.canExpand,
    required this.expanded,
    required this.menuOpen,
    required this.height,
    required this.foregroundColor,
    required this.disabledColor,
    required this.reducedMotion,
    required this.onToggleMenu,
  });

  final List<WpApplicationBarAction> actions;
  final bool canExpand;
  final bool expanded;
  final bool menuOpen;
  final double height;
  final Color foregroundColor;
  final Color disabledColor;
  final bool reducedMotion;
  final VoidCallback onToggleMenu;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth <= 0 ? 1.0 : constraints.maxWidth;
        final scale = availableWidth / 480;
        var spacing = 84 * scale;
        var slotWidth =
            (80 * scale).clamp(1.0, math.max(spacing, 1.0)).toDouble();
        final ellipsisWidth =
            (64 * scale).clamp(1.0, availableWidth).toDouble();
        final ellipsisCenter = (443 * scale)
            .clamp(ellipsisWidth / 2, availableWidth - ellipsisWidth / 2)
            .toDouble();
        final ellipsisLeft = ellipsisCenter - ellipsisWidth / 2;
        var groupCenter = availableWidth / 2;
        if (actions.isNotEmpty) {
          final rightLimit =
              canExpand ? math.max(ellipsisLeft - 4, 8.0) : availableWidth - 4;
          final half = (actions.length - 1) / 2;
          var lastRight = groupCenter + half * spacing + slotWidth / 2;
          var firstLeft = groupCenter - half * spacing - slotWidth / 2;
          if (lastRight > rightLimit || firstLeft < 4) {
            final usable = math.max(rightLimit - 4, 1.0);
            if (actions.length == 1) {
              slotWidth = math.min(slotWidth, usable);
              groupCenter = 4 + slotWidth / 2;
            } else {
              spacing = usable / actions.length;
              slotWidth = math.min(slotWidth, math.max(1.0, spacing - 2));
              groupCenter = 4 + usable / 2;
            }
          }
        }
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (expanded || height > 30)
              for (var index = 0; index < actions.length; index++)
                Positioned(
                  left: groupCenter +
                      (index - (actions.length - 1) / 2) * spacing -
                      slotWidth / 2,
                  top: 0,
                  width: slotWidth,
                  height: height,
                  child: _ApplicationBarButton(
                    label: actions[index].label,
                    onPressed: actions[index].onPressed,
                    foregroundColor: foregroundColor,
                    disabledColor: disabledColor,
                    reducedMotion: reducedMotion,
                    child: _ActionContents(
                      icon: actions[index].icon,
                      label: actions[index].label,
                      showLabel: expanded,
                    ),
                  ),
                ),
            if (canExpand)
              Positioned(
                left: ellipsisCenter - ellipsisWidth / 2,
                top: 0,
                width: ellipsisWidth,
                height: height,
                child: _ApplicationBarButton(
                  label: menuOpen
                      ? 'Close application menu'
                      : 'Open application menu',
                  onPressed: onToggleMenu,
                  foregroundColor: foregroundColor,
                  disabledColor: disabledColor,
                  reducedMotion: reducedMotion,
                  child: Align(
                    alignment: height <= 30
                        ? Alignment.center
                        : const Alignment(0, -.92),
                    child: _EllipsisIcon(color: foregroundColor),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActionContents extends StatelessWidget {
  const _ActionContents({
    required this.icon,
    required this.label,
    required this.showLabel,
  });

  final Widget icon;
  final String label;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color;
    final glyph = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color ?? Colors.white, width: 2),
      ),
      child: Center(
        child: IconTheme(
          data: IconThemeData(color: color, size: 26),
          child: icon,
        ),
      ),
    );
    if (!showLabel) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: glyph,
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: glyph,
            ),
          ),
        ),
        Positioned(
          left: 2,
          right: 2,
          bottom: 17,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'packages/wp_pivot_flutter/Selawik',
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EllipsisIcon extends StatelessWidget {
  const _EllipsisIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(32, 24),
      painter: _EllipsisPainter(color),
    );
  }
}

class _EllipsisPainter extends CustomPainter {
  const _EllipsisPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 8.0; x <= 24; x += 8) {
      canvas.drawCircle(Offset(x, size.height / 2), 1.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EllipsisPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ApplicationBarButton extends StatefulWidget {
  const _ApplicationBarButton({
    required this.label,
    required this.onPressed,
    required this.foregroundColor,
    required this.disabledColor,
    required this.reducedMotion,
    required this.child,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color foregroundColor;
  final Color disabledColor;
  final bool reducedMotion;
  final Widget child;
  final double? height;

  @override
  State<_ApplicationBarButton> createState() => _ApplicationBarButtonState();
}

class _ApplicationBarButtonState extends State<_ApplicationBarButton> {
  bool _focused = false;
  bool _keyboardInteraction = false;
  bool _pointerSession = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _setWash({required bool keyboard, required bool wash}) {
    if (_keyboardInteraction == keyboard && _focused == wash) return;
    setState(() {
      _keyboardInteraction = keyboard;
      _focused = wash;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.foregroundColor : widget.disabledColor;
    final child = AnimatedContainer(
      duration: widget.reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 80),
      color: _focused ? color.withAlpha(46) : Colors.transparent,
      child: IconTheme(
        data: IconThemeData(color: color),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: color),
          child: widget.child,
        ),
      ),
    );
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        enabled: enabled,
        onFocusChange: (focused) {
          if (!focused) {
            _pointerSession = false;
            _setWash(keyboard: false, wash: false);
            return;
          }
          if (_pointerSession) return;
          if (FocusManager.instance.highlightMode ==
              FocusHighlightMode.traditional) {
            _setWash(keyboard: true, wash: true);
          }
        },
        onShowFocusHighlight: (show) {
          if (_pointerSession) {
            if (_focused) setState(() => _focused = false);
            return;
          }
          final visible = show && _keyboardInteraction;
          if (_focused != visible) setState(() => _focused = visible);
        },
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              _pointerSession = false;
              _setWash(keyboard: true, wash: _focusNode.hasFocus);
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: Listener(
          onPointerDown: enabled
              ? (_) {
                  _pointerSession = true;
                  _keyboardInteraction = false;
                  if (_focused) setState(() => _focused = false);
                  _focusNode.requestFocus();
                }
              : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? () => widget.onPressed!() : null,
            child: widget.height == null
                ? child
                : SizedBox(height: widget.height, child: child),
          ),
        ),
      ),
    );
  }
}
