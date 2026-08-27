---
layout: default
title: Pivot motion study
---

# Pivot, recorded and compared

The original Flutter widget looked like a Pivot, but its page motion behaved like
a `PageView`. This study records Microsoft's actual Pivot control and uses those
observations to build a closer implementation. It is an ongoing fidelity study,
not a claim that the two renderers are indistinguishable.

**Reference:** a Silverlight WP8.0 app using `Microsoft.Phone.Controls.Pivot` on the
WP8.1 emulator, OS build 8.10.12358.0, at 480 × 800. These are emulator recordings,
not Lumia recordings. Hardware confirmation remains separate work.

## Watch the comparison

Native is on the left; the revised Flutter implementation is on the right. Both
panels use the same recorded input timeline. Flutter frames come from the actual
widget tree in the test engine, not an illustration or a redrawn native video.
They do not measure interactive runtime performance.

### Tap the next header

<video controls playsinline preload="metadata" width="960" height="856"
  style="width:100%;height:auto;background:#000"
  poster="{{ '/media/pivot/header_next.png' | relative_url }}">
  <source src="{{ '/media/pivot/header_next.mp4' | relative_url }}" type="video/mp4">
  Your browser cannot play this video. Use the download below.
</video>

[Download the header comparison]({{ '/media/pivot/header_next.mp4' | relative_url }})

### Drag and commit

<video controls playsinline preload="metadata" width="960" height="856"
  style="width:100%;height:auto;background:#000"
  poster="{{ '/media/pivot/drag_commit.png' | relative_url }}">
  <source src="{{ '/media/pivot/drag_commit.mp4' | relative_url }}" type="video/mp4">
  Your browser cannot play this video. Use the download below.
</video>

[Download the drag comparison]({{ '/media/pivot/drag_commit.mp4' | relative_url }})

### Wrap to the previous page

<video controls playsinline preload="metadata" width="960" height="856"
  style="width:100%;height:auto;background:#000"
  poster="{{ '/media/pivot/wrap_previous.png' | relative_url }}">
  <source src="{{ '/media/pivot/wrap_previous.mp4' | relative_url }}" type="video/mp4">
  Your browser cannot play this video. Use the download below.
</video>

[Download the wrap comparison]({{ '/media/pivot/wrap_previous.mp4' | relative_url }})

The videos are encoded at 30 fps. Native acquisition is slower and irregular;
missing time is represented by holding the last captured frame. We do not create
interpolated frames or stretch each animation to make it agree. Separate copies
with input pointers are included in the evidence release; raw images stay clean.

## What changed, and why

| Observation | Flutter change |
| --- | --- |
| Native headers have different size, spacing and cyclic order from the original example. | A full `WpPivotView` lays out headers from measured text widths and native reference coordinates. |
| Dragging moves the current page without continuously exposing its neighbor. | Header and body travel are controlled separately; a stock `PageView` no longer defines the transition. |
| Selection commits on release; outgoing and incoming content have distinct phases. | A coordinated transition moves the old page out before bringing the selected page in. |
| A skipped header rearranges before sliding into place. | The selected header becomes the anchor before a one-slot transition. |
| The threshold-crossing input sample is consumed before visible body travel; header travel starts later. | Gesture tracking reproduces the delivered-sample sequence seen in the native logs and images. |

The original `WpPivot` header-only API remains available. The full view is an
explicit migration: it replaces the app-bar-plus-`PageView` arrangement, preserves
page state, and supports controller selection, keyboard navigation and reduced
motion. It uses the OFL-licensed Selawik fallback; proprietary Segoe WP files are
not distributed. Font and rasterization differences remain visible.

## Measured improvement, with limits

The following results compare the retained 2.0 baseline with the `improved-02`
candidate on three pilot inputs. They are development comparisons, not independent
confirmation data. Errors are measured in the 480 × 800 reference image.

| Pilot | Moving-page position MAE, baseline → revised | Frames with different visible pages, baseline → revised |
| --- | --- | --- |
| Header tap | 313.0 → 32.2 px | 22 → 0 of 28 |
| Committed drag | 158.6 → 4.7 px | 23 → 1 of 46 |
| Previous wrap | 305.3 → 16.1 px | 27 → 0 of 36 |

