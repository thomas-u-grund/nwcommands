---
title: "nwgen"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Network extensions to generate"
---

# `nwgen`

Network extensions to generate

## Syntax

```stata
nwgen newnetname = netfcn(arguments) [, options]
nwgen newnetname = netexp [if] [, options]
```

## Description

The command generates a network. It can be used either with a) some function ***netfnc*** or b) with a network expression ***netexp***.

*netfcn* is one of:

- `duplicate(netname)` [, `xvars`]
- Duplicate a network (see [nwduplicate](nwduplicate)).

- `dyadprob(netname)` , `density(float)` [`undirected` `xvars`]
- Generate a network based on tie probabilities (see [nwdyadprob](nwdyadprob)).

- `geodesic(netname)` [`,`
- `unconnected(integer)`
- `nosym`
- `xvars`]
- Generate a network of shortest paths between nodes (see [nwgeodesic](nwgeodesic)).

- `homophily(varname)`, `homophily(float)` `density(float)` [...]
- Generate a homophily network (see [nwhomophily](nwhomophily)).

- `lattice`(*`rows cols`*) [, `undirected` `xwrap` `ywrap` `xvars`]
- Generate a lattice network (see [nwlattice](nwlattice)).

- `large(netname)`
- Extract the largest component as a network.

- `path(netname)`, `ego(nodeid)` `alter(nodeid)` [`length(int)` `sym` `xvars`]
- Not currently implemented as a shortcut - [nwpath](nwpath) can produce zero, one, or several
- output networks (one per shortest path found), which does not fit this command's own "exactly one
- network per call" form. Use [nwpath](nwpath) directly - its own `generate()` option names one
- network per path found.

- `permute(netname)` [, `xvars`]
- Random permutation of a network (see [nwpermute](nwpermute)).

- `pref`(`nodes`) [, `m0(int)` `m(int)` `prob(float)` `undirected` `xvars`]
- Generate a preferential attachment a network (see [nwpref](nwpref)).

- `random`(`nodes`) [, `prob(float)` `density(float)` `undirected` `xvars`]
- Generate a random network (see [nwrandom](nwrandom)).

- `reach(netname)` [, `nosym` `xvars`]
- Generate a reachability network (see [nwreach](nwreach)).

- `ring`(`nodes`) , `k(int)` [`undirected` `xvars`]
- Generate a ring lattice (see [nwring](nwring)).

- `small`(`nodes`) , `k(int)` [`prob(float)` `shortcuts(int)` `undirected` `xvars`]
- Generate a small-world network (see [nwsmall](nwsmall)).

- `transpose(netname)`
- Transpose a network (see [nwtranspose](nwtranspose)).

The shortcuts above all generate a new *network*. A second family generates a per-node *variable* instead - `nwgen` *newvarname* `=` *netfcn*(*netname*) - each a thin dispatch to an already-existing, dedicated command's own `generate()` option:

- `degree(netname)`, `outdegree(netname)`, `indegree(netname)`
- Degree centrality (see [nwdegree](nwdegree)). **degree()** on a directed network is total degree
- (out+in summed).

- `isolates(netname)`
- Isolate indicator (see [nwdegree](nwdegree), `isolates`).

- `components(netname)`, `lgc(netname)`
- Component membership, or a largest-component indicator (see [nwcomponents](nwcomponents)).

- `clustering(netname)`
- Clustering coefficient (see [nwclustering](nwclustering)).

- `closeness(netname)`, `farness(netname)`, `nearness(netname)`
- Closeness centrality and its two components (see [nwcloseness](nwcloseness)).

- `between(netname)`
- Betweenness centrality (see [nwbetween](nwbetween)).

- `evcent(netname)`
- Eigenvector centrality (see [nwevcent](nwevcent)).

- `context(netname)`, `attribute(varname)`
- Contextual (neighbor-attribute) statistic (see [nwcontext](nwcontext)) - `attribute()` is
- required and has no default.

Three further keywords are recognized but not implemented as a variable shortcut, since they do not naturally reduce to one value per node: **addnodes(** (mutates a network's own node set - see [nwaddnodes](nwaddnodes)), **subset(** (produces a new network, not a variable - see [nwsubset](nwsubset)), and **collapse(** (see [nwcollapse](nwcollapse)). Each raises a clear, immediate error rather than silently doing nothing.

## Examples

Generate a new network with a network function:

```stata
. nwclear
. nwgenerate newnet = random(10), prob(.3)
. nwsummarize newnet
```
Generate a per-node variable, one value per node, from an existing network:

```stata
. nwwebuse florentine, nwclear
. nwgenerate mydeg = degree(flomarriage)
. list mydeg in 1/5
```

## Supported network types

Not applicable to `nwgenerate` itself - the underlying dispatcher [nwgen](nwgen)/[nwgenvar](nwgenvar) both delegate to; the actual directed/valued/two-mode support depends entirely on whichever underlying *netfcn*/network expression is invoked - see that function's own help topic.

- last certified : 24 Aug 2026
