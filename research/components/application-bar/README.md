# Windows Phone Application Bar — implementation notes

## Scope

`WpApplicationBar` is a standalone Flutter bottom widget for
`Scaffold.bottomNavigationBar`. It implements up to four labelled icon actions,
native-style text menu entries, the default and minimized modes, a keyboard and
screen-reader operable ellipsis, disabled commands, colors, text scaling and
reduced motion.

The native fixture is `tools/native_application_bar/ApplicationBarReference.csproj`.
`build.ps1` invokes the hash-pinned `tools/native_toggle_switch/Restore-Toolkit.ps1`
before copying the WPtoolkit DLL. It owns a real `Microsoft.Phone.Shell.ApplicationBar` declared on a
`PhoneApplicationPage`, with two `ApplicationBarIconButton` entries and two
`ApplicationBarMenuItem` entries. The fixture starts in `Default` mode and its
body button toggles the real `ApplicationBar.Mode`. A second `DetailPage.xaml`
exists so PhoneApplicationFrame forward/back can be captured; that page is not
yet in a verified native trial. It logs passive touch input to `inputs.csv` and
state/click events to `state.csv`; `App.SaveEvidence` flushes them when the
application deactivates or closes.

## Evidence status

The native neutral-state image is
`artifacts/components-batch-01/application-bar/initial.png`. Parent inspection
observed the default Application Bar from y=728 through y=799 (72 pixels), icon
centers at (198, 764) and (282, 764), and ellipsis dots from x=430 through x=455
at y=742. The expanded pilot image is
`artifacts/components-batch-01/application-bar/runs/native-pilot-01/expanded_pilot_r01/frames/000031.png`.
Its native surface starts at y=473: the icon/ellipsis row is at the top, labels
sit below its icons, and the `settings` and `about` rows follow underneath.
The Flutter ordering and two-button placement follow these observed WVGA frames.

Expanded-pilot host frames 000014–000019 (read-only batch-01) show the command
row remaining on screen while the menu height grows: 000014 is the 72px bar;
000015 already shows `previous`/`next` labels with `settings` entering; 000016+
show both menu rows under the icons. That is clip-from-the-top of a still-mounted
command row, not a bottom-aligned child swap. Capture cadence was ~18 fps, so
those frames cannot support a fitted ease curve.

All three native pilot scenarios were collected in
`artifacts/components-batch-01/application-bar/runs/native-pilot-01`, with raw
frames and exported guest telemetry. The minimized pilot observed a 30-pixel
collapsed row, so the Flutter minimized height follows that measured state.
Guest `platform.txt` reports logical page `ActualHeight` 728 with the default
bar (800−72) and 770 when minimized (800−30). Transition timing, broader
action-count placement and typography remain unqualified. Menu expansion uses
the existing provisional 180 ms duration without claiming a native fit. The
Flutter motion suppresses when `MediaQuery.disableAnimationsOf(context)` or
`reducedMotion` is true, including the command focus wash.

`scenarios.json` describes 480×800 ApplicationBar pilots. The expanded pilot
leaves the native menu open and uses Back twice during cleanup (close menu, then
exit); that is the basis for Flutter `PopScope` consuming the first Back.
Batch-02 WVGA Frame capture of `DetailPage` is recorded in
`artifacts/components-batch-02/grok/NATIVE-CAPTURE.md`.

## Page shell (gallery)

The experimental gallery is not a native ApplicationBar page. Its chrome follows
the WP8 SDK `PhoneApplicationPage` template and
`v8.1/Design/ThemeResources.xaml`:

- `PhoneBackgroundColor` `#FF000000`, `PhoneChromeColor` `#FF1F1F1F`,
  `PhoneSubtleColor` `#99FFFFFF`
- `PhoneTextNormalStyle` 20px application title, `PhoneTextTitle1Style` 72px
  page title (`PhoneFontSizeExtraExtraLarge`), `PhoneTextExtraLargeStyle` 42.667
- Title panel margin `12,17,0,28` and page-title margin `9,-7,0,0`
- No in-page Material chevron. Pushed gallery pages show a **preview hardware
  Back** strip (chassis analog below the page, `maybePop`) plus Escape / system
  pop. That strip is gallery preview chrome, not an ApplicationBar Back icon.

Page layers use **TurnstileFeather** from local WPtoolkit **4.2013.8.16**
(`TransitionFrame` + `TurnstileFeatherTransition` + `FeatheringIndex` 0/1/2
on header, title, content). `ContinuumTransition` is **not** in that assembly.
WVGA Toolkit capture is `artifacts/components-batch-02/grok/TOOLKIT-MOTION.md`
(and `runs/toolkit-nav-01`). Plain `PhoneApplicationFrame` evidence remains
`NATIVE-CAPTURE.md` / `native-nav-01` and is not replaced.

Structural implementation (RotationY, sequential out-then-in, per-index delay,
ExponentialEase exponent 6) comes from the Toolkit DLL. Host capture ~22 fps
is **not** a fitted timing curve. ApplicationBar and gallery preview hardware
Back are not feather targets. Reduced motion keeps duration zero.

## Third-party assets

TurnstileFeather storyboards under `toolkit-storyboards/` are Microsoft-copyrighted
and licensed under the [Microsoft Public License (Ms-PL)](../MS-PL.txt). The native
fixture icons `tools/native_application_bar/Assets/appbar.back.rest.png` and
`appbar.next.rest.png` are from WPtoolkit **4.2013.8.16**, also under
[Ms-PL](../MS-PL.txt).

## Source references

Microsoft documents that a default Application Bar has icon buttons plus an
ellipsis, while a minimized bar has only the ellipsis, in its
[ApplicationBarMode reference](https://learn.microsoft.com/en-us/previous-versions/windows/apps/hh286467%28v%3Dvs.105%29).
Its [ApplicationBar icon-button reference](https://learn.microsoft.com/en-us/previous-versions/windows/apps/ff403307%28v%3Dvs.105%29)
contains the XAML pattern with two buttons and two menu items used by this
fixture. Microsoft also documents that Application Bar menu items slide up from
under the buttons when the ellipsis is pressed in the
[IsMenuEnabled reference](https://learn.microsoft.com/en-us/previous-versions/windows/apps/ff769567%28v%3Dvs.105%29).

## Next evidence step

WVGA Frame navigate/back (`NATIVE-CAPTURE.md`) and Toolkit TurnstileFeather
navigate/back (`TOOLKIT-MOTION.md`) are captured. Do not treat 21–24 fps frames
as curve proof. Glance `XdeBridge` remains pinned to
`Emulator 8.1 WVGA 4 inch 512MB`; other installed profiles cannot be captured
through the current harness.
