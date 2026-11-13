---
title: "Tutorial 20: Programming with Mata: from Stata Networks to Mata and Back"
parent: "nwcommands (core)"
nav_order: 20
description: "Bring a network into a Mata matrix, compute a measure nwcommands does not offer, return it as a node variable and as a new network, loop over the waves of a longitudinal network, and avoid the usual traps."
---

# Tutorial 20: Programming with Mata: from Stata Networks to Mata and Back

Sooner or later you want a network measure that no command offers. Stata's `matrix` language is
awkward for this; Mata, Stata's compiled matrix language, is made for it. This tutorial is the
bridge: it takes a network out of nwcommands into a Mata matrix, computes something of your own,
and brings the result back as a variable and as a new network. It is not a Mata primer. You need
[Tutorial 2](../02-core-concepts/) (netnames and the current network) and a little patience with
matrices; the few Mata constructs used are explained where they appear.

The data are the Florentine families (`flomarriage`, 16 nodes, undirected, with the node variable
`wealth`) and the three Glasgow friendship waves (`glasgow1` to `glasgow3`, 50 pupils, directed). The
script is [`example.do`](example.do), the complete output [`example.log`](example.log).

## 1. A network as a Mata matrix

`nwtomata` copies the adjacency matrix of a network into a Mata matrix of your own name:

```stata
. nwwebuse florentine

. nwtomata flomarriage, mat(A)

. mata: rows(A), cols(A)
        1    2
    +-----------+
  1 |  16   16  |
    +-----------+
```

Row *i* and column *j* of `A` belong to node *i* and node *j* in node order, so `rowsum(A)'` is
the degree of every family. Whatever you put after `mata:` on a Stata line is run as Mata. Look at the corner of the matrix:

```stata
. mata: A[1..4, 1..4]
[symmetric]
       1   2   3   4
    +-----------------+
  1 |  .              |
  2 |  0   .          |
  3 |  0   0   .      |
  4 |  0   0   0   .  |
    +-----------------+
```

The diagonal is missing (`.`), not 0: a network without self-loops has no value for "tie from a node to
itself". Section 6 returns to this, because it is the most common source of wrong numbers.

What you get is a **copy**. Changing it does not change the network:

```stata
. mata: A[2,1] = 7

. nwtomata flomarriage, mat(B)

. mata: A[1..3, 1..3], B[1..3, 1..3]
       1   2   3   4   5   6
    +-------------------------+
  1 |  .   0   0   .   0   0  |
  2 |  7   .   0   0   .   0  |
  3 |  0   0   .   0   0   .  |
    +-------------------------+
```

The left block is the changed copy `A`, the right block a fresh copy `B` taken afterwards: the
network still has no tie there. To change a network you hand a matrix back (section 3).

`nwtomata` also leaves results in `r()`: the network's name (`r(netname)`) and, for advanced programs, a
Mata expression for the network's own matrix, so that you can read it without a copy (see
`help nwprogramming` and `help _nwtomata`). For a matrix you intend to change, always use the copy.

## 2. A measure of our own: a small Mata function

Two measures that nwcommands does not give you directly, as Mata functions: how many others a node reaches within
two steps, and the mean of a node attribute over a node's neighbours. A Mata function states the types of
its argument and result, declares its local variables, and returns a value:

```stata
. mata:
: real colvector nw_reach2(real matrix A)
> {
>     real matrix B
>     B = A
>     _diag(B, 0)                // no self-ties; the diagonal arrives as missing
>     B = ((B + B*B) :> 0)       // tie, or a common partner
>     _diag(B, 0)
>     return(rowsum(B))          // how many others are within two steps
> }
: real colvector nw_nbrmean(real matrix A, real colvector x)
> {
>     real matrix B
>     B = A
>     _diag(B, 0)
>     return((B*x) :/ rowsum(B))  // . for an isolate
> }
: end
```

The ingredients: `B*B` is the matrix product, so `B*B[i,j]` counts the common partners of *i* and *j*; `:>` and `:/` are
the elementwise comparison and division (the colon means elementwise); `_diag(B, 0)` sets the diagonal in
place; `rowsum` adds up each row. The functions are defined once per session. For code you want to keep, put them in a `.mata`
file and compile it into a library (see `help mata mlib`), or paste the block at the top of the do-file as here.

