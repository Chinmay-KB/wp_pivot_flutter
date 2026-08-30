# Launcher component contract

This contract converts the WP8.1 emulator study into reusable Flutter package
boundaries. It does not add an Android launcher, installed-app discovery, intent
launching, pinned-state persistence, live-data scheduling, Microsoft artwork, or
proprietary fonts to the package.

The reference is the Microsoft Windows Phone 8.1 WVGA emulator at 480 × 800.
All pixel values below are rendered-reference units and scale from a 480-unit
logical width. Selawik remains the distributable fallback for Segoe WP.

## Minimum component set

| Priority | Package primitive | Evidence-backed responsibility | Explicit caller responsibility |
|---|---|---|---|
| P0 | `WpPhoneTheme` | Black/white shell palette, runtime accent, disabled color, reference width and Selawik fallback | App theme selection and persistence |
| P0 | `WpTile` | Caller-supplied content, label, semantics, tap/hold reporting, existing `WpTiltEffect`, controlled edit affordances | App identity, icon assets, pin/unpin/resize policy and persistence |
| P0 | `WpTileGrid` | Explicit four-column placement, 99-unit cell, 210-unit square and 12-unit gutter | Packing, ordering, drag reordering and stored layout |
| P0 | `WpAppListView` / `WpAppListHeader` / `WpAppListRow` | Measured column/slot placement, 74-unit pitch, 62-unit icon/header geometry, 16-unit icon-to-label gap and activation semantics | Installed-app lookup, sorting, filtering and launching |
| P0 | `WpAlphabetGrid` | Controlled four-column 99-unit cells, 12-unit gutters, enabled/disabled state and selection/cancel reporting | Mapping a selected letter to a list position |
| P0/P1 | `WpSplitSurfaceView` | Generic two-surface drag, commit, cancellation and snap-back states | Choosing Start/list content and owning the selected shell surface |
| P1 | `WpStaggeredSceneTransition` | Caller-driven right-edge 3-D item entry/exit with grid-order helper and reduced-motion fallback | Route changes, app launching and exact unqualified native timing |
| P1 | `WpTile` controlled edit presentation | 45/46-unit unpin/resize affordances above later siblings | Mutating or repacking tiles |

`WpBoundaryScrollPhysics` and live-tile content-plane motion remain later slices.
The emulator proves their behavior or phase ordering, but the current evidence
does not recover exact curves, durations, or physical latency. The implemented
staggered scene therefore exposes caller-controlled progress and tunable pose
parameters instead of claiming an exact native clock.

## Evidence and tolerances

- Start rest: small tiles are 99 × 99, square tiles are 210 × 210, and gutters
  are 12 pixels, with ±1 pixel observation uncertainty. The 432-pixel content
  width begins at x=24. Fit/development uses `start_rest_r01` and `r02`; `r03`
  is held out for confirmation.
- Edit pose: the Calendar tile occupies `[24,500,233,709]`; unpin and resize
  affordances are centered at `(250,478)` and `(250,714)` with 45/46-pixel
  diameters and ±2 pixel uncertainty.
- App list: row pitch is 74 pixels, icon/header boxes are 62 × 62, and the
  icon/name gap is 16 pixels. This is geometry evidence; `app_list_rest` is not
  timing-qualified.
- Alphabet grid: four columns use 99 × 99 cells with 12-pixel gutters. Enabled
  cells use the observed accent `#3e65ff`; disabled cells use `#202020`.
  Corrected selection proves behavior and geometry, not timing, because its
  held-out capture contains a 141.19 ms host gap.
- Lateral navigation: Start-to-list drag/flick commits, Start cancellation,
  inverse drag commit, and both cancellation directions are qualified phase
  evidence. Defaults must not assume symmetric flick behavior: recorded inverse
  flick requests snapped back.

Acceptance is reported separately for behavior, resting geometry, motion and
runtime. A deterministic widget replay is not a live Android performance result,
and emulator capture clocks are not physical touch-to-display latency.

## Implementation order

1. Theme, tile and explicit tile grid; compare the 480 × 800 resting fixture.
2. App-list row and alphabet grid; compare their resting geometry and semantics.
3. Generic split-surface interaction; replay delivered commit/cancel inputs.
4. Controlled edit overlay; confirm observed affordance geometry and unchanged
   state after cancellation.
5. Add an evidence-informed, caller-driven staggered scene pose without claiming
   exact timing; defer boundary physics and live-tile content-plane motion.

The canonical measurements and trial classifications remain in
`measurements.json`; this file chooses package boundaries but does not strengthen
their evidence claims.
