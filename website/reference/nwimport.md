---
title: "nwimport"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Import network"
---

# `nwimport`

Import network

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
| `xvars` | also generate Stata variables for the imported network (see [nwload](nwload.md)) |

## Description

Imports networks from popular network file formats. The command automatically recognizes whether networks are directed or undirected. However, options **forcedirected** and **forceundirected** can be used to override automatic detection.

- The following network formats are supported:

- [- Ucinet](nwimport.md)
- [- Pajek](nwimport.md)
- [- Raw adjacency matrix](nwimport.md)
- [- Raw edgelist](nwimport.md)
- [- Compressed edgelist](nwimport.md)
- [- GML](nwimport.md)

*`filename`* can also be a URL, so networks can be imported directly from the internet without downloading a local copy first, e.g.:

```stata
. nwimport "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop/data/edgelist_example.txt", type(edgelist)
```

## Supported network types

Binary: yes. Directed: yes - automatically detected from the source file unless overridden with **forcedirected**/**forceundirected**. Weighted: yes, where the source format itself carries tie values (e.g. Ucinet/Pajek matrices, weighted edgelists). Signed: yes, if the source file's own values are negative. Two-mode: yes, for the formats whose own file structure distinguishes row and column node sets (e.g. rectangular Ucinet/Pajek matrices); auto-detected the same way as any other [nwset](nwset.md)-created network.
