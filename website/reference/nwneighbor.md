---
title: "nwneighbor"
parent: "Command reference"
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
subnet(newnetname)
subreplace]
```

| | |
|---|---|
| `mode`(*[context](nwneighbor)*) | Defines the network neighborhood of node *ego*; default = *outgoing* |
| `generate(newvarname)` | Save information about network neighbors in variable. |
| `replace` | Overwrite variable *newvarname*. |
| `subnet(newnetname)` | Save the induced subgraph on *ego* plus its own neighbors (and every tie among them) as a new network |
| `subreplace` | Overwrite network *newnetname* if it already exists |

## Description

` nwneighbor` returns the network neighbors of *nodename* specified in **ego()**. The network neighborhood of a node is defined in `mode()`. By default, the neighborhood of a node *ego* consists of all nodes *j*, who receive a tie from node *ego*. Tie values are ignored.

`subnet(newnetname)` additionally saves the INDUCED SUBGRAPH on *ego* plus its own neighbors - a genuine new network containing exactly those nodes and every tie the original network has among them (not just ego's own ties) - as *newnetname*. Useful as a starting point for any ego-network-level analysis that needs an actual standalone network object (as opposed to a per-node attribute aggregate, which [nwaltergen](nwaltergen)/[nwego](nwego) already compute directly without needing one). The original network is left untouched; *newnetname* inherits its directedness/valued/self-loop/two-mode status.

## Examples

- . nwwebuse florentine, nwclear
- . nwneighbor flobusiness, ego(ginori)

- hline 40
- Network: flobusiness
- hline 40
- Ego : ginori
- Neighbors : barbadori , medici
- hline 40

This shows that the "ginori" family has business relationships with the "barbadori" and the "medici".

## Supported network types

Binary: yes. Directed: yes, via `mode(incoming|outgoing|either)`. Weighted: not applicable - returns which nodes are neighbors, not tie values. Signed: not applicable. Two-mode: not checked.

## Stored results

**Macros**

- **r(ego)** name of ego (a string, not a nodeid)
- **r(oneneighbor)** one randomly selected neighbor's name; empty if ego has no neighbors

**Scalars**

- **r(egoid)** nodeid of ego
- **r(num_neighbors)** number of neighbors ego has

**Matrices**

- **r(neighbors)** reshuffled list of all neighbors
