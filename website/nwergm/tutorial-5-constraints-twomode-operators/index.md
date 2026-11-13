---
title: "Tutorial 5: Constraints, two-mode networks and operators"
parent: "nwergm (ERGM)"
nav_order: 6
description: "Restrict the sample space with constraints(), model two-mode (bipartite) networks, and use operator terms such as Symmetrize and Project in nwergm."
---

# Tutorial 5: Constraints, two-mode networks and operators

**Goal.** Three tools beyond the basic model: **constraints** that restrict the networks the model is
defined on, **two-mode** terms for networks between two kinds of nodes (people and clubs), and
**operators** that evaluate terms on a derived network.

* Builds on [Tutorial 2](../tutorial-2-terms/) to [Tutorial 4](../tutorial-4-missing-comparing/).
* Needs the core `nwcommands` and `nwergm` (see [Install](../install/)).
* **The operators in the last section need `nwergm` 1.1.0 or later.** The other sections work with 1.0.1 as well.

**Data.** The Florentine marriage network and the Lazega friendship network (both shipped with
`nwcommands`), and a small two-mode network of 30 people and 12 clubs that is **simulated** in the
script (so that you can recreate it exactly; it is not a real data set). Run with `nwergm` 1.6.0 and the core 3.22.0; the
script and log are in [example.do](example.do) and [example.log](example.log).
Output is shortened to the coefficient table and the log-likelihood line.

## Constraints

A constraint changes the set of networks that the model is defined on. `constraints(edges)` holds the number
of ties fixed: the model then describes how a *fixed* number of ties is arranged, and the density
parameter drops out. Compare the unconstrained and the constrained fit:

```stata
. nwwebuse florentine, nwclear
```

```stata
. nwergm flomarriage, edges nodecov(wealth) gwesp(0.5) seed(1)
...
--------------------------------------------------------------------------------
   flomarriage | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
---------------+----------------------------------------------------------------
         edges |  -2.576975   .5269599    -4.89   0.000    -3.609798   -1.544153
nodecov_wealth |   .0104462   .0045714     2.29   0.022     .0014864    .0194061
     gwesp_0.5 |  -.0045009   .2390051    -0.02   0.985    -.4729422    .4639405
--------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood:   -51.5534 (df = 3)   AIC:     109.1   BIC:     117.5
Monte Carlo standard error of the log-likelihood:  .00086
```

```stata
. nwergm flomarriage, edges nodecov(wealth) gwesp(0.5) constraints(edges) seed(1)
...
--------------------------------------------------------------------------------
   flomarriage | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
---------------+----------------------------------------------------------------
         edges |          0  (omitted)
nodecov_wealth |   .0097449   .0049592     1.97   0.049      .000025    .0194649
     gwesp_0.5 |   .0487482   .2489059     0.20   0.845    -.4390985    .5365949
--------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood:   -55.4304 (df = 2)   AIC:     114.9   BIC:     120.4
Monte Carlo standard error of the log-likelihood:  .19034
```

`nwergm` prints a note that the constraint holds `edges` constant, and the coefficient of `edges` is
shown as omitted. The other coefficients are close to those of the unconstrained model. Other
constraints written as in R's `constraints=` include `degrees`, `odegrees`, `idegrees`, `bd()`,
`blocks()`, `blockdiag()`, `fixedas()`, `fixallbut()` and `observed`; see `help nwergm_constraints`. The related
`obsconstraints()` describes how the network was observed.

## Two-mode networks

In a two-mode (bipartite) network the ties go between two kinds of nodes, here people (mode 1)
and clubs (mode 2). We build the network from a 12 x 30 matrix of memberships with `nwset ..., bipartite`; a
person's group (`kind`, 1 or 2) and a club's type (also 1 or 2) are stored in one variable, the persons
first. The simulation makes ties more likely when person and club are of the same kind (probability 0.30,
otherwise 0.08), so we know what the model should find.

