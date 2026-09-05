---
title: "nwset"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Declare data to be network data"
---

# `nwset`

Declare data to be network data

## Syntax

```stata
Declare data to be network data
nwset varlist [, options ]
nwset
,
mat(matamatrix)
[ options ]
Declare a two-mode network from an edgelist of two id variables (see below)
nwset mode1id mode2id [tievalue] , twomode [ options ]
Declare a two-mode network from a Mata matrix or a wide affiliation-matrix varlist (see below)
nwset [varlist] , bipartite [mat(matamatrix)] [ options ]
Declare a temporal network from an edgelist (see below)
nwset fromid toid [tievalue] , time(varname) [ options ]
nwset fromid toid [tievalue] , interval(startvar endvar) [ options ]
nwset fromid toid , eventtime(varname) [ options ]
Display currently existing networks
nwset
Display more details about existing networks
nwset, detail
Clear all networks (but keep Stata variables)
nwset, clear
Clear all networks and Stata variables
nwset, nwclear
```

| | |
|---|---|
| `edgelist` | Declare data in edgelist format |
| `bipartite` | Declare a two-mode network from a Mata matrix or a wide affiliation-matrix `varlist` (see [Declare a two-mode network](nwset.md) below) |
| `twomode` | Declare a two-mode network from an edgelist of two (or three, for a valued network) id variables (see [Declare a two-mode network](nwset.md) below) |
| `mat(matamatrix)` | Declare a network directly from an existing Mata matrix (or a literal matrix expression) instead of `varlist`/an edgelist |
| `directed` | Force network to be directed |
| `undirected` | Force network to be undirected |
| `valued` | Force network to be treated as valued (tie strength, not just presence/absence) |
| `unvalued` | Force network to be treated as unvalued (binary) |
| `selfloop` | Allow self-loops (a tie from a node to itself); by default the diagonal is always blanked |
| `name`(*[newnetname](newnetname.md)*) | Name of the new network; default = *network* |
| `replace` | Overwrite an existing network of the same name instead of auto-picking a different valid name with a warning |
| `overwrite` | Backward-compatible alias for `replace` |
| `nodenames(string)` | Set the network's own node identifiers directly (a Mata expression evaluating to a string or numeric vector), independent of `labs()` |
| `labs`(*lab1, lab2,...*) | Node labels |
| `labsfromvar(varname)` | Use information in varname as node labels |
| `vars(varlist)` | Save network node identifiers/labels from these existing Stata variables instead of generating new ones (the inverse of `xvars`); must have as many entries as there are nodes |
| `biprownames(varname)` | `bipartite` only: use this variable's own values as mode-1 row names instead of the default sequential numbering |
| `edgelabs(string)` | Edgelist declarations only: labels for the two (or three) id variables themselves, used in messages/output |
| `xvars` | Generate Stata variables for the network |
| `keeporiginal` | Generate variable *_nodeoriginal* with original node id's (when setting from an edgelist) |
| `detail` | Display more detail (node/edge counts, directedness, etc.) about existing networks when `nwset` is called with no arguments |
| `nooutput` | Suppress the summary display normally printed after declaring a network |
| `clear` | Clear all networks (but keep Stata variables) |
| `nwclear` | Synonym for `clear` |
| `time(varname)` | Declare a snapshot temporal network - each row's own time value (see [Declare a temporal network](nwset.md) below) |
| `interval(startvar endvar)` | Declare an interval temporal network - each row active for start<=t<end (see [Declare a temporal network](nwset.md) below) |
| `eventtime(varname)` | Declare an event temporal network - each row a timestamped event, not a persistent tie (see [Declare a temporal network](nwset.md) below) |

## Description

This command declares data to be network data (it is very similar to `xtset` or `stset`). When networks are [imported](nwimport.md) or [used](nwuse.md) or loaded from the [internet](nwwebuse.md) or created from an [edgelist](nwfromedge.md) or created by any other [network generator](nw_topical.md), **nwset** is automatically invoked. But one can also explicitly declare data to be network data.

Networks ultimately exist as objects in Mata. Once a network is declared one can interact with it from Stata by referring to its [netname](netname.md). In practice, this works just as if one would refer to a `varname` in other commands. The command sets a new network by assigning it an adjacency matrix. It can also be used to assign various meta-information to the network.

An adjacency matrix is a simple representation of a network. The adjaceny matrix *M* of a one-mode network has the dimensions *nodes* x *nodes*. The matrix cell *M_ij* = 0 when there is no tie between nodes *i* and *j*. In binary networks, *M_ij* = 1 when there is a network relationship between nodes *i* and *j*. However, networks can also be valued, i.e. *M_ij* > 1; in undirected networks *M_ij = M_ji*.

The command automatically recognizes if the network is unvalued (only has values 0, 1 or missing) or valued.

There are three ways to explicitly declare data to be network data:

**ul:1. Declare adjacency matrix from variables**

