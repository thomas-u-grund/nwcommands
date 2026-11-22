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
rest:arts(#)
seed(#)
sym
silent]
```

| | |
|---|---|
| `sym` | On a directed network, analyse the symmetrized network (a tie counts in both directions, with the larger of its two values); without it a directed network with unreciprocated ties is refused (error 198) |
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores core membership |
| `replace` | Replace existing variable |
| `measure(binary\|valued)` | Whether to use tie values (*valued*) or only presence/absence of ties (*binary*); default = *valued* for valued networks, *binary* otherwise |
| `maxiter(int)` | Maximum number of local-search sweeps before giving up on convergence; default = 100 |
| `rest:arts(#)` | Number of starts of the local search; default = 1 (the degree-based start only); with more, further searches begin from random partitions and the partition with the highest fitness is kept |
| `seed(#)` | Random-number seed for the random starts; needs `restarts()` of 2 or more |
| `silent` | Suppress display of results |

## Description

`nwcoreperiphery` partitions the nodes of a network into a "core" and a "periphery" using the discrete core-periphery model (Borgatti and Everett 1999). The core-periphery model assumes ties are expected between any pair of nodes where at least one is a core member (core-core and core-periphery ties are both structurally expected), while periphery-periphery ties are not expected at all. `nwcoreperiphery` searches for the 0/1 assignment (0 = periphery, 1 = core) whose implied pattern correlates as highly as possible with the network actually observed, starting from a degree-based seed and then repeatedly trying to flip each node's status in turn, keeping any flip that improves the correlation, until a full sweep produces no further improvement. This is a greedy local search, not an exhaustive search over all 2^n possible partitions, so it can settle on a good but not necessarily globally optimal partition (a different starting partition can give a better core) - the same character of algorithm [nwcommunity](nwcommunity) already uses for modularity maximization. The search is local: it starts from the degree-based partition and the result depends on that start. With `restarts(#)` of 2 or more, the same local search is run from further random starting partitions (every node is in the core with probability one half) and the partition with the highest fitness over all starts is kept, never lower than that of the degree-based start; the number of starts that reached the best fitness is shown and stored in **r(nbest)**. Without `restarts()` the output and the random-number state are unchanged. `restarts()` is available for networks of up to 2,000 nodes.

`generate()` is required and names the new variable which stores, for each node, 1 if it was assigned to the core and 0 if it was assigned to the periphery. With more than one network in the *netlist*, a number is appended to the name (*newvarname***1**, *newvarname***2**, ...) and the stored results are those of the last network.

The classical model does not distinguish incoming from outgoing ties, so it is defined for an undirected network: a directed network with unreciprocated ties is refused (error 198) unless option `sym` asks for the symmetrized network (as [nwcommunity](nwcommunity) does); the output says which was done.

## Network types

**Directed:** refused (error 198) when some ties are not reciprocated, because the measure is defined for an undirected network; option `sym` analyses the symmetrized network (a tie counts in both directions, with the larger of its two values) and the output says so. A directed network whose ties are all reciprocated is the same as an undirected one and is analysed as such (the output says so). **Valued:** tie values are used by default (`measure(valued)`); `measure(binary)` ignores them. **Two-mode:** not supported (error 6088; use [nwproject](nwproject) first). **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

Above 2,000 nodes the search runs on the stored ties (the sums of the correlation with the ideal pattern are taken from the ties; the cores found are those of the matrix version, the fitness equal up to rounding in the last digits). Measured in Stata/BE on a random undirected network with 10 ties drawn per node: 10,000 nodes 0.3 seconds and 0.2 GB, 20,000 nodes 0.6 seconds.

A network with no ties at all is rejected (there is no structure to fit a core-periphery pattern to); an isolate is assigned to the periphery.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwcoreperiphery flomarriage, generate(_core)
```
- The best of 50 searches (the degree-based start and 49 random starts):

```stata
. nwcoreperiphery flomarriage, generate(_core) replace restarts(50) seed(1)
```
- The adjacency matrix with the core nodes first and the periphery last ([nwplotmatrix](nwplotmatrix)):

```stata
. nwplotmatrix flomarriage, sortby(_core) group(_core)
```

## Stored results

- **Scalars**
- **r(fitness)** --- correlation between the observed network and the ideal pattern implied by the found partition (-1 to 1; 1 = a perfect discrete core-periphery structure)
- **r(core)** --- number of nodes assigned to the core
- **r(restarts)** --- number of starts of the local search (1 = the degree-based start only)
- **r(beststart)** --- the first start that reached the best fitness (1 = the degree-based start)
- **r(nbest)** --- number of starts that reached the best fitness

## References

Borgatti, S.P., Everett, M.G. (1999). Models of core/periphery structures. *Social Networks* 21(4), 375-395.

## See also

- [nwconcor](nwconcor), [nwcommunity](nwcommunity), [nwconstraint](nwconstraint)

---

*nwcommands version 3.35.0, 22 November 2026* ([check your installed version](nwversion))
