---
title: "Which package do I need?"
nav_order: 2
permalink: /which-package/
description: "Choose between nwcommands (core), nwsaom, nwergm, nwdynam, nwrem, nwalaam, nwlsm and nwsbm by the kind of network data you have and the question you ask."
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
| One network, observed once, with a yes/no outcome on the actors (smoking, adoption, a side taken) | Why do these actors have the outcome, given the network around them? | [nwalaam](../nwalaam/) (ALAAM) |
| One network, observed once | Where do the actors lie, if the network is a map in which close actors are tied? | [nwlsm](../nwlsm/) (latent space model) |
| One network, observed once | Which actors play the same role, and how do the roles connect? | [nwsbm](../nwsbm/) (stochastic block model) |

All seven model packages need the core. The core is where you import, prepare and describe the data,
so most projects start there. If your network is large, see [how large a network can be](../nwcommands/size-limits/).

## Latent space, block model or ERGM?

Three of the packages describe the same kind of data, one network observed once, and answer different questions. In plain words:

- **ERGM ([nwergm](../nwergm/))** explains *which local patterns* build the network: reciprocity, triangles, homophily on an attribute, a few hubs. Each pattern gets a coefficient that you can interpret and test. Choose it when you have a hypothesis about how ties form.
- **Latent space model ([nwlsm](../nwlsm/))** gives every actor a *position* on a hidden map and says that close actors are likely to be tied. It describes clustering and transitivity through the map rather than through counts of triangles, and the map is a picture you can look at. Choose it when you want to see the structure of the network and a measure of how far apart actors are.
- **Stochastic block model ([nwsbm](../nwsbm/))** sorts the actors into *blocks* with the same pattern of ties and tells you how likely ties are within and between blocks. Choose it when you want roles (core and periphery, hubs and leaves, two sides that only tie across), or a partition of the actors with the number of groups chosen by a criterion. Blocks are not the same as communities.

They can be combined: a block model or a latent space can serve as a description before you fit an ERGM, and `nwcompare` of the core compares the fit statistics of stored models, with the caution that criteria of different model families are not always comparable. None of the three says anything about change over time; for that see nwsaom, nwdynam and nwrem.

## If you know the R packages

| R package | Stata package | Section |
|---|---|---|
| RSiena | nwsaom | [nwsaom and RSiena](../nwsaom/rsiena/) |
| `ergm` (statnet) | nwergm | [nwergm](../nwergm/) |
| `goldfish` | nwdynam | [nwdynam and goldfish](../nwdynam/r-goldfish/) |
| `relevent` | nwrem | [nwrem and relevent](../nwrem/r-relevent/) |
| ALAAMEE (Python), MPNet | nwalaam | [nwalaam](../nwalaam/) |
| `latentnet` | nwlsm | [nwlsm](../nwlsm/) |
| `sbm`, `blockmodels`, `greed` | nwsbm | [nwsbm](../nwsbm/) |

Each Stata package follows its R package (nwalaam: ALAAMEE, a Python program) and is not a replacement for it. The R package is the
reference implementation and the more complete program; each section says what is the same, what
differs and what is missing.

## Install

The simplest way is `nwinstall, everything`, which installs the core and all seven model packages (requires
Stata 17 or later; see [Installation](../nwcommands/install/)). To install the core and then only the model
package you need, see the Install page in each package's section.

## Longitudinal models side by side

For a first comparison of nwsaom, nwdynam and nwrem on the same kind of data, see
[Intro to Longitudinal Network Models](../tutorials/19-intro-longitudinal-models/).

## The packages and their versions

nwcommands is a family of eight packages. The core handles networks (138 commands and 130 dialog boxes).
Seven model packages build on it. They are installed separately, and each follows an established program
(an R package, or for nwalaam the Python program ALAAMEE) without replacing it. The core and all seven model packages are free software under the GNU
General Public License, version 3.

| Package | What it does | Follows | Version |
|---|---|---|---|
| [**nwcommands**](../nwcommands/) (core) | Import, generate, describe, analyze and plot networks | | 3.35.1 |
| [**nwsaom**](../nwsaom/) | Stochastic actor-oriented models (SAOM) for network panels ([Manual](https://doi.org/10.5281/zenodo.23623807)) | R package RSiena | 1.9.1 |
| [**nwergm**](../nwergm/) | Exponential random graph models (ERGM) for one network ([Manual](https://doi.org/10.5281/zenodo.23661331)) | R package `ergm` (statnet) | 1.13.0 |
| [**nwdynam**](../nwdynam/) | Dynamic network actor models (DyNAM) for event data ([Manual](https://doi.org/10.5281/zenodo.24398099)) | R package `goldfish` | 1.11.0 |
| [**nwrem**](../nwrem/) | Relational event models (REM) for event data ([Manual](https://doi.org/10.5281/zenodo.24398012)) | R package `relevent` | 1.7.0 |
| [**nwalaam**](../nwalaam/) | Autologistic actor attribute models (ALAAM) for a binary outcome on the actors of one network ([Manual](https://doi.org/10.5281/zenodo.24397901)) | ALAAMEE (Python) and MPNet |1.4.0 |
| [**nwlsm**](../nwlsm/) | Latent space models for the ties of a network, and for social influence ([Manual](https://doi.org/10.5281/zenodo.24398243)) | R package `latentnet` |1.0.6 |
| [**nwsbm**](../nwsbm/) | Stochastic block models and latent block models: which actors play the same role ([Manual](https://doi.org/10.5281/zenodo.24398296)) | R packages `sbm`, `blockmodels` and `greed` |1.0.2 |
