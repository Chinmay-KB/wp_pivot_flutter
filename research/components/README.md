# Experimental component studies

This work adds **Application Bar**, **Panorama**, **ToggleSwitch**, **Slider**,
**ProgressBar**, and **TiltEffect** behind
the opt-in `package:wp_pivot_flutter/wp_components.dart` import. The existing
Pivot import remains unchanged. The six-control gallery ships in version 2.2.0.

## Try the gallery

From `example/`, run `flutter run -d chrome -t lib/components.dart`.
The six routes exercise commands, minimized/expanded bars, panorama navigation,
controlled values, progress states, and press-position tilt. They do not change
network settings on the host.

## Study scope and acceptance

The accepted scope is an experimental implementation and reusable evidence
pipeline, not verified identity with Windows Phone. Component workers owned
disjoint source/test/native-scene paths; the coordinator alone controlled the
emulator and serialized Flutter commands. UI Fidelity supplies cooperative
leases and evidence checks. Sol Advisor supplies implementation/review routing.
The user approved explicit Terra/high workers and a fresh Sol/high reviewer
instead of unavailable named agent roles; runtime role isolation was not verified.

| Gate | Scope |
| --- | --- |
| Behavioral | Widget tests, disabled state, keyboard/semantics, reduced motion, layout bounds, directional Panorama settling |
| Reference | Real native controls on the WP8.1 WVGA 480×800 emulator; retained inputs, raw PNGs, guest logs, source/package hashes |
| Integration | Separate gallery and exports; existing Pivot regression tests |
| Fidelity | **Open**: no calibrated frame correspondence, fitted curves, repeatability estimate, live runtime benchmark, or hardware cross-check |

The first three controls remain exploratory pilots used to discover geometry and harness problems.
No numerical fidelity thresholds were frozen before tuning; this batch cannot
be interpreted as confirmation evidence. `custom` adapters remain unqualified.

## Evidence registry

Local evidence lives in ignored `artifacts/components-batch-01/`. Preserve that
directory separately from Git. Each component has `study.json`, `handoffs/`, and
`runs/`. Raw capture directories include `manifest.json`, `events.jsonl`,
`frames.csv`, original `frames/*.png`, and guest `state.csv`/`inputs.csv`.
Derived `*-media/` folders include a video, source-frame mapping, and timing report.

| Component/session | Trials | Observation |
| --- | --- | --- |
| Panorama/native-pilot-01 | clear_swipe; cancelled_small_drag | Native selection 0→1 and 0→0. The entry animation had not fully settled in the first frames. |
| ToggleSwitch/native-pilot-01 | wifi_tap; wifi_slow_drag_cancel | Tap changed off→on. The original drag missed the thumb: invalid as cancellation evidence. |
| ToggleSwitch/native-pilot-02 | wifi_slow_drag_cancel; wifi_slow_drag_commit | Both changed off→on. The short input's name describes intent, not observed cancellation. |
| Application Bar/native-pilot-01 | collapsed_pilot; expanded_pilot; minimized_pilot | Previous command fired; expanded menu visually observed; minimized mode logged. |

All nine pilots contain 430 raw frames in total. The native capture rate varied
approximately 14–26 fps. Playback is encoded at 30 fps by holding the last
observed frame on the host capture-end timeline; this does not improve temporal
resolution. `native-integrity.json` checks raw integrity; `video-integrity.json`
records independent complete decodes and hashes. Neither proves visual fidelity.

Flutter replay uses SDK **host receipt** event intervals in a deterministic
test clock. Those are not calibrated guest event times. Approximate scenes use
bundled Selawik instead of native Segoe WP and substitute icon glyphs. Native and
Flutter media must not be described as synchronized motion comparisons.

Component details: [Application Bar](application-bar/README.md),
[Panorama](panorama/scene-contract.md), [ToggleSwitch](toggle-switch/native-source.md),
[Slider, ProgressBar, and TiltEffect](micro-controls/README.md).

The micro-control study is a later calibrated batch: 15 repeated native trials
plus two fresh post-freeze Tilt confirmations, held-out Flutter input replay,
explicit per-metric acceptance, and immutable source checks. Its results do not
retroactively qualify the Application Bar, Panorama, or ToggleSwitch pilots.

Toolkit storyboards, icons, and other Microsoft-copyrighted research assets in
this tree are licensed under the [Microsoft Public License (Ms-PL)](MS-PL.txt).

## Resume without reconstructing the workflow

1. Load the installed `ui-fidelity:fidelity-study` skill and this registry. Read
   the component's study, handoff and failed-attempt logs before choosing trials.
2. Use the plugin's machine bindings and shared lease directory. One emulator
   owner at a time; one Flutter command owner per worktree. No hardware is required.
3. Build the selected `tools/native_*/build.ps1` fixture and deploy its XAP with
   Glance. ToggleSwitch restores a pinned Toolkit package with a checked hash;
   SDK/Toolkit binaries and licensed fonts are not committed.
4. Acquire an emulator lease, then run `tools/components/capture.py --help` and
   pass the component's `scenarios.json`, XAP and source directory. Choose a fresh
   output directory. Inspect initial frames and guest logs; launch success does
   not prove reset or rest. Release the lease after all clients exit.
5. Run UI Fidelity `verify-native`, then `tools/components/summarize.py` on each
   selected trial. Never edit raw inputs/PNGs or overwrite an old attempt.
6. Replay with `tools/components/render_test.dart` as documented beside that
   tool. Freeze source bytes, not only Git HEAD, before confirmation work.
7. Next: calibrate reset/rest detection and clock correspondence, collect
   repeated bidirectional/interrupt/cancel trials, then freeze measurable layout
   and motion acceptance thresholds before candidate tuning. Background
   Panorama parallax and ToggleSwitch short-drag behavior still need evidence.
