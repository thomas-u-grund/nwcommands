---
title: "nwintro"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
---

# `nwintro`

## Contents

**SectionDescription**

- hline 46
- [**[NW-1.1]****Introduction**](nwintro)
- [**[NW-1.2]****Required software**](nwintro)
- [**[NW-1.3]****Network concepts similar to Stata**](nwintro)
- [**[NW-1.4]****Network commands similar to Stata**](nwintro)
- [**[NW-1.5]****Statistical network models**](nwintro)
- [**[NW-1.6]****Questions, bugs and getting involved**](nwintro)
- [**[NW-1.7]****Citation**](nwintro)
- [**[NW-1.8]****Network size and speed**](nwintro)

## Introduction

nwcommands brings network analysis to Stata. Tutorials, data sets, manuals and news are at

browse "https://nwcommands.org"

Network analysis studies the relationships (ties) between units, such as friendship, advice or trust between people, or alliances between organizations, and the structure that these relationships form together. It is not limited to social units: any relational data, from genes to words, can be analyzed as a network. Unlike most statistical approaches, network analysis treats the dependence between units as the object of study.

A network G = (V,E) is a set of nodes *V* and a set of ties *E* between pairs (dyads) of nodes *i* and *j*. It can be stored as an adjacency matrix *M* with one row and one column per node: *M_ij* = 0 when there is no tie from *i* to *j*, and *M_ij* = 1 (or, in a valued network, the value of the tie) when there is one.

The core package [nwcommands](nwcommands) has 138 commands. They [import, export, load and save](nwtopical), [generate](nwtopical), [manipulate](nwtopical), [describe](nwtopical), [analyze](nwtopical) and [plot and animate](nwtopical) networks: centrality, cohesion and subgroups, communities, positions and roles, paths and flows, homophily and mixing, and tests such as QAP and conditional uniform graph tests. You can also write your own [network commands](nwprogramming).

A minimal example, which loads a real network and computes degree centrality:

```stata
. nwwebuse florentine, nwclear
. nwdegree flomarriage, generate(deg)
. list _nwnode deg in 1/5
```
See [nwstart](nwstart) for a full, hands-on walkthrough.

Networks are held by nwcommands, not in the Stata dataset: Stata's `clear` does not remove them, [nwclear](nwclear) does.

## Required software

Stata 17 or later. The commands are tested on macOS with Stata 17, 18 and 19 and on Windows with Stata 19. The Mata library is built with Stata 17, because a library built by a newer Stata is ignored by older versions; Stata 16 and older are not supported.

The core commands need nothing beyond Stata and the files of this package: no package from SSC, no internet connection after installation, and nothing is installed into your PLUS directory without your asking. The compiled plugins for macOS, Windows and Linux are installed with the package.

## Network concepts similar to Stata

nwcommands mirrors many concepts of Stata. The most important ones and their Stata counterparts are:

- hline 14c TThline 16c TThline 31
- c | Stata c | nwcommands c | Description c |
- hline 14c +hline 16c +hline 31
- c | `varname` c | [netname](netname) c | Name of existing network c |
- c | `newvarname` c | [newnetname](newnetname) c | Name of new network c |
- c | `varlist` c | [netlist](netlist) c | List of networks c |
- c | `exp` c | [netexp](netexp) c | Network expression c |
- c | `dta_examples` c | [netexample](netexample) c | Example network data c |
- hline 14c BThline 16c BThline 31

For example, many commands accept a [netname](netname) as an argument or option, just as Stata commands accept a `varname`. Network lists can be abbreviated like `variable lists`.

## Network commands similar to Stata

Many commands work like the Stata commands they are named after. The full list of commands is in [the topical list](nwtopical).

