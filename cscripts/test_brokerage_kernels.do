cscript

do unw_core.do

* Native kernels 29 (nwburt), 30 (nwconstraint) and 31 (nwsimmelian) against the Mata code they replace.
* The Mata path is forced with the global NW_NOFASTKERNELS. Floats to 1e-10 (in practice 1e-15), the Simmelian
* network exactly. Without a plugin of generation 7 (Linux/Windows binaries before the CI build) it is skipped.
* Prints "brokerage kernels: n random networks, all equal" on success.

mata: st_local("gen", strofreal(nwg_comb_version()))
if `gen' < 7 {
	di as txt "brokerage kernels: plugin generation `gen' < 7, native kernels not available: SKIPPED"
	exit
}

capture program drop _bk_cmp
program define _bk_cmp
	args net kind sparse
	* Burt: the kernel against calculate_burt() at double precision, then the command with and without the kernel
	_nwsyntax `net'
	qui if _N < `nodes' set obs `nodes'
	mata: bk_b = `netobj'->calculate_burt()
	mata: bk_r = nwg_comb(29, `nodes', `netobj'->edgelist(), J(0, 1, .), J(1, 0, .), bk_aux = J(1, 4, .), bk_st = .)
	mata: bk_r = (bk_r[., 1..3], bk_r[., 4] :+ editvalue(bk_r[., 5], 1, .))
	mata: st_local("miss", strofreal(rows(bk_r) == rows(bk_b) ? sum((bk_r :== .) :!= (bk_b :== .)) : 99))
	mata: st_local("md", strofreal(rows(bk_r) == rows(bk_b) ? mreldif(editvalue(bk_r, ., -99), editvalue(bk_b, ., -99)) : 99))
	if `miss' | `md' > 1e-10 {
		di as err "burt kernel differs (`md', `miss' missing mismatches): `net' (`kind')"
		exit 9
	}
	if `md' > $bk_maxdiff {
		global bk_maxdiff = `md'
	}
	* the command nwburt weights a valued network (kernel 40, cscripts/test_burt_valued.do): compare its two routes on unvalued networks
	if !strpos(`"`kind'"', "val=1") {
		global NW_NOFASTKERNELS
		qui nwburt `net', replace silent
		foreach v in _effsize _efficiency _constraint _hierarchy {
			qui gen double `v'_f = `v'
		}
		global NW_NOFASTKERNELS 1
		qui nwburt `net', replace silent
		global NW_NOFASTKERNELS
		foreach v in _effsize _efficiency _constraint _hierarchy {
			capture assert (`v' == `v'_f) | reldif(`v', `v'_f) < 1e-10
			if _rc {
				di as err "nwburt `v' differs: `net' (`kind')"
				exit 9
			}
			drop `v'_f
		}
	}
	* constraint: the cells of the kernel against calculate_constraint_triplets(), then the command's network
	mata: bk_t = `netobj'->calculate_constraint_triplets()
	mata: bk_k = nwg_comb(30, `nodes', `netobj'->edgelist(), J(0, 1, .), J(1, 0, .), bk_aux, bk_st = .)
	mata: st_local("md", strofreal(cols(bk_k) == 3 & rows(bk_k) == rows(bk_t) ? (rows(bk_t) ? max((mreldif(bk_k[., 1..2], bk_t[., 1..2]), mreldif(bk_k[., 3], bk_t[., 3]))) : 0) : 99))
	if `md' > 1e-10 {
		di as err "constraint kernel differs (`md'): `net' (`kind')"
		exit 9
	}
	foreach s in cf co {
		capture nwdrop `s'
	}
	global NW_NOFASTKERNELS
	qui nwconstraint `net', name(cf)
	global NW_NOFASTKERNELS 1
	qui nwconstraint `net', name(co)
	global NW_NOFASTKERNELS
	nwtomata cf, mat(bk_mf)
	nwtomata co, mat(bk_mo)
	mata: st_local("md", strofreal(mreldif(editvalue(bk_mf, ., 0), editvalue(bk_mo, ., 0))))
	if `md' > 1e-10 {
		di as err "nwconstraint differs (`md'): `net' (`kind')"
		exit 9
	}
	capture nwdrop cf
	capture nwdrop co
	* Simmelian ties: exactly equal
	global NW_NOFASTKERNELS
	qui nwsimmelian `net', name(sf) nwreplace
	global NW_NOFASTKERNELS 1
	qui nwsimmelian `net', name(so) nwreplace
	global NW_NOFASTKERNELS
	nwtomata sf, mat(bk_sf)
	nwtomata so, mat(bk_so)
	mata: st_local("md", strofreal(bk_sf == bk_so))
	if `md' != 1 {
		di as err "nwsimmelian differs: `net' (`kind')"
		exit 9
	}
	capture nwdrop sf
	capture nwdrop so
end

set seed 20261026
global bk_maxdiff 0
local nnet 0
forvalues r = 1/90 {
	local n = 5 + floor(runiform()^2 * 295)
	local dir = mod(`r', 2)
	local val = (mod(`r', 3) == 0)
	local iso = (mod(`r', 4) < 2)
	* some denser graphs so that mutual ties with common neighbours exist
	local m = ceil(`n' * (0.4 + 3 * runiform() + 4 * (mod(`r', 5) == 0)))
	clear
	qui set obs `m'
	qui gen long a = ceil(runiform() * `n')
	qui gen long b = ceil(runiform() * `n')
	* directed graphs: add reverse ties for half of them so that there are mutual ties
	if `dir' & mod(`r', 4) < 2 {
		qui expand 2
		qui gen long t = a
		qui replace a = b if _n > _N / 2
		qui replace b = t if _n > _N / 2
		qui drop t
	}
	qui gen double w = ceil(runiform() * 5) - (runiform() < 0.1) * 3 * `val'
	if !`val' qui replace w = 1
	* multiple edges and self-loops in the edge list (the constructor keeps one tie per dyad)
	qui expand 2 in 1/3
	local opt = cond(`dir', "directed", "undirected")
	if `val' qui nwfromedge a b w, name(net) `opt'
	else qui nwfromedge a b, name(net) `opt'
	if `iso' qui nwaddnodes net, nodenames(iso_a iso_b iso_c)
	_bk_cmp net "r=`r' n=`n' dir=`dir' val=`val' iso=`iso'"
	local ++nnet
	nwclear
}

* networks with self-loops
forvalues r = 1/6 {
	local n = 8 + 20 * `r'
	clear
	qui nwrandom `n', prob(.15) selfloop name(lp) `=cond(mod(`r',2), "undirected", "")'
	_bk_cmp lp "selfloop r=`r' n=`n'"
	local ++nnet
	nwclear
}

