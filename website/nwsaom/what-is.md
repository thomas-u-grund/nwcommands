---
title: "What it is"
parent: "nwsaom (SAOM)"
nav_order: 0.5
permalink: /nwsaom/what-is/
description: "nwsaom in plain words: what a stochastic actor-oriented model is, what question it answers, what data you need and when to use it."
---

# What nwsaom is, in plain words

## The idea

Imagine a class of pupils asked every year who their friends are. Between two surveys some friendships are made, some end and some stay. A stochastic actor-oriented model treats each pupil as someone who, now and then, gets the chance to change one tie and picks the change that suits them: keep a friend who returns the favour, befriend a friend of a friend, move towards someone similar. `nwsaom` estimates how strong each of these tendencies is from the surveys. It can do the same for the behaviour of the actors (smoking, grades, opinions) at the same time.

## Questions it answers

- Do people tend to reciprocate ties, close triangles, or choose similar others?
- Do friends become more alike because they select each other (selection), or because they adopt each other's behaviour (influence)?
- How fast does the network change, and does the speed differ between kinds of actors?

## What you need

A network observed at two or more points in time, on (mostly) the same actors, plus optional actor variables and behaviour measured at the same waves. Ties are recorded at the waves; you do not need to know when between the waves they changed.

## What you get

A table of effects with estimates, standard errors and convergence checks, goodness-of-fit tests, tests of single effects and comparisons of models, and simulation from the fitted model.

## Use it when

You have panel data of a network (waves) and want to explain how it changed.

## Use something else when

- a single snapshot of a network: use [nwergm](../../nwergm/) (patterns of the tie structure), [nwlsm](../../nwlsm/) or [nwsbm](../../nwsbm/).
- a time-stamped stream of events (calls, e-mails): use [nwrem](../../nwrem/) or [nwdynam](../../nwdynam/).

It follows the R package RSiena. `nwsaom` is part of the [nwcommands family](../../), and every package here needs the [core](../../nwcommands/).

## Next

[Install nwsaom](../install/), then [the first tutorial](../tutorial-1-first-saom/). The home page of the package has the technical description.
