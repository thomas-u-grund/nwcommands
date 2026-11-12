---
title: "nwbalance"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Structural balance of a signed network"
---

# `nwbalance`

Structural balance of a signed network

## Syntax

```stata
nwbalance
[netname]
[,
generate(namelist)]
```

| | |
|---|---|
| `generate(namelist)` | Up to 3 names, for the per-node balance ratio, count of balanced triads, and count of closed triads a node belongs to; default = *_balance _baltriad _clotriad*; existing variables of these names are replaced |

## Description

`nwbalance` evaluates a [network](netname)'s ties as signed (positive/negative) and tests every closed triad against Cartwright and Harary's (1956) strong structural balance criterion: a closed triad is *balanced* when the product of its three tie values is positive - equivalently, when it contains an even number (0 or 2) of negative ties ("the friend of my friend is my friend"; "the enemy of my enemy is my friend"). A triad with an odd number (1 or 3) of negative ties is *unbalanced*.

Ties do not need to be declared [signed](nwvalue) in any special way - any tie with a negative value is treated as negative, any positive value as positive.

For each node, `nwbalance` generates the number of closed triads it belongs to, the number of those that are balanced, and the ratio of the two. Network-level counts and the overall balance ratio are returned in `r()`.

## Examples

```stata
. nwset, mat((0,1,1,-1\1,0,1,-1\1,1,0,1\-1,-1,1,0)) undirected labs(A,B,C,D)
. nwbalance

----------------------------------------
  Network name: network
----------------------------------------
    Closed triad: 4
    Balanced triad: 2
    Unbalanced triad: 2
```
Of the 4 triads in this network, *A-B-C* (all positive) and *A-B-D* (two negative ties) are balanced; *A-C-D* and *B-C-D* (one negative tie each) are not.

## Stored results

- **Scalars**
- **r(closed_triad)** --- number of closed triads
- **r(balanced_triad)** --- number of balanced closed triads
- **r(unbalanced_triad)** --- number of unbalanced closed triads
- **r(balance)** --- *balanced_triad* / *closed_triad*

## References

Cartwright, D., Harary, F. (1956). Structural balance: a generalization of Heider's theory. *Psychological Review* 63(5), 277-293.

## See also

- [nwtriads](nwtriads), [nwvalue](nwvalue)

---

*nwcommands version 3.21.0, 12 November 2026* ([check your installed version](nwversion))