```stata
. nwset, mat(B) bipartite name(clubs)
. set obs 42
. generate byte kind = .
. mata: st_store(., "kind", (g1 \ g2))
```

```stata
. nwsummarize
--------------------------------------------------
   Network name:  clubs
   Network id:  1
   Directed: false
   Valued: false
   Two-mode: true
   Nodes: 42
      Level 1: 30 ()
      Level 2: 12 ()
   Selfloop: false
   Edges: 71
   Minimum value:  0
   Maximum value:  1
   Density:  .197
   Temporal: false
```

Terms that name a mode follow R's `b1`/`b2` terms, with the digit moved to the end (`bdegree1()` is R's
`b1degree`, `bgwdegree2()` is `gwb2degree`). `nodemix()` on a two-mode network gives one coefficient per
combination of the person's and the club's level; the first cell (1,1) is the reference.

```stata
. nwergm clubs, edges nodemix(kind)
...
----------------------------------------------------------------------------------
           clubs | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-----------------+----------------------------------------------------------------
           edges |  -.7563261   .1787266    -4.23   0.000    -1.106624   -.4060283
nodemix_kind_2_1 |  -1.512357   .3931267    -3.85   0.000    -2.282872   -.7418434
nodemix_kind_1_2 |  -2.379168   .6162542    -3.86   0.000    -3.587004   -1.171332
nodemix_kind_2_2 |  -.2340726   .3707259    -0.63   0.528    -.9606821    .4925369
----------------------------------------------------------------------------------
...
Log-likelihood:  -160.5841 (df = 4)   AIC:     329.2   BIC:     344.7
```

The cell (1,1) is the reference. Ties between persons of kind 2 and clubs of kind 1 (`2_1`) and
between persons of kind 1 and clubs of kind 2 (`1_2`) are much less likely than same-kind ties
(coefficients -1.51 and -2.38), whereas (2,2) does not differ from (1,1) (-0.23, p = 0.53). This is exactly the pattern put into the simulated data.
The model is dyad-independent, so it is fitted by pseudolikelihood. A degree term for the clubs makes it
dyad-dependent:

```stata
. nwergm clubs, edges nodemix(kind) bgwdegree2(0.5) seed(1)
...
----------------------------------------------------------------------------------
           clubs | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-----------------+----------------------------------------------------------------
           edges |  -.7414179   .1930383    -3.84   0.000    -1.119766   -.3630697
nodemix_kind_2_1 |  -1.506756   .4068944    -3.70   0.000    -2.304254   -.7092575
nodemix_kind_1_2 |  -2.212356   .5936993    -3.73   0.000    -3.375985   -1.048727
nodemix_kind_2_2 |  -.0559743   .4063925    -0.14   0.890    -.8524889    .7405403
  bgwdegree2_0.5 |  -1.690794   1.394711    -1.21   0.225    -4.424378     1.04279
----------------------------------------------------------------------------------

MCMLE converged after 2 iteration(s).
...
Log-likelihood:  -160.1196 (df = 5)   AIC:     330.2   BIC:     349.7
Monte Carlo standard error of the log-likelihood:   .0943
```

The geometrically weighted degree of the clubs, with decay 0.5, is not significant here (-1.69, s.e. 1.39):
there is no evidence that the popularity of the clubs is unevenly distributed. The other terms for
two-mode networks are listed in `help nwergm_bipartite`: concurrency, minimum degree and degree ranges,
stars, covariate ranges, shared-partner terms (`dsp`, `gwdsp`, `coincidence`) and the curved versions with an
estimated decay.

## Operators (version 1.1.0)

An operator evaluates terms on a derived network, or combines and transforms terms: `Sum`, `Prod`,
`S` (the subgraph induced by a set of nodes), `F` (filtered ties), `NodematchFilter`, `Symmetrize`, `Project`,
`I`, `For`, `Label`, `Log`, `Exp`, `Offset` and `Curve`. They are written like R's operator terms inside `operators()`; the
terms inside an operator are options of `nwergm`. Coefficient names follow R's, with `.`
replaced by `_`. Two examples.

