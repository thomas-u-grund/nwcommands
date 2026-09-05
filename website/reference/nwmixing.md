---
title: "nwmixing"
parent: "Command reference"
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
| `attribute(varname)` | Categorical (string or numeric) node attribute to cross-tabulate
ties by |
| `eiplot` | Plot the null (QAP-permutation) distribution of the E-I index, with the observed
value marked |
| `eiplotoptions(string)` | Additional options forwarded to the `eiplot`'s own
`kdensity` |
| `plot` | Plot the ego/alter mixing table via `tabplot` |
| `plotoptions(string)` | Additional options forwarded to `plot`'s own `tabplot` |
| `permutations(int)` | Number of QAP permutations for the E-I index's own null
distribution and p-value; default = 100. Set to 1 to skip the permutation test entirely (only the
observed table/index are reported) |
| `save(filename)` | Save the QAP permutation draws (variable *EI_simulated*) and the
observed value (variable *EI_observed*) to a new dataset |
| *tab_options* | Any other option is forwarded to the underlying `tab`
call that builds the mixing table (e.g. `row`, `column`, `cell`) |

## Description

`nwmixing` cross-tabulates every tie in the network by the `attribute()` value of its ego and alter (a "mixing table" or "mixing matrix"), and computes Krackhardt & Stern's (1988) E-I index: the number of ties *external* to an attribute category minus the number *internal* to it, divided by their sum. The index ranges from -1 (every tie stays within its own category - maximal homophily/segregation) to +1 (every tie crosses categories - maximal heterophily/integration); 0 indicates ties are split between internal and external exactly as the network's overall tie count would suggest.

Ties are treated as unvalued (presence/absence only) throughout - tie strength does not affect the mixing table or the E-I index.

With `permutations()` greater than 1 (the default, 100), `nwmixing` also runs a QAP permutation test: the attribute assignment is held fixed while the network itself is repeatedly randomly permuted, building a null distribution of the E-I index under "no association between this attribute and tie placement", and reports a two-sided p-value.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwmixing flomarriage, attribute(priorates)
```

## Supported network types

Binary: yes. Directed: yes - ego/alter mixing is directional for a directed network (an *attribute*`_ego`/*attribute*`_alter` pair is not symmetric); an undirected network's own mixing table instead shows each edge counted from both endpoints, noted explicitly in the output. Weighted: not applicable - see Description (ties are always treated as unvalued). Signed: not checked. Two-mode: not checked.

## Stored results

**Scalars**

- **r(EI_index)** the observed E-I index
- **r(EI_pvalue)** two-sided QAP permutation p-value (only when `permutations()` > 1)

**Macros**

- **r(netname)** the network name
- **r(attribute)** the `attribute()` variable name

**Matrices**

- **r(table)** the mixing table's own tie counts
- **r(col)** the mixing table's column category values
- **r(row)** the mixing table's row category values

## References

Krackhardt, D., Stern, R.N. (1988). Informal networks and organizational crises: An experimental simulation. *Social Psychology Quarterly* 51(2), 123-140.

## See also

- [nwassortativity](nwassortativity.md), [nwqap](nwqap.md), [nwcorrelate](nwcorrelate.md)
