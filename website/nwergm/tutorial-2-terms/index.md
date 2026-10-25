---
title: "Tutorial 2: Terms and model specification"
parent: "nwergm (ERGM)"
nav_order: 3
description: "How to choose and read the terms of an ERGM with nwergm: structural, degree, triad and covariate terms, nodematch and nodemix, and the decay of gwesp."
---

# ERGM 2: Terms and model specification

**Goal.** Learn how a model is written in `nwergm` and how to read the coefficient of each kind of
term: covariate terms (`nodematch`, `nodefactor`, `nodemix`, `nodeicov`), structural terms (`mutual`)
and triad terms (`gwesp`, with its decay parameter).

* This is the second ERGM tutorial. It builds on [Intro to ERGM in Stata](../../tutorials/09-intro-ergm/),
  which fits a first model and explains `edges`, MPLE and MCMLE.
* You need the core `nwcommands` and the package `nwergm` (see [Install](../install/)).

**Data.** Two networks that ship with `nwcommands` and are loaded with `nwwebuse`: `mesa`, the friendship
network of 205 students in a US high school (undirected, with the attributes `grade`, `race` and `sex`),
and `lazega`, the friendship network among 71 lawyers of a law firm (directed, with `practice`,
`seniority` and others). The commands below were run with `nwergm` 1.0.1 and the core 3.0.0; the
complete script and log are in [example.do](example.do) and [example.log](example.log). Every model
uses only terms that are in the released version 1.0.1. Models fitted by Monte Carlo involve
simulation, so a repetition with another `seed()` gives slightly different numbers.
Output is shortened to the coefficient table and the log-likelihood line; `...` marks what is left out.

## How a model is written

```stata
nwergm netname, edges term1 term2(...) ... [options]
```

`edges` is required (it is the intercept). Every other term is an option named after the term of R's
`ergm`. Each coefficient is the change in the log-odds of a tie when the statistic of the term grows by
one, given everything else in the model. One restriction: nodal attributes must be **numeric**, so a
string variable has to be encoded first.

## Covariate terms on the mesa network

```stata
. nwwebuse mesa, nwclear
. encode race, generate(race_n)
. encode sex, generate(sex_n)
```

With only `edges` the coefficient is the log-odds of the density of the network:

```stata
. nwergm mesa, edges

Exponential-family random graph model

Network:               =  mesa
Nodes:                 =  205
Ties:                  =  203
Directed:              =  No
Estimation:            =  MPLE

------------------------------------------------------------------------------
        mesa | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       edges |  -4.625021   .0705294   -65.58   0.000    -4.763256   -4.486786
------------------------------------------------------------------------------

Maximum pseudolikelihood estimate (not full ERGM maximum likelihood unless the model is dyad-independent).

             Null Deviance:   28987.4  on 20910 degrees of freedom
         Residual Deviance:    2285.7  on 20909 degrees of freedom

Log-likelihood: -1142.8711 (df = 1)   AIC:    2287.7   BIC:    2295.7   (MC std. err. =       0)
```

`nodematch(grade)` adds one statistic: the number of ties between students of the same grade.

```stata
. nwergm mesa, edges nodematch(grade)
...
---------------------------------------------------------------------------------
           mesa | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
          edges |  -6.034045   .1583032   -38.12   0.000    -6.344314   -5.723776
nodematch_grade |   2.830999   .1773251    15.97   0.000     2.483449     3.17855
---------------------------------------------------------------------------------
...
Log-likelihood:  -969.7742 (df = 2)   AIC:    1943.5   BIC:    1959.4   (MC std. err. =       0)
```

The coefficient 2.83 is large: the odds of a tie between two students of the same grade are
exp(2.83), about 17 times the odds for students of different grades, holding the other terms fixed.
Adding race and sex works the same way, one coefficient per variable:

```stata
. nwergm mesa, edges nodematch(grade race_n sex_n)
...
----------------------------------------------------------------------------------
            mesa | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-----------------+----------------------------------------------------------------
           edges |  -6.600575   .1998753   -33.02   0.000    -6.992324   -6.208827
 nodematch_grade |   2.830693    .177456    15.95   0.000     2.482886    3.178501
nodematch_race_n |   .4331562   .1429951     3.03   0.002     .1528911    .7134214
 nodematch_sex_n |   .6447389    .149475     4.31   0.000     .3517733    .9377045
----------------------------------------------------------------------------------
...
Log-likelihood:  -955.5870 (df = 4)   AIC:    1919.2   BIC:    1951.0   (MC std. err. =       0)
```