Position error includes only pages visible in both sources. The separate visibility
column prevents an absent or incorrect page from being counted as a perfect match.
Motion-only measurements exclude resting observations; all sample counts, full
metrics and frame mappings are available in the analysis archive. The page bar's
resting x/y/width changed from 16/134/448 to the native 24/165/432 pixels.

At each native acquisition midpoint, we compare the latest preceding Flutter
image. That preserves latency differences, but uncertainty in native timing can
produce large position errors during fast motion. An interval sensitivity check
is also provided. A zero interval-compatible error does **not** prove zero display
latency or perfect motion.

![Header transition: native observed positions and Flutter replay positions]({{ '/media/pivot/header-motion.png' | relative_url }})

### What we can and cannot infer

- **Layout and coarse motion:** supported by original PNGs and image tracking.
- **Adjacent header model:** fitting two core runs and checking a third suggests
  about 258 ms with power exponent 1.13. The held-out guest-coordinate RMSE is
  0.83 px, with a 2.88 px maximum. These are fitted observations, not extracted OS constants.
- **Skipped headers:** a single uninterrupted curve is rejected; it misses the
  initial rearrangement by roughly 114 px in the held-out run.
- **Body telemetry:** native element-coordinate logs can disagree with the
  rendered page. We retain those logs but use image markers for body motion.
- **Precise timing:** capture intervals, SDK delivery delay and instrumentation
  limit the conclusions. A render callback is not a display-presentation timestamp.
- **Flick thresholds:** successful examples are now recorded, but a few examples
  do not establish a universal velocity threshold or a hardware physics model.

## Fresh confirmation recordings

After freezing the candidate, we collected 21 additional trials: three repetitions
each of selected-header taps, reverse committed drags, reverse cancelled drags,
flicks in both directions, reversal within one contact, and forward wrapping.

The new input path sends its last vertex as release rather than adding a separate
stationary endpoint move. Actual native contacts for the flick cases lasted about
116–152 ms. All six selected the expected next/previous page. Earlier nominal
120 ms flick requests lasted roughly 202–332 ms and did not commit; those failed
attempts remain in the archive. Scenario names describe requests, not proof of an outcome.

The candidate matches all 21 fresh selection sequences, and all 21 earlier core
sequences. The full widget suite passes 19 tests. An initial replay-harness bug
delayed animation startup across idle gaps; correcting the test clock resolved
six false failures without changing the implementation's motion. The confirmation
archive includes source hashes, input traces, quality reports and that evaluation
history. Selection agreement does not establish identical motion or frame rate.

## Download every observation

### Header and title gestures: nine more native trials

The next collection found a missing interaction surface: native Pivot accepts
horizontal drags on its headers **and its title**, while our implementation had
listened only inside the content. The detector now surrounds all three regions.
All nine recorded selection sequences pass, alongside the 42 original traces;
the widget suite now has 20 passing tests. These new cases informed the fix and
are not held-out confirmation of it.

This adds 596 original PNGs, for **57 native trials / 3,830 PNGs** across releases.
Native acquisition in this batch ranges from 13.53 to 25.27fps, with a maximum
gap of 260ms in the slowest run. Three title-drag trials have buffered touch
callbacks with 628–670ms receipt spread. They are retained for layout and selection
evidence, but excluded from timing fits and aligned motion comparisons.
The slowest header trial also fails the alignment gate with 145.68ms receipt
spread. All four rejected trials remain available; neither chosen comparison
trial is among them.

<video controls playsinline preload="metadata" width="960" height="856"
  style="width:100%;height:auto;background:#000"
  poster="{{ '/media/pivot/header_drag_next.png' | relative_url }}">
  <source src="{{ '/media/pivot/header_drag_next.mp4' | relative_url }}" type="video/mp4">
  Your browser cannot play this video. Use the download below.
</video>

[Download the forward header-swipe comparison]({{ '/media/pivot/header_drag_next.mp4' | relative_url }})
· [Backward header swipe]({{ '/media/pivot/header_drag_previous.mp4' | relative_url }})

