---
layout: default
title: Pivot motion study
body_class: study-page
---

<header class="page-mast">
  <div class="mast-title"><h1>Pivot, recorded and compared.</h1></div>
  <div class="mast-copy">
    <p class="page-deck">Microsoft’s Pivot control was recorded, measured, and compared with the Flutter implementation. The results show a closer match—not an indistinguishable renderer.</p>
    <dl class="study-facts">
      <div class="study-fact"><dt>Reference</dt><dd>WP8.1 emulator</dd></div>
      <div class="study-fact"><dt>OS build</dt><dd>8.10.12358.0</dd></div>
      <div class="study-fact"><dt>Evidence</dt><dd>57 native trials</dd></div>
      <div class="study-fact"><dt>Hardware</dt><dd>Lumia pending</dd></div>
    </dl>
  </div>
</header>

<section class="manual-section" aria-labelledby="compare-title">
  <header class="section-label"><h2 id="compare-title">Watch the comparison</h2></header>
  <div class="section-body">
    <p>Native is on the left; Flutter is on the right. Each MP4 already contains both panels on the same recorded input timeline, so one play action starts both views. Flutter frames come from the widget tree, not a redrawn native video.</p>

    <figure class="media-evidence composite-compare">
      <div class="composite-compare__legend" aria-hidden="true"><span>Native reference</span><span>Flutter replay</span></div>
      <video controls playsinline preload="metadata" width="960" height="856" poster="https://chinmaykabi.com/wp_pivot_flutter/media/pivot/header_next.png">
        <source src="https://chinmaykabi.com/wp_pivot_flutter/media/pivot/header_next.mp4" type="video/mp4">
        Your browser cannot play this video.
      </video>
      <figcaption><strong>Tap the next header</strong><a href="https://chinmaykabi.com/wp_pivot_flutter/media/pivot/header_next.mp4">Download MP4</a></figcaption>
    </figure>

    <figure class="media-evidence composite-compare">
      <div class="composite-compare__legend" aria-hidden="true"><span>Native reference</span><span>Flutter replay</span></div>
      <video controls playsinline preload="metadata" width="960" height="856" poster="https://chinmaykabi.com/wp_pivot_flutter/media/pivot/drag_commit.png">
        <source src="https://chinmaykabi.com/wp_pivot_flutter/media/pivot/drag_commit.mp4" type="video/mp4">
        Your browser cannot play this video.
      </video>
      <figcaption><strong>Drag and commit</strong><a href="https://chinmaykabi.com/wp_pivot_flutter/media/pivot/drag_commit.mp4">Download MP4</a></figcaption>
    </figure>

    <figure class="media-evidence composite-compare">
      <div class="composite-compare__legend" aria-hidden="true"><span>Native reference</span><span>Flutter replay</span></div>
      <video controls playsinline preload="metadata" width="960" height="856" poster="https://chinmaykabi.com/wp_pivot_flutter/media/pivot/wrap_previous.png">
        <source src="https://chinmaykabi.com/wp_pivot_flutter/media/pivot/wrap_previous.mp4" type="video/mp4">
        Your browser cannot play this video.
      </video>
      <figcaption><strong>Wrap to the previous page</strong><a href="https://chinmaykabi.com/wp_pivot_flutter/media/pivot/wrap_previous.mp4">Download MP4</a></figcaption>
    </figure>

    <p class="quiet-note">The videos are encoded at 30 fps. Missing native capture time is represented by holding the last captured frame; frames are not interpolated or stretched to force agreement.</p>
  </div>
</section>

<section class="manual-section" aria-labelledby="changed-title">
  <header class="section-label"><h2 id="changed-title">What changed</h2></header>
  <div class="section-body">
    <table>
      <thead><tr><th>Observed behavior</th><th>Flutter change</th></tr></thead>
      <tbody>
        <tr><td>Headers use native spacing and cyclic order.</td><td><code>WpPivotView</code> lays out headers from measured widths and reference coordinates.</td></tr>
        <tr><td>A drag moves the current page without continuously exposing its neighbor.</td><td>Header and body travel are controlled separately instead of by a stock <code>PageView</code>.</td></tr>
        <tr><td>Selection commits on release with distinct outgoing and incoming phases.</td><td>The transition moves the old page out before bringing the selected page in.</td></tr>
        <tr><td>A skipped header rearranges before sliding into place.</td><td>The selected header becomes the anchor before a one-slot transition.</td></tr>
        <tr><td>The threshold-crossing sample is consumed before body travel.</td><td>Gesture tracking follows the delivered-sample sequence found in the logs and images.</td></tr>
      </tbody>
    </table>
    <p>The original <code>WpPivot</code> header-only API remains available. The full view is an explicit migration and preserves page state, controller selection, keyboard navigation, and reduced motion.</p>
  </div>
