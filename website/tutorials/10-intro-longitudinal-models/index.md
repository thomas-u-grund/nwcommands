---
title: "Intro to Longitudinal Network Models"
parent: Tutorials
nav_order: 10
description: "A conceptual orientation to stochastic actor-oriented models and relational event models."
---

# Intro to Longitudinal Network Models

[Intro to ERGM](../09-intro-ergm) modeled a single, static network. nwcommands ships two models
for network *change* instead — each built for a different kind of longitudinal data.

## Stochastic actor-oriented models (SAOM)

An SAOM (`nwsaom`) models change between two or more observed **panel waves** of the same
network as a sequence of unobserved, actor-driven "ministeps": one at a time, an actor is
activated and may create or drop exactly one of its own outgoing ties, choosing among the
alternatives via a model weighted by the same kind of effect coefficients an ERGM uses — but
evaluated *myopically*, from that one actor's own perspective only. That actor-level, myopic
framing is what actually distinguishes an SAOM from an ERGM, not just "two waves instead of one":
an ERGM has no actors or ministeps at all, only a single probability distribution over entire
graphs.

Here are three yearly waves of friendship among 50 pupils in a Scottish school (the Glasgow
data, RSiena's `s50` data), with outdegree, reciprocity, transitive closure, and homophily on
smoking:

```stata
. nwwebuse glasgow, nwclear

. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip samex(smoke1) seed(1)
-------------------------------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
-------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.761729   .1480041   -18.66   0.000    -3.051812   -2.471647
 reciprocity |   2.430146   .1968398    12.35   0.000     2.044347    2.815945
samex_smoke1 |   .1289793   .1416724     0.91   0.363    -.1486936    .4066521
   transtrip |   .6264698   .0756481     8.28   0.000     .4782023    .7747373
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    6.4403     5.2362 
          se |    1.1121     0.9281 
Overall maximum convergence ratio: 0.185 (good; all t-ratios below 0.1)
```

`outdegree` plays the same baseline-density role `edges` plays in an ERGM. `reciprocity` and
`transtrip` (transitive triplets: a friend of a friend becomes a friend) are both strongly
positive; once they are in the model, pupils show no significant tendency to befriend others with
the same smoking status (`samex_smoke1`). The rate table says how often, on average, a pupil had the
opportunity to change a friendship: about 6.4 times between the first and second waves and 5.2
times between the second and third. The last line checks convergence: an overall maximum
convergence ratio below 0.25 with every t-ratio below 0.1 means the estimates can be used;
otherwise, run the model again starting from them (see the examples in
[nwsaom](../../reference/nwsaom)).

## Relational event models (REM)

An REM (`nwrem`) is built for the opposite kind of data: a raw, continuous-time stream of
individual events (an email sent, a call placed, a message posted) rather than snapshots at a
handful of waves. There's no aggregation step at all — every single event is its own observation,
compared against every other actor-pair that *could* have generated an event at that same moment
but didn't.

```stata
. clear

. input sender receiver t

        sender   receiver          t
  1. 1 2 1
  2. 1 3 2
  3. 2 1 3
  4. 1 2 4
  5. 3 2 5
  6. 2 3 6
  7. 1 3 7
  8. 3 1 8
  9. 2 1 9
 10. 1 3 10
 11. end

. nwset sender receiver, eventtime(t) name(chat)

. nwrem chat, nodsnd nidrec
------------------------------------------------------------
Relational event model (ordinal partial likelihood, MLE)
Network: chat                          Actors: 3
Events: 10                             Log likelihood:  -15.9033
------------------------------------------------------------
------------------------------------------------------------------------------
        chat | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
      nodsnd |   1.268597   1.354196     0.94   0.349    -1.385579    3.922772
      nidrec |   -5.56779   3.511146    -1.59   0.113    -12.44951    1.313929
------------------------------------------------------------------------------
```

`nodsnd` asks whether a sender's own total out-activity so far predicts sending the next event;
`nidrec` asks the same for a receiver's in-activity. As with the SAOM example, ten events among
three actors is nowhere near enough data to estimate anything precisely — the point here is the
workflow, not the substantive result.

## Which one fits your data?

If you observed the network at a handful of discrete points in time (a survey repeated every
year, say), reach for `nwsaom`. If you have a genuine timestamped log of individual interactions,
`nwrem` uses that timing directly rather than throwing it away by collapsing into waves. A
forthcoming Stata Press book covers both in full depth — model specification, convergence
diagnostics for SAOM's Method-of-Moments estimation, goodness-of-fit, and worked applications
beyond this orientation. See the [nwsaom](../../reference/nwsaom) and [nwrem](../../reference/nwrem)
reference pages for the complete effect catalogs.
