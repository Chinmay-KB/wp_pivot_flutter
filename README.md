# wp_pivot_flutter

A Flutter package inspirred from Windows Phone Style Pivot Tabs.
![Pivots in action](showcase/ezgif-4-446097008731.gif)


## Example

The current plugin uses GlobalKey for accessing child function. A controller will be implemented in the next update

```
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';

GlobalKey<WpPivotState> globalKey = GlobalKey();

@override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: WpPivot(
          key: globalKey,
          backgroundColor: Colors.black,
          fontSize: 42,
          fontWeight: FontWeight.w400,
          selectedTabColor: Colors.white,
          unselectedTabColor: Colors.white38,
          tabTitles: [
            "Tab 1",
            "Tab 2",
            "Tab 3",
            "Tab 4",
          ],
          title: "Title",
          titleColor: Colors.white,
          titleFontSize: 14,
          titleFontWeight: FontWeight.bold,
        ),
     );
}
   


```