</section>

<section class="manual-section" aria-labelledby="results-title">
  <header class="section-label"><h2 id="results-title">Measured result</h2></header>
  <div class="section-body">
    <p>Three pilot inputs compare the retained 2.0 baseline with the revised candidate. Position MAE is mean absolute error in the 480 × 800 reference image.</p>
    <table>
      <thead><tr><th>Pilot</th><th>Moving-page MAE</th><th>Different visible pages</th></tr></thead>
      <tbody>
        <tr><td>Header tap</td><td>313.0 → 32.2 px</td><td>22 → 0 of 28</td></tr>
        <tr><td>Committed drag</td><td>158.6 → 4.7 px</td><td>23 → 1 of 46</td></tr>
        <tr><td>Previous wrap</td><td>305.3 → 16.1 px</td><td>27 → 0 of 36</td></tr>
      </tbody>
    </table>
    <figure class="media-evidence">
      <img src="https://chinmaykabi.com/wp_pivot_flutter/media/pivot/header-motion.png" alt="Native observed header positions and Flutter replay positions over time">
      <figcaption><strong>Header transition positions</strong><span>Native observation and Flutter replay</span></figcaption>
    </figure>
    <h3>Supported</h3>
    <ul>
      <li>Original PNGs and image tracking support layout and coarse-motion comparison.</li>
      <li>The candidate matches the selection sequence in 21 fresh trials and 21 earlier core trials.</li>
      <li>Nine later header and title gesture trials bring the archive to 57 native trials and 3,830 PNGs.</li>
    </ul>
    <h3>Not proven</h3>
    <ul>
      <li>Emulator evidence does not validate Lumia hardware behavior.</li>
      <li>Capture timing does not establish display latency or a universal flick threshold.</li>
      <li>Font and rasterizer differences remain visible.</li>
    </ul>
  </div>
</section>

<section class="manual-section" aria-labelledby="runtime-title">
  <header class="section-label"><h2 id="runtime-title">Runtime</h2></header>
  <div class="section-body">
    <p>The release web build replayed four scenarios with one warm-up and three measured repetitions. All 12 measured trials selected the expected page.</p>
    <table>
      <thead><tr><th>Engine measurement</th><th>Median</th><th>95th percentile</th><th>Maximum</th></tr></thead>
      <tbody>
        <tr><td>Build work</td><td>3.00ms</td><td>5.20ms</td><td>11.60ms</td></tr>
        <tr><td>Raster work / submission</td><td>0.40ms</td><td>0.80ms</td><td>24.00ms</td></tr>
        <tr><td>Total frame span</td><td>3.70ms</td><td>6.10ms</td><td>28.70ms</td></tr>
        <tr><td>Post-selection frame interval</td><td>16.60ms</td><td>17.30ms</td><td>29.30ms</td></tr>
      </tbody>
    </table>
    <figure class="media-evidence">
      <img src="https://chinmaykabi.com/wp_pivot_flutter/media/pivot/runtime-frame-cost.png" alt="Measured release web frame work including one frame over the chosen budget">
      <figcaption><strong>Release-web frame work</strong><span>678 measured engine frames</span></figcaption>
    </figure>
    <p class="quiet-note">These numbers support smooth animation on the measured host. They do not measure physical display presentation, native browser touch input, Windows Flutter, mobile performance, or Lumia hardware.</p>
  </div>
</section>

<section class="manual-section" aria-labelledby="evidence-title">
  <header class="section-label"><h2 id="evidence-title">Evidence</h2></header>
  <div class="section-body download-list">
    <a href="{{ site.github_repo }}/releases/tag/pivot-evidence-2026-08-27-header-runtime">Header gestures and runtime release</a>
    <a href="{{ site.github_repo }}/releases/tag/pivot-evidence-2026-08-27">Original Pivot evidence release</a>
    <a href="{{ site.github_repo }}/tree/pivot-evidence-2026-08-27/research/pivot">Protocol, tools, and reproduction commands</a>
    <p class="quiet-note">The archives include original frames, input traces, manifests, comparisons, metrics, source snapshots, and SHA-256 inventories. Unsuccessful trials and superseded prototypes remain labeled and available.</p>
  </div>
</section>

<section class="manual-section" aria-labelledby="next-work-title">
  <header class="section-label"><h2 id="next-work-title">Next checks</h2></header>
  <div class="section-body"><p>Wider gesture sampling, mobile runtime measurement, and a separately labeled Lumia cross-check remain open work.</p></div>
</section>
