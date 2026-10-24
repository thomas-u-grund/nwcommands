---
title: "Tutorial 1: A first DyNAM"
parent: "nwdynam tutorials"
nav_order: 1
description: "Fit a first dynamic network actor model with nwdynam to a log of phone calls: declare the events, fit the choice and the rate sub-model, and read the tables."
grand_parent: "nwdynam (DyNAM)"
---

# Tutorial 1: A first DyNAM on a phone-call log

**Goal.** Declare a stream of timed events, fit the two parts of a dynamic network actor model (DyNAM),
and understand what each part estimates.

**Data.** The phone calls among 84 university students that the R package goldfish ships as the
`calls` data of its Social Evolution example (data from a study of MIT students, distributed with goldfish): 439 calls over about six weeks in 2008, each with the
caller, the person called and the time (in seconds) of the call. The two data files ([events](../data/calls_events.csv), [actors](../data/calls_actors.csv)) are part of this section, so you can run everything below. You need the core `nwcommands` and
the `nwdynam` package (see [Install](../install/)); the commands were run with `nwdynam` 1.0.1 and the core
3.0.0. The complete script and log are in [example.do](example.do) and [example.log](example.log).
For a short, general introduction to event models, see
[Intro to Longitudinal Network Models](../../tutorials/10-intro-longitudinal-models/).

## What a DyNAM does, in four sentences

A relational event is a single act from one actor to another at a known moment. Between two events nothing
else is observed, so the model asks, event by event: given everything that has happened so far, which
actor was going to act next (the **rate** sub-model), and whom did that actor pick (the **choice**
sub-model)? Both sub-models weigh effects, such as "a person calls someone they called before", and
`nwdynam` estimates how strong each effect is. In the form fitted here only the *order* of the events enters the
likelihood, not the length of the gaps between them.

## Look at the events

```stata
. import delimited "../data/calls_events.csv", clear
. list in 1/5

     +--------------------------------+
     | sender   receiver    eventtime |
     |--------------------------------|
  1. |     72         50   1220733470 |
  2. |     43         51   1221102974 |
  3. |     43         51   1221784293 |
  4. |     43         22   1221785882 |
  5. |     43         55   1221787264 |
     +--------------------------------+

. count
  439

. display "span in days: " (eventtime[_N] - eventtime[1]) / 86400
span in days: 42.125949
```

Each row is one call. The data must be sorted by time (they are here). Many calls repeat the same pair:

```stata
. duplicates report sender receiver

Duplicates in terms of sender receiver

--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |           36             0
        2 |           26            13
        ...
       64 |           64            63
      115 |          115           114
--------------------------------------
```

Of the pairs that appear, 36 appear exactly once, while one pair accounts for 115 calls.
This strong repetition is what the effect `inertia` below picks up.

## Declare the events

The calls name 54 of the 84 students. The other 30 never make or receive a call, but they were
there and could have been called, so they belong to the set of possible choices. A list of events can only
create the actors it mentions, so we add the missing ones as isolates with `nwaddnodes`:

```stata
. nwset sender receiver, eventtime(eventtime) name(calls)
. nwaddnodes calls, nodenames(`miss')
```

(`miss` is the list of the ids 1 to 84 that do not occur in the log; the lines that build it are in
[example.do](example.do).) The option `eventtime()` tells `nwset` that each row is an event with a
time, not a lasting tie. Leaving the 30 actors out would change the estimates, because it shrinks the
set of people a caller can choose.

## The choice sub-model

`nwdynam` with no options fits the choice sub-model with its three standard effects:

```stata
. nwdynam calls
------------------------------------------------------------
Dynamic Network Actor Model - choice sub-model (MLE)
Network: calls                         Actors: 84
Events: 439                            Log likelihood: -695.4608
------------------------------------------------------------
------------------------------------------------------------------------------
       calls | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
     inertia |   5.365619   .1937551    27.69   0.000     4.985866    5.745372
       recip |   1.389441    .167288     8.31   0.000     1.061562    1.717319
       indeg |  -.1735184   .0909708    -1.91   0.056    -.3518179    .0047811
------------------------------------------------------------------------------
```

**How to read it.** At every call, the caller is known and the model compares everyone the caller could have
called, a conditional logit. A coefficient is the change in the log odds of being chosen when the effect increases by one
unit:

- `inertia` (5.37) is 1 if the caller has called this person before. A person called earlier is `exp(5.37)`, about 200
  times more likely to be called again than an otherwise similar person never called. Phone calls are
  extremely habitual.
- `recip` (1.39) is 1 if the candidate has called the caller before. Returning a call multiplies the odds by
  `exp(1.39)`, about 4.0.
- `indeg` (-0.17) is the number of different people who have called the candidate. Its coefficient is small and
  the 95% interval touches zero (p = 0.056): there is no clear evidence that popular people are chosen more often
  once repetition and reciprocation are accounted for.

The header gives the number of events, the number of actors and the log likelihood, which is the number you
compare between models (Tutorial 2).

## The rate sub-model

The same events, now asking *who* calls next:

```stata
. nwdynam calls, submodel(rate)
------------------------------------------------------------
Dynamic Network Actor Model - rate sub-model, no intercept (MLE)
Network: calls                         Actors: 84
Events: 439                            Log likelihood: -1.75e+03
------------------------------------------------------------
------------------------------------------------------------------------------
       calls | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       indeg |   .5514472   .0663444     8.31   0.000     .4214147    .6814798
      outdeg |   .2637836    .028386     9.29   0.000      .208148    .3194193
------------------------------------------------------------------------------
```

Here every one of the 84 actors is a candidate for the next call, and the effects describe the caller:

- `indeg` (0.55): the more different people have called someone, the sooner that person is likely to be the
  next caller. Those who are called also call.
- `outdeg` (0.26): the more different people someone has called, the more likely they call again.

The effects mean different things in the two sub-models: in the choice model `indeg` and `outdeg` are
properties of the *candidate being chosen*, in the rate model of the *actor who acts*. That is why the
two tables report different numbers under the same name.

The stored results hold everything for later use:

```stata
. display "sub-model: " e(submodel) ", effects: " e(effects)
sub-model: rate, effects: indeg outdeg

. display "events: " e(N) ", actors: " e(nodes) ", log likelihood: " %9.2f e(ll)
events: 439, actors: 84, log likelihood:  -1750.91
```

## A check against goldfish

For the choice model above, goldfish 1.6.12 gives `inertia` 5.36556 (s.e. 0.19375), `recip` 1.38944
(0.16729), `indeg` -0.17353 (0.09097) and a log likelihood of -695.46 on the same data, the same 84 actors
and the same model. The numbers agree to the digits shown.

## Things to try

- Fit only `inertia`: `nwdynam calls, inertia`. Asking for any effect restricts the model to the effects named.
- Fit the rate model with `outdeg` alone and see how the coefficient changes.
- Leave out the 30 isolates (skip `nwaddnodes`) and compare the coefficients with the table above.

## Next

[Tutorial 2](../tutorial-2-effects/) adds covariates and closure effects and compares models.
Back to the [overview of nwdynam](../).
