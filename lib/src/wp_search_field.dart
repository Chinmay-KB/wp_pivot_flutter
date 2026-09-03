import 'package:flutter/material.dart';

import 'wp_phone_theme.dart';

/// Measured Windows Phone 8.1 WVGA app-list search-field geometry.
///
/// Values are reference units in a 480-unit-wide coordinate space. The search
/// field occupies the first app-list slot: its 74-unit row starts at y=51 in
/// the content column (left 86, right 24) and centers a 62-unit inner field
/// for the 25-unit query text.
@visibleForTesting
abstract final class WpSearchFieldGeometry {
  /// Reference x of the app-list content column.
  static const contentLeft = 86.0;

  /// Reference y of the first app-list slot.
  static const firstSlotTop = 51.0;

  /// Reference right padding of the search slot.
  static const rightPadding = 24.0;

  /// Reference height of the search row.
  static const rowHeight = 74.0;

  /// Reference height of the inner text field.
  static const innerHeight = 62.0;

  /// Reference query-text size.
  static const fontSize = 25.0;
}

/// A reusable app-list search field using the measured WVGA presentation.
///
/// At a width of 480 the field occupies a 74-unit row and centers a 62-unit
/// inner text field for 25-unit query text. Geometry scales proportionally
/// with the available width, so callers should provide the scaled screen
/// width (for example full-width placement). The rest underline is 1-unit
/// foreground white and the focused underline is 2-unit accent; the cursor
/// uses the accent color.
///
/// The widget owns presentation only: [onChanged] forwards query edits and
/// the caller owns filtering, list updates, and dismissal.
class WpSearchField extends StatefulWidget {
  const WpSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'search',
    this.onChanged,
    this.autofocus = false,
    this.semanticLabel = 'Search apps',
    this.foregroundColor,
    this.accentColor,
    this.hintColor,
  });

  /// Controls the query text. A null controller uses the text-field default.
  final TextEditingController? controller;

  /// Focus for the inner text field. An internal node labelled
  /// `WpSearchField` is used when omitted.
  final FocusNode? focusNode;

  /// Placeholder shown when the query is empty.
  final String hintText;

  /// Forwards query edits. A null callback exposes a disabled field.
  final ValueChanged<String>? onChanged;

  /// When true, requests focus on mount.
  final bool autofocus;

  /// Accessibility label for the search field.
  final String semanticLabel;

  /// Query, hint-underline, and rest-underline color.
  final Color? foregroundColor;

  /// Cursor and focused-underline color.
  final Color? accentColor;

  /// Placeholder color. Defaults to the foreground at 54% opacity.
  final Color? hintColor;

  @override
  State<WpSearchField> createState() => _WpSearchFieldState();
}

class _WpSearchFieldState extends State<WpSearchField> {
  late final FocusNode _internalFocusNode =
      FocusNode(debugLabel: 'WpSearchField');

  @override
  void dispose() {
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final foreground = widget.foregroundColor ?? theme.foregroundColor;
    final accent = widget.accentColor ?? theme.accentColor;
    final hint = widget.hintColor ?? foreground.withAlpha(138);
    final enabled = widget.onChanged != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth,
          'WpSearchField requires a bounded width.',
        );
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : theme.referenceWidth;
        final scale = width / theme.referenceWidth;
        final fontSize = WpSearchFieldGeometry.fontSize * scale;
        return SizedBox(
          width: width,
          height: WpSearchFieldGeometry.rowHeight * scale,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              key: const ValueKey('wp-search-field-inner'),
              height: WpSearchFieldGeometry.innerHeight * scale,
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                label: widget.semanticLabel,
                onTap: () =>
                    (widget.focusNode ?? _internalFocusNode).requestFocus(),
                child: TextField(
                  key: const ValueKey('wp-search-field'),
                  controller: widget.controller,
                  focusNode: widget.focusNode ?? _internalFocusNode,
                  autofocus: widget.autofocus,
                  enabled: enabled,
                  onChanged: widget.onChanged,
                  style: TextStyle(
                    color: foreground,
                    fontFamily: theme.fontFamily,
                    fontSize: fontSize,
                  ),
                  cursorColor: accent,
                  cursorOpacityAnimates: !disableAnimations,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: hint,
                      fontFamily: theme.fontFamily,
                      fontSize: fontSize,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: foreground),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: accent, width: 2),
                    ),
                    disabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: theme.disabledColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
