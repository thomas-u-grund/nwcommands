---
title: "nwimport"
parent: "Core command reference"
grand_parent: "Packages and reference"
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
| `nwclear` | replace the data and the networks in memory with the imported ones |
| `clear` | same as `nwclear` |
| `nwappend` | add the network to those in memory |
| `xvars` | also generate Stata variables for the imported network (see [nwload](nwload)) |

## Description

Imports networks from popular network file formats. A Pajek file with ties in an **Arcs* (or **Arcslist*) section and a GML file with `directed 1` give a directed network, also when every tie is reciprocated; Pajek **Edges* (or **Edgeslist*) and GML `directed 0` give an undirected one. UCINET DL files, matrices, edge lists, Pajek **Matrix* and GML files without `directed` do not say: a network with a symmetric matrix is then undirected, any other directed. For matrices and edge lists, option **directed** (on its own or inside `type()`) declares the network directed. **forcedirected** and **forceundirected** override this.

**Data in memory.** A failed import changes nothing: data, networks and the current network stay as they are, also with `nwclear` or `clear`. With networks in memory, `nwappend` or `nwclear` is required. A successful import leaves the data in memory unchanged, with two exceptions. With `nwclear` or `clear` the data and the networks are replaced. If there are no data (no variables and no observations), the data set holds what the file gives: the node names (`_nwnode`) of an edge list, or the matrix columns and node attributes of a matrix. `xvars` adds the variables of the network to the data.

**Node names** cannot hold commas or double quotes. In names read from a file, commas become blanks and double quotes apostrophes, with a suffix _2, _3, ... where two names become equal; a note says so. Text files in UTF-8 are read as they are. For **type(edgelist)**, a byte-order mark is skipped, UTF-16 files with a byte-order mark are converted, and a text that is not valid UTF-8 is read as Windows-1252 (which covers Latin-1). Check accented letters in the node names of other imports, and convert a file in another encoding first (see `unicode translate`).

**Self-loops** (ties of a node with itself) in Pajek, GML, UCINET and edge list files are imported, and the network allows self-loops. The diagonal of a file read with `type(matrix)` is ignored, and so is a node listed with itself in a compressed edge list.

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

