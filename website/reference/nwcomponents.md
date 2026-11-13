---
title: "nwcomponents"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Network components and the largest component"
---

# `nwcomponents`

Network components and the largest component

## Syntax

```stata
nwcomponents 
[netlist]
[, lgc
generate(newvarname)
replace
silent
listall]
```

| | |
|---|---|
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores information about components (component membership, or largest-component membership if `lgc` is given) |
| `replace` | Replace existing variable |
| `lgc` | Calculate membership to largest component |
| `silent` | Suppress display of results |
| `listall` | Print the full table of components; by default at most the first 30 rows are printed, with a note. Results in `r()` are unchanged |

## Description

Calculate the components of a network or a list of networks. A component is a set of nodes that are only connected among each other. All calculations are performed on the undirected network. Nodes can only belong to one component.

`generate()` is required and names the new variable that stores the component membership. When option **lgc** is specified, the command instead stores in that variable information about membership to the largest component (1 for its nodes, 0 for all others). With more than one network in the *netlist*, a number is appended to the name (*newvarname***1**, *newvarname***2**, ...) and the stored results are those of the last network.

## Network types

**Directed:** weak components (the direction is ignored). **Valued:** tie values are ignored (every tie counts as present; the command prints a note). **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not applicable. See [nwnetworktypes](nwnetworktypes).

## Examples

```stata
. nwwebuse florentine, nwclear
. nwcomponents flomarriage, generate(_component)

----------------------------------------
  Network name: flomarriage
  Components: 2

 _component |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |         15       93.75       93.75
          2 |          1        6.25      100.00
------------+-----------------------------------
      Total |         16      100.00
```
This shows that there are two components in the Florentine marriage network. All except one node belong to the first component. Some alternative ways how the commands can be used.

```stata
. nwwebuse glasgow, nwclear
. nwcomponents glasgow1, generate(mycomponent)
. nwcomponents _all, lgc generate(_lgc)
. nwcomponents _all, lgc generate(mylgc)
```

## Limits

The components are found from the stored ties (10,000 nodes: 0.04 seconds). A network with more than 1,000 components (any sparse network of a few thousand nodes) has its component sizes counted in Mata; the table is not printed above 1,000 components, and **r(comp_sizeid)** holds the sizes ordered by size and then by component number.

## Stored results

- **Scalars**
- **r(components)** --- number of components

- **Matrices**
- **r(comp_sizeid)** --- distribution over components: one row per component with the columns size, compid (component id) and share

## See also

- [nwgen](nwgen), [nwkcomponents](nwkcomponents)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
