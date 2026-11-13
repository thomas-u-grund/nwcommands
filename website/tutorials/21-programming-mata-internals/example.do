* Tutorial 21: Inside the Mata classes: writing your own network commands
* Run with nwcommands 3.23.0. nwnbrdegree.ado (listed on the page) must be in the
* current directory or anywhere on the adopath.

* ---- 1. The pieces: one global object __nw, a collection of networks, one object per network
nwclear
capture mata: mata describe __nw
display _rc
nwwebuse florentine, nwclear
mata: mata describe
mata: classname(__nw)
mata: classname(__nw.nws)
mata: classname(__nw.nwsder)
mata: __nw.nws.get_number()
mata: __nw.nws.names
mata: __nw.nws.get_current_name()
mata: __nw.nws.get_index_of("flomarriage")
mata: __nw.nws.get_index_of("nosuchnet")

* one network = one NWdef object, reached through a pointer
mata: P = __nw.nws.pdefs[__nw.nws.get_index_of("flomarriage")]
mata: classname(*P)
mata: P->get_name()
mata: P->get_nodes()
mata: P->is_directed(), P->is_valued(), P->is_2mode(), P->is_temporal()
mata: P->is_directed_boolean(), P->is_valued_boolean()

* the same pointer as a macro: what _nwsyntax leaves behind
_nwsyntax flomarriage
display "`netobj'"
display "`nodes' nodes, directed: `directed', valued: `valued', two-mode: `is2mode'"
display "`labs'"
display "`id'"

* ---- 2. Reading a network without copying it
mata: P->get_nodenames()[1..4]
mata: P->get_nodesvar()[1..3]
mata: P->get_nodeid_from_nodename("medici")
mata: P->get_nodeid_from_nodename("nosuchfamily")
mata: P->has_node("medici")
mata: P->get_outdegree(0)'
mata: P->neighbors(1)'
mata: P->has_edge(1, 9), P->has_edge(1, 2)
mata: P->edgelist()[1..3, .]
mata: rows(P->edgelist())

* the adjacency matrix: a pointer to the stored matrix, not a copy
mata: A = P->get_matrix()
mata: rows(*A), cols(*A)
mata: (*A)[1..3, 1..3]
mata: C = P->get_matrix_copy()

* node attributes are ordinary variables, in node order after _nwdatasync
_nwdatasync flomarriage
describe
mata: wealth = st_data(., "wealth")
mata: wealth[1..4]'
mata: mean(wealth[P->neighbors(1)])

* a write through the pointer reaches the network, but not its sparse index
mata: M = (0, 1, 0 \ 0, 0, 1 \ 0, 0, 0)
nwset, mat(M) name(demo) directed
mata: D = __nw.nws.pdefs[__nw.nws.get_index_of("demo")]
mata: D->edge_weight(1, 2)
mata: pD = D->get_matrix()
mata: (*pD)[1, 2] = 5
mata: (*D->get_matrix())[1, 2]
mata: D->edge_weight(1, 2)
* work on a copy and hand it back with set_edge(): everything is rebuilt
mata: X = D->get_matrix_copy()
mata: X[1, 2] = 5
mata: D->set_edge(X)
mata: D->edge_weight(1, 2)
nwdrop demo
mata: mata drop M D pD X

* ---- 3. A new command
nwwebuse florentine, nwclear
nwnbrdegree flomarriage, generate(nbdeg)
return list
list _nwnode nbdeg in 1/5

* check against a direct computation on the matrix (the diagonal is missing: set it to 0 first)
mata: A = P->get_matrix_copy()
mata: _diag(A, 0)
mata: d = rowsum(A)
mata: check = (A * d) :/ d
mata: check[1..5]'
mata: max(abs(check[selectindex(d :> 0)] - st_data(selectindex(d :> 0), "nbdeg")))

nwnbrdegree flomarriage, generate(nbdeg) replace ego(medici)
display r(ego)
nwnbrdegree flomarriage, generate(nbdeg2) ego(3)
display r(ego)

* a directed network: out-neighbors, mean of their outdegrees
nwwebuse glasgow, nwclear
nwnbrdegree glasgow1, generate(nb1)
display r(mean)
display r(isolates)
summarize nb1

* ---- 4. Creating, replacing and deleting networks
nwclear
nwwebuse florentine, nwclear
mata: W = (0, 1, 2 \ 1, 0, 0 \ 2, 0, 0)
mata: W
nwset, mat(W) name(small) labs(a,b,c) undirected
nwsummarize small
capture nwset, mat(W) name(small) labs(a,b,c) undirected
display _rc
mata: W[1, 2] = 7; W[2, 1] = 7
nwset, mat(W) name(small) labs(a,b,c) undirected replace
mata: __nw.nws.pdefs[__nw.nws.get_index_of("small")]->edge_weight(1, 2)
nwcurrent
mata: __nw.nws.get_valid_name("small")
nwdrop small
mata: mata drop W
nwset

* the registration that nwset does, step by step
mata: T = (0, 1, 0 \ 1, 0, 2 \ 0, 2, 0)
mata: __nw.nws.add("tiny")
mata: N = __nw.nws.pdefs[__nw.nws.get_index_of("tiny")]
mata: N->create_by_name(("a", "b", "c"))
mata: N->get_name()
mata: N->set_name("tiny")
mata: N->set_edge(T)
mata: N->set_directed(0)
mata: N->set_selfloop(0)
mata: N->set_valued(N->check_valued())
nwset
nwsummarize tiny
mata: N->neighbors(2)'
mata: __nw.nws.rename("tiny", "tiny2")
nwset
nwdrop tiny2
mata: mata drop T N

* ---- 5. Size, speed and safety
nwrandom 25000, prob(.0002) name(huge)
mata: H = __nw.nws.pdefs[__nw.nws.get_index_of("huge")]
mata: H->get_nodes()
mata: H->is_dense_built()
nwnbrdegree huge, generate(nb)
summarize nb
mata: H->is_dense_built()
capture mata: A = H->get_matrix()
display _rc
capture noisily nwtomata huge, mat(Z)
display _rc
nwdrop huge
nwrandom 3000, prob(.002) name(mid)
mata: H = __nw.nws.pdefs[__nw.nws.get_index_of("mid")]
mata: H->is_dense_built()
mata: A = H->get_matrix()
mata: H->is_dense_built()
mata: rows(*A)
nwdrop mid
mata: mata drop A H

* ---- 6. Errors
nwwebuse florentine, nwclear
mata: P = __nw.nws.pdefs[__nw.nws.get_index_of("flomarriage")]
capture nwnbrdegree flomarriage, generate(_nwnode)
display _rc
capture nwnbrdegree nosuchnet, generate(z)
display _rc
capture nwnbrdegree flomarriage, generate(z) ego(nosuchfamily)
display _rc
capture nwnbrdegree flomarriage flobusiness, generate(z)
display _rc
capture mata: __nw.nws.add("flomarriage")
display _rc
capture mata: __nw.nws.add("bad name")
display _rc
capture mata: error_handle("no such node\n", 485)
display _rc
capture mata: P->neighbors(99)
display _rc
capture mata: P->has_edge(1, 99)
display _rc
capture mata: __nw.nws.drop("nosuchnet")
display _rc
capture mata: __nw.nws.delete_name("flobusiness")
display _rc
nwset