- hline 14c TThline 16c TThline 31
- c | Stata c | nwcommands c | Description c |
- hline 14c +hline 16c +hline 31
- c | `clear` c | [nwclear](nwclear) c | Clear all network data c |
- c | `drop` c | [nwdrop](nwdrop) c | Drop networks from memory c |
- c | `keep` c | [nwkeep](nwkeep) c | Keep networks in memory c |
- c | `use` c | [nwuse](nwuse) c | Use network data c |
- c | `webuse` c | [nwwebuse](nwwebuse) c | Use network data from internetc |
- c | `save` c | [nwsave](nwsave) c | Save network data c |
- c | `generate` c | [nwgenerate](nwgenerate) c | Generate networks c |
- c | `egen` c | [nwgen](nwgen) c | Advanced network generation c |
- c | `replace` c | [nwreplace](nwreplace) c | Replace networks c |
- c | `recode` c | [nwrecode](nwrecode) c | Recode networks c |
- c | `summarize` c | [nwsummarize](nwsummarize) c | Summarize networks c |
- c | `unab` c | [nwunab](nwunab) c | Unabbreviate network lists c |
- c | `ds` c | [nwds](nwds) c | List networks c |
- c | `tabulate` c | [nwtabulate](nwtabulate) c | Tabulate networks c |
- c | `correlate` c | [nwcorrelate](nwcorrelate) c | Correlate networks c |
- c | `expand` c | [nwexpand](nwexpand) c | Expand variable to network c |
- c | `syntax` c | [_nwsyntax](nwprogramming) c | Parse network syntax c |
- hline 14c BThline 16c BThline 31

## Statistical network models

The statistical models for networks are separate packages that build on `nwcommands`: `nwsaom` (stochastic actor-oriented models), `nwergm` (exponential random graph models), `nwdynam` (dynamic network actor models), `nwrem` (relational event models), `nwalaam` (autologistic actor attribute models), `nwlsm` (latent space models) and `nwsbm` (stochastic block models). Install them with `nwinstall, models`; [nwversion](nwversion) shows which are installed. Which package you need is explained at browse "https://nwcommands.org/which-package/".

## Questions, bugs and getting involved

Ask questions in the GitHub Discussions of the package, and report errors, wrong results and feature requests as GitHub issues:

browse "https://github.com/thomas-u-grund/nwcommands/discussions"break browse "https://github.com/thomas-u-grund/nwcommands/issues"

New releases and workshops are announced on the nwcommands mailing list, browse "https://groups.google.com/g/nwcommands". If you want to contribute to the software, start with the repository, browse "https://github.com/thomas-u-grund/nwcommands", or write to [thomas.u.grund@gmail.com](mailto:thomas.u.grund@gmail.com).

## Citation

Please cite the package and the version you used ([nwversion](nwversion) prints it):

Grund, T. U. (2026). *nwcommands: Network Analysis in Stata* (version *x.y.z*) [Computer software]. browse "https://github.com/thomas-u-grund/nwcommands"

How to cite the model packages is explained at browse "https://nwcommands.org/citing/".

## Network size and speed

How large a network you can use depends on what you do with it. Commands that work on the stored ties need memory in proportion to the number of ties; commands whose work or result is an *n*-by-*n* matrix need memory in proportion to the square of the number of nodes. Up to 9999 networks can be in memory at once.

