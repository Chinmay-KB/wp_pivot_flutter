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

  Widget _entry(int index, double left) {
    final isSelected = index == selected;
    final onTap = onSelected == null ? null : () => onSelected!(index);
    final color = isSelected ? selectedColor : unselectedColor;
    return Positioned(
      left: left,
      top: 0,
      width: widths[index] + 12 * scale,
      height: height - 41 * scale,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: titles[index],
        excludeSemantics: true,
        onTap: onTap,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            alignment: Alignment.topLeft,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            overlayColor: Colors.transparent,
            foregroundColor: color,
            disabledForegroundColor: color,
            shape: const RoundedRectangleBorder(),
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? BorderSide(color: selectedColor)
                  : BorderSide.none,
            ),
          ),
          child: Text(
            titles[index],
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: headerStyle.copyWith(color: color),
          ),
        ),
      ),
    );
  }

  List<Widget> _entries() {
    final entries = <Widget>[];
    final count = titles.length;
    if (count == 0 || height <= 41 * scale) return entries;
    final previous = (anchor - 1) % count;
    var x = 21 * scale + translation - span(widths[previous], scale);
    for (var order = -1; order < count; order++) {
      final index = (anchor + order) % count;
      if (order >= 0 || translation > 0) entries.add(_entry(index, x));
      x += span(widths[index], scale);
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries();
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