`nwimport` can import the most common Ucinet DL format types: *fullmatrix, lowerhalf, edgelist1, nodelist1*. It also supports multiple networks (*nm > 0), diagonal = absent, labels:, matrix labels:, level labels:, labels embedded, row labels embedded, col labels embedded*. Labels are separated by commas or blanks; a label that holds a blank, comma or semicolon is written in double quotes. A DL file does not say whether a network is directed: specify `forcedirected` to keep a directed network whose ties are all reciprocated as directed. A rectangular matrix (nr rows, nc columns, format fullmatrix, with row labels and col labels) is read as a two-mode network, the rows being the first mode. For a detailed description of the Ucinet .dl file format see [here](https://docs.gephi.org/desktop/User_Manual/Import/UCINET_DL_Format/) or the [Ucinet manual](https://pages.uoregon.edu/vburris/hc431/Ucinet_Guide.pdf).

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

`nwimport` can import the most common Pajek .net formats: **arcs, *edges, *arcslist, *edgeslist, *matrix*, with vertex labels read from the file's own **Vertices* block. **Matrix* follows a **Vertices n* line and holds n lines with n numbers each (a value other than 0 is a tie from the node of the line to the node of the column); it is not read for two-mode networks. **Vertices n n1* declares a two-mode network. For a detailed description of the Pajek .net file format see [here](https://docs.gephi.org/desktop/User_Manual/Import/Pajek_NET_Format/).

## Import raw adjacency matrix

This imports networks that are in raw matrix format, from a text file or an Excel file. In a text file the delimiters "tab" ";" "," and " " are recognised (or give `delimiter()`); in a file separated by semicolons or tabs a decimal comma (1,5) is read. Row and/or column names can be included; the same rules apply to text and Excel files. When data has already been opened/entered to Stata, [nwset](nwset) declares data as network data.

**Example 1:** 0 1 1 0 1 0 0 0 0 0 0 1 0 1 0 0

**Example 2:** thomas,peter,susan,kim 0,1,1,0 1,0,0,0 0,0,0,1 0,1,0,0

Names in the first row (Example 2), in the first column, or in both are recognised without suboptions:

- thomas,0,1,1,0
- peter,1,0,0,0
- susan,0,0,0,1
- kim,0,1,0,0

A first column or first row that holds text where numbers are expected holds names. Numbers are taken as names when the first row and the first column hold the same numbers and the corner cell is empty or text, or when there is only a first row of distinct numbers (not all 0 or 1) and one line more than columns. Otherwise, say so with `type(matrix, rownames)`, `type(matrix, colnames)` or both. If both the first row and the first column hold names, the nodes are named after the first column; the same names in a different order are refused.

Cells of the matrix must be numbers; a blank cell, `.` or `NA` is a missing tie value. Anything else stops the import with a message, as does a matrix with fewer columns than rows.

The file can also contain node attributes: when there are more columns than rows, all further columns are attributes, numeric or text. They are in the data after an import into an empty data set or with `nwclear` (*Data in memory* in the Description).

**Example 3:** thomas,peter,susan,kim, sex 0,1,1,0, male 1,0,0,0, male 0,0,0,1, female 0,1,0,0, male

## Import raw edgelist

This imports networks in [raw edgelist format](nwfromedge). Data can already be in Stata-dta format. Otherwise, delimiters "tab" "," ";" and " " are allowed. When two columns are given a non-valued network is loaded, when three columns are given a valued network is loaded. In case edgelist data has already been entered/opened in Stata, [nwfromedge](nwfromedge) generates a network. Node labels can be embedded in the edgelist. A line with a node and an empty second field declares a node without a tie from that line; a line with the same node twice (and a value other than 0) is a self-loop.

When the two columns hold numbers, the nodes are named **n** followed by the number (node 10 becomes **n10**), as [nwfromedge](nwfromedge) does. This also applies to an edge list written by [nwexport](nwexport) from a network whose node names are numbers.

**Header line.** In a text or Excel file, the first line is read as a header, not as a tie, if its first two fields are (in any case) *from to*, *source target*, *ego alter*, *sender receiver*, *sender recipient*, *node1 node2*, *id1 id2*, *src dst* or *tail head* and neither word occurs again in these two columns, or if the third field is a word while all other lines hold numbers (or nothing) there. A text file with numbers as node names can also have its column names recognised as such. `type(edgelist, noheader)` reads the first line of a text file as a tie.

The list does not say whether a network is directed. A list with each tie of an undirected network once, as [nwexport](nwexport) writes it, is read as directed unless `forceundirected` is specified; a list in which every tie is reciprocated is read as undirected unless `directed` or `forcedirected` is specified. Nodes without ties are not in a list written by [nwexport](nwexport).

**Example 1:** 1 2 1 4 2 4 4 3

**Example 2:** peter,thomas,1 thomas,susan,4 susan,thomas,3 geoff,john,2

**Edge lists with times.** The options `eventtime`, `time` and `interval` read a list that holds times, as written by [nwexport](nwexport) for a temporal network: *ego alter* [*value*] *time*, or *ego alter* [*value*] *start end* for `interval`; the value column is there when the list has one column more. The columns must be numeric where they hold times and values. The network is declared as [nwset](nwset) declares it with `eventtime()`, `time()` or `interval()`, one row per event or observation, and keeps the direction given by `directed` or `undirected` (the direction is not detected for a list with times). A list with a value and a time has four columns and is refused without one of the options.

```stata
. nwimport calls.txt, type(edgelist, eventtime directed) name(calls)
```

## Import compressed edgelist

This imports networks in compressed edgelist format. As delimiter "," is allowed.

**Example 1:** AS,MI,NY,TX TX,CA IL,AL,SD AL,MI,CA,NY

**Example 2:** peter,thomas,mathilde,tim thomas,susan susan geoff,john,michael

## Network types

**Directed:** as the file declares it, otherwise detected from the ties; `forcedirected` / `forceundirected` override it. **Valued:** tie values are read where the format has them. **Two-mode:** yes - the formats written by [nwexport](nwexport) come back as two-mode networks with level labels (not UCINET); a tie inside a mode is refused (error 459). **Signed:** yes. **Temporal:** edge lists with times (see [edge lists with times](nwimport)). See [nwnetworktypes](nwnetworktypes).

---

*nwcommands version 3.39.0, 26 November 2026* ([check your installed version](nwversion))
