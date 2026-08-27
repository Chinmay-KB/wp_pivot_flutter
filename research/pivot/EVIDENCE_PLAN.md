# Pivot evidence collection plan

Status: proposed protocol, reviewed against the local evidence on 2026-08-27.
This step is planning only; it does not approve existing data as ground truth or
change the Flutter implementation.
Sol Advisor route remains solo: the primary agent owns planning and verification.

## Objective and first boundary

Create a reusable, traceable reference for the Windows Phone Pivot's appearance
and interaction. Use it to measure the current Flutter package, guide changes,
and later detect visual and motion regressions. Publish the evidence on the
research website and include native-versus-Flutter comparison media in the final PR.

Start with Pivot in portrait, dark theme, one fixed accent, four pages, and matching
content. Panorama, page navigation, other controls, broad theme coverage, and
orientation changes follow once this protocol works.

Use the actual Microsoft Pivot control without replacing its template or motion.
The initial reference is a Silverlight WP8.0 app on the WP8.1 emulator at 480x800.
That is a specific platform configuration, not a claim about every Windows Phone
version. The Lumia 1020 is a separate hardware validation source, not an
interchangeable label for emulator footage.

## What exists, and what is not yet established

- Reference scene: `tools/native_pivot/`, with four differently colored pages and
  passive input/element-position logging.
- Capture runner and initial seven scenarios: `tools/capture/record_native.py`
  and `tools/capture/pivot_scenarios.json`.
- Local native collections already contain 27 motion trials: three pilots,
  21 core trials, and three trajectory-logging controls. A separate resting style
  snapshot also exists. Preserve and index these before recording replacements.
- Existing analysis qualifies the images for layout and coarse motion. Native
  capture is roughly 19-27 acquired fps, with some larger gaps. Encoded playback
  fps must not be presented as native rendering fps.
- Header telemetry has image cross-checks; body coordinate logs disagree with
  visible motion and are not qualified for trajectory fitting. Instrumentation
  overhead and fine display timing remain unresolved. See `README.md` for the
  existing results and limitations; this planning review did not rerun analysis.
- The retained Flutter baseline uses the original header's 600 ms
  `fastLinearToSlowEaseIn` transition. Local implementation experiments and
  improved replay artifacts also exist; preserve their provenance and keep them
  separate from the unchanged baseline. Their existence is not a fidelity verdict.
- Nominal flick requests were not delivered reliably as intended. Successful
  flicks, both-direction coverage, and reversal within the same contact still need
  fresh evidence. Reserve confirmation runs that have not been used to tune code.
- Evidence publication and hardware confirmation remain pending. Local file paths
  are not accessible publication links for mobile readers.

## 1. Qualify the measurement system before collecting at scale

First validate one header tap and one slow drag, using the existing pilots where
possible. Check the settled initial state, intended target, final selection, frame
integrity, and complete input-down/move/up sequence.

Compare visible marker/header motion in the PNGs with guest position logs. Confirm
that the logs reflect rendered motion rather than only layout coordinates. Compare
instrumented and uninstrumented runs for observable changes in motion or timing.
Record capture cadence both with and without competing preview consumers.

Keep three clocks distinct: host capture intervals, host SDK input receipts, and
guest input/render callbacks. Establish and document their alignment using matched
events and visual transitions; estimate offset/drift uncertainty rather than
assuming a common clock. Rendering callbacks are not proof of display presentation.

Report capture-interval distribution, longest gaps during motion, frame changes,
missing events, and tracking confidence. Unchanged images during rest are expected;
neither duplicate images nor a video's encoded fps establishes native refresh rate.

**Gate:** qualify each source for layout, coarse motion, and/or detailed timing.
If video sampling or telemetry cannot support fine curve estimates, improve the
capture path or report bounded coarse measurements. Do not invent missing frames,
use interpolation as observed evidence, or label an encoded 60 fps clip a 60 fps
capture. Keep failed attempts with explicit status and reasons.

## 2. Collect a small, repeatable scenario matrix

Reset to a verified initial page before each run. Keep viewport, theme, content,
font settings, app build, and target fixed. Record a settled lead-in, the whole
gesture, and enough tail to verify the final settled state. Save actual delivered
input samples in addition to requested actions; a requested duration is not a
measurement of the delivered gesture.

| Family | Variants | Questions answered |
| --- | --- | --- |
| Resting layout | Each selected page; short and long headers later | Header spacing, clipping, alignment, colors, text metrics |
| Header taps | Adjacent, visible non-adjacent, already selected | Target behavior, timing, selection changes, header/body relationship |
| Slow drags | Both directions; small displacement and larger displacement | Continuous tracking, cancellation versus commit, release settling |
| Flicks | Both directions; several measured speeds/distances | Velocity dependence, travel, wrap behavior |
| Interruption | Reverse while still touching; new gesture during settling | Continuity, interruption rules, selection timing |
| Boundaries | First-to-last and last-to-first | Wrapping and header rearrangement |

