---
layout: default
title: Home
---

<div class="hero">
  <div class="kicker">A research project · validated on Lumia 1020 hardware</div>
  <h1>Windows Phone,<br/>measured — not remembered.</h1>
  <p class="lead">
    Most "Metro-inspired" UI kits are built from screenshots and nostalgia.
    This project does it differently: we capture ground truth from a real,
    rooted Lumia 1020, measure every curve, duration and color, publish the raw
    data alongside our conclusions, and rebuild the design language faithfully
    in Flutter.
  </p>
</div>

<div class="tiles">
  <div class="tile">
    <h3><a href="{{ '/paradigms/' | relative_url }}">Paradigm Encyclopedia</a></h3>
    <p>Every Windows Phone UI paradigm — Pivot, Panorama, LongListSelector, turnstile transitions — documented with video, measurements and implementation status.</p>
  </div>
  <div class="tile">
    <h3><a href="{{ '/research/' | relative_url }}">Published Research</a></h3>
    <p>Easing curves fitted to tracked motion, theme color tokens pulled from the OS itself, the full Segoe type ramp, scroll physics derivations.</p>
  </div>
  <div class="tile">
    <h3><a href="{{ '/captures/' | relative_url }}">Capture Sessions</a></h3>
    <p>Browse every recording session: device build, theme, accent, frame rate, and links to the raw data releases. We show our work.</p>
  </div>
  <div class="tile">
    <h3><a href="{{ '/essays/' | relative_url }}">Essays &amp; Legacy</a></h3>
    <p>Why Metro mattered. Typography-first design, authentically digital interfaces — an archive of the ideas, preserved for the people who miss them.</p>
  </div>
</div>

<h2 class="accent-bar">The method</h2>

<ol>
  <li><strong>Capture</strong> — Project My Screen over USB gives full-resolution, tripod-stable footage of real hardware.</li>
  <li><strong>Measure</strong> — Frame-by-frame motion tracking; cubic-Bézier easing fits with published residuals; colors sampled per theme/accent and cross-checked against OS resource files via root access.</li>
  <li><strong>Specify</strong> — Everything measured becomes a design token or spec document in the repo.</li>
  <li><strong>Implement</strong> — Flutter components built against those tokens, starting with a v2 rewrite of the Pivot.</li>
  <li><strong>Verify</strong> — Automated pixel and frame-motion diffs against hardware captures. "Close enough" is not the bar; indistinguishable is.</li>
</ol>

<blockquote>
  Fidelity to the <em>feel</em> of Windows Phone is the goal — layout, typography,
  color and motion. No Microsoft IP is redistributed: fonts are referenced, never bundled.
</blockquote>

<p>Follow along on <a href="{{ site.github_repo }}">GitHub</a> — every milestone is broken into small, trackable issues.</p>
