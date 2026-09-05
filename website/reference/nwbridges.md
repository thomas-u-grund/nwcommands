---
title: "nwbridges"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Calculate bridges"
---

# `nwbridges`

Calculate bridges

## Syntax

```stata
nwbridges
[netname]
[,
name(newnetname)
type(type)
nwreplace]
```

| | |
|---|---|
| `name(newnetname)` | Save bridges as network; default = *_bridges*. |
| `type`(*[type](nwbridges.md)*) | Type of bridge; default = *global* |
| `nwreplace` | Overwrite network *newnetname*. |

## Description

A global bridge is a tie from node i to j if deleting the tie would make it impossible to reach node j from node i. A bridge is therefore essential to connect two nodes (or different parts of the network) with each other.

In contrast, a tie between nodes i and j is a local bridge if deleting the tie would increase the distance between i and j to a value strictly more than two.

The command saves all bridges as a new network *newnetname*.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwbridges flobusiness
. nwbridges flobusiness, type(local) nwreplace
```

## Supported network types

Binary: yes (only) - bridge status is a structural property, tie values are ignored. Directed: yes - `type()` distinguishes local/global bridges and arcs vs. edges. Weighted: not applicable. Signed: not applicable. Two-mode: not checked.

## Stored results

**Macros**

- **r(name)** name of the source network
- **r(directed)** whether the source network is directed (**true**/**false**)
- **r(bridges)** number of bridges found
- **r(bridges_type)** the `type()` used (**global**/**local**/**distance**)

## References

Burt, R. S. (1992). *Structural Holes: The Social Structure of Competition*. Cambridge: Harvard University Press.

## See also

- [nwburt](nwburt.md), [nwpath](nwpath.md)

- last certified : 24 Aug 2026
