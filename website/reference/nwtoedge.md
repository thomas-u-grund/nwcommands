---
title: "nwtoedge"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Convert a network to an edge list"
---

# `nwtoedge`

Convert a network to an edge list

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
comparemode(mode)
compress
full
upper
numeric
ignore2mode
all:pairs
time
agg:regate]
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
| `numeric` | Programming option: replace the node names in *ego* and *alter* with the node numbers of a full node x node grid (for the list of all dyads); only allowed with a single network |
| `ignore2mode` | Treat a two-mode network like a one-mode one - suppress the mode indicator that would otherwise be added to `egovars()`/`altervars()` automatically |
| `isolates0` | reserved; not currently implemented |
| `all:pairs` | Two-mode network: also write the pairs of nodes of different modes without a tie (by default a two-mode network is written as its ties, as with `compress`) |
| `time` | Temporal network: list one row per event, per observation of a tie or per interval, with the time(s) (see [Temporal networks](nwtoedge)) |
| `agg:regate` | Temporal network: list each tie once, aggregated over all times, without the note |

## Description

`nwtoedge` makes an edgelist from a network or a list of networks.

An edgelist of a single network [netname](netname) produced by `nwtoedge` is a set of three variables representing the relations in the network. The first variable (*_ego*) gives the [nodeid](nodeid) of the sending node *i* of a relationship; the second variable (*_alter*) gives the [nodeid](nodeid) of the receiving node *j*. Lastly, the variable *netname* saves information about the dyad pair (*i*,*j*) in the network *netname*.

When a network is undirected only one entry for the dyad pair (*i*,*j*) is generated, unless option `full` is specified. For an undirected valued network the listed pairs are those with *_ego* > *_alter*, so each tie appears once, in the row of the higher node id.

When the command is used with a [netlist](netlist), it generates one new variable for each network *netname* in the list. If only one of the networks in [netlist](netlist) is directed, the option `full` is enforced.

One can also include node attributes (saved as normal Stata variables) in the edgelist. Option `egovars()` generates new variables that match the attributes of the sender of a tie (ego); option `altervars()` generates new variables that match the attributes of the receiver of a tie (alter).

For example,

```stata
. nwwebuse glasgow1
. nwtoedge glasgow1, egovars(sport1)
. list

    +------------------------------------------+
    | _ego    _alter    glasgow1   from_sport1 |
    |------------------------------------------|
 1. |       1       1          0       regular |
 2. |       1       2          0       regular |
 3. |       1       3          0       regular |
 4. |       1       4          0       regular |
 5. |       1       5          0       regular |
    |------------------------------------------|
 6. |       1       6          0       regular |
              .....
    |------------------------------------------|
11. |       1      11          1       regular |
12. |       1      12          0       regular |
13. |       1      13          0       regular |
14. |       1      14          1       regular |
15. |       1      15          0       regular |
    |------------------------------------------|
              .....
```
loads the [Glasgow data](netexample) and transforms the network *glasgow1* in an edgelist. For example, *glasgow1[11] = 1* means, that there is a network tie from node 1 to node 11. It also generates a new variable *from_sport1*, which holds in this case information about the attribute of the sender of a tie on the original variable *sport1*.

For two-mode networks see [introduction to two-mode networks](nw2set)) and [nw2toedge](nw2toedge).

**Temporal networks.** A network declared with `time()`, `interval()` or `eventtime()` in [nwset](nwset) holds times that the list of ties above does not have: that list holds each tie once, aggregated over all times (for an event network every pair with at least one event), and the command says so in a note. `aggregate` states the aggregation and leaves the note out. With `time` the data in memory are replaced by one row for every event of an event network (in the order given), every observation of a tie of a snapshot network, or every interval of an interval network, for a single one-mode network: the variables *_ego* and *_alter* (or the names in `ego()` and `alter()`), *_time* (event and snapshot networks) or *_start* and *_end* (interval networks), and *_value* for a valued event network. An undirected snapshot or interval network lists each tie once. [nwset](nwset) with `eventtime()`, `time()` or `interval()` turns the rows into the network again. `time` cannot be combined with `aggregate` or with the options of the list of ties above (except `ego()` and `alter()`); error 198.

