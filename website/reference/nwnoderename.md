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

`nwnoderename` changes the name of a single node in a network. When a node with name *old_nwnode* is found in *netname*, it is replaced with *new_nwnode*. If *old_nwnode* is not found or *new_nwnode* is not a valid name, the command stops with an error (r(198)) and the network is not changed.

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

## Stored results

- **Scalars**
- **r(success)** --- 1 if the node was renamed, 0 if *old_nwnode* was not found or *new_nwnode* is not a valid name

## See also

- [nwrename](nwrename), [nwname](nwname)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
