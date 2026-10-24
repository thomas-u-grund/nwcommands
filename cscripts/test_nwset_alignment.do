cscript

do unw_core.do

* Regression test: declaring a network must not re-sort the data under the
* networks already in memory.
*
* Node attributes are read by row position, so rows 1..n of the data must
* stay in the node order of the networks they belong to. Before
* 2026-10-01 an unlabelled `nwset, mat()' gave the new network the
* default labels n1, n2, ..., and _nwdatasync then sorted the rows into
* that order; after `nwwebuse glasgow' (rows n1, n10, n11, ...) this moved
* the row of n10 to row 10 etc. under glasgow1/glasgow2, which silently
* changed every estimate that reads node attributes by row. Datasets whose
* labels are not n1..nN (gang: g1, g10, ...; s50: v1, v10, ...) got 2N
* rows instead.
*
* Checked here, on four datasets and for each network-creating command:
* the rows keep their order and count, every node keeps its attribute
* value, and the new network lists its nodes in the order of the rows.

capture program drop _al_snap
program define _al_snap
	args attr
	mata: __al_lab = st_sdata(., "_nwnode")
	mata: __al_x = st_data(., "`attr'")
	mata: __al_n = st_nobs()
end

capture program drop _al_check
program define _al_check
	args attr net what
	unw_defs
	mata: st_local("ok1", strofreal(st_nobs() == __al_n))
	assert `ok1' == 1
	mata: st_local("ok2", strofreal(st_sdata(., "_nwnode") == __al_lab))
	mata: st_local("ok3", strofreal(all((st_data(., "`attr'") :== __al_x))))
	_nwsyntax `net', max(1) other(chk)
	mata: st_local("ok4", strofreal(nw_rows_aligned(`chknetobj', "_nwnode")))
	di as txt "  `what' (`net'): rows kept " `ok2' ", attribute kept " `ok3' ", new network in row order " `ok4'
	assert `ok2' == 1
	assert `ok3' == 1
	assert `ok4' == 1
end

* --------------------------------------------------------------------------
* Every network-creating command, on datasets with non-alphabetical labels
* --------------------------------------------------------------------------

foreach spec in "glasgow glasgow1 smoke1" "gang gang Age" "s50 s50_w1 smoke1" "lazega lazega_adv age" {
	tokenize `spec'
	local ds `1'
	local net `2'
	local attr `3'
	di as res _n "=== `ds'"
	nwwebuse `ds', nwclear
	_nwsyntax `net', max(1)
	local N = `nodes'
	local first3 = _nwnode[1] + " " + _nwnode[2] + " " + _nwnode[3]
	di as txt "  rows start: `first3'"
	_al_snap `attr'

	* unlabelled mat(): node i is observation i
	nwtomata `net', mat(__al_M)
	nwset, mat(__al_M) name(c_mat)
	_al_check `attr' c_mat "nwset, mat()"
	nwtomata c_mat, mat(__al_M2)
	mata: assert(__al_M2 == __al_M)
	mata: st_local("l1", invtokens(`netobj'->get_nodenames()))
	_nwsyntax c_mat, max(1) other(cm)
	mata: st_local("l2", invtokens(`cmnetobj'->get_nodenames()))
	assert "`l1'" == "`l2'"

	* labs() listing the same nodes in reverse order: the network is
	* reordered into row order, ties unchanged
	mata: st_local("revlabs", invtokens(`netobj'->get_nodenames()[`N'..1], ","))
	mata: __al_R = __al_M[(`N'::1), (`N'::1)]
	nwset, mat(__al_R) labs(`revlabs') name(c_labs)
	_al_check `attr' c_labs "nwset, mat() labs()"
	nwtomata c_labs, mat(__al_M3)
	mata: assert(__al_M3 == __al_M)

	nwgen c_gen = `net'
	_al_check `attr' c_gen "nwgenerate"
	nwtranspose `net', name(c_tr)
	_al_check `attr' c_tr "nwtranspose"
	nwduplicate `net', name(c_dup)
	_al_check `attr' c_dup "nwduplicate"
	nwreplace c_dup = 0
	_al_check `attr' c_dup "nwreplace"
	nwsym `net', generate(c_sym)
	_al_check `attr' c_sym "nwsym, generate()"
	nwpermute `net', generate(c_perm)
	_al_check `attr' c_perm "nwpermute"
	nwgeodesic `net', name(c_geo)
	_al_check `attr' c_geo "nwgeodesic"
	nwrandom `N', prob(.1) name(c_rand)
	_al_check `attr' c_rand "nwrandom"
	nwring `N', k(2) name(c_ring)
	_al_check `attr' c_ring "nwring"
	nwdyadprob c_rand, density(.02) name(c_dp)
	_al_check `attr' c_dp "nwdyadprob"
	capture drop __al_cat
	gen __al_cat = mod(_n, 3)
	_al_snap `attr'
	nwexpand __al_cat, name(c_exp)
	_al_check `attr' c_exp "nwexpand"
	nwhomophily __al_cat, homophily(2) density(.1) name(c_hom)
	_al_check `attr' c_hom "nwhomophily"
	* the original network is still aligned with the rows
	_al_check `attr' `net' "original network"
	capture mata: mata drop __al_M __al_M2 __al_M3 __al_R
}

di as res "test_nwset_alignment: all checks passed"
