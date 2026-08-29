# Pivot example

A complete `WpPivotView` with cyclic headers and four sample pages. The example
uses the package in the parent directory through a path dependency.

From this directory, using a Flutter SDK with Dart 3.8+ for the development lints:

```sh
flutter pub get
flutter run -d chrome
```

Use `flutter build web --release` for a release web build. The normal entrypoint is
`lib/main.dart`; no measurement hooks run in the normal demo.

## Optional runtime probe

`lib/runtime_probe.dart` is a separate web-only entrypoint that replays recorded
inputs from `assets/runtime_replays.json`. It requires the JavaScript measurement
harness from the repository's `tools/runtime_probe` directory, which is not part
of the published package. It measures engine frame timing, not physical display
latency. See the [runtime evidence and reproduction notes](https://github.com/Chinmay-KB/wp_pivot_flutter/tree/master/research/pivot)
for the harness, build conditions and limits.
