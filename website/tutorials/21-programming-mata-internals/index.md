---
title: "Tutorial 21: Reading Networks in Mata with the nwapi Functions"
parent: "nwcommands (core)"
nav_order: 21
description: "Read networks in your own Mata code through a small, stable set of functions: properties, the adjacency matrix, the edge list, degrees and neighbors, then loop over networks, compute your own measure and give the result back to Stata."
---

# Tutorial 21: Reading Networks in Mata with the nwapi Functions

[Tutorial 20](../20-programming-mata-bridge/) moved a network into a Mata matrix with `nwtomata` and back with
`nwset`. This tutorial shows the next step for people who write more Mata: a small set of Mata functions, the
`nwapi_` functions, that read the networks nwcommands keeps in memory directly. You ask for a network by name
and get plain numbers, vectors and matrices: how many nodes, which ties, which neighbors. You do not need to know
how nwcommands stores a network, and a result never changes the network.

The functions are documented in `help nwapi`, and their signatures stay the same within a major version of
nwcommands (everything that is new comes as an addition in a minor version). You need a little Mata and
[Tutorial 2](../02-core-concepts/) (network names and the current network). The data are the Florentine families
(`flomarriage`, 16 nodes, undirected, with the node variable `wealth`), the Glasgow friendship waves
(`glasgow1` to `glasgow3`, 50 pupils, directed) and the Sampson monastery network (`samplike`, valued). The script is
[`example.do`](example.do) and the complete output is [`example.log`](example.log). It needs nwcommands 3.24 or later.

## 1. What is in memory

Four functions describe the collection of networks, and one the interface itself:

```stata
. nwwebuse florentine, nwclear

. mata: nwapi_version()
  1

. mata: nwapi_count()
  2

. mata: nwapi_names()'
                 1             2
    +-----------------------------+
  1 |  flobusiness   flomarriage  |
    +-----------------------------+

. mata: nwapi_current()
  flomarriage

. mata: nwapi_exists("flomarriage"), nwapi_exists("nonet")
       1   2
    +---------+
  1 |  1   0  |
    +---------+
```

`nwapi_names()` is a column vector (the quote transposes it, only to make it print compactly). A network is
addressed by its **exact name**: no abbreviations and no lists, unlike the commands. The empty name `""`, or leaving
the argument out, means the current network, so `nwapi_nodes()` is the number of nodes of `nwapi_current()`.
`nwapi_version()` is the generation of the interface; a program that depends on the functions can start with
`assert(nwapi_version() >= 1)`.

The properties of a network are one function each, all taking the network name:

```stata
. mata: nwapi_nodes("flomarriage"), nwapi_ties("flomarriage")
        1    2
    +-----------+
  1 |  16   20  |
    +-----------+

. mata: nwapi_directed("flomarriage"), nwapi_valued("flomarriage"), nwapi_twomode("flomarriage")
       1   2   3
    +-------------+
  1 |  0   0   0  |
    +-------------+

. mata: nwapi_nodes(), nwapi_ties()
        1    2
    +-----------+
  1 |  16   20  |
    +-----------+

. mata: lab = nwapi_nodelabels("flomarriage")

. mata: lab[1..5]'
                1            2            3            4            5
    +------------------------------------------------------------------+
  1 |  acciaiuoli      albizzi    barbadori     bischeri   castellani  |
    +------------------------------------------------------------------+
```

`nwapi_ties()` counts each tie once: the arcs of a directed network and the edges of an undirected one (the 20
marriages, not 40). The remaining properties are `nwapi_selfloops()`, `nwapi_temporal()` and, for two-mode networks,
`nwapi_modes()`, which gives the mode (1 or 2) of each node. Yes/no properties return 1 or 0. Nodes are numbered
1 to *n* in the order of `nwapi_nodelabels()`.

## 2. Reading the ties

### The adjacency matrix

```stata
. mata: A = nwapi_matrix("flomarriage")

. mata: rows(A), cols(A)
        1    2
    +-----------+
  1 |  16   16  |
    +-----------+

. mata: hasmissing(A)
  0
```

