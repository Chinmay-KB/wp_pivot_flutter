# Component pilot tools

These tools extend the study workflow to explicit native fixtures. They do not
turn the Pivot tracker into a generic motion adapter.

- `capture.py`: validate bounded input plans, capture raw SDK frames/events,
  record source/package provenance, close the fixture and export guest logs.
  Requires an already installed fixture and an externally held emulator lease.
  Plans may set `reference_viewport` (default `[480, 800]`) so coordinates are
  checked against that logical size. Live XDE attach remains the WVGA 512MB VM
  used by Glance; this is not a multi-profile launcher.
- `summarize.py TRIAL --output NEW_DIRECTORY`: validate raw frames and create
  held-frame video plus a source-frame/time mapping. No motion interpolation.
- `render_test.dart`: deterministic 480×800 Flutter replay of recorded pointer
  receipts, kept outside the normal test suite because it needs explicit inputs.
- `example/test/viewport_capture_test.dart`: multi-viewport PNG capture of actual
  gallery demos at 320×533, 480×800, 480×853, and 800×480 logical pixels (DPR 1).
  See `artifacts/components-batch-02/composer/VIEWPORT-PLAN.md`.
- `replay_video.py REPLAY --output NEW_DIRECTORY`: encode those frames at their
  test-clock cadence and fully decode the resulting MP4. Retains PNG hashes.

From the repository root, with exclusive Flutter ownership:

```powershell
flutter test --no-pub tools/components/render_test.dart `
  --dart-define=COMPONENT=panorama `
  --dart-define=EVENTS=C:/absolute/native-trial/events.jsonl `
  --dart-define=OUTPUT=C:/absolute/new-flutter-replay
```

`COMPONENT` accepts `application-bar`, `panorama`, or `toggle-switch`. Replays
export original receipt events, PNG frames, timestamps and selected/clicked
outcomes. Test-clock rendering is not a real-time performance measurement and
does not establish native/Flutter clock alignment. Preserve source snapshots
alongside the outputs. Use a new directory for every attempt, including failures.

Viewport matrix capture (gallery demos, run from `example/`):

```powershell
cd example
flutter test --no-pub test/viewport_capture_test.dart `
  --dart-define=OUTPUT=C:/absolute/viewport-checks/run-01
```

Writes 20 PNGs plus `manifest.json` and `source-snapshot/` per run. Output must be a fresh directory.

Checks: `python -m unittest discover -s tools/components -p 'test_*.py' -v`.
Python requires the existing capture dependencies, Pillow and imageio-ffmpeg.
The broader study registry is [research/components](../../research/components/README.md).
