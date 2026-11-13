---
title: "nwcug"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Conditional Uniform Graph (CUG) test"
---

# `nwcug`

Conditional Uniform Graph (CUG) test

## Syntax

```stata
nwcug
[netname]
,
stat(command)
rname(string)
[reps(int)
seed(int)
tail(both|upper|lower)
condition(density|census|mode1degree|mode2degree|degrees)
trades(#)
silent
plot
name(string)]
```

| | |
|---|---|
| `stat(command)` | Command template used to compute the test statistic; the token **##net##** marks where the network name belongs (without it, the name follows the command name) |
| `rname(string)` | Name of the *stat*'s **r()** scalar to use as the test statistic |
| `reps(int)` | Number of conditioned random networks to draw; default = 1000 |
| `seed(int)` | Set the random-number seed before drawing (for reproducibility) |
| `tail(both\|upper\|lower)` | Which tail(s) to report a p-value for; default = *both* |
| `condition(density\|census\|mode1degree\|mode2degree\|degrees)` | Null model to condition random draws on; default = *density*; *census* for directed one-mode networks, *degrees* for one-mode and two-mode networks, *mode1degree* and *mode2degree* for two-mode networks |
| `trades(#)` | **condition(degrees)**: the number of attempted tie swaps (one-mode; default = 10 times the number of ties) or curveball trades (two-mode; default = 5 times the number of nodes of the smaller mode, the first draw follows 6 times that many) between two draws |
| `silent` | Suppress display of results |
| `plot` | Draw a histogram of the **reps()** null draws, with a dashed reference line at the observed statistic (the same comparison R's **sna::plot.cug.test()** draws) |
| `name(string)` | Name for the graph created by `plot`; default = **cug** |

## Description

`nwcug` performs a Conditional Uniform Graph (CUG) test (Anderson, Butts and Carley 1999): it compares an observed network statistic against the distribution of that same statistic computed on **reps** random networks drawn uniformly from the set of all networks with the same number of nodes and the same density as [netname](netname) (using [nwrandom](nwrandom)'s **density()** conditioning). This answers "is my observed statistic unusual, given only the size and density of the network?" - a standard baseline null model in network analysis, since many statistics (e.g. transitivity, number of components) are mechanically related to density alone, and a CUG test controls for that before attributing a finding to genuine structure.

**stat()** is a full command template (any `nw*` command plus whatever options it needs) that returns a scalar in **r()**; use the literal token **##net##** wherever the network name belongs - `nwcug` substitutes it with the observed network's name once, and with a freshly-drawn random network's name **reps()** times. **rname()** names the returned scalar (without the surrounding `r(...)`). Passing whatever **replace**-style option the command needs (as part of the template) is the caller's responsibility, since the same command runs once per random draw. When **stat()** has no **##net##**, the network name is put right after the command name, so `stat(nwclustering)` is `stat(nwclustering ##net##)` and `stat(nwdyads)` is `stat(nwdyads ##net##)`; the token is needed only for a command or a program of your own that takes the network elsewhere. For example, to test whether the Florentine marriage network's component count is unusual for its size and density:

```stata
. nwwebuse florentine, nwclear
. nwcug flomarriage, stat(nwcomponents ##net##, generate(cc) replace silent) rname(components) reps(1000) seed(12345)
```
`condition(density|census)` chooses what property of [netname](netname) the random draws must share, via [nwrandom](nwrandom)'s own **density()** (the default) or **census()** conditioning. **condition(density)** draws uniformly from every network with the same node count and density - the standard baseline used above. **condition(census)** instead draws uniformly from every network with the *same dyad census* (identical mutual/asymmetric/null tie counts, via [nwdyads](nwdyads)) as [netname](netname) - a stricter, reciprocity-aware null model: two directed networks can share the same overall density while differing sharply in how many ties are reciprocated, so a statistic that is unremarkable once density alone is held fixed can still be unusual once reciprocity is held fixed too (or vice versa). **condition(census)** requires a directed network - mutual/asymmetric/null dyad types have no meaning for undirected ties, where every dyad is simply tied or not.

**condition(degrees)** keeps the degree of every node (in a directed network its out-degree and its in-degree): the draws are random networks with exactly the degrees of [netname](netname), no self-loops and no pair tied twice. It asks whether a statistic goes beyond what the degrees alone produce: popular nodes are tied to each other more often by chance, so clustering or a core can look remarkable against **condition(density)** and ordinary against **condition(degrees)**. The draws form a chain of random tie swaps on a copy of [netname](netname) (two ties a-b and c-d become a-d and c-b, see [nwpermute](nwpermute) with `swap`), as R's `igraph::rewire(g, keeping_degseq())`; `trades()` sets the number of attempted swaps between two draws. The copy keeps the node names and attributes of [netname](netname), and tie values move with their ties. The draws use the native plugin. For example, the global clustering coefficient of the Florentine marriage network is 0.191; random networks with its density have 0.147 on average and networks with its degrees 0.165 (sd 0.078), which agrees with `igraph` (0.162, sd 0.077):

```stata
. nwcug flomarriage, stat(nwclustering) rname(cluster_global) condition(degrees) reps(2000) seed(3)
```
Some statistics are fixed by the dyad census (reciprocity, for example). With **condition(census)** their null distribution has standard deviation 0 and the test carries no information; the command prints a one-line note in that case.

**tail()** controls which p-value(s) are reported: **upper** is the proportion of random draws with a statistic at least as large as observed (evidence the observed value is unusually *high*); **lower** is the proportion at least as small (unusually *low*); **both** (the default) reports both, plus a two-sided p-value (**r(p)**, twice the smaller one-sided p-value, capped at 1).

`plot` draws a histogram of the **reps()** null draws with a dashed vertical line at the observed statistic - the standard visual check for a CUG test (is the observed value out in the tail of the null distribution, or comfortably inside it?), the same comparison R's **sna** package's **plot.cug.test()** draws for its own **cug.test()**. Grayscale by design, matching every other plot this package produces.

For a two-mode network the null networks are two-mode networks with the same nodes (and the same node names and attributes) as [netname](netname); the draws are made by a kernel of the native plugin, so the time of a test is that of the statistic. The conditions are

- **condition(density)** (the default): the same number of ties between a random mode-1 node and a random mode-2 node, no pair twice (`igraph::sample_bipartite(type = "gnm")`,
- `vegan::nullmodel(method = "r00")`).
- **condition(mode1degree)**: every mode-1 node keeps its degree and takes its partners at random among all mode-2 nodes (`vegan` method `r0`).
- **condition(mode2degree)**: the same for the mode-2 nodes (`vegan` method `c0`).
- **condition(degrees)**: both degree sequences stay, the curveball algorithm of Strona et al. (2014) (`vegan` method `curveball`; the same null model as [nwpermute](nwpermute) with
- `swap`, which exchanges the partners of two ties). The draws form a chain; `trades()` sets the number of trades between two draws.

The values of a valued two-mode network are shuffled over the ties of every draw (the number of ties and the degrees count ties, not values). **condition(census)** counts the dyads of a directed one-mode network and is refused for a two-mode network (error 198); **condition(mode1degree)** and **condition(mode2degree)** are refused for a one-mode network. For example, to test whether the nestedness of the Southern women is unusual for their degrees:

```stata
. nwwebuse davis, nwclear
. nwcug davis, stat(nw2nested ##net##) rname(nodf) condition(degrees) reps(1000) seed(1)
```
The means and standard deviations of the null distributions agree with those of `vegan::nullmodel` in R (1,000 draws of the nestedness NODF of the Southern women: 36.98 against 36.78 for *density*, 38.81 against 38.81 for *mode1degree*, 44.53 against 44.53 for *mode2degree*, 48.36 against 48.43 for *degrees*).

## Network types

**Directed:** `condition(census)` needs a directed one-mode network; `condition(degrees)` keeps out-degrees and in-degrees. **Valued:** the use of tie values depends on the command in `stat()`; the values of a valued two-mode network are shuffled over the ties of every draw. **Two-mode:** yes - the null networks are two-mode networks with the same nodes (conditions above). **Signed:** depends on the command in `stat()`. See [nwnetworktypes](nwnetworktypes).

## Limits

Every draw of the null distribution is a new random network ([nwrandom](nwrandom)) and the statistic is computed on it. With `condition(density)` above 5,000 nodes a draw is made in a fraction of a second (the positions of the ties are drawn directly), so the time is that of the statistic: 5 draws with `nwcomponents` as the statistic take 2 seconds at 20,000 nodes. `condition(census)` works on the matrix.

## Stored results

- **Scalars**
- **r(obs)** --- observed statistic
- **r(reps)** --- number of random draws
- **r(mean_null)** --- mean of the statistic across random draws
- **r(sd_null)** --- standard deviation of the statistic across random draws
- **r(p_greater)** --- (1 + number of random draws >= observed)/(draws + 1) (upper-tail p-value, never 0)
- **r(p_less)** --- (1 + number of random draws <= observed)/(draws + 1) (lower-tail p-value, never 0)
- **r(p)** --- two-sided p-value (2 * min(p_greater, p_less), capped at 1)

## References

Strona, G., Nappo, D., Boccacci, F., Fattorini, S., San-Miguel-Ayanz, J. (2014). A fast and unbiased procedure to randomize ecological binary matrices with fixed row and column totals. *Nature Communications* 5, 4114.

Anderson, B.S., Butts, C., Carley, K. (1999). The interaction of size and density with graph-level indices. *Social Networks* 21(3), 239-267.

## See also

- [nwrandom](nwrandom), [nwdyads](nwdyads), [nwpermute](nwpermute), [nwqap](nwqap)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
