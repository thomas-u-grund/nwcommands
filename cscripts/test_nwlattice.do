cscript

do unw_core.do

/*
	nwlattice.ado had zero test coverage and could never actually
	complete a single call: it depends on nwvalidvars.ado (a genuinely
	working, self-contained variable-naming utility that had been
	archived to deprecated/ during an earlier harmonisation pass without
	checking whether anything still depended on it) and on nwset.ado's
	own vars() option (documented in nwset's own doc header - "can be
	set wit option vars()" - but silently missing from its actual
	syntax line, an independent, previously-undiscovered bug). Both
	fixed together: nwvalidvars.ado/.sthlp restored from deprecated/
	(confirmed genuinely self-contained, no legacy-architecture
	dependency at all - unlike _nwsyntax_other, which really was
	broken), and nwset.ado's syntax line + construction path given back
	a working vars() option (see cscripts/test_nwset.do's own new
	coverage for that half).
*/

nwclear
nwlattice 3 3, undirected
assert _rc == 0
nwsummarize
assert `"`r(directed)'"' == `"false"'
assert         r(nodes)   == 9
assert         r(edges)   == 12
assert reldif( r(density), .3333333333333333 ) < 1E-8

* toroidal (wrapped) lattice - every node gets exactly degree 4
nwclear
nwlattice 4 4, undirected xwrap ywrap
assert _rc == 0
nwsummarize
assert         r(nodes)   == 16
assert         r(edges)   == 32

* default is directed
nwclear
nwlattice 3
assert _rc == 0
nwsummarize
assert `"`r(directed)'"' == `"true"'
assert         r(nodes)   == 3

* vars() - explicit Stata variable names, routed through nwset's own
* vars() option (see its own dedicated test for the underlying
* mechanism) - nwlattice defaults the stub to its own name() default
* ("lattice") when vars() is not given, generating lattice1..latticeN
nwclear
nwlattice 3 3, undirected
nwload
foreach v in lattice1 lattice2 lattice3 lattice4 lattice5 lattice6 lattice7 lattice8 lattice9 {
	capture confirm variable `v'
	assert _rc == 0
}

* default (no xvars) does NOT generate Stata variables
nwclear
nwlattice 3 3, undirected
capture confirm variable lattice1
assert _rc != 0

* xvars generates Stata variables
nwclear
nwlattice 3 3, undirected xvars
foreach v in lattice1 lattice2 lattice3 lattice4 lattice5 lattice6 lattice7 lattice8 lattice9 {
	capture confirm variable `v'
	assert _rc == 0
}

* ntimes() generates multiple independent copies under name_1, name_2, ...
nwclear
nwlattice 3 3, undirected ntimes(2)
nwset
assert `"`r(nets)'"' == `" lattice_1 lattice_2"'
assert         r(networks) == 2

* --- alpha-audit regression: a single-node lattice used to crash
* (r3301, subscript invalid) - an unconditional hardcoded patch line
* (newmat[2,1]=1, fixing a boundary case in the left-neighbor formula
* for i>=2) indexed past a 1x1 matrix's own bounds when nodes==1.
nwclear
capture noisily nwlattice 1
assert _rc == 0
capture noisily nwlattice 1 1
assert _rc == 0
di "=== SINGLE-NODE LATTICE REGRESSION VERIFIED ==="

* moderate-severity pass, generators_structural group: xwrap/ywrap used
* to produce structurally wrong (uneven-degree) topology whenever
* cols != rows - the pre-existing tests here only ever used a square 3x3
* lattice, where a rows/cols mixup inside both wrap blocks cannot show
* up. "3 5" means cols=3, rows=5 (nwlattice's own first-arg=cols,
* second-arg=rows convention - see nwlattice.sthlp). Expected degree
* sums hand-derived from the lattice geometry directly (not copied from
* the buggy implementation): xwrap only wraps the column dimension, so
* only the 2 boundary rows (of 5) lose a vertical neighbor - 2*3 nodes
* at degree 3, 3*3 nodes at degree 4, sum = 6*3+9*4 = 54. ywrap only
* wraps the row dimension, so only the 2 boundary columns (of 3) lose a
* horizontal neighbor - 2*5 nodes at degree 3, 1*5 nodes at degree 4,
* sum = 10*3+5*4 = 50. Both together (a full torus) makes every node's
* degree exactly 4 with no boundary at all.
nwclear
nwlattice 3 5, undirected xwrap
nwdegree
qui sum _degree
assert r(min) == 3
assert r(max) == 4
assert r(sum) == 54

nwclear
nwlattice 3 5, undirected ywrap
nwdegree
qui sum _degree
assert r(min) == 3
assert r(max) == 4
assert r(sum) == 50

nwclear
nwlattice 3 5, undirected xwrap ywrap
nwdegree
qui sum _degree
assert r(min) == 4
assert r(max) == 4
di "=== NON-SQUARE xwrap/ywrap REGRESSION VERIFIED ==="

* moderate-severity pass, generators_structural group: r(netlist) parity
* with nwrandom (the only sibling generator that already exposed it).
nwclear
nwlattice 3 3
assert `"`r(netlist)'"' == `"lattice"'
nwclear
nwlattice 3 3, ntimes(3)
assert `"`r(netlist)'"' == `"lattice_1 lattice_2 lattice_3"'
di "=== r(netlist) REGRESSION VERIFIED ==="
