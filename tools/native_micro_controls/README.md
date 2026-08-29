# Native WP8 micro-controls reference

This buildable Silverlight WP8.0 fixture is intended to run on the Windows Phone 8.1 WVGA 4-inch 512 MB emulator at 480x800. It places three native reference surfaces on one page:

- the platform `System.Windows.Controls.Slider` with its default control template;
- platform determinate and indeterminate `System.Windows.Controls.ProgressBar` instances with their default control templates; and
- the Windows Phone Toolkit `Microsoft.Phone.Controls.TiltEffect`, enabled on the page and exercised through an otherwise default native `Button`.

The fixture does not assign a `Style`, replace a `ControlTemplate`, or override visual states for any measured control. Names, values, layout margins, and the page labels are scene setup, not template substitutions.

## Build and package

From PowerShell:

```powershell
tools/native_micro_controls/build.ps1
```

The build uses MSBuild 14, targets Windows Phone Silverlight 8.0, and produces `bin/Release/MicroControlsReference.xap`. Its fresh application ProductID is `00a800d5-a4fd-4da5-8ced-48f96b3f2a54`; the distinct project GUID is `a9f7df11-b113-4162-bf31-8420f15491c9`.

`Restore-Toolkit.ps1` downloads only NuGet `WPtoolkit` 4.2013.8.16 and verifies SHA-256 `C54E3547A0C8943378DEB8E919C22D69618361AD6BEA6AD21C2D400F975CEFD1` before extraction. Restored packages, build intermediates, and binaries are ignored and must not be committed.

## Source and licensing provenance

- Slider and ProgressBar come from the Windows Phone 8.0 SDK platform assemblies installed with the SDK. No platform source, font, or redistributed binary is committed by this fixture.
- TiltEffect comes from the published [WPtoolkit 4.2013.8.16 NuGet package](https://www.nuget.org/packages/WPtoolkit/4.2013.8.16).
- The archived upstream source is [microsoftarchive/WindowsPhoneToolkit](https://github.com/microsoftarchive/WindowsPhoneToolkit), licensed under the Microsoft Public License (MS-PL). The restore is a local build dependency; the package DLL is not committed.
- The linked application icon is the repository's existing `tools/native_pivot/Assets/Icon.png`; it is packaging metadata and is not part of the measured surface.

## Evidence and capture boundary

`state.csv` samples slider/progress state, actual control bounds, and the TiltEffect-created `PlaneProjection` (`RotationX`, `RotationY`, and `GlobalOffsetZ`) on every Silverlight `CompositionTarget.Rendering` callback. Toolkit TiltEffect projects the Button's first visual child rather than the Button object, so telemetry follows that exact target and distinguishes a missing projection from a zero-valued rest projection. `inputs.csv` records raw `Touch.FrameReported` actions and logical coordinates. Back explicitly saves both files through the same `App.SaveEvidence` callback also used for closing/deactivation. `platform.txt` records assembly identities, viewport, clock frequency, and instrumentation flags.

The render callback is guest UI-thread telemetry, not physical display-presentation timing. A package hash establishes the intended deployed build, not guest readback proof. The generic component recorder creates pilot evidence only; it is not a qualified aligned-motion adapter.

`scenarios.json` is a bounded pilot plan using the recorder's tap/swipe/hold/wait/key schema. A neutral 480×800 launch calibrated the Slider interaction line to y=182. The TiltEffect normalizes input over the Button's 456×72 outer bounds at x=12..468, y=412..484, then projects its 432×48 visual child at x=24..456, y=424..472. The first zero-distance held-press trials are retained as rejected adapter evidence because Silverlight never began a manipulation; the qualified plan now uses a slow 12 px press-drag inside the same center/corner region. Preserve failed trials; do not retarget the plan silently or infer physical touch latency from SDK receipt times.
