---
title: "nwcollapse"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Collapse a network"
---

# `nwcollapse`

Collapse a network

## Syntax

```stata
nwcollapse 
[(stat)]
[netname]
[,
by(varname) 
generate(newnetname) 
options]
```

## Description

This command collapses a network, i.e. it merges network nodes. It works very similar as `collapse`. With option `by(varname)` one specifies which nodes should be merged. The rule for collapsing two nodes are specified with *stat*, by default *stat* = **max** (`see here for possible values`). For example, when nodes A and B are collapsed to node Z, Z inherits all the ties from node A and B. A merged node takes the label of the first node of its group with the prefix **new_** (e.g. *new_A*); a node that is alone in its group keeps its label.

By default, an existing network is replaced, unless option `generate(newnetname)` is specified.

## Network types

**Directed:** yes. **Valued:** the collapse function *stat* works on the tie values. **Two-mode:** not supported (error 6088; use [nwproject](nwproject) first). **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

The collapse is done on the list of all dyads of the network (see [nwtoedge](nwtoedge)), so the time and the memory grow with the square of the number of nodes. Measured in Stata/BE, random directed network with 10 ties per node and 5 groups: 1,000 nodes 8 seconds, 5,000 nodes 61 seconds and 4.5 GB; above 7,071 nodes (50,000,000 dyads) the command stops at once with r(484), a message that says why and what to do instead.

## Examples

This collapses the first and the second node of a random network. The collapsed node will have all ties that the original nodes had.

```stata
. nwrandom 20, prob(.1) name(mynet)
. gen att = _n
. replace att = 1 in 2
. nwcollapse mynet, by(att)
```

## See also

- `collapse`

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