All three kinds of homophily are positive, and grade is by far the strongest. Every term so far depends
only on the attributes of the two students, so the model is **dyad-independent**: `nwergm` reports the
maximum pseudolikelihood estimate (MPLE), which for such a model is the maximum likelihood estimate,
and no simulation is needed.

### Pooled or differential homophily

`nodematch` pools all levels of an attribute into one coefficient. `nodematchdiff()` gives one
coefficient per level, so you can see whether homophily is equally strong for girls and for boys:

```stata
. nwergm mesa, edges nodematch(grade) nodematchdiff(sex_n)
...
-----------------------------------------------------------------------------------
             mesa | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
------------------+----------------------------------------------------------------
            edges |  -6.392904   .1856467   -34.44   0.000    -6.756765   -6.029043
  nodematch_grade |   2.820284   .1774895    15.89   0.000     2.472411    3.168157
nodematch_sex_n_1 |   .8880277   .1651607     5.38   0.000     .5643186    1.211737
nodematch_sex_n_2 |    .333064   .1871779     1.78   0.075     -.033798     .699926
-----------------------------------------------------------------------------------
...
Log-likelihood:  -955.4147 (df = 4)   AIC:    1918.8   BIC:    1950.6   (MC std. err. =       0)
```

(The levels of `sex_n` are 1 for F and 2 for M.) The preference for the same sex is clearer among girls
(0.89, p < 0.001) than among boys (0.33, p = 0.075).

### Activity by group and mixing between groups

`nodefactor()` asks whether members of a group have more ties overall: one coefficient per level, the
first level being the reference, as in R. `nodemix()` gives one coefficient per cell of the mixing
matrix, again with the first cell as the reference:

```stata
. nwergm mesa, edges nodematch(grade) nodefactor(race_n) nodemix(sex_n)
...
-------------------------------------------------------------------------------------
               mesa | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------------+----------------------------------------------------------------
              edges |  -3.303633   .4342755    -7.61   0.000    -4.154797   -2.452468
    nodematch_grade |   2.874633   .1785757    16.10   0.000     2.524631    3.224635
nodefactor_race_n_2 |  -1.335929   .2233276    -5.98   0.000    -1.773643   -.8982147
nodefactor_race_n_3 |   -.924473   .2260387    -4.09   0.000    -1.367501   -.4814453
nodefactor_race_n_4 |  -3.214314   1.025584    -3.13   0.002    -5.224422   -1.204206
nodefactor_race_n_5 |  -.8606332   .2582152    -3.33   0.001    -1.366726   -.3545407
  nodemix_sex_n_1_2 |  -.9352662   .1663521    -5.62   0.000     -1.26131   -.6092221
  nodemix_sex_n_2_2 |  -.6284435   .1849762    -3.40   0.001    -.9909901   -.2658968
-------------------------------------------------------------------------------------
...
Log-likelihood:  -931.6931 (df = 8)   AIC:    1879.4   BIC:    1943.0   (MC std. err. =       0)
```

The levels of `race_n` are sorted alphabetically (Black, Hisp, NatAm, Other, White), so the reference
is the small group of 6 Black students. Each `nodefactor_race_n_k` compares group `k` with it: all four
are negative, so students of the other groups have fewer ties on average. This is a statement about how
many ties people have, not about with whom they tie. The two `nodemix_sex_n` cells (girl-boy and
boy-boy) are measured against girl-girl ties, the reference cell: both are negative, so, given the
other terms, girl-girl is the most frequent kind of tie in these data.

## Dyad-dependent terms on the Lazega network

A term such as `mutual` (the number of reciprocated pairs) depends on more than one dyad at a time, so
the model is dyad-dependent. `nwergm` then switches to Monte Carlo maximum likelihood on its own, and
`seed()` makes the simulation repeatable. `nodeicov()` is the effect of a numeric attribute on
**receiving** ties.

```stata
. nwwebuse lazega, nwclear
. encode practice, generate(prac)
```

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority)
...
------------------------------------------------------------------------------------
         lazega_fr | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------------+----------------------------------------------------------------
             edges |  -2.516783   .1054299   -23.87   0.000    -2.723422   -2.310144
            mutual |   .9978762   .1575409     6.33   0.000     .6891017    1.306651
    nodematch_prac |   .9083953   .0933166     9.73   0.000     .7254982    1.091292
