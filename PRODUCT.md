# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Static Jekyll site served via GitHub Pages from `/docs` in the wp_pivot_flutter
repository. Plain markdown pages + one shared HTML layout + vanilla CSS. No JS
build step. Content is added by ordinary PRs.

## Users

- Windows Phone enthusiasts and nostalgists revisiting the platform's design ideas.
- Flutter developers who want to build WP-styled UIs against measured specs rather than guesswork.
- Design historians and writers researching the Metro design language (primary sources, measurements).

## Product Purpose

Publication site for the WP Pivot Research project: recreating the Windows Phone
(Metro) design language in Flutter, with every claim backed by measurements taken
from a real rooted Lumia 1020. The site hosts the paradigm encyclopedia, published
research findings (motion tokens, color tokens, typography), capture session indexes,
essays on Metro's legacy, and a resources index of archived primary sources.

Success = researchers trust the data, Flutter devs build against the specs,
and the preservation work reaches people who miss the platform.

## Positioning

The only Windows Phone design resource built from hardware measurement instead of
screenshots and memory: every easing curve, color token and type size ships with its
raw data. "Measured, not remembered."

## Operating Context

Content workflow: markdown PRs render automatically via Jekyll on merge to master.
Capture sessions produce media too large for git (goes to GitHub Releases).
Measurements flow: capture → track → fit → token → implement → verify.

## Capabilities and Constraints

- Jekyll's default GitHub Pages build (no custom plugins; kramdown/GFM only).
- Site must remain PR-driven so research contributions are plain markdown + media.
- Media budget: clips <10MB in git; raw footage in Releases.
- No Microsoft IP redistribution: Segoe referenced/substituted (Selawik), never bundled.
- Light JS allowed but each script is a maintenance cost; prefer CSS.

## Brand Commitments

Project name "WP Pivot Research". Voice: first-person, conversational, honest about
limits (see docs copy). Visual direction is user-pinned: authentic Metro — black
background, single accent color (classic phone blue #1ba1e2 family), Segoe-style
type ramp, tile-based navigation. This is a binding aesthetic brief.

## Evidence on Hand

- Working capture rig (MyProjectionClient over USB, ~30fps verified) — session media incoming.
- Roadmap doc (docs/ROADMAP.md), milestones/issues in repo.
- Archived primary sources collected on the Resources page (Codename Metro PDF, WP7 UI Guide v2.0).

## Product Principles

1. Show the receipts: no conclusion without raw data next to it.
2. Fidelity to feel, not just pixels: motion and typography carry the identity.
3. Preserve, don't gatekeep: everything public, contributions welcome.
4. The hardware is the source of truth; memory is not evidence.

## Accessibility & Inclusion

Standard web accessibility expected: contrast-aware accent usage on black, keyboard
navigable nav, semantic headings. No specific compliance target recorded.

Status: nav and tiles have visible `:focus-visible` outlines; tile links use their
visible titles as accessible names. Still open: the brand wordmark is an `h1` on
every page alongside the page title's `h1` (two h1s per page); collapsing it to a
single document `h1` is a known follow-up.
