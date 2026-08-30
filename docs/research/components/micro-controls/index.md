---
layout: default
title: Micro-control fidelity study
body_class: study-page
---

<header class="page-mast">
  <div class="mast-title"><h1>Three controls, measured.</h1></div>
  <div class="mast-copy">
    <p class="page-deck">Slider, ProgressBar, and TiltEffect were recorded on the WP8.1 emulator, implemented in Flutter, replayed with retained inputs, and checked again after candidate freeze.</p>
    <dl class="study-facts">
      <div class="study-fact"><dt>Controls</dt><dd>3</dd></div>
      <div class="study-fact"><dt>Native trials</dt><dd>17</dd></div>
      <div class="study-fact"><dt>Native PNGs</dt><dd>885</dd></div>
      <div class="study-fact"><dt>Hardware</dt><dd>Lumia pending</dd></div>
    </dl>
  </div>
</header>

<section class="manual-section" aria-labelledby="result-title">
  <header class="section-label"><h2 id="result-title">Held-out result</h2></header>
  <div class="section-body">
    <table>
      <thead><tr><th>Control</th><th>Measured result</th><th>Boundary</th></tr></thead>
      <tbody>
        <tr><td>Slider</td><td>Tap/drag value error &lt;0.000034 units; track and thumb edges exact.</td><td>Value ≤1 unit; edges ≤1 px.</td></tr>
        <tr><td>Determinate progress</td><td>408×4 track and 42% fill exact on all four edges.</td><td>Edges ≤1 px.</td></tr>
        <tr><td>Indeterminate progress</td><td>Five 4×4 marks; phase-aligned center MAE 2.175 px across 166 observations.</td><td>Center MAE ≤8 px.</td></tr>
        <tr><td>TiltEffect</td><td>Pose formula error &lt;0.0001°/px; fresh corner edges exact, center maximum edge error 2 px.</td><td>Pose ≤0.25°/0.5 px; projected edges reported separately.</td></tr>
      </tbody>
    </table>
    <p class="quiet-note">There is no aggregate fidelity score. Values, pixel edges, mark trajectories, pose, and timing stay in their native units.</p>
  </div>
</section>

<section class="manual-section" aria-labelledby="frames-title">
  <header class="section-label"><h2 id="frames-title">Resting frame</h2></header>
  <div class="section-body">
    <figure class="comparison-evidence">
      <div class="image-compare" data-image-compare style="--compare-position: 50%;" role="group" aria-label="Native and Flutter resting-frame comparison">
        <div class="image-compare__stage">
          <img class="image-compare__after" src="{{ '/media/components/flutter-rest.png' | relative_url }}" alt="Flutter micro-control reference scene at rest">
          <div class="image-compare__before"><img src="{{ '/media/components/native-rest.png' | relative_url }}" alt="Native WP8.1 micro-control fixture at rest"></div>
          <span class="image-compare__label image-compare__label--before">Native</span>
          <span class="image-compare__label image-compare__label--after">Flutter</span>
          <span class="image-compare__divider" aria-hidden="true"></span>
        </div>
        <label class="sr-only" for="resting-frame-reveal">Reveal more of the native or Flutter resting frame</label>
        <div class="image-compare__control"><span aria-hidden="true">Native</span><input id="resting-frame-reveal" data-image-compare-input data-first-label="Native" data-second-label="Flutter" type="range" min="0" max="100" value="50"><span aria-hidden="true">Flutter</span></div>
      </div>
      <figcaption><strong>Resting-frame reveal</strong><span>Original native PNG · deterministic Flutter render · both 480×800</span></figcaption>
    </figure>
    <p class="quiet-note">The layouts share reference coordinates. Typography remains visibly different because Flutter bundles Selawik rather than proprietary Segoe WP.</p>
  </div>
</section>

