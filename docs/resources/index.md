---
layout: default
title: Resources
---

<h1 class="accent-bar">Metro &amp; Windows Phone Design Resources</h1>

<p>Everything worth reading about the Metro design language, gathered in one place.
The official Microsoft docs are mostly dead links now, so wherever possible these
point at Wayback Machine captures — primary sources, not someone's retelling of them.</p>

<h2 class="accent-bar">Primary sources (Microsoft, archived)</h2>

<table>
  <thead><tr><th>Document</th><th>What it is</th></tr></thead>
  <tbody>
    <tr>
      <td><a href="https://web.archive.org/web/20101115052944/http://download.microsoft.com/download/F/F/C/FFCF79B1-C2EB-42C2-8E2D-665705380DA0/Windows%20Phone%20Design%20System%20-%20Codename%20Metro.PDF">Windows Phone Design System — Codename "Metro" (PDF)</a></td>
      <td>The 2010 internal-style design document that introduced Metro publicly. The closest thing to a founding text. Captured November 2010.</td>
    </tr>
    <tr>
      <td><a href="http://tableless.github.io/exemplos/pdf/guidelines-interface-mobiles/UI%20Design%20and%20Interaction%20Guide%20for%20Windows%20Phone%207%20v2.0.pdf">UI Design and Interaction Guide for Windows Phone 7 v2.0 (PDF)</a></td>
      <td>July 2010, ~90 pages of prescriptive guidance: tiles, pivot/panorama rules, app bar, typography, animation. The practical handbook every WP7 designer used.</td>
    </tr>
    <tr>
      <td><a href="https://web.archive.org/web/20121009185343/http://www.microsoft.com/design/toolbox/tutorials/windows-phone-7/metro/">.toolbox — Design Language of Windows Phone 7</a></td>
      <td>Microsoft's own interactive design tutorial series, captured October 2012.</td>
    </tr>
    <tr>
      <td><a href="https://web.archive.org/web/20130522125028/http://windowsphonemetro.com/2011/07/11/a-walkthrough-the-history-of-the-metro-ui/">A Walkthrough the History of the Metro UI</a></td>
      <td>Microsoft-run Windows Phone Metro site tracing the lineage from signage/Zune to WP7. Captured May 2013.</td>
    </tr>
    <tr>
      <td><a href="https://learn.microsoft.com/en-us/archive/blogs/africaapps/uxui-guidelines-for-windows-phone">UX/UI Guidelines for Windows Phone (archived blog)</a></td>
      <td>Surviving summary of the WP8-era guidelines on Microsoft Learn's archive.</td>
    </tr>
    <tr>
      <td><a href="https://web.archive.org/web/*/msdn.microsoft.com/library/windows/apps/hh465424.aspx">UX guidelines for Windows Store apps (MSDN, Wayback)</a></td>
      <td>The Windows 8-era continuation of the same design language. Search the capture index for hh465424.</td>
    </tr>
  </tbody>
</table>

<h2 class="accent-bar">Typography</h2>
<ul>
  <li><a href="https://github.com/microsoft/Selawik">Selawik</a> — Microsoft's open-source,
  metrically-compatible Segoe UI replacement (SIL OFL). This is the font strategy this
  project uses: identical metrics, no licensing problem.</li>
  <li><a href="https://learn.microsoft.com/en-us/typography/font-list/segoe-ui">Segoe UI spec</a> —
  the official character/spec reference on Microsoft Learn.</li>
  <li><a href="https://www.smashingmagazine.com/2015/11/using-system-ui-fonts-practical-guide/">Using
  UI System Fonts (Smashing Magazine)</a> — practical context on Segoe's role among system fonts.</li>
</ul>

<h2 class="accent-bar">Icons &amp; assets</h2>
<ul>
  <li><a href="https://www.benday.com/blog/list-of-standard-icons-for-windows-phone-7-wp7">List of
  standard WP7 app bar icons</a> — the canonical glyph set with names.</li>
  <li><a href="https://blogs.windows.com/windowsdeveloper/2010/07/27/windows-phone-7-design-resources-ui-guide-and-design-templates/">WP7
  Design Templates announcement</a> — points at the official PSD/AI template kits Microsoft shipped.</li>
</ul>

<h2 class="accent-bar">History &amp; analysis</h2>
<ul>
  <li><a href="https://en.wikipedia.org/wiki/Metro_(design_language)">Wikipedia: Metro (design
  language)</a> — the best single overview with a dense reference list; start here.</li>
  <li><a href="https://davidvkimball.com/posts/zunes-design-language-and-how-it-evolved-into-windows-phone">Zune's
  Design Language and How It Evolved into Windows Phone</a> — the pre-WP7 origin story.</li>
  <li><a href="https://medium.com/mossyblog/the-principles-of-microsoft-metro-ui-decoded-e52fa8bf9f4c">The
  principles of Microsoft Metro UI decoded</a> — community breakdown of the core principles.</li>
  <li><a href="https://spaceforfreedom.wordpress.com/2012/01/07/metro-ui-a-brief-story/">Metro UI —
  A Brief Story</a> — contemporary 2012 account.</li>
</ul>

<h2 class="accent-bar">Community recreations</h2>
<ul>
  <li><a href="https://github.com/god-s-perfect-idiot/MetroUIrevival">MetroUIrevival</a> —
  curated Metro-styled resources for Android.</li>
  <li>A Jetpack Compose kit recreating WP8 (panorama, pivot, live tiles, LongListSelector) exists
  on GitHub under the <code>windows-phone</code> topic — proof this nostalgia has legs beyond Flutter.</li>
</ul>

<blockquote>
  Know a dead link I should replace with a Wayback capture, or a resource missing
  from this list? Open a PR — this page is meant to be the definitive index.
</blockquote>

<p class="lead">This page seeds the <a href="{{ '/essays/' | relative_url }}">Essays</a> research:
the annotated-primary-sources essay will build directly on what's collected here.</p>