Use them on the matrix, and read a node variable into Mata with `st_data()`:

```stata
. nwtomata flomarriage, mat(A)

. mata: nw_reach2(A)'
        1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16
    +--------------------------------------------------------------------------------
  1 |   6   10    9    8    6    3    9    4   11    2    6    0   11    7    8   10
    +--------------------------------------------------------------------------------

. mata: x = st_data(., "wealth")

. mata: nw_nbrmean(A, x)'
```

(The second call prints, for each family, the mean wealth of its marriage partners: 103 for the Acciaiuoli, whose
only partner is the Medici, and `.` for the Pucci, who have no partner; the 16 values are in the log.)

The numbers say that the Medici (node 9, the family with the most ties) reach 11 of the 15 other families within two
marriage steps, the Pucci (node 12, no ties) reach none.

## 3. Back to Stata: variables, matrices, networks

**A node variable.** `st_store()` writes a Mata vector into dataset variables, one value per observation. `st_addvar()`
creates the variable and returns its index:

```stata
. mata: st_store(., st_addvar("double", "reach2"), nw_reach2(A))

. mata: st_store(., st_addvar("double", "nbrwealth"), nw_nbrmean(A, x))

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

This works because row *i* of the dataset is node *i* (the node names are in `_nwnode`).
Section 6 shows what keeps it that way.

**A Stata matrix.** `st_matrix("R", ...)` posts a Mata matrix as a Stata matrix, for `matrix list`, `esttab` and the like;
`st_numscalar()` does the same for a number.

**A new network.** The mirror image of `nwtomata` is the `mat()` option of `nwset`: it creates a network from a Mata
matrix. `nwset` reads a missing diagonal as "no tie", but products need a diagonal of 0, so set it first. Take the number of
two-step paths between each pair, from the squared matrix:

```stata
. mata: _diag(A, 0)

. mata: P = A*A

. mata: _diag(P, 0)

. _nwsyntax flomarriage

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

Two details. `_nwsyntax` (a helper that looks up a network, see Section 4) leaves the node names of the original network in the
local macro `labs`; passing them with `labs()` gives the new network the same node names. Without `labs()` a new network's nodes are called
`n1, n2, ...`, unless the dataset already holds node names for them; stating them is the safe habit. And the network is **valued**: nwcommands decides once, when a network is created from a matrix,
and finds values other than 0 and 1. For a binary "reaches within two steps" network, build a 0/1 matrix:

```stata
. mata: R2 = ((A + A*A) :> 0)

. mata: _diag(R2, 0)

. nwset, mat(R2) name(floreach2) undirected

. nwsummarize floreach2
--------------------------------------------------
   Network name:  floreach2
   Network id:  4
   Directed: false
   Valued: false
   Two-mode: false
   Nodes: 16
   Selfloop: false
   Edges: 55
   Minimum value:  0
   Maximum value:  1
   Density:  .458
   Mean degree:  6.88
   Temporal: false
```

(`undirected` is stated because the matrix is symmetric by construction. A matrix given to `nwset, mat()` without
`undirected` makes a directed network, symmetric or not; the program in Section 4 therefore passes the direction of the original.) To change an existing network instead of creating one, use
`nwreplacemat`, with the option `newmat()`.

## 4. A reusable command

Once the pieces work, wrap them in an ado program, so that `nwreach2 glasgow2, generate(r)` behaves like any
other nwcommands command:

