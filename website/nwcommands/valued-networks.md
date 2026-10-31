---
title: "Valued networks"
parent: "nwcommands (core)"
nav_order: 23
description: "How the core commands treat networks whose ties carry values: when a network is valued, which commands use the values, which ignore them, and how to get the binary result."
permalink: /nwcommands/valued-networks/
---

# Valued (weighted) networks
{: .no_toc }

A network is *valued* when its ties carry a number, such as the number of joint arrests, the number of e-mails or the strength of a friendship, and not only present or absent. This page tells you when the program treats a network as valued, which commands then use the numbers, which ignore them, and how to ask for the binary result instead.

1. TOC
{:toc}

## When is a network valued?

The program keeps a flag, *Valued*, with every network. It is set when the network is created, by the way you create it, and it is not worked out again from the numbers later:

| You create the network with | Valued? |
|---|---|
| `nwfromedge` with a value variable (the third variable), `nw2fromedge` with a value variable | yes, also when every value is 1 |
| `nwfromedge` or `nwset ..., edgelist` without a value variable | no |
| `nwimport` of a file that gives tie values (Pajek lines with a third field, GML `value` or `weight`, a matrix or UCINET file with values other than 0 and 1) | yes |
| `nwimport` of a file without tie values | no |
| `nwset` from a matrix or from variables, with no statement of intent | yes if the matrix has a value other than 0 and 1, otherwise no (this is the only place where the numbers decide) |
| `nwset, valued` or `nwset, unvalued`; `nwfromedge ..., valued` or `unvalued` | as you say |
| `nwuse` of a saved network | the flag that was saved with it |
| `nwdichotomize` | no |

Commands that transform a network (`nwkeepnodes`, `nwdropnodes`, `nwsubset`, `nwtranspose`, `nwsym`, `nwcollapse`, `nwpermute`, `nwduplicate`, `nwrecode`, `nwreplace` and others) keep the flag of their source. A binary network that gets a value other than 0 and 1 through such a command becomes valued.

`nwsummarize` shows the flag (`Valued: true` or `false`). If a saved network has the wrong flag, for example shares between 0 and 1 stored as binary by an earlier release, correct it with `nwname netname, newvalued(true)` (or `newvalued(false)`).

## The rule for the commands

* A measure that has a weighted form in R uses the tie values of a valued network **by default**, as R does, and says so in its output. The option `binary` ignores the values and gives the result for presence only. `binary` is the same option in all of them. The older option `weighted` is still accepted where it existed and means the same as the default.
* A measure that has no weighted form in R is binary by definition. On a valued network it prints one line, `(note: tie values are ignored; this measure is binary)`, once per call (not with `silent` or `quietly`). Use `nwdichotomize` to choose a cutoff.
* On a network that is not valued, nothing changes: every result is the one you got before.

## Commands that use the values by default

| Command | What the values do | R equivalent |
|---|---|---|
| `nwdegree` | degree is the **strength** (sum of the tie values); `alpha(a)` gives k (s/k)^a with k the number of ties and s the strength (Opsahl et al. 2010); `binary` or `alpha(0)` the number of ties; `ties()` stores the tie counts next to the strength; the output shows the mean number of ties and the mean strength | `igraph::strength`, `tnet::degree_w` (`igraph::degree` is the tie count) |
| `nwdegree` (`nw2degree`) on a two-mode network | the same for the two modes of a two-mode network (divided by the size of the other mode) | `tnet::degree_tm` |
| `nwgeodesic` | a step along a tie of value w costs 1/w^alpha, alpha = 1 by default, so a stronger tie is shorter; `alpha(-1)` reads the values as lengths; `binary` counts steps | `igraph::distances(weights = 1/w)`; `tnet::distance_w` |
| `nwcloseness` | closeness from those distances | `igraph::closeness(weights = 1/w)` |
| `nwbetween` | shortest paths of least cost 1/w^alpha; tied shortest paths are recognised with a relative tolerance of 1e-10 | `igraph::betweenness(weights = 1/w)`; `tnet::betweenness_w` |
| `nwevcent` | eigenvector centrality of the matrix of tie values | `igraph::eigen_centrality` |
| `nwpagerank` | the surfer follows a tie with probability proportional to its value | `igraph::page_rank` |
| `nwrandomwalk` | hitting times of a walk that steps along a tie with probability proportional to its value | (the walk of `igraph::random_walk`) |
| `nwpath` | the path of least cost 1/w^alpha; `r(path_cost)` is the cost | `igraph::shortest_paths(weights = 1/w)` |
| `nwmatching` | the matching of largest total tie value, which can have fewer pairs than the largest matching; `r(weight)` | `igraph::max_bipartite_match` |
| `nwassortativity` | the node attribute is the strength instead of the degree | `igraph::assortativity(values = strength)` |
| `nwkatz, walks` | weighted walks | `igraph::alpha_centrality` |
| `nwinduced` | inherits the weighting of the centrality it uses (the degree measure counts ties) | |

