---
title: "Tutorial 3: Limits and diagnostics"
parent: "nwdynam: DyNAM"
nav_order: 3
description: "What a small event log cannot tell you: a ten-event toy log gives degenerate choice-model estimates, how the standard errors shrink with more events, and the checks nwdynam makes for you."
---

# Tutorial 3: Limits and diagnostics

> **Display of the tables.** The coefficient tables on this page were produced before `nwdynam` 1.9.0. From 1.9.0 on, a table prints the full term names and leaves out the confidence-interval columns when `linesize` is below 100; the option `ci` brings the intervals back (the names are then cut as before), and `noci` leaves them out. The numbers are the same.


**Goal.** Learn to recognize a fit that cannot be trusted, see how much data a DyNAM needs, and know what the
command refuses and what it does not do.

**Data.** First the ten-event toy log from the `nwdynam` help file, then the first 60 and all 631 emails of
[Tutorial 1](../tutorial-1-first-dynam/) (the manufacturing company email data, `nwwebuse manufacturing, nwclear`; Michalski 2020, Harvard Dataverse,
[doi:10.7910/DVN/6Z3CGX](https://doi.org/10.7910/DVN/6Z3CGX), CC0 1.0; Nurek and Michalski 2020, *Applied Sciences* 10(5), 1699;
see [Data sets](../../datasets/)). You need the core `nwcommands` and
`nwdynam` (see [Install](../install/)); the commands were run with `nwdynam` 1.4.0 and the core 3.25.1.
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
------------------------------------------------------------------------------
Note: no usable standard error for inertia indeg.
      These effects are probably not identified (too few events, a perfectly predicted pattern, or effects that are
      linear functions of each other). Do not interpret their estimates; drop or recode the effect.
```

Three things in this output say "do not use": the message *flat region encountered* from the optimizer, coefficients of
-17 and -20 that are about as far from zero as a log odds can sensibly get, and standard errors in the thousands.
With three actors, a sender has only two possible choices; if some effect (here `inertia` and `indeg`)
happens to predict the observed choices perfectly or never, the likelihood has no maximum and the
estimate runs off to infinity. Whenever a coefficient is huge and its standard error is huger, suspect this, and
fit fewer effects or find more events.

## How much data is enough?

A realistic log is bigger in two ways: more actors, which gives each choice many alternatives, and more events.
Take the first 60 emails among the same 154 employees and fit two effects, then do the same with all 631 emails:

```stata
. nwdynam first60, inertia recip
...
Events: 60                             Log likelihood: -267.2627
...
     inertia |   3.412971   .4530379     7.53   0.000     2.525033    4.300909
       recip |   4.147044   .5934088     6.99   0.000     2.983984    5.310104

. nwdynam first631, inertia recip
...
Events: 631                            Log likelihood: -2.37e+03
...
     inertia |   2.420863   .1392213    17.39   0.000     2.147995    2.693732
       recip |   2.639499   .1456453    18.12   0.000      2.35404    2.924959
```

With 60 events the fit converges and both effects are clearly positive, but they are estimated roughly: `recip` is 4.15 with
a standard error of 0.59, an interval from 2.98 to 5.31. With 631 events the standard error falls to 0.15 and the
interval narrows to 2.35 to 2.92. The point estimates moved as well, `inertia` from 3.4 to 2.4 and `recip` from 4.1 to 2.6:
estimates from a short window of a process are estimates of that window, and a short window is also a noisy one.
Running the same model on the first 60, 150, 300 and all 631 events shows the gradual change:

```stata
events   60:  recip =  4.147   s.e. =  0.593
events  150:  recip =  2.329   s.e. =  0.423
events  300:  recip =  1.985   s.e. =  0.229
events  631:  recip =  2.639   s.e. =  0.146
```

The standard error falls steadily, while the point estimate does not settle down monotonically: it dips to 2.0 at 300 events and
rises again to 2.6 when the rest of the log is added. There is no formula for the number of events you need; it depends on how many actors and effects you have and how
often the rarer events (such as replies) occur. Look at the standard errors, not at the number of rows.

More effects need more events. On the 60-event log, adding `indeg` and `trans` gives:

```stata
. nwdynam first60, inertia recip indeg trans
...
     inertia |   2.398553   .5312518     4.51   0.000     1.357319    3.439788
       recip |   4.430292   .5908879     7.50   0.000     3.272173    5.588411
       indeg |   .5318019   .0833205     6.38   0.000     .3684967    .6951071
       trans |   1.389937   1.264229     1.10   0.272    -1.087907    3.867781
```

The standard error of `trans` is 1.26 and its interval runs from -1.09 to 3.87: the first 60 events give this effect little
variation to work with, so it is estimated imprecisely. In a smaller or more regular log the same situation turns into the
symptom of the toy log above, a coefficient with an enormous standard error. The other estimates changed as well
(`inertia` fell from 3.41 to 2.40 and its standard error rose from 0.45 to 0.53), and the coefficient of `indeg` is now very different from its value on the full log (0.11 in Tutorial 1).

## What the command refuses

`nwdynam` checks that an effect makes sense for the sub-model, and stops with an error instead of ignoring it:

```stata
. capture noisily nwdynam first631, submodel(rate) recip
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
- **Covariates are fixed.** An attribute such as the `level` in the hierarchy does not change over the log.
- **No goodness-of-fit or simulation command.** `nwdynam` reports estimates and the log likelihood. Compare models
  with `lrtest` or by the log likelihood, as in [Tutorial 2](../tutorial-2-effects/), and check the sensitivity of the
  conclusions to the window and the set of actors.
- **The risk set is the network's actors.** Actors that never appear in the log must be added as isolates if they
  could have been chosen (Tutorial 1).
- **Compare with the reference if it matters.** For an important result, run the same model in goldfish; the package was
  built to give the same numbers, and the page [nwdynam and goldfish](../r-goldfish/) lists what differs.

## Things to try

- Fit the first 150 and 300 events and watch the standard error of `recip` shrink.
- Fit `nwdynam first60, inertia recip indeg trans` and see whether the extra effects can be estimated.
- Fit the rate model on the first 60 events: `nwdynam first60, submodel(rate)`.

Back to the [overview of nwdynam](../), or on to [nwdynam and goldfish](../r-goldfish/).
