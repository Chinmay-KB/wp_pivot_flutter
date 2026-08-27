# Native Pivot evidence: first collection

This is an ongoing study, not a completed fidelity claim. The retained baseline
uses the existing 2.0.0 widget and example controller wiring. The revised
`WpPivotView` owns the header and content motion; both versions are compared with
actual native recordings rather than with an illustrated reference.

## Current implementation and confirmation

**Supplement:** [header/title gestures](header-01/README.md) add nine trials and
596 PNGs, bringing the retained native total to **57 trials / 3,830 PNGs**. The
gesture surface now includes title and headers. All **51 selection traces** and
**20 widget tests** pass. Title callback timing is unqualified and excluded from
aligned motion comparisons. A separate [release-web runtime study](runtime-01/README.md)
reports actual engine timings, with a 6.10ms p95 total span over 678 measured frames.
The original collection and its historical results below remain unchanged.

The original release contains 48 native motion trials: 27 initial plus 21 fresh confirmation
trials, with 3,234 original PNGs in total. All native frame hashes pass verification.
The resting native style snapshot is a separate artifact.

The full view uses native reference geometry, cyclic header rearrangement,
drag-linked header/body travel and separate content exit/entry phases. Its bundled
Selawik fonts are OFL-licensed substitutes, not identical Segoe WP fonts.

The 21 fresh trials add selected-header taps, reverse committed/cancelled drags,
successful next/previous flicks, same-contact reversal and forward wrapping. The
candidate matches all 21 selection sequences without changing its motion in
response to those outcomes; the 21 earlier core input traces also pass. See
[candidate provenance and evaluation](confirmation-01/evaluation.json). The first
event-only widget replay had an idle-gap ticker-start bug; the corrected replay
pumps a frame after each input and passes all 19 widget tests. Image captures use
the separate regular-frame replay harness.

Pilot image comparisons under `comparisons/` report positions and visible-page
mismatches separately. The revised resting page bar matches native x/y/width
24/165/432, versus the baseline's 16/134/448. Moving-page position MAE decreases
from 313.0 to 32.2 px for the header tap, 158.6 to 4.7 px for the committed drag,
and 305.3 to 16.1 px for previous wrapping in the `improved-02` pilot comparison.
These are image-sampling comparisons with timing uncertainty, not a single
fidelity percentage or proof of native display latency.

## Sources and provenance

- Native reference: Microsoft's `Microsoft.Phone.Controls.Pivot`, Silverlight
  WP8.0 application on WP8.1 emulator build `8.10.12358.0`, portrait 480x800.
- Flutter baseline: actual widget-tree rasterization in the Flutter test engine,
  replaying guest-recorded pointer events on a deterministic clock. This is not
  a desktop performance measurement. Local Segoe UI fonts are used and are not
  redistributed; they are not identical to Segoe WP.
- `native-pilot-01`: three initial trials, one each for header-next, drag-commit,
  and wrap-previous.
- `native-core-01`: seven requested scenarios with three repetitions each.
- `native-control-01`: three header-next trials with per-frame trajectory logging
  disabled. Low-overhead input logging remains enabled, so this is specifically
  a trajectory-instrumentation control, not a completely uninstrumented build.

