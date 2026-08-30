import 'package:flutter/material.dart';

/// A child and its explicit zero-based position in a [WpTileGrid].
@immutable
class WpTilePlacement {
  const WpTilePlacement({
    required this.child,
    required this.row,
    required this.column,
    this.rowSpan = 1,
    this.columnSpan = 1,
  })  : assert(row >= 0),
        assert(column >= 0),
        assert(rowSpan > 0),
        assert(columnSpan > 0);

  final Widget child;
  final int row;
  final int column;
  final int rowSpan;
  final int columnSpan;
}

/// Lays out explicitly placed children on the measured WVGA tile grid.
///
/// At a width of 480 logical pixels, the defaults produce four 99-pixel
/// columns, 12-pixel gutters, and 24-pixel horizontal outer margins. The whole
/// coordinate system scales proportionally to the bounded width. Placement is
/// deterministic: this widget does not discover apps, reorder tiles, or manage
/// pinning and persistence.
class WpTileGrid extends StatelessWidget {
  const WpTileGrid({
    super.key,
    required this.placements,
    this.columns = 4,
    this.referenceCellSize = 99,
    this.referenceGutter = 12,
    this.referenceHorizontalMargin = 24,
    this.scrollable = false,
    this.controller,
    this.physics,
    this.clipBehavior = Clip.none,
  })  : assert(columns > 0),
        assert(referenceCellSize > 0),
        assert(referenceGutter >= 0),
        assert(referenceHorizontalMargin >= 0),
        assert(scrollable || controller == null,
            'A controller requires scrollable to be true.');

  final List<WpTilePlacement> placements;
  final int columns;
  final double referenceCellSize;
  final double referenceGutter;
  final double referenceHorizontalMargin;

  /// Wraps the grid in a vertical [SingleChildScrollView] when true.
  final bool scrollable;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    assert(_debugValidatePlacements());
    return LayoutBuilder(
      builder: (context, constraints) {
        final referenceGridWidth = referenceHorizontalMargin * 2 +
            columns * referenceCellSize +
            (columns - 1) * referenceGutter;
        final requestedWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : referenceGridWidth;
        final width = constraints.constrainWidth(requestedWidth);
        final scale = width / referenceGridWidth;
        final occupiedRows = placements.fold<int>(
          0,
          (current, placement) => (placement.row + placement.rowSpan) > current
              ? placement.row + placement.rowSpan
              : current,
        );
        final referenceHeight = occupiedRows == 0
            ? 0.0
            : occupiedRows * referenceCellSize +
                (occupiedRows - 1) * referenceGutter;
        final height = referenceHeight * scale;
        final grid = SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: clipBehavior,
            children: <Widget>[
              for (final placement in placements)
                Positioned(
                  left: (referenceHorizontalMargin +
                          placement.column *
                              (referenceCellSize + referenceGutter)) *
                      scale,
                  top: placement.row *
                      (referenceCellSize + referenceGutter) *
                      scale,
                  width: (placement.columnSpan * referenceCellSize +
                          (placement.columnSpan - 1) * referenceGutter) *
                      scale,
                  height: (placement.rowSpan * referenceCellSize +
                          (placement.rowSpan - 1) * referenceGutter) *
                      scale,
                  child: placement.child,
                ),
            ],
          ),
        );
        if (!scrollable) return grid;
        return SingleChildScrollView(
          controller: controller,
          physics: physics,
          child: grid,
        );
      },
    );
  }

  bool _debugValidatePlacements() {
    final occupied = <int>{};
    for (final placement in placements) {
      assert(
        placement.column + placement.columnSpan <= columns,
        'Tile at row ${placement.row}, column ${placement.column} extends '
        'beyond the $columns-column grid.',
      );
      for (var row = placement.row;
          row < placement.row + placement.rowSpan;
          row++) {
        for (var column = placement.column;
            column < placement.column + placement.columnSpan;
            column++) {
          final cell = row * columns + column;
          assert(
            occupied.add(cell),
            'Tile placements overlap at row $row, column $column.',
          );
        }
      }
    }
    return true;
  }
}
