---
title: "nwtoedge"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Convert two-mode network to edgelist"
---

# `nwtoedge`

Convert two-mode network to edgelist

## Syntax

```stata
nw2toedge
[netlist]
[,
egovars(varlist)
altervars(varlist)
ego(newvarname)
alter(newvarname)]
```

| | |
|---|---|
| `egovars(varlist)` | Keep attributes of sending nodes |
| `altervars(varlist)` | Keep attributes of receiving nodes |
| `ego(newvarname)` | Sender of ties; default = *_ego* |
| `alter(newvarname)` | Receiver of ties; default = *_alter* |
| `compress` | Drop rows with no tie in any listed network, keeping only actual ties |
| `full` | List both *(i,j)* and *(j,i)* for an undirected network's dyads, rather than only one entry per dyad; forced automatically whenever any network in a [netlist](netlist.md) is directed |
| `upper` | List only one entry per undirected dyad (the default; see `full` above) - has no effect and is suppressed with a warning on a directed network |
| `ignore2mode` | Treat the two-mode network like a one-mode one - suppress the auto-generated *_nwmode_ego*/*_nwmode_alter* mode-indicator variables |
| `isolates0` | reserved; not currently implemented |

## Description

`nwtoedge` makes an edgelist from a two-mode network or a list of networks.

An edgelist of a single network [netname](netname.md) produced by `nwtoedge` is a set of three variables representing the relations in the network. The first variable (*_ego*) gives the [nodeid](nodeid.md) of the sending node *i* of a relationship; the second variable (*_alter*) gives the [nodeid](nodeid.md) of the receiving node *j*. Lastly, the variable *netname* saves information about the dyad pair (*i*,*j*) in the network *netname*.

When a network is undirected only one entry for the dyad pair (*i*,*j*) is generated, unless option `full` is specified.

When the command is used with a [netlist](netlist.md), it generates one new variable for each network *netname* in the list. If only one of the networks in [netlist](netlist.md) is directed, the option `full` is enforced.

One can also include node attributes (saved as normal Stata variables) in the edgelist. Option `egovars()` generates new variables that match the attributes of the sender of a tie (ego); option `altervars()` generates new variables that match the attributes of the receiver of a tie (alter).

For two-mode networks (see [introduction to two-mode networks](nw2set.md)) the command automatically generates the two variables *_nwmode_ego* and *_nwmode_alter*. They indicate in the edgelist format the mode to which a node belongs. Unlike [nwtoedge](nwtoedge.md) on a two-mode network, `nw2toedge` also filters the edgelist down to cross-mode pairs only (dropping any same-mode/self entry the underlying dense representation may otherwise still enumerate) - this is the one behavioral difference between the two commands; see [nwtoedge](nwtoedge.md)'s own help file if you specifically need the unfiltered enumeration.

## Examples

Build a small two-mode network (3 people x 2 events) and convert it to an edgelist:

```stata
. nwclear
. mata: net = (1,0 \ 1,1 \ 0,1)
. nw2set, mat(net) name(attendance)
. nw2toedge attendance
. list
```

## Supported network types

Two-mode: **T1**, native - this command's entire purpose is converting a two-mode network to an edge list. Binary: yes. Directed: not applicable. Weighted: yes, tie values are carried into the edge list. Signed: not checked.

## See also

- [nw2fromedge](nw2fromedge.md), [nwtoedge](nwtoedge.md), [nwsave](nwsave.md)

- last certified : 28 Aug 2026
