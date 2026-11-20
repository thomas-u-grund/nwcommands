---
title: "What it is"
parent: "nwsbm (block models)"
nav_order: 0.5
permalink: /nwsbm/what-is/
description: "nwsbm in plain words: what a stochastic block model is, what question it answers, what data you need and when to use it."
---

# What nwsbm is, in plain words

## The idea

A stochastic block model sorts the actors into groups, called blocks, so that actors in the same block tie to others in much the same way. The model then says how likely ties are within each block and between each pair of blocks. The number of blocks is not set by you: the program tries several and a criterion tells you which fits best. Blocks are not communities. A block can be a core that ties to everyone, a periphery that ties only to the core, or two sides that tie only to each other.

## Questions it answers

- Which actors play the same role in the network?
- How do the roles connect: core and periphery, two sides, or groups with many ties inside?
- For a two-mode network, which actors of each side group together?

## What you need

One network observed once (directed, undirected or two-mode; binary, counts or real values), plus optional covariates of the pairs.

## What you get

A grouping of the actors with the probability of each block for every actor, the matrix of tie probabilities between the blocks, the criterion for each number of blocks, and plots.

## Use it when

You want to divide a network into roles and describe how the roles connect.

## Use something else when

- you want to find groups with many ties inside: use the community commands of the core, such as `nwcommunity`.
- you want a map of positions: use [nwlsm](../../nwlsm/).

It follows the R packages blockmodels, sbm and greed. `nwsbm` is part of the [nwcommands family](../../), and every package here needs the [core](../../nwcommands/).

## Next

[Install nwsbm](../install/), then [the first tutorial](../tutorial-1-first-sbm/). The home page of the package has the technical description.
