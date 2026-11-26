---
title: "What it is"
parent: "nwergm (ERGM)"
nav_order: 1
permalink: /nwergm/what-is/
description: "nwergm in plain words: what a exponential random graph model is, what question it answers, what data you need and when to use it."
---

# What nwergm is, in plain words

## The idea

An ERGM asks what a network would look like if it were built by a few simple tendencies, and asks how strong each tendency must be to produce the network you observe. The tendencies are counts of small patterns: how many ties there are, how many ties are returned, how many triangles there are, how many ties join people of the same group. For each pattern the model gives one coefficient. A positive coefficient says the pattern occurs more often than chance would produce, given the other patterns in the model.

## Questions it answers

- Is there reciprocity, or is it just that everyone has many ties?
- Do people tie to others like themselves (homophily), after accounting for clustering?
- Which patterns together make a simulated network look like the real one?

## What you need

One network observed once (directed or undirected, one-mode or two-mode), plus optional actor variables. Missing ties are allowed.

## What you get

Coefficients with standard errors, goodness-of-fit checks, model comparison (AIC, BIC), simulation of networks from the fitted model, and, optionally, a Bayesian fit.

## Use it when

You have one network and want to know which local patterns build it.

## Use something else when

- the network was observed at several times and you want to explain change: use [nwsaom](../../nwsaom/).
- you want a map of the actors or a grouping into roles: use [nwlsm](../../nwlsm/) or [nwsbm](../../nwsbm/).

It follows the R package ergm of the statnet project. `nwergm` is part of the [nwcommands family](../../), and every package here needs the [core](../../nwcommands/).

## Next

[Install nwergm](../install/), then [the first tutorial](../tutorial-1-first-ergm/). The home page of the package has the technical description.
