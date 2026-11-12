---
title: "nwcoreperiphery"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Discrete core-periphery detection"
---

# `nwcoreperiphery`

Discrete core-periphery detection

## Syntax

```stata
nwcoreperiphery
[netlist]
[,
generate(newvarname)
replace
measure(string)
maxiter(int)
silent]
```

| | |
|---|---|
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores core membership |
| `replace` | Replace existing variable |
| `measure(binary\|valued)` | Whether to use tie values (*valued*) or only presence/absence of ties (*binary*); default = *valued* for valued networks, *binary* otherwise |
| `maxiter(int)` | Maximum number of local-search sweeps before giving up on convergence; default = 100 |
| `silent` | Suppress display of results |

## Description

`nwcoreperiphery` partitions the nodes of a network into a "core" and a "periphery" using the discrete core-periphery model (Borgatti and Everett 1999). The core-periphery model assumes ties are expected between any pair of nodes where at least one is a core member (core-core and core-periphery ties are both structurally expected), while periphery-periphery ties are not expected at all. `nwcoreperiphery` searches for the 0/1 assignment (0 = periphery, 1 = core) whose implied pattern correlates as highly as possible with the network actually observed, starting from a degree-based seed and then repeatedly trying to flip each node's status in turn, keeping any flip that improves the correlation, until a full sweep produces no further improvement. This is a greedy local search, not an exhaustive search over all 2^n possible partitions, so it can settle on a good but not necessarily globally optimal partition - the same character of algorithm [nwcommunity](nwcommunity) already uses for modularity maximization.

`generate()` is required and names the new variable which stores, for each node, 1 if it was assigned to the core and 0 if it was assigned to the periphery. With more than one network in the *netlist*, a number is appended to the name (*newvarname***1**, *newvarname***2**, ...) and the stored results are those of the last network.

Always operates on the undirected version of the network (the classical model does not distinguish incoming from outgoing ties); a directed network is symmetrized automatically - no separate **symmetrize** option is needed or offered (unlike [nwcommunity](nwcommunity), which needs **symmetrize** for a directed network).

## Examples

```stata
. nwwebuse florentine, nwclear
. nwcoreperiphery flomarriage, generate(_core)
```

## Stored results

- **Scalars**
- **r(fitness)** --- correlation between the observed network and the ideal pattern implied by the found partition (-1 to 1; 1 = a perfect discrete core-periphery structure)
- **r(core)** --- number of nodes assigned to the core

## References

Borgatti, S.P., Everett, M.G. (1999). Models of core/periphery structures. *Social Networks* 21(4), 375-395.

## See also

- [nwconcor](nwconcor), [nwcommunity](nwcommunity), [nwconstraint](nwconstraint)

---

*nwcommands version 3.21.0, 12 November 2026* ([check your installed version](nwversion))
