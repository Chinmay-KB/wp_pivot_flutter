import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'wp_phone_theme.dart';

/// A caller-ordered Start placement for [WpEditableStartGrid].
///
/// The grid packs placements in list order using first-fit placement, so list
/// order determines layout. [key] identifies the tile across reorders and must
/// be unique within one grid.
@immutable
class WpEditableStartPlacement {
  const WpEditableStartPlacement({
    required this.key,
    required this.child,
    this.rowSpan = 1,
    this.columnSpan = 1,
  })  : assert(rowSpan > 0),
        assert(columnSpan > 0);

  final Object key;
  final Widget child;
  final int rowSpan;
  final int columnSpan;
}

/// A packed slot produced by [WpEditableStartGridGeometry.pack].
@visibleForTesting
@immutable
class WpEditableStartSlot {
  const WpEditableStartSlot({
    required this.key,
    required this.index,
    required this.row,
    required this.column,
    required this.rowSpan,
    required this.columnSpan,
  });

  final Object key;
  final int index;
  final int row;
  final int column;
  final int rowSpan;
  final int columnSpan;
}

/// Pure geometry for [WpEditableStartGrid].
///
/// Values are reference units in a 480-unit-wide coordinate space, matching the
/// measured Windows Phone 8.1 Start field: 99-unit cells, 12-unit gutters,
/// 24-unit horizontal margins, and a 56-unit field top. The grid scales
/// proportionally to its bounded width.
@visibleForTesting
abstract final class WpEditableStartGridGeometry {
  static const double referenceWidth = 480;
  static const double referenceCellSize = 99;
  static const double referenceGutter = 12;
  static const double referenceMargin = 24;
  static const double referenceFieldTop = 56;
  static const double referenceBottomPadding = 32;
  static const int columns = 4;
  static const double activationFraction = 0.25;
  static const double selectedScale = 1.06;
  static const double dimmedScale = 0.92;
  static const double dimOpacity = 0.72;
  static const double ambientOffsetX = 1.4;
  static const double ambientOffsetY = 1.1;
  static const double ambientAngle = 0.0035;

  /// Packs [placements] in order using first-fit placement.
  static List<WpEditableStartSlot> pack(
    List<WpEditableStartPlacement> placements, {
    int columns = WpEditableStartGridGeometry.columns,
  }) {
    assert(columns > 0);
    final occupied = <(int, int)>{};
    final slots = <WpEditableStartSlot>[];
    for (var index = 0; index < placements.length; index++) {
      final placement = placements[index];
      final rowSpan = placement.rowSpan;
      final columnSpan = placement.columnSpan;
      assert(
        columnSpan <= columns,
        'Tile at index $index spans $columnSpan columns '
        'of a $columns-column grid.',
      );
      var row = 0;
      var placed = false;
      while (!placed) {
        for (var column = 0; column <= columns - columnSpan; column++) {
          if (_fits(
            occupied,
            row: row,
            column: column,
            rowSpan: rowSpan,
            columnSpan: columnSpan,
          )) {
            for (var y = row; y < row + rowSpan; y++) {
              for (var x = column; x < column + columnSpan; x++) {
                occupied.add((y, x));
              }
            }
            slots.add(
              WpEditableStartSlot(
                key: placement.key,
                index: index,
                row: row,
                column: column,
                rowSpan: rowSpan,
                columnSpan: columnSpan,
              ),
            );
            placed = true;
            break;
          }
        }
        if (!placed) row++;
      }
    }
    return List.unmodifiable(slots);
  }

  static bool _fits(
    Set<(int, int)> occupied, {
    required int row,
    required int column,
    required int rowSpan,
    required int columnSpan,
  }) {
    for (var y = row; y < row + rowSpan; y++) {
      for (var x = column; x < column + columnSpan; x++) {
        if (occupied.contains((y, x))) return false;
      }
    }
    return true;
  }

  /// Grid-local rect in reference units, excluding outer margin and field top.
  ///
  /// Margin and field top are constant offsets for every tile, so overlap
  /// comparisons are identical with or without them.
  static Rect slotRect({
    required int row,
    required int column,
    required int rowSpan,
    required int columnSpan,
    double cellSize = referenceCellSize,
    double gutter = referenceGutter,
  }) {
    final width = columnSpan * cellSize + (columnSpan - 1) * gutter;
    final height = rowSpan * cellSize + (rowSpan - 1) * gutter;
    return Rect.fromLTWH(
      column * (cellSize + gutter),
      row * (cellSize + gutter),
      width,
      height,
    );
  }

