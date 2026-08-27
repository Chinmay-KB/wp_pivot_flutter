# Pivot fidelity study

## Required outcome

Record actual Windows Phone Pivot interactions, analyze layout and motion, improve
the Flutter package against that evidence, publish the evidence on the research
website, and raise a PR containing native-versus-Flutter side-by-side video.
Tests and comparisons must measure behavior, not simply reproduce implementation
constants. Emulator and physical-device evidence must remain explicitly distinct.

## Work environment

- Base: `d9f158d40b87413fc17ee346304f0725e80220fe` (`master`).
- Worktree branch: `codex/pivot-native-fidelity`.
- Sol Advisor route: solo; root owns measurement, implementation, and verification.
- Flutter installed: 3.47.1, Dart 3.13.1.
- Native target available: WP8.1 SDK emulator, WVGA 480x800.
- Glance SDK capture/control from sibling `wp-mirror/app`; existing work preserved.

## Gates (not yet satisfied)

- [x] Build a minimal native reference using Microsoft's real Pivot control.
- [x] Capture a reproducible native scenario matrix, clean frames, timestamps,
      gesture events, and platform metadata.
- [x] Establish capture quality and uncertainty; do not treat held video frames
      as additional motion observations.
- [x] Publish trajectories, fits/residuals, layout measurements, and findings.
- [x] Capture the unmodified Flutter baseline with matching content/viewport.
- [x] Improve interaction and layout while retaining a documented migration path.
- [x] Test cancellation, header taps, continuous drag, wrap, reversal, lifecycle,
      accessibility, and controller behavior as supported by the native evidence.
- [x] Compare the improved actual Flutter output with native footage, quantitatively
      and visually; disclose remaining discrepancies.
- [x] Publish research/capture pages and downloadable evidence.
- [x] Raise PR with playable side-by-side comparison and verification results.

## Scope of the first reference scene

Four pages (`first`, `second`, `third`, `fourth`), title `PIVOT RESEARCH`, dark
background, native default headers, simple matching content with high-contrast
tracking markers. The native Pivot's template, easing, and gesture handling are
not replaced. Pointer overlays belong in review media, never in raw evidence.

The site's existing `PRODUCT.md`/`DESIGN.md` describe the publication site rather
than the Flutter control; preserve them and use native evidence for widget design.

## First collection completed

- 27 native motion trials: 3 pilot, 21 core, 3 trajectory-off controls; 1,538
  original frames verified against capture hashes. One additional resting style
  snapshot exports actual native font properties.
- Native headers use Segoe WP SemiLight at 72; title uses Segoe WP Semibold at
  22.667. Foreground properties alone do not describe inherited opacity; inactive
  headers look gray despite their text brush being white.
- Three baseline Flutter test-engine replays and three input-aligned comparison
  videos, with separate pointer-annotated copies. The baseline uses local Segoe UI,
  not redistributed Segoe WP fonts. It is not a runtime performance test.
- Analysis and interpretation: `research/pivot/README.md`; capture protocol:
  `research/pivot/EVIDENCE_PLAN.md`.
- Four Python measurement tests pass. Flutter analysis passes and all eight
  existing tests pass. The three opt-in capture runs also pass.
- Current findings: header/body phases differ from PageView; adjacent-header
  telemetry supports a roughly 258 ms candidate model; skipped headers require
  a discontinuity rather than the same single-phase curve. Body telemetry is not
  reliable; use image tracks.
- Capture limitations: nominal flicks are not reliably delivered as intended;
  per-trial actual input logs must govern replay. Trajectory-off controls only
  establish coarse comparability, not absence of subtle instrumentation overhead.
- Publication, improved Flutter code, full gesture coverage, hardware checks and
  final PR remain outstanding. No public evidence release has been claimed.

## Revised implementation and fresh confirmation

- Added `WpPivotView` with separate native-reference header/body phases and an
  explicit migration from the unchanged header-only API. Bundled unmodified
  OFL Selawik fonts, with license and source hashes.
- 21 fresh native confirmation trials add both-direction successful flicks,
  reverse drags, same-contact reversal, selected-header taps and forward wrap.
  All 1,696 new PNG hashes pass, bringing the native total to 48 trials / 3,234 PNGs.
- Candidate source hashes were frozen before checking the new outcomes. All 21
  fresh selection sequences match, as do all 21 original core traces. The widget
  replay required a ticker-start correction across idle gaps; the implementation's
  motion was not adjusted in response to these confirmation outcomes.
- 19 Flutter widget tests and 6 Python measurement checks pass. Flutter analysis
  passes. The release web example builds and a live browser header tap selects
  the second page; this is a functional check, not a runtime fps benchmark.
- Ten final comparison scenarios have clean native/Flutter video, side-by-side
  video, and a separate pointer version. All 40 MP4s decode fully and their decoded
  frame counts match the source-frame mapping CSVs.
- Final image metrics are under `research/pivot/comparisons/final/`. Body position
  errors and visible-page mismatches are separate. Default layout matches native
  bar coordinates; timing remains limited by native capture uncertainty.
- Added a bounded `gesture` operation to the existing Glance SDK bridge for timed
  paths and release-at-final-vertex. Five malformed requests were rejected before
  any pointer event on the connected emulator; 11 existing emulator tests pass.
  The release source snapshot must include this changed bridge.
- USB hardware query returned `no devices` (projection access unavailable). No
  physical-device comparison is claimed. Site publication and final PR are next.

## Publication verified

- Dataset release `pivot-evidence-2026-08-27` is public. All 26 original release
  assets match local SHA-256 digests; the test log and publication verification
  are additional attachments. Archives retain all native/baseline/prototype/final
  collections and include per-member inventories.
- Documentation-only PR #57 was built and merged to publish the study without
  merging the Flutter implementation. The existing master/docs Pages configuration
  is unchanged. The actual Jekyll page and all three public MP4s return HTTP 200;
  the public MP4 bytes match the verified local files.
- Desktop direct-video playback reached the end in browser inspection. A 390px
  iframe preview loads the embedded media; this is not a Codex mobile-app test.
- Publication evidence: `research/pivot/publication.json`. Flutter implementation
  remains on `codex/pivot-native-fidelity` for its separate review PR.
- Implementation PR #58 is open with the study, paired preview, playable native
  versus Flutter clips, quantitative differences and test results. The public
  header comparison played to its end (1.833333 s) in browser verification; all
  three embedded public videos report readyState 4 without a media error.
- Remaining fidelity validation: hardware comparison once USB projection is
  available, and interactive runtime timing/smoothness beyond deterministic
  replay. This work has not established a universal native-fidelity guarantee.
