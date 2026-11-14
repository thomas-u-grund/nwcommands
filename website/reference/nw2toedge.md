---
title: "nw2toedge"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Convert a two-mode network to an edge list"
---

# `nw2toedge`

Convert a two-mode network to an edge list

## Syntax

```stata
nw2toedge
[netlist]
[,
egovars(varlist)
altervars(varlist)
ego(newvarname)
alter(newvarname)
compress
full
upper
ignore2mode
isolates0
allpairs]
```

| | |
|---|---|
| `egovars(varlist)` | Keep attributes of sending nodes |
| `altervars(varlist)` | Keep attributes of receiving nodes |
| `ego(newvarname)` | Sender of ties; default = *_ego* |
| `alter(newvarname)` | Receiver of ties; default = *_alter* |
| `compress` | Drop rows with no tie in any listed network, keeping only actual ties |
| `full` | List both *(i,j)* and *(j,i)* for an undirected network's dyads, rather than only one entry per dyad; forced automatically whenever any network in a [netlist](netlist) is directed |
| `upper` | List only one entry per undirected dyad (the default; see `full` above) - has no effect and is suppressed with a warning on a directed network |
| `ignore2mode` | Treat the two-mode network like a one-mode one - suppress the auto-generated *_nwmode_ego*/*_nwmode_alter* mode-indicator variables |
| `isolates0` | reserved; not currently implemented |
| `allpairs` | Also write the pairs of nodes of different modes without a tie (by default the ties only, as with `compress`) |

## Description

`nw2toedge` makes an edgelist from a two-mode network or a list of networks.

An edgelist of a single network [netname](netname) produced by `nw2toedge` is a set of three variables representing the relations in the network. The first variable (*_ego*) gives the [node label](nodeid) of the sending node *i* of a relationship; the second variable (*_alter*) gives the [node label](nodeid) of the receiving node *j*. Lastly, the variable *netname* saves information about the dyad pair (*i*,*j*) in the network *netname*.

When a network is undirected only one entry for the dyad pair (*i*,*j*) is generated, unless option `full` is specified.

When the command is used with a [netlist](netlist), it generates one new variable for each network *netname* in the list. If only one of the networks in [netlist](netlist) is directed, the option `full` is enforced.

One can also include node attributes (saved as normal Stata variables) in the edgelist. Option `egovars()` generates new variables that match the attributes of the sender of a tie (ego); option `altervars()` generates new variables that match the attributes of the receiver of a tie (alter).

For two-mode networks (see [introduction to two-mode networks](nw2set)) the command automatically generates the two variables *_nwmode_ego* and *_nwmode_alter*. They indicate in the edgelist format the mode to which a node belongs. By default only the ties are listed (as with `compress`). With `allpairs`, `nw2toedge` lists every pair of nodes of different modes, while [nwtoedge](nwtoedge) with `allpairs` also lists the pairs of nodes of the same mode.

## Network types

**Directed:** not applicable. **Valued:** the tie values are carried into the edge list. **Two-mode:** yes - one row per tie between the two modes, with the mode of both nodes; `allpairs` also writes the pairs without a tie. **Signed:** negative values are written like any other value. See [nwnetworktypes](nwnetworktypes).

## Limits

Only the dyads between the two modes are listed, so the size grows with the product of the two mode sizes. Measured in Stata/BE for N mode-1 and N/2 mode-2 nodes with 10 ties per mode-1 node: 1,000 nodes 0.7 seconds, 5,000 nodes 24 seconds with `allpairs`; by default (ties only) 1,000 / 5,000 nodes in 0.7 / 1.0 seconds.

## Examples

Build a small two-mode network (3 people x 2 events) and convert it to an edgelist:

```stata
. nwclear
. mata: net = (1,0 \ 1,1 \ 0,1)
. nw2set, mat(net) name(attendance)
. nw2toedge attendance
. list
```

## See also

- [nw2fromedge](nw2fromedge), [nwtoedge](nwtoedge), [nwsave](nwsave)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
