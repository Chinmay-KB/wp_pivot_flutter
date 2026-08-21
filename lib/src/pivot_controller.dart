import 'package:flutter/foundation.dart';

/// Controls the state of a [WpPivot] widget.
///
/// The controller is the single source of truth for which pivot tab is
/// selected. Listeners are notified whenever [index] changes, so the pivot
/// bar and any companion view (e.g. a [PageView]) can stay in sync without
/// GlobalKeys:
///
/// ```dart
/// final pivotController = PivotController(length: tabs.length);
///
/// pivotController.addListener(() {
///   pageController.animateToPage(
///     pivotController.index,
///     duration: const Duration(milliseconds: 600),
///     curve: Curves.fastLinearToSlowEaseIn,
///   );
/// });
/// ```
class PivotController extends ChangeNotifier {
  /// Creates a pivot controller for [length] tabs.
  ///
  /// The initial selection is [initialIndex], clamped into range.
  PivotController({required int length, int initialIndex = 0})
      : assert(length >= 0),
        _length = length,
        _index = length == 0 ? 0 : initialIndex.clamp(0, length - 1);

  final int _length;
  int _index;
  int _previousIndex = 0;

  /// The number of tabs.
  int get length => _length;

  /// The currently selected tab index.
  int get index => _index;

  /// The previously selected tab index, before the most recent change.
  int get previousIndex => _previousIndex;

  /// Whether there is a next tab to navigate to.
  bool get canGoNext => _index < _length - 1;

  /// Whether there is a previous tab to navigate to.
  bool get canGoPrevious => _index > 0;

  /// Selects [index], notifying listeners if it changed.
  ///
  /// Out-of-range values are clamped. Returns true when the selection moved.
  bool animateTo(int index) {
    if (_length == 0) return false;
    final target = index.clamp(0, _length - 1);
    if (target == _index) return false;
    _previousIndex = _index;
    _index = target;
    notifyListeners();
    return true;
  }

  /// Selects the next tab, if any. Returns true when the selection moved.
  bool next() => animateTo(_index + 1);

  /// Selects the previous tab, if any. Returns true when the selection moved.
  bool previous() => animateTo(_index - 1);
}
