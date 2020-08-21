library wp_pivot_flutter;

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class WpPivot extends StatefulWidget implements PreferredSizeWidget {
  WpPivot({
    Key key,
    this.backgroundColor,
    this.selectedTabColor = Colors.black,
    this.unselectedTabColor = Colors.black38,
    this.tabTitles,
    this.fontWeight = FontWeight.w200,
    this.fontSize = 36,
    this.titleFontWeight = FontWeight.bold,
    this.titleFontSize = 16,
    this.titleColor = Colors.white,
    @required this.title,
  }) : super(key: key);

  /// Background color of the Appbar and tab bar
  Color backgroundColor;

  /// Color of selected tab. White by default, staying true to its origins
  Color selectedTabColor = Colors.white;

  /// Color of rest of the tabs
  Color unselectedTabColor = Colors.white30;

  FontWeight fontWeight, titleFontWeight;
  @required
  List<String> tabTitles;
  @required
  double fontSize;
  String title;
  double titleFontSize;
  Color titleColor;
  @override
  State<StatefulWidget> createState() => WpPivotState();

  @override
  // TODO: implement preferredSize
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
  String title;
  Color textColor;
  FontWeight fontWeight;
  double fontSize;
  CustomAppBar(
      {Key key, this.title, this.textColor, this.fontSize, this.fontWeight})
      : preferredSize = Size.fromHeight(kToolbarHeight),
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
