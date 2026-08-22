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

* xvars suppresses variable generation
nwclear
nwlattice 3 3, undirected xvars
capture confirm variable lattice1
assert _rc != 0

* ntimes() generates multiple independent copies under name_1, name_2, ...
nwclear
nwlattice 3 3, undirected ntimes(2)
nwset
assert `"`r(nets)'"' == `" lattice_1 lattice_2"'
assert         r(networks) == 2
