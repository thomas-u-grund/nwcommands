---
title: "nwlattice"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Generate a lattice network"
---

# `nwlattice`

Generate a lattice network

## Syntax

```stata
nwlattice
 cols rows
,
[undirected
xwrap
ywrap
name(newnetname)
vars(newvarlist)
stub(string)
labs(lab1 lab2 ...)
xvars
ntimes(int)]
```

| | |
|---|---|
| *`cols`* | number of columns in lattice; first positional argument |
| *`rows`* | number of rows in lattice; default = 1 if omitted |
| `xwrap` | wrap horizontally |
| `ywrap` | wrap vertically |
| `undirected` | generate an undirected network; default = directed |
| `name`(*[newnetname](newnetname)*) | name of the new network; default = *lattice* |
| `vars`(*`newvarlist`*) | new variables that are used for the network |
| `stub`(*string*) | stub of the variable names when `vars()` does not give one name per node; default = *lattice* |
| `labs`(*lab1 lab2 ...*) | node labels |
| `xvars` | generate Stata variables for the network |
| `ntimes(int)` | number of networks to be generated; default = 1 |
| `noreplace` | reserved; currently a no-op - the create/replace collision guard on `name()` already applies regardless |

## Description

`nwlattice` generates a lattice network. Each node is connected to maximally four other nodes. With options *xwrap* and *ywrap* each node is connected to exactly four other nodes.

## Examples

```stata
. nwclear
. nwlattice 4 4
. nwplot, label(_nodeid)

. nwclear
. nwlattice 4 4, xwrap ywrap
. nwplot, layout(grid) label(_nodeid)
```

## Stored results

- **nwlattice** stores the following in **r()**:

- **Macros**
- **r(netlist)** --- list of new networks

## See also

- [nwpref](nwpref), [nwrandom](nwrandom), [nwring](nwring), [nwsmall](nwsmall)

---

*nwcommands version 3.21.0, 12 November 2026* ([check your installed version](nwversion))