  /// Overlap area as a fraction of the smaller rect, in the range 0..1.
  ///
  /// A quarter of a small 99-unit tile is enough physical overlap to
  /// communicate intent while rejecting accidental 1--2px pointer tremor.
  static double overlapFraction(Rect moving, Rect candidate) {
    final overlap = moving.intersect(candidate);
    final overlapArea =
        (math.max(0, overlap.width) * math.max(0, overlap.height)).toDouble();
    if (overlapArea <= 0) return 0;
    final comparisonArea = math.min(
      moving.width * moving.height,
      candidate.width * candidate.height,
    );
    if (comparisonArea <= 0) return 0;
    return (overlapArea / comparisonArea).clamp(0.0, 1.0);
  }

  static double lerpDouble(double start, double end, double progress) =>
      start + (end - start) * progress;

  /// Deterministic wiggle phase for [key], in radians.
  static double ambientPhase(Object key) {
    var seed = 0;
    for (final codeUnit in key.toString().codeUnits) {
      seed = (seed * 31 + codeUnit) & 0x7fffffff;
    }
    return (seed % 360) / 360 * math.pi * 2;
  }

  static double exitOrder({
    required int row,
    required int column,
    required int columnSpan,
  }) =>
      math.min(8.0, 4 - column - columnSpan + row * 0.5);

  static double entryOrder({
    required int row,
    required int column,
    required int columnSpan,
  }) =>
      math.min(8.0, column + columnSpan - 1 + row * 0.5);

  /// Reference height including field top and bottom padding.
  static double referenceHeight({
    required int rows,
    double cellSize = referenceCellSize,
    double gutter = referenceGutter,
    double fieldTop = referenceFieldTop,
    double bottomPadding = referenceBottomPadding,
  }) {
    if (rows <= 0) return fieldTop + bottomPadding;
    return fieldTop +
        rows * cellSize +
        (rows - 1) * gutter +
        bottomPadding;
  }
}

/// A controlled, editable Windows Phone Start grid.
///
/// At a width of 480 logical pixels the defaults produce four 99-unit columns,
/// 12-unit gutters, 24-unit horizontal margins, and a 56-unit field top. The
/// whole coordinate system scales proportionally to the bounded width.
///
/// The caller owns order, edit selection, and persistence: [placements] are
/// packed in list order, [editingKey] selects the draggable tile (null when not
/// editing), and [onReorder] reports a committed drag as
/// `(oldIndex, newIndex)`. This widget never persists, discovers apps, or
/// schedules live data.
class WpEditableStartGrid extends StatefulWidget {
  const WpEditableStartGrid({
    super.key,
    required this.placements,
    this.editingKey,
    this.onReorder,
    this.columns = 4,
    this.referenceCellSize = 99,
    this.referenceGutter = 12,
    this.referenceHorizontalMargin = 24,
    this.referenceFieldTop = 56,
    this.referenceBottomPadding = 32,
    this.activationFraction = 0.25,
    this.selectedScale = 1.06,
    this.dimmedScale = 0.92,
    this.editScaleDuration = const Duration(milliseconds: 180),
    this.dimDuration = const Duration(milliseconds: 160),
    this.reflowDuration = const Duration(milliseconds: 220),
    this.ambientDuration = const Duration(milliseconds: 3200),
    this.ambientOffsetX = 1.4,
    this.ambientOffsetY = 1.1,
    this.ambientAngle = 0.0035,
    this.clipBehavior = Clip.none,
  })  : assert(columns > 0),
        assert(referenceCellSize > 0),
        assert(referenceGutter >= 0),
        assert(referenceHorizontalMargin >= 0),
        assert(referenceFieldTop >= 0),
        assert(referenceBottomPadding >= 0),
        assert(activationFraction >= 0 && activationFraction <= 1),
        assert(selectedScale > 0),
        assert(dimmedScale > 0),
        assert(dimOpacity >= 0 && dimOpacity <= 1),
        assert(ambientOffsetX >= 0),
        assert(ambientOffsetY >= 0),
        assert(ambientAngle >= 0);

