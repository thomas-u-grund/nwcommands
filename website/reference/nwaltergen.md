---
title: "nwaltergen"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Generate a variable from alter/neighbor attributes"
---

# `nwaltergen`

Generate a variable from alter/neighbor attributes

## Syntax

```stata
nwaltergen newvar = stat(alter.srcvar)
[,
net(netname)
replace
hop(int)]
nwaltergen newvar = proportion(alter.srcvaropvalue)
[,
net(netname)
replace
hop(int)]
stat is one of mean, wmean, sum, min, max, sd, count,
diversity.
op is == or !=; value must be numeric.
```

| | |
|---|---|
| `net(netname)` | Network to use; default = the current network |
| `replace` | Replace existing variable |
| `hop(int)` | Aggregate over nodes exactly this many (unweighted) steps away, instead of direct neighbors; default = 1 |

## Description

`nwaltergen` generates a new Stata variable that summarizes, for each node (*ego*), a Stata variable's values among its network neighbors (*alters*) - e.g. "the average smoking status among a person's contacts" (`mean(alter.smoking)`) or "the number of contacts who already adopted" (`count(alter.adopted)`). This is the standard "network exposure" / alter-aggregation primitive used throughout social influence, diffusion, and peer-effects research (see e.g. Valente 2005 on exposure models).

*srcvar* must already exist in the dataset and be indexed the same way as every other per-node result in `nwcommands`: observation *i* holds the value for node *i*.

For directed networks, *alter* means *out*-neighbors only - the nodes ego has a tie *to* - since exposure/influence is inherently about tie direction, not just structural adjacency (contrast this with, e.g., [nwkcore](nwkcore), where an undirected structural question uses the union of in- and out-neighbors instead). For undirected networks the distinction does not arise.

Missing values of *srcvar* among a node's alters are dropped before the statistic is computed (so a node with 3 alters, one of whom has a missing *srcvar*, is summarized over the 2 non-missing values) - never silently propagated into the result. A node with zero alters (after dropping missing values, if applicable) returns missing for **mean**/**min**/**max**/**sd**/ **diversity**, and 0 for **sum**/**count**. **sd** additionally requires at least 2 non-missing alter values (it is undefined for a single value) and returns missing otherwise.

**proportion(alter.***srcvar***==***value***)** (or **!=**) gives the proportion of ego's alters whose *srcvar* equals (or does not equal) a specific numeric category - e.g. "the proportion of a person's contacts who work in sector 3" (`proportion(alter.sector==3)`). For an already-binary (0/1) *srcvar*, `mean(alter.`*srcvar*`)` already gives exactly "the proportion with *srcvar*==1", so a bare `proportion(alter.`*srcvar*`)` with no comparison is not offered as a separate synonym for it - **proportion()**'s own value is for picking out one category of a variable with more than two categories, without first having to `generate` a 0/1 indicator by hand. Missing *srcvar* values are still dropped before the proportion is computed, exactly as for every other *stat* - a missing value is never silently read as "not in this category".

