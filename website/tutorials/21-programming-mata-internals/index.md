---
title: "Tutorial 21: Inside the Mata classes: writing your own network commands"
parent: "nwcommands (core)"
nav_order: 21
description: "Advanced: the hidden Mata classes behind nwcommands (the collection of networks, one network object, the helper functions) and a complete small command written against them."
---

# Tutorial 21: Inside the Mata classes: writing your own network commands

[Tutorial 20](../20-programming-mata-bridge/) showed how to move a network between Stata and Mata with
`nwtomata` and `nwset`. That is the supported, stable way to write your own network code. This tutorial goes one level
down: it opens the Mata classes in which nwcommands keeps its networks, reads a network *in place* (no copy), writes a
complete command against them, and registers a new network in the collection by hand. It is for readers who know Mata
classes, structs and pointers.

> **These classes are not a stable public API.** The classes, their methods and their signatures are internal to
> nwcommands and may change between minor releases, without notice. Everything on this page was run with
> **nwcommands 3.23.0** (Stata 17 and 18 give identical output); pin that version if you
> depend on it, and after an update re-run your code before you trust it. If a call fails after an update, look first at
> the release notes of the new version (`nwversion` shows your installed version). For anything that has to last, prefer the commands themselves, `nwtomata` and `nwset`
> (Tutorial 20): their syntax is documented and kept stable. Only methods that were checked in the source and in a
> real run are shown here; there are many more in the library, and most of them are not safe to call without reading
> their source.
{: .warning }

The full output of every example below is in `example.do` and `example.log` next to this page.

## 1. How the pieces fit

Networks live in Mata, next to the Stata dataset, not in variables. Everything hangs off **one global Mata object
named `__nw`**:

| Object | Mata class | What it is |
|---|---|---|
| `__nw` | `nws` | the top-level object; created by `nws_create()` |
| `__nw.nws` | `nws_def` (source name `NWsdef`) | the **collection**: network names, a pointer to each network, the current network |
| `__nw.nwsder` | `nws_der` | derived bookkeeping for `_nwdatasync` (a data signature) |
| `__nw.nws.pdefs[i]` | pointer to `nw_def` (source name `NWdef`) | **one network** |

The ado layer creates `__nw` on demand: the commands that bring in a first network (`nwset`, `nwfromedge`, `nwload`
and others) call `nws_create()` when no `__nw` exists, and `nwclear` removes it. Without any network the object is
simply not there, and a command that needs it stops with error 482 ("network not found"):

```stata
. nwclear

. capture mata: mata describe __nw

. display _rc
111

. nwwebuse florentine, nwclear

. mata: mata describe

      # bytes   type                        name and extent
-------------------------------------------------------------------------------
            8   class scalar                __nw
-------------------------------------------------------------------------------

. mata: classname(__nw)
  nws

. mata: classname(__nw.nws)
  nws_def

. mata: classname(__nw.nwsder)
  nws_der
```

The collection keeps three things: `names` (a row vector of network names), `pdefs` (a row vector of **pointers**, one
per network, in the same order) and the current network. Ask it with methods, not with fields: the field `number`
exists but is not kept up to date, `get_number()` is the reliable count.

```stata
. mata: __nw.nws.get_number()
  2

. mata: __nw.nws.names
                 1             2
    +-----------------------------+
  1 |  flobusiness   flomarriage  |
    +-----------------------------+

. mata: __nw.nws.get_current_name()
  flomarriage

. mata: __nw.nws.get_index_of("flomarriage")
  2

. mata: __nw.nws.get_index_of("nosuchnet")
  0
```

`get_index_of()` returns 0 when the name is not there; that 0 is yours to check, as an index of 0 stops with a raw
subscript error (3301) when you use it. A network is then an object you reach through a pointer:

