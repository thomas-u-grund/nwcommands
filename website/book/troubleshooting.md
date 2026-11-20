---
title: "When things go wrong: more"
parent: "Book companion"
nav_order: 6
description: "More error messages and installation details that go with Appendix B of the book: several groups in nwsaom, two mistakes the package now stops, and building plugins and Mata libraries."
permalink: /book/troubleshooting/
---

# When things go wrong: more
{: .no_toc }

This page goes with Appendix B of the book *Network Analysis with Stata*. The appendix covers how to read `_rc`, the five categories of error, installation problems and a checklist; here are the messages and procedures that the appendix leaves out for length.

1. TOC
{:toc}

## SAOM-specific failures: several groups

The joint model for several groups has preconditions of its own. The listing makes three artificial groups from the Glasgow pupils (as in the manual of the package) and breaks them on purpose. First, the whole Glasgow network is given with `groups()`, but the networks of the waves must have no ties between groups. Second, `gwaves()` gives group 2 a single wave, but a group needs at least two. Both stop with return code 198, as does an option that is not available with `groups()`, such as `ml`.

```stata
. nwwebuse glasgow, nwclear
. generate byte school = 1 + (_n > 15) + (_n > 35)
. mata: g = st_data(., "school"); M = J(rows(g), 1, g') :== g
. forvalues w = 1/3 {
.     quietly nwtomata glasgow`w', mat(F`w')
.     mata: st_matrix("S`w'", F`w' :* M)
.     nwset, mat(S`w') directed name(gw`w') nooutput
. }
. capture noisily nwsaom, waves(glasgow1 glasgow2 glasgow3) groups(school) ///
>         outdegree reciprocity
nwsaom: groups(): wave 1 has 12 tie(s) from actors of group 1 to actors of
  other groups; the networks of the waves must have no ties between groups
  (the groups are separate actor sets).
. display "_rc = " _rc
_rc = 198
. capture noisily nwsaom, waves(gw1 gw2 gw3) groups(school) gwaves(2: 1) ///
>         outdegree reciprocity
nwsaom: groups(): group 2 (value 2) has fewer than 2 waves.
. display "_rc = " _rc
_rc = 198
```

A fit that runs but whose convergence criteria are not met is a different kind of failure. `nwsaom` prints which criterion failed and suggests `nwsaom refit`, which reruns the fit from its estimates; `nwsaom refit, maxruns(3)` repeats the restart until both criteria are met. With groups of 15 pupils a different `seed()` may be enough.

## Two mistakes that used to pass silently

Two silent mistakes were common enough that the package now stops them. The first is a network whose nodes share a label:

```stata
. capture noisily nwset, mat((0,1,1\1,0,1\1,1,0)) undirected labs(A,A,B)
node labels must be unique; repeated: A
```

Node labels identify nodes: `nwload`, the node data and many commands look nodes up by label, so two nodes called A could be merged or confused later. `nwset` therefore refuses repeated labels and names the one that repeats.

The second is a variable overwritten when a network is loaded. Two networks on the same nodes use the same variable names, so loading the second replaces the first, and `nwload` now says so:

```stata
. nwwebuse florentine, nwclear
. drop _all
. nwload flomarriage
. nwload flobusiness
(variables of network flomarriage dropped; nwload loads one network at a time)
```

A variable of your own with the name of a node variable is not overwritten either: `nwload` stops and offers the option `overwrite`, to be used only when the variable is expendable.

## Compiling a plugin on your own computer

The compiled plugins can be missing for a platform, older than the commands that call them, or fail to load on a particular system. The commands then say that the plugin is not used, or that an effect needs a newer one. Most commands fall back to Mata with the same results; a few, such as the terms of the option `structural()` of `nwergm`, have no Mata version. The remedy is to compile the plugin on your own computer from the source that comes with each package:

```stata
. nwinstall, buildplugin(nwsaom)
. nwinstall, buildplugin(all)
```

The names are `nwcommands`, `nwsaom`, `nwergm` and `nwdynam` (`nwrem` has no plugin); `all` builds the four. An existing file is kept with the extension `.prev`. You need a C compiler and `make`: on a Mac, the command line tools of Xcode (`xcode-select --install` in the Terminal), on Linux `gcc` and `make`. Restart Stata afterward. The routine has been tested on macOS; on Windows the command stops with a message, and the build note that `net get nwsaom` copies together with the source gives the command for the Visual Studio command line.

## Building the Mata libraries with your Stata

The Mata libraries of the packages are built with Stata 17. A library built by an older Stata loads in every later version, but one built by a newer Stata is ignored by an older one: Stata says that the library was "compiled by Stata 18, is too new to be run by this version of Stata and so was ignored," and every Mata function is then reported as not found (error r(3499)). The remedy is to build the libraries with the Stata that you run:

```stata
. nwinstall, buildmata(all)
. nwinstall, buildmata(nwsaom)
```

The command compiles the Mata source of the core and of every installed model package and installs the libraries where Stata finds the current ones. The build clears the data and the Mata objects in memory, including loaded networks, so save your work first. The libraries of `nwsaom` and `nwergm` are accepted only together with exactly the library of the core they were compiled against, so rebuilding the core always rebuilds the installed model libraries as well. A build takes a few minutes. The shipped libraries are the better choice whenever they load. As with the plugins, update the packages first and restart Stata afterward.

## Archived manuals

The manuals of `nwergm` ([doi:10.5281/zenodo.23661331](https://doi.org/10.5281/zenodo.23661331)) and `nwsaom` ([doi:10.5281/zenodo.23623807](https://doi.org/10.5281/zenodo.23623807)) are archived at Zenodo; the DOI of all versions leads to the latest manual.
