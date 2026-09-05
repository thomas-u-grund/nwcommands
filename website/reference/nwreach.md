---
title: "nwreach"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Calculate reachability network"
---

# `nwreach`

Calculate reachability network

## Syntax

```stata
nwreach 
[netname]
[,
sym
name(string)
xvars
nwreplace]
```

| | |
|---|---|
| `sym` | Symmetrize network before calculation of reachability |
| `name(newnetname)` | Name of the new network; default = *reach* |
| `xvars` | Generate Stata variables for the network |
| `nwreplace` | if a network named *newnetname* already exists, drop it and use this name anyway - required, not silent (see [nwgeodesic](nwgeodesic) for the same convention) |

## Description

`nwreach` calculates the reachability network. The dyads *x_ij* in the reachibility network take value 1 when there is at least one path between *nodes i* and *j* in the original network [netname](netname), and 0 if there is no such path.

## Examples

- . nwclear
- . nwrandom 10, prob(.1)
- . nwreach random, sym
- . nwsummarize _reach, matonly

- 1 2 3 4 5 6 7 8 9 10
- hline 51
- 1 c | 0 c |
- 2 c | 1 0 c |
- 3 c | 1 1 0 c |
- 4 c | 1 1 1 0 c |
- 5 c | 1 1 1 1 0 c |
- 6 c | 1 1 1 1 1 0 c |
- 7 c | 1 1 1 1 1 1 0 c |
- 8 c | 0 0 0 0 0 0 0 0 c |
- 9 c | 1 1 1 1 1 1 1 0 0 c |
- 10 c | 1 1 1 1 1 1 1 0 1 0 c |
- hline 51

In this example, there is basically one isolate node (node 8) who is unconnected from everybody else.

## Supported network types

Binary: yes (only) - reachability is a structural yes/no property; [nwgeodesic](nwgeodesic)'s own weighted distance semantics do not carry through here. Directed: yes - symmetrized by default (same convention as [nwgeodesic](nwgeodesic)), `sym` available. Weighted: not applicable. Signed: not applicable. Two-mode: not checked.

## See also

- [nwgeodesic](nwgeodesic), [nwpath](nwpath)

- last certified : 24 Aug 2026
