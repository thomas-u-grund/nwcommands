---
title: "nwcug"
parent: "Command reference"
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
condition(density|census)
silent
plot
name(string)]
```

| | |
|---|---|
| `stat(command)` | Command template used to compute the test statistic; must contain the literal token **##net##** where the network name belongs |
| `rname(string)` | Name of the *stat*'s **r()** scalar to use as the test statistic |
| `reps(int)` | Number of conditioned random networks to draw; default = 1000 |
| `seed(int)` | Set the random-number seed before drawing (for reproducibility) |
| `tail(both\|upper\|lower)` | Which tail(s) to report a p-value for; default = *both* |
| `condition(density\|census)` | Null model to condition random draws on; default = *density* |
| `silent` | Suppress display of results |
| `plot` | Draw a histogram of the **reps()** null draws, with a dashed reference line at the observed statistic (the same comparison R's **sna::plot.cug.test()** draws) |
| `name(string)` | Name for the graph created by `plot`; default = **cug** |

## Description

`nwcug` performs a Conditional Uniform Graph (CUG) test (Anderson, Butts and Carley 1999): it compares an observed network statistic against the distribution of that same statistic computed on **reps** random networks drawn uniformly from the set of all networks with the same number of nodes and the same density as [netname](netname.md) (using [nwrandom](nwrandom.md)'s **density()** conditioning). This answers "is my observed statistic unusual, given only the size and density of the network?" - a standard baseline null model in network analysis, since many statistics (e.g. transitivity, number of components) are mechanically related to density alone, and a CUG test controls for that before attributing a finding to genuine structure.

**stat()** is a full command template (any `nw*` command plus whatever options it needs) that returns a scalar in **r()**; use the literal token **##net##** wherever the network name belongs - `nwcug` substitutes it with the observed network's name once, and with a freshly-drawn random network's name **reps()** times. **rname()** names the returned scalar (without the surrounding `r(...)`). Passing whatever **replace**-style option the command needs (as part of the template) is the caller's responsibility, since the same command runs once per random draw. For example, to test whether the Florentine marriage network's component count is unusual for its size and density:

```stata
. nwwebuse florentine, nwclear
. nwcug flomarriage, stat(nwcomponents ##net##, replace) rname(components) reps(1000) seed(12345)
```
`condition(density|census)` chooses what property of [netname](netname.md) the random draws must share, via [nwrandom](nwrandom.md)'s own **density()** (the default) or **census()** conditioning. **condition(density)** draws uniformly from every network with the same node count and density - the standard baseline used above. **condition(census)** instead draws uniformly from every network with the *same dyad census* (identical mutual/asymmetric/null tie counts, via [nwdyads](nwdyads.md)) as [netname](netname.md) - a stricter, reciprocity-aware null model: two directed networks can share the same overall density while differing sharply in how many ties are reciprocated, so a statistic that is unremarkable once density alone is held fixed can still be unusual once reciprocity is held fixed too (or vice versa). **condition(census)** requires a directed network - mutual/asymmetric/null dyad types have no meaning for undirected ties, where every dyad is simply tied or not.

**tail()** controls which p-value(s) are reported: **upper** is the proportion of random draws with a statistic at least as large as observed (evidence the observed value is unusually *high*); **lower** is the proportion at least as small (unusually *low*); **both** (the default) reports both, plus a two-sided p-value (**r(p)**, twice the smaller one-sided p-value, capped at 1).

`plot` draws a histogram of the **reps()** null draws with a dashed vertical line at the observed statistic - the standard visual check for a CUG test (is the observed value out in the tail of the null distribution, or comfortably inside it?), the same comparison R's **sna** package's **plot.cug.test()** draws for its own **cug.test()**. Grayscale by design, matching every other plot this package produces.

## Supported network types

Binary: yes. Directed: yes (required for `condition(census)`). Weighted: depends entirely on **stat()** - `nwcug` itself only draws random comparison networks and calls whatever command **stat()** names, so it inherits that command's own support. Signed: same as weighted, depends on **stat()**. Two-mode: no - [nwrandom](nwrandom.md)'s density/census conditioning used to draw comparison networks does not support two-mode networks.

## Stored results

**Scalars**

- **r(obs)** observed statistic
- **r(reps)** number of random draws
- **r(mean_null)** mean of the statistic across random draws
- **r(sd_null)** standard deviation of the statistic across random draws
- **r(p_greater)** proportion of random draws >= observed (upper-tail p-value)
- **r(p_less)** proportion of random draws <= observed (lower-tail p-value)
- **r(p)** two-sided p-value (2 * min(p_greater, p_less), capped at 1)

## References

Anderson, B.S., Butts, C., Carley, K. (1999). The interaction of size and density with graph-level indices. *Social Networks* 21(3), 239-267.

## See also

- [nwrandom](nwrandom.md), [nwdyads](nwdyads.md), [nwpermute](nwpermute.md), [nwqap](nwqap.md)

- last certified : 24 Aug 2026
