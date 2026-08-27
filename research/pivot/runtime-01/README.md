# Release-web runtime measurement

This is a real wall-clock run of the actual `ResearchPivot` / `WpPivotView`,
separate from the deterministic widget-test image replays. The opt-in entrypoint
is `example/lib/runtime_probe.dart`. The normal demo does not import it.

## Conditions and method

- Flutter 3.47.1, release web build, Chromium 151 on Windows, 360×600 logical
  viewport, DPR 1. The browser document reported visible throughout the run.
- Four scenarios: adjacent header tap, body drag, successful next flick, and
  forward header drag. Each uses a hashed native input replay.
- One warm-up per scenario, followed by three measured repetitions: 16 trials
  total, of which 12 are measured. All expected selection sequences match.
- Inputs are injected through Flutter's pointer dispatch, scheduled against
  `performance.now()` with real delays. This measures neither physical touch
  latency nor the browser's native touch event path.
- `SchedulerBinding.addTimingsCallback` collected 939 engine frames, including
  warm-up/reset/flush frames. The analysis selects 678 frames inside measured
  trial windows. No forced frames are requested during the gesture/animation.
- Post-selection cadence considers adjacent engine vsync-start timestamps within
  each 750ms animation window. Idle gaps are excluded; large animation gaps are
  retained. The 60Hz budget is a comparison target, not an inferred display rate.

## Results

| Measurement | Median | 95th percentile | Maximum |
| --- | ---: | ---: | ---: |
| Build work | 3.00ms | 5.20ms | 11.60ms |
| Raster work/submission | 0.40ms | 0.80ms | 24.00ms |
| Total engine span | 3.70ms | 6.10ms | 28.70ms |
| Post-selection frame interval | 16.60ms | 17.30ms | 29.30ms |
| Input scheduling lateness | 2.74ms | 9.27ms | 15.23ms |

One of 678 measured total spans exceeds 16.667ms. Small cadence variations around
16.667ms are not automatically dropped frames; the raw over-budget interval count
must not be presented as a dropped-frame percentage. See `summary.json` and
`frame-cost.png`. These are measurements of this host, not a universal benchmark.

Flutter's installed web engine uses `performance.now()` for its FrameTiming
timestamps and reports raster completion after rendering/submission. This does
not measure physical display presentation, a mobile GPU, native Windows Flutter,
or the Lumia. The local native Windows C++ build toolchain is unavailable.

Primary API references: [FrameTiming](https://api.flutter.dev/flutter/dart-ui/FrameTiming-class.html)
and [addTimingsCallback](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addTimingsCallback.html).
The build manifest records the precise Flutter engine revision and all compiled
bundle hashes. The raw browser report records every frame, input delivery,
selection and visibility observation. Exact build sources are retained alongside
the report; the current entrypoint only removes an unused import from that build.

## Reproduce

From the repository root, use a fresh output directory:

```powershell
python tools/runtime_probe/build.py --flutter D:/sdk/flutter/bin/flutter.bat --output artifacts/runtime-site-new/runtime
python -m http.server 8792 --bind 127.0.0.1 --directory artifacts/runtime-site-new
```

Open `http://127.0.0.1:8792/runtime/`, keep the tab visible, press **Start measurement**,
and wait for **Complete**. Save the full visible JSON report. Large DOM reads may
require multiple chunks; verify JSON parsing and length before analysis.

```powershell
python tools/runtime_probe/analyze.py path/to/report.json --output path/to/analysis
python -m unittest discover -s tools/runtime_probe -p 'test_*.py'
```

Do not run native recording, builds or other heavy benchmark workloads alongside
this measurement. The supplemental release includes the actual compiled probe,
build manifest, raw run, analysis and source; no proprietary font files are bundled.
