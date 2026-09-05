---
title: "nwnoderename"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Rename a single node in a network"
---

# `nwnoderename`

Rename a single node in a network

## Syntax

```stata
nwnoderename 
[netname]
,
old(old_nwnode)
new(new_nwnode)
```

## Description

`nwnoderename` changes the name of a single node in a network. When a node with name *old_nwnode* is found in *netname*, it is replaced with *new_nwnode*.

## Examples

- . nwclear
- . nwrandom 4, prob(1) name(mynet)
- . list _nwnode _nwinclude
- hline 9c -hline 10
- c | _nwnode _nwinc~e c |
- hline 9c -hline 10
- 1. c | n1 1 c |
- 2. c | n2 1 c |
- 3. c | n3 1 c |
- 4. c | n4 1 c |
- hline 9c -hline 10

- . nwnoderename mynet, old(n1) new(x1)
- . list _nwnode _nwinclude
- hline 9c -hline 10
- c | _nwnode _nwinc~e c |
- hline 9c -hline 10
- 1. c | x1 1 c |
- 2. c | n2 1 c |
- 3. c | n3 1 c |
- 4. c | n4 1 c |
- 5. c | n1 0 c |
- hline 9c -hline 10

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes - renames a single node's own label only; ties, tie values, and mode assignment are completely unchanged.

## See also

- [nwrename](nwrename.md), [nwname](nwname.md)

- last certified : 24 Aug 2026
