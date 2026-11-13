---
title: "_nwtomata"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Return adjacency matrix of network"
---

# `_nwtomata`

Return adjacency matrix of network

## Syntax

```stata
_nwtomata
[netname] 
, 
[mat(matamatrix)]
```

| | |
|---|---|
| `mat(matamatrix)` | name of the new Mata matrix |

## Description

This command allows interaction with the underlying adjacency matrix in Mata  of a network. You do not need to know Mata to use any of the nwcommands, but sometimes you might want to obtain the adjacency matrix, for example, when programming your own network commands.

`_nwtomata` returns a link to the [Mata network object](nwprogramming) and saves it in **r(netobj)**. Furthermore, it returns a direct link to the underlying Mata adjacency matrix of the network object and saves it in **r(adj)**.

Keep in mind that when you make alterations to **r(adj)** in Mata you change a network. This should only be done by advanced programmers.

When the option `mat()` is specified, the command obtains a copy of the adjacency matrix and saves it as a new Mata matrix *matamatrix*. When you make alterations to this *matamtrix* you do not change the network.

## Example

```stata
. nwclear
. nwrandom 5, prob(1) name(mynet)
. _nwtomata, mat(myadj)

. return list

macros:
           r(adj_copy) : "myadj"
                r(adj) : "(*__nw.nws.pdefs[1]->get_matrix())"
             r(netobj) : "__nw.nws.pdefs[1]"
            r(netname) : "mynet"
```
The previous commands generated a new Mata matrix called *myadj*. The next command displays this copy of the adjacency matrix.

```stata
. mata: `r(adj_copy)'
[symmetric]
       1   2   3   4   5
    +---------------------+
  1 |  .                  |
  2 |  1   .              |
  3 |  1   1   .          |
  4 |  1   1   1   .      |
  5 |  1   1   1   1   .  |
    +---------------------+
```
One can also directly interact with the underlying adjacency matrix of a network. But be careful when doing so because you might corrupt your network data. This displays the actual adjacency matrix.

```stata
. mata: `r(adj)'
[symmetric]
       1   2   3   4   5
    +---------------------+
  1 |  .                  |
  2 |  1   .              |
  3 |  1   1   .          |
  4 |  1   1   1   .      |
  5 |  1   1   1   1   .  |
    +---------------------+
```

## Stored results

- **Macros**
- **r(netname)** --- name of the network
- **r(netobj)** --- name of the Mata network object
- **r(adj)** --- Mata expression that points to the adjacency matrix of the network
- **r(adj_copy)** --- name of the new Mata matrix (only with `mat()`)

## See also

- [Programming own network commands](nwprogramming)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
