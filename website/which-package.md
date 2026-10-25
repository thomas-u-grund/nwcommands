---
title: "Which package do I need?"
nav_order: 2
permalink: /which-package/
description: "Choose between nwcommands (core), nwsaom, nwergm, nwdynam and nwrem by the kind of network data you have and the question you ask."
---

# Which package do I need?
{: .no_toc }

Pick by your data and your question.

| Your data | Your question | Package |
|---|---|---|
| Any network, descriptive questions | Centrality, components, cohesion, plots, import and export | [nwcommands](../nwcommands/) (core) |
| One network, observed once | Which ties are likely, given degree, reciprocity, triangles and node attributes? | [nwergm](../nwergm/) (ERGM) |
| The same actors observed at two or more waves (a panel) | How and why did the network change? Selection or influence? | [nwsaom](../nwsaom/) (SAOM) |
| Timestamped events (e-mails, calls), ordered by time | Who acts next, and whom do they choose, given the history? | [nwdynam](../nwdynam/) (DyNAM) |
| Timestamped events (e-mails, calls), ordered by time | Why this sender and this receiver at each event? | [nwrem](../nwrem/) (REM) |

All four model packages need the core. The core is where you import, prepare and describe the data,
so most projects start there. If your network is large, see [how large a network can be](../nwcommands/size-limits/).

## If you know the R packages

| R package | Stata package | Section |
|---|---|---|
| RSiena | nwsaom | [nwsaom and RSiena](../nwsaom/rsiena/) |
| `ergm` (statnet) | nwergm | [nwergm](../nwergm/) |
| `goldfish` | nwdynam | [nwdynam and goldfish](../nwdynam/r-goldfish/) |
| `relevent` | nwrem | [nwrem and relevent](../nwrem/r-relevent/) |

Each Stata package follows its R package and is not a replacement for it. The R package is the
reference implementation and the more complete program; each section says what is the same, what
differs and what is missing.

## Install

The core first, then the model package you need: see [Installation](../nwcommands/install/), or the
Install page in each package's section.

## Longitudinal models side by side

For a first comparison of nwsaom, nwdynam and nwrem on the same kind of data, see
[Intro to Longitudinal Network Models](../tutorials/10-intro-longitudinal-models/).
