---
layout: default
title: Research
---

<h1 class="accent-bar">Published Research</h1>

<p>Every finding here ships with its receipts: device build number, capture session
references, raw tracking CSVs, fit residuals. If I can't show you the data, I don't
publish the conclusion. That's the deal.</p>

<h2 class="accent-bar">Animations &amp; motion</h2>
<ul>
  <li><em>Pivot flick dynamics</em> — in progress (M3)</li>
  <li><em>Page transition suite</em> — planned (M3)</li>
  <li><em>List entrance stagger + semantic zoom</em> — planned (M3)</li>
  <li><em>Micro-interactions (tilt, toggle, press)</em> — planned (M3)</li>
</ul>
<p>Method, for the curious: track element positions across frames of real hardware
footage, fit cubic-Bézier easing curves to the trajectories, publish the curve
parameters alongside the residuals so you can see how good (or bad) the fit is.
Where a "transition" turns out to be a velocity handoff rather than a single curve,
that gets documented too — the phone doesn't care what fits nicely.</p>

<h2 class="accent-bar">Color</h2>
<ul>
  <li><em>Theme tokens (dark/light × accents)</em> — in progress (M2–M3). Exact hex
  values pulled from OS resource files via root access, then cross-checked against
  screen captures. Two independent sources agreeing beats one.</li>
</ul>

<h2 class="accent-bar">Typography</h2>
<ul>
  <li><em>The WP type ramp</em> — planned (M3). Sizes and weights measured from the
  device; font strategy references metric-compatible substitutes without bundling
  Microsoft's fonts. Licensing matters.</li>
</ul>

<h2 class="accent-bar">Physics</h2>
<ul>
  <li><em>Scroll &amp; flick physics model</em> — planned (M3). Is the deceleration
  exponential or constant-friction? What's the minimum velocity that turns a drag
  into a flick? We'll find out from footage rather than folklore.</li>
</ul>

<p>All research lands in <code>research/</code> in the repo — see the
<a href="{{ site.github_repo }}/blob/master/docs/ROADMAP.md#research-publication-plan">publication plan</a>
for the layout.</p>
