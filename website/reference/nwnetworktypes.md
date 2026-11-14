---
title: "nwnetworktypes"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "How commands classify binary/directed/weighted/signed/two-mode networks"
---

# `nwnetworktypes`

How commands classify binary/directed/weighted/signed/two-mode networks

## Description

`nwcommands` networks can be binary or valued (weighted), undirected or directed, and one-mode or two-mode (bipartite) - see [nwintro](nwintro) for the underlying data model. No single command supports every combination equally: some are inherently structural and apply unchanged to any network (e.g. [nwdrop](nwdrop)); some have a well-defined weighted generalization but a separate binary-only default (e.g. [nwclustering](nwclustering)); some have a two-mode form of the same concept that they use automatically on a two-mode network (e.g. [nwdegree](nwdegree); the option `onemode` forces the one-mode computation); a few are simply not implemented for a combination yet.

Rather than guess, every `nw*` command's own help file has a short **Network types** section stating explicitly what it does with a directed, weighted, signed, or two-mode network - whether that is full native support, an explicit binary-only/one-mode-only restriction with a clear error, silent-but-documented dichotomization, or simply "not applicable" for a command with no network-type-dependent behavior at all. That per-command section is always the authoritative answer for a specific command; this page explains the vocabulary those sections use and points to the small set of commands that have been read closely enough to also carry a fuller, source-verified classification.

## Valued networks

Every network carries a *Valued* flag (shown by [nwsummarize](nwsummarize)). It is set when the network is created, by the way it is created, and it is not worked out from the values again later: a network created with tie values ([nwfromedge](nwfromedge) with a value variable, an import of a file with tie values, `nwset, valued`, a matrix with a value other than 0 and 1) is valued, also if every value is 1; a network created without values is binary. Commands that transform a network keep its flag; [nwdichotomize](nwdichotomize) gives a binary network. A network loaded from a file keeps the flag it was saved with (`nwname` *net*`, newvalued(true)` changes it).

Measures that have a weighted form in R use the tie values of a valued network by default ([nwdegree](nwdegree), [nw2degree](nw2degree), [nwgeodesic](nwgeodesic), [nwcloseness](nwcloseness), [nwbetween](nwbetween), [nwevcent](nwevcent), [nwpagerank](nwpagerank), [nwrandomwalk](nwrandomwalk), [nwpath](nwpath), [nwmatching](nwmatching), [nwassortativity](nwassortativity), [nwkatz](nwkatz) with `walks`); the option `binary` ignores the values. Measures without a weighted form in R are binary by definition and print the line "(note: tie values are ignored; this measure is binary)" on a valued network. The website page on valued networks lists all commands.

## Two-mode networks and the nw2* names

Every network carries a *Two-mode* flag (shown by [nwsummarize](nwsummarize)). It is set when the network is created, by declaration, and nowhere else: `nwset, twomode` or `bipartite`, [nw2fromedge](nw2fromedge), [nw2set](nw2set), `nwfromedge, twomode`, [nwimport](nwimport) of a file that declares the modes and [nwuse](nwuse) of a saved two-mode network. No measure works the flag out from the ties, because the adjacency matrix of a two-mode network looks like that of a one-mode network. The declaration is checked: both modes must hold nodes and no tie may join two nodes of the same mode (`nwname, new2mode(true)` on a one-mode network is an error). Every command that derives a network from a two-mode network ([nwdropnodes](nwdropnodes), [nwkeepnodes](nwkeepnodes), [nwsubset](nwsubset), [nwduplicate](nwduplicate), [nwsym](nwsym), [nwtranspose](nwtranspose), [nwrecode](nwrecode), [nwdichotomize](nwdichotomize), [nwaddnodes](nwaddnodes), [nwpermute](nwpermute)) keeps the flag, the modes and the level labels. [nwexport](nwexport) and [nwimport](nwimport) keep the flag and the modes in all four formats and the level labels in Pajek, GML and edge list files (UCINET DL has no place for them); an edge list written by [nwtoedge](nwtoedge) or [nw2toedge](nw2toedge) holds the ties between the modes and reads back as the same network.

Every command's help file says in its **Network types** section, in one of four fixed wordings, what the command does with a two-mode network:

**Two-mode: yes - ...** The command uses the two modes the way R does (`tnet`, `igraph`, `bipartite`); the rest of the sentence says what changes.

**Two-mode: two-mode form by default ...** The command has a two-mode form of the same statistic and uses it on a two-mode network without being asked; the option `onemode` forces the one-mode computation on the bipartite graph. [nwdegree](nwdegree), [nwclustering](nwclustering), [nwmotifs](nwmotifs), [nwcloseness](nwcloseness) and [nwbetween](nwbetween) are of this kind.

**Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation)** The measure is defined on any graph and the number is right for the bipartite graph: components, k-cores, geodesics, betweenness, closeness, PageRank, eigenvector centrality, Burt's constraint and so on. Nothing is printed.

**Two-mode: not supported - error 6088** The command would read the blocks between nodes of the same mode, which hold no ties, and give missing or meaningless numbers. It stops with one message (the same for every such command) and the error 6088. Make a one-mode network of one mode with [nwproject](nwproject) first. [nwspectral](nwspectral) and [nwrandomwalk](nwrandomwalk) have the option `onemode`, which reads the bipartite graph as a one-mode graph, as `igraph` does.

