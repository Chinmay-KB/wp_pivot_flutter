---
layout: default
title: About
---

<h1 class="accent-bar">About this project</h1>

<p><strong>wp_pivot_flutter</strong> began in 2020 as a weekend experiment: a
Flutter implementation of the Windows Phone Pivot tab bar. In 2026 it grew into
something larger — a systematic, hardware-validated recreation of the entire
Windows Phone design language.</p>

<h2 class="accent-bar">Ground truth</h2>
<p>The reference device is a rooted Nokia Lumia 1020 (RM-875). Root access means
we can do more than record the screen: we can pull accent definitions, font
metrics and animation resources directly off the OS, then verify our pixel-level
conclusions against both sources independently.</p>

<h2 class="accent-bar">How to contribute</h2>
<ul>
  <li><strong>Own Windows Phone hardware?</strong> Capture sessions following the
  media policy — different builds and devices make the research stronger.</li>
  <li><strong>Can implement?</strong> Pick up any issue tagged with a published
  spec and build against it.</li>
  <li><strong>Have footage or memories?</strong> The Essays section preserves the
  platform's story; primary sources welcome.</li>
</ul>

<h2 class="accent-bar">Scope &amp; non-goals</h2>
<p>Fidelity to the <em>feel</em> of Windows Phone is the goal. Redistributing
Microsoft IP is not: Segoe/Selawik fonts are referenced and substituted with
metric-compatible alternatives, never bundled. Artwork remains Microsoft's.
Bit-exact rendering across display pipelines has physical limits; the bar we hold
ourselves to is "indistinguishable to a human," which we treat as roughly 95%+
overlap in automated diffs.</p>

<p>Everything happens in the open:
<a href="{{ site.github_repo }}">github.com/Chinmay-KB/wp_pivot_flutter</a>.</p>
