---
layout: default
title: About
---

<h1>About this project</h1>

<p><strong>wp_pivot_flutter</strong> started in 2020 as a weekend experiment: a
Flutter implementation of the Windows Phone Pivot tab bar. It worked, it was fun,
and then it sat still for six years. In 2026 it came back from the dead with a
bigger mission: recreate the whole Windows Phone design language, properly this
time, with a rooted Lumia 1020 as the source of truth.</p>

<h2>Why hardware?</h2>
<p>Because screenshots lie. They can't tell you how long a transition takes, what
easing curve a flick follows, or how a tile tilts when you press it. Most
"Metro-inspired" kits guess at these things, and you can feel the guessing.
With root access on the 1020 I can go one better than screen recording: pull the
accent definitions, font metrics and animation resources straight off the OS, then
check my pixel-level conclusions against both sources independently. When the
screen capture and the OS resources agree, you can trust the number.</p>

<h2>Honest limits</h2>
<p>Bit-exact rendering across display pipelines has physical limits. The bar here
is "indistinguishable to a human": roughly 95%+ overlap in the automated diffs.
I'd rather publish that number and let you judge than claim pixel perfection.</p>

<h2>How to contribute</h2>
<ul>
  <li><strong>Own Windows Phone hardware?</strong> Capture sessions following the
  media policy. Different builds and devices make the research stronger; my 1020
  can't be the only witness.</li>
  <li><strong>Can implement?</strong> Pick up any issue tagged with a published
  spec and build against it.</li>
  <li><strong>Have footage or memories?</strong> The Essays section keeps the
  platform's story alive. Primary sources very welcome.</li>
</ul>

<h2>Scope &amp; non-goals</h2>
<p>The goal is fidelity to the <em>feel</em> of Windows Phone. Redistributing
Microsoft's IP is not: Segoe fonts are referenced and substituted with
metric-compatible alternatives, never bundled, and artwork stays Microsoft's.</p>

<p>Everything happens in the open:
<a href="{{ site.github_repo }}">github.com/Chinmay-KB/wp_pivot_flutter</a>.</p>
