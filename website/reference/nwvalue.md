---
title: "nwvalue"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Returns a tie value"
---

# `nwvalue`

Returns a tie value

## Syntax

```stata
nwvalue 
[netname][,
ego(nodename)
alter(nodename)
egoid(integer)
alterid(integer)]
```

## Description

The command returns the scalar *r(value)* with the value of the tie between the nodes *ego* and *alter* if those nodes exists. It also returns the names of those nodes when ids are used. Either the option pair **ego(), alter()** or **egoid(), alterid()** need to be specified.

## Examples

```stata
. nwwebuse florentine
. nwvalue flobusiness, ego("medici") alter("pazzi")
. nwvalue flobusiness, egoid(2) alterid(9)
. return list
```

## Supported network types

Binary: yes. Directed: yes - the raw stored (row=ego, column=alter) cell is returned exactly as stored, respecting direction, never symmetrized. Weighted: yes, natively - returns the tie's own raw stored value. Signed: not checked; a negative value is returned as-is with no special handling. Two-mode: not checked, but not expected to need any - a direct single-cell lookup by node identity.

## See also

- [nwreplace](nwreplace)
- last certified : 24 Aug 2026
