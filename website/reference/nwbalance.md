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
generate(namelist)
reps(#)
seed(#)]
```

| | |
|---|---|
| `generate(namelist)` | Up to 3 names, for the per-node balance ratio, count of balanced triads, and count of closed triads a node belongs to; default = *_balance _baltriad _clotriad*; existing variables of these names are replaced |
| `reps(#)` | compare the share of balanced triads with # draws of random signs on the same ties; default 0 (no comparison) |
| `seed(#)` | random-number seed for `reps()` |

## Description

`nwbalance` evaluates a [network](netname)'s ties as signed (positive/negative) and tests every closed triad against Cartwright and Harary's (1956) strong structural balance criterion: a closed triad is *balanced* when the product of its three tie values is positive - equivalently, when it contains an even number (0 or 2) of negative ties ("the friend of my friend is my friend"; "the enemy of my enemy is my friend"). A triad with an odd number (1 or 3) of negative ties is *unbalanced*.

Ties do not need to be declared [signed](nwvalue) in any special way - any tie with a negative value is treated as negative, any positive value as positive.

For each node, `nwbalance` generates the number of closed triads it belongs to, the number of those that are balanced, and the ratio of the two. Network-level counts and the overall balance ratio are returned in `r()`.

## Random signs as a baseline

A share of balanced triads cannot be judged by itself: it depends on the share of ties that are positive. If each tie were positive with probability *p*, independently of the others, a closed triad would be balanced with probability (1 + (2*p* - 1)^3) / 2. With `reps(#)`, `nwbalance` draws # networks that keep every tie in its place and give each tie a positive sign with the observed share of positive ties as probability, independently of the other ties, and counts the balanced triads of each draw. It reports the observed share, the mean and standard deviation of the share over the draws, the share the formula gives, and the number of draws whose share is at least the observed one. With 500 draws, 0 of 500 means a p-value below about 0.002, not zero.

## Network types

**Directed:** a pair counts as tied when either direction has a tie; for a mutual dyad the sign of i->j is used. **Valued:** only the sign of each value is used. **Two-mode:** same as for the bipartite graph read as a one-mode network (no triangles: counts 0, balance missing). **Signed:** the purpose of the command. See [nwnetworktypes](nwnetworktypes).

## Limits

Closed triads are found from the stored ties (for every tied pair, the common neighbours), not by probing every pair of nodes. The enumeration is a kernel of the native plugin; a platform whose plugin does not have it uses Mata code, with the same results. Measured in Stata/BE, random valued network with 10 ties per node: 5,000 nodes 0.03 seconds with the plugin kernel (71 seconds with the Mata code).

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

. nwwebuse gahuku, nwclear
. nwbalance gahuku, reps(500) seed(1)
```
Of the 4 triads in this network, *A-B-C* (all positive) and *A-B-D* (two negative ties) are balanced; *A-C-D* and *B-C-D* (one negative tie each) are not.

## Stored results

- **Scalars**
- **r(closed_triad)** --- number of closed triads
- **r(balanced_triad)** --- number of balanced closed triads
- **r(unbalanced_triad)** --- number of unbalanced closed triads
- **r(balance)** --- *balanced_triad* / *closed_triad*
- **With `reps()`**
- **r(reps)** --- number of draws
- **r(p_positive)** --- share of the ties that are positive
- **r(null_mean)** --- mean share of balanced triads over the draws
- **r(null_sd)** --- standard deviation of that share over the draws
- **r(null_ge)** --- number of draws with a share at least the observed **r(balance)**
- **r(null_expected)** --- (1 + (2*p* - 1)^3) / 2 with *p* = **r(p_positive)**

## References

Cartwright, D., Harary, F. (1956). Structural balance: a generalization of Heider's theory. *Psychological Review* 63(5), 277-293.

## See also

- [nwtriads](nwtriads), [nwvalue](nwvalue)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