Rows are senders and columns are receivers; the cell holds the value of the tie (1 in a network without values) and
0 where there is no tie. **There are no missing values**: the diagonal of a network without self-loops is 0, and so is a
dyad inside one mode of a two-mode network, where no tie can exist. `nwtomata`, by contrast, leaves these cells missing,
and `A*A` is then missing everywhere (the first pitfall of Tutorial 20). With `nwapi_matrix()` the products work at once.

The matrix is a copy. Change it as you like; the network does not notice:

```stata
. mata: A = nwapi_matrix("flomarriage")

. mata: A[2,1] = 7

. mata: B = nwapi_matrix("flomarriage")

. mata: A[1..3, 1..3], B[1..3, 1..3]
       1   2   3   4   5   6
    +-------------------------+
  1 |  0   0   0   0   0   0  |
  2 |  7   0   0   0   0   0  |
  3 |  0   0   0   0   0   0  |
    +-------------------------+
```

The matrix needs *n* x *n* cells, so a network of more than 20,000 nodes is refused (Section 8). The next functions
need memory only in proportion to the number of ties.

### The edge list, degrees and neighbors

```stata
. mata: E = nwapi_edgelist("flomarriage")

. mata: rows(E), cols(E)
        1    2
    +-----------+
  1 |  20    3  |
    +-----------+

. mata: E[1..5, .]
       1   2   3
    +-------------+
  1 |  1   9   1  |
  2 |  2   6   1  |
  3 |  2   7   1  |
  4 |  2   9   1  |
  5 |  3   5   1  |
    +-------------+
```

`nwapi_edgelist()` has one row per tie: sender, receiver and value, ordered by sender and then receiver. An
undirected tie is listed **once**, with the smaller node number first. Twenty marriages are twenty rows. A network without
ties gives a matrix with 0 rows and 3 columns.

```stata
. mata: nwapi_outdegree("flomarriage")'
        1    2    3    4    5    6    7    8    9   10   11   12   13   14   15
    +----------------------------------------------------------------------------
  1 |   1    3    2    3    3    1    4    1    6    1    3    0    3    2    4
    +----------------------------------------------------------------------------
       16
     ------+
  1     3  |
     ------+

. mata: nwapi_outdegree("flomarriage") == nwapi_indegree("flomarriage")
  1
```