**diversity(alter.***srcvar***)** gives Blau's (1977) index of heterogeneity among ego's alters' *srcvar* values - **1 - sum(p_k^2)**, where *p_k* is the proportion of alters falling in category *k* of *srcvar* (treated as a categorical/discrete-coded variable, e.g. sector or ethnicity) - the standard "ego-network composition" measure: 0 when every alter shares the same category (no diversity), approaching 1 as alters spread evenly across many categories. This is the composition/diversity capability [nwego](nwego)'s own "Supported network types" note originally left open - unlike ego-network size/density, it needs per-alter attribute *values*, not just structural connectivity, so it belongs here alongside [nwaltergen](nwaltergen)'s other alter- attribute aggregations rather than in [nwego](nwego) itself. Missing *srcvar* values are dropped before computing the index, exactly as for every other *stat*; an ego with zero alters (after dropping missing values) returns missing, not spuriously 0 (mirroring **mean**/**min**/**max**/ **sd**'s own convention, not **sum**/**count**'s - diversity, like a mean, is undefined with no data to summarize, not naturally zero).

**wmean(alter.***srcvar***)** is a tie-strength-*weighted* exposure mean - **sum(w*x) / sum(w)** over ego's alters, where *w* is the tie weight to each alter and *x* is that alter's *srcvar* value - instead of **mean()**'s own plain, equally-weighted average. This is the standard weighted-exposure/peer-effect formulation used when tie strength itself should matter - e.g. a strong tie's contact matters more to exposure than a weak one (see e.g. Marsden and Friedkin 1993 on weighted social influence). On a binary (unweighted) network every present tie has weight 1, so **wmean()** gives exactly the same result as **mean()** - not an approximation, since a tie's weight is exactly 1 whenever the network itself carries no distinct tie values. An alter with a missing *srcvar* is dropped from both the numerator *and* the weight-sum denominator together (so it does not silently bias the result toward zero), matching every other *stat*'s own missing-value convention. **wmean()** is only supported at the default `hop(int):hop(1)` (direct alters) - which single tie weight should represent a multi-hop path has no single well-defined answer, so combining it with `hop(int)` > 1 is rejected with a clear error rather than guessed at.

`hop(int)` aggregates over nodes exactly that many (unweighted) steps away instead of direct (one-hop) neighbors - e.g. `mean(alter.smoking), hop(2)` is "the average smoking status among the contacts of a person's contacts" (excluding the person's own direct contacts, unless a network happens to reach them again by a different, exactly-2-step path). This is the standard multi-hop / lagged exposure question in diffusion research: does influence propagate beyond a node's immediate neighborhood? A node with no alters at exactly the requested hop distance (including one smaller than the network's diameter from it, or simply unreachable) is treated the same as a node with no direct alters: missing for **mean**/**min**/**max**/**sd**, 0 for **sum**/**count**. For a directed network, distance follows tie direction (out-going steps), matching *alter*'s own one-hop convention above; `hop(int)` works with **proportion()** too.

`nwgen` recognizes the same `mean(alter.`*x*`)`-style syntax (including `proportion(alter.`*x*`==`*value*`)` and `hop(int)`) as a shortcut and dispatches to `nwaltergen` automatically - `nwgen exposure = mean(alter.smoking)` and `nwaltergen exposure = mean(alter.smoking)` are equivalent.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwaltergen richavg = mean(alter.wealth)
. nwgen richavg2 = mean(alter.wealth), replace
. nwaltergen richwexp = wmean(alter.wealth)
. nwaltergen priorseat = proportion(alter.seat==1)
. nwaltergen richavg2hop = mean(alter.wealth), hop(2)
. nwaltergen seatdiv = diversity(alter.seat)
```

## Supported network types

Binary: yes. Directed: yes - *alter* means out-neighbors only, since exposure/influence follows tie direction (see above). Weighted: **W2** - **mean**/**sum**/**min**/**max**/**sd**/ **count**/**diversity** use only structural adjacency (tie strength does not enter); **wmean** (added 2026-09-02, closing a self-flagged gap) uses tie strength directly as the aggregation weight, an explicit opt-in via a separate *stat* name rather than an automatic switch. Signed: not checked - **wmean()** would divide by a possibly near-zero or sign-cancelling weight sum for a node with negative-weighted ties, not handled distinctly. Two-mode: no - *srcvar* is read per node under the one-mode *_nwnode* indexing convention, with no mode-specific handling.

## References

Valente, T.W. (2005). Network models and methods for studying the diffusion of innovations. In *Models and Methods in Social Network Analysis*, Cambridge University Press.

Marsden, P.V., Friedkin, N.E. (1993). Network studies of social influence. *Sociological Methods & Research* 22(1), 127-151. (**wmean()**'s own tie-strength-weighted exposure formulation)

Blau, P.M. (1977). *Inequality and Heterogeneity: A Primitive Theory of Social Structure*. Free Press. (**diversity()**'s own index of heterogeneity)

## See also

- [nwgen](nwgen), [nwneighbor](nwneighbor), [nwdegree](nwdegree)

- last certified : 02 Sep 2026
