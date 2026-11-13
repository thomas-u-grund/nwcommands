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

## Import Ucinet DL format

`nwimport` can import the most common Ucinet DL format types: *fullmatrix, lowerhalf, edgelist1, nodelist1*. It also supports multiple networks (*nm > 0), diagonal = absent, labels:, matrix labels:, level labels:, labels embedded, row labels embedded, col labels embedded*. A rectangular matrix (nr rows, nc columns, format fullmatrix, with row labels and col labels) is read as a two-mode network, the rows being the first mode. For a detailed description of the Ucinet .dl file format see [here](https://docs.gephi.org/desktop/User_Manual/Import/UCINET_DL_Format/) or the [Ucinet manual](https://pages.uoregon.edu/vburris/hc431/Ucinet_Guide.pdf).

**Example 1:** dl n=4 format=fullmatrix data: 0 1 1 0 1 0 1 1 1 1 0 0 0 1 0 0

**Example 2:** dl n = 4, nm = 2 labels: GroupA,GroupB,GroupC,GroupD matrix labels: Marriage,Business data: 0 1 0 1 1 0 0 0 0 0 1 0 1 0 0 1

- 0 1 1 1
- 1 0 0 0
- 1 0 0 1
- 1 0 1 0

**Example 3:** dl n = 4 format = lowerhalf labels: Sanders,Skvoretz S.Smith,T.Smith data: 2 1 2 1 1 2 0 1 0 2

**Example 4:** DL n=5 format = edgelist1 labels: george, sally, jim, billy, jane data: 1 2 1 3 2 3 3 1 4 3

**Example 5:** DL n=5 format = edgelist1 labels embedded: data: george sally george jim sally jim billy george jane jim

## Import Pajek .net format

`nwimport` can import the most common Pajek .net formats: **arcs, *edges, *arcslist, *edgeslist, *matrix*, with vertex labels read from the file's own **Vertices* block. Two-mode networks are not supported. For a detailed description of the Pajek .net file format see [here](https://docs.gephi.org/desktop/User_Manual/Import/Pajek_NET_Format/).

## Import raw adjacency matrix

This imports networks that are in raw matrix format. Data can be saved as .txt, .xls or anything else. As delimiters "tab" "," ";" and " " are allowed. Furthermore, row and/or column names can be included as well. This import option can be used to load networks from e.g. Excel. When data has already been opened/entered to Stata, [nwset](nwset) declares data as network data.

**Example 1:** 0 1 1 0 1 0 0 0 0 0 0 1 0 1 0 0

**Example 2:** thomas,peter,susan,kim 0,1,1,0 1,0,0,0 0,0,0,1 0,1,0,0

Notice that the command recognises when node names are given in the first row (Example 2 above) - **type(matrix)** with no suboptions already produces the correct 4-node network from that file, since the header row becomes each node's own variable name and `nwimport` labels nodes from variable names by default; **rownames**/**colnames** are *not* needed for this shape and should be omitted here.

**rownames**/**colnames** are for the opposite shape instead: a raw matrix with node names given as an explicit first *column* of text (no header row at all), e.g.

- thomas,0,1,1,0
- peter,1,0,0,0
- susan,0,0,0,1
- kim,0,1,0,0

which requires **type(matrix, rownames)** to read that first column as node labels rather than data.

Furthermore, the raw dataset can also contain additional attributes. When there are more variables than cases, all remaining variables are treated as attributes.

**Example 2:** thomas,peter,susan,kim, sex 0,1,1,0, male 1,0,0,0, male 0,0,0,1, female 0,1,0,0, male

## Import raw edgelist

This imports networks in [raw edgelist format](nwfromedge). Data can already be in Stata-dta format. Otherwise, delimiters "tab" "," ";" and " " are allowed. When two columns are given a non-valued network is loaded, when three columns are given a valued network is loaded. In case edgelist data has already been entered/opened in Stata, [nwfromedge](nwfromedge) generates a network. Node labels can be embedded in the edgelist.

**Example 1:** 1 2 1 4 2 4 4 3

**Example 2:** peter,thomas,1 thomas,susan,4 susan,thomas3 geoff,john,2

## Import compressed edgelist

This imports networks in compressed edgelist format. As delimiter "," is allowed.

**Example 1:** AS,MI,NY,TX TX,CA IL,AL,SD AL,MI,CA,NY

**Example 2:** peter,thomas,mathilde,tim thomas,susan susan geoff,john,michael

## Network types

**Directed:** detected from the file; `forcedirected` / `forceundirected` override it. **Valued:** tie values are read where the format has them. **Two-mode:** yes - the formats written by [nwexport](nwexport) come back as two-mode networks with level labels (not UCINET); a tie inside a mode is refused (error 459). **Signed:** yes. See [nwnetworktypes](nwnetworktypes).

---

*nwcommands version 3.23.0, 13 November 2026* ([check your installed version](nwversion))
