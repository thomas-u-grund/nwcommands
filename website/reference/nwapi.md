---
title: "nwapi"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Mata functions to read networks"
---

# `nwapi`

Mata functions to read networks

## Syntax

```stata
nwapi_version()
nwapi_count()
nwapi_names()
nwapi_exists([name])
nwapi_current()
nwapi_nodes([name])
nwapi_ties([name])
nwapi_directed([name])
nwapi_valued([name])
nwapi_twomode([name])
nwapi_selfloops([name])
nwapi_temporal([name])
nwapi_nodelabels([name])
nwapi_modes([name])
nwapi_matrix([name])
nwapi_edgelist([name])
nwapi_outdegree([name])
nwapi_indegree([name])
nwapi_neighbors(name, node)
nwapi_inneighbors(name, node)
nwapi_nodeid(name, label)
```

## Description

The functions give Mata programs, including those that you write for your own research, a small and stable way to read the networks that nwcommands holds in memory: how many networks there are, how large they are and of which kind, and their ties, as a matrix, as an edge list, as degrees or as the neighbors of a node. They need no knowledge of how nwcommands stores networks, never return anything that is linked to the stored network (every result is a copy), and never change a network, the list of networks or the current network. To create a network from a Mata matrix, use [nwset](nwset) with option `mat()`; to give a result back, store it in a Stata variable with `st_store()` or in a matrix with `st_matrix()`.

*name* is a string scalar, the exact name of a network; `""` (or no argument) is the current network. *node* is a node number (a whole number, real) or a node label (string). *label* is a string scalar. The square brackets in the syntax diagram mean that *name* can be left out.

For writing whole commands see [nwprogramming](nwprogramming). [nwtomata](nwtomata) is the command-line way to copy a network into a Mata matrix.

## Stability

The functions listed here are the programming interface of nwcommands for Mata. Within one major version of nwcommands (3.x) their names, arguments, the type and the orientation of their results (rows and columns), and their return codes do not change. New functions can be added in a minor version. A function that is to be removed is announced as deprecated in the help file and in the release notes at least one minor version ahead; it still works until the next major version. An incompatible change, which comes only with a new major version, raises `nwapi_version()`.

Nothing else in the Mata library of nwcommands is part of this interface: the classes that hold the networks and all other functions can change in any release without notice. Do not use them in code that has to keep working.

`nwapi_version()` returns the generation of the interface as a whole number (`1` for nwcommands 3.x); test it in a program that needs the functions: `assert(nwapi_version() >= 1)`. The functions of this help file exist from nwcommands 3.24 on; an older installation does not know them (Mata stops with r(3499), "function not found"). [nwversion](nwversion) shows the version of the package.

## Conventions

**Network names.** A name must match a network exactly (upper and lower case, no abbreviation, no wildcards). Unlike the commands, the functions do not accept abbreviated names or lists of networks. `""` or no argument is the current network (`nwapi_current()`); `nwapi_neighbors()`, `nwapi_inneighbors()` and `nwapi_nodeid()` need the name as their first argument and take `""` for the current network.

**Nodes.** Nodes are numbered 1 to `nwapi_nodes()` in the order of the node list; node *i* is observation *i* of the data after `_nwdatasync`. A function that takes a node accepts the number or the label. If two nodes have the same label, the label stands for the first of them.

**Two-mode networks.** A two-mode network is one list of nodes, first the nodes of the first mode, then those of the second; `nwapi_modes()` gives the mode of each node. Its matrix has the size of both modes together, and dyads inside a mode, where no tie can exist, are 0.

**Copies.** Every result is a copy: changing it does not change the network.

**Orientation.** Vectors with one value per node or per network are column vectors; a matrix has the senders in its rows and the receivers in its columns.

## The functions

*The collection*

- **`nwapi_version()`** --- real scalar: the generation of the interface, 1 in nwcommands 3.x
- **`nwapi_count()`** --- real scalar: the number of networks in memory (0 if none)
- **`nwapi_names()`** --- string colvector: the names of the networks, in the order in which they were created (`0 x 1` if none)
- **`nwapi_exists(`*name*`)`** --- real scalar: 1 if a network of this name exists, else 0; `nwapi_exists()` or `nwapi_exists("")`: 1 if there is any network
- **`nwapi_current()`** --- string scalar: the name of the current network (error 482 if there is no network)

*Properties of a network*

