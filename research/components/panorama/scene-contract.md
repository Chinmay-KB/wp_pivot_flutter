# Panorama native scene contract

## Source

- Control: `Microsoft.Phone.Controls.Panorama` on the Windows Phone 8.0 Silverlight target.
- Viewport: portrait 480 by 800 logical pixels.
- Title: `panorama`; headers: `first`, `second`, `third`.
- Each item supplies a distinct Metro color bar and 64 pixel marker. The wide generated background is a geometric fiducial through the stock Panorama `Background` layer.
- The scene leaves Panorama's template and motion untouched. It records render-state positions and selected index passively, and writes `state.csv` and touch `inputs.csv` when the application closes or deactivates.

## Capture plan

`tools/native_panorama/scenarios.json` contains a clear next swipe and a deliberately too-small drag. It uses 0.5 second pre-roll and 0.8 second post-roll.

## Adaptive layout policy (batch-02)

- **Title:** horizontal crop is intentional; the main title may extend past the
  viewport edge. Vertical overlap with item headers matches native Panorama.
- **Item band:** `itemTop` follows native `y=191` at 480×800, scaled by height
  and clamped on short viewports so the child canvas keeps at least ~64 logical
  px of usable height.
- **Horizontal pitch:** `itemLeft`, `peek`, and `panelGap` scale from the native
  24 / 24 / 36 values at 480 px width. Panel width is the remaining space.
- **Header gap:** spacing between item header and child follows the native
  `(317 − 191 − 87.79)` proportion rather than a fixed 24 px spacer.
- **Text scale:** item header and main title sizes respect `MediaQuery.textScalerOf`.

All geometry remains provisional until replay confirmation; Selawik ≠ Segoe WP.

## Evidence limits

The control is real native Panorama. The pilot observed a resting item leading edge of about x=24, item pitch of about 432, visible next-item sliver of about 24, content-bar width about 396, header top y=191, and color-bar top y=317 at 480 by 800. Its exported title style is Segoe WP Light 170 with an observed 687.55 by 226.11 layout box; headers are Segoe WP SemiLight 66 with observed heights of 87.79. The candidate uses those nominal 480-wide sizes with Selawik, so font metrics and rasterization remain a documented mismatch. Native title/background retain horizontal displacement after selection; the candidate accumulates travel in content units, then applies a bounded experimental layer offset so cyclic navigation never leaves a blank title or generic background. All geometry and parallax values remain provisional: `state.csv` is layout telemetry, not proof of presented pixels or a calibrated clock. The entry animation and unqualified clock make it unsuitable for a gesture-curve fit. The geometric background is a measurement aid only and does not establish Flutter parallax factors.

## Official reference

Microsoft documents [Panorama](https://learn.microsoft.com/en-us/previous-versions/windows/apps/ff941269(v=vs.105)) as an `ItemsControl` with background, items, and title panning layers, and [PanoramaItem](https://learn.microsoft.com/en-us/previous-versions/windows/apps/ff941284(v=vs.105)) as its item content control.
