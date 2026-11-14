---
title: "nwgenvar"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Generate variables or networks with network functions (like egen)"
---

# `nwgenvar`

Generate variables or networks with network functions (like egen)

## Syntax

```stata
nwgenvar newvar = netfcn1(arguments) [, options]
nwgenvar newnetname = netfcn2(arguments) [, options]
nwgenvar newnetname = netexp [if] [, options]
		
where the options are also fcn dependent.
```

## Description

These are network extensions to `generate`. The command is very similar to `egen` and allows producing either variables or networks. There are basically three ways to use this commands: 1) produce Stata variables with some function ***netfcn1***, 2) produce networks with some function ***netfnc2***, 3) produce networks with an expression ***netexp***. A network expression is very similar to normal expressions in Stata.

## Generating variables from networks

The command can be used to generate Stata variables with some function *netfcn1* that takes [netname](netname) as an argument. For example, this can be used to generate centrality scores for each node in a network.

`nwgenvar` newvar `=` *netfcn1*(*arguments*) [`,` *options*]

*netfcn1* is one of:

- `between(netname)` [, `nosym`]
- Calculate the betweenness centrality of network nodes (see [nwbetween](nwbetween)).

- `closeness(netname)` [, `unconnected(integer)` `nosym`]
- Calculate the closeness centrality of network nodes (see [nwcloseness](nwcloseness)).

- `clustering(netname)`
- Calculate the clustering coefficient of network nodes (see [nwclustering](nwclustering)).

- `components(netname)`
- Return the component membership of nodes (see [nwcomponents](nwcomponents)).

- `context(netname)``,`
- `attribute`(`varname`)
- [`stat`([statistic](nwcontext))
- `mode`([context](nwcontext))
- `mat`(string)
- `noweight`]
- Generate a context variable based on attributes of a node's neighbors (see [nwcontext](nwcontext)).

- `degree(netname)`
- Calculate the degree centrality of network nodes. When the network is directed, the total degree (outdegree plus indegree) is returned (see [nwdegree](nwdegree)).

- `evcent(netname)`
- Calculate the eigenvector centrality of network nodes (see [nwevcent](nwevcent)).

- `farness(netname)`
- Calculate the farness of network nodes (see [nwcloseness](nwcloseness)).

- `indegree(netname)`
- Return the indegree of network nodes. When the network is undirected, the degree is returned (see [nwdegree](nwdegree)).

- `isolates(netname)`
- Returns the isolates of a network (see [nwdegree](nwdegree)).

- `lgc(netname)`
- Calculate membership to largest component as variable (see [nwcomponents](nwcomponents)).

- `nearness(netname)`
- Calculate the nearness of network nodes (see [nwcloseness](nwcloseness)).

- `outdegree(netname)`
- Return the outdegree of network nodes. When the network is undirected, the degree is returned (see [nwdegree](nwdegree)).

The number of an observation `_n` in `newvar` corresponds to the [nodeid](nodeid) of a node in a network.

Unlike [nwgen](nwgen), `nwgenvar` does **not** support the `mean(alter.`*srcvar*`)`-style shortcut for summarizing an existing Stata variable's values among each node's network neighbors - use [nwaltergen](nwaltergen) directly for that, or use `nwgen` instead.

## Generating networks

The command can also be used to generate networks. There are two ways to do this:

`nwgenvar` *[newnetname](newnetname)* `=` *netfcn2*(*arguments*) [`,` *options*]

`nwgenvar` *[newnetname](newnetname)* `=` *[netexp](netexp)* [`,` *options*]

*netfcn2* is one of:

- `duplicate(netname)`
- Duplicate a network (see [nwduplicate](nwduplicate)).

- `dyadprob(netname)` , `density(float)` [`undirected` `xvars`]
- Generate a network based on tie probabilities (see [nwdyadprob](nwdyadprob)).

- `geodesic(netname)` [`,`
- `unconnected(integer)`
- `sym`
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

- `reach(netname)` [, `sym` `xvars`]
- Generate a reachability network (see [nwreach](nwreach)).

- `ring`(`nodes`) , `k(int)` [`undirected` `xvars`]
- Generate a ring lattice (see [nwring](nwring)).

- `small`(`nodes`) , `k(int)` [`prob(float)` `shortcuts(int)` `undirected` `xvars`]
- Generate a small-world network (see [nwsmall](nwsmall)).

- `transpose(netname)`
- Transpose a network (see [nwtranspose](nwtranspose)).

## Network types

The command works the same for every network type; what a function does with directed, valued, two-mode and signed networks is in the help of that function (see [nwnetworktypes](nwnetworktypes)).

## Examples

Generate a per-node variable with a network function:

```stata
. nwwebuse florentine, nwclear
. nwgenvar mydeg = degree(flomarriage)
. list mydeg in 1/5
```
Generate a new network with a network function:

```stata
. nwgenvar newnet = random(10), prob(.3)
. nwsummarize newnet
```

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
