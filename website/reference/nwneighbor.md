---
title: "nwneighbor"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Extract the network neighbors of a node"
---

# `nwneighbor`

Extract the network neighbors of a node

## Syntax

```stata
nwneighbor 
[netname],
ego(nodename)
[mode(context)
generate(newvarname)
replace
sub:net(newnetname)
subreplace]
```

| | |
|---|---|
| `mode`(*[context](nwneighbor)*) | Defines the network neighborhood of node *ego*; default = *outgoing* |
| `generate(newvarname)` | Save information about network neighbors in variable. |
| `replace` | Overwrite variable *newvarname*. |
| `sub:net(newnetname)` | Save the induced subgraph on *ego* plus its own neighbors (and every tie among them) as a new network |
| `subreplace` | Overwrite network *newnetname* if it already exists |

## Description

` nwneighbor` returns the network neighbors of *nodename* specified in **ego()**. The network neighborhood of a node is defined in `mode()`. By default, the neighborhood of a node *ego* consists of all nodes *j*, who receive a tie from node *ego*. Tie values are ignored.

`subnet(newnetname)` additionally saves the INDUCED SUBGRAPH on *ego* plus its own neighbors - a genuine new network containing exactly those nodes and every tie the original network has among them (not just ego's own ties) - as *newnetname*. Useful as a starting point for any ego-network-level analysis that needs an actual standalone network object (as opposed to a per-node attribute aggregate, which [nwaltergen](nwaltergen) / [nwego](nwego) already compute directly without needing one). The original network is left untouched; *newnetname* inherits its directedness/valued/self-loop/two-mode status.

## Network types

**Directed:** `mode(incoming|outgoing|either)` chooses the neighbours. **Valued:** tie values are ignored (every tie counts as present; the command prints a note). **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not applicable. See [nwnetworktypes](nwnetworktypes).

## Examples

```stata
. nwwebuse florentine, nwclear
. nwneighbor flobusiness, ego(ginori)

----------------------------------------
  Network: flobusiness
----------------------------------------
    Ego        : ginori
    Neighbors  : barbadori , medici
----------------------------------------
```
This shows that the "ginori" family has business relationships with the "barbadori" and the "medici".

## Stored results

- **Macros**
- **r(ego)** --- name of ego (a string, not a nodeid)
- **r(oneneighbor)** --- one randomly selected neighbor's name; empty if ego has no neighbors

- **Scalars**
- **r(egoid)** --- nodeid of ego
- **r(num_neighbors)** --- number of neighbors ego has

- **Matrices**
- **r(neighbors)** --- column vector with the nodeids of all neighbors, in nodeid order

## Also see

- [nwcontext](nwcontext), [nwgeodesic](nwgeodesic), [nwpath](nwpath)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
