---
title: "nwrename"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Rename a network"
---

# `nwrename`

Rename a network

## Syntax

```stata
Rename single network
nwrename old_netname new_netname
Rename multiple networks
nwrename (old1 old2 ...) (new1 new2 ...)
```

## Description

`nwrename` changes the name of an existing network *old_netname* to *new_netname*; the content of the network remains unchanged.

## Examples

```stata
. nwwebuse florentine, nwclear

(2 networks)
--------------------
        flobusiness
        flomarriage

. nwds
flobusiness    flomarriage

. nwrename flobusiness business
. nwrename flomarriage marriage

. nwds
business    marriage
```

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes - renames the network object only; its content, including directed/valued/two-mode status, is completely unchanged.

## See also

- [nwname](nwname), `rename`

- last certified : 24 Aug 2026

---

*nwcommands version 3.9.1, 26 October 2026* ([check your installed version](nwversion))
