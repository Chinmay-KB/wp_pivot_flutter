---
layout: default
title: Start screen and app list primitives
body_class: study-page
---

<header class="page-mast">
  <div class="mast-title"><h1>Start screen and app list primitives</h1></div>
  <div class="mast-copy"><p class="page-deck">A reproducible WP8.1 emulator study of tiles, app-list surfaces, alphabet navigation, scrolling, and live content. Research/tooling/media only: no launcher or package API decision.</p></div>
</header>

<section class="manual-section" aria-labelledby="scope">
  <header class="section-label"><h2 id="scope">Scope and evidence</h2></header>
  <div class="section-body">
    <p>The reference is the Microsoft Windows Phone 8.1 WVGA emulator at 480 × 800. The authoritative registry is <code>research/start-screen/measurements.json</code> schema v4; canonical media provenance is <code>docs/media/start-screen/media-index.json</code>. This release indexes 67 registry trials across 23 scenario IDs and 20 canonical source-mapped clips; requested-outcome-failed inverse flicks remain in that registry as observed snap-backs, while pilots and superseded invalid-precondition trials are retained separately in the release. <a href="{{ site.github_repo }}/releases/tag/start-screen-evidence-2026-08-30">Release page</a> · <a href="{{ site.github_repo }}/releases/download/start-screen-evidence-2026-08-30/wp81-start-screen-evidence-2026-08-30.zip">download evidence archive</a>.</p>
    <p>Every MP4 below is 480 × 800 H.264. “30 fps” is encoded presentation cadence only: each frame holds a preceding acquired native PNG, with no interpolation. Host capture intervals and input receipts are not guest presentation, display, or physical-touch time.</p>
  </div>
</section>

<section class="manual-section" aria-labelledby="geometry">
  <header class="section-label"><h2 id="geometry">Rendered geometry</h2></header>
  <div class="section-body">
    <p>Bounds are inclusive rendered screenshot pixels, not source asset size or font point size; edge uncertainty is ±1 px unless noted.</p>
    <table><thead><tr><th>primitive</th><th>measurement</th></tr></thead><tbody>
      <tr><td>tile planes</td><td>large 210 × 210 px; small 99 × 99 px; 12 px gutters</td></tr>
      <tr><td>icon/content landmarks</td><td>Rendered Phone [100,109,148,181] 49 × 73; Messaging [277,84,311,110] 35 × 27; IE [382,82,430,126] 49 × 45; Mail [278,202,311,228] 34 × 27; Calendar date/live content [107,653,226,700] 120 × 48; Kid’s Corner content [308,552,392,657] 85 × 106</td></tr>
      <tr><td>labels/live text</td><td>Fake GSM Network [34,237,195,253] 162 × 17; People [34,460,87,477] 54 × 18; Sun 30 [116,653,225,700] 110 × 48; Kid’s Corner [256,682,351,699] 96 × 18</td></tr>
      <tr><td>app list</td><td>search [25,57,67,98] = 43 × 42; header [86,57,147,118] = 62 × 62; Calculator icon [86,427,147,488] = 62 × 62; name [164,444,298,468] = 135 × 25, left x=164/top y=444; 74 px row pitch; 16 px icon/name gap; baseline y=468</td></tr>
      <tr><td>alphabet grid</td><td>replacement settled-grid overlay [24,19,456,785] = 433 × 767; four columns; a [135,19,233,117] = 99 × 99 and b [246,19,344,117] = 99 × 99; 12 px gutter; enabled #3e65ff, disabled #202020</td></tr>
      <tr><td>edit pose</td><td>Calendar [24,500,233,709]; unpin [228,456,272,500], center [250,478], diameter 45; resize [227,691,273,736], center [250,714], diameter 46; ±2 px</td></tr>
    </tbody></table>
  </div>
</section>

<section class="manual-section" aria-labelledby="evidence-code">
  <header class="section-label"><h2 id="evidence-code">Evidence and code record</h2></header>
  <div class="section-body"><p>Trace the exhaustive 23-ID matrix and limits through the <a href="{{ site.github_repo }}/blob/start-screen-evidence-2026-08-30/research/start-screen/README.md">study protocol</a>, <a href="{{ site.github_repo }}/blob/start-screen-evidence-2026-08-30/research/start-screen/measurements.json">measurements.json</a>, <a href="{{ '/media/start-screen/media-index.json' | relative_url }}">media-index.json</a>, <a href="{{ site.github_repo }}/tree/start-screen-evidence-2026-08-30/tools/launcher">launcher adapter record</a>, and <a href="{{ site.github_repo }}/blob/start-screen-evidence-2026-08-30/research/start-screen/EVIDENCE-NOTICE.md">evidence notice</a>. The source/release inventory is available from the <a href="{{ site.github_repo }}/releases/tag/start-screen-evidence-2026-08-30">release page</a> and the <a href="{{ site.github_repo }}/releases/download/start-screen-evidence-2026-08-30/wp81-start-screen-evidence-2026-08-30.zip">direct archive</a>.</p></div>
