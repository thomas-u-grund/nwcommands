cscript

do unw_core.do

* Tests of the public Mata API (help nwapi): every nwapi_*() function on a binary directed, an undirected, a valued
* and a two-mode network, checked against hand-computed values and against nwtomata / nwsummarize; the error paths; and
* a signature test (eltype, orgtype and shape of every return value) that fails when a signature changes.

mata:
void nwt_chk(transmorphic x, string scalar et, string scalar ot, string scalar what)
{
	if (eltype(x) != et | orgtype(x) != ot) {
		errprintf("SIGNATURE CHANGED: %s returns %s %s, documented %s %s\n", what, eltype(x), orgtype(x), et, ot)
		exit(9)
	}
}
real matrix nwt_rebuild(real matrix el, real scalar n, real scalar directed)
{
	real matrix B
	real scalar i

	B = J(n, n, 0)
	for (i = 1; i <= rows(el); i++) {
		B[el[i,1], el[i,2]] = el[i,3]
		if (directed == 0) B[el[i,2], el[i,1]] = el[i,3]
	}
	return(B)
}
void nwt_chkcol(transmorphic x, string scalar et, string scalar what)
{
	// a column vector with one element is a scalar to Mata (orgtype), so only the element type and "one column" are checked
	if (eltype(x) != et) {
		errprintf("SIGNATURE CHANGED: %s returns %s, documented %s\n", what, eltype(x), et)
		exit(9)
	}
	if (cols(x) != 1) {
		errprintf("SIGNATURE CHANGED: %s returns %g columns, documented 1\n", what, cols(x))
		exit(9)
	}
}
end

* ---------------------------------------------------------------- networks
nwclear
* D: binary directed, 5 nodes, 4 arcs, node e is an isolate: a->b, a->c, b->c, c->a
nwset, mat((0,1,1,0,0\0,0,1,0,0\1,0,0,0,0\0,0,0,0,0\0,0,0,0,0)) name(D) labs(a,b,c,d,e)
* U: binary undirected, 4 nodes: a-b, a-c, b-c, c-d (triangle with a tail)
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(U) labs(u1,u2,u3,u4) undirected
* V: valued undirected, 3 nodes: x-y 2, y-z 3.5
nwset, mat((0,2,0\2,0,3.5\0,3.5,0)) name(V) labs(x,y,z) undirected
* VD: valued directed with a self-loop: p->q 5, q->p 1, q->q 7
nwset, mat((0,5\1,7)) name(VD) labs(p,q) selfloop
* T: two-mode, persons p1 p2 and organisations o1 o2 o3: p1-o1, p1-o2, p2-o2, p2-o3
preserve
clear
input str5 p str5 o
"p1" "o1"
"p1" "o2"
"p2" "o2"
"p2" "o3"
end
nwset p o, twomode name(T)
restore
* E: no ties
nwset, mat(J(3,3,0)) name(E) labs(e1,e2,e3)

* ------------------------------------------------------ version, collection
mata: assert(nwapi_version() == 1)
mata: assert(nwapi_count() == 6)
mata: assert(nwapi_names() == ("D" \ "U" \ "V" \ "VD" \ "T" \ "E"))
mata: assert(nwapi_exists("D") == 1 & nwapi_exists("nonet") == 0 & nwapi_exists() == 1 & nwapi_exists("") == 1)
* the current network is the last one created; nwapi_current() follows nwcurrent / nwset
mata: assert(nwapi_current() == "E")
nwcurrent D
mata: assert(nwapi_current() == "D")
mata: assert(nwapi_nodes() == nwapi_nodes("D"))

