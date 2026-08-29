---
layout: default
title: Experimental components
body_class: study-page
---

<header class="page-mast">
  <div class="mast-title"><h1>Experimental components</h1></div>
  <div class="mast-copy">
    <p class="page-deck">Six opt-in Flutter controls now connect Windows Phone sources to labeled emulator evidence. Slider, ProgressBar, and TiltEffect add repeated measurement and held-out comparison; the earlier batch remains pilot research.</p>
    <dl class="study-facts">
      <div class="study-fact"><dt>Components</dt><dd>6</dd></div>
      <div class="study-fact"><dt>Reference</dt><dd>WP8.1 emulator</dd></div>
      <div class="study-fact"><dt>API</dt><dd>Opt-in</dd></div>
      <div class="study-fact"><dt>Release</dt><dd>2.2.0</dd></div>
    </dl>
  </div>
</header>

<section class="manual-section" aria-labelledby="available-title">
  <header class="section-label"><h2 id="available-title">What exists</h2></header>
  <div class="section-body">
    <ul class="record-list">
      <li class="record-row"><span class="record-name">Application Bar</span><span class="record-meta">Icon commands, text menu items, default and minimized modes</span><span class="status-badge">Experimental</span></li>
      <li class="record-row"><span class="record-name">Panorama</span><span class="record-meta">Layered title, background, item canvas, and directional navigation</span><span class="status-badge">Experimental</span></li>
      <li class="record-row"><span class="record-name">Toggle Switch</span><span class="record-meta">Controlled on/off state using the WP8 Toolkit template geometry</span><span class="status-badge">Experimental</span></li>
      <li class="record-row"><a href="{{ '/research/components/micro-controls/' | relative_url }}">Slider</a><span class="record-meta">Tap, drag, keyboard, semantics, and native template geometry</span><span class="status-badge status-available">Compared</span></li>
      <li class="record-row"><a href="{{ '/research/components/micro-controls/' | relative_url }}">ProgressBar</a><span class="record-meta">Determinate and five-mark indeterminate presentations</span><span class="status-badge status-available">Compared</span></li>
      <li class="record-row"><a href="{{ '/research/components/micro-controls/' | relative_url }}">TiltEffect</a><span class="record-meta">Touch-position pose and Toolkit release timing</span><span class="status-badge status-available">Compared</span></li>
    </ul>
    <p>All six are exported from the separate <code>wp_components.dart</code> library in version 2.2.0. The stable Pivot entrypoint and APIs remain unchanged.</p>
  </div>
</section>

<section class="manual-section" aria-labelledby="evidence-title">
  <header class="section-label"><h2 id="evidence-title">Evidence boundary</h2></header>
  <div class="section-body">
    <table>
      <thead><tr><th>Component</th><th>Evidence used</th><th>Not established</th></tr></thead>
      <tbody>
        <tr><td>Application Bar</td><td>Default, expanded, and minimized emulator pilots; measured 72 px and 30 px bar states at 480×800.</td><td>Fitted transition timing, typography, and broader action counts.</td></tr>
        <tr><td>Panorama</td><td>Native resting layout, item pitch, next-item peek, and layered control structure.</td><td>Gesture curve, calibrated parallax, font match, and RTL fidelity.</td></tr>
        <tr><td>Toggle Switch</td><td>WP8 Toolkit template dimensions plus native off/on observations.</td><td>Drag threshold and capture-verified motion timing.</td></tr>
        <tr><td>Slider</td><td>Three repeated tap/drag trials, exact value telemetry, and image-derived track/thumb edges.</td><td>Broader themes and Lumia hardware behavior.</td></tr>
        <tr><td>ProgressBar</td><td>Exact determinate edges and five phase-aligned native mark trajectories across three repetitions.</td><td>The exact native repeat period; it did not recur in the capture window.</td></tr>
        <tr><td>TiltEffect</td><td>Toolkit source formula, guest-clock release telemetry, held-out replay, and a fresh post-freeze capture.</td><td>Physical touch/display latency and Lumia rendering.</td></tr>
      </tbody>
    </table>
    <p class="quiet-note">The first batch remains exploratory. The micro-control study passes its declared per-metric checks but does not claim that Flutter is visually or temporally identical to Windows Phone.</p>
  </div>
</section>

<section class="manual-section" aria-labelledby="use-title">
  <header class="section-label"><h2 id="use-title">Try the API</h2></header>
  <div class="section-body">
    <pre><code>import 'package:wp_pivot_flutter/wp_components.dart';</code></pre>
    <p>Run <code>flutter run -d chrome -t lib/components.dart</code> from <code>example/</code> to open the component gallery.</p>
  </div>
</section>

<section class="manual-section" aria-labelledby="sources-title">
  <header class="section-label"><h2 id="sources-title">Sources</h2></header>
  <div class="section-body download-list">
    <a href="{{ site.github_repo }}/blob/master/research/components/application-bar/README.md">Application Bar notes</a>
    <a href="{{ site.github_repo }}/blob/master/research/components/panorama/scene-contract.md">Panorama scene contract</a>
    <a href="{{ site.github_repo }}/blob/master/research/components/toggle-switch/native-source.md">Toggle Switch source record</a>
    <a href="{{ '/research/components/micro-controls/' | relative_url }}">Slider, ProgressBar, and TiltEffect study</a>
    <a href="{{ site.github_repo }}/blob/master/research/components/micro-controls/README.md">Micro-control protocol and measurements</a>
    <a href="{{ site.github_repo }}/tree/master/research/components">Component evidence registry</a>
    <p class="quiet-note">Lumia validation remains open. Panorama, Application Bar, and ToggleSwitch still need their own calibrated confirmation studies.</p>
  </div>
</section>
