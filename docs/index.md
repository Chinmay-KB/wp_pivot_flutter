---
layout: default
title: Home
---

<div class="hero">
  <p class="kicker">wp pivot research</p>
  <h1>Windows Phone,<br/>measured, not remembered.</h1>
  <p class="lead">
    Every "Metro-inspired" UI kit out there was built from screenshots and fuzzy
    memories. That never sat right with me. I have the real thing, a rooted Lumia
    1020, so this project does it the hard way: capture the actual hardware doing
    its thing, measure every curve, duration and color, publish the raw data next
    to every conclusion, and rebuild the design language in Flutter properly.
  </p>
</div>

<p><a href="{{ '/research/pivot/' | relative_url }}">New: the Pivot motion study</a>
— 57 native emulator trials, raw evidence, native-versus-Flutter comparisons and a release-web runtime timing study.
The source is labeled throughout; Lumia validation remains a separate step.</p>

<div class="tiles">
  <a class="tile wide accent" href="{{ '/paradigms/' | relative_url }}">
    <div>
      <p class="tile-kicker">the encyclopedia</p>
      <h2 class="tile-title">Paradigms</h2>
      <p>Pivot, Panorama, turnstile transitions. Measured, filmed, documented.</p>
    </div>
  </a>
  <a class="tile narrow" href="{{ '/research/' | relative_url }}">
    <div>
      <h2 class="tile-title">Research</h2>
      <p>Easing curves fitted to tracked motion. Colors pulled off the OS via root access, not eyeballed from PNGs.</p>
    </div>
  </a>
  <a class="tile narrow" href="{{ '/captures/' | relative_url }}">
    <div>
      <h2 class="tile-title">Captures</h2>
      <p>Every recording session: build number, theme, accent, frame rate. Raw footage included, warts and all.</p>
    </div>
  </a>
  <a class="tile narrow" href="{{ '/resources/' | relative_url }}">
    <div>
      <h2 class="tile-title">Resources</h2>
      <p>The Codename Metro PDF, the WP7 UI guide, Selawik, icons. The whole paper trail, archived links fixed.</p>
    </div>
  </a>
  <a class="tile narrow" href="{{ '/essays/' | relative_url }}">
    <div>
      <h2 class="tile-title">Essays</h2>
      <p>Why Metro mattered. Kept for the people who still miss it.</p>
    </div>
  </a>
</div>

<h2>the method</h2>

<ol class="steps">
  <li data-step="1"><strong>Capture</strong>: record native controls through the emulator SDK or phone USB projection. Label the source, preserve original frames, and measure acquisition timing.</li>
  <li data-step="2"><strong>Measure</strong>: track element positions frame by frame, fit motion models where supported, and publish residuals and uncertainty. Keep layout, behavior and timing checks separate.</li>
  <li data-step="3"><strong>Specify</strong>: everything measured becomes a design token or spec document in the repo.</li>
  <li data-step="4"><strong>Implement</strong>: Flutter components built against those tokens, starting with a v2 rewrite of the Pivot.</li>
  <li data-step="5"><strong>Verify</strong>: compare against retained native captures, test fresh input traces, and publish remaining differences. Hardware confirmation is identified separately.</li>
</ol>

<blockquote>
  Fidelity to the <em>feel</em> of Windows Phone is the goal: layout, typography,
  color and motion. Proprietary Segoe font files are not redistributed; the
  Selawik fallback is distributed under its Open Font License.
</blockquote>

<p>Follow along on <a href="{{ site.github_repo }}">GitHub</a>: every milestone is broken into small, trackable issues. If you own Windows Phone hardware or have captured footage of your own, contributions are very welcome.</p>
