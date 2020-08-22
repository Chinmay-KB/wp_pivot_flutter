library wp_pivot_flutter;

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// This is a Flutter implementation of pivot style tabs in Windows Phone 7.x and 8.x
/// Pass a list of string you want as tabs and voila !
/// This plugin is currently using [GlobalKey] for parent->child communication,
/// which is not ideal. This will be improved in the nexr update

class WpPivot extends StatefulWidget implements PreferredSizeWidget {
  const WpPivot({
    Key key,
    this.backgroundColor = Colors.black,
    this.selectedTabColor = Colors.white,
    this.unselectedTabColor = Colors.white54,
    this.tabTitles,
    this.fontWeight = FontWeight.w200,
    this.fontSize = 36,
    this.titleFontWeight = FontWeight.bold,
    this.titleFontSize = 16,
    this.titleColor = Colors.white,
    @required this.title,
  }) : super(key: key);

  /// Background color of the Appbar and tab bar, default is [Colors.black]
  final Color backgroundColor;

  /// Color of selected tab, default is [Colors.white]
  final Color selectedTabColor;

  /// Color of rest of the tabs, default is [Colors.white54]
  final Color unselectedTabColor;

  /// Set the font weight of the tab options, default is [FontWeight.w200].
  final FontWeight fontWeight, titleFontWeight;

  /// List of all the tab names
  @required
  final List<String> tabTitles;

  /// Font size of the tab names, default is [36]
  @required
  final double fontSize;

  /// Set the pivot title
  final String title;

  /// Font size of the pivot title, default is [16]
  final double titleFontSize;

  /// Color of pivot title, default is [Colors.white]
  final Color titleColor;
  @override
  State<StatefulWidget> createState() => WpPivotState();

  @override
  Size get preferredSize => Size.fromHeight(fontSize * 1.5 + 42.5011);
}

class WpPivotState extends State<WpPivot> {
  final ItemScrollController itemScrollController = ItemScrollController();

  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  int highlightedIndex = 0;
  @override
  Widget build(BuildContext context) {
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
                physics: NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
                itemBuilder: (BuildContext context, int index) {
                  return (index != widget.tabTitles.length)
                      ? Padding(
                          padding: EdgeInsets.only(right: 28),
                          child: Text(
                            widget.tabTitles[index],
                            style: TextStyle(
                              fontSize: widget.fontSize,
                              color: (highlightedIndex == index)
                                  ? widget.selectedTabColor
                                  : widget.unselectedTabColor,
                              fontWeight: widget.fontWeight,
                            ),
                          ),
                        )
                      : Container(
                          width: 50,
                        );
                },
                itemCount: widget.tabTitles.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Function to take care of page change, currently only an increment of a decrement by 1 is allowed
  handlePagechange(int currentPage) {
    if (currentPage > highlightedIndex)
      increase();
    else
      decrease();
  }

  increase() {
    if (highlightedIndex != widget.tabTitles.length - 1)
      setState(() {
        itemScrollController.scrollTo(
            index: highlightedIndex + 1,
            curve: Curves.fastLinearToSlowEaseIn,
            duration: Duration(milliseconds: 600));
        highlightedIndex++;
      });
  }

  decrease() {
    if (highlightedIndex != 0)
      setState(() {
        itemScrollController.scrollTo(
            index: highlightedIndex - 1,
            curve: Curves.fastLinearToSlowEaseIn,
            duration: Duration(milliseconds: 600));
        highlightedIndex--;
      });
  }
}

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Color textColor;
  final FontWeight fontWeight;
  final double fontSize;
  const CustomAppBar(
      {Key key, this.title, this.textColor, this.fontSize, this.fontWeight})
      : preferredSize = const Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize; // default is 56.0

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.only(top: 16, left: 16),
        child: Text(
          widget.title,
          style: TextStyle(
              color: widget.textColor,
              fontWeight: widget.fontWeight,
              fontSize: widget.fontSize),
        ),
      ),
    );
  }
}
