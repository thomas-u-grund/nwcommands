---
title: "nwgen"
parent: "Core command reference"
grand_parent: "Packages and reference"
nav_exclude: true
search_exclude: false
description: "Generate a network from a function or a network expression"
---

# `nwgen`

Generate a network from a function or a network expression

## Syntax

```stata
nwgen newnetname = netfcn(arguments) [, options]
nwgen newnetname = netexp [if] [, xvars vars(varlist) replace options]
```

| | |
|---|---|
| `replace` | overwrite an existing network (or, for a function that makes a variable, an existing variable) of the name *newnetname* |
| `vars(varlist)` | network expression only: names for the Stata variables of the new network, one for each node (used by `xvars` and [nwload](nwload)); the functions do not take it |
| `xvars` | generate Stata variables for the network |

## Description

The command generates a network. It can be used either with a) some function ***netfcn*** or b) with a network expression ***netexp***.

*netfcn* is one of:

- `duplicate(netname)`<br>
  Duplicate a network (see [nwduplicate](nwduplicate)).
- `dyadprob(netname)` , `density(float)` [`undirected` `xvars`]<br>
  Generate a network based on tie probabilities (see [nwdyadprob](nwdyadprob)).
- `geodesic(netname)` [`,` `unconnected(integer)` `sym` `xvars`]<br>
  Generate a network of shortest paths between nodes (see [nwgeodesic](nwgeodesic)).
- `homophily(varname)`, `homophily(float)` `density(float)` [...]<br>
  Generate a homophily network (see [nwhomophily](nwhomophily)).
- `lattice`(*`rows cols`*) [, `undirected` `xwrap` `ywrap` `xvars`]<br>
  Generate a lattice network (see [nwlattice](nwlattice)).
- `large(netname)`<br>
  Extract the largest component as a network. For a directed network this is the largest strongly connected component; add the option `weak` (for example `large(net, weak)`) for the largest weakly connected component (see [nwcomponents](nwcomponents)).
- `path(netname)`, `ego(nodeid)` `alter(nodeid)` [`length(int)` `sym` `xvars`]<br>
  Not currently implemented as a shortcut - [nwpath](nwpath) can produce zero, one, or several output networks (one per shortest path found), which does not fit this command's own "exactly one network per call" form. Use [nwpath](nwpath) directly - its own `generate()` option names one network per path found.
- `permute(netname)` [, `xvars`]<br>
  Random permutation of a network (see [nwpermute](nwpermute)).
- `pref`(`nodes`) [, `m0(int)` `m(int)` `prob(float)` `undirected` `xvars`]<br>
  Generate a preferential attachment network (see [nwpref](nwpref)).
- `random`(`nodes`) [, `prob(float)` `density(float)` `undirected` `xvars`]<br>
  Generate a random network (see [nwrandom](nwrandom)).
- `reach(netname)` [, `sym` `xvars`]<br>
  Generate a reachability network (see [nwreach](nwreach)).
- `ring`(`nodes`) , `k(int)` [`undirected` `xvars`]<br>
  Generate a ring lattice (see [nwring](nwring)).
- `small`(`nodes`) , `k(int)` [`prob(float)` `shortcuts(int)` `undirected` `xvars`]<br>
  Generate a small-world network (see [nwsmall](nwsmall)).
- `sym(netname)` [, `mode(max|min|sum|mean)`]<br>
  Symmetrize a network; the original is not changed (see [nwsym](nwsym)).
- `transpose(netname)`<br>
  Transpose a network (see [nwtranspose](nwtranspose)).

The shortcuts above all generate a new *network*. A second family generates a per-node *variable* instead - `nwgen` *newvarname* `=` *netfcn*(*netname*) - each a thin dispatch to an already-existing, dedicated command's own `generate()` option:

- `degree(netname)`, `outdegree(netname)`, `indegree(netname)`<br>
  Degree centrality (see [nwdegree](nwdegree)). **degree()** on a directed network is total degree (out+in summed).
- `isolates(netname)`<br>
  Isolate indicator (see [nwdegree](nwdegree), `isolates`).
- `components(netname)`, `lgc(netname)`<br>
  Component membership, or a largest-component indicator (see [nwcomponents](nwcomponents)).
- `clustering(netname)`<br>
  Clustering coefficient (see [nwclustering](nwclustering)).
- `closeness(netname)`, `farness(netname)`, `nearness(netname)`<br>
  Closeness centrality and its two components (see [nwcloseness](nwcloseness)).
- `between(netname)`<br>
  Betweenness centrality (see [nwbetween](nwbetween)).
- `evcent(netname)`<br>
  Eigenvector centrality (see [nwevcent](nwevcent)).
- `context(netname)`, `attribute(varname)`<br>
  Contextual (neighbor-attribute) statistic (see [nwcontext](nwcontext)) - `attribute()` is required and has no default.

Three further keywords are recognized but not implemented as a variable shortcut, since they do not naturally reduce to one value per node: **addnodes(** (mutates a network's own node set - see [nwaddnodes](nwaddnodes)), **subset(** (produces a new network, not a variable - see [nwsubset](nwsubset)), and **collapse(** (see [nwcollapse](nwcollapse)). Each raises a clear, immediate error rather than silently doing nothing.

## Network types

What happens with directed, valued, two-mode and signed networks depends on the function that is called (see [nwgen](nwgen) / [nwgenvar](nwgenvar) and the help of the function). See [nwnetworktypes](nwnetworktypes).

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

---

*nwcommands version 3.39.0, 26 November 2026* ([check your installed version](nwversion))
