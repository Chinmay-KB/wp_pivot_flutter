[![Starware](https://img.shields.io/badge/⭐-Starware-f5a91a?labelColor=black)](https://github.com/zepfietje/starware)


# wp_pivot_flutter

A Flutter package inspirred from Windows Phone Style Pivot Tabs
![Pivots in action](https://github.com/Chinmay-KB/wp_pivot_flutter/blob/master/showcase/ezgif-4-446097008731.gif)


## Example

The current plugin uses GlobalKey for accessing child function. A controller will be implemented in the next update.

```dart
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
## Starware

<!-- TODO: project name --> is Starware.  
This means you're free to use the project, as long as you star its GitHub repository.  
Your appreciation makes us grow and glow up. ⭐
