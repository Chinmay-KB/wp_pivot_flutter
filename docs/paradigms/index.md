---
layout: default
title: Paradigms
body_class: index-page
---

<header class="page-mast">
  <div class="mast-title"><h1>Paradigms</h1></div>
  <div class="mast-copy"><p class="page-deck">An inventory of Windows Phone interaction patterns. Evidence, Flutter implementation, and hardware validation are tracked separately.</p></div>
</header>

<section class="manual-section" aria-labelledby="available-title">
  <header class="section-label"><h2 id="available-title">Available</h2></header>
  <div class="section-body">
    <a class="featured-record" href="{{ '/research/pivot/' | relative_url }}">
      <span class="record-name">Pivot</span>
      <span class="record-detail"><code>WpPivotView</code> ships in package v2.2.0. Emulator evidence is published; Lumia validation is pending.</span>
      <span class="status-badge status-available">Published</span>
    </a>
    <ul class="record-list">
      <li class="record-row"><a href="{{ '/research/start-screen/' | relative_url }}">Start tiles</a><span class="record-meta">23-scenario emulator study; no package component or launcher decision</span><span class="status-badge status-available">Published evidence</span></li>
      <li class="record-row"><a href="{{ '/research/components/' | relative_url }}">Panorama</a><span class="record-meta">Opt-in layout and directional navigation</span><span class="status-badge">Experimental</span></li>
      <li class="record-row"><a href="{{ '/research/components/' | relative_url }}">Application Bar</a><span class="record-meta">Opt-in commands, menu, and minimized mode</span><span class="status-badge">Experimental</span></li>
      <li class="record-row"><a href="{{ '/research/components/' | relative_url }}">Toggle Switch</a><span class="record-meta">Opt-in controlled switch using Toolkit geometry</span><span class="status-badge">Experimental</span></li>
      <li class="record-row"><a href="{{ '/research/components/micro-controls/' | relative_url }}">Slider, ProgressBar, TiltEffect</a><span class="record-meta">Opt-in controls with held-out emulator comparisons</span><span class="status-badge status-available">Compared</span></li>
    </ul>
  </div>
</section>

<section class="manual-section" aria-labelledby="backlog-title">
  <header class="section-label"><h2 id="backlog-title">Backlog</h2></header>
  <div class="section-body">
    <ul class="record-list">
      <li class="record-row"><span class="record-name">Long lists</span><span class="record-meta">LongListSelector and semantic zoom</span><span class="status-badge status-planned">Planned</span></li>
      <li class="record-row"><span class="record-name">Transitions</span><span class="record-meta">Pages and list entrances</span><span class="status-badge status-planned">Planned</span></li>
      <li class="record-row"><span class="record-name">Press states</span><span class="record-meta">Tilt and general press response</span><span class="status-badge status-planned">Planned</span></li>
    </ul>
  </div>
</section>
