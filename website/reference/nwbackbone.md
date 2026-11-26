---
title: "nwbackbone"
parent: "Core command reference"
grand_parent: "Packages and reference"
nav_exclude: true
search_exclude: false
description: "Backbone extraction for valued networks and two-mode projections"
---

# `nwbackbone`

Backbone extraction for valued networks and two-mode projections

## Syntax

```stata
nwbackbone [netname] , m:ethod(method) [options]
```

| | |
|---|---|
| `al:pha(#)` | significance level; default `0.05` |
| `mtc(adjustment)` | multiple-testing correction: `none` (default), `bonferroni`, `holm`, `hochberg`, `hommel`, `BH` (= `fdr`), `BY` |
| `thr:eshold(# [#])` | for `method(global)`: keep ties with a value above # |
| `sign:ed` | keep significantly weak ties as well, with the value -1 |
| `keep:values` | give the kept ties their tie values (the counts of the projection) instead of 1 |
| `miss:ingaszero` | also test the dyads without a tie |
| `p:roject(1\|2)` | two-mode network: the mode whose projection is filtered; default `1` |
| `tri:als(#)` | `method(fdsm)`: number of random networks |
| `seed(#)` | random-number seed (`method(fdsm)`) |
| `gen:erate(newname)` | name of the backbone network; default `backbone` |
| `replace` | overwrite an existing network of that name |
| `silent` | do not show the summary |

## Description

`nwbackbone` reduces a dense, valued network to its backbone: the ties that are significantly strong (or, with `signed`, significantly weak) against a stated null model. The result is a new network that is binary (1 for a kept tie) or, with `keepvalues`, keeps the values of the kept ties. The methods and their names follow the R package *backbone* (Neal; version 3.0.4), against which `nwbackbone` was checked.

Two kinds of input are handled.

- **A valued one-mode network** (tie values other than 0 and 1; directed or undirected). The methods
- `disparity`, `lans` and `mlf` test every tie against a null model of the ties of the same nodes;
- `global` keeps ties above a value.
- **A binary two-mode network**, say persons by events. The weighted projection onto one mode counts the
- shared affiliations of every pair of nodes; the methods `sdsm`, `fdsm`, `fixedrow`,
- `fixedcol` and `fixedfill` test each count against a null model of random two-mode networks.
- The backbone is a one-mode network of the nodes of the mode chosen with `project()`.

## Methods