Declare the variables in `varlist` to represent the adjacency matrix of the network. In this case a `varlist` (var_1, var_2,..., var_z) needs to be given. Each variable is assumed to stand for one column in the adjacency matrix.

*M_ij = var_i[j]*

When there are more observations *n* than variables *z*, only the the first *z* observations of each variable are considered. When there are more variables than observations, then only the first *n* variables are considered as network data.

In this dummy example, we create 5 new variables v1-v5 and set a network from these variables. It creates an empty network (there are no ties).

```stata
. nwclear
. forvalues i = 1/5{
gen v = 0
}
. nwset v*
```
After that we can display the networks that have been set (see also [nwsummarize](nwsummarize.md) or [nwds](nwds.md))

```stata
. nwset, detail
```
- hline 50
- 1) Current Network
- hline 50
- Network name: network
- Directed: true
- Nodes: 5
- Network id: 1
- Variables: v1 v2 v3 v4 v5
- Labels: v1 v2 v3 v4 v5

There is exactly one network. When neither **name()**, **vars()**, or **labs()** are specified, the command comes up with a suggestion to fill this meta-information.

**ul:2. Declare edgelist from variables**

In this case, the command interprets the variables `varlist` as egdelist (see [nwfromedge](nwfromedge.md)).

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

The following command declares such data as network data and gives the new network the name *mynet*:

```stata
. nwset fromid toid value, name(mynet) edgelist
```
**ul:3. Declare adjacency matrix from Mata matrix**

Set a network from a *nodes x nodes* Mata matrix that holds the adjacency matrix of the new network. The option **mat()** is specified with the name of an existing Mata matrix.

For example, this generates a Mata matrix:

```stata
. nwclear
. mata: net = (0,1,0,0\1,0,0,1\1,1,0,0\1,1,1,0)
. nwset, mat(net) name(network)
```
This also generates a network called *network*. When no **name()** for a network is specified, the command makes a valid suggestion (see [nwvalidate](nwvalidate.md)).

Now a network called *network* exists and we can interact with it. For example, we can get a summary of the network:

- . nwsummarize network, mat
- hline 50
- Network name: network
- Network id: 1
- Directed: true
- Nodes: 4
- Arcs: 8
- Minimum value: 0
- Maximum value: 1
- Density: .6666666666666666
- 1 2 3 4
- hline 17
- 1 c | 0 1 0 0 c |
- 2 c | 1 0 0 1 c |
- 3 c | 1 1 0 0 c |
- 4 c | 1 1 1 0 c |
- hline 17

**ul:4. Declare a two-mode network**

