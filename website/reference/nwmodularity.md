---
title: "nwmodularity"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Score an existing node partition using Newman's modularity"
---

# `nwmodularity`

Score an existing node partition using Newman's modularity

## Syntax

```stata
nwmodularity
[netlist]
,
group(varname)
[measure(string)
sym:metrize
resolution(real)
silent
one:mode]
```

| | |
|---|---|
| `group(varname)` | Stata variable holding each node's community/group assignment |
| `measure(binary\|valued)` | Whether to use tie values (*valued*) or only presence/absence of ties (*binary*); default = *valued* for valued networks, *binary* otherwise |
| `sym:metrize` | Symmetrize a directed network before scoring (required for directed networks) |
| `resolution(real)` | Resolution parameter (Reichardt-Bornholdt); must be > 0; default = 1 |
| `silent` | Suppress display of results |
| `one:mode` | Two-mode network: the modularity of Newman for the bipartite graph read as a one-mode graph, instead of the bipartite modularity of Barber (the default for a two-mode network) |

## Description

`nwmodularity` computes Newman's modularity *Q* of the network(s) in [netlist](netlist) against an ul:existing node partition given in **group()** — for example a partition obtained from [nwcomponents](nwcomponents), a block model, or any hand-coded grouping variable. Unlike [nwcommunity](nwcommunity), `nwmodularity` does not search for a partition; it only scores the one given. All calculations are performed on the undirected network; directed networks require **symmetrize**.

Modularity compares the fraction of ties that fall within the given groups to the fraction expected under a random network with the same degree sequence. Values near 0 indicate the grouping is no better than chance; higher (positive) values indicate a grouping that captures real community structure. Scoring a single, all-nodes-in-one-group partition always gives *Q* = 0, for any network.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwcomponents flomarriage, generate(comp)
. nwmodularity flomarriage, group(comp)
```

## Stored results

- **Scalars**
- **r(communities)** --- number of distinct groups in **group()**
- **r(modularity)** --- modularity Q of the given partition

- **Macros**
- **r(modularity_type)** --- **barber** (bipartite modularity of a two-mode network) or **newman**

- **Matrices**
- **r(comm_sizeid)** --- distribution over groups: one row per group, columns **size**, **compid** (group value) and **share**, sorted by size

## References

Newman, M.E.J. (2006). Modularity and community structure in networks. *PNAS* 103(23), 8577-8582.

## See also

- [nwcommunity](nwcommunity), [nwcomponents](nwcomponents)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
