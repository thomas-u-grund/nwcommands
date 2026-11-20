---
title: "What it is"
parent: "nwrem (REM)"
nav_order: 0.5
permalink: /nwrem/what-is/
description: "nwrem in plain words: what a relational event model is, what question it answers, what data you need and when to use it."
---

# What nwrem is, in plain words

## The idea

When data come as a list of events (who sent what to whom, and when), a relational event model looks at each event and asks: of all pairs of actors who could have interacted at that moment, why was it this pair? The answer is a set of effects that make a pair more likely: the sender is very active, the pair interacted before, the receiver just wrote to the sender, the two are in the same group. `nwrem` estimates how strong each effect is, in the way a Cox model compares the case that happened with those that could have.

## Questions it answers

- Do people return to earlier partners (inertia)?
- Is a message more likely to be answered by its receiver (reciprocity)?
- Do covariates of the actors or the pair change who interacts with whom?

## What you need

A list of timestamped events (sender, receiver, time), the actors, and optional actor and pair variables.

## What you get

Coefficients with standard errors, likelihood and information criteria, and model comparison.

## Use it when

You have a time-ordered list of events and want to know which effects make the observed pair more likely than the alternatives.

## Use something else when

- you want to treat who acts and whom they choose as two separate decisions: use [nwdynam](../../nwdynam/).
- you have waves of a network, not events: use [nwsaom](../../nwsaom/).

It was written from Butts (2008) and cross-checked against the R package relevent. `nwrem` is part of the [nwcommands family](../../), and every package here needs the [core](../../nwcommands/).

## Next

[Install nwrem](../install/), then [the first tutorial](../tutorial-1-first-rem/). The home page of the package has the technical description.
