---
title: "nwhomophily"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Generate a homophily network"
---

# `nwhomophily`

Generate a homophily network

## Syntax

```stata
nwhomophily 
varlist
,
homophily(h1 h2 ...)
density(float)
[mode(expand_mode)
nodes(integer)
name(string)
xvars
undirected]
```

| | |
|---|---|
| `homophily`(*`h1 h2 ...`*) | degree of homophily for each variable in `varlist` |
| `density(float)` | density of the new network |
| `mode`(*[expand_mode](nwexpand)*) | mode used to generate probabilities for ties |
| `nodes(integer)` | number of nodes; if not specified the number of valid cases of *`varname`* is used |
| `name(newnetname)` | name of the new random network |
| `xvars` | generate Stata variables for the network |

## Description

`nwhomophily` generates a homophily network - a network where ties between nodes *i* and *j* are more/less likely to exist when the two nodes have the same values on `varlist`. Basically, this command is a convenience wrapper for [nwdyadprob](nwdyadprob).

Each possible tie in the new network has the probability *p_ij* to exist. These proabilities are derived from a weight *w_ij* and the values defined in **homophily()** and **density()**.

The weight *w_ij* is calculated on the basis of the identity/similarity of nodes *i* and *j* on variables in `varlist` (see [nwexpand](nwexpand)). By default,

*w_ij = (varname[i] == varname[j])*, i.e. node *i* and node *j* have the same value on a variable.

Another way to calculate *w_ij* would be using ** mode(absdistinv)**

*w_ij = max(absdist) - abs(var[i] - var[j])* - a bounded inverse-distance transform (closer pairs score higher), not a literal *1/|diff|* reciprocal, deliberately avoiding the numerical blowup a true reciprocal would cause for near-equal values (see the caveat below)

For more information on how *w_ij* is calculated based on **mode()** see [nwexpand](nwexpand).

The probability *p_ij* is defined as:

*p_ij =  (exp(w_ij * homophily) / (sum_allk_alll(exp(w_kl * homophily)))*

The following example generates a variable *gender* and creates networks where ties are more likely to exist between nodes with the same gender.

```stata
. nwclear
. set obs 20
. gen gender = (_n > 10) + 2
. gen genderlabel = "Name"
. label define genderlabel 2 "male" 3 "female"
. label values gender genderlabel
```
So far, we just generated the variable *gender*. The next step produces the homophily network based on this variable and a positive **homophily()** effect. The size of this effect can be interpreted just like a logistic regression coefficient for homophilious ties to exist (conditioning on **density()**).

```stata
. nwhomophily gender, density(0.05) homophily(5)
. nwplot, color(gender) layout(circle) title("homophily = 5")
. graph save g1, replace
```
Next, we produce a network with a negative homophily parameter (heterophily). In this network, ties are more likely between nodes of different gender.

```stata
. nwhomophily gender, density(0.05) homophily(-5)
. nwplot, color(gender) layout(circle) title("homophily = -5")
. graph save g2, replace
```
Lastly, let us produce a network with no homohily effect at all.

```stata
. nwhomophily gender, density(0.05) homophily(0)
. nwplot, color(gender) layout(circle) title("homophily = 0")
. graph save g3, replace
```
All three new networks can be displayed in comparison:

```stata
. graph combine g1.gph g2.gph g3.gph
```
Notice that when *nwhomophily* is used together with *z* variables in `varlist`, the option **homophily()** also needs to have *z* entries. The next example also shows how the command works with non-categorical variables. After generating a categorical variable *gender* and a metric variable *income*, this would generate a homophily network where ties are less likely to exist between individuals with the same gender (effect size = -2) and more likely to exist between individuals who have similar (not the same) income (effect size = 0.5).

```stata
. nwhomophily gender income, density(0.05) homophily(-2 0.5) mode(same absdistinv)
```
**mode(absdistinv)**'s own weight scales with the raw magnitude of the underlying variable (unlike **mode(same)**'s bounded 0/1 indicator) - a large *homophily()* coefficient combined with a large-magnitude variable (e.g. income in the thousands) can produce weights skewed enough that the underlying sampler fails; scale the variable (e.g. to a 0-10 range) or use a smaller *homophily()* coefficient for **absdistinv**/**distinv** in that case.

## Remarks

The program requires some additional programs (**gsample, moremata**) that it will automatically install with a working internet connection.

## Supported network types

Binary: yes (only). Directed: yes, via `undirected` (default is directed). Weighted: not applicable - no `weights()` option; `density()` controls overall tie placement rate, not individual tie values. Signed: not applicable. Two-mode: not applicable - this generator always produces a one-mode network.

## See also

- [nwdyadprob](nwdyadprob)
