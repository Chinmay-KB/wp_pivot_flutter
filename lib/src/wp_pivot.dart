import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:wp_pivot_flutter/src/custom_appbar.dart';
import 'package:wp_pivot_flutter/src/pivot_controller.dart';

/// A Flutter implementation of pivot style tabs in Windows Phone 7.x and 8.x.
///
/// Pass a list of strings you want as tabs and voila!
///
/// Selection state lives in a [PivotController]. If none is provided, an
/// internal one is created; pass your own to drive the pivot from the outside
/// (e.g. to keep it in sync with a [PageView]).
class WpPivot extends StatefulWidget implements PreferredSizeWidget {
  const WpPivot({
    super.key,
    required this.tabTitles,
    this.backgroundColor = Colors.black,
    this.selectedTabColor = Colors.white,
    this.unselectedTabColor = Colors.white54,
    this.fontWeight = FontWeight.w200,
    this.fontSize = 36,
    this.titleFontWeight = FontWeight.bold,
    this.titleFontSize = 16,
    this.titleColor = Colors.white,
    required this.title,
    this.controller,
  });

  /// Background color of the Appbar and tab bar, default is [Colors.black]
  final Color backgroundColor;

  /// Color of selected tab, default is [Colors.white]
  final Color selectedTabColor;

  /// Color of rest of the tabs, default is [Colors.white54]
  final Color unselectedTabColor;

  /// Set the font weight of the tab options, default is [FontWeight.w200].
  final FontWeight fontWeight, titleFontWeight;

  /// List of all the tab names
  final List<String> tabTitles;

  /// Font size of the tab names, default is [36]
  final double fontSize;

  /// Set the pivot title
  final String title;

  /// Font size of the pivot title, default is [16]
  final double titleFontSize;

  /// Color of pivot title, default is [Colors.white]
  final Color titleColor;

  /// Controls which tab is selected.
  ///
  /// When omitted, the widget manages its own internal controller.
  /// The controller's [PivotController.length] should match
  /// [tabTitles.length]; in debug mode an assertion enforces this.
  final PivotController? controller;

  @override
  State<WpPivot> createState() => _WpPivotState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + fontSize * 1.7);
}

const Duration _kScrollDuration = Duration(milliseconds: 600);
const Curve _kScrollCurve = Curves.fastLinearToSlowEaseIn;

class _WpPivotState extends State<WpPivot> {
  PivotController? _internalController;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int? _lastScrolledIndex;

  PivotController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = PivotController(length: widget.tabTitles.length);
    }
    _effectiveController.addListener(_handleSelectionChanged);
  }

  @override
  void didUpdateWidget(covariant WpPivot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?.removeListener(_handleSelectionChanged);
      if (widget.controller == null && _internalController == null) {
        _internalController = PivotController(length: widget.tabTitles.length);
      } else {
        _internalController?.dispose();
        _internalController = null;
      }
      _effectiveController.addListener(_handleSelectionChanged);
      _lastScrolledIndex = null;
      _scrollToSelection(animated: false);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleSelectionChanged);
    _internalController?.dispose();
    super.dispose();
  }

  void _handleSelectionChanged() {
    setState(() {});
    _scrollToSelection();
  }

  void _scrollToSelection({bool animated = true}) {
    final index = _effectiveController.index;
    if (_lastScrolledIndex == index) return;
    _lastScrolledIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_itemScrollController.isAttached) return;
      _itemScrollController.scrollTo(
        index: index,
        duration: animated ? _kScrollDuration : Duration.zero,
        curve: _kScrollCurve,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      if (widget.controller != null &&
          widget.controller!.length != widget.tabTitles.length) {
        throw FlutterError(
          'WpPivot.controller has length ${widget.controller!.length}, but '
          '${widget.tabTitles.length} tab titles were provided. '
          'The controller length must match tabTitles.length.',
        );
      }
      return true;
    }());

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: CustomAppBar(
        title: widget.title.toUpperCase(),
        fontSize: widget.titleFontSize,
        fontWeight: widget.titleFontWeight,
        textColor: widget.titleColor,
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: widget.fontSize * 1.7,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
              child: ScrollablePositionedList.builder(
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
                itemBuilder: (BuildContext context, int index) {
                  return (index != widget.tabTitles.length)
                      ? Padding(
                          padding: const EdgeInsets.only(right: 28),
                          child: Text(
                            widget.tabTitles[index],
                            style: TextStyle(
                              fontSize: widget.fontSize,
                              color: (_effectiveController.index == index)
                                  ? widget.selectedTabColor
                                  : widget.unselectedTabColor,
                              fontWeight: widget.fontWeight,
                            ),
                          ),
                        )
                      : Container(width: 50);
                },
                itemCount: widget.tabTitles.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
