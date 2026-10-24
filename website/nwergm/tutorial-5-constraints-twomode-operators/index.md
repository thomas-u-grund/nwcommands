---
title: "ERGM 5: Constraints, two-mode networks and operators"
parent: "nwergm (ERGM)"
nav_order: 6
description: "Restrict the sample space with constraints(), model two-mode (bipartite) networks, and use operator terms such as Symmetrize and Project in nwergm."
---

# ERGM 5: Constraints, two-mode networks and operators

**Goal.** Three tools beyond the basic model: **constraints** that restrict the networks the model is
defined on, **two-mode** terms for networks between two kinds of nodes (people and clubs), and
**operators** that evaluate terms on a derived network.

* Builds on [ERGM 2](../tutorial-2-terms/) to [ERGM 4](../tutorial-4-missing-comparing/).
* Needs the core `nwcommands` and `nwergm` (see [Install](../install/)).
* **The operators in the last section are in the development version of `nwergm` and will be in the
  next release; they are not in the 1.0.1 release.** Everything else on this page is in 1.0.1: I ran
  those commands with both the development version and the 1.0.1 tag, and the coefficient tables are identical.

**Data.** The Florentine marriage network and the Lazega friendship network (both shipped with
`nwcommands`), and a small two-mode network of 30 people and 12 clubs that is **simulated** in the
script (so that you can recreate it exactly; it is not a real data set). Run with the core 3.0.0; the
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
         edges |  -2.605989   .5516758    -4.72   0.000    -3.687253   -1.524724
nodecov_wealth |   .0106207   .0049005     2.17   0.030     .0010159    .0202256
     gwesp_0.5 |  -.0110212   .2695755    -0.04   0.967    -.5393795    .5173372
--------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood:   -51.5556 (df = 3)   AIC:     109.1   BIC:     117.5   (MC std. err. =  .00137)
```

```stata
. nwergm flomarriage, edges nodecov(wealth) gwesp(0.5) constraints(edges) seed(1)
...
--------------------------------------------------------------------------------
   flomarriage | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
---------------+----------------------------------------------------------------
         edges |          0  (omitted)
nodecov_wealth |   .0101067   .0049302     2.05   0.040     .0004436    .0197698
     gwesp_0.5 |   .0416532    .269677     0.15   0.877     -.486904    .5702104
--------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood:   -55.3094 (df = 2)   AIC:     114.6   BIC:     120.2   (MC std. err. =  .03135)
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
Log-likelihood:  -160.5841 (df = 4)   AIC:     329.2   BIC:     344.7   (MC std. err. =       0)
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
           edges |  -.7193805   .1700763    -4.23   0.000    -1.052724   -.3860371
nodemix_kind_2_1 |  -1.508956   .3994583    -3.78   0.000     -2.29188   -.7260322
nodemix_kind_1_2 |  -2.281624   .6240499    -3.66   0.000    -3.504739   -1.058508
nodemix_kind_2_2 |  -.0955488   .3818886    -0.25   0.802    -.8440367    .6529391
  bgwdegree2_0.5 |  -1.780811   1.446186    -1.23   0.218    -4.615284    1.053662
----------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood:  -160.3273 (df = 5)   AIC:     330.7   BIC:     350.1   (MC std. err. =  .02951)
```

The geometrically weighted degree of the clubs, with decay 0.5, is not significant here (-1.78, s.e. 1.45):
there is no evidence that the popularity of the clubs is unevenly distributed. The other terms for
two-mode networks are listed in `help nwergm_bipartite`: concurrency, minimum degree and degree ranges,
stars, covariate ranges, shared-partner terms (`dsp`, `gwdsp`, `coincidence`) and the curved versions with an
estimated decay.

## Operators (development version)

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
           edges |  -1.139001    .379029    -3.01   0.003    -1.881884   -.3961175
nodemix_kind_2_1 |  -1.723024   .4929781    -3.50   0.000    -2.689243   -.7568042
nodemix_kind_1_2 |  -2.436596   .6572586    -3.71   0.000    -3.724799   -1.148393
nodemix_kind_2_2 |  -.2391259   .4489509    -0.53   0.594    -1.119054    .6408018
     Proj1~edges |   .1819743    .186709     0.97   0.330    -.1839686    .5479173
  Proj1~triangle |  -.0118757   .0252019    -0.47   0.637    -.0612706    .0375191
----------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood:  -159.7977 (df = 6)   AIC:     331.6   BIC:     354.9   (MC std. err. =  .03068)
```

Neither projected term is significant (`Proj1~edges` 0.18, s.e. 0.19), as the data were generated
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
                      edges |  -2.753317   .0810188   -33.98   0.000    -2.912111   -2.594523
                     mutual |   .9896271   .1824762     5.42   0.000     .6319803    1.347274
             nodematch_prac |   .9098446   .0939548     9.68   0.000     .7256965    1.093993
Symmetrize(strong)~triangle |   1.017895    .271825     3.74   0.000     .4851273    1.550662
---------------------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood: -1703.4419 (df = 4)   AIC:    3414.9   BIC:    3440.9   (MC std. err. =  .02772)
```

Closure among reciprocated friendships is strongly positive (1.02, s.e. 0.27), on top of the
reciprocity (`mutual`) and same-practice effects. The AIC of this model (3414.9) can be compared with the two Lazega models of
[ERGM 4](../tutorial-4-missing-comparing/), which have the same other terms and the same N: 3410.9 without a
closure term and 3349.9 with `gwesp(0.5)`. Closure among *reciprocated* friendships alone does not improve
the model, while the `gwesp` term does: the closure in this network is not restricted to mutual ties.

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
