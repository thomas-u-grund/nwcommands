---
title: "Tutorial 2: Effects and interpretation"
parent: "nwdynam tutorials"
nav_order: 2
description: "Add covariates, closure effects, recency windows and weights to a DyNAM with nwdynam, and compare models by their log likelihoods."
grand_parent: "nwdynam (DyNAM)"
---

# Tutorial 2: Effects and interpretation

**Goal.** Extend the model of [Tutorial 1](../tutorial-1-first-dynam/) with actor attributes, closure effects and recency, read the new
coefficients, and decide with a likelihood-ratio test which additions earn their place.

**Data.** The same 439 phone calls among 84 students, plus two attributes per student: `floor`, the floor of the
dorm on which the student lived (1 to 9), and `gradetype`. Both data files are part of this section: [events](../data/calls_events.csv), [actors](../data/calls_actors.csv).
You need the core `nwcommands` and `nwdynam` (see [Install](../install/)); the commands were run with `nwdynam` 1.0.1
and the core 3.0.0. Script and log: [example.do](example.do), [example.log](example.log).

## Put the attributes where `nwdynam` looks for them

Covariate effects read a variable with one row per actor, in the actor order of the network. `nwload ..., xvars`
creates exactly such a dataset (one row per actor, with the actor's label in `_nwnode`), and we then merge the attributes
into it. The merge sorts the rows, so we restore the original order afterwards. This is the one step where it is easy to
go wrong, so check the result:

```stata
. nwload calls, xvars
. gen long actor = real(subinstr(_nwnode, "n", "", 1))
. gen long row = _n
. merge m:1 actor using `actors', keep(master match) nogenerate
. sort row
. list _nwnode actor floor gradetype in 1/4

     +------------------------------------+
     | _nwnode   actor   floor   gradet~e |
     |------------------------------------|
  1. |      n1       1       3          5 |
  2. |      n2       2       5          1 |
  3. |      n3       3       5          2 |
  4. |      n4       4       2          2 |
     +------------------------------------+
```

(The 54 students who appear in the log come first and are labelled `n1`, `n2`, ...; the 30 added isolates follow
and carry their plain number. The variable `actor` recovers the student id from either form.)

## Homophily: do people call others on their own floor?

`same(floor)` is 1 when caller and candidate share the value of `floor`. We fit the baseline model of Tutorial 1,
store it, add the effect, and put the two side by side:

```stata
. nwdynam calls, inertia recip indeg
. estimates store base
. nwdynam calls, inertia recip indeg same(floor)
. estimates store samefloor
. estimates table base samefloor, b(%9.3f) stats(ll N)

--------------------------------------
    Variable |   base      samefloor  
-------------+------------------------
     inertia |     5.366       5.405  
       recip |     1.389       1.365  
       indeg |    -0.174      -0.182  
        same |                -0.170  
-------------+------------------------
          ll |  -695.461    -694.859  
           N |       439         439  
--------------------------------------

. lrtest samefloor base

Likelihood-ratio test
Assumption: base nested within samefloor

 LR chi2(1) =   1.20
Prob > chi2 = 0.2726
```

The coefficient of `same` is -0.17 with a standard error of 0.16 (z = -1.09, not shown above; the full table is in
[example.log](example.log)): callers do not prefer people from their own floor once they have called them before. The
likelihood-ratio test says the same, with p = 0.27, and the other coefficients hardly move. `estimates store`,
`estimates table` and `lrtest` work on `nwdynam` results because the fit leaves `e(b)`, `e(V)` and `e(ll)` behind.
(The test is meaningful for nested models fitted to the same events.)

## Closure: do friends of friends call each other?

`trans` counts the two-paths sender, third person, candidate on the calls so far; `nodetrans` measures how embedded the
candidate is in such structures:

```stata
. nwdynam calls, inertia recip indeg trans
...
       indeg |  -.1632543   .1032653    -1.58   0.114    -.3656505    .0391419
       trans |  -.0506873   .2438788    -0.21   0.835    -.5286809    .4273062
...
. nwdynam calls, inertia recip indeg nodetrans
...
   nodetrans |  -.0274378   .1325023    -0.21   0.836    -.2871376    .2322619
```

Both coefficients are close to zero with wide intervals, and the log likelihood hardly changes (-695.44 against
-695.46). In this log there is no sign of triadic closure beyond repetition and reciprocation. Only the part of a
model that has support in the data is worth keeping.

## Recency and weights

By default `inertia` is 1 if the pair *ever* talked before. Two alternatives change what "before" means:

```stata
. nwdynam calls, inertiawindow(604800) recip indeg
...
Events: 439                            Log likelihood: -687.0629
...
     inertia |   5.180362   .1899864    27.27   0.000     4.807996    5.552729
       recip |   1.708492   .1880702     9.08   0.000     1.339881    2.077103
       indeg |  -.0787753   .0907875    -0.87   0.386    -.2567155    .0991649

. nwdynam calls, weightedinertia recip indeg
...
Events: 439                            Log likelihood: -921.2929
...
     inertia |   .2412274    .020603    11.71   0.000     .2008462    .2816087
```

`inertiawindow(604800)` counts a past call only if it happened within the last 604,800 seconds (one week, the unit
is the unit of your time variable). The log likelihood rises from -695.46 to -687.06 with the same number of
parameters: recent calls predict the next call better than old ones, and reciprocity gets stronger (1.71).
`weightedinertia` counts how many times the pair called instead of whether they did; this model fits clearly worse
(-921.29): how often a pair called is a worse guide to the next call than whether they called. Models with the same number of parameters, as here, can be compared
by their log likelihood directly; the window and the weights are not nested in the plain effect, so there is no
likelihood-ratio test between them.

## A covariate in the rate model

In the rate sub-model a covariate describes the actor who acts, and is called `ego`:

```stata
. nwdynam calls, submodel(rate) indeg outdeg
. estimates store rate0
. nwdynam calls, submodel(rate) indeg outdeg ego(floor)
. estimates store rate1
...
       indeg |   .5167077   .0637887     8.10   0.000     .3916841    .6417312
      outdeg |   .2622773    .028161     9.31   0.000     .2070829    .3174718
         ego |  -.4007556   .0306576   -13.07   0.000    -.4608434   -.3406678

. lrtest rate1 rate0

 LR chi2(1) = 224.58
Prob > chi2 = 0.0000
```

Each floor up multiplies a student's rate of calling by `exp(-0.40)`, about 0.67; students on low floors make the
calls, and the improvement in fit is large. This is an association in these data, not an explanation: floors are
numbered in the data set and who lives where may be related to many things.

## Things to try

- Try `diff(floor)` or `sim(floor)` instead of `same(floor)`; `sim` is exactly `-diff`, so do not enter both.
- Try `alter(floor)` in the choice model: do students call people from certain floors more?
- Try different window lengths for `inertiawindow()` (one day is 86400) and watch the log likelihood.
- Add `recipwindow()` to give reciprocity its own window.

## Next

[Tutorial 3](../tutorial-3-limits/) looks at what the models cannot tell you with little data.
