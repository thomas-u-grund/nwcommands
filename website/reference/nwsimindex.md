---
title: "nwsimindex"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Common-neighbor similarity indices between all node pairs"
---

# `nwsimindex`

Common-neighbor similarity indices between all node pairs

## Syntax

```stata
nwsimindex
[netname]
[,
measure(string)
name(newnetname)
xvars
replace]
```

| | |
|---|---|
| `measure(common\|jaccard\|dice\|cosine\|adamicadar)` | Which similarity index to compute; default = *jaccard* |
| `name(newnetname)` | Name of the new similarity network; default = *simindex* |
| `xvars` | Generate Stata variables for the new network |
| `replace` | Replace an existing network of the same name |

## Description

`nwsimindex` computes a common-neighbor similarity index (Liben-Nowell and Kleinberg 2007) for every pair of nodes and stores the result as a new, valued, undirected network [newnetname](newnetname) (default: *simindex*). These indices measure how much two nodes' neighborhoods overlap - a standard building block for link prediction, structural-equivalence/role analysis, and as an input to blockmodeling or one-mode projection (see [nw2project](nw2project)).

All calculations use the undirected neighbor sense: for directed networks, a node's neighbor set is the union of its out- and in-neighbors (the same convention [nwkcore](nwkcore) uses), since neighborhood overlap is a direction-agnostic question. *measure* is one of:

- **common**
- the raw count of shared neighbors, *|N(i) intersect N(j)|*
- **jaccard** (default)
- *|N(i) intersect N(j)| / |N(i) union N(j)|*
- **dice**
- the Sorensen-Dice coefficient, *2|N(i) intersect N(j)| / (|N(i)| + |N(j)|)*
- **cosine**
- the Salton cosine similarity, *|N(i) intersect N(j)| / sqrt(|N(i)| * |N(j)|)*
- **adamicadar**
- Adamic-Adar, *sum over shared neighbors k of 1/log(degree(k))* - weights rare
- (low-degree) shared neighbors more heavily than common ones

The similarity of a node with itself is not defined and is set to missing, as are any pairs where the underlying formula is undefined - most notably **cosine** between two isolate nodes (0/0). This mirrors how [nwgeodesic](nwgeodesic) reports an undefined diameter/radius rather than silently coercing an undefined value to 0.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwsimindex flomarriage, measure(jaccard)
. nwsummarize simindex, matonly
```

## Supported network types

Binary: yes (only) - similarity is computed from binary neighbor-set overlap; tie values are ignored. Directed: yes - each node's neighbor set is the union of its out- and in-neighbors (the same convention [nwkcore](nwkcore) uses). Weighted: not applicable. Signed: not applicable. Two-mode: not checked.

## Stored results

**Scalars**

- **r(nodes)** number of nodes

**Macros**

- **r(measure)** the measure used
- **r(netname)** name of the new similarity network

## References

Liben-Nowell, D., Kleinberg, J. (2007). The link-prediction problem for social networks. *Journal of the American Society for Information Science and Technology* 58(7), 1019-1031.

Adamic, L.A., Adar, E. (2003). Friends and neighbors on the Web. *Social Networks* 25(3), 211-230.

## See also

- [nwsimilar](nwsimilar), [nw2project](nw2project), [nwkcore](nwkcore), [nwburt](nwburt)

- last certified : 24 Aug 2026
