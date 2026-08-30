## [2.3.0] 30 August 2026.

* Add opt-in reusable Start tiles, explicit tile grid, app-list rows and surface,
  alphabet jump grid, two-surface lateral navigation, and staggered 3-D scene
  transition through `wp_components.dart`.
* Keep Android home-role integration, installed-app discovery, intents, ordering,
  persistence, and live-data scheduling outside the package API.
* Add keyboard/semantic behavior, controlled tile edit callbacks, proportional
  WVGA geometry, and reduced-motion handling.
* Add a runnable launcher-component composition example and deterministic native
  emulator comparison tooling. Held-out static geometry has zero measured edge
  error; four held-out lateral commit/cancel directions pass the capture-bounded
  trajectory and exact outcome/separation gates.

## [2.2.0] 29 August 2026.

* Add opt-in experimental Application Bar, Panorama, ToggleSwitch, Slider,
  ProgressBar and TiltEffect components through `wp_components.dart`, with a
  separate interactive example gallery.
* Add source-backed Windows Phone geometry and native WP8.1 emulator fixtures.
  Slider, ProgressBar and TiltEffect include repeated measurement, held-out
  input replay and an independently recaptured post-freeze Tilt confirmation.
* Add keyboard and accessibility behavior, controlled state, and reduced-motion
  fallbacks for the new micro controls.
* Publish the micro-control measurements, media, integrity limits and reusable
  analysis/replay tools on the research site.
* Preserve the existing Pivot entrypoint and APIs.
* Refresh the example Android toolchain to AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0
  and Java 17 so the gallery builds on current Flutter stable.

## [2.1.0] 28 August 2026.

* Add `WpPivotView`: complete Pivot layout, cyclic headers, release-time selection,
  separate content exit/entry, gesture cancellation, keyboard navigation and
  reduced-motion support.
* Add configurable `PivotMotion` and bundled OFL-licensed Selawik fonts.
* Support swipes across the title, headers and content, with 51 recorded native
  selection traces covered by regression tests.
* Replace the example's PageView synchronization with the full control.
* Add a native WP reference app, timestamped evidence collection, image tracking,
  Flutter input replay, comparison video generation and recorded-input regressions.
* Add an opt-in release-web runtime probe and timing-alignment validation for
  comparisons. Measurements use the WP8.1 emulator; Lumia hardware validation
  remains pending, and Selawik is not identical to Segoe WP.
* Preserve the existing header-only `WpPivot` and controller API.
* Declare Flutter 3.22 / Dart 3.4 as the minimum supported SDKs for the new APIs.
* Refresh package documentation and exclude repository research, media and capture
  tooling from the package archive while retaining the library, fonts and example.

## [2.0.0] 21 August 2026.

* **BREAKING**: Replaced the GlobalKey-based API with a `PivotController`
* `WpPivot` now accepts an optional `controller`; selection can be driven and observed externally
* Migrated to Dart 3, current Flutter stable APIs and lint set
* Fixed app bar height mismatch that caused a silent RenderFlex overflow

## [1.0.0]

* Null-safe release

## [0.0.2] 22 August 2020.

* Minor tweaks to adhere to dart conventions

## [0.0.1] 22 August 2020.

* A flutter package implementing Windows Phone style pivot tab bar
