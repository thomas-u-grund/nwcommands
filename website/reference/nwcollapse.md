---
title: "nwcollapse"
parent: "Command reference"
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

This command collapses a network, i.e. it merges network nodes. It works very similar as `collapse`. With option `by(varname)` one specifies which nodes should be merged. The rule for collapsing two nodes are specified with *stat*, by default *stat* = **max** (`see here for possible values`). For example, when nodes A and B are collapsed to node Z, Z inherits all the ties from node A and B. The nodes in the new network are named after the values in *varname*.

By default, an existing network is replaced, unless option `generate(newnetname)` is specified.

## Examples

This collapses the first and the second node of a random network. The collapsed node will have all ties that the original nodes had.

```stata
. nwrandom 20, prob(.1) name(mynet)
. gen att = _n
. replace att = 1 in 2
. nwcollapse mynet, by(att)
```

## Supported network types

Binary: yes. Directed: yes. Weighted: yes - `generate()`'s own collapse function operates on whatever tie values are present. Signed: not checked. Two-mode: not supported - the row-grouping this command performs has no notion of mode, so it would freely collapse mode-1 and mode-2 nodes together; rejected explicitly with a clear error instead.

## See also

- `collapse`
- last certified : 24 Aug 2026
