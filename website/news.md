---
title: "Releases and news"
nav_order: 12
description: "Dated list of releases of nwcommands, nwsaom, nwergm, nwdynam and nwrem, and changes to this site."
permalink: /news/
---

# Releases and news
{: .no_toc }

Newest first. Announcements also go to the [nwcommands mailing list](https://groups.google.com/g/nwcommands). The full change history of each package is in its `CHANGELOG`, and every release has notes on GitHub.

All releases: [nwcommands](https://github.com/thomas-u-grund/nwcommands/releases), [nwsaom](https://github.com/thomas-u-grund/nwsaom/releases), [nwergm](https://github.com/thomas-u-grund/nwergm/releases), [nwdynam](https://github.com/thomas-u-grund/nwdynam/releases), [nwrem](https://github.com/thomas-u-grund/nwrem/releases).

## 26 October 2026: nwergm 1.3.1

**nwergm 1.3.1: corrections** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.3.1)). No estimate changes.

- **`estat mcmcdiag`.** With `quietly` the command now prints nothing (a stray row was printed before). The header shows the thinning interval of the final sample and, when the adaptive sampler spaced the draws further apart than requested, a line `Requested interval`. The note at the end of the report now advises `mcmleeffectivesize()` (and `mcmcsamplesize()` or `mcmcinterval()` for fixed-size samples).
- **Documentation.** The README is updated and the manual for the 1.3 series is in the repository. The speed statement is corrected: on the eight benchmark models nwergm 1.3 is 2.9 to 9.4 times faster than R's `ergm` 4.12.0, and 1.2.3 was slower than R on six of the eight.

## 26 October 2026: nwergm 1.3.0

**nwergm 1.3.0: faster, R's sampling defaults** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.3.0)). It works with nwcommands 3.6.0 and later.

- **Results that change slightly.** The default Monte Carlo maximum likelihood fit now uses R's adaptive sample size and R's convergence test (as in `ergm`'s `MCMLE.effectiveSize` and its default termination), instead of a fixed 3,000 draws per iteration. A default fit therefore uses different draws and its estimates differ a little from those of 1.2.x. Over 20 seeds the mean estimates agree with R's within 0.04 of an R standard error on five models. The option `mcmleeffectivesize(0)` restores the algorithm of 1.2.3.
- **Faster.** On the eight benchmark models, nwergm is 2.9 to 9.4 times faster than R's `ergm` 4.12.0 (median of seven fits, same networks, default settings, R and nwergm run in turn, one fit at a time, on an idle machine; 1.2.3 was slower than R on six of the eight). Your times depend on the model and the machine. The compiled sampling kernels are faster, and the Windows plug-in is built with optimisation.

## 26 October 2026: nwdynam 1.2.0 and nwrem 1.0.10

- **nwdynam 1.2.0** ([release notes](https://github.com/thomas-u-grund/nwdynam/releases/tag/v1.2.0)). When the compiled plugin file is missing for your platform, a fit of the original structural effect set (choice and rate sub-models) now prints one warning line and runs on the slower Mata engine, as nwergm does; before, the fallback was silent. Results are unchanged.
- **nwrem 1.0.10** ([release notes](https://github.com/thomas-u-grund/nwrem/releases/tag/v1.0.10)). The speed statement in the help is replaced by timings of 26 October 2026 against R's relevent: the ratio of the times ranged from 0.75 to 36 over five effect sets and 200 to 20,000 events; nwrem is slower with the recency effects at up to 1,000 events. See [nwrem and R's relevent](/nwrem/r-relevent/). No change in results.

## 26 October 2026: valued layouts, faster similarities, two-mode nwcug

**nwcommands 3.10.0** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.10.0)). The four model packages are unchanged by this release (they work with it; their current versions are nwsaom 1.1.0, nwergm 1.2.4, nwdynam 1.1.4 and nwrem 1.0.9).

- **Results that change: plots of valued networks.** `nwplot` and `nwmovie` (layouts `kk` and `frucht`, the defaults) now use the tie values as strengths, as `igraph::plot()` does: strongly tied nodes lie closer together. The option `binary` restores the earlier positions. Binary networks, two-mode networks, signed networks and the other layouts are not affected.
- **`nwcug` works on two-mode networks** (it stopped with an error before) with four null models: density, the degrees of mode 1, of mode 2, or of both.
- **Faster:** `nwcorrelate` and `nwsimilar, type(pearson)` (24 times faster at 5,000 nodes, same numbers), the other types of `nwsimilar` and `nwdissimilar`, and `nwdissimilar, type(manhatten)` (minutes before). New: `nwcommunity, algorithm(dirtlpa)` for two-mode networks (the repeated label propagation of Beckett, 2016). The compiled plug-in has to be the new one: `nwinstall` fetches it; without it the commands give the same numbers, slowly (`algorithm(dirtlpa)` stops with a message).
- **Windows:** the compiled plug-in is built with optimisation, and all counters in it are 64 bits wide. The compiled kernels now also have a test that runs without Stata on Linux, macOS and Windows.

## 26 October 2026: nwsaom 1.1.0 and the manual for version 1.1

**nwsaom 1.1.0** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.1.0)). Works with nwcommands 3.6.0 and later; no new core needed.

- **A warning when `nwsaom` has to use the slow Mata engine.** If the compiled plugin cannot be used (its file is missing for your platform, it is older than the model needs, or the model is outside what the plugin covers), `nwsaom` now prints one line before the estimation starts that says why, as `nwergm` already did. Before, the fit ran for a very long time without a message. The results do not change.
- **Manual for version 1.1.** The nwsaom manual is relabelled and brought up to date: installation with `nwinstall`, the rule that tie values must be 0 or 1, the warning, and the changes of the releases since the last manual. It is archived at Zenodo under the same DOI of all versions, [doi:10.5281/zenodo.23623807](https://doi.org/10.5281/zenodo.23623807); cite it with that DOI and the exact package version from `nwsaom version`.

## 26 October 2026: the menu is installed once

**nwcommands 3.9.2** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.9.2)). The four model packages are unchanged by this release (they work with it; their current versions are nwsaom 1.0.11, nwergm 1.2.4, nwdynam 1.1.4 and nwrem 1.0.9).

