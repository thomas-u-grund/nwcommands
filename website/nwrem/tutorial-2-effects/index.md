---
title: "Tutorial 2: Effects and interpretation"
parent: "nwrem (REM)"
nav_order: 3
description: "Add actor covariates, a pair covariate and recency effects to a relational event model with nwrem, and read what each one says."
---

# Tutorial 2: Covariates, pairs and recency

**Goal.** Extend the model of [Tutorial 1](../tutorial-1-first-rem/) with the floor on which a student lives (an attribute of one actor),
whether two students share a floor (an attribute of a pair), and with recency instead of frequency.

**Data.** The same 439 phone calls among 84 students, plus the attribute `floor` (1 to 9) of each student; both data files are available: [events](../data/calls_events.csv), [actors](../data/calls_actors.csv). You need the core `nwcommands` and `nwrem` (see [Install](../install/)); the commands were run with `nwrem`
1.0.1 and the core 3.0.0. Script and log: [example.do](example.do), [example.log](example.log).

## Where the covariates come from

The three kinds of covariate effects read their data from different places:

| Option | What it is | Where it is read from |
|---|---|---|
| `covsnd(var)` | an attribute of the sender | a variable with one row per actor |
| `covrec(var)` | an attribute of the receiver | a variable with one row per actor |
| `covint(var)` | the same attribute of sender and receiver, one shared coefficient | a variable with one row per actor |
| `covevent(net)` | a value for each ordered pair | another network with the same actors |

For the first three, `nwload calls, xvars` gives a dataset with one row per actor, in the actor order of the network; we merge the attribute into
it and restore the order, and check the result:

```stata
. nwload calls, xvars
. gen long actor = real(subinstr(_nwnode, "n", "", 1))
. gen long row = _n
. merge m:1 actor using `actors', keep(master match) nogenerate
. sort row
. list _nwnode actor floor in 1/4
...
```

For `covevent()` we make a second network, `sameflr`, with a tie from `i` to `j` if the two live on the same floor. Mata builds
the matrix and `nwset` declares it:

```stata
. mata:
: F = st_data(., "floor")
: n = rows(F)
: S = J(n, n, 0)
: for (i = 1; i <= n; i++) {
>     for (j = 1; j <= n; j++) S[i, j] = (i != j) & (F[i] == F[j])
> }
: end
. nwset, mat(S) name(sameflr) directed
. nwset
(2 networks)
--------------------
      calls
      sameflr
```

The pair covariate is read as given: an ordered pair has the value in its own cell, and nothing is symmetrised. Here
the relation is symmetric, so the matrix is as well.

## Actor covariates

Start from the model of the pair's history and add the floor of the sender and of the receiver:

```stata
. nwrem calls, frpsndsnd frrecsnd
. estimates store hist
. nwrem calls, frpsndsnd frrecsnd covsnd(floor) covrec(floor)
. estimates store floors
...
Events: 439                            Log likelihood: -2.20e+03
...
   frpsndsnd |   6.134409   .1464316    41.89   0.000     5.847408     6.42141
    frrecsnd |   1.562276   .1440921    10.84   0.000     1.279861    1.844692
covsnd_floor |  -.2432981   .0274013    -8.88   0.000    -.2970036   -.1895926
covrec_floor |  -.1703417   .0256821    -6.63   0.000    -.2206777   -.1200057
```

Both coefficients are negative and clear: for each floor higher, a person's odds of being the caller fall by a factor of
`exp(-0.24)`, about 0.78, and the odds of being the person called by `exp(-0.17)`, about 0.84. People on low floors
call more and are called more. The reciprocity effect dropped from 2.03 to 1.56 once the floor was in the model, so part of the
apparent reciprocity is shared with the floor effects.

## A pair covariate

```stata
. nwrem calls, frpsndsnd frrecsnd covevent(sameflr)
...
covevent_sameflr |  -.5312484   .1219874    -4.35   0.000    -.7703393   -.2921574
```

Sharing a floor *lowers* the odds that a given pair makes a call, by `exp(-0.53)`, about 0.59, once the history of the pair is
in the model. A plausible reading is that people on the same floor talk in person and use the phone for others; the model
only says that this is the pattern in the data.

## Recency instead of frequency

`frpsndsnd` and `frrecsnd` ask how large a *share* of the sender's contacts went to or came from this person.
`rsndsnd` and `rrecsnd` ask how *recently*: they are the reciprocal of the rank of this person among the sender's earlier
partners (most recent partner = rank 1, never contacted = 0). Only the order counts, not how often.

```stata
. nwrem calls, rsndsnd rrecsnd
. estimates store recent
. nwrem calls, frpsndsnd frrecsnd rsndsnd rrecsnd
. estimates store both
```

## Putting the models side by side

```stata
. estimates table hist floors samefloor recent both, b(%9.3f) stats(ll N)
--------------------------------------------------------------------------
    Variable |   hist       floors     samefloor    recent       both     
-------------+------------------------------------------------------------
   frpsndsnd |     6.254       6.134       6.390                   1.193  
    frrecsnd |     2.035       1.562       2.014                   0.757  
covsnd_floor |                -0.243                                      
covrec_floor |                -0.170                                      
covevent_s~r |                            -0.531                          
     rsndsnd |                                         6.417       5.475  
     rrecsnd |                                         1.600       0.931  
-------------+------------------------------------------------------------
          ll |  -2274.048   -2197.731   -2263.785   -2122.016   -2094.776  
           N |       439         439         439         439         439  
--------------------------------------------------------------------------

. lrtest floors hist
 LR chi2(2) = 152.63
Prob > chi2 = 0.0000
. lrtest both hist
 LR chi2(2) = 358.54
Prob > chi2 = 0.0000
```

Reading across the log likelihoods (higher, i.e. less negative, is better):

- Adding the floors improves on the history model by 76 log-likelihood units (LR test 152.6 on 2 degrees of freedom).
- Recency (-2122.0) fits clearly better than frequency (-2274.0) with the same number of parameters. Whom you called *last* tells more than whom
  you called most.
- Using both gives the best fit (-2094.8), and the recency effect of the sender keeps most of its size (6.42 to 5.48) while the frequency effects shrink (6.25 to 1.19
  and 2.03 to 0.76). Recency does most of the work.

The `lrtest` between nested models is the formal comparison; between the frequency and the recency model, which are not nested, only the
log likelihoods can be compared.

## Things to try

- Use `covint(floor)` in place of `covsnd` and `covrec`: it forces one coefficient for both roles.
- Build `sameflr` with another attribute, such as `gradetype`, and use it in `covevent()`.
- Fit `rsndsnd` and `rrecsnd` together with `covevent(sameflr)`.

## Next

[Tutorial 3](../tutorial-3-comparing/) compares specifications more systematically and looks at the limits of the package.
Back to the [overview of nwrem](../).