The weighting convention differs between R packages. `igraph` treats the weights of its path functions as lengths; `tnet` and `nwcommands` treat them as strengths and use the cost 1/w^alpha. With `alpha(-1)` (`nwgeodesic`, `nwpath`, `nwbetween`) you get igraph's convention. Closeness from `tnet` is the `igraph` value multiplied by the mean tie value; the ranking is the same.

A few details. `nwgeodesic` computes weighted distances for networks of up to 100 nodes; for a larger network it counts steps and says so, unless you add `force`. `nwpagerank` and `nwrandomwalk` on a valued network are computed in Mata and take longer than the binary version on very large networks. The directed `nwevcent, nosym` uses outgoing ties, igraph uses incoming ties.

## Commands that have their own measure option

These use the values already, with an option of their own (`measure()`, `stat()`, ...). The default for a valued network is the weighted form; `measure(binary)` or the option named in the table gives the binary form.

`nwclustering` (Opsahl and Panzarasa 2009; `measure(binary)`), `nwconstraint`, `nwconcor`, `nwcoreperiphery`, `nwfactions`, `nwcommunity`, `nwmodularity`, `nwspectral` (`measure(binary)`), `nwdissimilar` and `nwhierarchy` (`euclidean` and `manhatten` use the values), `nwsimilar` (`pearson`, `crossproduct`), `nwcorrelate`, `nwcontext`, `nw2project` (`stat()`), `nw2clustering`, `nwqap`, `nwmaxflow` (`weighted`: the values are capacities, as `capacity` is in igraph).

## Commands that look only at presence

R has no weighted form of these measures. On a valued network they print the one-line note:

`nwbridges`, `nwbrokerage`, `nwclique`, `nwcohesion`, `nwcomponents`, `nwdyads`, `nwego`, `nwkcomponents`, `nwkcore`, `nwkplex`, `nwmixing`, `nwmotifs`, `nwnclan`, `nwnclique`, `nwneighbor`, `nwreach`, `nwshared`, `nwsimindex`, `nwsimmelian`, `nwtabulate`, `nwtriads`, `nwturnover`.

`nwkatz` without `walks` (decay by the number of steps), `nwutility`, `nwlambda` and `nwaltergen` have no weighted counterpart in R either; the first two use steps, `nwlambda` counts edge-disjoint paths (use `nwmaxflow, weighted` for capacities).

## Commands that refuse

| Command | When | Message |
|---|---|---|
| `nwclustering` | a weighted `measure()` on a directed network | "not defined for networks that are both weighted and directed. Either choose measure(binary) or symmetrize the network." |
| `nwcommunity`, `nwmodularity` | directed network without `symmetrize` | "Either specify symmetrize or symmetrize the network first." |
| `nwmatching` | one-mode network | requires a two-mode network |

## Negative values

Only `nwbalance` is built for signed networks. The other commands do not agree on what a negative tie is: some count it as a tie, some treat it as no tie, and some give values that make no sense. Split a signed network into a positive and a negative network with `nwrecode` or `nwdichotomize`, or use `nwbalance`.

## Data handling

* Dichotomize: `nwdichotomize net, threshold(k) generate(new)` gives 1 to every dyad with a value of at least k and 0 to everything else; the result is binary. For `gang_valued`, `threshold(2)` reproduces the 133 ties of the binary `gang` network.
* Recode into a few levels: `nwrecode net (1 2 = 1) (3/4 = 2), generate(new)` (the result keeps the flag of the source).
* Combine the two directions when symmetrizing: `nwsym net, mode(max)` (or `min`, `sum`, `mean`).
* Save and load: values and flag come back unchanged in `nwsave`/`nwuse`, with full precision, and in Pajek and UCINET files; `nwimport, type(gml)` reads `value` or `weight` and the direction.

## Running a command on a cutoff version

```stata
. nwwebuse gang, nwclear
. nwdichotomize gang_valued, threshold(2) generate(gang_strong)
. nwsummarize gang_strong
. nwbetween gang_strong, generate(btw_strong)
```

Report the cutoff and, ideally, show that the main result does not depend on it (try 1, 2 and 3).

## References

Newman, M. E. J. (2004). Analysis of weighted networks. *Physical Review E* 70, 056131.
Opsahl, T., Agneessens, F., and Skvoretz, J. (2010). Node centrality in weighted networks: Generalizing degree and shortest paths. *Social Networks* 32, 245-251.
Opsahl, T., and Panzarasa, P. (2009). Clustering in weighted networks. *Social Networks* 31, 155-163.
Leung, C. C., and Chau, H. F. (2007). Weighted assortative and disassortative networks model. *Physica A* 378, 591-602.