- **`nwinstall, everything` (and `all`) set up the "Network Analysis" menu and the dialog boxes, and never twice:** the start-up line in `profile.do` is written once (the older `nwinstall, downloadoff` counts as the same line), a menu you built yourself is respected, and running the command again shows each entry once. New option `nogui` leaves the menu out; `nwinstall, dupcheck` lists dialog files that exist in two folders. `nwinstall, remove` now also removes the numbered packages. No command or result differs from 3.9.1.

## 26 October 2026: help files corrected

**nwsaom 1.0.11**, **nwergm 1.2.4**, **nwdynam 1.1.4** and **nwrem 1.0.9** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.2.4)). Help text and README only; no change in results, no new core needed (they work with nwcommands 3.6.0 and later).

- **nwergm:** the help file now describes the software as it is: the sampler, the change statistics and the pseudolikelihood design matrix run in a compiled plugin, the Mata implementation is a slow fallback used for tests and comparison, a valued network is fitted as the binary graph with one note, 125 of the 139 terms of `ergm` 4.12.0 are implemented, and the page range of Geyer and Thompson (1992) is 657-683. The timing ratios of an earlier benchmark are removed: speed relative to R depends on the model.
- **nwsaom, nwdynam, nwrem:** references to development scripts and internal notes removed from the help files; install lines in the README start with `nwinstall`.

## 26 October 2026: a short install address

**nwcommands 3.9.1** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.9.1)). The four model packages are unchanged (nwsaom 1.0.10, nwergm 1.2.3, nwdynam 1.1.3, nwrem 1.0.8 work with it).

- **The core now installs from a short address:** `net install nwcommands, from(https://nwcommands.org/net/) replace`, then `nwinstall, everything`. The long GitHub address (`https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/`) keeps working, and so do the tagged addresses of older releases. Nothing else changes: no command, result or plug-in differs from 3.9.0.

## 26 October 2026: plots show tie values, signs and the two modes

**nwcommands 3.9.0** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.9.0)). The four model packages are unchanged (nwsaom 1.0.10, nwergm 1.2.3, nwdynam 1.1.3, nwrem 1.0.8 work with it).

