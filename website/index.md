---
title: Home
nav_order: 1
description: "nwcommands: network analysis for Stata. Import, generate, describe, analyze and plot networks; fit statistical network models with the companion packages nwsaom (SAOM), nwergm (ERGM), nwdynam (DyNAM), nwrem (REM), nwalaam (ALAAM), nwlsm (latent space models) and nwsbm (stochastic block models)."
permalink: /
---

<h1><img src="{{ '/assets/images/nwcommands-logo.png' | relative_url }}" alt="nwcommands" width="480"></h1>

Network analysis in Stata: import, generate, describe, analyze and plot networks, and fit statistical
network models, from the Stata command line or from dialog boxes.
{: .fs-6 .fw-300 }

[Start here](start/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Tutorials](tutorials/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Command reference](reference/){: .btn .fs-5 .mb-4 .mb-md-0 }

<div class="home-figs">
  <figure>
    <a href="{{ '/start/' | relative_url }}"><img src="{{ '/assets/images/start/florentine.png' | relative_url }}" alt="Plot of the marriage ties among 16 Florentine families"></a>
    <figcaption>Marriage ties among Florentine families, drawn with <code>nwplot</code></figcaption>
  </figure>
  <figure>
    <a href="{{ '/tutorials/05-visualization/' | relative_url }}"><img src="{{ '/tutorials/05-visualization/interactive_pictograms.png' | relative_url }}" alt="Interactive plot of an advice network with pictograms for men and women"></a>
    <figcaption>An interactive plot with pictograms (<code>nwplot, interactive</code>)</figcaption>
  </figure>
</div>

## What's new

- **Workshops:** two workshops are planned for Sunbelt 2027 in Montreal. To organize one elsewhere, get in touch: see [Teaching and workshops](teaching/).
- **For instructors:** [slides, course outlines and a workshop](teaching/).
- **For readers of the book:** [do-files and an exercise bank](book/).

[All news](news/) · [Release notes](releases/)

## The packages
{: #the-packages }

<div class="pkg-grid">
  <a class="pkg-card" href="{{ '/nwcommands/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwcommands.png' | relative_url }}" alt="nwcommands" width="228" height="50"></span>
    <span class="pkg-card-text">The core: import, describe, analyze and plot networks</span>
  </a>
  <a class="pkg-card" href="{{ '/nwergm/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwergm.png' | relative_url }}" alt="nwergm" width="140" height="50"></span>
    <span class="pkg-card-text">Exponential random graph models (ERGM)</span>
  </a>
  <a class="pkg-card" href="{{ '/nwsaom/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwsaom.png' | relative_url }}" alt="nwsaom" width="167" height="50"></span>
    <span class="pkg-card-text">Stochastic actor-oriented models (SAOM)</span>
  </a>
  <a class="pkg-card" href="{{ '/nwdynam/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwdynam.png' | relative_url }}" alt="nwdynam" width="203" height="50"></span>
    <span class="pkg-card-text">Dynamic network actor models (DyNAM)</span>
  </a>
  <a class="pkg-card" href="{{ '/nwrem/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwrem.png' | relative_url }}" alt="nwrem" width="129" height="50"></span>
    <span class="pkg-card-text">Relational event models (REM)</span>
  </a>
  <a class="pkg-card" href="{{ '/nwalaam/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwalaam.png' | relative_url }}" alt="nwalaam" width="168" height="50"></span>
    <span class="pkg-card-text">Autologistic actor attribute models (ALAAM)</span>
  </a>
  <a class="pkg-card" href="{{ '/nwlsm/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwlsm.png' | relative_url }}" alt="nwlsm" width="127" height="50"></span>
    <span class="pkg-card-text">Latent space models</span>
  </a>
  <a class="pkg-card" href="{{ '/nwsbm/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwsbm.png' | relative_url }}" alt="nwsbm" width="140" height="50"></span>
    <span class="pkg-card-text">Stochastic block models</span>
  </a>
</div>

## Install

```stata
. net install nwcommands, from(https://nwcommands.org/net/) replace
. nwinstall, everything
```

Needs Stata 17 or later; Stata BE is enough. New here? [Start here](start/) takes you from installation to your
first network, then to your own data.
