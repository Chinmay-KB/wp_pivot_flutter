[![Starware](https://img.shields.io/badge/⭐-Starware-f5a91a?labelColor=black)](https://github.com/zepfietje/starware)


# wp_pivot_flutter
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

A Flutter package inspired from Windows Phone Style Pivot Tabs
![Pivots in action](https://github.com/Chinmay-KB/wp_pivot_flutter/blob/master/showcase/ezgif-4-446097008731.gif)

> **2026 Update:** This project is evolving beyond the Pivot control into a systematic,
> research-driven recreation of the Windows Phone UI in Flutter. The first published
> Pivot study uses the WP8.1 emulator; Lumia 1020 validation remains pending. See
> [docs/ROADMAP.md](docs/ROADMAP.md) for the vision and methodology,
> and the research site at **[chinmaykabi.com/wp_pivot_flutter](https://chinmaykabi.com/wp_pivot_flutter/)**
> for the study, project status, and source material.



## Requirements

Version **2.3.0** requires Flutter **3.22.0+** and Dart **3.4.0+**. See the
[changelog](CHANGELOG.md) for release details and [pub.dev](https://pub.dev/packages/wp_pivot_flutter)
for registry availability. A merged version is not automatically published.
The repository's example app uses Flutter 3.44+ for its current Android
toolchain; the package library itself retains the 3.22 minimum.

## Full Pivot: native layout and motion

`WpPivotView` owns both the headers and page content. It follows measurements from
Microsoft's real Pivot control running on the WP8.1 emulator: cyclic headers,
drag tracking, release-time selection, and separate outgoing/incoming content
animations. See the [evidence study](research/pivot/README.md) for recordings,
methodology and known limits. Emulator evidence is not labeled as Lumia evidence.

```dart
MaterialApp(
  theme: ThemeData(fontFamily: wpPivotFontFamily),
  home: WpPivotView(
    title: 'MY APPLICATION',
    tabTitles: const ['first', 'second', 'third'],
    children: const [
      Center(child: Text('First page')),
      Center(child: Text('Second page')),
      Center(child: Text('Third page')),
    ],
  ),
)
```

An optional `PivotController` drives selection; dispose controllers you create.
`onChanged` reports committed selections. Pages keep their state while hidden.
Arrow keys navigate, headers support keyboard focus and semantic selection, and
the system reduced-animation setting removes the spatial transitions. `wrap:
false` disables cycling at the ends. Give the view a bounded width and height.

Geometry scales from a 480-unit reference viewport. Header and title font families,
weights, colors, and `PivotMotion` parameters can be customized. The package bundles
unmodified **Selawik 1.01** under the [SIL Open Font License](assets/fonts/OFL.txt);
no proprietary Segoe font files are redistributed. Selawik is a fallback, not an
identical copy of Segoe WP. Source and hashes are in [assets/fonts/SOURCE.json](assets/fonts/SOURCE.json).

### Migrating the example

Replace the `WpPivot` app bar plus external `PageView` with one `WpPivotView`, move
the page widgets into `children`, and remove the two-controller synchronization.
The full view reproduces native content phases that a stock `PageView` does not.
The existing `WpPivot` header-only API and `PivotController` remain available.

### Current fidelity limits

The native font and rasterizer differ from Flutter's. Capture timing is too coarse
to establish physical display latency; flick parameters remain provisional beyond
the recorded inputs. The regression suite replays 21 native core, 21 confirmation
and nine header/title input traces, including successful flicks, cancellations,
reversal, wrapping and ignored gestures during transitions. Header and title swipes
share the content gesture surface. A separate release-web runtime probe measures
real engine frame timing, not physical display latency or Lumia performance.
Independent hardware validation and broader gesture sampling remain separate work.

## Launcher UI primitives

The experimental `wp_components.dart` entrypoint now contains the reusable UI
layer needed to compose a Windows Phone-style launcher without putting launcher
policy into this package:

- `WpPhoneTheme`, `WpTile`, and `WpTileGrid` provide the palette, touch tilt,
  controlled edit affordances, and explicit four-column layout.
- `WpAppListView`, `WpAppListHeader`, `WpAppListRow`, and `WpAlphabetGrid`
  reproduce the measured list and jump-grid geometry while leaving app data,
  sorting, and selection destinations with the caller.
- `WpSplitSurfaceView` provides the two-surface commit/cancel drag between Start
  and the app list.
- `WpStaggeredSceneTransition` applies a caller-driven perspective entry/exit
  to one item. The caller supplies scene ordering and transform origin and still
  decides when navigation happens.

```dart
import 'package:wp_pivot_flutter/wp_components.dart';

WpPhoneTheme(
  data: const WpPhoneThemeData.dark(),
  child: WpSplitSurfaceView(
    first: WpTileGrid(placements: tilePlacements),
    second: WpAppListView(children: appListSlots),
  ),
)
```

Run `flutter run -t lib/launcher_components.dart` from `example/` for a complete
composition using placeholder content. The package deliberately does not request
the Android home role, enumerate installed packages, launch intents, persist pins,
order apps, or schedule live data.

At the 480 x 800 evidence viewport, held-out comparisons found zero edge error
for 11 tile surfaces, 10 app-list slots, and 28 alphabet cells. Four held-out
lateral commit/cancel replays in both directions ended on the correct page with
zero final/separation error; presentation-registered tracking p95 ranged from
3.4 to 22.5 px within the 36 px host-capture uncertainty bound. Raw host timing
error is retained separately because emulator timestamps do not identify guest
presentation. The staggered scene pose is evidence-informed and visually
inspected, but exact native timing and transformed polygons are not claimed.
See [the component contract](research/start-screen/COMPONENT-CONTRACT.md) and
[runtime report](research/start-screen/runtime-01/README.md).

## Legacy header-only example

Selection state is managed by a `PivotController` - pass your own to drive the
pivot from the outside, or let the widget create one internally.

```dart
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';

final PivotController pivotController = PivotController(length: 4);
final PageController pageController = PageController();

@override
void initState() {
  super.initState();
  // Keep the PageView in sync with the pivot.
  pivotController.addListener(() {
    pageController.animateToPage(
      pivotController.index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastLinearToSlowEaseIn,
    );
  });
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    appBar: WpPivot(
      controller: pivotController,
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
    body: PageView(
      controller: pageController,
      onPageChanged: (index) => pivotController.animateTo(index),
      children: const [ /* pages */ ],
    ),
  );
}
```

## Experimental component gallery

Application Bar, Panorama, ToggleSwitch, Slider, ProgressBar, TiltEffect, and the launcher UI primitives are available through the separate
`package:wp_pivot_flutter/wp_components.dart` import. From `example/`, run
`flutter run -d chrome -t lib/components.dart` to try them together.
They are experimental. The three micro controls have repeated WP8.1 emulator
measurements and held-out comparisons; the earlier component batch remains pilot
evidence. See the [component studies](research/components/README.md) for evidence,
known differences, and the reusable capture/replay workflow. Emulator results do
not establish Lumia hardware fidelity. The existing Pivot API is unchanged.

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

wp_pivot_flutter is Starware.  
This means you're free to use the project, as long as you star its GitHub repository.  
Your appreciation makes us grow and glow up. ⭐
