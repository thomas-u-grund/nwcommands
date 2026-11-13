---
title: "nwprogramming"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
---

# `nwprogramming`

## Contents

**SectionDescription**

- hline 46
- [**[NW-5.1]****A first network command**](nwprogramming)
- [**[NW-5.2]****A command that creates a network**](nwprogramming)
- [**[NW-5.3]****How networks are stored**](nwprogramming)
- [**[NW-5.4]****Entering a network: _nwsyntax**](nwprogramming)
- [**[NW-5.5]****Reading the ties**](nwprogramming)
- [**[NW-5.6]****Conventions**](nwprogramming)
- [**[NW-5.7]****Pitfalls**](nwprogramming)
- [**[NW-5.8]****Stable Mata functions: nwapi**](nwprogramming)

## A first network command

The program below computes the indegree of every node of a network and stores it in a new variable. It reads the ties through the network object, so it works on networks of any size without building the adjacency matrix.

```stata
capture program drop myindegree
program myindegree
        syntax [anything(name=netname)], GENerate(name)
        _nwsyntax `netname'
        _nwdatasync `netname'
        confirm new variable `generate'
        quietly generate double `generate' = .
        mata: st_store((1::`nodes'), "`generate'", `netobj'->get_indegree(0))
end
```
`_nwsyntax` finds the network (the current network when none is named), unabbreviates its name and leaves local macros behind: ``netobj'` refers to the network object and ``nodes'` is its number of nodes ([[NW-5.4]](nwprogramming)). `_nwdatasync` makes observation *i* of the dataset belong to node *i*, so that the result can be stored row by row. `get_indegree(0)` returns one value per node: the number of incoming ties (all ties of an undirected network).

```stata
. nwwebuse florentine, nwclear
. myindegree flomarriage, generate(indeg)
. list _nwnode indeg in 1/5
```

## A command that creates a network

For a small network it is often simplest to work on the adjacency matrix. [nwtomata](nwtomata) copies it into a Mata matrix, and [nwset](nwset) with option `mat()` makes a new network of a Mata matrix. This program creates the complement of a binary network: a tie wherever the original network has none.

