import 'package:flutter/material.dart';

import 'wp_phone_theme.dart';

/// Measured Windows Phone 8.1 wide live-tile content geometry.
///
/// Values are reference units at the 432-unit-wide wide tile
/// (four 99-unit columns with 12-unit gutters). The widget scales them
/// proportionally to its bounded parent width.
@visibleForTesting
abstract final class WpLiveTileContentGeometry {
  static const referenceWidth = 432.0;
  static const referenceHeight = 210.0;
  static const paddingLeft = 18.0;
  static const paddingTop = 18.0;
  static const paddingRight = 18.0;
  static const paddingBottom = 34.0;
  static const gap = 18.0;
  static const titleFontSize = 19.0;
  static const bodyFontSize = 16.0;
  static const bodyHeight = 1.12;
  static const countFontSize = 25.0;
}

/// Wide live-tile content: icon, title, body, and notification count.
///
/// At the 432-unit reference width the content uses 18-unit top/side padding
/// and 34-unit bottom padding, an 18-unit icon gap, a 19-unit single-line
/// title, a 16-unit two-line body with a 1.12 line-height multiplier, and a
/// 25-unit weight-300 count shown only when [count] is greater than one. The
/// whole composition scales proportionally to the parent-provided width.
///
/// Colors and font family come from [WpPhoneTheme]. The caller owns tile size,
/// placement, tap handling, and live-data scheduling; when [title], [body],
/// and [count] carry no live content the icon is centered.
class WpLiveTileContent extends StatelessWidget {
  const WpLiveTileContent({
    super.key,
    required this.icon,
    this.title,
    this.body,
    this.count = 0,
  }) : assert(count >= 0);

  final Widget icon;
  final String? title;
  final String? body;

  /// Notification count. Shown only when greater than one.
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth,
          'WpLiveTileContent requires a bounded width.',
        );
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : WpLiveTileContentGeometry.referenceWidth;
        final scale = width <= 0
            ? 1.0
            : width / WpLiveTileContentGeometry.referenceWidth;
        if (title == null && body == null && count <= 1) {
          return Center(child: icon);
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(
            WpLiveTileContentGeometry.paddingLeft * scale,
            WpLiveTileContentGeometry.paddingTop * scale,
            WpLiveTileContentGeometry.paddingRight * scale,
            WpLiveTileContentGeometry.paddingBottom * scale,
          ),
          child: Row(
            children: [
              icon,
              SizedBox(width: WpLiveTileContentGeometry.gap * scale),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.foregroundColor,
                          fontFamily: theme.fontFamily,
                          fontSize: WpLiveTileContentGeometry.titleFontSize *
                              scale,
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                      ),
                    if (body != null)
                      Text(
                        body!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.foregroundColor,
                          fontFamily: theme.fontFamily,
                          fontSize:
                              WpLiveTileContentGeometry.bodyFontSize * scale,
                          fontWeight: FontWeight.w400,
                          height: WpLiveTileContentGeometry.bodyHeight,
                        ),
                      ),
                  ],
                ),
              ),
              if (count > 1)
                Text(
                  '$count',
                  style: TextStyle(
                    color: theme.foregroundColor,
                    fontFamily: theme.fontFamily,
                    fontSize:
                        WpLiveTileContentGeometry.countFontSize * scale,
                    fontWeight: FontWeight.w300,
                    height: 1,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
