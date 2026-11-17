---
title: "Tutorial 1: A first relational event model"
parent: "nwrem (REM)"
nav_order: 2
description: "Fit a first relational event model with nwrem to an e-mail log: declare the event sequence, fit degree and inertia effects, and read the coefficient table."
---

# Tutorial 1: A first relational event model on an e-mail log

> **Display of the tables.** The coefficient tables on this page were produced before `nwrem` 1.5.0. From 1.5.0 on, a table prints the full term names and leaves out the confidence-interval columns when `linesize` is below 100; the option `ci` brings the intervals back (the names are then cut as before), and `noci` leaves them out. The numbers are the same.


**Goal.** Declare a sequence of timed events, fit a relational event model (REM) with `nwrem`, and understand what the coefficients
say.

**Data.** The e-mail metadata of a manufacturing company: 50,233 e-mails among 144 employees between January and September 2010,
each with the sender, the receiver and the time (in days since 1 January 2010); no content. Source: Michalski, R. (2020), "Manufacturing
company email metadata and corporate hierarchy", Harvard Dataverse,
[doi:10.7910/DVN/6Z3CGX](https://doi.org/10.7910/DVN/6Z3CGX) (CC0 1.0), described in Nurek, M. and Michalski, R. (2020), *Applied
Sciences* 10(5), 1699. The data are loaded from the website with `nwwebuse manufacturing`; see the [data sets page](../../datasets/) for the
file and its description. To keep the fits quick we use the e-mails of the first five days only: 631 e-mails. You need the core `nwcommands`
and the `nwrem` package (see [Install](../install/)); the commands were run with `nwrem` 1.1.2 and the core 3.25.1. The complete
script and log are in [example.do](example.do) and [example.log](example.log). For a general introduction to event models, see
[Intro to Longitudinal Network Models](../../tutorials/19-intro-longitudinal-models/).

## What a REM does, in four sentences

A relational event is one act from a sender to a receiver at a known moment (an e-mail, a call, a hand-shake). A REM
(Butts 2008) looks at the events one after the other and asks at each moment: among all the ordered pairs of actors that could have
interacted next, why was it *this* pair? Effects such as "the sender has been very active so far" or "the sender has written to this
receiver before" raise or lower the chance of a pair, and `nwrem` estimates by how much. Only the order of the events enters the
likelihood (it is a partial likelihood, as in a Cox model), so there is no intercept to estimate.

## Look at the events and declare them

```stata
. nwwebuse manufacturing, nwclear
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
  50,233
. keep if t < 5
. count
  631
. display "span in days: " %5.2f (t[_N] - t[1])
span in days:  1.75
```

The full data are far larger than a tutorial needs, so `keep if t < 5` keeps the first five days; the e-mails in this window begin on
the fourth day of January and span 1.75 days. The window names 102 of the 144 employees. The other 42 neither write nor receive in it, but they are
possible senders and receivers, so they belong to the set of pairs the model compares. A list of events creates only the actors it
mentions, so we add the missing ones as isolates with `nwaddnodes` (the lines that build the list `miss` are in
[example.do](example.do)):

```stata
. nwset sender receiver, directed eventtime(t) name(mail)
. nwaddnodes mail, nodenames(`miss')
```

The option `eventtime()` says that each row is an event with a time and not a lasting tie. There are now 144 x 143 = 20,592 ordered pairs
that could have happened at any moment.

## Model 1: activity

`nodsnd` is the sender's *normalized out-degree*: the share of all earlier events in which this actor was the sender. `nidrec` is the
receiver's normalized in-degree: the share of earlier events in which this actor was the receiver.

```stata
. nwrem mail, nodsnd nidrec
------------------------------------------------------------
Relational event model (ordinal partial likelihood, MLE)
Network: mail                          Actors: 144
Events: 631                            Log likelihood: -5.99e+03
------------------------------------------------------------
------------------------------------------------------------------------------
        mail | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
      nodsnd |    15.5574   1.605506     9.69   0.000     12.41067    18.70413
      nidrec |   25.03367   1.069952    23.40   0.000      22.9366    27.13074
------------------------------------------------------------------------------
```

**How to read it.** The effects are shares between 0 and 1, so the coefficients are large. A sender whose share of earlier
e-mails is 0.1 higher has `exp(1.56)`, about 4.7 times the odds of sending the next e-mail. A receiver whose share of earlier receipts
is 0.1 higher is about `exp(2.50)`, 12 times as likely to be the one written to. People who have been busy stay busy, and people
who have received a lot keep receiving.

## Model 2: history of the pair

`frpsndsnd` ("inertia") is the share of the sender's own earlier e-mails that went to *this* receiver. `frrecsnd`
("reciprocity of receipt") is the share of the sender's earlier receipts that came from this receiver.

```stata
. nwrem mail, frpsndsnd frrecsnd
...
Events: 631                            Log likelihood: -5.73e+03
...
   frpsndsnd |   3.166249   .2084023    15.19   0.000     2.757788     3.57471
    frrecsnd |   3.480144   .1970316    17.66   0.000     3.093969    3.866318

. display "events: " e(N) ", actors: " e(nodes) ", log likelihood: " %9.2f e(ll)
events: 631, actors: 144, log likelihood:  -5733.44
. display "effect of inertia on the odds: x" %6.1f exp(_b[frpsndsnd] * 0.1) " per 10 percentage points"
effect of inertia on the odds: x   1.4 per 10 percentage points
```

If another 10 percentage points of the sender's e-mails had gone to a given person, the odds that the next e-mail goes
to that person again are multiplied by 1.4. Replying also increases the odds: for each 10 percentage points of the sender's earlier receipts
that came from a given person, the odds that the next e-mail goes to that person are multiplied by about 1.4 as well (`exp(0.348)`; 3.48 on the log scale
for a sender whose receipts all came from this person). This model fits far
better than the activity model: the log likelihood rises from about -5,993 to -5,733 (the log likelihood is printed in rounded form in the header;
`e(ll)` holds the exact value). How people behave toward *each other* explains the e-mails better than how active they are in general.

## Both together

```stata
. nwrem mail, nodsnd nidrec frpsndsnd frrecsnd
...
Events: 631                            Log likelihood: -5.53e+03
...
      nodsnd |   14.36186   1.616598     8.88   0.000     11.19339    17.53033
      nidrec |   22.01834   1.182924    18.61   0.000     19.69985    24.33683
   frpsndsnd |   2.296481   .1856057    12.37   0.000     1.932701    2.660261
    frrecsnd |   3.820982    .161876    23.60   0.000     3.503711    4.138253
```

Once the activity of the actors is in the model, the inertia effect shrinks (3.17 to 2.30) and the activity effects shrink a little too
(`nodsnd` from 15.6 to 14.4, `nidrec` from 25.0 to 22.0), while the reciprocity of receipt grows (3.48 to 3.82). All four effects remain clearly
different from zero, and the log likelihood rises to about -5,532: neither the activity of the actors nor the history of the pair
alone tells the whole story. Part of what looked like "who writes to whom" in Model 2 was activity, and part of what looked like
"busy people stay busy" in Model 1 was people writing to those they always write to. This is the usual reason for fitting several effects together and not one at a time.

## A word on precision

The degree-type effects are running shares that move closer to one another (towards 1/144) as the log grows. Therefore their
estimates can stay noisy, and several of them in one model can be nearly collinear, so that different starting values give visibly different
individual coefficients with about the same log likelihood. If it matters, check the stability of a coefficient under the other
specifications, as in [Tutorial 3](../tutorial-3-comparing/).

## Things to try

- Fit `nwrem mail, frpsndsnd` alone, and then `nwrem mail, frrecsnd` alone.
- Replace the shares by recency: `nwrem mail, rsndsnd rrecsnd` asks whether the *most recent* partners are the ones returned to.
- Change the window to `keep if t < 4` or `keep if t < 6` and see which effects keep their size.
- Add `seed(1)` to any `nwrem` call; it only decides which optimizer restart is tried first and never changes a converged result.

## Next

[Tutorial 2](../tutorial-2-effects/) adds actor and pair covariates and the recency effects.
Back to the [overview of nwrem](../).