- **nwcommands 3.9.0. The default pictures of `nwplot`, `nwmovie` and `nwplotmatrix` change for valued, signed and two-mode networks, and `nwturnover` changes on two-mode networks; read the "Results that change" list in the [release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.9.0).**
  - *Valued networks.* `nwplot` draws the tie values as edge widths (`binary` gives the old picture). *Signed networks.* Positive ties are solid navy, negative ties dashed cranberry, with a legend (`nosign` gives the old colours); the width follows the absolute value. *Two-mode networks.* The two modes get different symbols and colours and a legend unless `color()` or `symbol()` is given.
  - *`nwplotmatrix`* has a colour legend by default and, for a two-mode network, groups the nodes by mode with a line between the modes. *`nwturnover`* on a two-mode network counts only the ties between the modes (the cells inside a mode were counted as ties present in both networks, so the counts and the Jaccard index were wrong).
  - *Also.* `nwdyadprob` with `density()` and neither a weight network nor `mat()` stops with a message; `nwaltergen, wmean` notes that the weights of a signed network keep their signs; `nwplot ... if ..., edgesize()` works. *Speed.* `nwgeodesic ..., force` on an unvalued network no longer takes the slow Mata route: 0.03 s instead of 37 s at 600 nodes, same distances.

## 26 October 2026: bipartite motifs, and a two-mode network gets its two-mode form

**nwcommands 3.8.0** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.8.0)). The four model packages are unchanged (nwsaom 1.0.10, nwergm 1.2.3, nwdynam 1.1.3, nwrem 1.0.8 work with it).

- **nwcommands 3.8.0. Results change for two-mode networks; read the "Results that change" list in the [release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.8.0).**
  - *A network declares itself two-mode, and the commands follow.* A command that has a two-mode form of the same concept uses it automatically on a two-mode network, and the option `onemode` gives the one-mode computation of the bipartite graph. `nwdegree`, `nwclustering` and `nwmotifs` use the two-mode degree, the two-mode clustering coefficients and the bipartite motifs; `nwcloseness` and `nwbetween` give the normalisations of Borgatti and Everett by default (`twomode` is still accepted). `nw2degree`, `nw2clustering` and `nw2motifs` remain as aliases with the same options and results. One-mode networks and calls with `onemode` give what 3.7.0 gave. The rule is explained on the page on [two-mode networks](/nwcommands/two-mode/).
  - *Bipartite motifs.* `nwmotifs` (and `nw2motifs`) on a two-mode network counts the 17 bipartite motifs of two to five nodes (44 with `sixnode`) of Simmons et al. (2019) and the positions of every node in them. The counts equal `bmotif` in R; on the 5,092 + 455 company directors the five-node set takes 0.04 s, where `bmotif` needs 54 s (see the [size page](/nwcommands/size-limits/)). Update the plugin with `nwinstall`.

## 26 October 2026: faster valued and two-mode commands, valued closeness at any size

