# Header and title gesture surface

Nine additional WP8.1 emulator trials (three repetitions each) test slow forward
header drags, backward header drags, and forward title drags. All 596 original
PNG hashes pass. Together with the original release this is 57 native trials and
3,830 PNGs, excluding the separate resting style snapshot.

Every forward header/title drag selects page 1; every backward header drag selects
page 3. The previous Flutter implementation listened only inside the content area.
The gesture detector now surrounds title, headers and content, preserving child
tap recognition and vertical scrolling through Flutter's gesture arena. All 20
widget tests pass, including all 51 core, confirmation and header selection traces.
These nine traces informed this fix: they are development evidence, not held-out
confirmation of the fix.

## Timing qualification

Native acquisition ranges from 13.53 to 25.27 fps in this batch. The slowest trial
has a 260.38ms maximum capture gap. Encoded 30fps playback holds source frames;
it does not supply missing observations.
That slow `header_drag_next_r02` also has 145.68ms receipt spread and fails the
alignment gate. It is excluded from aligned motion comparisons, alongside the
three title trials. The two comparison trials pass the coarse alignment gate.

All three title drags show burst delivery to `Touch.FrameReported`: many changing
coordinates receive nearly identical callback timestamps. Host/guest receipt
spread is 628–670ms, versus roughly 19–23ms in the two header trials used for
comparison. Title input logs therefore support the event order and final selection,
but not the delivered gesture speed or a shared motion timeline. Their preliminary
plots and replays are retained with explicit timing warnings. No title timing fit,
aligned comparison video or motion-error score is claimed.

The analysis tools now reject aligned comparison when receipt spread exceeds
100ms. This is a conservative rejection rule, not an accuracy guarantee for the
accepted samples. Header/body presentation time is still not directly observed.

## Header-swipe comparisons

| Trial | Shared-visible body-position MAE | Motion-only MAE | Visibility mismatches |
| --- | ---: | ---: | ---: |
| `header_drag_next_r01` | 6.26px | 9.52px | 0/42 sampled frames |
| `header_drag_previous_r01` | 5.18px | 8.08px | 0/42 sampled frames |

Both native and Flutter resting bar geometry is x=24, y=165, width=432. These
image-sampling errors include clock uncertainty; interval-compatible zero errors
are not proof of identical motion. The fonts/rasterizers differ. See
`../comparisons/header-01/` for raw tracks, plots, metrics and source hashes.

The supplemental release retains all nine native trials, both actual Flutter
frame captures, clean and pointer-annotated comparisons, and qualified analysis.
The original evidence release is unchanged.