Begin with three valid repetitions per core scenario. Then concentrate additional
runs around disagreements, cancellation/commit boundaries, and suspected velocity
thresholds. Three repetitions establish an initial repeatability check, not a
precise threshold or confidence interval. Keep exploratory and confirmation runs
separate; reserve fresh runs to test any fitted model.

The current seven scripted scenarios are a starting subset. They do not yet cover
all directions or reversal while the same contact remains down. Add missing cases
only after capture qualification; do not describe intended outcomes as observations.

## 3. Preserve an evidence bundle for every trial

Each stable session/scenario/repetition ID should resolve to:

- Original lossless frames, frame hashes, and capture timing intervals.
- Requested gesture, delivered input log, and guest telemetry when available.
- Manifest: source type, device/VM, OS and control version, viewport and scale,
  orientation, theme/accent, font settings, app/tool commit IDs and build hashes,
  capture backend, instrumentation settings, clock semantics, and quality status.
- Derived clean playback clip and a separate annotated clip with tap/drag pointers.
  Pointer overlays never alter the raw images used for measurement.
- Extracted positions, analysis settings/script versions, results, and limitations.

Use simple app-owned content without personal data. Record font identity/metrics
without redistributing proprietary font files. Raw large assets belong in a
versioned GitHub Release; small manifests, scripts, measurements, and findings
belong in git. Published manifests must link to downloadable assets with hashes,
not just local paths.

## 4. Turn observations into a specification

Measure header and page-body trajectories separately, relative to input-down and
release. Separate finger-following motion from post-release settling. Measure
selection timing, displacement relationships, duration, settling, any overshoot,
clipping, and opacity changes where the capture supports them.

For layout, record positions, text bounds/baselines, spacing, and color samples in
both native units and normalized viewport coordinates. Document physical-to-logical
pixel mapping; do not compare the same numeric font size across different scales.

Fit curves or velocity-dependent models only after inspecting the observations.
Do not force all interactions into a single cubic Bezier. Publish raw samples,
fits, residuals, repeat variation, and uncertainty; assess the fit on reserved runs.
Every proposed Flutter change should link to a specific observation and trial.

## 5. Establish Flutter baseline and comparison rules

Capture the unchanged package before tuning it. Match content, viewport, scale,
initial selection, and actual input path/timing as closely as the input systems
allow. Disclose differences in font availability and renderer. A deterministic
Flutter test replay is useful for regression, but must be labeled separately from
an interactive runtime capture or performance measurement.

Compare native, baseline Flutter, and later improved Flutter using:

- Shared-timeline side-by-side video at real speed, plus clearly labeled slow motion.
- Aligned stills/overlays and position-versus-time plots for header and content.
- Per-scenario spatial error, timing error, and behavior/selection mismatches.

Align to input events, retain response latency, and do not independently retime
clips to make them agree. Choose numeric acceptance tolerances after calibration
and before tuning; publish them with the measurement uncertainty. Keep behavior,
layout, motion, and runtime smoothness distinct rather than claiming one overall
"fidelity percentage." Baseline and improved output must use the same protocol.

## 6. Cross-check on hardware and publish

Record a representative subset on the Lumia 1020 after confirming deployment and
capture access. Hardware input may require manual gestures; preserve that limitation
and do not claim an exactly replayed trajectory unless it was measured. If deployment
is unavailable, stock-app footage is supplementary context, not a matched reference.
Keep emulator-only findings explicitly provisional for hardware fidelity.

Publish a Pivot study page, session index, playable clips with posters and downloads,
measurement tables, plots, raw-data links, and reproduction instructions. Correct
existing site language that implies every capture comes from the Lumia before adding
emulator sessions. Check public playback on desktop and mobile web; separately verify
the user's Codex mobile viewing path when available rather than assuming PC paths
or desktop playback work there.

## Order of deliverables

1. Calibration report: what the capture system can and cannot measure reliably.
2. First reference bundle: one header transition and one drag, with raw evidence,
   annotations, trajectory cross-checks, and matching unchanged Flutter output.
3. Repeated core matrix, measurement report, and evidence-backed change list.
4. Published reference pages/data, improved Flutter implementation and regression
   checks, then a final PR with playable native-versus-Flutter comparisons and
   explicit remaining differences.

The immediate next action after this plan is agreed is to audit and index the
existing collections, then assemble one header-tap and one slow-drag reference
bundle with their quality reports and unchanged Flutter comparisons. Reuse valid
recordings; repeat only failed or insufficient cases. Freeze the candidate build
before collecting fresh confirmation gestures, and use those runs to evaluate,
not tune, that candidate. If they drive another change, collect a new confirmation
set. No new capture run, implementation change, or publication was performed as
part of this planning review.
