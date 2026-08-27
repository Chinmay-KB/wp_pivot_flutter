## [Unreleased]

* Add `WpPivotView`: complete Pivot layout, cyclic headers, release-time selection,
  separate content exit/entry, gesture cancellation, keyboard navigation and
  reduced-motion support.
* Add configurable `PivotMotion` and bundled OFL-licensed Selawik fonts.
* Replace the example's PageView synchronization with the full control.
* Add a native WP reference app, timestamped evidence collection, image tracking,
  Flutter input replay, comparison video generation and recorded-input regressions.
* Preserve the existing header-only `WpPivot` and controller API.

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
