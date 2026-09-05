---
title: "nwdichotomize"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Dichotomize a network at a threshold (built on [nwrecode](nwrecode.md))"
---

# `nwdichotomize`

Dichotomize a network at a threshold (built on [nwrecode](nwrecode.md))

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

`nwdichotomize` converts a valued (weighted) network into a binary one: any dyad whose value is greater than or equal to `threshold()` becomes 1, every other dyad (including missing ties) becomes 0. It is a thin convenience wrapper around [nwrecode](nwrecode.md) - internally it is exactly equivalent to

- `. nwrecode` *netname* `(`*threshold*`/max=1) (min/max=0)`

- - given its own name specifically so the common "binarize at a cutoff" operation does not require
- knowing [nwrecode](nwrecode.md)'s own general recode-rule syntax. For anything beyond a single cutoff
- (multiple bands, missing-value handling, etc.), use [nwrecode](nwrecode.md) directly.

As with [nwrecode](nwrecode.md) (and following the package's general convention - see [the style guide](NWCOMMANDS_COMMAND_STYLE.md)'s "Output creation" section - for commands where in-place modification is the default), the network is dichotomized in place unless `generate()` or `prefix()` is specified, in which case the original is left untouched and the result is saved under a new name instead.

## Examples

Build a small valued trade network (export values between three countries), then dichotomize it at 100, in place:

```stata
. clear
. mata: M = (0,150,40 \ 90,0,220 \ 60,30,0)
. nwset, mat(M) name(trade) directed labs(A,B,C)
. nwdichotomize trade, threshold(100)
```
Same, but keep the original valued network and save the binary version under a new name:

```stata
. nwdichotomize trade, threshold(100) generate(trade_binary)
```
- last certified : 28 Aug 2026

## Supported network types

Binary: yes (a no-op - every value is already either 0 or 1, so `threshold(1)` leaves it unchanged). Directed: yes. Weighted: yes - this is its primary use case. Signed: not checked - a negative value below `threshold()` is treated the same as any other sub-threshold value. Two-mode: not checked directly, but inherits whatever [nwrecode](nwrecode.md)/[nwtoedge](nwtoedge.md) support for two-mode data.
