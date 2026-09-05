---
title: "nwcomponents"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Calculate network components / largest component"
---

# `nwcomponents`

Calculate network components / largest component

## Syntax

```stata
nwcomponents 
[netlist]
[, lgc
generate(newvarname)
replace
silent]
```

| | |
|---|---|
| `generate(newvarname)` | **Required.** Name of the Stata variable that stores information about components (component membership, or largest-component membership if `lgc` is given) |
| `replace` | Replace existing variable |
| `lgc` | Calculate membership to largest component |
| `silent` | Suppress display of results |

## Description

Calculate the components of a network or a list of networks. A component is a set of nodes that are only connected among each other. All calculations are performed on the undirected network. Nodes can only belong to one component.

`generate()` is required and names the new variable that stores the component membership. When option **lgc** is specified, the command instead stores in that variable information about membership to the largest component.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwcomponents flomarriage, generate(_component)
```
- hline 40
- Network name: flomarriage
- Components: 2

- _component c | Freq. Percent Cum.
- hline 12c +hline 35
- 1 c | 15 93.75 93.75
- 2 c | 1 6.25 100.00
- hline 12c +hline 35
- Total c | 16 100.00

This shows that there are two components in the Florentine marriage network. All except one node belong to the first component. Some alternative ways how the commands can be used.

```stata
. nwwebuse glasgow
. nwcomponents glasgow1, generate(mycomponent)
. nwcomponents _all, lgc generate(_lgc)
. nwcomponents _all, lgc generate(mylgc)
```

## Supported network types

Binary: yes (only) - component membership is a structural (weak-connectivity) property, tie values are ignored. Directed: yes - uses weak connectivity (ignores tie direction), matching the standard convention for "components" on a directed graph. Weighted: not applicable. Signed: not applicable. Two-mode: not checked.

## Stored results

**Scalars**

- **r(components)** number of components

**Matrices**

- **r(comp_sizeid)** distribution over components

## See also

- [nwgen](nwgen.md), [nwkcomponents](nwkcomponents.md)
