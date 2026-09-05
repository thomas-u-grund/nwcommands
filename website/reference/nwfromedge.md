---
title: "nwfromedge"
parent: "Command reference"
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
twomode]
```

| | |
|---|---|
| `name(newnetname)` | name of the new network; default = *network* |
| `xvars` | generate Stata variables for the network |
| `labs`(*lab1 lab2 ...*) | overwrite node labels |
| `undirected` | force the network to be undirected (alias: `forceundirected`) |
| `directed` | force the network to be directed (alias: `forcedirected`) |
| `twomode` | declare a two-mode (bipartite) network instead - *fromid*/*toid* are the mode-1/mode-2 id variables, not a directed ego/alter pair. An exact alias for [nw2fromedge](nw2fromedge), forwarding `name()`/`xvars` only; cannot be combined with `directed`/`undirected`/`forcedirected`/`forceundirected`. See [nw2fromedge](nw2fromedge) for the full two-mode-specific behavior (same-label disambiguation, mode assignment, `project()`) |
| `noclear` | do not clear existing dataset |
| `replace` | if a network named *newnetname* already exists, drop it and use this name anyway (see [nwset](nwset) for the same convention) |
| `labprefix`(*string*) | prefix used for auto-generated node labels when `fromid`/`toid` are numeric and `labs()` is not specified; default = **n** - named `labprefix()`, not `prefix()`, to avoid colliding with [nwrecode](nwrecode)'s unrelated `prefix()` (which prefixes new *network* names, not node labels) |
| `overwrite` | forwarded to [nwload](nwload) governing whether this command's own generated Stata variables overwrite existing ones of the same name - unrelated to `replace` above, which is about the *network*, not Stata variables |

## Description

`nwfromedge` imports a network from a dataset in edgelist format.

An edgelist or arclist is a set of two (or three in the case of a valued network) variables representing relations. Nodes are identified by entries in the cells.  For example, the data

- hline 14c -
- c | fromid toid c |
- hline 14c -
- 1. c | 1 2 c |
- 2. c | 2 3 c |
- 3. c | 4 2 c |
- hline 14c -

stores information about three *ties* (1=>2), (2=>3) and (4=>2) among four unique network nodes. The variables defining the edges can also be `string` variables.

- hline 25c -
- c | fromid toid valuec |
- hline 25c -
- 1. c | Peter Thomas 1 c |
- 2. c | Tim Peter 3 c |
- 3. c | Mathilde Thomas 2 c |
- hline 25c -

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
By default, **nwfromedge** recognizes if a network is directed or undirected, i.e. for each dyad entry (i,j) there is also a dyad entry (j,i). However, this automatic detection can be overwritten with the options `undirected` and `directed`.

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

Binary: yes. Directed: yes, via `directed`/`undirected`/`forcedirected`/`forceundirected`. Weighted: yes - a third edge-list column supplies tie values. Signed: not checked. Two-mode: yes, via `twomode` - an exact alias for [nw2fromedge](nw2fromedge), the command that actually implements two-mode edge-list import (see that command's own help file for the full behavior, where isolate preservation below does not apply). A node with zero ties (an isolate) can never appear as a ROW in an edgelist - there is no pair to write - but a round trip through [nwtoedge](nwtoedge) specifically is not affected: `nwtoedge` attaches its source network's own full node list to the edgelist dataset (invisibly - no extra variables or rows), and `nwfromedge` automatically adds back any node that list has but the edgelist's own ties did not reproduce. A hand-built or externally-sourced edgelist carries no such list, so isolates neither of those every had are genuinely unrepresentable - add them with [nwaddnodes](nwaddnodes) same as always.