A two-mode (bipartite) network has two distinct sets of nodes ("modes"), with ties running only *between* the two sets, never within either one - e.g. people and the organisations they belong to. Two-mode status is stored directly on the network object itself (queryable via [nwsummarize](nwsummarize.md) or [nwname](nwname.md)'s own **r(mode2)**/**r(nodes1)**/**r(nodes2)** results), the same as directed/valued/selfloop status - there are two ways to declare one, matching the two input shapes **nwset** already supports for one-mode networks:

**twomode** - from an edgelist of two (or three, for a valued network) id variables, one row per tie, directly analogous to **edgelist** above. This is generally the more natural form when the data already looks like a list of affiliations:

```stata
. nwclear
. use "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop/data/institutions.dta", clear
. nwset person institution, twomode name(mynet)
```
This also automatically sets each mode's own human-readable description from the variable names used (*person*/*institution* here - see **r(mode1desc)**/**r(mode2desc)** in [nwname](nwname.md), [nwsummarize](nwsummarize.md)), and (if **xvars** is given) generates a *_mode* variable holding each node's own mode ("1" for persons, "2" for institutions - see [nw2fromedge](nw2fromedge.md) for the full option set this delegates to internally, including **name()**/**xvars**/**keeporiginal**). **twomode** cannot be combined with **bipartite** - they declare two different input shapes (an edgelist of ties vs. a wide affiliation matrix, below) that cannot be told apart from a bare `varlist` alone, so combining them is rejected as an explicit error rather than guessed at.

Like any edgelist-based declaration (**edgelist** above included), **twomode** can only ever create nodes that actually appear in the edgelist - a node with zero ties (an isolate) is never created, silently, since an edgelist has no way to record it in the first place. Use [nwaddnodes](nwaddnodes.md)'s own **mode()** option afterward to add any isolates the source data itself could not represent (required, not optional, on a two-mode network - it never silently assumes which of the two modes an added isolate belongs to).

**bipartite** - from a Mata matrix, or from a `varlist` interpreted as a *wide* affiliation matrix (each named variable is one mode-1 node, each observation is one mode-2 node) - the two-mode analogue of the plain adjacency-matrix forms in sections 1 and 3 above:

```stata
. nwclear
. mata: net = (1,1,0\1,0,1\0,1,1)
. nwset, mat(net) bipartite name(mynet)
```
Here **net** is a 3 (mode 1) x 3 (mode 2) matrix - **bipartite** tells **nwset** the matrix's own columns are mode-1 nodes and its rows are mode-2 nodes, rather than treating it as an ordinary square one-mode adjacency matrix.

Ordinary **nw*** commands inspect a network's own two-mode status and behave accordingly rather than requiring a separate command family for bipartite data - see each command's own help file for whether it has a native bipartite definition, works on the raw bipartite structure directly, requires an explicit projection (see [nw2project](nw2project.md) - **nwset** and the rest of the package never project automatically), or does not support two-mode data at all.

- **ul:5. Declare a temporal network**

Time belongs to edges/ties, not to a separate network copy per timepoint. An edgelist can carry a temporal dimension via exactly one of three options - **time()**, **interval()**, or **eventtime()** - matching three distinct semantics that are never conflated:

- **time(*timevar*)**
- **snapshot** semantics: each row's own *timevar* value is the single instant that tie
- was recorded (e.g. a wave number). Ties from different waves live in the same network object, each
- carrying its own recorded time
- **interval(*startvar endvar*)**
- **interval** semantics: each row is active for *startvar* <= *t* < *endvar* - a
- missing *endvar* means the tie is still ongoing (open-ended)
- **eventtime(*eventtimevar*)**
- **event** semantics: each row is a timestamped relational *event*, not a persistent
- tie - e.g. a message sent at a particular instant. Event data is never silently treated as an
- ordinary graph

For example, this declares a snapshot network from three waves of ties:

```stata
. nwset ego alter, time(wave) name(mynet)
```
A temporal network is otherwise a completely ordinary **nwset**-declared network - [nwsummarize](nwsummarize.md) shows its temporal metadata, and [nwattime](nwattime.md) produces an ordinary static network containing only the ties active at a given timepoint, usable with any **nw*** command exactly like any other network.

**time()**/**interval()**/**eventtime()** CAN be combined with **twomode** in the same call - a two-mode temporal network, declared exactly like an ordinary **twomode** edgelist with a temporal option added:

```stata
. nwset person organisation, twomode time(wave) name(mynet)
```
**bipartite**'s own wide-affiliation-matrix shape (one variable per mode-1 node, one row per mode-2 node) has no natural per-row time value to attach, so it remains explicitly unsupported with any temporal option - use **twomode**'s edgelist shape instead. This is deliberate groundwork only, per the package's own stated scope: no full temporal-network modelling subsystem (dynamic centrality, relational-event models, temporal ERGMs) is implemented or attempted here.

## Remarks

The command **nwset** or **nwset, detail** without a `varlist` or **mat()** option, give a list of all networks that do currently exist in memory. A similar overview is provided by [nwds](nwds.md) (which is very similar to `ds`).

Although not really needed, networks can be represented with Stata variables (see [nwload](nwload.md)). For this purpose, each network holds some meta-information about which Stata variables should be created when a network is loaded in such a way. This meta-information can be set wit option **vars()**. When specified, it needs to have as many entries as there are nodes in the network. When not specified, the program automatically makes a suggestion for variable names.

By default, network generators (including `nwset` itself) only produce a network object - they do NOT load a network as Stata variables (see [nwload](nwload.md)). Many network generators allow the option **xvars**, which ADDITIONALLY loads the new network as Stata variables right away (equivalent to following the generator with a separate [nwload](nwload.md) call). Leaving **xvars** unspecified keeps Stata's own variable budget free when one deals with many or large networks - all commands that require a [netname](netname.md) still work even when no Stata variables for that network exist at all, or after ** drop _all**. This also means that one can still deal with larger networks even when using **Small Stata**.

Each node in a network also has a node label. This is a unique name for each node. This meta-information can be set with option **labs()**. As before, there need to be as many entries as there are nodes in the network. When not specified, the program automatically labels nodes according the variables that have been set.

Whenever a network is set with **nwset**, it is also made the [current network](nwcurrent.md). The current network is always the network that has been most recently loaded or generated. Many nwcommands allow that a [netname](netname.md) or a [netlist](netlist.md) is optional. In case no network is given, all nwcommands generally refer to the current network.

Programmers can use **nwset** to write their own import routines  (see also [nwimport](nwimport.md)) for different network file formats that are not natively supported by the **nwcommands**.All you need to do is transform your data either in an adjacency list or an edgelist represented by Stata variables.

## Supported network types

This command is the primary mechanism by which a network's own binary/directed/weighted/signed/two-mode status is declared in the first place (`directed`/`undirected`, `valued`/`unvalued`, `bipartite`/`twomode`), rather than a command whose own behavior varies by a pre-existing network's type. Signed values (negative ties) are accepted and stored as-is, not validated or rejected.

## See also

- [nodeid](nodeid.md), [nwname](nwname.md), [nwds](nwds.md), [nwload](nwload.md), [nwvalidate](nwvalidate.md), [nwsummarize](nwsummarize.md), [nw2fromedge](nw2fromedge.md), [nw2project](nw2project.md) ([nwproject](nwproject.md)), [nwattime](nwattime.md), [feasible network sizes](nw_intro.md)
