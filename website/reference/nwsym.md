---
title: "nwsym"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Symmetrize network"
---

# `nwsym`

Symmetrize network

## Syntax

```stata
nwsym
[netname]
[,
mode(mode)
check
generate(newntename)
replace]
```

| | |
|---|---|
| `mode`(*[mode](nwsym)*) | Logic for creating an undirected tie |
| `check` | Check if network is symmetric (regardless of whether is declared as directed or undirected) |
| `generate`(*[newnetname](newnetname)*) | Save symmetrization as new network |
| `replace` | Symmetrize in place (the default when neither `replace` nor `generate()` is given - this option exists to state that choice explicitly rather than to change behavior). Cannot be combined with `generate()` |

## Description

Symmetrizes a network and changes the meta-information of a network, i.e. it transforms a directed network in an undirected network. The logic for this transformation is defined by **mode()**.

By default, an undirected tie is formed when there is either a tie from node *i* to node *j* or a tie from node *j* to node *i*; **mode(max)**.

*M_ij = max( M_ij, M_ji )*

Alternatively, with **mode(min)** an undirected tie is only formed when there are both ties from node *i* to node *j* and a tie from node *j* to node *i*.

*M_ij = min( M_ij, M_ji )*

When not specified otherwise, the network [netname](netname) is replaced with the symmetrized network (equivalently, `replace` can be given explicitly to state this). In case `generate()` is specified the new symmetrized network is saved as [newnetname](netname) instead, and the original network is left untouched. `replace` and `generate()` are mutually exclusive.

Option **check** tests if the underlying adjacency matrix of the network is symmetric (but does not symmetrize the network). Notice that this is independent of any meta-information saved together with the network (see [nwname](nwname)). Hence, a network can be set as directed, but still be symmetric. In contrast, all undirected networks are by default also symmetric.

The logic for valued networks works in exactly the same way.

## Examples

This loads the Glasgow data and symmetrizes the network *glasgow1*. After that the originally directed network has become undirected.

```stata
. nwwebuse glasgow, nwclear
. nwsym glasgow1
```
```stata
. nwsym glasgow1, check
```
- hline 50
- Network name: glasgow1
- Directed: false
- Symmetric: true

This example only checks for symmetry, but does not change anything. Notice that by default **nwrandom** produces a directed network. However, a complete network (produced with `prob(1))`, where everybody is connected with everybody else, is also symmetric.

- . nwrandom 10, prob(1)
- . nwsym, check
- hline 50
- Network name: network
- Directed: true
- Symmetric: true

## Supported network types

Binary: yes. Directed: yes - this command's entire purpose is converting a directed network to an undirected one (or checking whether it already is). Weighted: yes - `mode()` controls how the two directions' tie values are combined (e.g. max/min/sum) when they differ. Signed: not checked. Two-mode: not applicable - a bipartite network's own cross-mode structure has no "direction" to symmetrize in the first place.

## Stored results

- Macros:
- **r(is_symmetric)** "true" or "false"
- **r(name)** name of the network

## See also

- [nwsymmetrize](nwsymmetrize) (an exact alias for this command)

- last certified : 28 Aug 2026