- **`global`** --- Keeps every tie whose value is greater than `threshold()`. With two numbers, ties above the larger one are kept as +1 and ties below the smaller one as -1. No test is made, so `alpha()`, `mtc()` and `signed` do not apply.
- **`disparity`** --- Disparity filter (Serrano, Boguna and Vespignani 2009). The null model spreads the strength of a node uniformly at random over its ties; a tie is tested from the point of view of both end nodes (for a directed network, the sender and the receiver) and the smaller p-value counts.
- **`lans`** --- Locally adaptive network sparsification (Foti, Hughes and Rockmore 2011): a tie is kept if it ranks high among the ties of its node (nonparametric; ranks of the shares of the node's strength).
- **`mlf`** --- Marginal likelihood filter (Dianati 2016): tie values are counts whose total is distributed over the dyads in proportion to the strengths of the nodes; each tie is tested with a binomial distribution. Needs integer tie values.
- **`sdsm`** --- Stochastic degree sequence model (Neal 2014; compared with the other models by Neal, Domagalski and Sagan 2021): the probability of a tie of the two-mode network is modelled from the degrees of both nodes (the bipartite configuration model, maximum likelihood); the number of shared affiliations of two nodes is then a Poisson-binomial variable. Its tail is computed with the refined normal approximation of the R package, not exactly.
- **`fdsm`** --- Fixed degree sequence model (Zweig and Kaufmann 2011; Neal, Domagalski and Sagan 2021): the p-value is the share of random two-mode networks with the same degrees (Monte Carlo with curveball trades, Strona et al. 2014; the number of networks is `trials()`) in which the pair shares at least as many affiliations. Slow for large networks.
- **`fixedrow`** --- Fixed row model (Neal, Domagalski and Sagan 2021): the row degrees are fixed; the shared affiliations follow a hypergeometric distribution.
- **`fixedcol`** --- Fixed column model: the column degrees are fixed; refined normal approximation.
- **`fixedfill`** --- Fixed fill model: only the total number of ties is fixed; exact distribution.

## Options

`alpha(#)`: a tie is kept if its p-value is smaller than *#* (after the correction of `mtc()`). With `signed` a tie is kept as strong, or as weak (-1), if the p-value of that tail is smaller than *#*/2.

`mtc(adjustment)` corrects the p-values for the number of tests made, with the formulas of R's `p.adjust`. For an undirected network (and always for a projection) each pair is counted once. Without the option every tie is tested at `alpha()`, which over-states the evidence when thousands of ties are tested.

`threshold(# [#])` is required for `method(global)`.

`signed` also records the ties that are significantly weaker than the null model expects: the backbone then has the values +1 and -1. For `method(global)` give two thresholds instead.

`keepvalues` gives each kept tie its original value (for a projection: the number of shared affiliations); the `signed` sign is then lost. Without the option kept ties have the value 1 (-1).

`missingaszero` also tests dyads that have no tie (value 0 or, for a projection, no shared affiliation). Dyads without a tie are otherwise never in the backbone. The number of tests for `mtc()` grows accordingly. With `signed` this is how significantly weak, absent ties are found.

`project(1|2)` (two-mode networks) chooses the mode whose nodes become the nodes of the backbone; mode 1 is the first level shown by [nwsummarize](nwsummarize). The result is a one-mode network with the node names of that mode.

`trials(#)` sets the number of random networks of `fdsm`. By default it is chosen as in the R package from `alpha()` so that the test can tell a p-value just below `alpha()` from one just above it, which needs about 80,000 networks at `alpha(0.05)`; with a multiple-testing correction the default is much larger. For exploratory work set `trials()` to a few thousand (the p-values then have a standard error of up to `0.5/sqrt(`trials`)`). `set seed` or `seed()` makes the result reproducible.

`generate(newname)` and `replace`: name of the network created; an existing network is only overwritten with `replace`.

## Remarks

**What a backbone is.** The ties of a valued network are not all equally informative: a weight can be large only because both nodes are active. Each method asks, for every tie, whether its weight is larger than a particular random model of the same network would produce, and keeps the ties for which the answer is yes. The methods differ in the null model (and so in what counts as a surprise), not in the final step. A tie that is kept is a statement about that null model, not a statement that other ties do not matter.

**Checked against R.** For one-mode networks and for `sdsm`, `fixedrow`, `fixedcol` and `fixedfill` the p-values equal those of the R package *backbone* 3.0.4 (to better than 1e-8 absolute, 1e-6 relative) and the kept ties are identical, with and without the corrections and with `signed`, on the networks of the test suite. A p-value that is exactly equal to `alpha()` in exact arithmetic can fall on either side of it through rounding, in R as well as here. `fdsm` cannot reproduce R's random numbers; its p-values agree with a 40,000-draw reference within the Monte Carlo error. Not implemented: the SDSM variant with edge constraints, the extraction from unweighted networks (sparsification: `backbone_from_unweighted` in R), and bipartite networks with tie values.

**Limits.** The p-values are computed for all pairs of nodes at once and held in memory as *n* x *n* matrices. Beyond a few thousand nodes of the projected mode memory runs out first. `fdsm` needs one projection per random network and becomes slow beyond a few hundred nodes at the default number of networks.

**Direction.** A directed network is filtered as directed; an undirected network as undirected (a pair is tested once). The disparity filter of a directed network uses the out-strength of the sender and the in-strength of the receiver and keeps the smaller p-value, as in R.

**Input.** `disparity`, `lans` and `mlf` need a valued network with non-negative values; a network with only the values 0 and 1 is refused, as in R. For a binary one-mode network see [nwdichotomize](nwdichotomize) for the opposite direction (valued to binary at a fixed cutoff).

## Examples

- Disparity filter of a valued network, with a Holm correction
- `. nwset, mat((0,9,1,1\9,0,1,2\1,1,0,8\1,2,8,0)) name(w) undirected`
- `. nwbackbone w, method(disparity) alpha(0.2) mtc(holm) generate(wb)`

- Keep the ties of a valued network with a value above 3, with their values
- `. nwbackbone w, method(global) threshold(3) keepvalues generate(wg)`

- Load a two-mode network (women by social events)
- `. nwwebuse davis, nwclear`

- Backbone of the projection of a two-mode network (persons by events) onto the persons
- `. nwbackbone davis, method(sdsm) alpha(0.05) mtc(BH) project(1) generate(persons)`

- Fixed degree sequence model with 2,000 random networks
- `. nwbackbone davis, method(fdsm) trials(2000) seed(1) generate(persons_fdsm)`

## Stored results

`nwbackbone` stores the following in `r()`:

- **Scalars**
- **`r(nodes)`** --- number of nodes of the backbone network
- **`r(ties_in)`** --- number of ties tested (pairs for an undirected network)
- **`r(ties)`** --- number of ties in the backbone
- **`r(removed)`** --- percentage of the ties removed
- **`r(alpha)`** --- the level
- **`r(trials)`** --- number of random networks (`fdsm`)
- **Macros**
- **`r(network)`** --- name of the input network
- **`r(backbone)`** --- name of the backbone network
- **`r(method)`, `r(mtc)`** --- options as used

## References

Dianati, N. 2016. Unwinding the hairball graph: pruning algorithms for weighted complex networks. *Physical Review E* 93: 012304.

Foti, N. J., J. M. Hughes and D. N. Rockmore. 2011. Nonparametric sparsification of complex multiscale networks. *PLOS ONE* 6: e16431.

Neal, Z. P. 2014. The backbone of bipartite projections: inferring relationships from co-authorship, co-sponsorship, co-attendance and other co-behaviors. *Social Networks* 39: 84-97.

Neal, Z. P., R. Domagalski and B. Sagan. 2021. Comparing alternatives to the fixed degree sequence model for extracting the backbone of bipartite projections. *Scientific Reports* 11: 23929.

Neal, Z. P. 2026. backbone: an R package to extract network backbones. *PLOS ONE* 21: e0349258.

Serrano, M. A., M. Boguna and A. Vespignani. 2009. Extracting the multiscale backbone of complex weighted networks. *Proceedings of the National Academy of Sciences* 106: 6483-6488.

Strona, G., D. Nappo, F. Boccacci, S. Fattorini and J. San-Miguel-Ayanz. 2014. A fast and unbiased procedure to randomize ecological binary matrices with fixed row and column totals. *Nature Communications* 5: 4114.

Zweig, K. A. and M. Kaufmann. 2011. A systematic approach to the one-mode projection of bipartite graphs. *Social Network Analysis and Mining* 1: 187-218.

## Also see

- psee
- [nwdichotomize](nwdichotomize), [nwproject](nwproject), [nwrecode](nwrecode), [nwkeep](nwkeep)

---

*nwcommands version 3.39.0, 26 November 2026* ([check your installed version](nwversion))
