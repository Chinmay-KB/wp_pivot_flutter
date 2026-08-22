---
layout: default
title: Home
---

<div class="hero">
  <div class="kicker">A research project · validated on Lumia 1020 hardware</div>
  <h1>Windows Phone,<br/>measured — not remembered.</h1>
  <p class="lead">
    Every "Metro-inspired" UI kit out there was built from screenshots and fuzzy
    memories. That never sat right with me. I have the real thing — a rooted Lumia
    1020 — so this project does it the hard way: capture the actual hardware doing
    its thing, measure every curve, duration and color, publish the raw data next
    to every conclusion, and rebuild the design language in Flutter properly.
  </p>
</div>

<div class="tiles">
  <div class="tile">
    <h3><a href="{{ '/paradigms/' | relative_url }}">Paradigm Encyclopedia</a></h3>
    <p>Pivot, Panorama, LongListSelector, turnstile transitions — every Windows Phone UI paradigm, documented with video, measurements and implementation status. I wasted time reverse-engineering these so you don't have to.</p>
  </div>
  <div class="tile">
    <h3><a href="{{ '/research/' | relative_url }}">Published Research</a></h3>
    <p>Easing curves fitted to tracked motion. Theme colors pulled straight off the OS via root access, not eyeballed from PNGs. The full Segoe type ramp. Scroll physics with the derivations shown.</p>
  </div>
  <div class="tile">
    <h3><a href="{{ '/captures/' | relative_url }}">Capture Sessions</a></h3>
    <p>Every recording session: device build, theme, accent, frame rate, and links to the raw data releases. We show our work — raw footage included, warts and all.</p>
  </div>
  <div class="tile">
    <h3><a href="{{ '/essays/' | relative_url }}">Essays &amp; Legacy</a></h3>
    <p>Why Metro mattered. Typography-first design, authentically digital interfaces — an archive of the ideas, kept for the people who still miss them.</p>
  </div>
</div>

<h2 class="accent-bar">The method</h2>

<ol>
  <li><strong>Capture</strong> — the phone mirrors over USB at full resolution. No camera pointed at a screen, thank you.</li>
  <li><strong>Measure</strong> — track element positions frame by frame, fit cubic-Bézier easing curves to the trajectories, publish the residuals. Colors get sampled per theme and accent, then cross-checked against the OS resource files (root access has its perks).</li>
  <li><strong>Specify</strong> — everything measured becomes a design token or spec document in the repo.</li>
  <li><strong>Implement</strong> — Flutter components built against those tokens, starting with a v2 rewrite of the Pivot.</li>
  <li><strong>Verify</strong> — automated pixel and frame-motion diffs against the hardware captures. "Close enough" is not the bar; indistinguishable is.</li>
</ol>

<blockquote>
  Fidelity to the <em>feel</em> of Windows Phone is the goal — layout, typography,
  color and motion. No Microsoft IP gets redistributed here: fonts are referenced,
  never bundled.
</blockquote>

<p>Follow along on <a href="{{ site.github_repo }}">GitHub</a> — every milestone is broken into small, trackable issues. If you own Windows Phone hardware or have captured footage of your own, contributions are very welcome.</p>
