# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Static Jekyll site served via GitHub Pages from `/docs` in the wp_pivot_flutter
repository. Plain markdown pages + one shared HTML layout + vanilla CSS. No JS
build step. Content is added by ordinary PRs.

## Users

- Primary: technically sophisticated readers who love Metro and want serious,
  evidence-backed restoration work rather than nostalgia bait.
- Flutter developers who want to build Metro-informed interfaces from measured
  behavior instead of guesswork.
- Design historians and Windows Phone enthusiasts researching the design language
  through primary sources, captures, and reproducible measurements.

## Product Purpose

Publication site for the WP Pivot Research project: recording the Windows Phone
(Metro) design language from labeled sources and rebuilding its interaction
patterns in Flutter. The first published Pivot study uses the WP8.1 emulator;
Lumia 1020 validation remains pending. The site separates available package work,
active research, planned work, and published evidence.

Success = researchers trust the data, Flutter devs build against the specs,
and readers immediately recognize the project as a credible restoration effort.

## Positioning

A public, evidence-led Metro restoration effort. Findings are published only when
their capture reference, method, and raw data are available. Describe the work
literally; do not turn the project purpose into a campaign slogan.

## Operating Context

Content workflow: markdown PRs render automatically via Jekyll on merge to master.
Capture sessions produce media too large for git (goes to GitHub Releases).
Measurements flow: capture → track → fit → token → implement → verify.

## Capabilities and Constraints

- Jekyll's default GitHub Pages build (no custom plugins; kramdown/GFM only).
- Site must remain PR-driven so research contributions are plain markdown + media.
- Media budget: clips <10MB in git; raw footage in Releases.
- No proprietary Microsoft IP redistribution: Segoe is referenced when installed;
  the OFL-licensed Selawik fallback may be bundled.
- Light JS allowed but each script is a maintenance cost; prefer CSS.

## Brand Commitments

Project name "WP Pivot Research". Voice: first-person, conversational, honest about
limits, concise, and specific. Avoid generic promotional language, repeated claims,
and over-explaining. Metro is a source of principles—not a period costume: preserve
its typographic confidence, content-first hierarchy, purposeful motion, directness,
and occasional asymmetry while producing a contemporary research publication.
Typography is pinned to Microsoft's native system family: use `Segoe UI Variable`
and `Segoe UI` when installed, with Segoe UI Light for display and Semibold for
navigation and technical labels. Never redistribute proprietary Segoe font files;
Selawik is the OFL-licensed, metric-compatible fallback on systems without Segoe.

## Evidence on Hand

- Pivot evidence release: 57 native emulator trials, 3,830 retained PNGs,
  comparisons, manifests, and raw analysis archives.
- Package v2.1.0 with `WpPivotView`, `PivotMotion`, and bundled OFL Selawik fonts.
- Lumia 1020 hardware validation is pending and must not be implied by emulator results.
- Roadmap doc (docs/ROADMAP.md), milestones/issues in repo.
- Archived primary sources collected on the Resources page (Codename Metro PDF, WP7 UI Guide v2.0).
- Shipping copy may state only facts supported by these repository sources or
  explicitly confirmed by the project owner. Generated comp text, demonstration
  data, invented dates, sample measurements, and implied findings are not evidence
  and must never ship as content.

## Product Principles

1. Show the receipts: no conclusion without raw data next to it.
2. Fidelity to feel, not just pixels: motion and typography carry the identity.
3. Preserve, don't gatekeep: everything public, contributions welcome.
4. The hardware is the source of truth; memory is not evidence.
5. Say it once, then show the evidence: concise copy and strong information design
   should replace repeated explanation.
6. Never oversell unfinished work: use plain `planned`, `in progress`, and
   `verified` states; do not imply a result before its source data exists.
7. Prefer ordinary words over promotional language or unnecessary jargon. Keep a
   specialist term only when it is the precise term the technical reader needs.

## Accessibility & Inclusion

Standard web accessibility expected: contrast-aware text, keyboard navigation,
semantic headings, and reduced-motion support. No specific compliance target is
recorded.

Status: the brand is a link rather than a heading, each page has one `h1`, current
navigation uses `aria-current`, focus is visible, and the homepage exposes one
descriptive call to action while detailed evidence remains in the linked study.