- **`nwapi_nodes()`** --- real scalar: the number of nodes
- **`nwapi_ties()`** --- real scalar: the number of ties; the arcs of a directed network, the edges of an undirected network (a tie between two nodes counts once, and a self-loop counts once)
- **`nwapi_directed()`** --- real scalar: 1 if the network is directed
- **`nwapi_valued()`** --- real scalar: 1 if the ties have values
- **`nwapi_twomode()`** --- real scalar: 1 if the network is two-mode
- **`nwapi_selfloops()`** --- real scalar: 1 if ties from a node to itself are allowed
- **`nwapi_temporal()`** --- real scalar: 1 if the network was declared temporal (snapshots, intervals or events); the times themselves are not read by this interface
- **`nwapi_nodelabels()`** --- string colvector: the node labels, one row per node
- **`nwapi_modes()`** --- real colvector: the mode (1 or 2) of every node; all 1 in a one-mode network

*Ties*

- **`nwapi_matrix()`** --- real matrix, *n* x *n*: the adjacency matrix, see below
- **`nwapi_edgelist()`** --- real matrix, *m* x 3: sender, receiver and value of every tie, see below
- **`nwapi_outdegree()`** --- real colvector, *n* x 1: the number of ties each node sends (a self-loop counts once)
- **`nwapi_indegree()`** --- real colvector, *n* x 1: the number of ties each node receives; in an undirected network the same as the outdegree
- **`nwapi_neighbors(`*name*`,` *node*`)`** --- real colvector: the numbers of the nodes that *node* sends ties to, in ascending order (`0 x 1` if none); in an undirected network all neighbors
- **`nwapi_inneighbors(`*name*`,` *node*`)`** --- real colvector: the numbers of the nodes that send ties to *node*, in ascending order; in an undirected network the same as `nwapi_neighbors()`
- **`nwapi_nodeid(`*name*`,` *label*`)`** --- real scalar: the number of the node with this label (error 485 if there is none)

In a network with values, the degrees count the ties, not the values; sum the third column of `nwapi_edgelist()` or the rows of `nwapi_matrix()` for the sum of the values. A tie with the value 0 is not a tie.

**The matrix.** `nwapi_matrix()` holds the value of the tie from row node to column node (1 in a network without values) and 0 where there is no tie. For an undirected network it is symmetric. It contains no missing values, so that `A*A` and `rowsum(A)` work. [nwtomata](nwtomata) returns the same matrix but with missing values on the diagonal of a network without self-loops (and between the nodes of one mode of a two-mode network); the functions here put 0 in those cells. A network of more than 20,000 nodes is not turned into a matrix: the function stops with error 484, because the matrix would need more than 3 GB of memory; use the edge list, the neighbors or the degrees, which need memory in proportion to the number of ties only.

**The edge list.** `nwapi_edgelist()` has one row for each tie, ordered by sender and then by receiver. In an undirected network a tie is listed once, with the smaller node number first (so the rows are the upper triangle of the matrix); in a directed network every arc is listed. A network without ties gives a matrix of 0 rows and 3 columns. It is the right way to read large networks.

## Errors

The functions check their arguments and stop with the return codes of [nwerrorcodes](nwerrorcodes) and a message that says what is wrong:

- **482** --- no network of this name (or no network at all, for `""`)
- **485** --- no node with this label, or a node number below 1 or above the number of nodes
- **198** --- *node* is not a single whole number or a single label (a missing value, a fraction, a vector, a number that is not real)
- **484** --- `nwapi_matrix()` of a network with more than 20,000 nodes

Use `capture` to catch them: `capture mata: nwapi_nodes("friends")` followed by `if _rc == 482 ...`. Mata itself stops with r(3200) or r(3250) if an argument has the wrong size or type (a vector for *name*, a number for *label*).

## Examples

- Use the functions in a Mata block, here the Florentine marriage network

```stata
. nwwebuse florentine, nwclear
. mata:
: nwapi_names()'
: nwapi_nodes("flomarriage"), nwapi_ties("flomarriage")
: nwapi_directed("flomarriage")
: end
```
- Neighbors and degree of a family by label

```stata
. mata:
: nb = nwapi_neighbors("flomarriage", "medici")
: lab = nwapi_nodelabels("flomarriage")
: lab[nb]'
: deg = nwapi_outdegree("flomarriage")
: deg[nwapi_nodeid("flomarriage", "medici")]
: end
```
- The density of a network, and the number of triangles from the matrix

```stata
. mata:
: n = nwapi_nodes("flomarriage")
: nwapi_ties("flomarriage") / (n*(n-1)/2)
: A = nwapi_matrix("flomarriage")
: trace(A*A*A) / 6
: end
```
- Catch an error

```stata
. capture mata: nwapi_nodes("nonetwork")
. display _rc
```

## See also

[nwprogramming](nwprogramming), [nwtomata](nwtomata), [nwset](nwset), [nwerrorcodes](nwerrorcodes), [nwversion](nwversion)

---

*nwcommands version 3.23.0, 13 November 2026* ([check your installed version](nwversion))
