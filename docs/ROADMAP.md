# Project Vision & Roadmap: Recreating the Windows Phone UI in Flutter

## Background

This package started in 2020 as a weekend experiment: a Flutter implementation of the
Windows Phone **Pivot** tab bar. It worked, it was fun, and then it sat still.

It is no longer just a pivot widget.

## The New Goal

Evolve `wp_pivot_flutter` from a single control into a systematic, research-driven effort to
recreate the Windows Phone (Metro) design language in Flutter — with **pixel-faithful visuals**
and **motion-faithful interactions**, validated against real Windows Phone hardware.

The target device is a rooted **Lumia 1020**, which gives us something most recreations never
have: ground truth.

## Why Hardware Ground Truth Matters

Most "Metro-inspired" UI kits are built from screenshots and memory. Screenshots cannot tell you:

- Easing curves and durations of transitions
- Stagger timing between list items
- Scroll/inertia physics of Pivot flicks and LongListSelector
- Exact theme colors, font weights, and optical sizing across states

A rooted Lumia 1020 can answer all of these — both through screen capture *and* by reading
theme/animation resources directly off the OS.

## Methodology

### Phase 0 — Capture infrastructure

- Screen recording via **Project My Screen** over USB (full-resolution, no camera shake)
- Frame extraction pipeline for frame-by-frame motion analysis
- With root access: pull accent color definitions, Segoe font assets/metrics, and system
  animation constants from OS resources

### Phase 1 — Reference app on-device

Build an app that catalogues every control and interaction that defines the platform:

Pivot, Panorama, LongListSelector, application bar, toasts, dialogs, toggle switches,
progress indicators, page transitions, list item entrance animations, press/release feedback.

### Phase 2 — Measurement & analysis

- Track element positions across frames; fit cubic Bézier easing curves to position-over-time data
- Sample colors per theme/accent state into design tokens
- Extract typography scale (sizes, weights, letter-spacing) for the Segoe WP type ramp
- Document touch physics (flick velocity thresholds, deceleration) empirically

Everything measured becomes a **design token or spec document**, published in this repo under
`research/`.

### Phase 3 — Flutter implementation

Implement components against the spec, starting with a v2 rewrite of the Pivot:

- Proper `PivotController` API (retiring the `GlobalKey` workaround)
- Motion driven by measured curves/durations, not approximations

### Phase 4 — Verification

Automated comparison harness: screenshot Flutter output → pixel/frame diff against captures
from the 1020 → iterate until indistinguishable. This keeps us honest; "close enough" is not
the bar.

## The Role of AI

AI assists at every step — generating implementations from specs, fitting curves to tracked
motion, and automating diff analysis — but measurement is deterministic. We publish raw data
alongside conclusions so anyone can verify.

## Research Publication Plan

All research lives in this repo:

```
research/
  animations/       # easing fits, duration tables, stagger timings, raw frame tracks
  typography/       # type ramp measurements, font metrics
  color/            # theme tokens, accent palettes, contrast samples
  physics/          # scroll/flick models derived from capture sessions
  captures/         # session notes, device/build info, extraction scripts
```

Each finding includes sources (device build number), raw data, and methodology so results are
reproducible.

## Scope & Non-goals

- Goal: fidelity to the *feel* of Windows Phone — layout, typography, color, and motion.
- Not a goal: redistributing Microsoft IP. Segoe fonts will be referenced, not bundled;
  artwork/assets remain Microsoft's.
- Bit-exact rendering across platforms has hardware limits; the realistic bar is
  "indistinguishable to a human," which we treat as ~95%+ overlap in diffs.

## Contributing

This repo follows the [all-contributors](https://allcontributors.org/docs/en/emoji-key)
specification. If you own Windows Phone hardware, have captured footage, or want to implement
components against published specs — contributions of any kind are welcome.
