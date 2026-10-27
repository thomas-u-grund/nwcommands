---
title: "Tutorial 9: Undirected and two-mode networks"
parent: "nwsaom (SAOM)"
nav_order: 10
description: "Stochastic actor-oriented models for undirected networks (symtype) and for two-mode networks in which actors choose among events, with nwsaom."
---

# Tutorial 9: Undirected and two-mode networks

**Goal.** So far every tie had a sender and a receiver, and every actor chose its own outgoing ties.
This tutorial covers two other kinds of network: **undirected** ties (a friendship that is simply there between two
people) and **two-mode** ties (people attending events, authors writing papers). Both need a few extra
decisions, and `nwsaom` handles them without a separate command.

**Data.** Part 1 uses the Glasgow friendship data, made undirected. Part 2 uses the "Southern women" data
(18 women, 14 social events; see [Data sets](../../datasets/) for the source), which are observed *once* only. No two-mode
panel data ship with the packages, so for part 2 we **create** two later waves with a small, documented simulation.
The commands were run with `nwsaom` 1.1.1 and the core 3.10.0 in Stata 18, and checked in Stata 17. The complete script and
log are in [example.do](example.do) and [example.log](example.log).

## Part 1: undirected networks

### Why a different model is needed

In a directed network an actor decides about their own outgoing ties alone. A tie in an undirected network
involves two people, so who decides? Different answers give different models, and the choice is yours (`symtype()`).
`nwsaom` detects an undirected network from the data (a network declared undirected, or directed waves in which every tie is
reciprocated), so no option is needed to switch the model on.

We make the Glasgow networks undirected: a tie exists if at least one of the two pupils named the other (`nwsym`, mode `max`).

```stata
. nwsym glasgow1, generate(u1) mode(max)
. nwsym glasgow2, generate(u2) mode(max)
. nwsym glasgow3, generate(u3) mode(max)
```

```stata
. nwsaom describe, waves(u1 u2 u3)

Network data: 3 waves, 50 actors, undirected
----------------------------------------------------------
wave          ties     density   avg. degree
1               74      0.0604         2.960
2               81      0.0661         3.240
3               77      0.0629         3.080
----------------------------------------------------------
period      kept  created dissolved  Jaccard   Hamming
1->2          43       38        31    0.384        69
2->3          47       30        34    0.423        64
----------------------------------------------------------
```

"Undirected" appears in the first line: ties are counted once per pair, so there are 74 ties among 50 pupils at the first wave. There is no
reciprocity effect, because every tie is mutual by definition (`nwsaom` says so if you ask for it, and refuses). The structural
effect that matters most is triadic closure, here measured by `gwesp(.69)` (geometrically weighted edgewise shared
partners; a friendship between two pupils is more likely the more friends they share).

### The default: forcing

```stata
. nwsaom, waves(u1 u2 u3) outdegree gwesp(.69) samex(smoke1) seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: u1 u2 u3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
    u1_to_u3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.370856   .1885703   -12.57   0.000    -2.740447   -2.001265
samex_smoke1 |   .2002612    .188039     1.06   0.287    -.1682885     .568811
   gwesp_.69 |   1.625979   .1710248     9.51   0.000     1.290776    1.961181
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    2.4826     2.0093 
          se |    0.4241     0.3160 
Overall maximum convergence ratio: 0.094 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The default model (`symtype(forcing)`, RSiena's default for undirected data) lets one pupil, chosen at random, propose to create or end a
tie, and the tie then changes. `gwesp_.69` is 1.63 (z = 9.5): friendships cluster strongly; `samex_smoke1` is 0.20 (z = 1.1): no clear
sign that pupils choose friends by smoking.

### Other ways in which a tie can change

`symtype()` chooses among RSiena's model types, by name:

| `symtype()` | who decides |
|---|---|
| `forcing` (default) | one actor decides and imposes the change on the other |
| `confirmation` | as `forcing`, but a *new* tie needs the other's agreement |
| `force`, `agree`, `joint` | a *pair* meets; the tie changes if the initiator wants it (`force`), if both want a new tie or either wants to end one (`agree`), or if their summed preferences favor it (`joint`) |

```stata
. nwsaom, waves(u1 u2 u3) outdegree gwesp(.69) samex(smoke1) symtype(confirmation) seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: u1 u2 u3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
    u1_to_u3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -1.380789   .1185397   -11.65   0.000    -1.613122   -1.148455
