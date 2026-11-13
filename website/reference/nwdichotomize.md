---
title: "nwdichotomize"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Dichotomize a network at a threshold"
---

# `nwdichotomize`

Dichotomize a network at a threshold

## Syntax

```stata
nwdichotomize
netlist
,
threshold(#)
[generate(newnetlist) prefix(str)]
```

| | |
|---|---|
| `threshold(#)` | cutoff value; dyads with a value **>= #** become 1, all others become 0 |
| `generate(newnetlist)` | save the dichotomized network(s) under new name(s); default is to replace the original network(s) in place |
| `prefix(str)` | generate new networks with *str* prefix, instead of replacing in place |

## Description

`nwdichotomize` converts a valued (weighted) network into a binary one: any dyad whose value is greater than or equal to `threshold()` becomes 1, every other dyad becomes 0 (a missing tie value stays missing, as with Stata's `recode` rule *min/max*). It is a thin convenience wrapper around [nwrecode](nwrecode) - internally it is exactly equivalent to

```stata
. nwrecode netname (threshold/max=1) (min/max=0)
```
It has its own name so that the common "binarize at a cutoff" operation does not require knowing [nwrecode](nwrecode)'s own general recode-rule syntax. For anything beyond a single cutoff (multiple bands, missing-value handling, etc.), use [nwrecode](nwrecode) directly.

As with [nwrecode](nwrecode) (and following the package's general convention for commands where in-place modification is the default), the network is dichotomized in place unless `generate()` or `prefix()` is specified, in which case the original is left untouched and the result is saved under a new name instead.

## Network types

**Directed:** yes. **Valued:** the purpose of the command; a 0/1 network is left unchanged by `threshold(1)`. **Two-mode:** yes - the flag, the modes and the level labels are kept. **Signed:** a negative value is treated as any other value below `threshold()`. See [nwnetworktypes](nwnetworktypes).

## Limits

See [nwrecode](nwrecode): 1,000 / 5,000 / 20,000 nodes in 0.03 / 0.07 / 0.3 seconds, random directed network with 10 ties per node.

## Examples

Build a small valued trade network (export values between three countries), then dichotomize it at 100, in place:

```stata
. clear
. mata: M = (0,150,40 \ 90,0,220 \ 60,30,0)
. nwset, mat(M) name(trade) directed labs(A,B,C)
. nwdichotomize trade, threshold(100)
```
Instead of the in-place call, keep the original valued network and save the binary version under a new name:

```stata
. nwdichotomize trade, threshold(100) generate(trade_binary)
```

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
