---
title: "nwmixing"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "E-I index and mixing table for a categorical node attribute"
---

# `nwmixing`

E-I index and mixing table for a categorical node attribute

## Syntax

```stata
nwmixing
[netname]
,
attribute(varname)
[eiplot
eiplotoptions(string)
plot
plotoptions(string)
permutations(int)
save(filename)
tab_options]
```

| | |
|---|---|
| `attribute(varname)` | Categorical (string or numeric) node attribute to cross-tabulate ties by |
| `eiplot` | Plot the null (QAP-permutation) distribution of the E-I index, with the observed value marked |
| `eiplotoptions(string)` | Additional options forwarded to the `eiplot`'s own `kdensity` |
| `plot` | Plot the ego/alter mixing table as a bar plot in the style of `tabplot` (built in; see Remarks on plot) |
| `plotoptions(string)` | Additional options forwarded to `twoway` for `plot` |
| `permutations(int)` | Number of QAP permutations for the E-I index's own null distribution and p-value; default = 100. Set to 1 to skip the permutation test entirely (only the observed table/index are reported) |
| `save(filename)` | Save the QAP permutation draws (variable *EI_simulated*) and the observed value (variable *EI_observed*) to a dataset (an existing file is replaced); only when `permutations()` > 1 |
| *tab_options* | Any other option is forwarded to the underlying `tab` call that builds the mixing table (e.g. `row`, `column`, `cell`) |

## Description

`nwmixing` cross-tabulates every tie in the network by the `attribute()` value of its ego and alter (a "mixing table" or "mixing matrix"), and computes Krackhardt & Stern's (1988) E-I index: the number of ties *external* to an attribute category minus the number *internal* to it, divided by their sum. The index ranges from -1 (every tie stays within its own category - maximal homophily/segregation) to +1 (every tie crosses categories - maximal heterophily/integration); 0 indicates ties are split between internal and external exactly as the network's overall tie count would suggest.

Ties are treated as unvalued (presence/absence only) throughout - tie strength does not affect the mixing table or the E-I index.

With `permutations()` greater than 1 (the default, 100), `nwmixing` also runs a QAP permutation test: the attribute assignment is held fixed while the network itself is repeatedly randomly permuted, building a null distribution of the E-I index under "no association between this attribute and tie placement", and reports a two-sided p-value.

## Remarks on plot

The `plot` option draws the table with a built-in bar plot (the same plot the user-written `tabplot` draws; `tabplot` itself is not needed, and is not used even if it is installed). Any further options in `plotoptions()` are passed to `twoway`. The built-in plot follows the idea and the look of Nick Cox's `tabplot` (SSC); thanks to N. J. Cox.

## Network types

**Directed:** the mixing table is directional (ego to alter); on an undirected network every tie is counted from both ends, as the output notes. **Valued:** tie values are ignored (every tie counts as present; the command prints a note). **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

The mixing table counts ties, so only the ties are listed (not all dyads). Measured in Stata/BE, random directed network with 10 ties per node: 5,000 nodes 0.3 seconds. The significance test (`permutations()`) permutes the attribute on the dense adjacency matrix; its running time at 5,000 nodes has not been measured.

The permutations of `permutations()` act on the stored ties of a network that is held that way (a tie (u,v) lands in the cell (inv u, inv v) of the permuted matrix, O(ties) per draw). 20,000 nodes with 20 permutations: 1.2 seconds.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwmixing flomarriage, attribute(priorates)
```

## Stored results

- **Scalars**
- **r(EI_index)** --- the observed E-I index
- **r(EI_pvalue)** --- two-sided QAP permutation p-value with the plus-one Monte Carlo correction, 2(1 + k)/(permutations + 1) with k the number of draws in the smaller tail, so that it is never 0 (only when `permutations()` > 1)

- **Macros**
- **r(netname)** --- the network name
- **r(attribute)** --- the `attribute()` variable name

- **Matrices**
- **r(table)** --- the mixing table's own tie counts
- **r(col)** --- the mixing table's column category values
- **r(row)** --- the mixing table's row category values

## References

Krackhardt, D., Stern, R.N. (1988). Informal networks and organizational crises: An experimental simulation. *Social Psychology Quarterly* 51(2), 123-140.

## See also

- [nwassortativity](nwassortativity), [nwqap](nwqap), [nwcorrelate](nwcorrelate)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
