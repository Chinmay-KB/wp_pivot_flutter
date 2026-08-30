# WP8.1 Start-screen capture adapter

`capture.py` records the actual Windows Phone 8.1 WVGA 480 x 800 shell. It
retains lossless PNGs, hashes, host intervals, delivered events, `precondition.png`,
and `reset.png`; it does not deploy a package, implement a launcher, or prove
guest/display/touch timing.

Use one cooperative emulator lease and a fresh output path for every capture,
analysis, and media run. Do not open another bridge or recorder while capture is
live. Inspect retained frames before accepting coordinate-bearing behavior.

```powershell
$py = '<STUDY_PYTHON>'
$helper = '<FIDELITY_HELPER>'
& $py $helper doctor --study artifacts/launcher-primitives-01/study.json
& $py $helper run --study artifacts/launcher-primitives-01/study.json --resource emulator --output artifacts/launcher-primitives-01/runs/capture/NEW -- $py tools/launcher/capture.py --glance-app <GLANCE_APP> --plan tools/launcher/scenarios.json --output artifacts/launcher-primitives-01/runs/capture/NEW --repetitions 3 --only alphabet_grid_cancel
& $py $helper verify-native artifacts/launcher-primitives-01/runs/capture/NEW
& $py tools/launcher/analyze.py artifacts/launcher-primitives-01/runs/capture/NEW --output artifacts/launcher-primitives-01/runs/analysis/NEW
& $py tools/launcher/aggregate.py
& $py tools/launcher/media.py verify docs/media/start-screen/alphabet-cancel
& $py tools/launcher/media_index.py
& $py -m unittest discover -s tools/launcher -p 'test_*.py' -v
```

Resolve `<STUDY_PYTHON>` and `<GLANCE_APP>` from `study.json`; `<FIDELITY_HELPER>` is the installed UI-Fidelity helper. Alphabet cancel waits 1.5 seconds after Start-to-app-list before the header tap; alphabet selection additionally waits for the grid, then taps the verified enabled b-cell center (295,68), not the a-cell coordinate x=179.
the old no-settle trial remains rejected. Release only after the recorder is
terminal, emulator idle is confirmed, and `fidelity.py leases` returns `[]`.