The sampled shared-visible body-position MAE is **6.26px forward / 5.18px backward**,
with no visibility mismatches in either trial's 42 sampled frames. Motion-only
MAE is 9.52px / 8.08px. These errors include capture/clock uncertainty; font and
rasterizer differences remain. No title-drag timing score is claimed.

## Runtime smoothness

We also ran the actual Flutter scene in a **release web build**, using real elapsed
time to replay native input paths. Four scenarios each received one warm-up and
three measured repetitions. All 12 measured trials selected the expected page.
This was Chromium 151 on Windows, a 360×600 logical viewport at DPR 1, with the
document reporting visible throughout.

| Engine measurement | Median | 95th percentile | Maximum |
| --- | ---: | ---: | ---: |
| Build work | 3.00ms | 5.20ms | 11.60ms |
| Raster work/submission | 0.40ms | 0.80ms | 24.00ms |
| Total frame span | 3.70ms | 6.10ms | 28.70ms |
| Post-selection frame interval | 16.60ms | 17.30ms | 29.30ms |

There were 678 measured engine frames; one total span exceeded the chosen 16.667ms
budget. Input scheduling lateness was 9.27ms at p95 and 15.23ms maximum. Small frame
interval variations around 16.667ms are not automatically dropped frames. Cadence
includes all gaps inside the continuous post-selection animation windows.

![Measured release-web frame work, including the outlier]({{ '/media/pivot/runtime-frame-cost.png' | relative_url }})

These results support smooth animation on this host. They do **not** measure
physical display presentation, the native browser touch path, native Windows
Flutter, mobile performance, or the Lumia. Deterministic 60Hz test replays remain
a different kind of evidence. The raw run includes every engine timing, actual
input timestamp, selection and visibility event.

### Supplemental download

[Header gestures and runtime evidence release]({{ site.github_repo }}/releases/tag/pivot-evidence-2026-08-27-header-runtime)
contains all nine new native trials, two Flutter frame captures, clean/pointer
comparison videos, quality reports, the raw runtime run, exact compiled probe and
build sources, and updated reproduction tools. Each ZIP has a SHA-256 inventory.
The four timing-unqualified trials remain included and labeled.

### Original release

[Open the versioned evidence release]({{ site.github_repo }}/releases/tag/pivot-evidence-2026-08-27)

| Archive | Contents |
| --- | --- |
| `pivot-native.zip` | Every retained native collection: original PNGs, capture intervals, guest logs, manifests, style snapshot and control/confirmation runs. |
| `pivot-flutter.zip` | Unchanged baseline, prototype and revised widget-tree captures, their input replays and source hashes. |
| `pivot-comparisons.zip` | Clean and pointer-annotated videos, with mappings back to original frames. |
| `pivot-analysis.zip` | Tracks, plots, fitted models, quality reports, comparison metrics and the collection protocol. |
| `pivot-source.zip` | The actual Flutter/reference/capture sources and the Glance SDK bridge used for timed input. |

Each archive carries a member inventory with SHA-256 hashes. The release manifest
also gives archive hashes. Unsuccessful trials and superseded prototypes are kept
with their original labels. No installed Windows font files are included.

## Reproduce and extend

The source archive and repository contain the native reference app, scenario
plans, recorder, analysis scripts, Flutter replay harness and comparison encoder.
The native side requires Windows with the WP8.1 SDK and configured emulator;
ordinary Flutter widget tests do not require it.

1. Build and deploy the reference app without replacing the native Pivot template.
2. Record a new session, preserving actual input samples and capture intervals.
3. Check image integrity and tracking quality before fitting a model.
4. Replay those inputs in Flutter and compare visible-page sets as well as positions.
5. Keep fresh confirmation runs separate from inputs used to tune an implementation.

See the [protocol and reproduction commands]({{ site.github_repo }}/tree/pivot-evidence-2026-08-27/research/pivot).
The next fidelity checks are wider gesture sampling, mobile runtime performance,
and a separately labeled Lumia cross-check. Emulator data is useful evidence;
it is not a substitute for those measurements.
