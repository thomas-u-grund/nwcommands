---
title: "nwtostata"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Copy a Mata matrix into Stata variables"
---

# `nwtostata`

Copy a Mata matrix into Stata variables

## Syntax

```stata
nwtostata
,
mat(matamatrix)
(gen(namelist) | stub(string))
```

| | |
|---|---|
| `mat(matamatrix)` | name of the Mata matrix to copy into Stata variables |
| `gen(namelist)` | one new Stata variable name per column of *matamatrix* |
| `stub(string)` | generate columns as *stub*`1`, *stub*`2`, ... instead of naming them individually |

## Description

`nwtostata` is the reverse of [nwtomata](nwtomata): it copies an existing Mata matrix *matamatrix* into new Stata variables, one column per variable, one row per observation (creating additional observations if the dataset does not already have enough). Exactly one of `gen()` or `stub()` must be specified - `gen()` names each new variable individually (one name per column of *matamatrix*); `stub()` instead generates however many *stub*`1`, *stub*`2`, ... columns are needed to hold every column of *matamatrix*.

This is a low-level utility for programmers moving data between Mata and Stata directly; ordinary use of the package does not need it - see [nwtomata](nwtomata) / [nwload](nwload) for the normal way to bring a network's own data into Stata.

## Examples

```stata
. mata: m = (1,2 \ 3,4 \ 5,6)
. nwtostata, mat(m) gen(a b)
. list

. mata: m = (1,2 \ 3,4 \ 5,6)
. nwtostata, mat(m) stub(col)
. list
```

## Stored results

- **Scalars**
- **r(rows)** --- number of rows of *matamatrix*
- **r(cols)** --- number of columns of *matamatrix* (with `stub()`)

## See also

- [nwtomata](nwtomata), [nwload](nwload)

---

*nwcommands version 3.20.1, 12 November 2026* ([check your installed version](nwversion))
