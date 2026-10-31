---
title: "Tutorial 17: Networks over Time"
parent: "nwcommands (core)"
nav_order: 17
description: "Repeated observations of the same network: how many ties were kept, formed and dissolved between waves (nwturnover), correlation between waves, and slicing a temporal edge list into snapshots (nwattime)."
---

# Tutorial 17: Networks over Time

Many network data sets observe the same group more than once: a school class in autumn and again in spring, a firm
every year. Before you fit a model of change you want to know how much *changed*. This tutorial shows the
descriptive tools of the core: turnover between waves, correlation between waves, and how to turn a list of
ties with time stamps into snapshots. The animated version, `nwmovie`, is in [Tutorial 5](../05-visualization/); models
of change are in [Tutorial 19](../19-intro-longitudinal-models/) and the [nwsaom](../../nwsaom/) tutorials.

The data are the three waves of the Glasgow friendship study (`glasgow1`, `glasgow2`, `glasgow3`, 50 pupils). The
script is [`example.do`](example.do), the complete output [`example.log`](example.log).

```stata
. nwwebuse glasgow, nwclear

. nwsummarize glasgow1
```

(`Arcs: 113`, `Density: .0461`; the second wave has 116 arcs. The full summaries are in the log.)

## Turnover: stable, formed and dissolved ties

`nwturnover` compares two networks on the same nodes and counts the ties that were **stable** (present in both),
**formed** (new in the second) and **dissolved** (gone in the second). Only presence is compared, not tie values.

```stata
. nwturnover glasgow1 glasgow2, generate(stab12)
----------------------------------------
  Networks: glasgow1 -> glasgow2
  Stable: 57  Formed: 59  Dissolved: 56
  Jaccard index: .331
  Persistence: .504

. nwturnover glasgow2 glasgow3, generate(stab23)
----------------------------------------
  Networks: glasgow2 -> glasgow3
  Stable: 66  Formed: 56  Dissolved: 50
  Jaccard index: .384
  Persistence: .569
```

Between the first two waves the pupils kept 57 friendships, dropped 56 and made 59 new ones: about half of the
ties of the first wave were still there in the second (**persistence** .50 = 57 / (57 + 56)). The **Jaccard
index** is the share of all ties of either wave that are stable: 57 / (57 + 59 + 56) = .33. It is the number
that the longitudinal literature uses (Snijders' SIENA documentation) to judge whether a network changes enough to be
worth modelling, and whether it changes so much that the waves are hard to bridge: a common rule of thumb is that
values below about .3 make estimation difficult. These networks, at .33 and .38, are in the usable range
but with a lot of change.

The results are also stored (`r(stable)`, `r(formed)`, `r(dissolved)`, `r(jaccard)`, `r(persistence)`) for use in
loops and tables. `generate()` saves for each pupil an own Jaccard index, restricted to that pupil's ties, so you can see who
is stable and who changes:

```stata
. summarize stab12 stab23

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
      stab12 |         48    .3944444    .3421413          0          1
      stab23 |         48    .3881944    .3075288          0          1
```

The average pupil has an own Jaccard index of about .39, and individuals range from 0 (no tie kept) to 1 (all
ties kept). The variable has 48 values, not 50: for two pupils the own index is undefined (missing).

## Correlation between waves

`nwcorrelate` ([Tutorial 14](../14-homophily-mixing/)) correlates the tie cells of two networks. It answers a related
but different question from turnover: it compares the values of the cells, not only the counts of kept and new ties:

```stata
. nwcorrelate glasgow1 glasgow2
    Correlation: .473

. nwcorrelate glasgow2 glasgow3
    Correlation: .532
```

The second pair of waves is more alike in both measures. Both fit the same picture: friendships are
fairly persistent, but a great deal changes in a year.

## From time-stamped ties to snapshots

Panel data come as separate networks. Other data come as one list of ties with a time: an e-mail log, contacts with
the day on which they happened. Declare the time variable with `nwset` and `nwattime` cuts out the ties active at a given time as an
ordinary static network, to which every other command applies:

```stata
. input ego alter wave
. nwset ego alter, time(wave) name(mynet)

. nwattime mynet, at(2) name(t2)
----------------------------------------
  Static graph view: t2
  Source network: mynet (snapshot)
  At: 2
  Ties: 2

. nwturnover t1 t2, generate(stab_t12)
----------------------------------------
  Networks: t1 -> t2
  Stable: 0  Formed: 2  Dissolved: 1
  Jaccard index: 0
  Persistence: 0
```

In this toy example (the five ties are listed in the script) a tie is active in the wave in which it is recorded
(`snapshot`). With `interval()` instead, a tie is active from its start time up to, but not including, its end time,
and a tie without an end is open-ended; with `eventtime()` it is active at exactly the moment of the event. `nwattime`
is deliberately simple: it gives you a static view, not a model of the process.

## Which command when?

| Question | Command |
|---|---|
| How many ties were kept, formed and dissolved between two waves? | `nwturnover` |
| How alike are two waves, corrected for density? | `nwcorrelate` |
| Show the waves as an animation | `nwmovie` ([Tutorial 5](../05-visualization/)) |
| A list of ties with times: the network at one time | `nwset ..., time()`, `nwattime` |
| A model of how the network changes | [Tutorial 19](../19-intro-longitudinal-models/), [nwsaom](../../nwsaom/) |
