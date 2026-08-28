import 'package:flutter/material.dart';

/// Internal shared layout for the full native-reference Pivot surface.
class PivotHeader extends StatelessWidget {
  const PivotHeader(
      {super.key,
      required this.title,
      required this.titles,
      required this.selected,
      required this.anchor,
      required this.translation,
      required this.scale,
      required this.widths,
      required this.headerStyle,
      required this.titleStyle,
      required this.onSelected,
      required this.selectedColor,
      required this.unselectedColor,
      required this.height});

  final String title;
  final List<String> titles;
  final int selected, anchor;
  final double translation, scale, height;
  final List<double> widths;
  final TextStyle headerStyle, titleStyle;
  final ValueChanged<int>? onSelected;
  final Color selectedColor, unselectedColor;

  static double span(double width, double scale) =>
      ((width / scale + 22.667).roundToDouble()) * scale;

  @override
  Widget build(BuildContext context) {
    final entries = <Widget>[];
    final count = titles.length;
    if (count > 0 && height > 41 * scale) {
      final previous = (anchor - 1) % count;
      var x = 21 * scale + translation - span(widths[previous], scale);
      for (var order = -1; order < count; order++) {
        final index = (anchor + order) % count;
        if (order >= 0 || translation > 0) {
          entries.add(Positioned(
            left: x,
            top: 0,
            width: widths[index] + 12 * scale,
            height: height - 41 * scale,
            child: Semantics(
              button: true,
              selected: index == selected,
              label: titles[index],
              excludeSemantics: true,
              onTap: onSelected == null ? null : () => onSelected!(index),
              child: TextButton(
                onPressed: onSelected == null ? null : () => onSelected!(index),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.topLeft,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  overlayColor: Colors.transparent,
                  foregroundColor:
                      index == selected ? selectedColor : unselectedColor,
                  disabledForegroundColor:
                      index == selected ? selectedColor : unselectedColor,
                  shape: const RoundedRectangleBorder(),
                ).copyWith(
                    side: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.focused)
                            ? BorderSide(color: selectedColor)
                            : BorderSide.none)),
                child: Text(titles[index],
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: headerStyle.copyWith(
                        color: index == selected
                            ? selectedColor
                            : unselectedColor)),
              ),
            ),
          ));
        }
        x += span(widths[index], scale);
      }
    }
    return SizedBox(
        height: height,
        child: ClipRect(
            child: Stack(children: [
          Positioned(
              left: 24 * scale,
              top: 16 * scale,
              right: 24 * scale,
              child: Text(title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle)),
          if (height > 41 * scale)
            Positioned(
                left: 0,
                right: 0,
                top: 41 * scale,
                bottom: 0,
                child: Stack(clipBehavior: Clip.hardEdge, children: entries)),
        ])));
  }
}