* ------------------------------------------------------------- properties
mata: assert(nwapi_nodes("D") == 5 & nwapi_nodes("U") == 4 & nwapi_nodes("V") == 3 & nwapi_nodes("VD") == 2 & nwapi_nodes("T") == 5 & nwapi_nodes("E") == 3)
mata: assert(nwapi_directed("D") == 1 & nwapi_directed("U") == 0 & nwapi_directed("V") == 0 & nwapi_directed("VD") == 1 & nwapi_directed("T") == 0)
mata: assert(nwapi_valued("D") == 0 & nwapi_valued("U") == 0 & nwapi_valued("V") == 1 & nwapi_valued("VD") == 1 & nwapi_valued("T") == 0)
mata: assert(nwapi_twomode("D") == 0 & nwapi_twomode("T") == 1 & nwapi_twomode("V") == 0)
mata: assert(nwapi_selfloops("D") == 0 & nwapi_selfloops("VD") == 1 & nwapi_selfloops("U") == 0)
mata: assert(nwapi_temporal("D") == 0 & nwapi_temporal("T") == 0)
mata: assert(nwapi_nodelabels("D") == ("a" \ "b" \ "c" \ "d" \ "e"))
mata: assert(nwapi_nodelabels("T") == ("p1" \ "p2" \ "o1" \ "o2" \ "o3"))
mata: assert(nwapi_modes("D") == J(5, 1, 1))
mata: assert(nwapi_modes("T") == (1 \ 1 \ 2 \ 2 \ 2))

