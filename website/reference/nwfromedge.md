---
title: "nwfromedge"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Imports network data from edgelist"
---

# `nwfromedge`

Imports network data from edgelist

## Syntax

```stata
nwfromedge 
 fromid
 toid
[tievalue]
[if]
[,
name(newnetname)
xvars
labs(lab1 lab2 ...)
undirected
directed
twomode
valued
unvalued]
```

| | |
|---|---|
| `name(newnetname)` | name of the new network; default = *network* |
| `xvars` | generate Stata variables for the network |
| `labs`(*lab1 lab2 ...*) | overwrite node labels |
| `undirected` | force the network to be undirected (alias: `forceundirected`) |
| `directed` | force the network to be directed (alias: `forcedirected`) |
| `twomode` | declare a two-mode (bipartite) network instead - *fromid*/*toid* are the mode-1/mode-2 id variables, not a directed ego/alter pair. An exact alias for [nw2fromedge](nw2fromedge), forwarding `name()`/`xvars` only; cannot be combined with `directed`/`undirected`/`forcedirected`/`forceundirected`. See [nw2fromedge](nw2fromedge) for the full two-mode-specific behavior (same-label disambiguation, mode assignment, `project()`) |
| `valued` | mark the network as valued (default if a value variable is given, also when every value is 1) |
| `unvalued` | mark the network as binary even if a value variable is given |
| `noclear` | do not clear existing dataset |
| `replace` | if a network named *newnetname* already exists, drop it and use this name anyway (see [nwset](nwset) for the same convention) |
| `labprefix`(*string*) | prefix used for auto-generated node labels when `fromid`/`toid` are numeric and `labs()` is not specified; default = **n** - named `labprefix()`, not `prefix()`, to avoid colliding with [nwrecode](nwrecode)'s unrelated `prefix()` (which prefixes new *network* names, not node labels) |
| `overwrite` | forwarded to [nwload](nwload) governing whether this command's own generated Stata variables overwrite existing ones of the same name - unrelated to `replace` above, which is about the *network*, not Stata variables |

## Description

`nwfromedge` imports a network from a dataset in edgelist format.

An edgelist or arclist is a set of two (or three in the case of a valued network) variables representing relations. Nodes are identified by entries in the cells.  For example, the data

```stata
   +---------------+
   |  fromid  toid |
   |---------------|
1. |  1       2    |
2. |  2       3    |
3. |  4       2    |
   +---------------+
```
stores information about three *ties* (1=>2), (2=>3) and (4=>2) among four unique network nodes. The variables defining the edges can also be `string` variables.

```stata
   +--------------------------+
   |  fromid    toid     value|
   |--------------------------|
1. |  Peter     Thomas   1    |
2. |  Tim       Peter    3    |
3. |  Mathilde  Thomas   2    |
   +--------------------------+
```
Here, there are also three relationships: (Peter => Thomas), (Tim => Peter) and (Mathilde => Thomas).

The following command declares such data as network data:

```stata
. nwfromedge fromid toid value, name(mynet)
```
This automatically generates the relevant meta-information for the network and makes it available for other programs under the [netname](netname) *mynet*. In case no **name()** is specified, the command tries to come up with a suitable name for the new network. By default, it tries *network*, however, if a network with this name already exists, it comes up with an alternative name *network_1* and so on (see [nwvalidate](nwvalidate)).

After a network has been declared, one can refer to it by its [netname](netname), just as if one would refer to a `varname`. For example, this [makes a network plot](nwplot) of *mynet*.

```stata
. nwplot mynet
```
Or alternatively, this calculates the [betweenness centrality](nwbetween) of the nodes in *mynet*.

```stata
. nwbetween mynet
```
By default, **nwfromedge** recognizes if a network is directed or undirected, i.e. for each dyad entry (i,j) there is also a dyad entry (j,i). However, this automatic detection can be overwritten with the options `undirected` and `directed`. With `undirected`, a tie that is listed in only one direction is stored as it is (a negative value stays negative); if both directions are listed with different values, the larger value is kept.

One can also transfrom any network that exists in memory into such an edgelist with [nwtoedge](nwtoedge).

## Examples

This loads a network dataset from the internet and transforms the network *glasgow1* into an edgelist.

```stata
. nwwebuse glasgow, nwclear
. nwtoedge glasgow1
```
`nwtoedge` produces variables *_ego*/*_alter* (not *_fromid*/*_toid*) plus a tie-value column named after the network itself (*glasgow1* here, not *_link*) - and, being every possible pair rather than a compact edgelist, it needs filtering down to the real ties before being turned back into a network:

```stata
. keep if glasgow1 == 1
. nwfromedge _ego _alter, name(mynet)
```
*glasgow1* has 50 nodes but only 47 with at least one tie; *mynet* still comes out with all 50 - the 3 isolates [nwtoedge](nwtoedge) could not write as edgelist rows are added back automatically, with no extra step needed (see this file's own **Supported network types** section above). This only works because `nwtoedge` itself produced this particular edgelist; it would not apply to an edgelist typed in by hand or imported from an external source.

## Supported network types

Binary: yes. Directed: yes, via `directed`/`undirected`/`forcedirected`/`forceundirected`. Weighted: yes - a third edge-list column supplies tie values. Signed: yes - with `undirected` a tie listed once keeps its sign. Two-mode: yes - with `twomode`, an exact alias for [nw2fromedge](nw2fromedge), which builds the network from the two id columns. A node with zero ties (an isolate) can never appear as a ROW in an edgelist - there is no pair to write - but a round trip through [nwtoedge](nwtoedge) specifically is not affected: `nwtoedge` attaches its source network's own full node list to the edgelist dataset (invisibly - no extra variables or rows), and `nwfromedge` automatically adds back any node that list has but the edgelist's own ties did not reproduce. A hand-built or externally-sourced edgelist carries no such list, so isolates neither of those every had are genuinely unrepresentable - add them with [nwaddnodes](nwaddnodes) same as always.

---

*nwcommands version 3.9.1, 26 October 2026* ([check your installed version](nwversion))
