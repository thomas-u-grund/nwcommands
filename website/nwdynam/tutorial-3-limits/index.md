---
title: "Tutorial 3: Limits and diagnostics"
parent: "nwdynam tutorials"
nav_order: 3
description: "What a small event log cannot tell you: a ten-event toy log gives degenerate choice-model estimates, how the standard errors shrink with more events, and the checks nwdynam makes for you."
grand_parent: "nwdynam (DyNAM)"
---

# Tutorial 3: Limits and diagnostics

**Goal.** Learn to recognize a fit that cannot be trusted, see how much data a DyNAM needs, and know what the
command refuses and what it does not do.

**Data.** First the ten-event toy log from the `nwdynam` help file, then the first 60 and all 439 phone calls of
[Tutorial 1](../tutorial-1-first-dynam/) (the data files: [events](../data/calls_events.csv), [actors](../data/calls_actors.csv)). You need the core `nwcommands` and
`nwdynam` (see [Install](../install/)); the commands were run with `nwdynam` 1.0.1 and the core 3.0.0.
Script and log: [example.do](example.do), [example.log](example.log).

## A toy log gives degenerate estimates

The help file shows how to type in a tiny event log. It is good for learning the syntax, not for estimating anything:

```stata
. nwset sender receiver, directed eventtime(t) name(chat)
. nwdynam chat
cannot compute an improvement -- flat region encountered
------------------------------------------------------------
Dynamic Network Actor Model - choice sub-model (MLE)
Network: chat                          Actors: 3
Events: 10                             Log likelihood:   -3.9890
------------------------------------------------------------
------------------------------------------------------------------------------
        chat | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
     inertia |  -16.95435   4803.848    -0.00   0.997    -9432.324    9398.415
       recip |  -.6931435   1.224744    -0.57   0.571    -3.093598    1.707311
       indeg |  -19.78143   13962.73    -0.00   0.999    -27386.22    27346.66
------------------------------------------------------------
```

Three things in this output say "do not use": the message *flat region encountered* from the optimizer, coefficients of
-17 and -20 that are about as far from zero as a log odds can sensibly get, and standard errors in the thousands.
With three actors, a caller has only two possible choices; if some effect (here `inertia` and `indeg`)
happens to predict the observed choices perfectly or never, the likelihood has no maximum and the
estimate runs off to infinity. Whenever a coefficient is huge and its standard error is huger, suspect this, and
fit fewer effects or find more events.

## How much data is enough?

A realistic log is bigger in two ways: more actors, which gives each choice many alternatives, and more events.
Take the first 60 calls among the same 84 students and fit two effects, then do the same with all 439 calls:

```stata
. nwdynam first60, inertia recip
...
Events: 60                             Log likelihood: -106.2032
...
     inertia |   5.923066   .4134493    14.33   0.000      5.11272    6.733412
       recip |   .3139963   .8760043     0.36   0.720    -1.402941    2.030933

. nwdynam first439, inertia recip
...
Events: 439                            Log likelihood: -697.3087
...
     inertia |   5.207598   .1740419    29.92   0.000     4.866482    5.548714
       recip |   1.342851   .1646743     8.15   0.000     1.020096    1.665607
```

With 60 events the fit converges, and `inertia` is estimated well, but `recip` has a standard error of 0.88 around
a coefficient of 0.31: the data cannot distinguish "no reciprocity" from a strong one (the interval runs from -1.4 to
2.0). Reciprocal calls are simply still rare in the first stretch. With 439 events the standard error falls to 0.16
and the effect becomes clear (1.34, the interval 1.02 to 1.67). The point estimate of `inertia` also moved,
from 5.9 to 5.2: estimates from a short window of a process are estimates of that window.
Running the same model on the first 60, 120, 240 and all 439 events shows the gradual change:

```stata
events  60:  recip =  0.314   s.e. =  0.876
events 120:  recip =  1.704   s.e. =  0.466
events 240:  recip =  1.730   s.e. =  0.264
events 439:  recip =  1.343   s.e. =  0.165
```

The standard error falls steadily, and the point estimate settles down only after a few hundred events. There is no formula for the number of events you need; it depends on how many actors and effects you have and how
often the rarer events (such as reciprocal calls) occur. Look at the standard errors, not at the number of rows.

More effects need more events. On the 60-event log, adding `indeg` and `trans` gives:

```stata
. nwdynam first60, inertia recip indeg trans
...
     inertia |   6.252711   1.050194     5.95   0.000     4.194369    8.311054
       recip |   .3090334   .8766641     0.35   0.724    -1.409197    2.027263
       indeg |  -.3645551   1.044636    -0.35   0.727    -2.412005    1.682894
       trans |  -8.170142    588.795    -0.01   0.989    -1162.187    1145.847
```

The standard error of `trans` is 589: the first 60 events give this effect almost no variation to work
with, so it is not identified, the same symptom as in the toy log. The other estimates became less precise as
well (the standard error of `inertia` is now 1.05, against 0.41 without the two new effects).

## What the command refuses

`nwdynam` checks that an effect makes sense for the sub-model, and stops with an error instead of ignoring it:

```stata
. capture noisily nwdynam first439, submodel(rate) recip
inertia/recip/same()/diff()/sim()/alter()/trans/cycle/commonsender/commonreceiver/four/egoalterint()/tie() are choice sub-model effects (submodel(choice)), not available with submodel(rate) - see nwdynam.
invalid syntax
. display "return code: " _rc
return code: 198
```

The reason is structural: in the rate model there is no candidate receiver, so a dyadic effect such as "has the
candidate called me" has nothing to compare. The same kind of message appears for a network that is not an event network
(declare it with `eventtime()`), for a two-mode or undirected network where the sub-model needs another
shape, and for combinations of options that are not supported (see `help nwdynam`).

## What to keep in mind

- **Only the order of events counts.** The default likelihood uses the sequence of events and not the time between them.
  Windows such as `inertiawindow()` do use the clock time. The option `intercept` of the rate model uses the
  elapsed time between events as well; read `help nwdynam` before using it.
- **Effects are computed from the past only.** At each event the statistics use the events before it, never after it.
- **Covariates are fixed.** An attribute such as `floor` does not change over the log.
- **No goodness-of-fit or simulation command.** `nwdynam` reports estimates and the log likelihood. Compare models
  with `lrtest` or by the log likelihood, as in [Tutorial 2](../tutorial-2-effects/), and check the sensitivity of the
  conclusions to the window and the set of actors.
- **The risk set is the network's actors.** Actors that never appear in the log must be added as isolates if they
  could have been chosen (Tutorial 1).
- **Compare with the reference if it matters.** For an important result, run the same model in goldfish; the package was
  built to give the same numbers, and the page [nwdynam and goldfish](../r-goldfish/) lists what differs.

## Things to try

- Fit the first 120 and 240 events and watch the standard error of `recip` shrink.
- Fit `nwdynam first60, inertia recip indeg trans` and see whether the extra effects can be estimated.
- Fit the rate model on the first 60 events: `nwdynam first60, submodel(rate)`.

Back to the [overview of nwdynam](../), or on to [nwdynam and goldfish](../r-goldfish/).
