---
title: "nwregular"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Classes of regularly equivalent nodes"
---

# `nwregular`

Classes of regularly equivalent nodes

## Syntax

```stata
nwregular [netname], gen:erate(newvar) [replace silent]
```

| | |
|---|---|
| `gen:erate(newvar)` | variable for the class of each node; required |
| `replace` | overwrite an existing variable |
| `silent` | do not show the table of classes |

## Description

`nwregular` finds the classes of regularly equivalent nodes of a network (the maximal regular equivalence). Two nodes are regularly equivalent if, whenever one of them has a tie to some node, the other has a tie to a node of the same class, and the same holds for the ties they receive (White and Reitz 1983). Unlike structural equivalence ([nwdissimilar](nwdissimilar), [nwconcor](nwconcor), [nwhierarchy](nwhierarchy)), regular equivalence does not require the same contacts, only the same kind of contacts: two team leaders who are each asked by their own juniors and each ask the same head are regularly but not structurally equivalent.

The classes are found step by step (CATREGE for binary data; Borgatti and Everett 1993): all nodes start in one class; a class is split whenever two of its members differ in the set of classes they send ties to or receive ties from; this is repeated until no class splits. Tie values are ignored (any nonzero value is a tie), and so are self-loops. On an undirected network all nodes with at least one tie fall into one class.

The exact classes are all or nothing on many real networks: when every node sends and receives ties, all nodes are in one class; a few nodes without sent or without received ties can split the network into classes of single nodes. Exact regular equivalence suits networks whose ties follow levels or kinds, such as formal hierarchies or food webs.

## Examples

- A small office: juniors ask team leaders, team leaders ask the head
- `. nwclear`
- `. clear`
- `. input str8 ego str8 alter`
- `. "Anna" "Gwen"`
- `. "Sophie" "Gwen"`
- `. "Fion" "Leh"`
- `. "Magalie" "Leh"`
- `. "Gwen" "Antonia"`
- `. "Leh" "Antonia"`
- `. end`
- `. nwset ego alter, edgelist directed name(firm)`
- `. nwregular firm, generate(regular)`
- `. matrix list r(image)`

## Stored results

`nwregular` stores the following in `r()`:

- **Scalars**
- **`r(classes)`** --- number of classes
- **Matrices**
- **`r(image)`** --- classes x classes; 1 if members of the row class send ties to members of the column class

## References

Borgatti, S. P., and M. G. Everett. 1993. Two algorithms for computing regular equivalence. *Social Networks* 15: 361-376.

White, D. R., and K. P. Reitz. 1983. Graph and semigroup homomorphisms on networks of relations. *Social Networks* 5: 193-234.

## Also see

- psee
- [nwconcor](nwconcor), [nwhierarchy](nwhierarchy), [nwdissimilar](nwdissimilar), [nwsimilar](nwsimilar), [nwcollapse](nwcollapse)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
