[![Starware](https://img.shields.io/badge/⭐-Starware-f5a91a?labelColor=black)](https://github.com/zepfietje/starware)


# wp_pivot_flutter
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

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
## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/Chinmay-KB"><img src="https://avatars0.githubusercontent.com/u/13520364?v=4" width="100px;" alt=""/><br /><sub><b>Chinmay Kabi</b></sub></a><br /><a href="https://github.com/Chinmay-KB/wp_pivot_flutter/commits?author=Chinmay-KB" title="Code">💻</a></td>
  </tr>
</table>

<!-- markdownlint-enable -->
<!-- prettier-ignore-end -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
## Starware

<!-- TODO: project name --> is Starware.  
This means you're free to use the project, as long as you star its GitHub repository.  
Your appreciation makes us grow and glow up. ⭐