```stata
capture program drop mycomplement
program mycomplement
        syntax [anything(name=netname)], name(name)
        _nwsyntax `netname'
        tempname net
        nwtomata `netname', mat(`net')
        mata: `net' = (`net' :== 0)
        mata: _diag(`net', 0)
        local undirected = cond("`directed'" == "false", "undirected", "")
        nwset, mat(`net') name(`name') labs(`labs') `undirected'
        mata: mata drop `net'
end

. nwwebuse florentine, nwclear
. mycomplement flomarriage, name(nomarriage)
. nwsummarize nomarriage
```
``labs'` and ``directed'`, also left by `_nwsyntax`, give the new network the same nodes and the same direction as the original. A command that creates a network names it with `name()`; `generate()` is for new variables.

The adjacency matrix has *n* x *n* cells, so this is for networks of up to a few thousand nodes; above 20,000 nodes it is refused (error 484). For larger networks, read the ties as in [[NW-5.5]](nwprogramming) and create the network from an edge list with [nwfromedge](nwfromedge) or `nwset, edgelist`.

## How networks are stored

Networks are kept in Mata, next to the Stata dataset, in one object of class **NWs**. It holds the list of networks in memory (class **NWsdef**): their names, a pointer to each network and the current network. Each network is an object of class **NWdef**. The classes are compiled into the Mata library **lnwcommands.mlib**; their source is **unw_core.do** in the repository.

An **NWdef** object holds

- ***name, nodes*** --- the network name and the node names
- ***type*** --- whether the network is directed, valued, two-mode (with the mode of every node), has self-loops, or is temporal (snapshots, intervals or events)
- ***sparse index*** --- the ties as compressed rows: for every node its out-neighbors and tie values, and for a directed network also its in-neighbors
- ***adjacency matrix*** --- the *n* x *n* matrix of tie values

The sparse index and the adjacency matrix hold the same ties, and each is built from the other when it is first needed. A network created from an edge list ([nwfromedge](nwfromedge), `nwset, edgelist`, the generators above 2,000 nodes) starts with the sparse index only; its adjacency matrix is built only for a command that needs it, and is refused above 20,000 nodes. Most commands work on the sparse index, which needs memory in proportion to the number of ties; see [[NW-1.8]](nwintro) for which commands need the matrix.

Node *i* of a network is observation *i* of the dataset. Node attributes are ordinary variables, and results for nodes are stored in ordinary variables. A network does not need variables to exist; [nwload](nwload) creates them on request.

The heavy computations (shortest paths, betweenness, cliques, communities, motifs and others) run in a compiled plugin, **nwgraph**, which is installed for macOS, Windows and Linux. Where it is missing, most commands fall back to Mata code, which gives the same results more slowly.

Always change networks through the commands or the methods of **NWdef**, never by changing the objects directly: the sparse index and the matrix must stay consistent.

## Entering a network: _nwsyntax

`_nwsyntax` *netlist* [`,` `max(#)` `min(#)`] checks that the networks exist and unabbreviates them (by default exactly one network). It leaves these local macros, for the last network of the list:

- **`netname`** --- the full network name (all names, when `max()` allows several)
- **`netobj`** --- the network object, to be used in Mata as ``netobj'->`*method*`()`
- **`nodes`** --- the number of nodes
- **`directed`** --- `true` or `false`; likewise `valued`, `selfloops`, `is2mode` and `istemporal`
- **`labs`** --- the node names, ready for `nwset, labs()`
- **`networks`** --- the number of networks in the list

Without a network name it uses the current network. Network lists can be abbreviated like variable lists (`flo*`, `net1-net3`, `_all`); see [netlist](netlist) and [nwunab](nwunab).

## Reading the ties

Methods of **NWdef** that read the sparse index (node numbers run from 1 to ``nodes'`):

- **`neighbors(`*i*`)`** --- column vector of the out-neighbors of node *i* (all neighbors in an undirected network)
- **`neighbors_in(`*i*`)`** --- column vector of the in-neighbors of node *i*
- **`degree(`*i*`)`, `degree_in(`*i*`)`** --- number of out- and in-neighbors
- **`get_outdegree(0)`, `get_indegree(0)`** --- the same for all nodes at once, as an *n* x 1 vector
- **`has_edge(`*i*`,`*j*`)`** --- 1 if there is a tie from *i* to *j*
- **`edge_weight(`*i*`,`*j*`)`** --- the value of that tie (0 if none)
- **`edgelist()`** --- all ties as an *m* x 3 matrix of sender, receiver and value
- **`get_nodes()`, `get_nodenames()`** --- number and names of the nodes

`get_matrix()` returns a pointer to the adjacency matrix, building it if needed. In a directed network, decide whether a measure needs out-neighbors, in-neighbors or both: a question about a node's surroundings (is it in a dense core? do two neighborhoods overlap?) usually uses both directions, a question about exposure (what do my contacts do?) the out-neighbors.

## Conventions

**Options.** `generate()` names new variables, `name()` a new network; `replace` allows overwriting. Commands that change a network in place say so.

**Results.** Node-level results go into variables, one observation per node, after `_nwdatasync`. Scalars and matrices are returned in `r()` with `return scalar` and `return matrix` in an `rclass` program.

**Errors.** The return codes of nwcommands are listed in [nwerrorcodes](nwerrorcodes); use them, so that users meet the same code for the same problem.

**Tests.** The commands of the package have test files in **cscripts/** of the repository, which check the results against values computed by hand or by another program. Run a new command's test against the compiled library, not only against the Mata source.

## Pitfalls

1. **Missing diagonal.** Without self-loops, the diagonal of the adjacency matrix is missing (`.`), so a matrix product such as `net*net` is missing everywhere. Set the diagonal to 0 first: `_diag(net, 0)`.

2. **No broadcasting.** Mata's elementwise operators do not combine a column and a row vector into a matrix: `x :+ x'` is a conformability error. Write `(x*J(1,n,1)) :+ (J(n,1,1)*x')`.

3. **Rows of the dataset.** Storing a node result with `st_store()` fails if the dataset has fewer observations than the network has nodes, or puts values on the wrong nodes if they are in another order. Call `_nwdatasync` first.

4. **r() inside the program.** A value set with `return scalar` is in `r()` only after the program has ended; inside the program, use the local or scalar it came from.

5. **One-line Mata.** `mata: if (...) ...` and `mata: for (...) ...` on one line of an ado-file do not work; put loops and conditions in a Mata function.

## Stable Mata functions: nwapi

The classes and methods described in this help file are internal: they can change in any release. If you only need to read networks in your own Mata code (the number of nodes, the adjacency matrix, the edge list, degrees, neighbors), use the functions `nwapi_nodes()`, `nwapi_matrix()`, `nwapi_edgelist()`, `nwapi_outdegree()`, `nwapi_neighbors()` and the others of [nwapi](nwapi). They take the name of a network, return copies with documented shapes, stop with the return codes of [nwerrorcodes](nwerrorcodes) and keep their signatures within a major version. For example, `A = nwapi_matrix("flomarriage")` is an adjacency matrix without missing values, which can be multiplied at once (pitfall 1).

## See also

[nwapi](nwapi), [_nwsyntax](nwprogramming), [nwtomata](nwtomata), [nwset](nwset), [nwfromedge](nwfromedge), [nwunab](nwunab), [nwerrorcodes](nwerrorcodes), [nwinternals](nwinternals)

---

*nwcommands version 3.23.0, 13 November 2026* ([check your installed version](nwversion))
