---
title: "REM: A first relational event model"
parent: "nwrem (REM)"
nav_order: 2
description: "Fit a first relational event model with nwrem to a log of phone calls: declare the event sequence, fit degree and inertia effects, and read the coefficient table."
---

# Tutorial 1: A first relational event model on a phone-call log

**Goal.** Declare a sequence of timed events, fit a relational event model (REM) with `nwrem`, and understand what the coefficients
say.

**Data.** The phone calls among 84 university students that the R package goldfish ships as the `calls` data of its Social
Evolution example (data from a study of MIT students, distributed with goldfish): 439 calls over about six weeks in 2008, each with the caller, the person called and the time (in seconds)
of the call. The two data files ([events](../data/calls_events.csv), [actors](../data/calls_actors.csv)) are part of this section. You need the core `nwcommands` and the `nwrem`
package (see [Install](../install/)); the commands were run with `nwrem` 1.0.1 and the core 3.0.0. The complete script and log are in
[example.do](example.do) and [example.log](example.log). For a general introduction to event models, see
[Intro to Longitudinal Network Models](../../tutorials/10-intro-longitudinal-models/).

## What a REM does, in four sentences

A relational event is one act from a sender to a receiver at a known moment (a call, an e-mail, a hand-shake). A REM
(Butts 2008) looks at the events one after the other and asks at each moment: among all the ordered pairs of actors that could have
interacted next, why was it *this* pair? Effects such as "the sender has been very active so far" or "the sender has called this
receiver before" raise or lower the chance of a pair, and `nwrem` estimates by how much. Only the order of the events enters the
likelihood (it is a partial likelihood, as in a Cox model), so there is no intercept to estimate.

## Look at the events and declare them

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

The log names 54 of the 84 students. The other 30 neither call nor are called, but they are possible callers and receivers,
so they belong to the set of pairs the model compares. A list of events creates only the actors it mentions, so we add the
missing ones as isolates with `nwaddnodes` (the lines that build the list `miss` are in [example.do](example.do)):

```stata
. nwset sender receiver, directed eventtime(eventtime) name(calls)
. nwaddnodes calls, nodenames(`miss')
```

The option `eventtime()` says that each row is an event with a time and not a lasting tie. There are now 84 x 83 = 6,972 ordered pairs
that could have happened at any moment.

## Model 1: activity

`nodsnd` is the sender's *normalized out-degree*: the share of all earlier events in which this actor was the sender. `nidrec` is the
receiver's normalized in-degree: the share of earlier events in which this actor was the receiver.

```stata
. nwrem calls, nodsnd nidrec
------------------------------------------------------------
Relational event model (ordinal partial likelihood, MLE)
Network: calls                         Actors: 84
Events: 439                            Log likelihood: -3.12e+03
------------------------------------------------------------
------------------------------------------------------------------------------
       calls | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
      nodsnd |   10.57478   .3530761    29.95   0.000     9.882761    11.26679
      nidrec |   11.32606   .3391393    33.40   0.000     10.66136    11.99077
------------------------------------------------------------------------------
```

**How to read it.** The effects are shares between 0 and 1, so the coefficients are large. A sender whose share of earlier
calls is 0.1 higher has `exp(1.06)`, about 2.9 times the odds of making the next call. A receiver whose share of earlier receipts
is 0.1 higher is about `exp(1.13)`, 3.1 times as likely to be the one called. People who have been busy stay busy, and people
who have been called get called.

## Model 2: history of the pair

`frpsndsnd` ("inertia") is the share of the sender's own earlier calls that went to *this* receiver. `frrecsnd`
("reciprocity of receipt") is the share of the sender's earlier receipts that came from this receiver.

```stata
. nwrem calls, frpsndsnd frrecsnd
...
Events: 439                            Log likelihood: -2.27e+03
...
   frpsndsnd |   6.254331   .1453025    43.04   0.000     5.969544    6.539119
    frrecsnd |   2.034655   .1400245    14.53   0.000     1.760212    2.309098

. display "events: " e(N) ", actors: " e(nodes) ", log likelihood: " %9.2f e(ll)
events: 439, actors: 84, log likelihood:  -2274.05
. display "effect of inertia on the odds: x" %6.1f exp(_b[frpsndsnd] * 0.1) " per 10 percentage points"
effect of inertia on the odds: x   1.9 per 10 percentage points
```

If another 10 percentage points of the sender's calls had gone to a given person, the odds that the next call goes
to that person again are multiplied by 1.9. Calling back someone who called you earlier also increases the odds (2.03 on the log scale
for a sender whose receipts all came from this person). This model fits far better than the activity model: the log likelihood
rises from about -3,120 to -2,274 (the log likelihood is printed in rounded form in the header; `e(ll)` holds the exact value).
How people behave toward *each other* explains the calls much better than how active they are in general.

## Both together

```stata
. nwrem calls, nodsnd nidrec frpsndsnd frrecsnd
...
Events: 439                            Log likelihood: -2.12e+03
...
      nodsnd |   5.392451   .4376142    12.32   0.000     4.534743     6.25016
      nidrec |   .9485414   .5809882     1.63   0.103    -.1901745    2.087257
   frpsndsnd |   5.782841   .1612638    35.86   0.000      5.46677    6.098913
    frrecsnd |   1.640027   .1538415    10.66   0.000     1.338504    1.941551
```

Once the history of the pair is in the model, the activity effects shrink: `nodsnd` halves (5.4) and `nidrec` falls to 0.95 and
is no longer distinguishable from zero (the interval runs from -0.19 to 2.09). Much of what looked like "popular people get called" in
Model 1 was people calling those they always call. This is the usual reason for fitting several effects together and not one at a time.

## A word on precision

The degree-type effects are running shares that move closer to one another (towards 1/84) as the log grows. Therefore their
estimates can stay noisy, and several of them in one model can be nearly collinear, so that different starting values give visibly different
individual coefficients with about the same log likelihood. If it matters, check the stability of a coefficient under the other
specifications, as in [Tutorial 3](../tutorial-3-comparing/).

## Things to try

- Fit `nwrem calls, frpsndsnd` alone, and then `nwrem calls, frrecsnd` alone.
- Replace the shares by recency: `nwrem calls, rsndsnd rrecsnd` asks whether the *most recent* partners are the ones returned to.
- Add `seed(1)` to any call; it only decides which optimizer restart is tried first and never changes a converged result.

## Next

[Tutorial 2](../tutorial-2-effects/) adds actor and pair covariates and the recency effects.
Back to the [overview of nwrem](../).