```stata
program nwreach2, rclass
    syntax [anything(name=netname)], GENerate(name) [NETwork(name)]
    _nwsyntax `netname'
    _nwdatasync `netname'
    confirm new variable `generate'
    tempname A
    nwtomata `netname', mat(`A')
    quietly generate double `generate' = .
    mata: st_store((1::`nodes'), "`generate'", nw_reach2(`A'))
    if "`network'" != "" {
        mata: _diag(`A', 0)
        mata: `A' = ((`A' + `A'*`A') :> 0)
        mata: _diag(`A', 0)
        local undirected = cond("`directed'" == "false", "undirected", "")
        nwset, mat(`A') name(`network') labs(`labs') `undirected'
    }
    mata: mata drop `A'
    quietly summarize `generate'
    return scalar mean = r(mean)
    return local netname "`netname'"
end
```

What is new here are the two helpers that nwcommands' own commands use (see `help nwprogramming`):

* `_nwsyntax` takes the network name (the current network if none is given), checks that it exists, and leaves
  local macros: `netname`, `netobj` (the network object), `nodes`, `directed`, `valued` (each `true` or `false`) and `labs`.
* `_nwdatasync` makes observation *i* of the dataset belong to node *i*, so that `st_store()` puts the values on the right rows.

`tempname` gives the matrix a name that cannot clash with another and `mata drop` frees it at the end. The program
returns the mean in `r(mean)`:

```stata
. drop reach2

. nwreach2 flomarriage, generate(reach2) network(floreach2b)

. return list

scalars:
               r(mean) =  6.875

macros:
            r(netname) : "flomarriage"
```

The new network `floreach2b` is the same as `floreach2` from Section 3 (55 edges, density .458; see the log). Because the function `nw_reach2()` has
to be known to Mata, define it (as above) or keep it in a library before the program is called.

## 5. Loop over the waves of a longitudinal network

A longitudinal network is a list of networks in the same session, so a loop is all that is needed. The program
does not care how the networks were created. The waves of Glasgow, with the mean two-step reach of each wave
collected in a Stata matrix:

```stata
. nwwebuse glasgow, nwclear

. matrix W = J(3, 1, .)

. local i 0

. foreach w in glasgow1 glasgow2 glasgow3 {
  2.     local ++i
  3.     nwreach2 `w', generate(reach_`w')
  4.     matrix W[`i', 1] = r(mean)
  5. }

. matrix rownames W = glasgow1 glasgow2 glasgow3

. matrix colnames W = mean_reach2

. matrix list W

W[3,1]
          mean_reach2
glasgow1         4.72
glasgow2            5
glasgow3         4.54
```

(Network lists such as `glasgow1-glasgow3` or `glasgow*`, [Tutorial 2](../02-core-concepts/), are for commands that accept
several networks; `nwreach2` takes one, so the loop names them.) The three
variables `reach_glasgow1`, `reach_glasgow2`, `reach_glasgow3` hold, per pupil, the number of pupils reached within two
friendship steps (following out-ties) at each wave, for example as input to a regression or a graph.

When all waves go into one computation (say the product of two waves' matrices), call `nwtomata` once per wave with a
different `mat()` name. The waves of one dataset share their nodes, so row *i* is the same pupil in every matrix.

## 6. Pitfalls

**The diagonal is missing, not 0.** In Mata a missing value makes every sum and product it
touches missing, and it counts as larger than any number:

```stata
. nwtomata flomarriage, mat(A)

. mata: (A*A)[1, 1..3]
       1   2   3
    +-------------+
  1 |  .   .   .  |
    +-------------+

. mata: _diag(A, 0)

. mata: (A*A)[1, 1..3]
       1   2   3
    +-------------+
  1 |  1   1   1  |
    +-------------+
```

Set the diagonal to 0 first. For the same reason `sum(S :> 0)` on a matrix with a missing diagonal counts the diagonal too:
for the valued network `samplike` it gives 106 where the network has 88 ties; after `_diag(S, 0)` it gives 88 (see the log).

**Node order.** Row *i* of a matrix is node *i*, and node *i* is dataset row *i* only when the dataset is in node order. Sort the data
and the next `st_store()` writes onto the wrong rows (or `st_data()` reads them in the wrong order).
`_nwdatasync` puts the dataset back in node order:

```stata
. sort wealth

. list _nwnode wealth in 1/3

     +---------------------+
     |    _nwnode   wealth |
     |---------------------|
  1. |      pucci        3 |
  2. |   guadagni        8 |
  3. | acciaiuoli       10 |
     +---------------------+

. _nwdatasync flomarriage

. list _nwnode wealth in 1/3

     +---------------------+
     |    _nwnode   wealth |
     |---------------------|
  1. | acciaiuoli       10 |
  2. |    albizzi       36 |
  3. |  barbadori       55 |
     +---------------------+
```

Call it at the start of any program that reads or writes node variables, as `nwreach2` does.

**Labels.** The matrix has no row names. The node names are `_nwnode` in the dataset (in node order) and the macro `labs` after `_nwsyntax`.
A new network built with `nwset, mat()` is called `n1, n2, ...` unless the dataset holds node names or you pass `labs()`. If the dataset has fewer observations than the network has nodes, `st_store()` stops with
`argument out of range` (r(3300)); it never matches by name.

**Directed networks.** Row *i* holds the ties *sent by* node *i*, column *j* the ties *received* by node *j*. Decide whether your
measure uses out-ties (row sums, `A*x`: exposure, "what do my contacts do?"), in-ties (column sums, `A'*x`) or both:

```stata
. nwtomata glasgow1, mat(G)

. mata: sum(G :!= G')
  70

. display "directed = `directed', valued = `valued', nodes = `nodes'"
directed = true, valued = false, nodes = 50
```

70 cells differ from their mirror image, so the Glasgow matrix is far from symmetric and `A*x` and `A'*x` give different answers. Use
`directed` and `valued` after `_nwsyntax` to pick the right branch, and pass `undirected` to `nwset, mat()` when the result is undirected.

**Valued networks.** The matrix holds the tie values, not 0 and 1. `A :> 0` (or `A :!= 0`) gives the presence of ties. A program
that should treat a valued network as binary must do that conversion; one that should use the values must say so in its documentation.
When you create a network from a matrix, the values decide: one value other than 0 and 1 makes it valued (see `help nwset`).

**Matrices and the network are different things.** A matrix is a copy: it does not follow later changes of the network and
nothing you do to it changes the network until you hand it back with `nwset, mat()` or `nwreplacemat`. Do not change the network
objects directly; always go through the commands.

**Memory.** An adjacency matrix has *n* x *n* cells of 8 bytes, whatever the number of ties: 50 pupils use 20,000 bytes, 10,000 nodes
about 800 MB, and a network of more than 20,000 nodes is refused. `mata describe` lists what you hold:

```stata
. mata: mata describe

      # bytes   type                        name and extent
-------------------------------------------------------------------------------
          172   real colvector              nw_nbrmean()
          192   real colvector              nw_reach2()
        2,048   real matrix                 A[16,16]
            8   class scalar                __nw
-------------------------------------------------------------------------------
```

Drop matrices you no longer need with `mata drop`, and in a program use `tempname` and drop it at the end.
For a large, sparse network, do not go through the matrix: the network object offers the ties directly (`neighbors()`, `edgelist()`;
see `help nwprogramming`), which needs memory in proportion to the number of ties. (`__nw` is the object that holds all your networks: leave it alone.)

## 7. The bridge commands at a glance

| Command | Direction | What it does |
|---|---|---|
| `nwtomata` *net*`, mat(`*name*`)` | network to Mata | copy of the adjacency matrix |
| `nwtomatafast` *net* | network to Mata | no copy: `r(mata)` holds a Mata expression for the live matrix |
| `_nwsyntax` *net* | network to program | checks the network, sets `netname`, `netobj`, `nodes`, `directed`, `valued`, `labs` |
| `_nwdatasync` *net* | dataset | puts the dataset in node order |
| `st_data()`, `st_matrix()`, `st_numscalar()` | Stata to Mata and back | variables, matrices, scalars (Mata functions) |
| `st_store()` with `st_addvar()` | Mata to Stata | a Mata vector as a node variable |
| `nwset, mat(`*name*`) name() labs()` | Mata to network | a new network from a Mata matrix |
| `nwreplacemat` *net*`, newmat(`*name*`)` | Mata to network | replaces the matrix of an existing network |
| `nwload`, `nwsync` | network and variables | the network as Stata variables, and back |

For the commands of the network itself see `help nwprogramming` and `help nwinternals`.