```stata
. nwtoedge calls, time
. nwset _ego _alter, eventtime(_time) name(calls2) directed
```
The command can also transform two (or more) networks in edgelists at the same time.

```stata
. nwtoedge glasgow1 glasgow2
```
This generates a dataset with one variable for each network, *glasgow1* and *glasgow2*:

```stata
. list

    +---------------------------------------+
    | _ego    _alter    glasgow1   glasgow2 |
    |---------------------------------------|
 1. |       1       1          0          0 |
 2. |       1       2          0          0 |
 3. |       1       3          0          0 |
 4. |       1       4          0          0 |
 5. |       1       5          0          0 |
    |---------------------------------------|
 6. |       1       6          0          0 |
 7. |       1       7          0          0 |
 8. |       1       8          0          0 |
 9. |       1       9          0          0 |
10. |       1      10          0          1 |
    |---------------------------------------|
11. |       1      11          1          0 |
12. |       1      12          0          0 |
13. |       1      13          0          0 |
14. |       1      14          1          1 |
15. |       1      15          0          0 |
              .....
```
`comparevars(varlist)` adds an ego/alter *comparison* column for each listed variable, alongside (not instead of) whatever `egovars()`/`altervars()` already add - e.g. "do ego and alter share the same value" or "how far apart are their values", rather than just the two raw values side by side. `comparemode()` picks which comparison (any [nwexpand mode](nwexpand) - **same** (the default), **dist**, **absdist**, **distinv**, **absdistinv**, **sender**, **receiver**) applies to every variable in `comparevars()`; each variable is internally expanded via [nwexpand](nwexpand) itself (so the exact same, already-certified comparison logic is used, not a reimplementation) and the resulting column is named *mode_varname* - matching [nwexpand](nwexpand)'s own default naming - e.g. `comparevars(sport1)` with the default **comparemode(same)** adds a column named *same_sport1*. **dist**/**distinv**/**sender**/ **receiver** comparisons are directional (ego's value relative to alter's, not the reverse), so adding one automatically triggers the same "any directed network in the list forces `full`" rule already used for a mixed directed/undirected [netlist](netlist) - every dyad appears in both directions, so the signed comparison is preserved correctly for both.

```stata
. nwwebuse glasgow, nwclear
. nwtoedge glasgow1, comparevars(sport1) comparemode(same)
. nwtoedge glasgow1, comparevars(sport1) comparemode(dist)
```

## Network types

**Directed:** yes. **Valued:** tie values are written to the edge list. **Two-mode:** yes - one row per tie between the modes (`allpairs`: every pair) with the modes of both nodes. **Signed:** not checked. The node list is stored with the data, so [nwfromedge](nwfromedge) restores isolates. See [nwnetworktypes](nwnetworktypes).

## Limits

The list of *all* dyads (without `compress`) has one row for every pair of nodes, so its size grows with the square of the number of nodes. Measured in Stata/BE, random directed network with 10 ties per node: 1,000 nodes (1,000,000 rows) 0.5 seconds, 5,000 nodes (25,000,000 rows) 20 seconds and 3.2 GB; above 50,000,000 rows (7,072 nodes, 10,000 for an undirected network) the command stops with an error that recommends `compress`. With `compress` only the ties are listed: 1,000 / 5,000 / 20,000 nodes in 0.08 / 0.24 / 0.9 seconds. For a two-mode network `compress` lists only the ties between the two modes (as [nw2toedge](nw2toedge) does), never the pairs of nodes inside one mode.

For all commands at network sizes of 1,000 to 100,000 nodes see the web page [How large a network can I analyze?](https://nwcommands.org/nwcommands/size-limits/)

## See also

- [nwfromedge](nwfromedge), [nw2toedge](nw2toedge), [nwsave](nwsave), [nwexpand](nwexpand)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
