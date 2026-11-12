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

## See also

- [nwname](nwname), `rename`

---

*nwcommands version 3.21.0, 12 November 2026* ([check your installed version](nwversion))
