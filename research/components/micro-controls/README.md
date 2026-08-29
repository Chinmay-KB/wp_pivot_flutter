# Slider, ProgressBar, and TiltEffect

This study adds opt-in Flutter implementations of three previously absent
Windows Phone controls. The reference is the exact WP8.1 WVGA 480×800 emulator,
using native `Slider` and `ProgressBar` controls plus the archived Windows Phone
Toolkit `TiltEffect`. It is not a Lumia hardware study.

## Sources and fixture

- WP8.1 dark `System.Windows.xaml`: Slider and ProgressBar template geometry.
- WP8.1 dark `ThemeResources.xaml`: progress background and runtime accent.
- Microsoft Windows Phone Toolkit 4.2013.8.16: TiltEffect formula and its
  200 ms return delay plus 100 ms linear return.
- `tools/native_micro_controls/`: the source-complete native reference fixture.
- `tools/components/analyze_micro_controls.py`: immutable native measurement.
- `tools/components/compare_micro_controls.py`: held-out Flutter comparison.
- `tools/components/confirm_micro_tilt.py`: post-freeze Tilt confirmation.

The restored Toolkit package is hash-pinned and not committed. The native XAP
used for capture has SHA-256
`6B3D698068C0A34F483406E2D7597BF51FFB9CA0AAAFDEC19AB075ACFF60B5FC`.
The original 15-trial collection digest is
`1945D53F1AB03F66E3368B35DBF4C073809E5CD3768648053075DB4F482E3157`.

## Protocol

Repetitions 1–2 were used for fitting. Repetition 3 was held out. The first
held-out Tilt replay exposed a Matrix4/PlaneProjection camera convention error;
the correction was justified against repetitions 1–2, then the emulator was
recaptured after candidate freeze. That fresh two-trial collection contains 116
original PNGs and digest
`AAA63FA5DD517C4A34F56D7169C4B5FECE37858F75F67D958FA5F4F1BE03F6CE`.

Across the initial collection, all 15 trials and 769 original PNGs passed
membership, SHA-256, byte-length, dimension, manifest-error, and initial-state
checks. The final Flutter held-out set contains 635 indexed 480×800 frames; the
fresh Tilt replay adds 254.

## Measurements

| Control | Held-out result |
| --- | --- |
| Slider | Tap and drag value error below 0.000034 units; track and thumb edges match all four native edges exactly. |
| Determinate ProgressBar | 408×4 track and 42% fill match all four native edges exactly. |
| Indeterminate ProgressBar | Five 4×4 marks; phase-aligned center MAE 2.175 px across 166 matched observations. Native repeat period remains unknown, with the held-out lower bound greater than 3452.231 ms. |
| TiltEffect | Formula regression error below 0.0001°/0.0001 px. In the fresh confirmation, corner projected edges match exactly and center edges differ by at most 2 px. Native guest samples bracket the 200 ms delay and 100 ms return contract. |

The ProgressBar's configured 4500 ms loop is conservative. It must not be
described as the measured native period: no native trajectory recurred in any
immutable capture window. Progress phase was aligned only to report trajectory
shape, without interpolating native frames.

## Limits

- Host image acquisition and the guest `Stopwatch` are separate clock domains.
- Native video holds the last acquired frame at 30 fps; it does not invent
  observations or improve the roughly 15–16 fps capture rate.
- Flutter uses the OFL-licensed Selawik fallback and a different rasterizer from
  native Segoe WP.
- Emulator evidence does not establish physical display latency or Lumia
  hardware fidelity.
- No aggregate “fidelity percentage” is reported; each supported metric retains
  its own units and acceptance boundary.

The public study page links compact, fully decoded native and Flutter videos.
Raw source evidence remains outside the package archive and is published as a
separate evidence bundle when the release is created.
