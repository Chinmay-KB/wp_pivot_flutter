# Start screen and app list primitives

Release: `start-screen-evidence-2026-08-30`
Archive: `wp81-start-screen-evidence-2026-08-30.zip`

This is an emulator-only study of the actual Microsoft Windows Phone 8.1 WVGA
(480 x 800) Start screen and app list. It contributes research, capture tooling,
measurements, and attributed media only: no launcher, Android integration,
package API, or component decision.

`measurements.json` schema v4 is the canonical registry; `docs/media/start-screen/media-index.json`
is canonical media provenance. Raw PNGs are immutable observations. H.264 clips
hold those frames on a 30 fps presentation schedule without interpolation. Host
capture/input clocks are not guest presentation, display, or physical-touch time.

## Reproduce safely

Use the configured study Python, one cooperative emulator lease, and a fresh path
for every output. Before accepting coordinate input, inspect `precondition.png`
and the post-precondition `reset.png`.

```powershell
$py = '<STUDY_PYTHON>'
$helper = '<FIDELITY_HELPER>'
& $py $helper doctor --study artifacts/launcher-primitives-01/study.json
& $py $helper run --study artifacts/launcher-primitives-01/study.json --resource emulator --output artifacts/launcher-primitives-01/runs/capture/NEW -- $py tools/launcher/capture.py --glance-app <GLANCE_APP> --plan tools/launcher/scenarios.json --output artifacts/launcher-primitives-01/runs/capture/NEW --repetitions 3 --only alphabet_grid_cancel
& $py $helper verify-native artifacts/launcher-primitives-01/runs/capture/NEW
& $py tools/launcher/analyze.py artifacts/launcher-primitives-01/runs/capture/NEW --output artifacts/launcher-primitives-01/runs/analysis/NEW
& $py tools/launcher/aggregate.py
& $py tools/launcher/media_index.py
& $py -m unittest discover -s tools/launcher -p 'test_*.py' -v
```

`<STUDY_PYTHON>` and `<GLANCE_APP>` are the configured runtime/bound Glance root
in `study.json`; `<FIDELITY_HELPER>` is the installed UI-Fidelity helper. `alphabet_grid_cancel` explicitly waits 1.5 seconds after the Start-to-app-list
swipe before tapping the verified header (116,88). Stop recorder clients and
confirm idle before release; a new owner may proceed only when `fidelity.py
leases` reports `[]`.

## Scenario and outcome registry

There are 23 IDs. “Eligible” means the three-repeat coarse emulator gate passed,
not that native duration or easing was recovered.

| ID | observed result | repeats | eligible |
|---|---|---:|---|
| start_rest | resting Start | 3 | yes |
| live_tile_passive_flip | People content-plane change | 3 | no |
| start_scroll_slow / flick / overscroll | captured | 3 / 3 / 3 | no / yes / no |
| tile_hold_edit / tile_tap_launch | edit entered then Back restored Start; Calendar launched and recorded clip ends at location prompt | 3 / 3 | yes / no |
| app_to_start_home | Calculator Home entry to Start | 3 | yes |
| start_to_app_list_drag_commit / flick / cancel | list commit; list commit; Start snap-back | 3 each | yes |
| app_list_rest | resting app list | 3 | no |
| app_list_scroll_slow / flick / overscroll | captured | 3 each | yes |
| app_list_to_start_drag_commit | Start commit | 3 | yes |
| app_list_to_start_flick | rejected commit; list snap-back | 3 | observed snap-back only |
| app_list_to_start_flick_commit_strong | rejected commit; list snap-back | 1 | no |
| app_list_to_start_cancel | list snap-back | 3 | yes |
| alphabet_grid_open / select / cancel | opened; settled enabled **b** cell selected to the B section; canceled | 3 each | open/cancel yes; select no (r03 141.19 ms host-capture gap) |
| app_list_item_launch | Calculator launched | 3 | yes |

The old Calculator-to-Home trials are rejected because their initial retained
surface is app list. The old alphabet-select r01–r03 are rejected because the
header precondition was not settled and x=179 was incorrectly labeled as the
**b** cell; replacement `alphabet-select-corrected-01` uses the verified b-cell
center (295,68) and ends at Battery Saver/Calculator/Calendar/Camera/Cortana.
Old alphabet-cancel r01–r03 are rejected because the
unsettled swipe caused Calculator launch; canonical cancel evidence is
`runs/capture/alphabet-cancel-corrected-01`. IE and Store pilots are behavior-only
(privacy/network dialogs). Continuous reverse-while-held is unsupported by this
input bridge and was not faked with two swipes.

## Measured rendered geometry

All bounds are inclusive screenshot pixels: +/-1 px unless noted. They are not
font points, source asset sizes, or universal OS constants.

| primitive | visible rendered measurement |
|---|---|
| tiles | large 210 x 210 px; small 99 x 99 px; 12 px gutters |
| Phone / Messaging / IE | [100,109,148,181] = 49 x 73; [277,84,311,110] = 35 x 27; [382,82,430,126] = 49 x 45 |
| Mail / Calendar / Kid's Corner | [278,202,311,228] = 34 x 27; [107,653,226,700] = 120 x 48; [308,552,392,657] = 85 x 106 |
| labels/live text | Fake GSM Network [34,237,195,253] = 162 x 17; People [34,460,87,477] = 54 x 18; Sun 30 [116,653,225,700] = 110 x 48; Kid's Corner [256,682,351,699] = 96 x 18 |
| app list | search [25,57,67,98] = 43 x 42; header [86,57,147,118] = 62 x 62; Calculator icon [86,427,147,488] = 62 x 62; name [164,444,298,468] = 135 x 25, left x=164/top y=444; 74 px pitch; 16 px gap; baseline y=468 |
| alphabet | replacement settled-grid overlay [24,19,456,785] = 433 x 767; four columns; a cell [135,19,233,117] = 99 x 99 and b cell [246,19,344,117] = 99 x 99; 12 px gutter; enabled `#3e65ff`, disabled `#202020` |
| edit | Calendar [24,500,233,709]; unpin [228,456,272,500], center [250,478], diameter 45; resize [227,691,273,736], center [250,714], diameter 46; +/-2 px |

## Findings, candidates, and limits

Observed phases include staggered per-tile 3-D entry/exit, split lateral Start/
app-list surfaces, release commit/cancel/snap-back, alphabet expansion/dismissal/
selection, Calculator launch, People content-plane flip, vertical boundary motion,
and edit affordances. Exact curves and duration remain unknown.

Candidates for later evaluation are a tile surface/content plane, semantic
alphabet grid, app-list row, scroll/overscroll behavior, and transition
orchestration. API and component selection are deliberately deferred.

No claim is made about Lumia hardware, Android launcher behavior, physical
latency, exact font family/point size, exact easing, or an overall fidelity score.
Microsoft-origin UI is attributed research evidence only; see
[EVIDENCE-NOTICE.md](EVIDENCE-NOTICE.md). No Segoe binaries or standalone Windows
artwork are redistributed.
