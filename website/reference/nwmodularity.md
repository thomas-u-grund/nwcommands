---
title: "nwmodularity"
parent: "Command reference"
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
SYMmetrize
resolution(real)
silent]
```

| | |
|---|---|
| `group(varname)` | Stata variable holding each node's community/group assignment |
| `measure(binary\|valued)` | Whether to use tie values (*valued*) or only presence/absence of ties (*binary*); default = *valued* for valued networks, *binary* otherwise |
| `symmetrize` | Symmetrize a directed network before scoring (required for directed networks) |
| `resolution(real)` | Resolution parameter (Reichardt-Bornholdt); must be > 0; default = 1 |
| `silent` | Suppress display of results |

## Description

`nwmodularity` computes Newman's modularity *Q* of the network(s) in [netlist](netlist) against an ul:existing node partition given in **group()** — for example a partition obtained from [nwcomponents](nwcomponents), a block model, or any hand-coded grouping variable. Unlike [nwcommunity](nwcommunity), `nwmodularity` does not search for a partition; it only scores the one given. All calculations are performed on the undirected network; directed networks require **symmetrize**.

Modularity compares the fraction of ties that fall within the given groups to the fraction expected under a random network with the same degree sequence. Values near 0 indicate the grouping is no better than chance; higher (positive) values indicate a grouping that captures real community structure. Scoring a single, all-nodes-in-one-group partition always gives *Q* = 0, for any network.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwcomponents flomarriage, generate(comp)
. nwmodularity flomarriage, group(comp)
```

## Supported network types

Binary: yes. Directed: requires `symmetrize` - modularity as computed here is not defined for a directed network. Weighted: yes, via `measure(binary|valued)`; default = *valued* for a valued network, *binary* otherwise. Signed: not checked. Two-mode: not checked.

## Stored results

**Scalars**

- **r(communities)** number of distinct groups in **group()**
- **r(modularity)** modularity Q of the given partition

**Matrices**

- **r(comm_sizeid)** distribution over groups

## References

Newman, M.E.J. (2006). Modularity and community structure in networks. *PNAS* 103(23), 8577-8582.

## See also

- [nwcommunity](nwcommunity), [nwcomponents](nwcomponents)