**The rule.** A network declares itself two-mode when it is created. A command that has a two-mode form of the same concept uses that form automatically on a two-mode network, and the option `onemode` forces the one-mode computation on the bipartite graph (what `igraph` does with a bipartite graph). [nwdegree](nwdegree) (number of ties over the size of the other mode, `raw` for the count), [nwclustering](nwclustering) (Opsahl 2013; `ra`: Robins and Alexander 2004), [nwmotifs](nwmotifs) (the bipartite motifs of Simmons et al. 2019), [nwcloseness](nwcloseness) and [nwbetween](nwbetween) (the normalisations of Borgatti and Everett 1997; `twomode` is accepted as a synonym of the default), [nwcommunity](nwcommunity) and [nwmodularity](nwmodularity) (the bipartite modularity of Barber) and [nwsimilar](nwsimilar) and [nwdissimilar](nwdissimilar) (nodes are compared with nodes of their own mode) follow it. The names [nw2degree](nw2degree), [nw2clustering](nw2clustering) and [nw2motifs](nw2motifs) are aliases of the main commands; their help files list their options. [nw2project](nw2project) and [nw2nested](nw2nested) have no one-mode counterpart and keep their own names. The website page on two-mode networks and the table of network types list all commands.

## Weighted (valued) networks

A network is *valued* (weighted) when its ties carry a real number, not just presence/absence - set automatically whenever [nwset](nwset), [nwfromedge](nwfromedge), or an import command is given tie values other than a plain 0/1 indicator (at least one tie value other than 0 and 1; a network whose ties are all 1 is binary), and readable via [nwsummarize](nwsummarize) / [nwname](nwname)'s own `valued` field. As with two-mode status, ordinary commands do not need a special flag to tell them a network is valued; each command's own **Network types** section states what it actually does with the tie values.

Three patterns cover almost every command in this package:

**1. Native (W1)** - the tie value enters the calculation directly, with one well-defined formula for the whole [0,1] weighted-to-binary spectrum. Most centrality/cohesion commands with a weighted variant follow Opsahl, Agneessens and Skvoretz (2010)'s own generalized-degree convention: *k_i * (s_i/k_i)^alpha*, where *k_i* is the plain tie count and *s_i* is the tie-value sum ("strength"). `alpha(0)` always reduces this back to plain unweighted degree exactly - not approximately; `alpha(1)` gives pure strength; values in between blend the two. [nwdegree](nwdegree) and [nw2degree](nw2degree) (one-mode and two-mode degree respectively) both use this exact formula; [nwbetween](nwbetween)'s `weighted` option uses the same `alpha()` convention to turn tie strength into a Dijkstra path cost instead ([nwgeodesic](nwgeodesic) / [nwkatz](nwkatz) do too, for distance); [nwconstraint](nwconstraint) / [nwburt](nwburt) use tie weight directly as Burt's own investment-proportion formula, with no separate binary mode at all.

**2. Optional, explicit toggle (W2)** - a command supports both a binary and a weighted formulation, selected by an option rather than assumed from the network's own valued/unvalued status. [nwclustering](nwclustering) / [nwcommunity](nwcommunity) / [nwconcor](nwconcor) / [nw2clustering](nw2clustering)'s own `measure(binary|valued)` is the recurring convention here (usually defaulting to whichever matches the loaded network, documented explicitly in each command's own help file, never silently picked).

**3. Binary-only, documented (W3)** - the command has a single, dichotomized formulation and says so plainly (e.g. [nwtriads](nwtriads)' triad census, [nwclique](nwclique)'s clique membership, [nwcomponents](nwcomponents)' weak-connectivity components) - not a gap, since no standard weighted generalization of the underlying concept exists in the literature, but worth checking a command's own help file before assuming tie strength is being used.

A tie value of exactly 0 and "no tie at all" are treated identically almost everywhere in this package (both mean "not connected") - a network with meaningful zero-valued ties distinct from missing ones needs a workaround (e.g. a small constant offset) rather than being handled natively. **Negative (signed) tie values** are a separate, much less consistently supported dimension - most commands' own "Signed" part of their **Network types** section reads "not checked" or "not supported", meaning a negative weight is not distinguished from an unusually low positive one in most formulas (an explicit exception: [nwbalance](nwbalance), which exists specifically to classify triads by tie sign). Checking a specific command's own **Signed** field before relying on negative ties is worth doing explicitly - do not assume support carries over from a command's own weighted (W1/W2) status.

[nwsummarize](nwsummarize) reports whether a loaded network is valued directly:

```stata
. nwwebuse florentine, nwclear
. nwsummarize flomarriage
```

## Reading the "Network types" section of a command

The help file of each command has a short section **Network types** that says only what that command does with **directed** networks (used as directed, or symmetrized; the option that changes it), **valued** networks (whether the tie values are used by default, and the option `binary` or `weighted`), **two-mode** networks (what the result means, or that the command does not apply) and **signed** networks (how negative ties are treated). Every command works on binary (0/1) networks unless the section says otherwise. A command whose behaviour does not depend on the network type says so in one sentence.

## Examples

[nwsummarize](nwsummarize) reports a loaded network's own classification along these same dimensions:

```stata
. nwwebuse florentine, nwclear
. nwsummarize flomarriage
```

## Source-verified classifications

A small set of commands - the ones most central to network analysis, where getting the weighted/ directed/signed handling exactly right matters most - have been independently re-derived from source code (not just summarized from their own help text), each backed by a quoted line of code, using a classification key of **W1**-**W5** for weighted support and **T1**-**T5** for two-mode support.

## See also

- [nwintro](nwintro), [nwtopical](nwtopical), [introduction to two-mode networks](nw2set)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
