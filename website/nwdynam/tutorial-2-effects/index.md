---
title: "Tutorial 2: Effects and interpretation"
parent: "nwdynam (DyNAM)"
nav_order: 3
description: "Add covariates, closure effects, recency windows and weights to a DyNAM with nwdynam, and compare models by their log likelihoods."
---

# Tutorial 2: Effects and interpretation

**Goal.** Extend the model of [Tutorial 1](../tutorial-1-first-dynam/) with actor attributes, closure effects and recency, read the new
coefficients, and decide with a likelihood-ratio test which additions earn their place.

**Data.** The same 631 emails among 154 employees of the manufacturing company (see [Tutorial 1](../tutorial-1-first-dynam/); Michalski 2020, Harvard Dataverse,
[doi:10.7910/DVN/6Z3CGX](https://doi.org/10.7910/DVN/6Z3CGX), CC0 1.0; Nurek and Michalski 2020, *Applied Sciences* 10(5), 1699; see [Data sets](../../datasets/)), plus attributes
of the employees from the company file `manufacturing_nodes`: `level`, the number of steps to the CEO in the reporting hierarchy
(0 to 5), and `division`, the branch of the CEO the employee belongs to (twelve values; we turn it into the numeric variable `div`).
Both files are loaded from the web with `nwwebuse`. You need the core `nwcommands` and `nwdynam` (see [Install](../install/)); the commands were run with `nwdynam` 1.4.0
and the core 3.25.1. Script and log: [example.do](example.do), [example.log](example.log).

## Put the attributes where `nwdynam` looks for them

Covariate effects read a variable with one row per actor, in the actor order of the network. `nwload ..., xvars`
creates exactly such a dataset (one row per actor, with the actor's label in `_nwnode`), and we then merge the attributes
into it. The merge sorts the rows, so we restore the original order afterwards. This is the one step where it is easy to
go wrong, so check the result:

```stata
. nwload mail, xvars
. gen long row = _n
. rename _nwnode label
. merge m:1 label using `actors', keep(master match) nogenerate
. sort row
. list label level div in 1/4

     +----------------------+
     | label   level    div |
     |----------------------|
  1. |  E102       2    E36 |
  2. |  E103       2    E85 |
  3. |  E104       1   E104 |
  4. |  E105       2   E104 |
     +----------------------+

. list label level div in 130/133

     +---------------------+
     | label   level   div |
     |---------------------|
130. |   E28       4   E69 |
131. |   E29       3   E69 |
132. |   E31       3   E69 |
133. |   E32       4   E69 |
     +---------------------+
```

(The 102 employees who appear in the log come first, then the 52 added isolates, each group in label order. All 154 rows
are matched. `div` is a numeric variable that carries the division as its value label, which is why `E36` is printed.)

## Homophily: do people write to others in their own division?

`same(div)` is 1 when sender and candidate belong to the same division. We fit the baseline model of Tutorial 1,
store it, add the effect, and put the two side by side:

```stata
. nwdynam mail, inertia recip indeg
. estimates store base
. nwdynam mail, inertia recip indeg same(div)
. estimates store samediv
. estimates table base samediv, b(%9.3f) stats(ll N)

--------------------------------------
    Variable |   base       samediv   
-------------+------------------------
     inertia |     1.765       1.713  
       recip |     2.922       2.870  
       indeg |     0.110       0.114  
        same |                 0.595  
-------------+------------------------
          ll | -2307.397   -2290.415  
           N |       631         631  
--------------------------------------

. lrtest samediv base

Likelihood-ratio test
Assumption: base nested within samediv

 LR chi2(1) =  33.96
Prob > chi2 = 0.0000
```

The coefficient of `same` is 0.60 with a standard error of 0.10 (z = 5.81, not shown above; the full table is in
[example.log](example.log)): an employee is `exp(0.60)`, about 1.8 times more likely to write to a colleague of the own division, over and
above repetition and reciprocation. The likelihood-ratio test agrees (chi-squared 33.96 with one degree of freedom, p < 0.001), and the other coefficients hardly move. `estimates store`,
`estimates table` and `lrtest` work on `nwdynam` results because the fit leaves `e(b)`, `e(V)` and `e(ll)` behind.
(The test is meaningful for nested models fitted to the same events.)

## Closure: do friends of friends write to each other?

`trans` counts the two-paths sender, third person, candidate on the emails so far; `nodetrans` measures how embedded the
candidate is in such structures:

```stata
. nwdynam mail, inertia recip indeg trans
...
       indeg |   .0947766   .0091763    10.33   0.000     .0767914    .1127618
       trans |    .502668   .1032237     4.87   0.000     .3003533    .7049827
...
. display "log likelihood: " %9.2f e(ll)
log likelihood:  -2296.49

. nwdynam mail, inertia recip indeg nodetrans
...
   nodetrans |   .0428565   .0230401     1.86   0.063    -.0023012    .0880142
...
. display "log likelihood: " %9.2f e(ll)
log likelihood:  -2305.71
```

`trans` is clearly positive (0.50, z = 4.87) and raises the log likelihood from -2307.40 to -2296.49: a colleague who is
reachable through a third person is more likely to be written to, beyond repetition and reciprocation, a sign of triadic closure. `nodetrans` is
small, with an interval that includes zero (p = 0.063), and the log likelihood hardly changes (-2305.71). Only the part of a
model that has support in the data is worth keeping.

## Recency and weights

By default `inertia` is 1 if the pair *ever* wrote before. Two alternatives change what "before" means:

```stata
. nwdynam mail, inertiawindow(0.5) recip indeg
...
     inertia |   1.651971   .1348708    12.25   0.000     1.387629    1.916312
       recip |   3.225301    .126903    25.42   0.000     2.976576    3.474027
       indeg |   .1241474   .0077913    15.93   0.000     .1088768     .139418
. display "log likelihood: " %9.2f e(ll)
log likelihood:  -2312.85

. nwdynam mail, weightedinertia recip indeg
...
     inertia |   .4343398   .0509665     8.52   0.000     .3344473    .5342323
       recip |   3.499136   .1203136    29.08   0.000     3.263326    3.734946
       indeg |   .1305183   .0076684    17.02   0.000     .1154886    .1455481
. display "log likelihood: " %9.2f e(ll)
log likelihood:  -2350.15
```

`inertiawindow(0.5)` counts a past email only if it was sent within the last half day (the unit
is the unit of your time variable, here days). The log likelihood falls from -2307.40 to -2312.85 with the same number of
parameters: in these days a pair that wrote earlier is as likely to write again whether the earlier email was recent or not, so cutting off
the old emails loses information; reciprocity gets stronger (3.23).
`weightedinertia` counts how many times the pair wrote instead of whether they did; this model fits clearly worse
(-2350.15): how often a pair wrote is a worse guide to the next email than whether they wrote. Models with the same number of parameters, as here, can be compared
by their log likelihood directly; the window and the weights are not nested in the plain effect, so there is no
likelihood-ratio test between them.

## A covariate in the rate model

In the rate sub-model a covariate describes the actor who acts, and is called `ego`:

```stata
. nwdynam mail, submodel(rate) indeg outdeg
. estimates store rate0
. nwdynam mail, submodel(rate) indeg outdeg ego(level)
. estimates store rate1
...
       indeg |   .0317144   .0119843     2.65   0.008     .0082255    .0552032
      outdeg |    .289142   .0177914    16.25   0.000     .2542714    .3240126
         ego |  -.1205667   .0423815    -2.84   0.004     -.203633   -.0375005

. lrtest rate1 rate0

 LR chi2(1) =   8.12
Prob > chi2 = 0.0044
```

Each step down the hierarchy multiplies an employee's rate of writing by `exp(-0.12)`, about 0.89: people closer to the top
send emails sooner, and the improvement in fit is moderate (chi-squared 8.12, p = 0.004). This is an association in these data, not an
explanation: the level in the hierarchy is related to the tasks, the workload and the number of colleagues of an employee.

## Things to try

- Try `diff(level)` or `sim(level)` instead of `same(div)`; `sim` is exactly `-diff`, so do not enter both.
- Try `alter(level)` in the choice model: do employees write more often to people high up in the hierarchy?
- Try different window lengths for `inertiawindow()` (one day is 1) and watch the log likelihood.
- Add `recipwindow()` to give reciprocity its own window.

## Next

[Tutorial 3](../tutorial-3-limits/) looks at what the models cannot tell you with little data.
