---
title: "Programming with networks in Mata"
parent: "Book companion"
nav_order: 4
description: "How to write a new network command, in Stata and Mata, with nwtomata and the nwapi functions: a companion to the book."
permalink: /book/programming/
---

# Programming with networks in Mata
{: .no_toc }

This page goes with the book *Network Analysis with Stata*.

Every command in the book is an ordinary Stata `.ado` program. This page is for a reader who wants to write a new network command, for example to compute a measure the package does not have, or to read networks in a Mata program of their own. A program gets at a network in one of two supported ways: it copies the network to a Mata matrix with `nwtomata` (and back with `nwset, mat()`), or, with nwcommands 3.24 or later, it reads the network with the Mata functions `nwapi_*`. How the package stores a network internally (the Mata classes behind it, the pointer `netobj`) is not part of the interface and can change in any release; do not write code that depends on it.

## The first way: `nwtomata` and `nwset, mat()`

`nwtomata` *netname*`, mat(`*name*`)` copies a network's n × n adjacency matrix into the Mata matrix *name*. The matrix is a copy: changing it never changes the network. It holds the tie value (1 in a network without values), with the senders in the rows, and a *missing value* on the diagonal of a network without self-loops (and between the nodes of one mode of a two-mode network). `getmata` brings a Mata vector back into Stata as a variable, and `nwset, mat(`*name*`)` declares a network from a Mata matrix, so that every command in the book can use the result. This is the way to get a result back into a network, and it works in every version of the package.

## The second way: the `nwapi` functions

*Requires nwcommands 3.24 or later.* The `nwapi_` functions read a network from a Mata program directly: how many networks there are, their kind and size, and their ties as a matrix, an edge list, degrees or the neighbors of a node. Within version 3.x their names, arguments, result types and return codes do not change; new functions are added only in minor versions, and a function that is to be removed is announced one minor version ahead. A program can start with `assert(nwapi_version() >= 1)`; an older installation stops with r(3499), "function not found". Every function returns a copy and changes nothing, and none of them creates a network.

A *name* is the exact name of one network (no abbreviations, no lists); `""` or no argument means the current network. A node is given by its number, 1 to `nwapi_nodes()`, or by its label. Results go back to Stata with `st_numscalar()`, `st_matrix()` or `st_store()`. The density of the Florentine marriage network, the marriage partners of the Medici and the number of triangles:

```stata
. nwwebuse florentine, nwclear
. mata:
:     A   = nwapi_matrix("flomarriage")
:     n   = nwapi_nodes("flomarriage")
:     lab = nwapi_nodelabels("flomarriage")
:     nb  = nwapi_neighbors("flomarriage", "medici")
:     sum(A) / (n*(n-1))                           // density
  .1666666667
:     invtokens(lab[nb]')                          // Medici's marriage partners
  acciaiuoli albizzi barbadori ridolfi salviati tornabuoni
:     trace(A*A*A) / 6                             // triangles
  3
: end
```

## Which way to use

`nwtomata` and `nwset, mat()` work in every version of the package, are the only way to *create* a network from a matrix, and give an ordinary Mata matrix that can be multiplied, inverted or decomposed at once: short, readable code for a small network. The matrix is always the full n × n one, whose size grows with n², and its missing diagonal turns products such as `net*net` into missing values unless the diagonal is set to 0 first.

The `nwapi` functions read the ties as an edge list, as degrees or as the neighbors of a node, with memory in proportion to the ties. They are plain functions that return values, so they work inside expressions and loops, including a loop over all networks (`nwapi_names()`), and they report the properties of a network (directed, valued, two-mode, labels, modes) without parsing local macros. Their matrix has no missing values, and names, results and return codes stay fixed within version 3.x. They need nwcommands 3.24 or later, are read-only (fetch a matrix or an edge list once and reuse it), and cover the structure and the tie values only: node attributes are ordinary Stata variables, and the times of a temporal network are not read.