Original images, guest logs and host timing are retained in the ignored local
`artifacts/` directory and in the [public evidence release](https://github.com/Chinmay-KB/wp_pivot_flutter/releases/tag/pivot-evidence-2026-08-27).
The [published study](https://chinmaykabi.com/wp_pivot_flutter/research/pivot/) includes
playable comparisons and interpretation. Core/control manifests record source hashes, package hash
expectations, and clock semantics. Pilot provenance is less complete and remains
labeled as pilot evidence.

## What the first recordings show

| Requested scenario | Observed native outcome across three core trials |
| --- | --- |
| Adjacent header tap | Selected page 1 in all three |
| Skip to visible third header | Selected page 2 in all three |
| Short slow drag | Stayed on page 0 in all three |
| Long slow drag | Selected page 1 in all three |
| 120 ms next flick request | Stayed on page 0 in all three; delivered contacts lasted about 202–332 ms |
| Previous/wrap gesture | Selected page 3 in all three |
| Reverse after release | First gesture selected page 1 in two trials and stayed on page 0 in one; second gesture did not change selection |

Scenario names describe the requested input, not a successful behavior. In
particular, these flick and interruption trials are not qualified examples of
successful flicking or reversal. The SDK delivery latency and endpoint pause must
be addressed before measuring flick thresholds.

The tap footage shows separate header and body motion. The outgoing content can
clear before incoming content appears; the unchanged Flutter `PageView` reveals
the next page continuously. During a drag, the existing Flutter header also changes
its selection/position differently from the native header. The comparison frames
show substantial typography and spacing differences before motion is considered.

## Measurement qualification

See each trial's `quality.json`, `image_tracks.csv`, `replay.json`, and trajectory
plot under [pilot-01](pilot-01/), [core-01](core-01/), and [control-01](control-01/).

Original PNG hashes are checked against the capture manifests. Native timing is
reported as host acquisition intervals, with an approximate guest-clock offset
estimated from corresponding input events. SDK receipts are not actual physical
touch timestamps. Alignment uncertainty includes receipt variation, but is not a
proven bound on guest presentation latency.

Header tracking uses normalized image correlation, checked independently against
the guest logs. The image matcher rejects flat patches and incomplete matches.
Both overall and motion-only compatibility errors are recorded so long resting
periods cannot hide motion errors.

Body `TransformToVisual` logs give the same coordinate for multiple pages and can
disagree with visible motion. They are **not qualified for body trajectory fitting**.
Instead, the analysis tracks each page's unique colored square and horizontal bar
in the PNGs. A clipped bar's missing edge is inferred only from its known 432 px
width in this fixed, unscaled scene. Solid-pixel edges have about one pixel of
antialiasing uncertainty. Missing observations remain missing.

Video delivery is 30 fps with held source frames. This does not turn the roughly
19–27 fps native acquisition into a 30 fps measurement. The Flutter replay samples
at 60 Hz on a synthetic clock; that likewise does not establish interactive fps.

The trajectory-on/off header controls each contain only four moving image samples
per trial. Their first settled image midpoints occur 285–323 ms and 291–343 ms
after guest release, respectively. This is coarse acquisition timing, not animation
duration. The ranges overlap, and the sampling does not establish a precise
instrumentation penalty or prove there is none. The present qualification is
**layout and coarse image motion**, with adjacent-header telemetry usable as a
candidate model subject to its image checks. Fine display latency and flick
physics remain unqualified.

## Exploratory header model

[The fit and held-out results](core-01/header-fits.json) use runs 1–2 for fitting and
run 3 for checking, with time relative to the guest selection callback.

- Adjacent-header fit: about 258 ms and power exponent 1.13. The held-out guest
  coordinates have 0.83 px RMSE and 2.88 px maximum error. The first settled samples
  occur about 273–279 ms after selection. These are different measurements, not
  interchangeable definitions of duration.
- The same single-phase model is **rejected for a skipped header**: held-out error
  reaches about 114 px. The trace jumps from x=402 to about x=261 at the beginning,
  then moves toward x=21. Header rearrangement must be modeled before curve fitting.

These are exploratory fits, not extracted native animation constants or proof of
physical-device timing. Instrumentation-control results and image tracking must
accompany them before implementation decisions are finalized.

## Reproduction

The native SDK/Glance checkout are Windows-specific prerequisites. Build and deploy
`tools/native_pivot/PivotReference.csproj`, then run `record_native.py` with the
Glance app directory and a fresh output path. `build.ps1 -NoTrajectory` creates the
trajectory-off variant. Never mix that variant's label with a trajectory-on build.

Analysis dependencies: NumPy, Pillow, SciPy, Matplotlib, and imageio-ffmpeg. Commands
below run from the repository root with those dependencies available:

```text
python tools/capture/analyze_native.py artifacts/native-core-01 --output research/pivot/core-01
python tools/capture/fit_headers.py artifacts/native-core-01 --output research/pivot/core-01
python -m unittest discover -s tools/capture -p "test_*.py"
python tools/capture/record_flutter.py research/pivot/pilot-01 --output artifacts/flutter-baseline-01 --flutter D:/sdk/flutter/bin/flutter.bat
python tools/capture/make_comparison.py --native artifacts/native-pilot-01/drag_commit_r01 --analysis research/pivot/pilot-01/drag_commit_r01 --flutter artifacts/flutter-baseline-01/drag_commit_r01 --output artifacts/comparisons-pilot/drag_commit
```

Flutter images are captured using [RenderRepaintBoundary.toImage](https://api.flutter.dev/flutter/rendering/RenderRepaintBoundary/toImage.html).
The replay supplies measured timestamps to gesture events; see
[TestGesture.moveTo](https://api.flutter.dev/flutter/flutter_test/TestGesture/moveTo.html).

## Remaining work toward the goal

The raw assets and study are published; ten final comparison scenarios were
inspected and all 40 video variants decoded. Public page/media responses and
release hashes are recorded in `publication.json`. The implementation PR retains
the native-versus-Flutter comparisons. Hardware cross-checks remain separate: a USB projection status query
on this host returned no devices during the confirmation session. Broader input
threshold sampling, instrumentation influence and interactive runtime smoothness
remain explicit limits rather than conclusions of the deterministic replay.
