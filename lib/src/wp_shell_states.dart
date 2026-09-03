import 'package:flutter/material.dart';

import 'wp_phone_theme.dart';

/// Measured black-field shell tokens shared by loading, failure and empty
/// Start states.
///
/// The 160×3 loading line, 24-unit failure padding, 34-unit headline, 96×48
/// retry target, 44-unit empty icon and 21-unit empty message come from the
/// Metrophone launcher shell (`launcher_screen.dart`). This package owns only
/// the reusable presentation; callers own navigation, persistence and
/// launcher policy.
abstract final class WpShellStatesGeometry {
  static const loadingWidth = 160.0;
  static const loadingHeight = 3.0;
  static const failurePadding = 24.0;
  static const headlineFontSize = 34.0;
  static const detailFontSize = 18.0;
  static const retryMinWidth = 96.0;
  static const retryMinHeight = 48.0;
  static const emptyIconSize = 44.0;
  static const emptyMessageFontSize = 21.0;
}

/// A centered 160-logical-pixel-wide, 3-logical-pixel-high linear indicator
/// on a dark track.
///
/// Colors come from [WpPhoneThemeData]: the scaffold uses
/// [WpPhoneThemeData.backgroundColor], the moving line uses
/// [WpPhoneThemeData.accentColor] and the track uses
/// [WpPhoneThemeData.disabledColor] (which defaults to `#202020`). Geometry
/// is square (`BorderRadius.zero`).
///
/// When [MediaQuery.disableAnimationsOf] is true the indicator renders a
/// static half-filled line instead of animating.
class WpLoadingSurface extends StatelessWidget {
  const WpLoadingSurface({super.key, this.semanticLabel = 'Loading'});

  /// Accessibility label for the progress indicator.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Center(
        child: SizedBox(
          width: WpShellStatesGeometry.loadingWidth,
          child: Semantics(
            label: semanticLabel,
            child: LinearProgressIndicator(
              minHeight: WpShellStatesGeometry.loadingHeight,
              // Static determinate fill when reduced-motion is requested;
              // otherwise the standard indeterminate animation runs.
              value: disableAnimations ? 0.5 : null,
              color: theme.accentColor,
              backgroundColor: theme.disabledColor,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ),
    );
  }
}

/// A safe-area black failure surface with padded headline, concise detail
/// text and a square retry action.
///
/// Padding is 24 logical pixels. The headline is 34 logical pixels at
/// [FontWeight.w300] in [WpPhoneThemeData.foregroundColor]. The detail line
/// is 18 logical pixels in the foreground color at 70% opacity. The retry
/// action is white-on-accent with a 96×48 minimum size and square
/// (`BorderRadius.zero`) corners.
///
/// The surface is static and therefore already honors
/// [MediaQuery.disableAnimationsOf].
class WpFailureSurface extends StatelessWidget {
  const WpFailureSurface({
    super.key,
    this.headline = 'Something could not start',
    this.detail = 'An unknown error occurred.',
    this.retryLabel = 'retry',
    required this.onRetry,
  });

  final String headline;
  final String detail;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WpShellStatesGeometry.failurePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                headline,
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: WpShellStatesGeometry.headlineFontSize,
                  fontWeight: FontWeight.w300,
                  color: theme.foregroundColor,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                detail,
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: WpShellStatesGeometry.detailFontSize,
                  // Matches Colors.white70 when the foreground is white.
                  color: theme.foregroundColor.withAlpha(179),
                ),
              ),
              const SizedBox(height: 28),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: theme.foregroundColor,
                  backgroundColor: theme.accentColor,
                  minimumSize: const Size(
                    WpShellStatesGeometry.retryMinWidth,
                    WpShellStatesGeometry.retryMinHeight,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  textStyle: TextStyle(fontFamily: theme.fontFamily),
                ),
                child: Text(retryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An empty-Start prompt that navigates to the app list to pin the first
/// tile.
///
/// The icon is 44 logical pixels and the message is 21 logical pixels at
/// [FontWeight.w300] with a 1.25 line height, both in
/// [WpPhoneThemeData.foregroundColor]. The ink splash is square
/// (`BorderRadius.zero`) and is replaced with [NoSplash] plus a transparent
/// highlight when [MediaQuery.disableAnimationsOf] is true.
class WpEmptyStart extends StatelessWidget {
  const WpEmptyStart({
    super.key,
    required this.onOpen,
    this.icon = Icons.arrow_forward,
    this.message = 'swipe to apps\nthen hold an app to pin it',
    this.semanticsLabel = 'Open apps to pin your first tile',
  });

  final VoidCallback onOpen;
  final IconData icon;
  final String message;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Center(
      child: Semantics(
        button: true,
        label: semanticsLabel,
        onTap: onOpen,
        excludeSemantics: true,
        child: InkWell(
          onTap: onOpen,
          excludeFromSemantics: true,
          borderRadius: BorderRadius.zero,
          splashFactory:
              disableAnimations ? NoSplash.splashFactory : null,
          highlightColor: disableAnimations ? Colors.transparent : null,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: WpShellStatesGeometry.emptyIconSize,
                  color: theme.foregroundColor,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: theme.fontFamily,
                    color: theme.foregroundColor,
                    fontSize: WpShellStatesGeometry.emptyMessageFontSize,
                    fontWeight: FontWeight.w300,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