* a network of more than 2,000 nodes held as stored ties (the sparse route of nwconstraint)
forvalues r = 1/2 {
	clear
	local n = 2100 + 300 * `r'
	qui set obs `=5 * `n''
	qui gen long a = ceil(runiform() * `n')
	qui gen long b = ceil(runiform() * `n')
	if `r' == 2 {
		qui expand 2
		qui gen long t = a
		qui replace a = b if _n > _N / 2
		qui replace b = t if _n > _N / 2
		qui drop t
	}
	qui nwfromedge a b, name(big) `=cond(`r' == 1, "undirected", "directed")'
	_bk_cmp big "large r=`r' n=`n'"
	local ++nnet
	nwclear
}

* hand-checkable cases: a star, a triangle with a pendant node, an empty network
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(star) undirected
qui nwburt star, silent
assert reldif(_effsize[1], 3) < 1e-6 & reldif(_effsize[2], 1) < 1e-6 & reldif(_constraint[2], 1) < 1e-6
qui nwsimmelian star, name(sm)
nwtomata sm, mat(bk_m)
mata: assert(sum(editvalue(bk_m, ., 0)) == 0)
nwclear
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(tp) undirected
qui nwsimmelian tp, name(sm)
nwtomata sm, mat(bk_m)
mata: assert(editvalue(bk_m, ., 0) == (0,1,1,0\1,0,1,0\1,1,0,0\0,0,0,0))
nwclear
nwset, mat((0,0,0\0,0,0\0,0,0)) name(emp) undirected
qui nwburt emp, silent
assert _effsize[1] == 0 & _hierarchy[1] == .
qui nwconstraint emp, name(ce)
qui nwsimmelian emp, name(se)

di as txt "brokerage kernels: `nnet' random networks, all equal (max relative difference of nwburt " as res %9.2e $bk_maxdiff as txt ")"