nodeicov_seniority |   -.006562   .0021514    -3.05   0.002    -.0107788   -.0023453
------------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood: -1697.3338 (df = 4)   AIC:    3402.7   BIC:    3428.7   (MC std. err. =  .02686)
```

`mutual` is 0.99: friendships are strongly reciprocal. Lawyers of the same practice are more likely to
be friends, and the negative `nodeicov_seniority` says that lawyers with a higher value of `seniority`
receive slightly fewer friendship nominations.

### The decay of gwesp

Friends of friends tend to become friends. `gwesp(decay)` counts tied pairs that have shared partners,
with diminishing weight for each additional partner; `decay` sets how fast the weight diminishes (a
small decay means that the second and third shared partner add little, a large decay that each shared
partner counts nearly fully). The right value is an empirical question. Here are two values:

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(0.5) seed(1)
...
------------------------------------------------------------------------------------
         lazega_fr | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------------+----------------------------------------------------------------
             edges |  -3.323792   .1300159   -25.56   0.000    -3.578619   -3.068966
            mutual |   .8118747   .1619457     5.01   0.000     .4944671    1.129282
    nodematch_prac |   .7068091   .0811852     8.71   0.000      .547689    .8659292
nodeicov_seniority |  -.0043879   .0016961    -2.59   0.010    -.0077123   -.0010636
         gwesp_0.5 |   .4927714   .0630313     7.82   0.000     .3692323    .6163106
------------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood: -1668.2523 (df = 5)   AIC:    3346.5   BIC:    3379.1   (MC std. err. =  .07975)
```

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(1) seed(1)
...
------------------------------------------------------------------------------------
         lazega_fr | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------------+----------------------------------------------------------------
             edges |   -3.17037   .1094412   -28.97   0.000     -3.38487   -2.955869
            mutual |   .7987458   .1583605     5.04   0.000      .488365    1.109127
    nodematch_prac |   .6946017   .0806937     8.61   0.000      .536445    .8527583
nodeicov_seniority |  -.0044466   .0016232    -2.74   0.006    -.0076281   -.0012651
           gwesp_1 |   .3263843   .0377359     8.65   0.000     .2524233    .4003453
------------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood: -1666.1471 (df = 5)   AIC:    3342.3   BIC:    3374.9   (MC std. err. =  .04272)
```

Both values give a clearly positive closure effect and similar other coefficients, but the two
`gwesp` coefficients cannot be compared by size, because the statistic is scaled differently. Compare
the models through the log-likelihood, AIC and BIC (see [Tutorial 4](../tutorial-4-missing-comparing/)):
here -1667.8 for decay 0.5 and -1666.6 for decay 1, a small difference. To let the data choose the
decay, the curved term `gwespfree()` estimates it as a parameter.

### Adding a degree term

Terms for the degree distribution (`gwidegree()`, `gwodegree()`, `degree()`, `kstar()` and others)
are added in the same way:

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(0.5) gwidegree(0.5) seed(1)
...
------------------------------------------------------------------------------------
         lazega_fr | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------------+----------------------------------------------------------------
             edges |   -3.35556   .1433422   -23.41   0.000    -3.636506   -3.074615
            mutual |   .8133899   .1624744     5.01   0.000      .494946    1.131834
    nodematch_prac |   .7103852   .0807026     8.80   0.000      .552211    .8685594
nodeicov_seniority |  -.0045569   .0019048    -2.39   0.017    -.0082903   -.0008236
         gwesp_0.5 |   .5028252   .0677129     7.43   0.000     .3701103    .6355401
     gwidegree_0.5 |   1.143053   1.770761     0.65   0.519    -2.327575    4.613682
------------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood: -1667.0046 (df = 6)   AIC:    3346.0   BIC:    3385.1   (MC std. err. =  .04225)
```

The coefficient of the in-degree term (1.04) is small relative to its standard error (1.59), so it adds
nothing here. Keep a term only if it answers your question or improves the model.

## Things to try

- Replace `nodematch(prac)` by `nodematchdiff(prac)` and see whether homophily differs between the
  two practices.
- Add `nodeocov(seniority)` (the effect on **sending** ties).
- Fit the Lazega model with `gwesp(0.25)` and with `gwesp(0.75)` and compare AIC with `estimates stats`.
- Try `edgecov(lazega_cow)` to ask whether lawyers who are co-workers are friends; a dyadic covariate
  is another network in memory.
- `help nwergm` lists all term options; [Terms](../terms/) is a map of the families.

## Where next

[Tutorial 3](../tutorial-3-diagnostics/) shows how to check that a Monte Carlo fit can be trusted and
how well the fitted model reproduces the network.