<section class="manual-section" aria-labelledby="motion-title">
  <header class="section-label"><h2 id="motion-title">Recorded motion</h2></header>
  <div class="section-body">
    <h3>Indeterminate ProgressBar</h3>
    <figure class="comparison-evidence video-compare" data-video-compare>
      <div class="video-compare__grid">
        <div class="video-compare__pane">
          <span class="compare-pane__label">Native acquisition</span>
          <video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/components/native-rest.png' | relative_url }}">
            <source src="{{ '/media/components/progress-native.mp4' | relative_url }}" type="video/mp4">Your browser cannot play the native video.
          </video>
          <p class="compare-pane__note">Held original frames; no interpolation.</p>
        </div>
        <div class="video-compare__pane">
          <span class="compare-pane__label">Flutter replay</span>
          <video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/components/flutter-rest.png' | relative_url }}">
            <source src="{{ '/media/components/progress-flutter.mp4' | relative_url }}" type="video/mp4">Your browser cannot play the Flutter video.
          </video>
          <p class="compare-pane__note">33.333 ms deterministic test clock.</p>
        </div>
      </div>
      <div class="compare-toolbar" role="group" aria-label="Indeterminate ProgressBar comparison playback">
        <button type="button" data-video-play>Play both</button><button type="button" data-video-pause>Pause both</button><button type="button" data-video-restart>Restart both</button><span class="compare-status" data-video-status aria-live="polite">Ready · independent timelines</span>
      </div>
      <figcaption><strong>Indeterminate ProgressBar</strong><span>Launches together; clocks and durations remain independent</span></figcaption>
    </figure>
    <figure class="media-evidence">
      <img src="{{ '/media/components/indeterminate-trajectories.png' | relative_url }}" alt="Five measured native indeterminate progress mark trajectories across three repetitions">
      <figcaption><strong>Native mark trajectories</strong><span>Repetition 3 is held out</span></figcaption>
    </figure>

    <h3>TiltEffect corner press</h3>
    <figure class="comparison-evidence video-compare" data-video-compare>
      <div class="video-compare__grid">
        <div class="video-compare__pane">
          <span class="compare-pane__label">Fresh native confirmation</span>
          <video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/components/native-rest.png' | relative_url }}">
            <source src="{{ '/media/components/tilt-native.mp4' | relative_url }}" type="video/mp4">Your browser cannot play the native video.
          </video>
          <p class="compare-pane__note">Captured after candidate freeze.</p>
        </div>
        <div class="video-compare__pane">
          <span class="compare-pane__label">Flutter replay</span>
          <video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/components/flutter-rest.png' | relative_url }}">
            <source src="{{ '/media/components/tilt-flutter.mp4' | relative_url }}" type="video/mp4">Your browser cannot play the Flutter video.
          </video>
          <p class="compare-pane__note">Retained host input intervals.</p>
        </div>
      </div>
      <div class="compare-toolbar" role="group" aria-label="TiltEffect comparison playback">
        <button type="button" data-video-play>Play both</button><button type="button" data-video-pause>Pause both</button><button type="button" data-video-restart>Restart both</button><span class="compare-status" data-video-status aria-live="polite">Ready · independent timelines</span>
      </div>
      <figcaption><strong>TiltEffect corner press</strong><span>Launches together; clocks and durations remain independent</span></figcaption>
    </figure>
    <figure class="media-evidence">
      <img src="{{ '/media/components/tilt-release.png' | relative_url }}" alt="Native TiltEffect rotation and depth after pointer release">
      <figcaption><strong>Guest-clock release telemetry</strong><span>200 ms delay and 100 ms return bracketed by samples</span></figcaption>
    </figure>
    <p class="quiet-note">“Play both” launches the two files together without aligning or resampling their timelines. Native and Flutter use different clocks and durations. The 30 fps native MP4 holds the last acquired image; it does not turn the roughly 15–16 fps source into new observations.</p>
  </div>
</section>

<section class="manual-section" aria-labelledby="method-title">
  <header class="section-label"><h2 id="method-title">Method and integrity</h2></header>
  <div class="section-body">
    <ol>
      <li>A source-complete WP8.1 fixture rendered actual Slider and ProgressBar controls and Toolkit TiltEffect at 480×800.</li>
      <li>Repetitions 1–2 were fitting evidence; repetition 3 was withheld until the candidate was frozen.</li>
      <li>All 769 initial native PNGs passed hash, byte-length, membership, dimension, manifest-error, and initial-state checks.</li>
      <li>After the first held-out Tilt replay exposed a camera-convention defect, the fix was checked against fitting data and two new native trials were captured. Their 116 PNGs also passed integrity checks.</li>
      <li>The final Flutter replay retained source snapshots and produced 889 indexed 480×800 frames across the held-out and fresh-confirmation sets.</li>
    </ol>
    <p>Slider final values matched native telemetry and image-derived positions independently. Progress dots were compared after one phase offset without interpolating native motion. Tilt image edges and guest-clock release telemetry were evaluated as separate domains.</p>
  </div>
</section>

<section class="manual-section" aria-labelledby="unknown-title">
  <header class="section-label"><h2 id="unknown-title">What remains unknown</h2></header>
  <div class="section-body">
    <ul>
      <li>The native indeterminate loop did not recur. Its held-out lower bound is greater than 3452.231 ms; the Flutter 4500 ms loop is conservative, not a measured native period.</li>
      <li>Host acquisition and the guest Stopwatch have no calibrated clock correspondence.</li>
      <li>Emulator evidence does not establish Lumia presentation, latency, or performance.</li>
      <li>Selawik and Flutter rasterization do not reproduce Segoe WP exactly.</li>
    </ul>
  </div>
</section>

<section class="manual-section" aria-labelledby="evidence-title">
  <header class="section-label"><h2 id="evidence-title">Evidence and code</h2></header>
  <div class="section-body download-list">
    <a href="{{ site.github_repo }}/blob/master/research/components/micro-controls/README.md">Protocol and measurements</a>
    <a href="{{ site.github_repo }}/tree/master/tools/native_micro_controls">Native fixture</a>
    <a href="{{ site.github_repo }}/blob/master/tools/components/analyze_micro_controls.py">Native analyzer</a>
    <a href="{{ site.github_repo }}/blob/master/tools/components/compare_micro_controls.py">Held-out comparator</a>
    <a href="{{ site.github_repo }}/releases/tag/micro-controls-evidence-2026-08-29">Raw evidence bundle</a>
  </div>
</section>