`nwapi_outdegree()` and `nwapi_indegree()` give the number of ties each node sends and receives, one row per node; in
an undirected network they are the same. In a valued network they count ties, not values (sum the third column of the edge
list for the total value of a node's ties).

A node is given by its number or by its label. `nwapi_nodeid()` turns a label into a number, and `nwapi_neighbors()`
returns the numbers of the neighbors in ascending order:

```stata
. mata: id = nwapi_nodeid("flomarriage", "medici")

. mata: id
  9

. mata: nb = nwapi_neighbors("flomarriage", id)

. mata: nb'
        1    2    3    4    5    6
    +-------------------------------+
  1 |   1    2    3   13   14   16  |
    +-------------------------------+

. mata: lab[nb]'
                1            2            3            4            5
    +------------------------------------------------------------------
  1 |  acciaiuoli      albizzi    barbadori      ridolfi     salviati
    +------------------------------------------------------------------
                6
     --------------+
  1    tornabuoni  |
     --------------+

. mata: lab[nwapi_neighbors("flomarriage", "medici")]'
        (the same six labels)
```

The labels of the neighbors of the Medici come from indexing the label vector with the neighbor numbers. A node
without ties has a neighbor vector with 0 rows.

### Directed and valued networks

In a directed network `nwapi_neighbors()` are the nodes a node sends ties to, and `nwapi_inneighbors()` the nodes it
receives them from:

```stata
. nwwebuse glasgow, nwclear

. mata: nwapi_directed("glasgow1"), nwapi_nodes("glasgow1"), nwapi_ties("glasgow1")
         1     2     3
    +-------------------+
  1 |    1    50   113  |
    +-------------------+

. mata: nwapi_neighbors("glasgow1", 1)'
       1   2
    +---------+
  1 |  3   6  |
    +---------+

. mata: nwapi_inneighbors("glasgow1", 1)'
  6
```

Pupil 1 names pupils 3 and 6 as friends, and is named by pupil 6 only. For a valued network the matrix holds the
values and the number of ties stays the number of ties:

```stata
. nwwebuse sampson, nwclear

. mata: A = nwapi_matrix("samplike")

. mata: max(A)
  3

. mata: sum(A :> 0)
  88

. mata: nwapi_ties("samplike")
  88

. nwtomata samplike, mat(S)

. mata: sum(S :> 0)
  106
```

The 88 ties are what the network has. The 106 of the `nwtomata` matrix are 88 ties plus the 18 missing diagonal cells, because in Mata a
missing value is larger than every number. That is the other reason for the zero diagonal of `nwapi_matrix()`.

## 3. Looping over the networks in memory

Because the names are a vector, a loop over all networks is a few lines. This function prints a table of every
network in memory:

```stata
. nwwebuse glasgow, nwclear

. set seed 2111

. nwrandom 30, prob(.1) undirected name(random30)

. mata:
: void nwt_table()
> {
>     real scalar i, n, m, dens
>     string colvector names
>     string scalar nm
>
>     names = nwapi_names()
>     printf("{txt}%-14s %6s %6s  %-10s %7s\n", "network", "nodes", "ties", "type", "density")
>     for (i = 1; i <= rows(names); i++) {
>         nm = names[i]
>         n = nwapi_nodes(nm)
>         m = nwapi_ties(nm)
>         dens = m / (nwapi_directed(nm) ? n*(n-1) : n*(n-1)/2)
>         printf("{res}%-14s %6.0f %6.0f  %-10s %7.3f\n", nm, n, m,
>             nwapi_directed(nm) ? "directed" : "undirected", dens)
>     }
> }
: end

. mata: nwt_table()
network         nodes   ties  type       density
glasgow1           50    113  directed     0.046
glasgow2           50    116  directed     0.047
glasgow3           50    122  directed     0.050
random30           30     51  undirected   0.117
```

The only thing that depends on the type of network is the number of possible ties, *n*(*n*-1) for a directed
and *n*(*n*-1)/2 for an undirected network. `nwapi_ties()` hides the difference in how the ties are stored.
The same loop works for the waves of a longitudinal network; Tutorial 20 shows this with a command.

## 4. A measure of your own

Two functions, written against `nwapi_` only. The first, how many other nodes a node reaches within two steps, is
natural with the matrix. The second, the mean of a node attribute over the neighbors, uses the neighbor lists and so
works for networks of any size:

```stata
. mata:
: // how many other nodes are reached in at most two steps (matrix version)
: real colvector nwt_reach2(string scalar net)
> {
>     real matrix A, R
>
>     A = nwapi_matrix(net)
>     R = ((A + A*A) :> 0)
>     _diag(R, 0)
>     return(rowsum(R))
> }
: // the mean of x over the neighbors of every node; missing for an isolate (works for large networks)
: real colvector nwt_nbrmean(string scalar net, real colvector x)
> {
>     real scalar i, n
>     real colvector out, nb
>
>     n = nwapi_nodes(net)
>     out = J(n, 1, .)
>     for (i = 1; i <= n; i++) {
>         nb = nwapi_neighbors(net, i)
>         if (rows(nb) > 0) out[i] = mean(x[nb])
>     }
>     return(out)
> }
: end
```

The functions take the network by name, so they know nothing about nwcommands beyond `nwapi_`. In `nwt_reach2()` the
matrix has no missing diagonal, so no `_diag(A, 0)` is needed before `A*A`; the `_diag(R, 0)` afterwards only
removes the node itself from its reach. Use them on the Florentine families:

```stata
. nwwebuse florentine, nwclear

. mata: nwt_reach2("flomarriage")'
        1    2    3    4    5    6    7    8    9   10   11   12   13   14   15
    +----------------------------------------------------------------------------
  1 |   6   10    9    8    6    3    9    4   11    2    6    0   11    7    8
    +----------------------------------------------------------------------------
       16
     ------+
  1    10  |

. mata: x = st_data(., "wealth")

. mata: nwt_nbrmean("flomarriage", x)'
                 1             2             3             4             5
    +-----------------------------------------------------------------------
  1 |          103   47.66666667          61.5   67.66666667   83.33333333
        (the full output is in example.log)
```

`st_data()` reads the node variable `wealth`. Row *i* of the data is node *i* only while the dataset is in node order,
which `_nwdatasync` guarantees (Section 6). Node 12 (Pucci) has no marriage ties and so a missing value.

## 5. Back to Stata: variables, matrices and new networks

Nothing in the `nwapi_` functions writes to Stata or to a network: giving a result back is ordinary Mata and an
ordinary command, as in Tutorial 20.

```stata
. mata: st_store(., st_addvar("double", "reach2"), nwt_reach2("flomarriage"))

. mata: st_store(., st_addvar("double", "nbrwealth"), nwt_nbrmean("flomarriage", x))

. list _nwnode wealth reach2 nbrwealth in 1/6
     +------------------------------------------+
     |    _nwnode   wealth   reach2   nbrwealth |
     |------------------------------------------|
  1. | acciaiuoli       10        6         103 |
  2. |    albizzi       36       10   47.666667 |
  3. |  barbadori       55        9        61.5 |
  4. |   bischeri       44        8   67.666667 |
  5. | castellani       20        6   83.333333 |
     |------------------------------------------|
  6. |     ginori       32        3          36 |
     +------------------------------------------+
```

A result as a Stata matrix or scalar goes through `st_matrix()` and `st_numscalar()`:

```stata
. mata: st_matrix("R", nwt_reach2("flomarriage"))

. mata: st_numscalar("meanreach", mean(nwt_reach2("flomarriage")))

. display meanreach
6.875
```

A new network is created from a Mata matrix with `nwset, mat()`, which is the documented way (`help nwset`). The
matrix of paths of length two, with the node labels taken from the network:

```stata
. mata:
: P = nwapi_matrix("flomarriage")
: P = P*P
: _diag(P, 0)
: end

. mata: st_local("labs", invtokens(nwapi_nodelabels("flomarriage")', ","))

. nwset, mat(P) name(paths2) labs(`labs') undirected

. nwsummarize paths2
--------------------------------------------------
   Network name:  paths2
   Network id:  3
   Directed: false
   Valued: true
   Two-mode: false
   Nodes: 16
   Selfloop: false
   Edges: 43
   Minimum value:  0
   Maximum value:  2
   Density:  .358
   Mean degree:  5.38
   Temporal: false
```

The values of `paths2` are the number of paths of length two between two nodes, so the network is valued. The
interface is read-only on purpose: to change a network you use the commands.

## 6. A reusable command

A command that wraps `nwt_nbrmean()` needs only a few lines of ado code around it. `_nwsyntax` (see `help nwprogramming`)
finds the network, accepts abbreviations and the current network and leaves the full name in the local macro `netname`;
`_nwdatasync` puts the dataset in node order. The Mata function receives the exact name:

```stata
. capture program drop nwnbrwealth

. program nwnbrwealth
  1.     syntax [anything(name=netname)], GENerate(name) VARiable(varname numeric)
  2.     _nwsyntax `netname'
  3.     _nwdatasync `netname'
  4.     confirm new variable `generate'
  5.     quietly generate double `generate' = .
  6.     mata: st_store(., "`generate'", nwt_nbrmean(st_local("netname"), st_data(., "`variable'")))
  7. end

. nwwebuse florentine, nwclear

. nwnbrwealth flomar, generate(nw1) variable(wealth)

. nwnbrwealth flomarriage, generate(nw2) variable(wealth)

. list _nwnode wealth nw1 nw2 in 1/4
     +---------------------------------------------+
     |    _nwnode   wealth         nw1         nw2 |
     |---------------------------------------------|
  1. | acciaiuoli       10         103         103 |
  2. |    albizzi       36   47.666667   47.666667 |
  3. |  barbadori       55        61.5        61.5 |
  4. |   bischeri       44   67.666667   67.666667 |
     +---------------------------------------------+
```

The abbreviation `flomar` is resolved by `_nwsyntax`, so the command accepts what every nwcommands command accepts. The Mata functions
must exist when the command runs: put them in a `.mata` file that you compile into a library (`help mata mlib`).

## 7. Errors

The functions check their arguments and stop with the return codes of `help nwerrorcodes`, and a message that says
what is wrong. Catch them with `capture`:

```stata
. capture noisily mata: nwapi_nodes("friends")
network friends not found
. display _rc
482

. capture noisily mata: nwapi_neighbors("flomarriage", "nobody")
node nobody not found in network flomarriage
. display _rc
485

. capture noisily mata: nwapi_neighbors("flomarriage", 99)
node 99 does not exist in network flomarriage (it has 16 nodes)
. display _rc
485

. capture noisily mata: nwapi_neighbors("flomarriage", 1.5)
the node number must be a whole number, not 1.5
. display _rc
198
```

| Code | Meaning |
|---|---|
| 482 | no network of that name (or none at all, for the current network) |
| 485 | no node with that label, or a node number out of range |
| 198 | a node that is not a single whole number or a single label |
| 484 | `nwapi_matrix()` of a network with more than 20,000 nodes |

If your code may run on an older installation, `capture mata: nwapi_version()` is 0 when the functions exist and an
error (r(3499), function not found) when they do not.

## 8. Large networks

The edge list, the degrees and the neighbors need memory in proportion to the number of ties; only the matrix grows
with the square of the number of nodes. A ring of 25,000 nodes shows both:

```stata
. clear

. quietly set obs 25000

. generate long a = _n

. generate long b = mod(_n, 25000) + 1

. nwset a b, edgelist name(ring) undirected

. mata: nwapi_nodes("ring"), nwapi_ties("ring")
           1       2
    +-----------------+
  1 |  25000   25000  |
    +-----------------+

. mata: E = nwapi_edgelist("ring")

. mata: E[1..3, .]
           1       2       3
    +-------------------------+
  1 |      1       2       1  |
  2 |      1   25000       1  |
  3 |      2       3       1  |
    +-------------------------+

. mata: d = nwapi_outdegree("ring")

. mata: min(d), max(d)
       1   2
    +---------+
  1 |  2   2  |
    +---------+

. mata: nwapi_neighbors("ring", 1)'
           1       2
    +-----------------+
  1 |      2   25000  |
    +-----------------+

. capture noisily mata: A = nwapi_matrix("ring")
network ring has 25000 nodes; a dense 25000 x 25000 matrix would need about 4.66 GB and is refused (more than 20000 nodes). Use nwapi_edgelist(), nwapi_neighbors() or nwapi_outdegree() instead, which never need the dense matrix.
. display _rc
484
```

Everything works on the ring except the matrix, and the refusal says what to use instead. A measure that you write
for large networks should therefore start from `nwapi_edgelist()` or `nwapi_neighbors()`, as `nwt_nbrmean()` does,
and use `nwapi_matrix()` only where the matrix is the natural object, as `nwt_reach2()` does.

## 9. The functions at a glance

| Function | Returns |
|---|---|
| `nwapi_version()` | the generation of the interface (1) |
| `nwapi_count()`, `nwapi_names()`, `nwapi_exists(`*name*`)`, `nwapi_current()` | the collection of networks |
| `nwapi_nodes()`, `nwapi_ties()` | number of nodes and of ties |
| `nwapi_directed()`, `nwapi_valued()`, `nwapi_twomode()`, `nwapi_selfloops()`, `nwapi_temporal()` | 1 or 0 |
| `nwapi_nodelabels()`, `nwapi_modes()` | labels and modes, one row per node |
| `nwapi_matrix()` | the *n* x *n* adjacency matrix, without missing values |
| `nwapi_edgelist()` | the *m* x 3 matrix of sender, receiver and value |
| `nwapi_outdegree()`, `nwapi_indegree()` | the number of ties sent and received, one row per node |
| `nwapi_neighbors(`*name*`,` *node*`)`, `nwapi_inneighbors(`*name*`,` *node*`)` | the node numbers of the neighbors |
| `nwapi_nodeid(`*name*`,` *label*`)` | the node number of a label |

Every function except the last three takes an optional network name (`""` or no argument is the current
network); the last three need the name first. See `help nwapi` for the exact definitions.

## Behind the API

Behind these functions nwcommands keeps the networks in Mata objects of its own. They exist, and the commands of the
package use them, but they are not part of the interface that this tutorial describes: their classes, methods and
signatures can change in any release without notice, and code that depends on them can break after an update. For code
that has to last, use the `nwapi_` functions, the commands, `nwtomata` and `nwset`. If you need something that the
functions do not offer, say so on the [issue tracker](https://github.com/thomas-u-grund/nwcommands/issues): the
interface grows by additions in minor versions.