**nwcommands 3.7.0** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.7.0)), **nwsaom 1.0.10** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.10)), **nwergm 1.2.3** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.2.3)), **nwdynam 1.1.3** ([release notes](https://github.com/thomas-u-grund/nwdynam/releases/tag/v1.1.3)), **nwrem 1.0.8** ([release notes](https://github.com/thomas-u-grund/nwrem/releases/tag/v1.0.8))

- **nwcommands 3.7.0. Results change in a few cases; read the "Results that change" list in the [release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.7.0).**
  - *Compiled kernels.* The weighted betweenness of `nwbetween` (1,000 nodes: 0.13 s instead of 111 s; 10,000 nodes 15 s), the two-mode community search of `nwcommunity` (27 times faster on the 5,092 + 455 company directors), the maximum-weight matching of `nwmatching` (the directors take 0.2 s; the Mata routine could not do it), the tie swapping of `nwpermute, swap` and the weighted walk of `nwpagerank` now run in the compiled plugin. Results equal the earlier code and R's `igraph`. The timings are on the [size page](/nwcommands/size-limits/). Update the plugin with `nwinstall`.
  - *Valued closeness at any size.* `nwcloseness` and `nwgeodesic` on a valued network of more than 100 nodes used to count steps silently; they now compute least-cost distances (1,000 nodes 0.15 s, 10,000 nodes 14 s). A platform whose plugin is not yet updated stops with error 198 unless `force` or `binary` is given.
  - *Two-mode level labels in files.* `nwexport` and `nwimport` keep the labels of the two modes (Pajek, GML, edge list); a rectangular UCINET matrix with equal numbers of rows and columns is read as a two-mode network.
  - *Fixes.* `nwshared` on a directed network now requires the option `undirected`, as its help says (error 198); the random starting orders of the two-mode search and of `nwpermute, swap` come from a generator of their own, so the same `set seed` gives the same result on every platform but not the draws of earlier versions; the error text of `nwinduced` is plain.
- **nwsaom 1.0.10, nwergm 1.2.3, nwdynam 1.1.3, nwrem 1.0.8.** Audit fixes; they work with nwcommands 3.6.0 and later. *nwsaom* refuses real shares in a network declared as 0/1 (as RSiena) and accepts a 0/1 network made with a value variable; *nwergm* fits a valued network as the binary graph, with one note (as `ergm` does), and `edgecov()` works with a two-mode covariate network; *nwdynam* `tie()` counts a tie only when its value is greater than 0 (as `goldfish`); *nwrem* refuses a two-mode `covevent()` network and missing tie values with a clear message. The messages that asked for a "native plugin of protocol N" now ask to update nwcommands and nwsaom.

## 26 October 2026: valued networks, two-mode networks, nwburt, nwinstall everything

**nwcommands 3.6.0** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.6.0)), **nwsaom 1.0.9** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.9)), **nwergm 1.2.2** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.2.2)), **nwdynam 1.1.2** ([release notes](https://github.com/thomas-u-grund/nwdynam/releases/tag/v1.1.2)) and **nwrem 1.0.7** ([release notes](https://github.com/thomas-u-grund/nwrem/releases/tag/v1.0.7)). **Update all five together:** the core Mata library changed, and a model package needs the core version that it was built against.

- **nwcommands 3.6.0. Results change; read the "Results that change" list in the [release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.6.0) before you re-run old analyses.**
  - *Valued networks.* A network is valued if it was created with tie values (`nwfromedge` with a value variable, an import with values, `nwset` from a matrix with other values than 0 and 1); the flag is no longer worked out again from the values. On a valued network the commands that have a weighted form in R now use the tie values by default (`nwdegree`, `nw2degree`, `nwgeodesic`, `nwcloseness`, `nwbetween`, `nwevcent`, `nwpagerank`, `nwrandomwalk`, `nwpath`, `nwmatching`, `nwassortativity`, `nwkatz`, `nwinduced`); the option `binary` gives the earlier result, and binary networks give the same results as before. See [Valued networks](/nwcommands/valued-networks/).
  - *Two-mode networks.* The flag, the modes and the level labels survive `nwdropnodes`, `nwkeepnodes`, `nwsubset` and the other commands that derive a network. Commands that cannot say anything about a two-mode network stop with one message (error 6088). `nwcommunity` and `nwmodularity` use Barber's bipartite modularity, `nwsimilar` and `nwdissimilar` compare nodes within a mode, `nwpermute` permutes within the modes, edge lists, Pajek, UCINET and GML files keep the modes, and there are new measures: `nw2nested`, `nw2clustering, ra`, `nw2project, stat(newman)`, `nw2degree, raw`. See [Two-mode networks](/nwcommands/two-mode/) and [the network types each command supports](/nwcommands/network-types/).
  - *nwburt on valued networks* now computes Burt's weighted measures, as `igraph` does; before, effective size could be negative. These measures run in the compiled plugin (a new plugin generation); `binary` ignores the values.
  - *Fixes to results:* standardised `nwdegree`, the betweenness centralisation, `nwcloseness` on a network that is not connected (now as in `igraph`, option `legacy` for the old values), Jaccard similarity, `nwutility` with `benefit()` and `cost()`, and `nwkatz` with extra observations.
  - *Install everything in one step:* `nwinstall, everything` installs the core and the four model packages. Stata 17 or later is required (tested with Stata 17 and 18; the Mata libraries are built with Stata 17). The data set `usair_full` (549 airports) is new; see [Data sets](/datasets/).
- **nwsaom 1.0.9, nwergm 1.2.2, nwdynam 1.1.2, nwrem 1.0.7.** Rebuilt for core 3.6.0; they need nwcommands 3.6.0 or later. No change in results.

## 25 October 2026 (late night): fix for Stata 17

**nwcommands 3.5.1** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.5.1)), **nwsaom 1.0.8** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.8)), **nwergm 1.2.1** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.2.1)), **nwdynam 1.1.1** ([release notes](https://github.com/thomas-u-grund/nwdynam/releases/tag/v1.1.1)) and **nwrem 1.0.6** ([release notes](https://github.com/thomas-u-grund/nwrem/releases/tag/v1.0.6)). **If you use Stata 17, update all five.** The Mata libraries of the releases earlier today were built with Stata 18 and Stata 17 ignored them (`nws_create() not found`, r(3499)). They are now built with Stata 17, which works in Stata 17 and 18. nwcommands is tested with Stata 17 and 18; older versions are not tested. The core prints a clear message with the reinstall steps when the library is missing, too new or an old copy is in your PLUS folder. No change to results. If you have an older install, run `ado uninstall nwcommands` (and the model packages) first, then reinstall as on the [install page](/nwcommands/install/).

## 25 October 2026 (night)

**nwcommands 3.5.0** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.5.0)), **nwergm 1.2.0** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.2.0)), **nwdynam 1.1.0** ([release notes](https://github.com/thomas-u-grund/nwdynam/releases/tag/v1.1.0)), **nwrem 1.0.5** ([release notes](https://github.com/thomas-u-grund/nwrem/releases/tag/v1.0.5)) and **nwsaom 1.0.7** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.7)). Several of these change results; read the release notes before you re-run old analyses.
- **nwcommands 3.5.0.** Three new real signed-network data sets (`senate114`, `senate93` from the US Senate, and the 16 tribes of the Gahuku-Gama, `gahuku`; see [Data sets](/datasets/)). Fixed: saving and reloading an undirected signed network turned its negative ties into 0, so `nwbalance` called every triad balanced; undirected networks built from a list that names each pair once now keep their negative ties. Equal-sized classes in `r(core_sizeid)`, `r(comm_sizeid)` and `r(block_sizeid)`, and equal values in several plots, now come in the same order under every seed. Error messages that were hidden inside `quietly` blocks are shown.
- **nwergm 1.2.0.** The MCMC defaults now follow R's `ergm` (interval 1024, burn-in 16 times the interval; the old fast settings are `mcmcburnin(3000) mcmcinterval(50)`). Chains mix much better (for the Lazega advice model the smallest effective sample size goes from 21 to about 340), and estimates agree with R, but fits take longer.
- **nwdynam 1.1.0.** Events with the same time are treated as simultaneous, as in goldfish (new option `sequential` for the old way); before, tied events were ordered by the state of the random-number generator. Results change only for data with tied event times.
- **nwrem 1.0.5.** Events with the same time keep the order of the event list (before, ties were ordered by the random-number generator). Results change only for data with tied event times.
- **nwsaom 1.0.7.** `nwsaom version` finds the plugin at the start of a session.

## 25 October 2026 (evening)

**nwcommands 3.4.0**, **nwsaom 1.0.6**, **nwergm 1.1.4**, **nwdynam 1.0.4** and **nwrem 1.0.4** (release notes: [nwcommands](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.4.0), [nwsaom](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.6), [nwergm](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.1.4), [nwdynam](https://github.com/thomas-u-grund/nwdynam/releases/tag/v1.0.4), [nwrem](https://github.com/thomas-u-grund/nwrem/releases/tag/v1.0.4)). **Update all five together** (`net install` the core, then `nwinstall, models`): the core Mata library changed, and the model packages are rebuilt for it. First, the core: ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.4.0)). Faster: `nwclustering`, `nwtriads`, `nwevcent`, `nwburt`, `nwsimmelian`, `nwconstraint`, `nwpagerank`, `nwclique` and `nwkcomponents` (with `k(2)`) run in the compiled graph plugin, with identical results (for example `nwtriads` at 100,000 nodes: 73 s to 1 s; `nwburt`: 26 s to 0.2 s; `nwkcomponents, k(2)` at 20,000 nodes: 67 s to 1 s); the page [How large a network can I analyze?](/nwcommands/size-limits/) has the new numbers and a section that compares the core with R's igraph. Two new two-mode example data sets, `davis` (Southern women) and `ftdirectors_se` (company directors in Sweden), with a [new tutorial](/tutorials/11-two-mode-networks/). `nwplot, interactive` has `fname()` to write the page to a chosen file, the shape drop-down shows "mixed" for mixed groups, and a layout brought back with `importcoords()` is drawn with the proportions of the view; `nwmovie, noopen` no longer opens the viewer; `nwplot, force` works. Stray Stata messages such as `(N real changes made)` no longer appear in the output of core commands, and some printed numbers no longer show floating point noise. `nwsave` of a two-mode network writes only the ties between the modes (1.2 MB instead of 2.6 GB for 5,092 + 455 nodes); files from earlier versions still load. Help files and dialog boxes are up to date, with a new dialog for `nwpagerank` and new tabs for `nwplot` (interactive, more options). A page with a [live interactive example](/book/interactive/) goes with the book *Network Analysis with Stata*. The Linux and Windows plugins are rebuilt by the plugin workflow for the release; until a platform has the new plugin the commands use the Mata code and are as slow as before. The Mata library is unchanged, so the model packages need no new release.

## 25 October 2026

**nwcommands 3.3.1** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.3.1)), **nwsaom 1.0.5** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.5)), **nwergm 1.1.3** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.1.3)), **nwdynam 1.0.3** ([release notes](https://github.com/thomas-u-grund/nwdynam/releases/tag/v1.0.3)) and **nwrem 1.0.3** ([release notes](https://github.com/thomas-u-grund/nwrem/releases/tag/v1.0.3)). Maintenance release: the model libraries are now indexed automatically, so a model command works right after installing it, even in the same Stata session. The core has a check at release time that warns when its Mata library changed and the model packages must be rebuilt in step. No change to results.

**nwcommands 3.3.0** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.3.0)), **nwsaom 1.0.4** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.4)) and **nwergm 1.1.2** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.1.2)). Networks of 100,000 nodes: more commands work at that size, and commands that cannot are refused at once with a message and an alternative; a new page, [How large a network can I analyze?](/nwcommands/size-limits/), says which commands suit which size. **Update all three together** (`net install` the core, then `nwinstall, models`): the model packages are rebuilt for core 3.3.0 and older model packages stop with r(3021) after the core is updated. nwergm 1.1.2 also fixes goodness of fit for two-mode fits, a failure with 5,000-node networks, and two-mode simulation output.