samex_smoke1 |   .1235281     .12458     0.99   0.321    -.1206443    .3677004
   gwesp_.69 |   1.095177   .1085168    10.09   0.000     .8824875    1.307866
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    5.0775     4.0687 
          se |    0.8474     0.6750 
Overall maximum convergence ratio: 0.077 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

```stata
. nwsaom, waves(u1 u2 u3) outdegree gwesp(.69) samex(smoke1) symtype(joint) seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: u1 u2 u3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
    u1_to_u3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.087691    .171507   -12.17   0.000    -2.423838   -1.751543
samex_smoke1 |    .153545   .1718964     0.89   0.372    -.1833656    .4904557
   gwesp_.69 |   1.343861   .1352783     9.93   0.000     1.078721    1.609002
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    0.4712     0.3753 
          se |    0.0856     0.0660 
Overall maximum convergence ratio: 0.030 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The clustering effect remains clear and large in all three versions (1.63, 1.10 and 1.34) and the smoking effect remains small, so
the substantive conclusion does not depend on the choice. The numbers, however, do not compare directly across types: the coefficients are
defined for different decision rules, and the rate means different things (about 2 opportunities per period in the forcing model, 4 to 5 in the
confirmation model, and a pairwise rate of about 0.4 in the joint model). Choose the type that matches how you think the ties arise,
fix it before looking at the results, and report it.

If you ask for an effect that makes no sense for an undirected network, `nwsaom` stops with a message:

```stata
. capture noisily nwsaom, waves(u1 u2 u3) outdegree reciprocity
reciprocity is not meaningful under symmetric - every tie is reciprocated by construction once both directions are forced equal, so this effect's own statistic is a constant (RSiena itself does not offer recip for a non-directed dependent variable).
invalid syntax
```

## Part 2: two-mode networks

### What is different

In a two-mode network there are two kinds of nodes, and ties only go between the kinds. In the Southern women data the two kinds
are women and the events they attended. In a SAOM the **actors are one kind and the events the other**: the women choose which events to
attend; the events do not act. A woman's choices are described by effects such as `outdegree` (how many events she attends)
and `indegpopularity` (are popular events more attractive?). There is no reciprocity and there are no triangles in a two-mode network;
`cycle4` (four-cycles: two women who attend the same two events) takes the place of closure.

```stata
. nwwebuse davis, nwclear
```

```stata
. nwsummarize
--------------------------------------------------
   Network name:  davis
   Network id:  1
   Directed: false
   Valued: false
   Two-mode: true
   Nodes: 32
      Level 1: 18 (woman)
      Level 2: 14 (event)
   Selfloop: false
   Edges: 89
   Minimum value:  0
   Maximum value:  1
   Density:  .353
   Temporal: false
```

The summary says "Two-mode: true", 18 women (level 1) and 14 events (level 2), and 89 ties (attendances).

### Creating later waves

A SAOM needs at least two waves; these data have one. To have something to analyze we let the world run on
for two more waves, with a rule that we know. It is a few lines of Mata (the script has them in full). A woman is chosen at random, looks at all
14 events, and either changes nothing or toggles one attendance, choosing among these options with probabilities that depend on the same kind of
objective function as a SAOM actor uses: the density effect is -1.5, and an event is more attractive the more women
already attend it (indegree popularity 0.3). This is done 200 times between waves.

```stata
. mata:
: rseed(20261027)
: nw = rows(A1)
: ne = cols(A1)
: A = A1
: ...                      (200 choices per period, see example.do)
: end
```

The attendance counts of the three waves are 89 (the real data), then 78 and 82. These are three two-mode networks,
which we declare with `nwset, bipartite`; the rows of the matrix are the first kind of node, the actors:

```stata
. nwset, mat(W1) bipartite name(women1)
. nwset, mat(W2) bipartite name(women2)
. nwset, mat(W3) bipartite name(women3)
```

### The model

```stata
. nwsaom, waves(women1 women2 women3) outdegree indegpopularity seed(4)
(two-mode network: 18 actors (mode 2) choose among 14 events)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: women1 women2 women3
Actors: 32                             Periods: 2
Two-mode network: 18 actors choose among 14 events
----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------
women1_to_wom~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
      outdegree |  -1.923622   .2516051    -7.65   0.000    -2.416759   -1.430485
