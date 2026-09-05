---
title: "nwtoedge"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Convert network to edgelist"
---

# `nwtoedge`

Convert network to edgelist

## Syntax

```stata
nwtoedge 
[netlist]
[,
egovars(varlist)
altervars(varlist)
ego(newvarname)
alter(newvarname)
comparevars(varlist)
comparemode(mode)]
```

| | |
|---|---|
| `egovars(varlist)` | Keep attributes of sending nodes |
| `altervars(varlist)` | Keep attributes of receiving nodes |
| `ego(newvarname)` | Sender of ties; default = *_ego* |
| `alter(newvarname)` | Receiver of ties; default = *_alter* |
| `comparevars(varlist)` | Add an ego/alter comparison column for each variable (e.g. *same*, *dist*) |
| `comparemode`(*[mode](nwexpand)*) | Comparison used for `comparevars()`; default = *same* |
| `compress` | Compress edgelist |
| `full` | List both *(i,j)* and *(j,i)* for an undirected network's dyads, rather than only one entry per dyad; forced automatically whenever any network in a [netlist](netlist) is directed |
| `upper` | List only one entry per undirected dyad (the default; see `full` above) - has no effect and is suppressed with a warning on a directed network |
| `numeric` | Return every possible node pair (a full node x node grid), not just actual ties; only allowed with a single network |
| `ignore2mode` | Treat a two-mode network like a one-mode one - suppress the mode indicator that would otherwise be added to `egovars()`/`altervars()` automatically |
| `isolates0` | reserved; not currently implemented |

## Description

`nwtoedge` makes an edgelist from a network or a list of networks.

An edgelist of a single network [netname](netname) produced by `nwtoedge` is a set of three variables representing the relations in the network. The first variable (*_ego*) gives the [nodeid](nodeid) of the sending node *i* of a relationship; the second variable (*_alter*) gives the [nodeid](nodeid) of the receiving node *j*. Lastly, the variable *netname* saves information about the dyad pair (*i*,*j*) in the network *netname*.

When a network is undirected only one entry for the dyad pair (*i*,*j*) is generated, unless option `full` is specified.

When the command is used with a [netlist](netlist), it generates one new variable for each network *netname* in the list. If only one of the networks in [netlist](netlist) is directed, the option `full` is enforced.

One can also include node attributes (saved as normal Stata variables) in the edgelist. Option `egovars()` generates new variables that match the attributes of the sender of a tie (ego); option `altervars()` generates new variables that match the attributes of the receiver of a tie (alter).

For example,

```stata
. nwwebuse glasgow1
```
- . nwtoedge glasgow1, egovars(sport1)
- . list
- hline 9c -hline 7c -hline 10c -hline 13
- c | _ego _alter glasgow1 from_sport1 c |
- hline 9c -hline 7c -hline 10c -hline 13
- 1. c | 1 1 0 regular c |
- 2. c | 1 2 0 regular c |
- 3. c | 1 3 0 regular c |
- 4. c | 1 4 0 regular c |
- 5. c | 1 5 0 regular c |
- hline 9c -hline 7c -hline 10c -hline 13
- 6. c | 1 6 0 regular c |
- .....
- hline 9c -hline 7c -hline 10c -hline 13
- 11. c | 1 11 1 regular c |
- 12. c | 1 12 0 regular c |
- 13. c | 1 13 0 regular c |
- 14. c | 1 14 1 regular c |
- 15. c | 1 15 0 regular c |
- hline 9c -hline 7c -hline 10c -hline 13
- .....

loads the [Glasgow data](netexample) and transforms the network *glasgow1* in an edgelist. For example, *glasgow1[11] = 1* means, that there is a network tie from node 1 to node 11. It also generates a new variable *from_sport1*, which holds in this case information about the attribute of the sender of a tie on the original variable *sport1*.

For two-mode networks see [introduction to two-mode networks](nw2set)) and [nw2toedge](nw2toedge).

The command can also transform two (or more) networks in edgelists at the same time.

```stata
. nwtoedge glasgow1 glasgow2
```
This generates a dataset with one variable for each network, *glasgow1* and *glasgow2*:

- . list
- hline 9c -hline 7c -hline 10c -hline 10
- c | _ego _alter glasgow1 glasgow2 c |
- hline 9c -hline 7c -hline 10c -hline 10
- 1. c | 1 1 0 0 c |
- 2. c | 1 2 0 0 c |
- 3. c | 1 3 0 0 c |
- 4. c | 1 4 0 0 c |
- 5. c | 1 5 0 0 c |
- hline 9c -hline 7c -hline 10c -hline 10
- 6. c | 1 6 0 0 c |
- 7. c | 1 7 0 0 c |
- 8. c | 1 8 0 0 c |
- 9. c | 1 9 0 0 c |
- 10. c | 1 10 0 1 c |
- hline 9c -hline 7c -hline 10c -hline 10
- 11. c | 1 11 1 0 c |
- 12. c | 1 12 0 0 c |
- 13. c | 1 13 0 0 c |
- 14. c | 1 14 1 1 c |
- 15. c | 1 15 0 0 c |
- .....

`comparevars(varlist)` adds an ego/alter *comparison* column for each listed variable, alongside (not instead of) whatever `egovars()`/`altervars()` already add - e.g. "do ego and alter share the same value" or "how far apart are their values", rather than just the two raw values side by side. `comparemode()` picks which comparison (any [nwexpand mode](nwexpand) - **same** (the default), **dist**, **absdist**, **distinv**, **absdistinv**, **sender**, **receiver**) applies to every variable in `comparevars()`; each variable is internally expanded via [nwexpand](nwexpand) itself (so the exact same, already-certified comparison logic is used, not a reimplementation) and the resulting column is named *mode_varname* - matching [nwexpand](nwexpand)'s own default naming - e.g. `comparevars(sport1)` with the default **comparemode(same)** adds a column named *same_sport1*. **dist**/**distinv**/**sender**/ **receiver** comparisons are directional (ego's value relative to alter's, not the reverse), so adding one automatically triggers the same "any directed network in the list forces `full`" rule already used for a mixed directed/undirected [netlist](netlist) - every dyad appears in both directions, so the signed comparison is preserved correctly for both.

```stata
. nwwebuse glasgow, nwclear
. nwtoedge glasgow1, comparevars(sport1) comparemode(same)
. nwtoedge glasgow1, comparevars(sport1) comparemode(dist)
```

## Supported network types

Binary: yes. Directed: yes. Weighted: yes, tie values are carried into the edge list. Signed: not checked. Two-mode: yes - see [nw2toedge](nw2toedge) for the two-mode-specific counterpart, though this command's own `egovars()`/`altervars()` two-mode handling is used internally by several other commands directly on a two-mode network too.

## See also

- [nwfromedge](nwfromedge), [nw2toedge](nw2toedge), [nwsave](nwsave), [nwexpand](nwexpand)

- last certified : 24 Aug 2026