The size of the matrix decides most cases. A dense adjacency matrix stores a number for every pair of nodes; real networks are sparse, so most of it is zeros. A network ten times larger needs a hundred times the memory, and at 100,000 nodes the matrix would need about 74.5 GB. The package's own benchmark at 100,000 nodes and 1,000,000 ties runs degree, components and similar commands in 0.06 to 7 seconds without ever building it (Appendix A of the book; see [Performance and network size](/book/performance/)). So use the `nwapi` functions when a program visits the neighbors of each node, works on a large network, loops over networks, checks their properties or has to keep working across releases. Use `nwtomata` for matrix algebra on a small network, for a script that has to run with nwcommands 3.23 or earlier, and, with `nwset, mat()`, whenever the result is a new network. For a directed network "neighbor" means out-neighbors, in-neighbors or both, depending on the question: a structural question (*is this node in a dense core?*) uses both directions, as `nwkcore` does (Chapter 9); an exposure question (*what do my contacts' attributes look like?*) uses out-neighbors only, as `nwaltergen` does (Chapter 11).

## Writing a command

### The frame

A command that takes a network name begins with `` _nwsyntax `netname' ``. It resolves the name (abbreviations are accepted), stops with a clear message if the network does not exist, and leaves local macros for the rest of the command:

```stata
netname                               the resolved, unabbreviated network name
nodes                                 the number of nodes
directed, valued, is2mode, selfloops  "true" or "false"
labs                                  comma-joined node labels, ready for
                                      nwset, ... labs(`labs')
```

A command that accepts several networks at once calls `_nwsyntax` with `max()` raised above 1 and loops over the result. A few helper commands exist mainly for other commands: `nwunab` expands an abbreviated or wildcard list of network names, `nwvalidate` checks a proposed name for a new network and returns a valid one in `r(validname)`, `nwvalidvars` checks that Stata variables can hold a network's attributes, and `nwsync` aligns a network with the Stata variables after the data have been sorted or changed. Their help files give the syntax.

### A node-level statistic

The simplest command computes one number per node and writes it as a Stata variable. Indegree, computed by hand rather than by the package's own `nwdegree`, with the first way:

```stata
program myindegree
    syntax [anything(name=netname)] , [ generate(string)]
    _nwsyntax `netname'
    nwtomata `netname', mat(net)
    local generate = cond("`generate'"=="", "_myindegree", "`generate'")
    mata: indegree = colsum(net)'
    getmata `generate' = indegree, force
    mata: mata drop indegree net
end
```

`colsum(net)'` is the column vector of incoming ties (`colsum()` skips the missing diagonal) and `getmata` brings it back as a variable. Run on the Florentine data:

```stata
. nwwebuse florentine, nwclear

. myindegree flomarriage, generate(myindegree_flomarriage)

. list _nwnode myindegree_flomarriage in 1/5

     +-----------------------+
     |    _nwnode   myinde~e |
     |-----------------------|
  1. | acciaiuoli          1 |
  2. |    albizzi          3 |
  3. |  barbadori          2 |
  4. |   bischeri          3 |
  5. | castellani          3 |
     +-----------------------+
```

The values agree with `nwdegree` (Chapter 8). With the second way the body is shorter, because `nwapi_indegree()` already returns the vector (here as `myindegree2`):

```stata
program myindegree2
    syntax [anything(name=netname)] , [ generate(string)]
    _nwsyntax `netname'
    local generate = cond("`generate'"=="", "_myindegree", "`generate'")
    mata: st_store((1::`nodes'), st_addvar("double", "`generate'"), nwapi_indegree("`netname'"))
end
```

### A command that returns a network

A command can also return a network instead of a variable. Inverting an adjacency matrix (every present tie becomes absent and vice versa) ends with `nwset, mat()`, the command of Chapter 4 that declares a network from a matrix:

```stata
program myinverse
    syntax [anything(name=netname)] , [ name(string)]
    _nwsyntax `netname'
    nwtomata `netname', mat(net)
    local name = cond("`name'"=="", "_myinverse", "`name'")
    mata: inverse = (net :== 0)
    nwset, mat(inverse) name("`name'") undirected
    mata: mata drop net inverse
end

. myinverse flomarriage, name(flomarriage_inverse)

. nwsummarize flomarriage_inverse
(output omitted)
```

A command that reports numbers about a whole network is `rclass` and publishes them with `return scalar`.

### Memory and clean-up

Variables declared inside a Mata *function* are freed when the function returns. Variables created in a `mata:` block or by a command (the matrix that `nwtomata, mat()` writes) live in the Mata workspace until you remove them with `mata drop`, `mata clear` or `clear all`; `mata describe` lists them. Both ways copy, so the network itself is never affected, but a copy of a large matrix takes memory for as long as it exists. Drop what a program created, as the examples do, or do the work in a Mata function, so that nothing is left behind. Give the Mata variables of a program tempnames (`tempname net`, then ``mat(`net')``) instead of fixed names, which would overwrite a matrix of the same name in the user's workspace; the examples use fixed names for readability.

### Pitfalls

Each of these cost time during the package's own development.

1. A missing value makes every product and elementwise calculation that touches it missing, while the sum functions (`sum()`, `colsum()`, `rowsum()`) skip it. `nwtomata` returns a missing diagonal for a network without self-loops, so `colsum(net)` is right, but `net*net` is all missing unless the diagonal is set to 0 first.
2. `selectindex()` keeps the orientation of its input: a row in, a row out. Transpose explicitly if downstream code assumes a column.
3. `return scalar` publishes `r()` only when the program exits, so inside the program use the local, not `r()`. An `r()` result that was never set evaluates to missing without an error.
4. A successful `assert` or `di` does not reset `_rc`. After `capture badcmd`, `_rc` stays non-zero for the rest of the do-file.

### Checklist

1. Decide the output shape first: a per-node variable (`generate()`), a new network (`name()`) or summary numbers (`rclass`).
2. Enter the network's context with `_nwsyntax`; never parse a network name by hand.
3. Read the network with `nwapi_*` or `nwtomata` (see "Which way to use"), and drop what you created.
4. Check the command against a small network whose answer you can work out by hand, and where the package already computes the quantity, as with `nwdegree` above, compare with it too. Keep the check in a do-file next to the command.
5. Follow the package's conventions: `netname` or `netlist`, `generate()` or `name()` by output type, and an informative error of the form `"<command> does not support <condition>; <suggested fix>."` for a network type the command cannot handle.

## Reference: the `nwapi` functions

*Requires nwcommands 3.24 or later.* `help nwapi` shows the same list in Stata. *name* is a string scalar, `""` or omitted for the current network; *node* is a node number (a whole real number) or a node label (a string); *label* is a string scalar. Vectors with one value per node or per network are column vectors; in a matrix the senders are the rows and the receivers the columns. Nodes are numbered 1 to `nwapi_nodes()` in the order of the node list. If two nodes have the same label, the label stands for the first of them.

### The collection

- `nwapi_version()`: real scalar: the generation of the interface, 1 in nwcommands 3.x.
- `nwapi_count()`: real scalar: the number of networks in memory (0 if none).
- `nwapi_names()`: string colvector: the names of the networks in the order in which they were created (0 × 1 if none).
- `nwapi_exists(`*name*`)`: real scalar: 1 if a network of this name exists, else 0; `nwapi_exists()` or `nwapi_exists("")`: 1 if there is any network.
- `nwapi_current()`: string scalar: the name of the current network (error 482 if there is no network).

### Properties of a network

Each takes an optional *name*.

- `nwapi_nodes(`[*name*]`)`: real scalar: the number of nodes.
- `nwapi_ties(`[*name*]`)`: real scalar: the number of ties; the arcs of a directed network, the edges of an undirected network (a tie between two nodes counts once, and a self-loop counts once).
- `nwapi_directed(`[*name*]`)`: real scalar: 1 if the network is directed.
- `nwapi_valued(`[*name*]`)`: real scalar: 1 if the ties have values.
- `nwapi_twomode(`[*name*]`)`: real scalar: 1 if the network is two-mode. A two-mode network is one list of nodes, first the nodes of the first mode, then those of the second.
- `nwapi_selfloops(`[*name*]`)`: real scalar: 1 if ties from a node to itself are allowed.
- `nwapi_temporal(`[*name*]`)`: real scalar: 1 if the network was declared temporal (snapshots, intervals or events); the times themselves are not read by this interface.
- `nwapi_nodelabels(`[*name*]`)`: string colvector: the node labels, one row per node.
- `nwapi_modes(`[*name*]`)`: real colvector: the mode (1 or 2) of every node; all 1 in a one-mode network.

### Ties

- `nwapi_matrix(`[*name*]`)`: real matrix, n × n: the adjacency matrix. It holds the value of the tie from the row node to the column node (1 in a network without values) and 0 where there is no tie; it is symmetric for an undirected network. It has no missing values, so that `A*A` and `rowsum(A)` work; `nwtomata` returns the same matrix with missing values on the diagonal of a network without self-loops, and between the nodes of one mode of a two-mode network, where this function puts 0. A two-mode network gives the matrix of both modes together. A network of more than 20,000 nodes is not turned into a matrix (error 484, the matrix would need more than 3 GB); use the edge list, the neighbors or the degrees.
- `nwapi_edgelist(`[*name*]`)`: real matrix, m × 3: sender, receiver and value of every tie, ordered by sender and then by receiver. In an undirected network a tie is listed once, with the smaller node number first (the upper triangle of the matrix); in a directed network every arc is listed. A network without ties gives a matrix with 0 rows and 3 columns. This is the way to read a large network: it needs memory in proportion to the ties only.
- `nwapi_outdegree(`[*name*]`)`: real colvector, n × 1: the number of ties each node sends (a self-loop counts once).
- `nwapi_indegree(`[*name*]`)`: real colvector, n × 1: the number of ties each node receives; in an undirected network the same as the outdegree.
- `nwapi_neighbors(`*name*`,` *node*`)`: real colvector: the numbers of the nodes that *node* sends ties to, in ascending order (0 × 1 if none); in an undirected network all neighbors. The network name is the first argument; `""` is the current network.
- `nwapi_inneighbors(`*name*`,` *node*`)`: real colvector: the numbers of the nodes that send ties to *node*, in ascending order; in an undirected network the same as `nwapi_neighbors()`.
- `nwapi_nodeid(`*name*`,` *label*`)`: real scalar: the number of the node with this label (error 485 if there is none).

In a network with values the degrees count the ties, not the values; sum the third column of `nwapi_edgelist()` or the rows of `nwapi_matrix()` for the sum of the values. A tie with the value 0 is not a tie.

### Errors

The functions check their arguments and stop with a message that says what is wrong and one of these return codes (see `help nwerrorcodes`); catch them with `capture mata: nwapi_nodes("friends")` and test `_rc`.

- 482: no network of this name (or no network at all, for `""`).
- 485: no node with this label, or a node number below 1 or above the number of nodes.
- 198: *node* is not a single whole number or a single label (a missing value, a fraction, a vector, a number that is not real).
- 484: `nwapi_matrix()` of a network with more than 20,000 nodes.

Mata itself stops with r(3200) or r(3250) if an argument has the wrong size or type (a vector for *name*, a number for *label*).

### Stability

Within version 3.x the names, arguments, the type and orientation of the results and the return codes of these functions do not change. A function that is to be removed is announced as deprecated in the help file and the release notes at least one minor version ahead and still works until the next major version. Nothing else in the Mata library of the package is part of this interface.