</section>

<section class="manual-section" aria-labelledby="entry">
  <header class="section-label"><h2 id="entry">Start entry, Calendar exit, and edit pose</h2></header>
  <div class="section-body"><p>Observed entry/exit is staggered per-tile 3-D motion; exact easing and duration are unknown. Calendar evidence ends on its recorded location prompt, not a claim about permissions.</p>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/start-entry/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/start-entry/clip.mp4' | relative_url }}" type="video/mp4">Start entry video unavailable; <a href="{{ '/media/start-screen/start-entry/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Calculator keypad → staggered 3-D Start entry → settled tiles. Source-mapped corrected Calculator Home r03.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/start-exit-calendar/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/start-exit-calendar/clip.mp4' | relative_url }}" type="video/mp4">Calendar exit video unavailable; <a href="{{ '/media/start-screen/start-exit-calendar/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Start → Calendar tile fly-off in staggered 3-D → recorded Calendar prompt. Source-mapped r03.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/tile-edit/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/tile-edit/clip.mp4' | relative_url }}" type="video/mp4">Edit pose video unavailable; <a href="{{ '/media/start-screen/tile-edit/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Calendar lifted with circular unpin/resize affordances, then unchanged Start after Back. Source-mapped r03.</figcaption></figure>
  </div>
</section>

<section class="manual-section" aria-labelledby="lateral">
  <header class="section-label"><h2 id="lateral">Lateral surfaces and release outcomes</h2></header>
  <div class="section-body"><p>During drag, Start and list surfaces share the viewport. Release outcomes are observed commit or snap-back states, not a recovered curve.</p>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/start-to-app-list-drag/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/start-to-app-list-drag/clip.mp4' | relative_url }}" type="video/mp4">Drag video unavailable; <a href="{{ '/media/start-screen/start-to-app-list-drag/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Start → shared split → app-list commit. Source-mapped r03.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/start-to-app-list-flick/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/start-to-app-list-flick/clip.mp4' | relative_url }}" type="video/mp4">Flick video unavailable; <a href="{{ '/media/start-screen/start-to-app-list-flick/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Start flick → split surfaces → app-list commit. Source-mapped r03.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/start-to-app-list-cancel/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/start-to-app-list-cancel/clip.mp4' | relative_url }}" type="video/mp4">Cancel video unavailable; <a href="{{ '/media/start-screen/start-to-app-list-cancel/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Short Start drag exposes list edge, then snaps back to Start. Source-mapped r03.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/app-list-to-start-drag/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/app-list-to-start-drag/clip.mp4' | relative_url }}" type="video/mp4">Inverse drag video unavailable; <a href="{{ '/media/start-screen/app-list-to-start-drag/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>App list → shared split → Start commit. Source-mapped r03.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/app-list-to-start-cancel/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/app-list-to-start-cancel/clip.mp4' | relative_url }}" type="video/mp4">Inverse cancel video unavailable; <a href="{{ '/media/start-screen/app-list-to-start-cancel/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Short app-list drag exposes Start, then snaps back to the list. Source-mapped r03.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/inverse-flick-snap-back/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/inverse-flick-snap-back/clip.mp4' | relative_url }}" type="video/mp4">Rejected flick video unavailable; <a href="{{ '/media/start-screen/inverse-flick-snap-back/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Rejected inverse-flick commit: partial right displacement, then app-list snap-back. Source-mapped r03.</figcaption></figure>
  </div>
</section>