  final List<WpEditableStartPlacement> placements;

  /// Key of the tile in edit selection, or null when not editing.
  final Object? editingKey;

  /// Called with list indices when a drag commits. Null disables reordering.
  final void Function(int oldIndex, int newIndex)? onReorder;

  final int columns;
  final double referenceCellSize;
  final double referenceGutter;
  final double referenceHorizontalMargin;
  final double referenceFieldTop;
  final double referenceBottomPadding;

  /// Overlap fraction of the smaller tile required to preview and commit.
  final double activationFraction;

  /// Scale of the selected tile in edit mode.
  final double selectedScale;

  /// Scale of non-selected tiles in edit mode.
  final double dimmedScale;
  static const double dimOpacity = 0.72;

  final Duration editScaleDuration;
  final Duration dimDuration;
  final Duration reflowDuration;
  final Duration ambientDuration;
  final double ambientOffsetX;
  final double ambientOffsetY;
  final double ambientAngle;
  final Clip clipBehavior;

  @override
  State<WpEditableStartGrid> createState() => _WpEditableStartGridState();
}

class _WpEditableStartGridState extends State<WpEditableStartGrid>
    with SingleTickerProviderStateMixin {
  List<WpEditableStartPlacement>? _previewPlacements;
  Object? _draggingKey;
  Offset _dragDelta = Offset.zero;
  Offset? _dragStart;
  double _reflowProgress = 0;
  bool _previewCanCommit = false;
  bool _motionReduced = false;
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: widget.ambientDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionReduced = MediaQuery.disableAnimationsOf(context);
    _syncAmbientMotion();
  }

  @override
  void didUpdateWidget(covariant WpEditableStartGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ambientDuration != oldWidget.ambientDuration) {
      _ambientController.duration = widget.ambientDuration;
    }
    _syncAmbientMotion();
    if (widget.editingKey == null && oldWidget.editingKey != null) {
      _draggingKey = null;
      _dragStart = null;
      _dragDelta = Offset.zero;
      _previewPlacements = null;
      _reflowProgress = 0;
      _previewCanCommit = false;
    }
    if (widget.editingKey != oldWidget.editingKey) {
      _draggingKey = null;
      _dragStart = null;
      _dragDelta = Offset.zero;
      _previewPlacements = null;
      _reflowProgress = 0;
      _previewCanCommit = false;
    }
  }

  void _syncAmbientMotion() {
    if (widget.editingKey != null && !_motionReduced) {
      if (!_ambientController.isAnimating) _ambientController.repeat();
    } else {
      _ambientController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  void _startDrag(Object key, PointerDownEvent event) {
    if (widget.editingKey != key || widget.onReorder == null) return;
    setState(() {
      _draggingKey = key;
      _dragStart = event.position;
      _dragDelta = Offset.zero;
      _previewPlacements = null;
      _reflowProgress = 0;
      _previewCanCommit = false;
    });
  }

  void _updateDrag(Object key, PointerMoveEvent event, double scale) {
    if (_draggingKey != key || _dragStart == null) return;
    if (scale <= 0) return;
    final delta = (event.position - _dragStart!) / scale;
    final original = widget.placements;
    final originSlots = WpEditableStartGridGeometry.pack(
      original,
      columns: widget.columns,
    );
    final origin = originSlots.firstWhere(
      (slot) => slot.key == key,
      orElse: () => throw StateError('Missing origin slot for $key.'),
    );
    final movingRect = WpEditableStartGridGeometry.slotRect(
      row: origin.row,
      column: origin.column,
      rowSpan: origin.rowSpan,
      columnSpan: origin.columnSpan,
      cellSize: widget.referenceCellSize,
      gutter: widget.referenceGutter,
    ).shift(delta);
    WpEditableStartSlot? target;
    var largestOverlap = 0.0;
    var largestFraction = 0.0;
    for (final slot in originSlots.where((slot) => slot.key != key)) {
      final candidateRect = WpEditableStartGridGeometry.slotRect(
        row: slot.row,
        column: slot.column,
        rowSpan: slot.rowSpan,
        columnSpan: slot.columnSpan,
        cellSize: widget.referenceCellSize,
        gutter: widget.referenceGutter,
      );
      final overlap = movingRect.intersect(candidateRect);
      final overlapArea =
          (math.max(0, overlap.width) * math.max(0, overlap.height)).toDouble();
      final fraction = WpEditableStartGridGeometry.overlapFraction(
        movingRect,
        candidateRect,
      );
      if (overlapArea > largestOverlap) {
        largestOverlap = overlapArea;
        largestFraction = fraction;
        target = slot;
      }
    }
    final preview = [...original];
    final oldIndex = preview.indexWhere((placement) => placement.key == key);
    if (target != null && largestOverlap > 0 && oldIndex >= 0) {
      final moving = preview.removeAt(oldIndex);
      preview.insert(target.index.clamp(0, preview.length), moving);
    }
    setState(() {
      _dragDelta = delta;
      _previewPlacements =
          target == null || largestOverlap == 0 ? null : preview;
      _reflowProgress =
          (largestFraction / widget.activationFraction).clamp(0.0, 1.0);
      if (widget.activationFraction <= 0) _reflowProgress = 1;
      _previewCanCommit = largestFraction >= widget.activationFraction;
    });
  }

  void _endDrag(Object key) {
    if (_draggingKey != key) return;
    final List<WpEditableStartPlacement>? previewTiles = _previewPlacements;
    final canReorder = widget.onReorder != null;
    final shouldCommit =
        _previewCanCommit && previewTiles != null && canReorder;
    final oldIndex =
        widget.placements.indexWhere((placement) => placement.key == key);
    var newIndex = oldIndex;
    if (shouldCommit) {
      newIndex = previewTiles.indexWhere((placement) => placement.key == key);
      if (newIndex < 0) newIndex = oldIndex;
    }
    setState(() {
      _draggingKey = null;
      _dragStart = null;
      _dragDelta = Offset.zero;
      _previewCanCommit = false;
      if (shouldCommit) {
        _reflowProgress = 1;
      } else {
        _previewPlacements = null;
        _reflowProgress = 0;
      }
    });
    if (shouldCommit && oldIndex >= 0 && newIndex >= 0 && oldIndex != newIndex) {
      widget.onReorder!(oldIndex, newIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _previewPlacements = null;
          _reflowProgress = 0;
        });
      });
    } else if (shouldCommit) {
      setState(() {
        _previewPlacements = null;
        _reflowProgress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_debugValidatePlacements());
    final theme = WpPhoneTheme.of(context);
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        final requestedWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : theme.referenceWidth;
        final width = constraints.constrainWidth(requestedWidth);
        final scale = width / theme.referenceWidth;
        final effectiveScale = scale <= 0 ? 1.0 : scale;
        final tiles = _previewPlacements ?? widget.placements;
        final slots = WpEditableStartGridGeometry.pack(
          tiles,
          columns: widget.columns,
        );
        final originalSlots = WpEditableStartGridGeometry.pack(
          widget.placements,
          columns: widget.columns,
        );
        final previewLastRow = slots.fold<int>(
          0,
          (value, slot) => math.max(value, slot.row + slot.rowSpan),
        );
        final originalLastRow = originalSlots.fold<int>(
          0,
          (value, slot) => math.max(value, slot.row + slot.rowSpan),
        );
        final lastRow = math.max(previewLastRow, originalLastRow);
        final referenceHeight = WpEditableStartGridGeometry.referenceHeight(
          rows: lastRow,
          cellSize: widget.referenceCellSize,
          gutter: widget.referenceGutter,
          fieldTop: widget.referenceFieldTop,
          bottomPadding: widget.referenceBottomPadding,
        );
        final height = referenceHeight * effectiveScale;
        // Paint the dragging tile last so it tracks above its neighbors.
        final ordered = [
          for (final slot in slots.where(
            (slot) => slot.key != _draggingKey,
          ))
            slot,
          for (final slot in slots.where(
            (slot) => slot.key == _draggingKey,
          ))
            slot,
        ];
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            key: const ValueKey('editable-start-tile-stack'),
            clipBehavior: widget.clipBehavior,
            children: [
              for (final slot in ordered)
                _buildSlot(
                  context,
                  slot,
                  originalSlots,
                  effectiveScale,
                  reducedMotion,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlot(
    BuildContext context,
    WpEditableStartSlot slot,
    List<WpEditableStartSlot> originalSlots,
    double scale,
    bool reducedMotion,
  ) {
    final key = slot.key;
    final dragging = key == _draggingKey;
    final origin = originalSlots.firstWhere(
      (item) => item.key == key,
      orElse: () => slot,
    );
    final positioned = dragging ? origin : slot;
    final isSelected = widget.editingKey == key;
    final inEdit = widget.editingKey != null;
    final pitch = widget.referenceCellSize + widget.referenceGutter;
    final width = (positioned.columnSpan * widget.referenceCellSize +
            (positioned.columnSpan - 1) * widget.referenceGutter) *
        scale;
    final height = (positioned.rowSpan * widget.referenceCellSize +
            (positioned.rowSpan - 1) * widget.referenceGutter) *
        scale;
    final column = dragging
        ? origin.column.toDouble()
        : WpEditableStartGridGeometry.lerpDouble(
            origin.column.toDouble(),
            slot.column.toDouble(),
            _reflowProgress,
          );
    final row = dragging
        ? origin.row.toDouble()
        : WpEditableStartGridGeometry.lerpDouble(
            origin.row.toDouble(),
            slot.row.toDouble(),
            _reflowProgress,
          );
    Widget tile = Listener(
      onPointerDown: (event) => _startDrag(key, event),
      onPointerMove: (event) => _updateDrag(key, event, scale),
      onPointerUp: (_) => _endDrag(key),
      onPointerCancel: (_) => _endDrag(key),
      child: AnimatedScale(
        key: ValueKey('tile-edit-scale-$key'),
        duration: reducedMotion ? Duration.zero : widget.editScaleDuration,
        curve: Curves.easeOutCubic,
        scale: inEdit ? (isSelected ? widget.selectedScale : widget.dimmedScale) : 1,
        child: AnimatedOpacity(
          key: ValueKey('tile-edit-opacity-$key'),
          duration: reducedMotion ? Duration.zero : widget.dimDuration,
          opacity: inEdit && !isSelected
              ? WpEditableStartGrid.dimOpacity
              : 1,
          child: _lookupChild(key),
        ),
      ),
    );
    if (inEdit && !isSelected && !reducedMotion) {
      final phase = WpEditableStartGridGeometry.ambientPhase(key);
      tile = AnimatedBuilder(
        key: ValueKey('tile-edit-wiggle-$key'),
        animation: _ambientController,
        child: tile,
        builder: (context, child) {
          final time = _ambientController.value * math.pi * 2;
          final offset = Offset(
            math.sin(time + phase) * widget.ambientOffsetX * scale,
            math.sin(time * 0.79 + phase * 1.7) *
                widget.ambientOffsetY *
                scale,
          );
          final angle =
              math.sin(time * 1.13 + phase * 0.6) * widget.ambientAngle;
          return Transform.translate(
            key: ValueKey('tile-edit-wiggle-offset-$key'),
            offset: offset,
            child: Transform.rotate(angle: angle, child: child),
          );
        },
      );
    }
    return AnimatedPositioned(
      key: ValueKey('tile-position-$key'),
      duration: reducedMotion || _draggingKey != null
          ? Duration.zero
          : widget.reflowDuration,
      curve: Curves.easeOutCubic,
      left: (widget.referenceHorizontalMargin + column * pitch) * scale +
          (dragging ? _dragDelta.dx * scale : 0),
      top: (widget.referenceFieldTop + row * pitch) * scale +
          (dragging ? _dragDelta.dy * scale : 0),
      width: width,
      height: height,
      child: tile,
    );
  }

  Widget _lookupChild(Object key) {
    final tiles = _previewPlacements ?? widget.placements;
    for (final placement in tiles) {
      if (placement.key == key) return placement.child;
    }
    for (final placement in widget.placements) {
      if (placement.key == key) return placement.child;
    }
    return const SizedBox.shrink();
  }

  bool _debugValidatePlacements() {
    final seen = <Object>{};
    for (final placement in widget.placements) {
      assert(
        seen.add(placement.key),
        'WpEditableStartGrid keys must be unique (duplicate: ${placement.key}).',
      );
      assert(
        placement.columnSpan <= widget.columns,
        'Tile ${placement.key} spans ${placement.columnSpan} columns '
        'of a ${widget.columns}-column grid.',
      );
    }
    return true;
  }
}