**nwdynam 1.0.2** ([release notes](https://github.com/thomas-u-grund/nwdynam/releases/tag/v1.0.2)) and **nwrem 1.0.2** ([release notes](https://github.com/thomas-u-grund/nwrem/releases/tag/v1.0.2)). The version is shown at the bottom of each help file, as in the other packages.

**nwcommands 3.2.0** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.2.0)). Networks of up to 100,000 nodes now work in the import, storage and most analysis commands, and many commands are much faster (for example `nwcomponents` 27 s to 0.5 s at 100,000 nodes). Several wrong results are fixed, so some results change: `nwcommunity` (Louvain) now finds the right communities above about 1,500 nodes and gives better partitions on small networks; `nwtabulate, attribute()` p-values are no longer biased; `nwmixing, permutations()` no longer overwrites a valued network; `nwrecode` and `nwdichotomize` no longer permute the result when labels are not in alphabetical order; node labels are no longer damaged above about 900 nodes. New options `maxcliques()`, `maxplexes()`, `maxtime()`, `countonly`, `nomatrix` and `force`, and memory guards that refuse at once with a message. Nothing is installed from SSC behind your back. `nwinstall, gui` adds the nwsaom and nwergm dialogs to the Statistical Models menu when those packages are installed.

**nwsaom 1.0.3** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.3)). Dialog boxes for every option and effect (`db nwsaom`, `db nwsaom_multinet`, `db nwsaom_bayes`, `db nwsaom_meta`, `db nwsaom_describe`, `db nwsaom_estat`). A co-evolution fit whose behavior rate grows without bound (for example with the `behrate` effects `avexposure` or `avtinexposuredist2` on unsuitable data) now stops with return code 498 and a message, as RSiena does, instead of running for hours. The version is shown at the bottom of each help file. The manual is updated.