indegpopularity |   .5911646   .0942954     6.27   0.000      .406349    .7759801
---------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |   11.5125     9.9544 
          se |    2.4674     2.1855 
Overall maximum convergence ratio: 0.082 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The message above the table says what `nwsaom` understood: 18 actors choose among 14 events (by default the actors are the
*rows* of the attendance matrix). `indegpopularity` is 0.59 (z = 6.3): popular events attract more women, which is the direction we built in.
The size is not recovered exactly (we used 0.3; the estimate has a standard error of 0.09), as can happen with 18 actors and
two periods; the density effect (-1.92 against the -1.5 we used) moves with it, because the two effects are
estimated jointly. The rates are about 11 and 10: each woman had roughly 11 opportunities per period, close to the 200/18 we used.

A second activity effect:

```stata
. nwsaom, waves(women1 women2 women3) outdegree indegpopularity outactivity seed(6)
(two-mode network: 18 actors (mode 2) choose among 14 events)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: women1 women2 women3
Actors: 32                             Periods: 2
Two-mode network: 18 actors choose among 14 events
----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------
women1_to_wom~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
      outdegree |  -1.746669   .4122939    -4.24   0.000     -2.55475   -.9385877
indegpopularity |   .5775975   .0940682     6.14   0.000     .3932272    .7619678
    outactivity |  -.0159469   .0341944    -0.47   0.641    -.0829666    .0510728
---------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |   11.4227    10.0482 
          se |    2.6326     2.1795 
Overall maximum convergence ratio: 0.095 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

`outactivity` (women who attend many events attend even more) is close to zero, and the popularity effect hardly changes.
The two-mode effects available are `outdegree`, `indegpopularity`, `outactivity`, `cycle4`, `outiso`, the anti-isolate effects
and covariate effects, and the covariates are variables of the actors or the events; see `help nwsaom_remarks`.

### Who is the actor?

Everything above treated the women as actors. If the events were to choose their attendees instead, you set `actormode(1)`:

```stata
. nwsaom, waves(women1 women2 women3) outdegree indegpopularity actormode(1) seed(7)
(two-mode network: 14 actors (mode 1) choose among 18 events)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: women1 women2 women3
Actors: 32                             Periods: 2
Two-mode network: 14 actors choose among 18 events
----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------
women1_to_wom~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
      outdegree |  -.1135387   .5292987    -0.21   0.830    -1.150945    .9238677
indegpopularity |  -.1428934   .2334045    -0.61   0.540    -.6003578    .3145709
---------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |   13.0694    11.1071 
          se |    2.3102     2.0313 
Overall maximum convergence ratio: 0.143 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Now 14 events choose among 18 women, and the model is a different one: there is no evidence that women are more likely to be
chosen when many events have already chosen them (`indegpopularity` -0.14, z = -0.6). Choose the actor mode by asking **who decides**; the roles
are not interchangeable.

## Things to try

- Add `cycle4` to the two-mode model.
- Create the waves with a different popularity value (for example 0.6 or 0) and see how the estimate follows.
- Undirected: compare `symtype(force)` and `symtype(agree)`.

## Where next

[Tutorial 10](../tutorial-10-endowment-interaction-rate/) goes back to the directed Glasgow network and adds effects that treat creating
a tie and ending a tie differently, interactions between effects, and the rate of change.
