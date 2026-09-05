---
title: "nwbrokerage"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Gould-Fernandez brokerage roles"
---

# `nwbrokerage`

Gould-Fernandez brokerage roles

## Syntax

```stata
nwbrokerage
[netlist]
,
group(varname)
[generate(newvarname)
replace
silent]
```

| | |
|---|---|
| `group(varname)` | Existing Stata variable holding each node's group membership (required) |
| `generate(newvarname)` | **Required.** Stem for the 5 new Stata variables that store role counts |
| `replace` | Replace existing variables |
| `silent` | Suppress display of results |

## Description

`nwbrokerage` counts, for every node *b*, how often it plays each of the five brokerage roles defined by Gould and Fernandez (1989). For every directed two-path *a -> b -> c* (with *a* != *c*) through *b*, the role is determined by comparing the group membership of *a*, *b* and *c* (from `group()`):

- **coordinator***a*, *b* and *c* all in the same group
- **gatekeeper***a* in a different group from *b*; *c* in the same group as *b*
- **representative***a* in the same group as *b*; *c* in a different group
- **consultant***a* and *c* in the same group, different from *b*'s
- **liaison***a*, *b* and *c* all in different groups

`generate()` is required and gives the stem for five new Stata variables, one per role, each holding node *b*'s count of that role (e.g. `generate(_broker)` produces *_broker_coordinator*, *_broker_gatekeeper*, *_broker_representative*, *_broker_consultant* and *_broker_liaison*).

For a directed network, *a* ranges over *b*'s incoming ties and *c* over its outgoing ties - brokerage is fundamentally about *a* reaching *c* *through* *b*. For an undirected network, incoming and outgoing ties are identical, so *a* and *c* both range over *b*'s (undirected) neighbors - the same five-role classification still applies, just without the directional distinction a directed network provides.

## Examples

```stata
. nwwebuse florentine, nwclear
. gen faction = mod(_n, 2)
. nwbrokerage flomarriage, group(faction) generate(_broker)
```

## Supported network types

Binary: yes. Directed: yes, and directionality is used directly (see Description) - this is the network type the model was originally defined for. Undirected networks are supported too, with the directional distinction collapsing away as described above. Weighted: not used - only the presence/absence of a tie determines whether a two-path exists; tie strength does not affect role counts. Signed: not checked. Two-mode: not checked - operates on the network's own square adjacency matrix. `group()` must be an existing Stata variable already aligned with the network's nodes (the same convention [nwmodularity](nwmodularity)'s own `group()` option uses) - `nwbrokerage` does not detect groups itself; pair it with [nwconcor](nwconcor), [nwcoreperiphery](nwcoreperiphery), [nwcommunity](nwcommunity), or a substantive attribute for the grouping.

## Stored results

**Scalars**

- **r(pairs)** total number of a-b-c two-paths counted, summed across all nodes and all five roles

## References

Gould, R.V., Fernandez, R.M. (1989). Structures of mediation: A formal approach to brokerage in transaction networks. *Sociological Methodology* 19, 89-126.

## See also

- [nwconcor](nwconcor), [nwcoreperiphery](nwcoreperiphery), [nwcommunity](nwcommunity), [nwmodularity](nwmodularity)

- last certified : 21 Aug 2026
