# Windows Phone Toolkit ToggleSwitch source

The native fixture uses the actual `Microsoft.Phone.Controls.ToggleSwitch` from NuGet package `WPtoolkit` version `4.2013.8.16`, restored by `tools/native_toggle_switch/Restore-Toolkit.ps1`.

- Published package: https://www.nuget.org/packages/WPtoolkit/4.2013.8.16
- Package SHA-256: `C54E3547A0C8943378DEB8E919C22D69618361AD6BEA6AD21C2D400F975CEFD1`
- Source: https://github.com/microsoftarchive/WindowsPhoneToolkit
- Source license: Microsoft Public License (MS-PL), retained in the upstream repository.

The WP8 `Generic.xaml` defines the real control template: normal font/content setup, `PhoneAccentBrush` as `SwitchForeground`, a `12,5,12,42` grid margin, and `ToggleSwitchButton` in the second column. Its `SwitchTrack` is 89 px wide, `SwitchBottom` is 34 px high, `SwitchThumb` is 28 by 38 px (with a 20 px white center after its 4 px horizontal borders), and the checked transform is 69 px. The template's generated check transition is 50 ms with exponential ease-out. No template or visual-state override is present in the fixture.

Native pilot `native-pilot-01` supplies rest-state observations only: the Wi-Fi off thumb bounds were x=368..387 and y=175..212; its track right edge was x=456; and the initial Bluetooth on-state used OS cobalt approximately `#3B5FFF`. Its original slow-drag-cancel input started outside the thumb and is a no-op observation, not drag evidence. `scenarios.json` now starts both slow drags at (378,194), ending at (393,194) for cancel and (445,194) for commit.

Native pilot `native-pilot-02` found that both revised inputs, (378,194)->(393,194) and (378,194)->(445,194), emitted `Wifi,checked,True` in `state.csv`. The cancellation threshold remains unqualified: the short native input may be a tap. Flutter's 30 px regression is a different trajectory and does not establish a native threshold; richer native drag samples are required before changing implementation behavior.

No qualified motion or clock fit exists. Flutter uses source-template dimensions and a 50 ms exponential ease-out as provisional source-derived choices, not capture-verified motion.

## Focus presentation (batch-02)

Native WP8 ToggleSwitch shows no rectangular focus border during touch
interaction. Flutter suppresses the custom keyboard focus ring after pointer
activation; the ring appears only after a keyboard `KeyDown` on the focused
control (Tab traversal or Space/Enter activation). Track/thumb dimensions stay
at the template 89×38 logical pixels; row `minHeight` and label fonts grow with
`textScaler` while long labels ellipsize.
