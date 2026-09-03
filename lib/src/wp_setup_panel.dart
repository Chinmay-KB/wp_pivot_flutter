import 'package:flutter/material.dart';

import 'wp_phone_theme.dart';

/// A single square text action in a [WpSetupPanel].
@immutable
class WpSetupAction {
  const WpSetupAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;
}

/// Setup controls shown while app capabilities are missing.
///
/// Must be placed in a [Stack]. The panel sits at 24 logical pixels from the
/// left and right edges and 24 logical pixels plus
/// [MediaQuery.paddingOf.bottom] from the bottom, over
/// [WpPhoneThemeData.backgroundColor] and beneath a 2-logical-pixel
/// [WpPhoneThemeData.foregroundColor] top rule with 10 logical pixels of top
/// padding. Actions are square ([BorderRadius.zero]) text buttons with a
/// 48×48 minimum size and 18-logical-pixel [FontWeight.w400] labels.
///
/// Returns [SizedBox.shrink] when [actions] is empty, matching the launcher
/// behavior of hiding setup once capabilities are satisfied. The panel is
/// static and therefore already honors reduced-motion.
class WpSetupPanel extends StatelessWidget {
  const WpSetupPanel({super.key, required this.actions});

  final List<WpSetupAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = WpPhoneTheme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 24,
      right: 24,
      bottom: 24 + bottomInset,
      child: ColoredBox(
        color: theme.backgroundColor,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.foregroundColor, width: 2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                for (final action in actions)
                  TextButton(
                    onPressed: action.onPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.foregroundColor,
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      textStyle: TextStyle(
                        fontFamily: theme.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    child: Text(action.label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Transient feedback shown over the black field.
///
/// Must be placed in a [Stack] at the same 24-unit offsets as [WpSetupPanel].
/// A null or empty [text] hides the notice with zero opacity and disables
/// hit testing via [IgnorePointer]. Otherwise the 19-logical-pixel message
/// in [WpPhoneThemeData.foregroundColor] fades in over [fadeDuration].
///
/// [visibleDuration] is the caller-owned hold time (1600 ms in the launcher)
/// before clearing [text]; this widget owns only the [fadeDuration] opacity
/// transition (120 ms in the launcher). When
/// [MediaQuery.disableAnimationsOf] is true the fade collapses to zero. The
/// message is exposed as a live region for assistive technology.
class WpTransientNotice extends StatelessWidget {
  const WpTransientNotice({
    super.key,
    this.text,
    this.visibleDuration = const Duration(milliseconds: 1600),
    this.fadeDuration = const Duration(milliseconds: 120),
    this.textStyle,
  });

  /// The message to show. Null or empty hides the notice.
  final String? text;

  /// Recommended caller-owned hold time before clearing [text].
  final Duration visibleDuration;

  /// Opacity transition time. Collapses to zero under reduced-motion.
  final Duration fadeDuration;

  /// Overrides the default 19-unit themed message style.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reducedMotion ? Duration.zero : fadeDuration;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final visible = text != null && text!.isNotEmpty;
    final message = text ?? '';
    return Positioned(
      left: 24,
      right: 24,
      bottom: 24 + bottomInset,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          duration: duration,
          opacity: visible ? 1 : 0,
          child: ColoredBox(
            color: theme.backgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Semantics(
                liveRegion: true,
                label: visible ? message : null,
                excludeSemantics: true,
                child: Text(
                  message,
                  style:
                      textStyle ??
                      TextStyle(
                        fontFamily: theme.fontFamily,
                        fontSize: 19,
                        color: theme.foregroundColor,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
