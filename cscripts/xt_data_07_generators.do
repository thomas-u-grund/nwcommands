* xt_data_07_generators.do
* Generators nwrandom, nwring, nwlattice, nwsmall: invariants that hold for every draw (node and tie counts,
* symmetry of undirected draws, no self-ties, exact counts of density() and census(), degrees of degree()/
* outdegree()/indegree(), degree 2k of a ring, tie count of a lattice and a torus), the sizes 0/1/2, the
* sparse paths above 2,000 nodes, ntimes() with labs() and nodenamesmata(), names in use, invalid options with
* data and networks unchanged, no leftover Mata globals.
* Counts are derived by hand from the definitions (and, for density(), from get_random_density in nwrandom.ado).
clear all
set more off
run cscripts/xt_data_00_helpers.do
xt_init xt_data_07_generators
set seed 20261112

* xt_props net : c_local n (nodes), s (sum of off-diagonal cells), sym (1 if symmetric), diag (non-zero diagonal cells)
capture program drop xt_props
program xt_props
	args net
	quietly nwname `net'
	c_local n = r(nodes)
	quietly nwtomata `net', mat(__xt_P)
	mata: __xt_P = editmissing(__xt_P, 0)
	mata: st_local("dg", strofreal(sum(diagonal(__xt_P) :!= 0)))
	mata: _diag(__xt_P, 0)
	mata: st_local("s", strofreal(sum(__xt_P :!= 0)))
	mata: st_local("sy", strofreal(__xt_P == __xt_P'))
	c_local s `s'
	c_local sym `sy'
	c_local diag `dg'
	mata: mata drop __xt_P
end

* --- A. nwrandom: prob(0), prob(1), density(), census()
nwclear
nwrandom 7, prob(1) name(c7)
xt_props c7
xt_chk `=(`n' == 7 & `s' == 42 & `diag' == 0)' "prob(1), 7 nodes: complete, 42 arcs, no self-ties (got `s', `diag')"
nwrandom 7, prob(1) undirected name(c7u)
xt_props c7u
xt_chk `=(`s' == 42 & `sym' == 1)' "prob(1) undirected: 42 cells, symmetric"
nwrandom 7, prob(0) name(e7)
xt_props e7
xt_chk `=(`s' == 0)' "prob(0): no ties"
nwrandom 10, density(.5) name(d10)
xt_props d10
xt_chk `=(`s' == 45 & `diag' == 0)' "density(.5), 10 nodes directed: floor(90 * .5) = 45 arcs (got `s')"
nwrandom 10, density(.5) undirected name(d10u)
xt_props d10u
xt_chk `=(`sym' == 1 & mod(`s', 2) == 0 & abs(`s' - 45) <= 1)' "density(.5) undirected: symmetric, 2 x floor(45/2) = 44 cells (got `s')"
nwrandom 10, census(5 7) name(cen)
xt_props cen
xt_chk `=(`s' == 17)' "census(5 7): 2 x 5 mutual + 7 asymmetric = 17 arcs (got `s')"
xt_mat cen __xt_M
mata: st_local("mut", strofreal(sum(__xt_M :* __xt_M') / 2))
xt_chk `=("`mut'" == "5")' "census(5 7): 5 mutual dyads (got `mut')"
nwrandom 10, prob(.4) selfloop name(sl)
quietly nwname sl
xt_chk `=("`r(selfloop)'" == "true")' "selfloop: flag set"
di "PASS A nwrandom counts"

* --- B. sizes 0, 1, 2
nwclear
nwrandom 1, prob(.5) name(r1)
xt_props r1
xt_chk `=(`n' == 1 & `s' == 0)' "nwrandom 1: one node, no tie"
nwrandom 2, prob(1) name(r2)
xt_props r2
xt_chk `=(`n' == 2 & `s' == 2)' "nwrandom 2, prob(1): 2 arcs"
xt_snap b1
capture noisily nwrandom 0, prob(.5) name(r0)
xt_chk `=(_rc != 0)' "nwrandom 0 is refused (got `=_rc')"
xt_same b1 "nwrandom 0"
di "PASS B sizes"

* --- C. invalid options: error code, nothing changed
nwclear
nwrandom 5, prob(.5) name(keep)
gen keepme = _n
xt_snap c1
capture noisily nwrandom 5, prob(.5) directed undirected name(x)
xt_chk `=(_rc == 198)' "directed with undirected: r(198) (got `=_rc')"
xt_same c1 "directed with undirected"
capture noisily nwrandom 5, name(x)
xt_chk `=(_rc == 198)' "no prob/density/census: r(198) (got `=_rc')"
xt_same c1 "no prob/density/census"
capture noisily nwrandom 5, census(8 3) name(x)
xt_chk `=(_rc == 198)' "census() with more dyads than 10: r(198) (got `=_rc')"
xt_same c1 "census() too many dyads"
capture noisily nwrandom 5, prob(.5) name(keep)
xt_chk `=(_rc == 483)' "name() in use: r(483) (got `=_rc')"
xt_same c1 "nwrandom name() in use"
* weights(1,2) is valid (a Mata row vector, help: weights(p1, p2,...)); a weight that is no number is not
capture noisily nwrandom 5, prob(.5) weights(abc,def) name(x)
xt_chk `=(_rc == 198)' "weights() that is no Mata vector: r(198) (got `=_rc')"
xt_same c1 "invalid weights()"
capture noisily nwring 5, k(1) name(keep)
xt_chk `=(_rc == 483)' "nwring name() in use: r(483) (got `=_rc')"
xt_same c1 "nwring name() in use"
capture noisily nwlattice 2 2, name(keep)
xt_chk `=(_rc == 483)' "nwlattice name() in use: r(483) (got `=_rc')"
xt_same c1 "nwlattice name() in use"
capture noisily nwsmall 6, k(1) prob(.1) name(keep)
xt_chk `=(_rc == 483)' "nwsmall name() in use: r(483) (got `=_rc')"
xt_same c1 "nwsmall name() in use"
nwrandom 5, prob(.5)
nwrandom 5, prob(.5)
xt_hasnet random_1
xt_chk `has' "no name(): random, then random_1"
di "PASS C errors"

* --- D. degree(), outdegree()/indegree() (native plugin 3.17.0 or later)
nwclear
capture noisily nwrandom 6, degree(2 2 2 2 2 2) name(deg)
if _rc == 198 {
	di as txt "  (degree(): native plugin missing or too old, block skipped)"
}
else {
	xt_chk `=(_rc == 0)' "degree(2 2 2 2 2 2) drawn (got `=_rc')"
	xt_mat deg __xt_M
	mata: st_local("ok", strofreal(all(rowsum(__xt_M) :== 2) & __xt_M == __xt_M'))
	xt_chk `ok' "degree(): every node has degree 2, undirected"
	xt_snap d1
	capture noisily nwrandom 4, degree(3 3 1 1) name(x)
	xt_chk `=(_rc == 198)' "degree(3 3 1 1) is not graphical (Erdos-Gallai at k = 2): r(198) (got `=_rc')"
	xt_same d1 "degree() not graphical"
	capture noisily nwrandom 3, degree(1 1 1) name(x)
	xt_chk `=(_rc == 198)' "degree(1 1 1): odd sum, r(198) (got `=_rc')"
	xt_same d1 "degree() odd sum"
	capture noisily nwrandom 3, degree(1 1) name(x)
	xt_chk `=(_rc == 198)' "degree() with 2 values for 3 nodes: r(198) (got `=_rc')"
	xt_same d1 "degree() wrong length"
	capture noisily nwrandom 3, outdegree(1 1 1) indegree(1 1 0) name(x)
	xt_chk `=(_rc == 198)' "outdegree and indegree sums differ: r(198) (got `=_rc')"
	xt_same d1 "outdegree/indegree sums differ"
	capture noisily nwrandom 3, degree(1 1 0) prob(.5) name(x)
	xt_chk `=(_rc == 198)' "degree() with prob(): r(198) (got `=_rc')"
	xt_same d1 "degree() with prob()"
	nwrandom 5, outdegree(1 2 0 1 1) indegree(2 0 1 1 1) name(dd)
	xt_mat dd __xt_M
	mata: st_local("ok", strofreal(rowsum(__xt_M)' == (1,2,0,1,1) & colsum(__xt_M) == (2,0,1,1,1)))
	xt_chk `ok' "outdegree()/indegree(): exact degrees per node"
}
di "PASS D degrees"

* --- E. ntimes() with labs() and nodenamesmata(); r(netlist)
nwclear
nwrandom 3, prob(.5) ntimes(3) labs(a,b,c) name(t)
xt_chk `=("`r(netlist)'" == "t_1 t_2 t_3")' "ntimes(3): r(netlist) (got `r(netlist)')"
quietly nwname t_3
xt_chk `=("`r(labs)'" == "a,b,c")' "ntimes(3): labs() used by every network"
mata: __xt_nm = ("p", "q", "r")
nwrandom 3, prob(.5) ntimes(2) nodenamesmata(__xt_nm) name(u)
quietly nwname u_2
xt_chk `=("`r(labs)'" == "p,q,r")' "ntimes(2) with nodenamesmata(): names used by every network (got `r(labs)')" // was bug S24 (fixed)
nwring 4, k(1) ntimes(2) name(rg)
xt_chk `=("`r(netlist)'" == "rg_1 rg_2")' "nwring ntimes(2): r(netlist)"
nwlattice 2 2, ntimes(2) name(lt)
xt_chk `=("`r(netlist)'" == "lt_1 lt_2")' "nwlattice ntimes(2): r(netlist)"
di "PASS E ntimes"

* --- F. nwring, nwlattice, nwsmall structure
nwclear
nwring 9, k(2) name(ring)
xt_props ring
xt_mat ring __xt_M
mata: st_local("ok", strofreal(all(rowsum(__xt_M) :== 4)))
xt_chk `=(`n' == 9 & `s' == 36 & `sym' == 1 & "`ok'" == "1")' "nwring 9, k(2): every node degree 4, 36 cells, symmetric (got `s')"
nwring 4, k(3) name(ringfull)
xt_props ringfull
xt_chk `=(`s' == 12)' "nwring 4, k(3): complete, 12 cells (got `s')"
nwring 2001, k(2) undirected name(bigring)
xt_props bigring
xt_mat bigring __xt_M
mata: st_local("ok", strofreal(all(rowsum(__xt_M) :== 4)))
xt_chk `=(`n' == 2001 & `s' == 8004 & `sym' == 1 & `diag' == 0 & "`ok'" == "1")' "nwring 2001 (sparse path), k(2): degree 4 everywhere (got `s')"
nwlattice 4 3, name(lat)
xt_props lat
xt_chk `=(`n' == 12 & `s' == 34 & `sym' == 1)' "nwlattice 4 3: 3 x 3 + 4 x 2 = 17 edges, 34 cells (got `s')"
xt_mat lat __xt_M
mata: st_local("c", strofreal(rowsum(__xt_M)[1]) + "," + strofreal(rowsum(__xt_M)[6]))
xt_chk `=("`c'" == "2,4")' "nwlattice 4 3: corner degree 2, inner node 6 degree 4 (got `c')"
nwlattice 4 3, xwrap ywrap name(torus)
xt_props torus
xt_chk `=(`s' == 48)' "nwlattice 4 3 xwrap ywrap: degree 4 everywhere, 48 cells (got `s')"
nwlattice 3, name(lat1)
xt_props lat1
xt_chk `=(`n' == 3 & `s' == 4)' "nwlattice 3: a path of 3 nodes, 4 cells (got `s')"
nwlattice 1 1, name(lat11)
xt_props lat11
xt_chk `=(`n' == 1 & `s' == 0)' "nwlattice 1 1: one node, no tie"
nwsmall 9, k(2) prob(0) name(sm0)
xt_mat sm0 __xt_A
xt_mat ring __xt_B
mata: st_local("ok", strofreal(__xt_A == __xt_B))
xt_chk `ok' "nwsmall prob(0) is the ring of nwring with the same k"
nwsmall 30, k(2) prob(.3) name(sm)
xt_props sm
xt_chk `=(`n' == 30 & `diag' == 0)' "nwsmall 30: 30 nodes, no self-ties"
capture mata: mata describe __nwlattice_newmat
xt_chk `=(_rc != 0)' "[policy] nwlattice leaves no Mata global __nwlattice_newmat"
xt_chk `=("$nwtotal" == "")' "[policy] nwlattice leaves no global macro nwtotal"
di "PASS F structure"

* --- G. nwrandom above 2,000 nodes (sparse path)
nwclear
nwrandom 2001, prob(.002) undirected name(bigr)
xt_props bigr
xt_chk `=(`n' == 2001 & `sym' == 1 & `diag' == 0)' "nwrandom 2001 prob(.002) undirected: 2,001 nodes, symmetric, no self-ties"
quietly nwname bigr
xt_chk `=("`r(directed)'" == "false")' "sparse path: undirected flag"
xt_chk `=(_N == 2001)' "sparse path: 2,001 rows (got `=_N')"
di "PASS G big"

capture mata: mata drop __xt_M __xt_A __xt_B __xt_nm
xt_end
di "ALL PASS"
