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

```stata
. nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(wave1)

. nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(wave2)

. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity
------------------------------------------------------------------------------------------------------------------
SAOM (Method of Moments), waves: wave1 -> wave2
Actors: 6                              Estimated rate:  1.328 (0.584)
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
wave1_to_w~2 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -.0427608   .6120532    -0.07   0.944    -1.242363    1.156841
 reciprocity |    1.40833   .9113804     1.55   0.122    -.3779423    3.194603
------------------------------------------------------------------------------
```

`outdegree` plays the same baseline-density role `edges` plays in an ERGM; `reciprocity` asks
whether an actor is more likely to create a tie back to someone already tied to them. With only
6 actors and 2 waves there's little information to pin either coefficient down precisely (both
confidence intervals are wide) — expected for a toy example, not a sign of a problem.

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
      nodsnd |   1.268585   1.354195     0.94   0.349    -1.385589    3.922759
      nidrec |  -5.567764   3.511139    -1.59   0.113    -12.44947    1.313942
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
