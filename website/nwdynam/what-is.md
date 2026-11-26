---
title: "What it is"
parent: "nwdynam (DyNAM)"
nav_order: 1
permalink: /nwdynam/what-is/
description: "nwdynam in plain words: what a dynamic network actor model is, what question it answers, what data you need and when to use it."
---

# What nwdynam is, in plain words

## The idea

Some data is a list of events: this person wrote to that person at this moment. A dynamic network actor model splits each event into two questions. First, who acts next? Some people write often, and more so when they are well connected. Second, given that someone acts, whom do they pick? People write to those who wrote to them, or to those they wrote to before. `nwdynam` estimates one set of effects for the first question and one for the second.

## Questions it answers

- Who is likely to act next, and what makes some actors more active?
- Whom do actors choose, and does the choice depend on past interaction?
- Do actors who act and actors who are chosen follow different rules?

## What you need

A list of timestamped events (sender, receiver, time), the actors, and optional actor and pair variables.

## What you get

Separate coefficients for the rate (who acts) and the choice (whom), standard errors, information criteria, and tools to compare models.

## Use it when

You have a stream of timed events and want to model the actor's decision to act and the choice of a partner separately.

## Use something else when

- you want one model for the pair that interacts at each event: use [nwrem](../../nwrem/).
- the network is observed in waves, not as events: use [nwsaom](../../nwsaom/).

It follows the R package goldfish. `nwdynam` is part of the [nwcommands family](../../), and every package here needs the [core](../../nwcommands/).

## Next

[Install nwdynam](../install/), then [the first tutorial](../tutorial-1-first-dynam/). The home page of the package has the technical description.