```stata
. mata: P = __nw.nws.pdefs[__nw.nws.get_index_of("flomarriage")]

. mata: classname(*P)
  nw_def

. mata: P->get_name()
  flomarriage

. mata: P->get_nodes()
  16

. mata: P->is_directed(), P->is_valued(), P->is_2mode(), P->is_temporal()
           1       2       3       4
    +---------------------------------+
  1 |  false   false   false   false  |
    +---------------------------------+

. mata: P->is_directed_boolean(), P->is_valued_boolean()
       1   2
    +---------+
  1 |  0   0  |
    +---------+
```

Every flag comes in two forms: `is_directed()` returns the *string* `"true"` or `"false"` (handy for `st_local()` and
for comparing with a local macro), `is_directed_boolean()` the number 0 or 1. The same pair exists for `valued`,
`2mode`, `selfloop` and `temporal`.

What a network object stores (the fields; use the methods to read them): the name, a label and caption, the node names
(`get_nodenames()`) and the names of the Stata variables the nodes would get when loaded (`get_nodesvar()`); the four
flags above; for a two-mode network the mode of every node; optional temporal information (snapshot, interval or event
data); and the ties themselves, in two forms that always describe the same network: a **sparse index** (for every node,
its out-neighbors and tie values, and for a directed network its in-neighbors) and the dense **adjacency matrix**. Each
is built from the other the first time it is needed. A network created from a list of ties starts with the sparse index
only (section 5).

### What `_nwsyntax` hands you

Commands do not search `__nw.nws.names` themselves. `_nwsyntax` resolves the network name the user typed (an
abbreviation, a netlist, or nothing for the current network) and leaves local macros in the calling program:

```stata
. _nwsyntax flomarriage

. display "`netobj'"
__nw.nws.pdefs[2]

. display "`nodes' nodes, directed: `directed', valued: `valued', two-mode: `is2mode'"
16 nodes, directed: false, valued: false, two-mode: false

. display "`labs'"
acciaiuoli,albizzi,barbadori,bischeri,castellani,ginori,guadagni,lamberteschi,medi
> ci,pazzi,peruzzi,pucci,ridolfi,salviati,strozzi,tornabuoni

. display "`id'"
2
```

The macro `netobj` is not a value but a piece of Mata *source text*: the pointer expression to the network. That is why
the idiom in a command is ``mata: `netobj'->get_nodes()``, and why the same text works inside any Mata function you
call with it (section 3).

## 2. Reading a network without copying it

Node `i` of a network is observation `i` of the dataset; all methods count nodes from 1 and use that order. A few
read methods of the network object (all of them read the sparse index and need memory in proportion to the number of
ties):

```stata
. mata: P->get_nodenames()[1..4]
                1            2            3            4
    +-----------------------------------------------------+
  1 |  acciaiuoli      albizzi    barbadori     bischeri  |
    +-----------------------------------------------------+

. mata: P->get_nodeid_from_nodename("medici")
  9

. mata: P->get_nodeid_from_nodename("nosuchfamily")
  -1

. mata: P->has_node("medici")
  1

. mata: P->get_outdegree(0)'
        1    2    3    4    5    6    7    8    9   10   11   12   13   14   15
    +----------------------------------------------------------------------------
  1 |   1    3    2    3    3    1    4    1    6    1    3    0    3    2    4
    +----------------------------------------------------------------------------
       16
     ------+
  1     3  |
     ------+

. mata: P->neighbors(1)'
  9

. mata: P->has_edge(1, 9), P->has_edge(1, 2)
       1   2
    +---------+
  1 |  1   0  |
    +---------+

. mata: P->edgelist()[1..3, .]
       1   2   3
    +-------------+
  1 |  1   9   1  |
  2 |  2   6   1  |
  3 |  2   7   1  |
    +-------------+

. mata: rows(P->edgelist())
  40
```

`get_outdegree(0)` (and `get_indegree(0)`) return one value per node as a column vector; the argument is the exponent
of the tie values in a valued network (0 counts ties, 1 sums their values). `neighbors(i)` is the column vector of the
*out*-neighbors of node `i` (all neighbors in an undirected network) and `neighbors_in(i)` the in-neighbors.
`edgelist()` gives all ties as a matrix of sender, receiver and tie value; an undirected tie is listed in both
directions (40 rows for the 20 marriages). A missing node name gives `-1` from `get_nodeid_from_nodename()`.