The web page [How large a network can I analyze?](https://nwcommands.org/nwcommands/size-limits/) lists, command by command, which commands are comfortable, workable or refused at 1,000 to 100,000 nodes. The help file of each command states its own limits.

## Commands that work on the ties

Among others, [nwfromedge](nwfromedge), `nwset, edgelist`, [nwimport](nwimport) type(edgelist), [nwdegree](nwdegree), [nwcomponents](nwcomponents), [nwclustering](nwclustering), [nwneighbor](nwneighbor), [nwevcent](nwevcent), [nwpagerank](nwpagerank), [nwrandomwalk](nwrandomwalk), [nwmaxflow](nwmaxflow), [nwmatching](nwmatching), [nwtriads](nwtriads), [nwburt](nwburt), [nwsimmelian](nwsimmelian), and [nwtoedge](nwtoedge) with `compress` do not build an *n*-by-*n* matrix.

## Commands that need the full adjacency matrix

The matrix is not built above 20,000 nodes; in practice these commands are comfortable at a few thousand nodes. At 100,000 nodes, commands with an *n*-by-*n* result or matrix ([nwgeodesic](nwgeodesic), [nwreach](nwreach), [nwlambda](nwlambda), [nwexpand](nwexpand), [nwcontext](nwcontext), [nwsimilar](nwsimilar), [nwdissimilar](nwdissimilar), [nwsimindex](nwsimindex), [nwcorrelate](nwcorrelate), [nwqap](nwqap), [nwutility](nwutility), [nwspectral](nwspectral), [nwconcor](nwconcor), [nwhierarchy](nwhierarchy), [nwplotmatrix](nwplotmatrix), [nwtomata](nwtomata), [nwtostata](nwtostata)) stop with r(484), a message and an alternative.

Further limits:

- [nwspectral](nwspectral), [nwconcor](nwconcor), [nwhierarchy](nwhierarchy) and [nwdendrogram](nwdendrogram): running time grows steeply with the number of nodes; refused above 6,000 nodes unless `force` is given.
- [nwcorrelate](nwcorrelate) of the nodes of one network: refused above 7,000 nodes.
- [nwhomophily](nwhomophily), [nwcollapse](nwcollapse), and [nwtoedge](nwtoedge) and [nw2toedge](nw2toedge) without `compress` (one row per dyad): refused above 50,000,000 dyads (7,071 nodes for a directed network).
- [nwplotmatrix](nwplotmatrix): refused above 2,500 nodes.
- [nwbetween](nwbetween), [nwcloseness](nwcloseness), [nwkatz](nwkatz), [nwkcomponents](nwkcomponents) and [nwcohesion](nwcohesion) stop with r(484) on very large networks when the run would be long; their help files give the rules.
- Commands that would need more than 12 GB for a dense result stop with r(484).
- Two-mode networks are one matrix over both modes and are refused above 20,000 nodes in total.

Where a command offers the option `force`, it runs in spite of such a guard. [nwtostata](nwtostata) needs one Stata variable per node and is limited by the number of variables of your Stata flavor.

## Cohesion, factions, motifs, connectivity and exhaustive subgroup searches

[nwcohesion](nwcohesion), [nwfactions](nwfactions), [nwlambda](nwlambda), [nwmotifs](nwmotifs), [nwclustering](nwclustering) (on a two-mode network) and [nwinduced](nwinduced) with `measure(degree)` run in compiled code on the list of ties (the result of [nwlambda](nwlambda) is itself a dense *n*-by-*n* network). `nwinduced` with betweenness, closeness or eigenvector centrality recomputes the measure for every node left out and is slow already at a few hundred nodes.

[nwkplex](nwkplex), [nwnclique](nwnclique) and [nwnclan](nwnclan) list *all* maximal subgroups, and the number of those, not the number of nodes, decides what is feasible: it can reach millions in a network of 100 nodes. These commands stop with a message (r(484)) when they find more than `maxplexes()` / `maxcliques()` sets (default 100,000), when the matrix would be too large, or after `maxtime()` seconds (default 60); `countonly` counts the sets without storing them and `nomatrix` keeps only the per-node variable and the counts.

## Loading a network as Stata variables

[nwload](nwload) (and the `xvars` option many [network generators](nwtopical) accept) represents a network as ordinary Stata variables, one per node, in a wide adjacency-matrix layout. This is bounded by Stata's own variable-count ceiling (**c(max_k_theory)** - varies by your Stata flavor: for example, a few thousand in Small Stata, far more in Stata/IC, BE, or MP), not by anything this package imposes. `nwload` itself will not materialize a network above 1000 nodes this way unless `force` is specified, since doing so routinely for large networks is rarely what you want.

Crucially, loading a network as Stata variables is **not** required to analyze it - every [netname](netname)-based command works directly against the network's own internal representation, with or without any Stata variables present. By default, network generators do **not** load their result as Stata variables at all (only `xvars` does this on request) - so building and analyzing a 50,000-node network's own structure never has to touch Stata's variable budget in the first place, as long as you never ask a command to also load it. [nwload](nwload) is still there for the cases that genuinely call for it - inspecting individual tie values directly, or feeding a network's data into ordinary Stata commands.

These limits do not cover every shape of network; the help file of a command is the authority on it.

---

*nwcommands version 3.37.1, 25 November 2026* ([check your installed version](nwversion))