**nwergm 1.1.1** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.1.1)). Dialog boxes for every term and option (`db nwergm`, `db nwergm_simulate`, `db nwergm_estat`; nine tabs, with a section selector inside the crowded tabs). Four fixes: `estat gof` with `b1degree`/`b2degree` after a two-mode fit; `obsconstraints(b1degrees)` and `(b2degrees)` no longer crash Stata; `constraints(observed)` and `obsconstraints(observed)` follow R; `mcmletermination(none)` no longer fails for some seeds. The version is shown at the bottom of each help file.

## 24 October 2026

**nwcommands 3.1.1** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.1.1)). `nwinstall` no longer deletes a user's `profile.do` when the edit fails (Mac and Linux); help text for the `s50` example data corrected.

**nwcommands 3.1.0** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.1.0)). The core is now free software under the GNU General Public License, version 3. `nwinstall, gui` installs the "Network Analysis" menu. Neighbor lists are returned in sorted order, independent of earlier session state. The release branch is `main`; `master` is kept as a copy.

**nwsaom 1.0.2** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.2)). Behavior centring with missing behavior data now follows RSiena (mean of the wave means of the observed values). The convergence message states RSiena's two criteria on separate lines.

**nwergm 1.1.0** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.1.0)). The operator terms of ergm (`operators()`), the term `balance`, curved two-mode terms and `altkstar` with an estimated decay; `seed()` is reproducible across sessions. 125 of the 139 terms of ergm 4.12.0.

