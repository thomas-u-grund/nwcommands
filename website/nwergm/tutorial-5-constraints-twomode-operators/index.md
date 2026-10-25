---
title: "Tutorial 5: Constraints, two-mode networks and operators"
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
* **The operators in the last section need `nwergm` 1.1.0 or later.** The other sections work with 1.0.1 as well.

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
         edges |  -2.601731   .5516856    -4.72   0.000    -3.683015   -1.520447
nodecov_wealth |    .010747   .0050312     2.14   0.033     .0008861    .0206079
     gwesp_0.5 |  -.0155111   .2702111    -0.06   0.954    -.5451152    .5140929
--------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood:   -51.5535 (df = 3)   AIC:     109.1   BIC:     117.5   (MC std. err. =  .00031)
```

```stata
. nwergm flomarriage, edges nodecov(wealth) gwesp(0.5) constraints(edges) seed(1)
...
--------------------------------------------------------------------------------
   flomarriage | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
---------------+----------------------------------------------------------------
         edges |          0  (omitted)
nodecov_wealth |   .0102325   .0051168     2.00   0.046     .0002038    .0202612
     gwesp_0.5 |   .0356296   .2746778     0.13   0.897     -.502729    .5739883
--------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood:   -55.2627 (df = 2)   AIC:     114.5   BIC:     120.1   (MC std. err. =  .15074)
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
           edges |  -.7311237   .1727851    -4.23   0.000    -1.069776   -.3924711
nodemix_kind_2_1 |  -1.503362   .3983645    -3.77   0.000    -2.284142   -.7225817
nodemix_kind_1_2 |  -2.243641   .6135545    -3.66   0.000    -3.446186   -1.041096
nodemix_kind_2_2 |  -.0679029   .3766518    -0.18   0.857    -.8061268    .6703211
  bgwdegree2_0.5 |  -1.788379    1.47199    -1.21   0.224    -4.673427    1.096668
----------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood:  -160.2587 (df = 5)   AIC:     330.5   BIC:     349.9   (MC std. err. =  .08311)
```

The geometrically weighted degree of the clubs, with decay 0.5, is not significant here (-1.78, s.e. 1.45):
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
           edges |  -1.115536   .3680386    -3.03   0.002    -1.836878   -.3941935
nodemix_kind_2_1 |  -1.719906   .5034645    -3.42   0.001    -2.706678   -.7331337
nodemix_kind_1_2 |  -2.339619   .6306518    -3.71   0.000    -3.575674   -1.103565
nodemix_kind_2_2 |  -.2481904   .4301325    -0.58   0.564    -1.091235    .5948538
     Proj1~edges |   .1732472   .1869192     0.93   0.354    -.1931076    .5396021
  Proj1~triangle |   -.011537    .025884    -0.45   0.656    -.0622688    .0391948
----------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood:  -159.8953 (df = 6)   AIC:     331.8   BIC:     355.1   (MC std. err. =  .03188)
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
                      edges |  -2.735312   .0817972   -33.44   0.000    -2.895632   -2.574992
                     mutual |   .9106177   .1723656     5.28   0.000     .5727873    1.248448
             nodematch_prac |   .8949306    .094184     9.50   0.000     .7103335    1.079528
Symmetrize(strong)~triangle |    .748699   .4483014     1.67   0.095    -.1299556    1.627354
---------------------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood: -1701.3376 (df = 4)   AIC:    3410.7   BIC:    3436.7   (MC std. err. =  .05874)
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
