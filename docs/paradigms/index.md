---
layout: default
title: Paradigms
---

<h1 class="accent-bar">The Paradigm Encyclopedia</h1>

<p>One page per Windows Phone UI paradigm. Each entry gets: reference footage from
real hardware, the measured motion tokens (curves, durations, stagger), color and
type specs where they matter, and where the Flutter implementation stands. No
guessing, no "approximately like the original" — measurements or it didn't happen.</p>

<h2 class="accent-bar">Navigation structures</h2>
<table>
  <thead><tr><th>Paradigm</th><th>Status</th><th>Entry</th></tr></thead>
  <tbody>
    <tr><td>Pivot</td><td><span class="status-badge status-spec">spec'd</span></td><td><em>first entry, in progress</em></td></tr>
    <tr><td>Panorama</td><td><span class="status-badge status-spec">spec'd</span></td><td>—</td></tr>
    <tr><td>LongListSelector + semantic zoom</td><td><span class="status-badge status-spec">spec'd</span></td><td>—</td></tr>
    <tr><td>App bar &amp; menus</td><td><span class="status-badge status-spec">spec'd</span></td><td>—</td></tr>
  </tbody>
</table>

<h2 class="accent-bar">Motion &amp; transitions</h2>
<table>
  <thead><tr><th>Paradigm</th><th>Status</th><th>Entry</th></tr></thead>
  <tbody>
    <tr><td>Turnstile transition</td><td><span class="status-badge status-spec">spec'd</span></td><td>—</td></tr>
    <tr><td>Slide / rotate / flip / roll</td><td><span class="status-badge status-spec">spec'd</span></td><td>—</td></tr>
    <tr><td>Continuum (image continuity)</td><td><span class="status-badge status-spec">spec'd</span></td><td>—</td></tr>
    <tr><td>List item entrance stagger</td><td><span class="status-badge status-spec">spec'd</span></td><td>—</td></tr>
    <tr><td>Tilt effect</td><td><span class="status-badge status-spec">spec'd</span></td><td>—</td></tr>
    <tr><td>ToggleSwitch / press states</td><td><span class="status-badge status-spec">spec'd</span></td><td>—</td></tr>
  </tbody>
</table>

<p>Status key: <span class="status-badge status-spec">spec'd</span> measured &amp;
specified · <span class="status-badge status-building">building</span> Flutter port
underway · <span class="status-badge status-shipped">shipped</span> in package ·
<span class="status-badge status-verified">verified</span> passed the hardware diff
harness.</p>

<p>Entries are added by ordinary PRs — markdown plus media, per the
<a href="{{ site.github_repo }}/blob/master/docs/MEDIA_POLICY.md">media policy</a>.
The paradigm inventory comes from real capture sessions; see
<a href="{{ '/captures/' | relative_url }}">Captures</a>.</p>