<section class="manual-section" aria-labelledby="scroll">
  <header class="section-label"><h2 id="scroll">Vertical scrolling and boundaries</h2></header>
  <div class="section-body"><p>These clips show observed content displacement and boundary return. A timing-qualified coarse gate does not establish physical latency or a native easing equation.</p>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/start-scroll-slow/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/start-scroll-slow/clip.mp4' | relative_url }}" type="video/mp4">Start slow-scroll video unavailable; <a href="{{ '/media/start-screen/start-scroll-slow/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Start slow scroll to lower tile/Photos content. Source-mapped r03.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/start-scroll-flick/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/start-scroll-flick/clip.mp4' | relative_url }}" type="video/mp4">Start flick-scroll video unavailable; <a href="{{ '/media/start-screen/start-scroll-flick/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Start flick scroll to lower content. Source-mapped r03.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/start-overscroll/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/start-overscroll/clip.mp4' | relative_url }}" type="video/mp4">Start overscroll video unavailable; <a href="{{ '/media/start-screen/start-overscroll/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Start top boundary pulled down, then restored. Source-mapped r03.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/app-list-scroll-slow/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/app-list-scroll-slow/clip.mp4' | relative_url }}" type="video/mp4">List slow-scroll video unavailable; <a href="{{ '/media/start-screen/app-list-scroll-slow/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>App-list slow scroll from A rows to lower rows. Source-mapped r03.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/app-list-scroll-flick/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/app-list-scroll-flick/clip.mp4' | relative_url }}" type="video/mp4">List flick-scroll video unavailable; <a href="{{ '/media/start-screen/app-list-scroll-flick/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>App-list flick scroll to lower rows. Source-mapped r03.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/app-list-overscroll/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/app-list-overscroll/clip.mp4' | relative_url }}" type="video/mp4">List overscroll video unavailable; <a href="{{ '/media/start-screen/app-list-overscroll/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>App-list top boundary pulled down, then restored. Source-mapped r03.</figcaption></figure>
  </div>
</section>

<section class="manual-section" aria-labelledby="alphabet">
  <header class="section-label"><h2 id="alphabet">Alphabet grid and app launch</h2></header>
  <div class="section-body"><p>The corrected cancel session waits for list settle before the header tap. Old no-settle cancel trials remain rejected supplemental evidence because they launched Calculator.</p>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/alphabet-open/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/alphabet-open/clip.mp4' | relative_url }}" type="video/mp4">Alphabet-open video unavailable; <a href="{{ '/media/start-screen/alphabet-open/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>App list → alphabet overlay expansion → grid. Source-mapped r01.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/alphabet-select/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/alphabet-select/clip.mp4' | relative_url }}" type="video/mp4">Alphabet-select video unavailable; <a href="{{ '/media/start-screen/alphabet-select/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Corrected settled grid → enabled b-cell transition → distinct B app-list section (Battery Saver through Cortana). Source-mapped corrected r03; its 141.19 ms host-capture gap makes this behavior/geometry evidence, not a timing trajectory claim.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/alphabet-cancel/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/alphabet-cancel/clip.mp4' | relative_url }}" type="video/mp4">Alphabet-cancel video unavailable; <a href="{{ '/media/start-screen/alphabet-cancel/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Corrected grid → Back dismissal over app list → list restored. Source-mapped corrected r03.</figcaption></figure>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/app-list-launch/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/app-list-launch/clip.mp4' | relative_url }}" type="video/mp4">Calculator launch video unavailable; <a href="{{ '/media/start-screen/app-list-launch/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>Calculator row → launch splash → keypad surface. Source-mapped r01.</figcaption></figure>
  </div>
</section>

<section class="manual-section" aria-labelledby="live">
  <header class="section-label"><h2 id="live">People live-tile flip</h2></header>
  <div class="section-body"><p>This is passive native content-plane evidence, not a reconstructed shell animation. The repeat group supports behavior/geometry; its timing gate is not eligible.</p>
    <figure class="media-evidence"><video controls playsinline preload="metadata" width="480" height="800" poster="{{ '/media/start-screen/live-tile-flip/poster.png' | relative_url }}"><source src="{{ '/media/start-screen/live-tile-flip/clip.mp4' | relative_url }}" type="video/mp4">Live-tile flip video unavailable; <a href="{{ '/media/start-screen/live-tile-flip/clip.mp4' | relative_url }}">download MP4</a>.</video><figcaption>People content plane splits/flips, then reaches its updated rendered state. Source-mapped r01.</figcaption></figure>
  </div>
</section>

<section class="manual-section" aria-labelledby="limits">
  <header class="section-label"><h2 id="limits">Boundaries and candidate implications</h2></header>
  <div class="section-body"><p>No Lumia/hardware, Android-launcher, overall-fidelity, exact-font/point-size, exact-easing, or physical-latency claim follows from this emulator record. Continuous reverse-while-held is unsupported by the bridge. Microsoft-origin emulator UI is attributed evidence only, not package assets or trademark affiliation; no proprietary Segoe binary or standalone Windows artwork is redistributed.</p><p>Candidate primitives for later evaluation are a tile surface/content plane, semantic alphabet grid, app-list row, scroll/overscroll behavior, and transition orchestration. API/component selection is deferred until after research review.</p></div>
</section>
