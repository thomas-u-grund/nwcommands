---
title: "nwvalue"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Return a tie value"
---

# `nwvalue`

Return a tie value

## Syntax

```stata
nwvalue 
[netname][,
ego(nodename)
alter(nodename)
egoid(integer)
alterid(integer)]
nwvalue
netname[egoid,alterid]
```

## Description

The command returns the scalar *r(value)* with the value of the tie between the nodes *ego* and *alter* if those nodes exists. It also returns the names of those nodes when ids are used. Either the option pair **ego(), alter()** or **egoid(), alterid()** need to be specified.

## Examples

```stata
. nwwebuse florentine
. nwvalue flobusiness, ego("medici") alter("pazzi")
. nwvalue flobusiness, egoid(2) alterid(9)
. nwvalue flobusiness[2,9]
. return list
```

## Stored results

- **Scalars**
- **r(value)** --- value of the tie from ego to alter
- **r(ego_id)** --- position of ego in the network
- **r(alter_id)** --- position of alter in the network
- **r(ego_valid)** --- 1 if ego exists (with `ego()` and `alter()`)
- **r(alter_valid)** --- 1 if alter exists (with `ego()` and `alter()`)

- **Macros**
- **r(ego)** --- name of ego
- **r(alter)** --- name of alter

## See also

- [nwreplace](nwreplace)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
