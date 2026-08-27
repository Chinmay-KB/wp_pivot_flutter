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
- [ ] Capture a reproducible native scenario matrix, clean frames, timestamps,
      gesture events, and platform metadata.
- [ ] Establish capture quality and uncertainty; do not treat held video frames
      as additional motion observations.
- [ ] Publish trajectories, fits/residuals, layout measurements, and findings.
- [ ] Capture the unmodified Flutter baseline with matching content/viewport.
- [ ] Improve interaction and layout while retaining a documented migration path.
- [ ] Test cancellation, header taps, continuous drag, wrap, reversal, lifecycle,
      accessibility, and controller behavior as supported by the native evidence.
- [ ] Compare the improved actual Flutter output with native footage, quantitatively
      and visually; disclose remaining discrepancies.
- [ ] Publish research/capture pages and downloadable evidence.
- [ ] Raise PR with playable side-by-side comparison and verification results.

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