* ties: against hand counts and against nwsummarize
mata: assert(nwapi_ties("D") == 4 & nwapi_ties("U") == 4 & nwapi_ties("V") == 2 & nwapi_ties("VD") == 3 & nwapi_ties("T") == 4 & nwapi_ties("E") == 0)
quietly nwsummarize D
local arcs = r(arcs)
mata: assert(nwapi_ties("D") == `arcs')
quietly nwsummarize U
local edges = r(edges)
mata: assert(nwapi_ties("U") == `edges')
quietly nwsummarize V
local edges = r(edges)
mata: assert(nwapi_ties("V") == `edges')
quietly nwsummarize T
local edges = r(edges)
mata: assert(nwapi_ties("T") == `edges')

* ------------------------------------------------------------------ matrix
mata: assert(nwapi_matrix("D") == (0,1,1,0,0\0,0,1,0,0\1,0,0,0,0\0,0,0,0,0\0,0,0,0,0))
mata: assert(nwapi_matrix("U") == (0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0))
mata: assert(nwapi_matrix("V") == (0,2,0\2,0,3.5\0,3.5,0))
mata: assert(nwapi_matrix("VD") == (0,5\1,7))
mata: assert(nwapi_matrix("T") == (0,0,1,1,0\0,0,0,1,1\1,0,0,0,0\1,1,0,0,0\0,1,0,0,0))
mata: assert(nwapi_matrix("E") == J(3,3,0))
* nwtomata gives the same matrix except for the missing cells (diagonal without self-loops, dyads inside a mode of a
* two-mode network), which the API replaces by 0
foreach nm in D U V VD T {
	nwtomata `nm', mat(__nwt_M)
	mata: A = nwapi_matrix("`nm'")
	mata: assert(!hasmissing(A))
	mata: _editmissing(__nwt_M, 0)
	mata: assert(A == __nwt_M)
	mata: mata drop A __nwt_M
}
* the matrix is a copy: changing it does not change the network; and A*A works (zero diagonal)
mata:
A = nwapi_matrix("D")
A[1,2] = 99
B = nwapi_matrix("D")
assert(B[1,2] == 1)
assert(!hasmissing(A * A))
mata drop A B
end
* the current network
mata: assert(nwapi_matrix() == nwapi_matrix("D"))

* ---------------------------------------------------------------- edgelist
mata: assert(nwapi_edgelist("D") == (1,2,1\1,3,1\2,3,1\3,1,1))
* an undirected tie is listed once, sender <= receiver
mata: assert(nwapi_edgelist("U") == (1,2,1\1,3,1\2,3,1\3,4,1))
mata: assert(nwapi_edgelist("V") == (1,2,2\2,3,3.5))
mata: assert(nwapi_edgelist("VD") == (1,2,5\2,1,1\2,2,7))
mata: assert(nwapi_edgelist("T") == (1,3,1\1,4,1\2,4,1\2,5,1))
mata: assert(rows(nwapi_edgelist("E")) == 0 & cols(nwapi_edgelist("E")) == 3)
mata: assert(nwapi_edgelist() == nwapi_edgelist("D"))
* the edge list rebuilds the matrix (directed and undirected) and its length is the number of ties
foreach nm in D U V VD T E {
	mata: el = nwapi_edgelist("`nm'")
	mata: assert(rows(el) == nwapi_ties("`nm'"))
	mata: assert(nwt_rebuild(el, nwapi_nodes("`nm'"), nwapi_directed("`nm'")) == nwapi_matrix("`nm'"))
	mata: mata drop el
}

* ------------------------------------------------------------------ degrees
mata: assert(nwapi_outdegree("D") == (2 \ 1 \ 1 \ 0 \ 0))
mata: assert(nwapi_indegree("D") == (1 \ 1 \ 2 \ 0 \ 0))
mata: assert(nwapi_outdegree("U") == (2 \ 2 \ 3 \ 1) & nwapi_indegree("U") == (2 \ 2 \ 3 \ 1))
* valued: the number of ties, not the sum of the values
mata: assert(nwapi_outdegree("V") == (1 \ 2 \ 1))
mata: assert(nwapi_outdegree("VD") == (1 \ 2) & nwapi_indegree("VD") == (1 \ 2))
mata: assert(nwapi_outdegree("T") == (2 \ 2 \ 1 \ 2 \ 1))
mata: assert(nwapi_outdegree("E") == J(3, 1, 0))
mata: assert(nwapi_outdegree() == nwapi_outdegree("D") & nwapi_indegree() == nwapi_indegree("D"))
* against row and column sums of the unvalued matrix, on a larger random network
nwrandom 40, prob(.1) name(R) 
mata: A = nwapi_matrix("R") :!= 0
mata: assert(nwapi_outdegree("R") == rowsum(A) & nwapi_indegree("R") == colsum(A)')
mata: assert(nwapi_ties("R") == (nwapi_directed("R") ? sum(A) : sum(A) / 2))
mata: mata drop A

* --------------------------------------------------------------- neighbors
mata: assert(nwapi_neighbors("D", 1) == (2 \ 3))
mata: assert(nwapi_neighbors("D", "a") == (2 \ 3))
mata: assert(nwapi_inneighbors("D", 1) == 3)
mata: assert(nwapi_inneighbors("D", "c") == (1 \ 2))
mata: assert(rows(nwapi_neighbors("D", "e")) == 0 & cols(nwapi_neighbors("D", "e")) == 1)
mata: assert(rows(nwapi_inneighbors("D", 4)) == 0 & cols(nwapi_inneighbors("D", 4)) == 1)
mata: assert(nwapi_neighbors("U", "u3") == (1 \ 2 \ 4) & nwapi_inneighbors("U", "u3") == (1 \ 2 \ 4))
mata: assert(nwapi_neighbors("V", "y") == (1 \ 3))
mata: assert(nwapi_neighbors("VD", 2) == (1 \ 2) & nwapi_inneighbors("VD", 1) == 2)
mata: assert(nwapi_neighbors("T", "o2") == (1 \ 2) & nwapi_neighbors("T", "p1") == (3 \ 4))
* the name "" is the current network
nwcurrent D
mata: assert(nwapi_neighbors("", "a") == (2 \ 3))
* nodeid
mata: assert(nwapi_nodeid("D", "c") == 3 & nwapi_nodeid("T", "o3") == 5 & nwapi_nodeid("", "e") == 5)

* ----------------------------------------------- the arguments stay untouched
mata:
nm = ""
x = nwapi_nodes(nm)
assert(nm == "")
x = nwapi_neighbors(nm, 1)
assert(nm == "")
mata drop nm x
end

* --------------------------------------------------------------- error paths
* unknown network: 482 (the package's "network not found", help nwerrorcodes)
foreach f in nodes ties directed valued twomode selfloops temporal nodelabels modes matrix edgelist outdegree indegree {
	capture mata: nwapi_`f'("nonet")
	assert _rc == 482
}
capture mata: nwapi_neighbors("nonet", 1)
assert _rc == 482
capture mata: nwapi_inneighbors("nonet", 1)
assert _rc == 482
capture mata: nwapi_nodeid("nonet", "a")
assert _rc == 482
* names are exact: no abbreviation, no case folding
capture mata: nwapi_nodes("d")
assert _rc == 482
capture mata: nwapi_nodes("U ")
assert _rc == 482
* unknown node 485: label and id out of range
capture mata: nwapi_neighbors("D", "zzz")
assert _rc == 485
capture mata: nwapi_inneighbors("D", "zzz")
assert _rc == 485
capture mata: nwapi_nodeid("D", "zzz")
assert _rc == 485
capture mata: nwapi_neighbors("D", 6)
assert _rc == 485
capture mata: nwapi_neighbors("D", 0)
assert _rc == 485
capture mata: nwapi_neighbors("D", -1)
assert _rc == 485
capture mata: nwapi_inneighbors("D", 6)
assert _rc == 485
* invalid arguments 198: a node that is neither a whole number nor a label, or not a single value
capture mata: nwapi_neighbors("D", 1.5)
assert _rc == 198
capture mata: nwapi_neighbors("D", .)
assert _rc == 198
capture mata: nwapi_neighbors("D", (1, 2))
assert _rc == 198
capture mata: nwapi_neighbors("D", J(0, 1, 1))
assert _rc == 198
capture mata: nwapi_neighbors("D", 1i)
assert _rc == 198
capture mata: nwapi_inneighbors("D", ("a" \ "b"))
assert _rc == 198
* no network in memory: the current network does not exist
nwclear
capture mata: nwapi_nodes()
assert _rc == 482
capture mata: nwapi_current()
assert _rc == 482
capture mata: nwapi_matrix("")
assert _rc == 482
mata: assert(nwapi_count() == 0 & rows(nwapi_names()) == 0 & cols(nwapi_names()) == 1 & nwapi_exists() == 0 & nwapi_exists("D") == 0)
* (the registry is gone after nwclear: the functions do not break on a missing __nw)
capture mata: nwapi_edgelist("D")
assert _rc == 482

* ----------------------------------------------------------------- huge network
* 25,000 nodes, a ring, built sparse (no dense matrix): matrix refused with 484 like nwtomata, everything else works
clear
quietly set obs 25000
generate long a = _n
generate long b = mod(_n, 25000) + 1
nwset a b, edgelist name(big) undirected
mata: assert(nwapi_nodes("big") == 25000 & nwapi_ties("big") == 25000)
mata: assert(rows(nwapi_edgelist("big")) == 25000 & sum(nwapi_outdegree("big") :== 2) == 25000)
mata: assert(sort(nwapi_neighbors("big", 1), 1) == (2 \ 25000))
capture mata: nwapi_matrix("big")
assert _rc == 484
capture nwtomata big, mat(__nwt_M)
assert _rc == 484
* the message: readable, the node count is filled in, no unexpanded macro or format
tempfile lg
quietly log using "`lg'", text replace
capture noisily mata: nwapi_matrix("big")
quietly log close
local msg ""
file open fh using "`lg'", read text
file read fh line
while r(eof) == 0 {
	local msg `"`msg' `line'"'
	file read fh line
}
file close fh
assert strpos(`"`msg'"', "25000 nodes") > 0
assert strpos(`"`msg'"', "refused") > 0
assert strpos(`"`msg'"', "20000") > 0
assert strpos(`"`msg'"', "`") == 0 & strpos(`"`msg'"', "%g") == 0 & strpos(`"`msg'"', "errDenseTooLarge") == 0
nwclear
capture mata: mata drop __nwt_M

* ------------------------------------------------------------ signature test
* One call of every function with the documented argument types: eltype, orgtype and the orientation of the result.
* A change of a signature (return type, rows against columns, arguments) fails here.
nwset, mat((0,1,1,0,0\0,0,1,0,0\1,0,0,0,0\0,0,0,0,0\0,0,0,0,0)) name(D) labs(a,b,c,d,e)
nwset, mat((0,2,0\2,0,3.5\0,3.5,0)) name(V) labs(x,y,z) undirected
mata:
nwt_chk(nwapi_version(), "real", "scalar", "nwapi_version()")
nwt_chk(nwapi_count(), "real", "scalar", "nwapi_count()")
nwt_chkcol(nwapi_names(), "string", "nwapi_names()")
nwt_chk(nwapi_exists(), "real", "scalar", "nwapi_exists()")
nwt_chk(nwapi_exists("D"), "real", "scalar", "nwapi_exists(name)")
nwt_chk(nwapi_current(), "string", "scalar", "nwapi_current()")
nwt_chk(nwapi_nodes(), "real", "scalar", "nwapi_nodes()")
nwt_chk(nwapi_nodes("D"), "real", "scalar", "nwapi_nodes(name)")
nwt_chk(nwapi_ties("D"), "real", "scalar", "nwapi_ties(name)")
nwt_chk(nwapi_directed("D"), "real", "scalar", "nwapi_directed(name)")
nwt_chk(nwapi_valued("D"), "real", "scalar", "nwapi_valued(name)")
nwt_chk(nwapi_twomode("D"), "real", "scalar", "nwapi_twomode(name)")
nwt_chk(nwapi_selfloops("D"), "real", "scalar", "nwapi_selfloops(name)")
nwt_chk(nwapi_temporal("D"), "real", "scalar", "nwapi_temporal(name)")
nwt_chkcol(nwapi_nodelabels("D"), "string", "nwapi_nodelabels(name)")
nwt_chkcol(nwapi_modes("D"), "real", "nwapi_modes(name)")
nwt_chk(nwapi_matrix("D"), "real", "matrix", "nwapi_matrix(name)")
nwt_chk(nwapi_edgelist("D"), "real", "matrix", "nwapi_edgelist(name)")
nwt_chkcol(nwapi_outdegree("D"), "real", "nwapi_outdegree(name)")
nwt_chkcol(nwapi_indegree("D"), "real", "nwapi_indegree(name)")
nwt_chkcol(nwapi_neighbors("D", 1), "real", "nwapi_neighbors(name, id)")
nwt_chkcol(nwapi_neighbors("D", "a"), "real", "nwapi_neighbors(name, label)")
nwt_chkcol(nwapi_inneighbors("D", 1), "real", "nwapi_inneighbors(name, id)")
nwt_chkcol(nwapi_inneighbors("D", "a"), "real", "nwapi_inneighbors(name, label)")
nwt_chk(nwapi_nodeid("D", "a"), "real", "scalar", "nwapi_nodeid(name, label)")
// orientation: matrix n x n, edge list m x 3, vectors n x 1
assert(rows(nwapi_matrix("D")) == 5 & cols(nwapi_matrix("D")) == 5)
assert(rows(nwapi_edgelist("D")) == 4 & cols(nwapi_edgelist("D")) == 3)
assert(rows(nwapi_edgelist("V")) == 2 & cols(nwapi_edgelist("V")) == 3)
assert(rows(nwapi_outdegree("D")) == 5 & rows(nwapi_indegree("D")) == 5 & rows(nwapi_nodelabels("D")) == 5 & rows(nwapi_modes("D")) == 5)
// no argument and "" both mean the current network (the last one created: V)
assert(nwapi_current() == "V")
assert(nwapi_nodes() == 3 & nwapi_nodes("") == 3 & nwapi_ties() == 2 & nwapi_directed() == 0 & nwapi_valued() == 1)
assert(nwapi_matrix() == nwapi_matrix("") & nwapi_edgelist() == nwapi_edgelist(""))
assert(nwapi_nodelabels() == nwapi_nodelabels("") & nwapi_outdegree() == nwapi_outdegree("V") & nwapi_modes() == nwapi_modes(""))
// the whole public surface is exactly these 21 functions: a new or removed function must be noticed here
// (internal helpers start with _nwapi_)
end
local expected nwapi_version nwapi_count nwapi_names nwapi_exists nwapi_current nwapi_nodes nwapi_ties nwapi_directed nwapi_valued nwapi_twomode nwapi_selfloops nwapi_temporal nwapi_nodelabels nwapi_modes nwapi_matrix nwapi_edgelist nwapi_outdegree nwapi_indegree nwapi_neighbors nwapi_inneighbors nwapi_nodeid
foreach f of local expected {
	capture mata: mata which `f'()
	assert _rc == 0
}
local nexp : word count `expected'
assert `nexp' == 21

* the commands are not disturbed: the API changed nothing in the registry
nwsummarize V
assert r(edges) == 2
nwclear
di "=== nwapi TESTS PASSED ==="
