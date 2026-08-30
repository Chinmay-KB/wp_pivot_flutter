# Launcher component runtime comparison

This follow-up turns the Start/app-list study into UI-only Flutter components and
checks the actual package widgets against held-out Windows Phone 8.1 WVGA emulator
evidence. The component boundary is in `../COMPONENT-CONTRACT.md`.

## Results

| domain | held-out evidence | result |
|---|---|---|
| Start tile rest geometry | r03 native rest vs deterministic package fixture | 11/11 surfaces passed; 0 px maximum edge error |
| app-list rest geometry | `app_list_rest_r03` | 10/10 header/icon slots passed; 0 px maximum edge error |
| alphabet rest geometry | corrected `alphabet_grid_select_r03` reset | 28/28 cells passed; 0 px maximum edge error |
| lateral forward commit/cancel | r03 trials, delivered pointer events | both outcomes passed; 0 px final and surface-separation error |
| lateral inverse commit/cancel | r03 trials, delivered pointer events | both outcomes passed; 0 px final and surface-separation error |
| staggered Start entry/exit | canonical entry/exit frames vs package pose sweep | qualitative correspondence only; exact curve, timing, and transformed polygon equivalence remain unqualified |

The four held-out lateral presentation-registered tracking p95 errors are 3.40,
14.73, 12.72, and 22.50 px. The acceptance bound is 36 px: one approximately
90 ms native host-capture interval at the approximately 400 px/s delivered drag
speed. Direct host-timestamp p95 errors (26.0–96.0 px) are retained in the raw
reports but are not used as guest-presentation latency because the capture
metadata explicitly does not provide that clock.

Presentation registration is an analysis-only constant lag per trial. Native
pointer events are rebased so the first down is 500 ms and otherwise replayed
without interpolation or retiming. Flutter positions are interpolated only when
sampling its 60 fps trajectory at native frame midpoints.

## Reproduce

Use the configured fidelity helper and fresh output paths. The relevant adapters
are:

- `tools/launcher/flutter_render_test.dart`
- `tools/launcher/compare_flutter.py`
- `tools/launcher/compare_primitives.py`
- `tools/launcher/prepare_lateral.py`
- `tools/launcher/record_flutter_lateral.py`
- `tools/launcher/lateral_capture_test.dart`
- `tools/launcher/compare_lateral.py`
- `tools/launcher/compare_lateral_batch.py`
- `tools/launcher/stagger_render_test.dart`
- `tools/launcher/compare_stagger_poses.py`

The adapters require fresh outputs and preserve native/Flutter hashes and source
provenance. Unit tests cover expected passes and deliberate geometry failures.

## Limits

These results are emulator evidence, not Lumia hardware evidence or a live Android
launcher benchmark. Selawik differs from native Segoe WP. Placeholder fixture
icons are intentionally not Microsoft artwork. Vertical overscroll, live-tile
content scheduling, alphabet open/dismiss timing, exact stagger curves, and
physical touch latency are not qualified by this phase.
