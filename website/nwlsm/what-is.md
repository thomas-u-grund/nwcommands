---
title: "What it is"
parent: "nwlsm (latent space)"
nav_order: 1
permalink: /nwlsm/what-is/
description: "nwlsm in plain words: what a latent space model is, what question it answers, what data you need and when to use it."
---

# What nwlsm is, in plain words

## The idea

A latent space model gives every actor a position on an invisible map and says that actors who are close on the map are more likely to be tied. The model finds the positions that best explain the ties you observe. The result is a picture of the network: clusters appear as groups of nearby actors, and the effect of a covariate, such as working in the same office, is measured against the distance. Because closeness is transitive (a friend of a friend is also near), the model explains clustering without counting triangles.

## Questions it answers

- What does the network look like as a map, and which actors form groups?
- Do shared attributes raise the chance of a tie once distance is accounted for?
- How many clusters does the network have?

## What you need

One network observed once (directed or undirected, binary or with counts), plus optional actor and pair covariates. For the influence model, an outcome measured twice.

## What you get

Estimated positions, posterior distributions of the coefficients, chain diagnostics, goodness-of-fit checks, a BIC for choosing the number of clusters, and plots.

## Use it when

You want a map of a network, or a model for its ties in which clustering comes from distance.

## Use something else when

- you want to count specific patterns such as reciprocity or triangles: use [nwergm](../../nwergm/).
- you want hard groups of actors with the same role (core and periphery, for example): use [nwsbm](../../nwsbm/).

It follows the R package latentnet. `nwlsm` is part of the [nwcommands family](../../), and every package here needs the [core](../../nwcommands/).

## Next

[Install nwlsm](../install/), then [the first tutorial](../tutorial-1-first-lsm/). The home page of the package has the technical description.
