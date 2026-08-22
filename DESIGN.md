# DESIGN.md — WP Pivot Research site

Recorded from the built Metro world (2026-08-22, impeccable new-work, user-pinned brief).

## World

Authentic Windows Phone Metro, desktop-web interpretation. The site presents itself
as a WP start screen: true-black ground, Segoe Light type ramp, flat square-cornered
tiles, one accent color. The site is itself the project's first fidelity proof.

## Color tokens

| Token | Value | Role |
|---|---|---|
| `--bg` | `#000000` | Page ground. True black (AMOLED reference), never dark-grey. |
| `--surface` | `#111111` | Pre/code blocks only. |
| `--tile-dark` | `#1d1d1d` | Standard tile fill. |
| `--accent` | `#1ba1e2` | Phone blue. Used in WP's own grammar: hero kicker, tile fill (encyclopedia tile only), step numerals, th text, links, verified badge. |
| `--fg` | `#ffffff` | Primary text. |
| `--fg-dim` | `#a6a6a6` | Secondary text (tagline, tile body on dark tiles uses `#cfcfcf`). |
| `--hairline` | `#2a2a2a` | 1px separators (h2 underline, table rows, step rows, footer top). |
| Footer text | `#9d9d9d` | Minimum contrast floor for any text on black. |

## Typography

Segoe UI / Selawik stack (system fallbacks after). Weights are the WP ramp:

- Display (hero h1, brand): 200, clamp(34–64px), line-height ~1.05
- Page h1: 200, clamp(34–56px)
- Section h2: 300, 24px, hairline underline
- Tile title: 300, 20px
- Body: 400, 15–16px, `#d9d9d9`, max-width 72ch
- Tile body: 400, 14px, `#cfcfcf` (regular weight — light weight illegible at tile size)
- Kickers/labels/th: 400, 11–13px, lowercase (Metro convention), letter-spacing 0.02–0.12em

## Components

- **Tiles**: CSS grid, 4 columns desktop / 2 mobile, 8px gutters (tight, WP-like).
  `span 2` standard, `span 4` wide. One accent-filled tile per grid (encyclopedia).
  Hover = `scale(.97)` press-down (never lift/shadow). Chevron glyph bottom-right at 35% opacity.
  Whole-tile click via stretched `a.tile-link`.
- **Step list** (`.steps`): borderless rows with hairline separators; numeral rendered
  via `::before` from `data-step`, accent color, 26px weight 200 — WP settings-page grammar, not a blog list.
- **Blockquote**: no box, no background — oversized light-weight statement type (22px, weight 200, white).
- **Tables**: hairline row separators; `th` in accent, lowercase.
- **Code**: `#111` surface, no border-radius, no accent border.
- **Status badges**: flat squares, WP toast palette (#333 spec / #ca5010 building / #107c10 shipped / accent verified).

## Bans (binding)

No border-radius anywhere (`* { border-radius: 0 }`). No drop shadows. No gradient
fills. No side-tab accent borders. No cards-in-cards. Background is never #111-or-lighter
for page ground.

## Motion

Single transition: tile press-down `transform .08s ease-out`. Nothing else animates.
(Motion research on the real platform is the project's subject; the site stays still
so the measurements stand out.)

## Content rules

Lowercase nav and section labels. First-person conversational copy per the site voice.
One accent tile per grid — accent is structural, never decorative scatter.
