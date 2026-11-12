---
title: "nwimport"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Import a network from a Pajek, UCINET, GML or edge list file"
---

# `nwimport`

Import a network from a Pajek, UCINET, GML or edge list file

## Syntax

```stata
nwimport 
filename
, 
type(import_type[, type_sub])
[name(newnetname)
forcedirected
forceundirected
nwclear
clear
nwappend
xvars]
```

| | |
|---|---|
| `name(newnetname)` | name of the imported network; default = *filename* |
| `forcedirected` | force network to be directed |
| `forceundirected` | force network to be undirected |
| `nwclear` | clear all data and networks |
| `clear` | same as `nwclear` |
| `nwappend` | append to existing data |
| `xvars` | also generate Stata variables for the imported network (see [nwload](nwload)) |

## Description

Imports networks from popular network file formats. The command automatically recognizes whether networks are directed or undirected. However, options **forcedirected** and **forceundirected** can be used to override automatic detection.

The following network formats are supported:

- [- Ucinet](nwimport)
- [- Pajek](nwimport)
- [- Raw adjacency matrix](nwimport)
- [- Raw edgelist](nwimport)
- [- Compressed edgelist](nwimport)
- [- GML](nwimport)

*`filename`* can also be a URL, so networks can be imported directly from the internet without downloading a local copy first, e.g.:

```stata
. nwimport "https://nwcommands.org/examples/edgelist_example.txt", type(edgelist)
```

---

*nwcommands version 3.21.0, 12 November 2026* ([check your installed version](nwversion))
