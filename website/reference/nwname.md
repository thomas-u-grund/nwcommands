---
title: "nwname"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Obtain and change meta-information of a network"
---

# `nwname`

Obtain and change meta-information of a network

## Syntax

```stata
nwname 
[netname]
[,id(int)
newname(newnetname)
newtitle(string)
newdirected(boolean)
new2mode(boolean)
newvalued(boolean)
newselfloop(boolean)
newlabsfromvar(varname)
newcaption(string)
newprovenance(string)
newmodes(string)
newmode1desc(string)
newmode2desc(string)
]
```

| | |
|---|---|
| `id(int)` | network ID |
| `newname`([newnetname](newnetname.md)) | new name of the network |
| `newtitle(string)` | new title of the network |
| `newdirected`(boolean) | force change: directed = *true*, not directed = *false* |
| `new2mode`(boolean) | force change: twomode = *true*, not twomode = *false* |
| `newvalued`(boolean) | force change: valued = *true*, unvalued = *false* |
| `newselfloop`(boolean) | force change: selfloops = *true*, no selfloops = *false* |
| `newlabsfromvar(varname)` | new node labels (saved in Stata variable) |
| `newcaption(string)` | new caption/description text for the network |
| `newprovenance(string)` | new provenance/source note for the network |
| `newmodes(string)` | new mode assignment for a two-mode network's own nodes (see [introduction to two-mode networks](nw2set.md)); an empty value is a deliberate no-op |
| `newmode1desc(string)` | new description of mode 1 (two-mode networks) |
| `newmode2desc(string)` | new description of mode 2 (two-mode networks) |

## Description

`nwname` obtains and changes the meta-information of a network.

## Examples

This loads the Florentine data and returns various information about the *flobusiness* network.

```stata
. nwwebuse florentine
. nwname flobusiness
. return list
```
This changes the name of the network *flobusiness* into *flob*. This could also be achieved with [nwrename](nwrename.md).

```stata
. nwname flobusiness, newname(flob)
. return list
```

## Supported network types

Not applicable in the usual sense - this command reports and *sets* a network's own directed/valued/two-mode/self-loop status and other metadata directly; it is the mechanism by which those properties are themselves declared, not something whose behavior varies by them.

## Stored results

- **nwname** stores the following in **r()**:

**Scalars**

- **r(id)** internal ID of the network
- **r(nodes)** number of nodes in the network
- **r(nodes1)** number of mode-1 nodes (two-mode networks only)
- **r(nodes2)** number of mode-2 nodes (two-mode networks only)
- **r(selfloops)** number of self-loops
- **r(missing_edges)** number of missing (undefined) dyads

**Macros**

- **r(netname)** name of the network
- **r(title)** title/label of the network
- **r(caption)** caption/description text, if set
- **r(provenance)** provenance/source note, if set
- **r(directed)** **true**/**false**
- **r(valued)** **true**/**false**
- **r(mode2)** **true**/**false** - whether the network is two-mode
- **r(selfloop)** **true**/**false** - whether the network permits self-loops
- **r(temporal)** **true**/**false** - whether the network is temporal
- **r(temporaltype)** temporal storage type, if **r(temporal)** is **true**
- **r(timevar)**/**r(startvar)**/**r(endvar)**/**r(eventtimevar)** the underlying temporal variable name(s) actually used, depending on **r(temporaltype)**
- **r(labs)** comma-separated node labels
- **r(vars)** Stata variable names used to represent the network
- **r(modes)** mode assignment string for a two-mode network's own nodes
- **r(mode1desc)** description of mode 1 (two-mode networks only)
- **r(mode2desc)** description of mode 2 (two-mode networks only)

## See also

- [nwsummarize](nwsummarize.md), [nwset](nwset.md), [nwload](nwload.md)
- last certified : 24 Aug 2026