### The adjacency matrix: a pointer, not a copy

`get_matrix()` returns a **pointer** to the matrix stored inside the network. Nothing is copied; `get_matrix_copy()`
returns a copy you may change:

```stata
. mata: A = P->get_matrix()

. mata: rows(*A), cols(*A)
        1    2
    +-----------+
  1 |  16   16  |
    +-----------+

. mata: (*A)[1..3, 1..3]
[symmetric]
       1   2   3
    +-------------+
  1 |  .          |
  2 |  0   .      |
  3 |  0   0   .  |
    +-------------+

. mata: C = P->get_matrix_copy()
```

Note the diagonal: in a network without self-loops the diagonal of the stored matrix is **missing** (`.`), not 0. A
matrix product such as `*A * *A` is therefore missing everywhere; copy first and set the diagonal with `_diag(C, 0)`
(done in section 3). In an undirected network the matrix is stored symmetric.

### Node attributes are ordinary variables

Attributes of nodes are not kept in the network object. They are Stata variables, row `i` for node `i`, and
`_nwdatasync` makes sure the rows are in the order of the network:

```stata
. _nwdatasync flomarriage

. describe

Contains data from https://nwcommands.org/examples/florentine.nwdta
 Observations:            16                  
    Variables:             5                  16 May 2019 17:02
----------------------------------------------------------------------------------
Variable      Storage   Display    Value
    name         type    format    label      Variable label
----------------------------------------------------------------------------------
_nwnode         str12   %12s                  
wealth          float   %9.0g                 
priorates       float   %9.0g                 
seat            float   %9.0g                 
_nwinclude      float   %9.0g                 
----------------------------------------------------------------------------------
Sorted by: 
     Note: Dataset has changed since last saved.

. mata: wealth = st_data(., "wealth")

. mata: wealth[1..4]'
        1    2    3    4
    +---------------------+
  1 |  10   36   55   44  |
    +---------------------+

. mata: mean(wealth[P->neighbors(1)])
  103
```

The mean wealth of the neighbors of the first family (the Medici, at 103) is one line: neighbors are node numbers,
and node numbers are row numbers.

### The pointer reaches the network but not its sparse index

Because `get_matrix()` is the stored matrix, a write through it changes the network. It does **not** tell the sparse
index, which was built from the old matrix. After such a write the two descriptions of the network disagree:

```stata
. mata: M = (0, 1, 0 \ 0, 0, 1 \ 0, 0, 0)

. nwset, mat(M) name(demo) directed

. mata: D = __nw.nws.pdefs[__nw.nws.get_index_of("demo")]

. mata: D->edge_weight(1, 2)
  1

. mata: pD = D->get_matrix()

. mata: (*pD)[1, 2] = 5

. mata: (*D->get_matrix())[1, 2]
  5

. mata: D->edge_weight(1, 2)
  1
```

`edge_weight()` still reads the old value from the sparse index. The safe way to change a network is to change a copy
and hand it back with `set_edge()`, which resets and rebuilds the sparse index:

```stata
. mata: X = D->get_matrix_copy()

. mata: X[1, 2] = 5

. mata: D->set_edge(X)

. mata: D->edge_weight(1, 2)
  5

. nwdrop demo

. mata: mata drop M D pD X
```

The rule: **read** through `get_matrix()` or the neighbor methods, **write** only with `set_edge()` or a command such
as `nwreplace`. A stale pointer is also a risk after the network is replaced or dropped: fetch `pdefs[i]` again
instead of keeping pointers across commands that may change the collection.

## 3. A worked example: a new command

