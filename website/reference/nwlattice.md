---
title: "nwlattice"
parent: "Command reference"
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
| `name`(*[newnetname](newnetname)*) | name of the new network |
| `vars`(*`newvarlist`*) | new variables that are used for the network |
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
```
```stata
. nwclear
. nwlattice 4 4, xwrap ywrap
. nwplot, layout(grid) label(_nodeid)
```

## Supported network types

Binary: yes (only). Directed: yes, via `undirected` (default is directed). Weighted: not applicable - no `weights()` option; generates a purely structural lattice. Signed: not applicable. Two-mode: not applicable - this generator always produces a one-mode network.

## Stored results

- **nwlattice** stores the following in **r()**:

**Macros**

- **r(netlist)** list of new networks

## See also

- [nwpref](nwpref), [nwrandom](nwrandom), [nwring](nwring), [nwsmall](nwsmall)
