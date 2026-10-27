---
title: "nwnoderename"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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

```stata
. nwclear
. nwrandom 4, prob(1) name(mynet)
. list _nwnode _nwinclude

   +--------------------+
   | _nwnode   _nwinc~e |
   |--------------------|
1. |      n1          1 |
2. |      n2          1 |
3. |      n3          1 |
4. |      n4          1 |
   +--------------------+

. nwnoderename mynet, old(n1) new(x1)
. list _nwnode _nwinclude

   +--------------------+
   | _nwnode   _nwinc~e |
   |--------------------|
1. |      x1          1 |
2. |      n2          1 |
3. |      n3          1 |
4. |      n4          1 |
5. |      n1          0 |
   +--------------------+
```

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes - renames a single node's own label only; ties, tie values, and mode assignment are completely unchanged.

## See also

- [nwrename](nwrename), [nwname](nwname)

- last certified : 24 Aug 2026

---

*nwcommands version 3.9.1, 26 October 2026* ([check your installed version](nwversion))
