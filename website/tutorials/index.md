---
title: "Tutorials"
nav_order: 3
has_children: true
has_toc: false
permalink: /tutorials/
description: "Worked, step-by-step tutorials for network analysis in Stata, by package: from installing nwcommands to statistical models of networks."
---

# Tutorials
{: .no_toc }

Each tutorial explains an idea in plain words, runs a real Stata command and shows the output. Each one also stands
alone.

**New to network analysis in Stata?** Start with [Tutorial 1: Installation and setup](01-installation-setup/) and
read on from there.

## The core: nwcommands

| Group | Tutorials | What you learn |
|---|---|---|
| [First steps](nwcommands-first-steps/) | 1 to 7 | Install, import your data, draw, generate and change networks |
| [Describing networks](nwcommands-describing/) | 8 to 14 | Centrality, paths, groups, positions, homophily |
| [More topics](nwcommands-more/) | 15 to 21 | Two-mode, valued and changing networks, testing, Mata |

## Statistical models

Each kind of model has its own package. Choose by the data you have:

| Your data | Your question | Tutorials |
|---|---|---|
| One network, observed once | Which patterns of ties build it? | [nwergm: exponential random graph models](nwergm/) |
| One network, observed once | Who would be close on a map of the network? | [nwlsm: latent space models](nwlsm/) |
| One network, observed once | Which groups of actors have similar ties? | [nwsbm: stochastic block models](nwsbm/) |
| A network and a yes/no outcome of its actors | Do partners tend to share the outcome? | [nwalaam: actor attribute models](nwalaam/) |
| A network observed in two or more waves | How did it change? | [nwsaom: stochastic actor-oriented models](nwsaom/) |
| Time-stamped events between actors | What drives which event comes next? | [nwrem: relational event models](nwrem/) |
| Time-stamped events between actors | Who acts next, and whom do they choose? | [nwdynam: dynamic network actor models](nwdynam/) |

Not sure? See [Which package do I need?](../which-package/). To look up a single command, use the
[command reference](../reference/).

## Reference pages that go with the tutorials

[Valued networks](/nwcommands/valued-networks/), [two-mode networks](/nwcommands/two-mode/) and
[network types](/nwcommands/network-types/) (what every command does with each kind of network).
