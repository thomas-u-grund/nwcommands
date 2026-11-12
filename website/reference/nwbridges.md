---
title: "nwbridges"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Find bridges (ties whose removal disconnects the network)"
---

# `nwbridges`

Find bridges (ties whose removal disconnects the network)

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
| `type`(*[type](nwbridges)*) | Type of bridge; default = *global* |
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

## Stored results

- **Macros**
- **r(name)** --- name of the source network
- **r(directed)** --- whether the source network is directed (**true**/**false**)
- **r(bridges)** --- number of bridges found
- **r(bridges_type)** --- the `type()` used (**global**/**local**/**distance**)

## References

Burt, R. S. (1992). *Structural Holes: The Social Structure of Competition*. Cambridge: Harvard University Press.

## See also

- [nwburt](nwburt), [nwpath](nwpath)

---

*nwcommands version 3.21.0, 12 November 2026* ([check your installed version](nwversion))
