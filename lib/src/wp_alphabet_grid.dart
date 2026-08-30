import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'wp_phone_theme.dart';

/// Builds the visual contents of one alphabet cell.
///
/// Activation and accessibility remain owned by [WpAlphabetGrid].
typedef WpAlphabetCellBuilder = Widget Function(
  BuildContext context,
  String letter,
  bool enabled,
);

/// Measured Windows Phone 8.1 WVGA alphabet-grid geometry.
///
/// Values are reference units in a 480-unit-wide coordinate space.
@visibleForTesting
abstract final class WpAlphabetGridGeometry {
  static const referenceWidth = 480.0;
  static const horizontalMargin = 24.0;
  static const topMargin = 19.0;
  static const cellSize = 99.0;
  static const gutter = 12.0;
  static const columns = 4;
}

/// A semantic alphabet jump grid grounded in the WP8.1 WVGA study.
///
/// The default four-column grid uses 99-unit cells, 12-unit gutters, 24-unit
/// horizontal margins, and a 19-unit top margin at a width of 480. Geometry
/// scales proportionally with its available width. Disabled letters cannot be
/// activated. The caller owns list mapping, scrolling, selection state, and any
/// open, dismiss, or selection animation.
class WpAlphabetGrid extends StatelessWidget {
  const WpAlphabetGrid({
    super.key,
    required this.letters,
    required this.enabledLetters,
    required this.onSelected,
    this.onCancel,
    this.cellBuilder,
    this.columns = WpAlphabetGridGeometry.columns,
    this.enabledColor,
    this.disabledColor,
    this.foregroundColor,
    this.semanticLabel = 'Alphabet jump list',
  }) : assert(columns > 0);

  /// Letters in row-major display order.
  final List<String> letters;

  /// Letters that currently map to a destination in the caller's app list.
  final Set<String> enabledLetters;

  final ValueChanged<String> onSelected;

  /// Called when the user taps grid background or invokes dismiss/Escape.
  final VoidCallback? onCancel;

  /// Optional visual cell contents. Interaction and semantics stay built in.
  final WpAlphabetCellBuilder? cellBuilder;

  final int columns;
  final Color? enabledColor;
  final Color? disabledColor;
  final Color? foregroundColor;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = WpPhoneTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth,
          'WpAlphabetGrid requires a bounded width.',
        );
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : theme.referenceWidth;
        final scale = width / theme.referenceWidth;
        final margin = WpAlphabetGridGeometry.horizontalMargin * scale;
        final topMargin = WpAlphabetGridGeometry.topMargin * scale;
        final gutter = WpAlphabetGridGeometry.gutter * scale;
        final referenceCellSize = (theme.referenceWidth -
                WpAlphabetGridGeometry.horizontalMargin * 2 -
                WpAlphabetGridGeometry.gutter * (columns - 1)) /
            columns;
        final cellSize = referenceCellSize * scale;
        final rows =
            letters.isEmpty ? 0 : (letters.length + columns - 1) ~/ columns;
        final height =
            topMargin + rows * cellSize + (rows > 0 ? (rows - 1) * gutter : 0);

        Widget grid = SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onCancel,
                  excludeFromSemantics: true,
                  child: const SizedBox.expand(),
                ),
              ),
              for (var index = 0; index < letters.length; index++)
                _positionedCell(
                  context: context,
                  index: index,
                  letter: letters[index],
                  isEnabled: enabledLetters.contains(letters[index]),
                  margin: margin,
                  topMargin: topMargin,
                  gutter: gutter,
                  cellSize: cellSize,
                  scale: scale,
                  theme: theme,
                ),
            ],
          ),
        );

        grid = Semantics(
          container: true,
          explicitChildNodes: true,
          label: semanticLabel,
          onDismiss: onCancel,
          child: grid,
        );

        if (onCancel == null) return grid;
        return Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) {
                  onCancel!();
                  return null;
                },
              ),
            },
            child: grid,
          ),
        );
      },
    );
  }

  Widget _positionedCell({
    required BuildContext context,
    required int index,
    required String letter,
    required bool isEnabled,
    required double margin,
    required double topMargin,
    required double gutter,
    required double cellSize,
    required double scale,
    required WpPhoneThemeData theme,
  }) {
    final column = index % columns;
    final row = index ~/ columns;
    final contents = cellBuilder?.call(context, letter, isEnabled) ??
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 12 * scale, bottom: 4 * scale),
            child: Text(
              letter,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: foregroundColor ?? theme.foregroundColor,
                fontFamily: theme.fontFamily,
                fontSize: 50 * scale,
                fontWeight: FontWeight.w300,
                height: 1,
              ),
            ),
          ),
        );
    final onTap = isEnabled ? () => onSelected(letter) : null;

    return Positioned(
      key: ValueKey<String>('wp-alphabet-cell-$letter'),
      left: margin + column * (cellSize + gutter),
      top: topMargin + row * (cellSize + gutter),
      width: cellSize,
      height: cellSize,
      child: Semantics(
        container: true,
        button: true,
        enabled: isEnabled,
        label: letter,
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: isEnabled
              ? enabledColor ?? theme.accentColor
              : disabledColor ?? theme.disabledColor,
          child: InkWell(
            canRequestFocus: isEnabled,
            onTap: onTap,
            excludeFromSemantics: true,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            hoverColor: theme.foregroundColor.withAlpha(18),
            focusColor: theme.foregroundColor.withAlpha(38),
            child: SizedBox.expand(child: contents),
          ),
        ),
      ),
    );
  }
}