**`Proj1()`** applies terms to the one-mode projection of the people: two people are tied if they share
a club. `edges` and `triangle` of the projection ask whether people who belong to common clubs are
unusually often connected, over and above the model for the two-mode ties.

```stata
. nwergm clubs, edges nodemix(kind) operators(Proj1(edges triangle)) seed(1)
...
----------------------------------------------------------------------------------
           clubs | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-----------------+----------------------------------------------------------------
           edges |  -1.105045   .3662216    -3.02   0.003    -1.822826   -.3872639
nodemix_kind_2_1 |  -1.776232   .5313858    -3.34   0.001    -2.817729   -.7347348
nodemix_kind_1_2 |   -2.40565   .6836645    -3.52   0.000    -3.745607   -1.065692
nodemix_kind_2_2 |  -.2850296    .459771    -0.62   0.535    -1.186164     .616105
     Proj1~edges |   .1944617   .1914415     1.02   0.310    -.1807567    .5696801
  Proj1~triangle |  -.0139922   .0263967    -0.53   0.596    -.0657289    .0377444
----------------------------------------------------------------------------------

MCMLE converged after 3 iteration(s).
...
Log-likelihood:  -159.5072 (df = 6)   AIC:     331.0   BIC:     354.3
Monte Carlo standard error of the log-likelihood:  .16144
```

Neither projected term is significant (`Proj1~edges` 0.19, s.e. 0.19), as the data were generated
without any such structure.

**`Symmetrize()`** evaluates a term on the undirected network that is obtained from a directed one.
With `rule(strong)`, two lawyers are tied if the friendship is reciprocated, so `Symmetrize(strong)~triangle`
counts triangles among mutual friendships:

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) operators(Symmetrize(triangle, rule(strong))) seed(1)
...
---------------------------------------------------------------------------------------------
                  lazega_fr | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------------------+----------------------------------------------------------------
                      edges |  -2.736795   .0810857   -33.75   0.000     -2.89572    -2.57787
                     mutual |   .9130825   .1676719     5.45   0.000     .5844516    1.241713
             nodematch_prac |   .8967159   .0964408     9.30   0.000     .7076954    1.085736
Symmetrize(strong)~triangle |   .6922598   .4560459     1.52   0.129    -.2015737    1.586093
---------------------------------------------------------------------------------------------

MCMLE converged after 5 iteration(s).
...
Log-likelihood: -1700.7989 (df = 4)   AIC:    3409.6   BIC:    3435.6
Monte Carlo standard error of the log-likelihood:  .10562
```

Closure among reciprocated friendships is positive but not significant (0.69, s.e. 0.46, p = 0.13), next to the
reciprocity (`mutual`) and same-practice effects. The AIC of this model (3409.6) can be compared with the two Lazega models of
[Tutorial 4](../tutorial-4-missing-comparing/), which have the same other terms and the same N: 3410.6 without a
closure term and 3349.4 with `gwesp(0.5)`. Closure among *reciprocated* friendships alone hardly improves
the model (3409.6 against 3410.6), while the `gwesp` term does: the closure in this network is not restricted to mutual ties.

Operators cannot be combined with `constraints()`, `obsconstraints()`, `freedyads()`, `blockdiag()` or
`fixdensity`, and a curved (free-decay) term cannot be used inside an operator. The complete list
and arguments are in `help nwergm_operators`.

## Things to try

- Change the decay of `bgwdegree2()` from 0.5 to 1 and compare the log-likelihoods.
- Use `Label()` to give a term your own coefficient name, and `Offset()` to hold a coefficient at a fixed value.
- Replace `rule(strong)` by `rule(weak)` in the `Symmetrize` example.
- Constrain the degrees of the people in the club model with `constraints(b1degrees)` and read the
  warnings: `edges` is then fixed by the constraint and the other terms may become collinear.

## Where next

[nwergm and R's ergm](../rergm/) lists what is the same and what is missing; [Terms](../terms/) is the map of
all term families.
