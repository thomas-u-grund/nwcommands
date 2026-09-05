---
title: "nwmatching"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Maximum-cardinality bipartite matching"
---

# `nwmatching`

Maximum-cardinality bipartite matching

## Syntax

```stata
nwmatching
[netname]
[,
generate(newvarname)
replace
silent]
```

| | |
|---|---|
| `generate(newvarname)` | Name of the Stata variable that stores each mode-1 node's own matched mode-2 partner's node id (0 if unmatched); default = *_match* |
| `replace` | Replace existing variable |
| `silent` | Suppress display of results |

## Description

`nwmatching` finds a maximum-CARDINALITY matching on a two-mode network - the largest possible set of ties such that no node (on either side) appears in more than one selected tie. Computed via the standard reduction to maximum flow: a virtual source with a capacity-1 arc to every mode-1 node, a virtual sink with a capacity-1 arc from every mode-2 node, capacity 1 on every existing tie, then one max-flow call from source to sink (the same [nwmaxflow](nwmaxflow.md) machinery this command builds on internally) - the classical integrality theorem for unit-capacity flow networks guarantees this finds an OPTIMAL (maximum-cardinality) matching directly, not merely a good one.

Requires a genuine two-mode network (`twomode`/`bipartite` in [nwset](nwset.md), or [nw2set](nw2set.md), [nw2fromedge](nw2fromedge.md)) - the mode assignment already tells this command which side of the bipartition each node is on, so no separate bipartiteness detection is needed (and a general, non-bipartite graph's own maximum matching - Edmonds' 1965 blossom algorithm - is a materially harder problem, not attempted here).

`generate(newvarname)` is populated only on the MODE-1 side: a mode-1 node's own value is its matched mode-2 partner's node id (0 if left unmatched by the optimal solution - this can happen whenever the two sides have unequal size, or the bipartite graph's own structure has no perfect matching); every mode-2 node's own value is always 0 - read the match off the mode-1 side only, matching [nw2project](nw2project.md)'s own established "one side owns the report" convention for a two-mode result.

## Examples

```stata
. nwset person org, twomode name(assign)
. nwmatching assign
. list person _match if _match > 0
```

## Supported network types

Binary: yes (only) - matching is a presence/absence structure; tie values are ignored. Directed: not applicable (a two-mode affiliation tie has no meaningful direction). Weighted: not applicable - see [nwmaxflow](nwmaxflow.md) directly if a WEIGHTED assignment problem (maximum total value, not maximum count) is actually what is needed; that is a different, harder problem (not this command). Signed: not checked. Two-mode: required.

## Stored results

**Scalars**

- **r(matched)** number of matched pairs found

**Macros**

- **r(matchvar)** name of the generated match variable

## References

Hopcroft, J.E., Karp, R.M. (1973). An n^2.5 algorithm for maximum matchings in bipartite graphs. *SIAM Journal on Computing* 2(4), 225-231.

## See also

- [nwmaxflow](nwmaxflow.md), [nw2project](nw2project.md), [nw2set](nw2set.md), [nw2fromedge](nw2fromedge.md)

- last certified : 31 Aug 2026
