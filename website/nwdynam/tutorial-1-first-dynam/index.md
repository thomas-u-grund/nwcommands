---
title: "Tutorial 1: A first DyNAM"
parent: "nwdynam: DyNAM"
nav_order: 1
description: "Fit a first dynamic network actor model with nwdynam to a log of emails: declare the events, fit the choice and the rate sub-model, and read the tables."
---

# Tutorial 1: A first DyNAM on an email log

> **Display of the tables.** The coefficient tables on this page were produced before `nwdynam` 1.9.0. From 1.9.0 on, a table prints the full term names and leaves out the confidence-interval columns when `linesize` is below 100; the option `ci` brings the intervals back (the names are then cut as before), and `noci` leaves them out. The numbers are the same.


**Goal.** Declare a stream of timed events, fit the two parts of a dynamic network actor model (DyNAM),
and understand what each part estimates.

**Data.** The email metadata of a manufacturing company, the example data `manufacturing` of the core package
(Michalski 2020, Harvard Dataverse, [doi:10.7910/DVN/6Z3CGX](https://doi.org/10.7910/DVN/6Z3CGX), CC0 1.0; see also Nurek and
Michalski 2020, *Applied Sciences* 10(5), 1699; the page [Data sets](../../datasets/) says more). Each row is one email with the
sender, the receiver and the time it was sent, in days since 1 January 2010. We use the first part of the log, 631 emails
sent on 4 and 5 January 2010 (`keep if t < 5`), among 154 employees. The data are loaded from the web with
`nwwebuse manufacturing, nwclear`; no file is needed. You need the core `nwcommands` and
the `nwdynam` package (see [Install](../install/)); the commands were run with `nwdynam` 1.4.0 and the core
3.25.1. The complete script and log are in [example.do](example.do) and [example.log](example.log).
For a short, general introduction to event models, see
[Intro to Longitudinal Network Models](../../tutorials/19-intro-longitudinal-models/).

## What a DyNAM does, in four sentences

A relational event is a single act from one actor to another at a known moment. Between two events nothing
else is observed, so the model asks, event by event: given everything that has happened so far, which
actor was going to act next (the **rate** sub-model), and whom did that actor pick (the **choice**
sub-model)? Both sub-models weigh effects, such as "a person writes to someone they wrote to before", and
`nwdynam` estimates how strong each effect is. In the form fitted here only the *order* of the events enters the
likelihood, not the length of the gaps between them.

## Look at the events

```stata
. nwwebuse manufacturing, nwclear
. keep if t < 5
. list in 1/5

     +------------------------------+
     | sender   receiver          t |
     |------------------------------|
  1. |    E39        E81   3.235255 |
  2. |    E39        E81   3.235822 |
  3. |   E112       E136    3.25566 |
  4. |   E112        E60    3.25728 |
  5. |   E112        E57   3.257963 |
     +------------------------------+

. count
  631

. display "span in days: " %5.2f t[_N] - t[1]
span in days:  1.75
```

Each row is one email. The data must be sorted by time (they are here). Many emails repeat the same pair:

```stata
. duplicates report sender receiver

Duplicates in terms of sender receiver

--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |          235             0
        2 |          160            80
        3 |           75            50
        4 |           76            57
        5 |           55            44
        6 |            6             5
        8 |           24            21
--------------------------------------
```

Of the 374 pairs that appear, 235 appear exactly once, while three pairs account for eight emails each.
This repetition is what the effect `inertia` below picks up.

## Declare the events

The emails name 102 of the 154 employees of the company file. The other 52 neither send nor receive an email in these
days, but they were there and could have been written to, so they belong to the set of possible choices. A list of events can only
create the actors it mentions, so we add the missing ones as isolates with `nwaddnodes`:

```stata
. nwset sender receiver, directed eventtime(t) name(mail)
. nwaddnodes mail, nodenames(`miss')
```

(`miss` is the list of the labels in the company file, `manufacturing_nodes`, that do not occur in the log; the lines that
build it are in [example.do](example.do).) The option `eventtime()` tells `nwset` that each row is an event with a
time, not a lasting tie. Leaving the 52 actors out would change the estimates, because it shrinks the
set of people a sender can choose.

## The choice sub-model

`nwdynam` with no options fits the choice sub-model with its three standard effects:

```stata
. nwdynam mail
------------------------------------------------------------
Dynamic Network Actor Model - choice sub-model (MLE)
Network: mail                          Actors: 154
Events: 631                            Log likelihood: -2.31e+03
Note: 3 events share a time point with an earlier event; events with equal times
are simultaneous (as in goldfish).
------------------------------------------------------------
------------------------------------------------------------------------------
        mail | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
     inertia |   1.764848   .1422702    12.40   0.000     1.486004    2.043693
       recip |   2.922411   .1401072    20.86   0.000     2.647806    3.197016
       indeg |   .1096219   .0083143    13.18   0.000     .0933262    .1259177
------------------------------------------------------------------------------

. display "log likelihood: " %9.2f e(ll)
log likelihood:  -2307.40
```

The note says that three emails were sent at exactly the same moment as an earlier one; such events are treated as simultaneous.

**How to read it.** At every email, the sender is known and the model compares everyone the sender could have
written to, a conditional logit. A coefficient is the change in the log odds of being chosen when the effect increases by one
unit:

- `inertia` (1.76) is 1 if the sender has written to this person before. A person written to earlier is `exp(1.76)`, about 5.8
  times more likely to be written to again than an otherwise similar person never written to. Email contacts are
  habitual.
- `recip` (2.92) is 1 if the candidate has written to the sender before. Answering an email multiplies the odds by
  `exp(2.92)`, about 18.6.
- `indeg` (0.11) is the number of different people who have written to the candidate. Each additional person multiplies the
  odds by `exp(0.11)`, about 1.12: people who receive mail from many colleagues are more likely to receive more, even
  once repetition and reciprocation are accounted for.

The header gives the number of events, the number of actors and the log likelihood, which is the number you
compare between models (Tutorial 2).

## The rate sub-model

The same events, now asking *who* writes next:

```stata
. nwdynam mail, submodel(rate)
------------------------------------------------------------
Dynamic Network Actor Model - rate sub-model, no intercept (MLE)
Network: mail                          Actors: 154
Events: 631                            Log likelihood: -2.99e+03
Note: 3 events share a time point with an earlier event; events with equal times
are simultaneous (as in goldfish).
------------------------------------------------------------
------------------------------------------------------------------------------
        mail | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       indeg |    .032447   .0121149     2.68   0.007     .0087021    .0561918
      outdeg |   .2981679   .0176337    16.91   0.000     .2636064    .3327294
------------------------------------------------------------------------------
```

Here every one of the 154 actors is a candidate for the next email, and the effects describe the sender:

- `indeg` (0.03): the more different people have written to someone, the sooner that person is likely to be the
  next sender, but the effect is weak (z = 2.68).
- `outdeg` (0.30): the more different people someone has written to, the more likely they write again. Active
  senders stay active.

The effects mean different things in the two sub-models: in the choice model `indeg` and `outdeg` are
properties of the *candidate being chosen*, in the rate model of the *actor who acts*. That is why the
two tables report different numbers under the same name.

The stored results hold everything for later use:

```stata
. display "sub-model: " e(submodel) ", effects: " e(effects)
sub-model: rate, effects: indeg outdeg

. display "events: " e(N) ", actors: " e(nodes) ", log likelihood: " %9.2f e(ll)
events: 631, actors: 154, log likelihood:  -2986.28
```

## A check against goldfish

For the choice model above, goldfish 1.6.12 gives `inertia` 1.76485 (s.e. 0.14227), `recip` 2.92238
(0.14011), `indeg` 0.10962 (0.00831) and a log likelihood of -2307.40 on the same events, the same 154 actors
and the same model. For the rate model it gives `indeg` 0.03246 (0.01211), `outdeg` 0.29812 (0.01763) and a log likelihood of
-2986.28. The numbers agree to the digits shown, apart from the last digit of `recip` (2.92241 against 2.92238), which is
within the tolerance of the two optimizers.

## Things to try

- Fit only `inertia`: `nwdynam mail, inertia`. Asking for any effect restricts the model to the effects named.
- Fit the rate model with `outdeg` alone and see how the coefficient changes.
- Leave out the 52 isolates (skip `nwaddnodes`) and compare the coefficients with the table above.

## Next

[Tutorial 2](../tutorial-2-effects/) adds covariates and closure effects and compares models.
Back to the [overview of nwdynam](../).