The command `nwnbrdegree` computes, for every node, the mean degree of its neighbors (a simple measure of how
well-connected a node's contacts are). It stores the result in a variable, returns the mean in `r()`, and takes an
optional `ego()` to return the value of one node. Save this as `nwnbrdegree.ado` in your current directory (or
anywhere on the adopath):

```stata
capture program drop nwnbrdegree
program nwnbrdegree, rclass
	version 17
	syntax [anything(name=netname)], GENerate(name) [replace EGO(string)]

	unw_defs                                  // error-code locals (`errTwoModeUnsupported' ...) and the names of the Mata objects
	_nwsyntax `netname'                       // resolves the name; leaves `netobj', `nodes', `directed', `valued', ...

	if "`is2mode'" == "true" {
		display as error "nwnbrdegree does not support two-mode networks"
		exit `errTwoModeUnsupported'
	}
	if "`replace'" == "" confirm new variable `generate'    // r(110) if the variable exists
	if `"`ego'"' != "" {
		_nwnodeid `netname', nodelab(`ego')   // node name or number -> r(nodeid); stops with r(485) if there is no such node
		local egoid = r(nodeid)
	}
	_nwdatasync `netname'                     // observation i of the dataset = node i of the network

	capture drop `generate'
	quietly generate double `generate' = .
	mata: nwnbr_run(`netobj', "`generate'")

	if `"`ego'"' != "" return scalar ego = `generate'[`egoid']
	return scalar N        = `nodes'
	return scalar mean     = scalar(__nwnbr_mean)
	return scalar isolates = scalar(__nwnbr_iso)
	return local  netname  "`netname'"
	return local  directed "`directed'"
	scalar drop __nwnbr_mean __nwnbr_iso
end

mata:
void nwnbr_run(pointer(class nw_def scalar) scalar net, string scalar varname)
{
	real scalar i, n, iso
	real colvector deg, res, nb

	n   = net->get_nodes()
	deg = net->get_outdegree(0)           // number of out-ties per node (all ties if undirected), one value per node
	res = J(n, 1, .)
	iso = 0
	for (i = 1; i <= n; i++) {
		nb = net->neighbors(i)            // out-neighbors of node i, read from the sparse index
		if (rows(nb) == 0) {
			iso++
			continue
		}
		res[i] = mean(deg[nb])
	}
	st_store((1::n), varname, res)
	st_numscalar("__nwnbr_mean", mean(res))
	st_numscalar("__nwnbr_iso", iso)
}
end
```

The pattern is the one the commands of the core follow, in this order:

1. **`syntax`** takes the network as an optional leading `[anything(name=netname)]`, so that the current network is
   used when none is named. Results that are new variables go into `generate()`, new networks into `name()`; `replace`
   allows overwriting.
2. **`unw_defs`** defines the error-code locals (`errNWsNotFound`, `errTwoModeUnsupported`, ...), and the locals `nw`, `nws` and `nwsder`
   with the names of the Mata objects. Call it once, near the top.
3. **`_nwsyntax `netname'`** resolves the network. It stops with 482 if the network does not exist and with 198 if the
   user gave more networks than the command accepts (`max(#)` raises the limit for commands that take a netlist). It
   leaves `netname` (unabbreviated), `netobj`, `nodes`, `directed`, `valued`, `selfloops`, `is2mode`, `istemporal`,
   `labs`, `id` and `networks` as locals. Check the properties your measure cannot handle *now*, with the code that
   documents them.
4. **`_nwdatasync`** before you store anything per node: it makes observation `i` of the dataset the node `i` of the
   network.
5. **Compute in a Mata function** that takes the pointer, and pass it the text of ``netobj`` (the Mata function above
   has a pointer-to-`nw_def` argument). Mata loops over `neighbors(i)` stay in the sparse index, so the command works
   on networks of any size. Because the function is defined in the same file as the program, nothing else needs to be
   installed.
6. **Results**: node-level results to variables with `st_store()`; scalars and matrices to `r()` with `return`
   (a `return` value is visible in `r()` only after the program has ended). The scalars used to pass numbers out of
   Mata are dropped before the program ends.

Run it on the marriage network. The first five values can be checked by eye: the Acciaiuoli family has one tie, to the
Medici, who have six:

```stata
. nwwebuse florentine, nwclear

. nwnbrdegree flomarriage, generate(nbdeg)

. return list

scalars:
           r(isolates) =  1
               r(mean) =  3.544444444444444
                  r(N) =  16

macros:
           r(directed) : "false"
            r(netname) : "flomarriage"

. list _nwnode nbdeg in 1/5

     +------------------------+
     |    _nwnode       nbdeg |
     |------------------------|
  1. | acciaiuoli           6 |
  2. |    albizzi   3.6666667 |
  3. |  barbadori         4.5 |
  4. |   bischeri   3.6666667 |
  5. | castellani           3 |
     +------------------------+
```

A check against a direct computation on the adjacency matrix (a second implementation: the neighbor sums by matrix
product, with the diagonal set to 0 first). The largest absolute difference over all nodes with at least one tie is 0:

```stata
. mata: A = P->get_matrix_copy()

. mata: _diag(A, 0)

. mata: d = rowsum(A)

. mata: check = (A * d) :/ d

. mata: check[1..5]'
                 1             2             3             4             5
    +-----------------------------------------------------------------------+
  1 |            6   3.666666667           4.5   3.666666667             3  |
    +-----------------------------------------------------------------------+

. mata: max(abs(check[selectindex(d :> 0)] - st_data(selectindex(d :> 0), "nbdeg")))
  0
```

The `ego()` option accepts a node name or a node number, through the helper `_nwnodeid`, which leaves `r(nodeid)` or
stops with 485:

```stata
. nwnbrdegree flomarriage, generate(nbdeg) replace ego(medici)

. display r(ego)
2.3333333

. nwnbrdegree flomarriage, generate(nbdeg2) ego(3)

. display r(ego)
4.5
```

On a directed network the same code takes the out-neighbors and their outdegrees (Glasgow friendship nominations, wave
1; four pupils nominate nobody and have no value):

```stata
. nwwebuse glasgow, nwclear

. nwnbrdegree glasgow1, generate(nb1)

. display r(mean)
2.6293478

. display r(isolates)
4

. summarize nb1

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         nb1 |         46    2.629348    .7343779          1          5
```

Which direction a measure needs is a modelling decision you have to make explicitly for directed networks:
`neighbors(i)` for what node `i` sends, `neighbors_in(i)` for what it receives, both for questions about its
surroundings. Valued networks need a decision too: `get_outdegree(0)` counts ties whatever their value, with exponent
1 it sums the values.

## 4. Creating, replacing and deleting networks

The supported way to create a network from a Mata matrix is `nwset` with `mat()` (Tutorial 20). It checks the matrix,
chooses the node names, sets the flags, aligns the nodes with the dataset and syncs the variables. A network name must
be a valid Stata name; an existing name is refused with 483 unless `replace` is given:

```stata
. nwclear

. nwwebuse florentine, nwclear

. mata: W = (0, 1, 2 \ 1, 0, 0 \ 2, 0, 0)

. mata: W
[symmetric]
       1   2   3
    +-------------+
  1 |  0          |
  2 |  1   0      |
  3 |  2   0   0  |
    +-------------+

. nwset, mat(W) name(small) labs(a,b,c) undirected

. nwsummarize small
--------------------------------------------------
   Network name:  small
   Network id:  3
   Directed: false
   Valued: true
   Two-mode: false
   Nodes: 3
   Selfloop: false
   Edges: 2
   Minimum value:  0
   Maximum value:  2
   Density:  .667
   Mean degree:  1.33
   Temporal: false

. capture nwset, mat(W) name(small) labs(a,b,c) undirected

. display _rc
483

. mata: W[1, 2] = 7; W[2, 1] = 7

. nwset, mat(W) name(small) labs(a,b,c) undirected replace

. mata: __nw.nws.pdefs[__nw.nws.get_index_of("small")]->edge_weight(1, 2)
  7

. nwcurrent
----------------------------------------
   Current network:  small
   Number of nodes:  3
----------------------------------------
```

Note that the new network became the current one, and that the valued flag was set from the matrix (it has a tie value
of 2). The collection can suggest a free name: `get_valid_name()` returns the name itself if it is free and
`name_1`, `name_2`, ... otherwise:

```stata
. mata: __nw.nws.get_valid_name("small")
  small_1
```

To delete a network use the command `nwdrop`, not the collection's own `drop()`: after the deletion `nwdrop` brings
the current network and the registry up to date (and removes `__nw` with the last network). Free your own Mata
matrices as well:

```stata
. nwdrop small

. mata: mata drop W

. nwset
(2 networks)
--------------------
      flobusiness
      flomarriage
```

### The registration, step by step

For completeness, here is what `nwset` does at its core. Calling these methods yourself is only worthwhile when a
command builds a network whose ties it already holds in the right form, and you accept the duties listed below:

```stata
. mata: T = (0, 1, 0 \ 1, 0, 2 \ 0, 2, 0)

. mata: __nw.nws.add("tiny")

. mata: N = __nw.nws.pdefs[__nw.nws.get_index_of("tiny")]

. mata: N->create_by_name(("a", "b", "c"))

. mata: N->get_name()
  

. mata: N->set_name("tiny")

. mata: N->set_edge(T)

. mata: N->set_directed(0)

. mata: N->set_selfloop(0)

. mata: N->set_valued(N->check_valued())

. nwset
(3 networks)
--------------------
      flobusiness
      flomarriage
      tiny

. nwsummarize tiny
--------------------------------------------------
   Network name:  tiny
   Network id:  3
   Directed: false
   Valued: true
   Two-mode: false
   Nodes: 3
   Selfloop: false
   Edges: 2
   Minimum value:  0
   Maximum value:  2
   Density:  .667
   Mean degree:  1.33
   Temporal: false

. mata: N->neighbors(2)'
       1   2
    +---------+
  1 |  1   3  |
    +---------+
```

The duties, each of them learned the hard way:

* `add(name)` registers an empty network and makes it current; it stops with 483 if the name exists and with 198 if the
  name is not a valid Stata name.
* `create_by_name()` sets the node names and **clears the network's own name**, as the line `N->get_name()` above
  shows (it prints nothing). Call `set_name()` afterwards, or the network cannot be found by name (`nwcurrent` fails).
* The self-loop flag starts unset. Without `set_selfloop(0)` the diagonal of the stored matrix stays 0 instead of
  missing, and densities differ; call it, in this order, after `set_edge()`.
* `set_valued(N->check_valued())` derives the valued flag from the ties; `set_directed()` takes 0 or 1. For an
  undirected network the matrix you pass must be symmetric: no method does that for you here (`nwsym` does it
  afterwards).
* The new network is not yet aligned with the data: `nwset` also calls `_nwdatasync` and reorders the nodes to the row
  order of the dataset. After a low-level registration call `_nwdatasync` yourself.

`rename(old, new)` renames a registered network (it checks the new name). Deleting through the collection's `drop(name)`
removes the network from the lists but does not update the current network, and a name that is not there stops with a
raw 3301. This is the reason for the advice to use `nwdrop`:

```stata
. mata: __nw.nws.rename("tiny", "tiny2")

. nwset
(3 networks)
--------------------
      flobusiness
      flomarriage
      tiny2

. nwdrop tiny2

. mata: mata drop T N
```

## 5. Size, speed and safety

**Avoid the matrix.** A network of `n` nodes has an `n` x `n` matrix; at 25,000 nodes that is 4.66 GB. Networks
created from a tie list or by a generator above 2,000 nodes exist as their sparse index only, and `get_matrix()` builds
the matrix on first demand, up to 20,000 nodes. Above that it stops with 484, as does `nwtomata`. A command that reads
the sparse index never triggers any of this. Here a directed random network of 25,000 nodes, on which `nwnbrdegree`
never builds the matrix:

```stata
. nwrandom 25000, prob(.0002) name(huge)

. mata: H = __nw.nws.pdefs[__nw.nws.get_index_of("huge")]

. mata: H->get_nodes()
  25000

. mata: H->is_dense_built()
  0

. nwnbrdegree huge, generate(nb)

. summarize nb

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
          nb |     24,854    5.003669    1.118926          0         13

. mata: H->is_dense_built()
  0

. capture mata: A = H->get_matrix()

. display _rc
484

. capture noisily nwtomata huge, mat(Z)
Network `huge' has 25000 nodes; materializing a dense 25000x25000 matrix would req
> uire approximately 4.66 GB and has been refused. Use a sparse-native command (ne
> ighbors(), degree(), calculate_components(), etc.) instead, which never requires
>  the dense matrix.
. display _rc
484

. nwdrop huge
```

On a smaller network the matrix is built when first asked for, and stays:

```stata
. nwrandom 3000, prob(.002) name(mid)

. mata: H = __nw.nws.pdefs[__nw.nws.get_index_of("mid")]

. mata: H->is_dense_built()
  0

. mata: A = H->get_matrix()

. mata: H->is_dense_built()
  1

. mata: rows(*A)
  3000

. nwdrop mid

. mata: mata drop A H
```

**Other rules for fast, safe code**

* *Pass pointers, not matrices.* Functions that take `pointer(class nw_def scalar)` or `pointer(real matrix)` copy
  nothing. `get_matrix_copy()` and the `*_copy` methods allocate; call them once, outside loops.
* *One step per node, not per tie.* `neighbors(i)` is a vector; vectorize over it (as `mean(deg[nb])` does) rather
  than looping over its elements, and call `get_outdegree(0)` once instead of `degree(i)` for every `i`.
* *Node order is row order.* Node `i` is observation `i` only after `_nwdatasync`, and `st_store()` fails or writes to
  the wrong nodes without it.
* *Undirected means symmetric.* In an undirected network `neighbors(i)` returns all neighbors, the matrix is symmetric,
  and `edgelist()` lists each tie in both directions. A direct write to one cell must change both cells.
* *Valued versus binary.* Decide it and say it: `get_outdegree(0)`
  counts ties, and tie values of 0 are not ties.
* *Do not reimplement what exists.* The expensive algorithms (shortest paths, betweenness, components, cliques,
  communities, motif and triad counts, clustering and several more) run in a compiled plugin, called once per command,
  with a slower Mata fallback when the plugin is missing. Call the command (`nwbetween`, `nwgeodesic`, ...) from your
  program and read its variable or `r()` result instead of writing the loop again in Mata; the Mata classes are for the
  measures that do not exist yet.

## 6. Errors and return codes

A command that fails should fail with the code the other commands use for the same problem, so that users can
`capture` it. The codes are listed in `help nwerrorcodes`; the ones a new command meets most often:

| Code | Meaning | Where it comes from |
|---|---|---|
| 110 | a Stata *variable* already exists; give `replace` or another name | `confirm new variable` |
| 198 | invalid syntax; too many networks; not a valid network name | `syntax`, `_nwsyntax`, `add()` |
| 482 | network not found | `_nwsyntax` |
| 483 | a *network* with that name already exists | `add()`, `nwset` without `replace` |
| 484 | the network is too large to materialize as a matrix | `get_matrix()`, `nwtomata` |
| 485 | a node (name or number) does not exist | `_nwnodeid` |

All of these come out of the `nwnbrdegree` above and the calls of the previous sections:

```stata
. nwwebuse florentine, nwclear

. mata: P = __nw.nws.pdefs[__nw.nws.get_index_of("flomarriage")]

. capture nwnbrdegree flomarriage, generate(_nwnode)

. display _rc
110

. capture nwnbrdegree nosuchnet, generate(z)

. display _rc
482

. capture nwnbrdegree flomarriage, generate(z) ego(nosuchfamily)

. display _rc
485

. capture nwnbrdegree flomarriage flobusiness, generate(z)

. display _rc
198

. capture mata: __nw.nws.add("flomarriage")

. display _rc
483

. capture mata: __nw.nws.add("bad name")

. display _rc
198

. capture mata: error_handle("no such node\n", 485)

. display _rc
485
```

Inside a program, use the locals from `unw_defs` instead of the bare numbers (`exit `errNWsNotFound'``), print the
message first (`display as error`) and then `exit` with the code. In Mata, the library function
`error_handle("message\n", code)` prints the message and exits with the code (last call above).

The raw methods are less careful than the commands. Many do not check their arguments, and what you get is a Mata
error or, worse, a quiet answer:

```stata
. capture mata: P->neighbors(99)

. display _rc
3301

. capture mata: P->has_edge(1, 99)

. display _rc
0

. capture mata: __nw.nws.drop("nosuchnet")

. display _rc
3301

. capture mata: __nw.nws.delete_name("flobusiness")

. display _rc
3253
```

`neighbors(99)` on a network of 16 nodes stops with a subscript error, `has_edge(1, 99)` answers 0 without complaint,
`drop()` of an unknown name stops with a subscript error, and `delete_name()` does not accept a name at all (error 3253,
type mismatch): use `nwdrop`. Check node numbers and names against `get_nodes()` and `get_index_of()` before you use
them, and turn your own failures into the codes above.

## 7. Reference: the methods used on this page

`nw` is a pointer to a network (`__nw.nws.pdefs[i]`, or the text of ``netobj``); `nws` is `__nw.nws`.

| Call | Returns / does |
|---|---|
| `nws.get_number()` | number of networks |
| `nws.names` | row vector of network names (field) |
| `nws.pdefs[i]` | pointer to the `i`th network (field) |
| `nws.get_index_of(name)` | index of the network, 0 if absent |
| `nws.get_current_name()` | name of the current network |
| `nws.get_valid_name(name)` | `name` if free, otherwise `name_1`, `name_2`, ... |
| `nws.add(name)` | registers an empty network, makes it current; 483 if the name exists, 198 if invalid |
| `nws.rename(old, new)` | renames a network; 482 if `old` is absent |
| `nws.drop(name)` | removes a network from the lists (use `nwdrop`) |
| `nw->get_name()`, `set_name(s)` | the network name |
| `nw->get_nodes()` | number of nodes |
| `nw->get_nodenames()`, `get_nodesvar()` | node names; names of the variables for the nodes |
| `nw->get_nodeid_from_nodename(s)`, `has_node(s)` | node number (-1 if absent); 1 or 0 |
| `nw->is_directed()`, `is_valued()`, `is_2mode()`, `is_temporal()`, `is_selfloop()` | `"true"` or `"false"` |
| `nw->is_directed_boolean()`, `is_valued_boolean()`, ... | 0 or 1 |
| `nw->set_directed(0/1)`, `set_selfloop(0/1)`, `set_valued(0/1)` | set a flag |
| `nw->check_valued()` | 1 if the ties are not all 0/1 |
| `nw->neighbors(i)`, `neighbors_in(i)` | column vector of out- or in-neighbors of node `i` |
| `nw->get_outdegree(a)`, `get_indegree(a)` | column vector over all nodes; `a` = 0 counts ties |
| `nw->has_edge(i, j)`, `edge_weight(i, j)` | 1 or 0; value of the tie (0 if none); no range check |
| `nw->edgelist()` | matrix of sender, receiver, value |
| `nw->get_matrix()` | pointer to the stored matrix (diagonal missing without self-loops); 484 if too large |
| `nw->get_matrix_copy()` | a copy of the matrix |
| `nw->is_dense_built()` | 1 if the matrix exists, 0 if the network is held as sparse index only |
| `nw->create_by_name(names)` | sets the node names and an empty matrix; clears the network name |
| `nw->set_edge(M)` | takes a matrix, rebuilds the sparse index |
| `_nwsyntax`, `_nwdatasync`, `_nwnodeid`, `unw_defs` | ado helpers described in section 3 |
| `error_handle(msg, code)` | Mata: print and exit with a return code |

What this tutorial left out, on purpose: the temporal and two-mode parts of the network object, the persistence methods
behind `nwsave` and `nwuse`, the many `calculate_*` methods that run the algorithms of the commands, and everything
that changes a network in place (dropping nodes, symmetrizing, permuting). They exist, they are tied closely to the
sparse index and the plugin, and they are the part most likely to change. For the model packages, which are built on the
same objects, see their own documentation.