**Site.** New sections for [nwsaom](../nwsaom/), [nwergm](../nwergm/), [nwdynam](../nwdynam/) and [nwrem](../nwrem/), each with an install page, tutorials, a comparison with the R package and a citation page; pages for [choosing a package](../which-package/), [citing and licenses](../citing/) and [getting help](../help/).

**nwcommands 3.0.0** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.0.0), [all releases](https://github.com/thomas-u-grund/nwcommands/releases)). The core now contains only the core. The model commands `nwsaom`, `nwergm`, `nwdynam` and `nwrem` moved to packages of their own; install them with `nwinstall, models`. Scripts that call these commands need the model packages installed, so this is a breaking change. New: `nwinstall, models` and `nwversion`, which shows the version of the core and of the installed model packages.

**nwsaom 1.0.1** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.1), [all releases](https://github.com/thomas-u-grund/nwsaom/releases)). The help file documents `nwsaom version` and the stored results that report the version.

**nwsaom 1.0.0** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.0)). First release of nwsaom as a package of its own: stochastic actor-oriented models with method of moments, maximum likelihood and Bayesian estimation, compared with RSiena and multiSiena.

**nwergm 1.0.1** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.0.1), [all releases](https://github.com/thomas-u-grund/nwergm/releases)). The help file documents `nwergm version` and the stored results that report the version.

**nwergm 1.0.0** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.0.0)). First release of nwergm as a package of its own: exponential random graph models for directed, undirected and bipartite networks, about 110 of the 139 ergm terms, maximum pseudolikelihood and Monte Carlo maximum likelihood.

**nwdynam 1.0.1** ([release notes](https://github.com/thomas-u-grund/nwdynam/releases/tag/v1.0.1), [all releases](https://github.com/thomas-u-grund/nwdynam/releases)). The help file documents `nwdynam version` and the stored results that report the version.

**nwdynam 1.0.0** ([release notes](https://github.com/thomas-u-grund/nwdynam/releases/tag/v1.0.0)). First release of nwdynam as a package of its own: dynamic network actor models with rate and choice submodels for event data, compared with goldfish.

**nwrem 1.0.1** ([release notes](https://github.com/thomas-u-grund/nwrem/releases/tag/v1.0.1), [all releases](https://github.com/thomas-u-grund/nwrem/releases)). The help file documents `nwrem version` and the stored results that report the version.

**nwrem 1.0.0** ([release notes](https://github.com/thomas-u-grund/nwrem/releases/tag/v1.0.0)). First release of nwrem as a package of its own: relational event models for event data, estimated by partial likelihood and compared with relevent.

## Earlier

nwcommands 2.0.0 (25 August 2026) was the last release with the four model families inside the core. The original releases, 1.x, date from 2014 and 2015.
