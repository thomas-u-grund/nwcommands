---
title: "What it is"
parent: "nwalaam (ALAAM)"
nav_order: 1
permalink: /nwalaam/what-is/
description: "nwalaam in plain words: what a autologistic actor attribute model is, what question it answers, what data you need and when to use it."
---

# What nwalaam is, in plain words

## The idea

Suppose you know who smokes, who adopted a new practice or who has a disease, and you know the network between the actors. An autologistic actor attribute model asks what in the network goes together with having the outcome. It counts things like how many actors have it, how many of an actor's partners have it (contagion), and how well connected the actors with it are. A positive contagion coefficient says that actors with the outcome are clustered in the network. It does not by itself say that anyone influenced anyone.

## Questions it answers

- Are actors with the outcome tied to each other more than chance would give?
- Do actors with many ties have the outcome more often?
- Which actor and network features go together with the outcome?

## What you need

One network, observed once, and a yes-or-no outcome for every actor, plus optional actor variables.

## What you get

Coefficients with standard errors, convergence statistics, goodness-of-fit checks and simulation.

## Use it when

Your question is about an outcome of the actors, not about the ties between them.

## Use something else when

- you want to model the ties: use [nwergm](../../nwergm/).
- the outcome is measured at several times and you want to model change: use [nwsaom](../../nwsaom/).

It follows the ALAAM of Robins, Pattison and Elliott (2001) and the software published for it. `nwalaam` is part of the [nwcommands family](../../), and every package here needs the [core](../../nwcommands/).

## Next

[Install nwalaam](../install/), then [the first tutorial](../tutorial-1-first-alaam/). The home page of the package has the technical description.
