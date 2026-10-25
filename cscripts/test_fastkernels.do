cscript

do unw_core.do

* Native kernels 26 (nwclustering), 27 (nwtriads) and 28 (nwevcent) against the Mata code they replace.
* The Mata path is forced with the global NW_NOFASTKERNELS. Counts must agree exactly, floats to 1e-10.
* Runs in well under a minute. Prints "fastkernels: n random networks, all equal" on success.
* Without a plugin of generation 6 (Linux/Windows binaries before the CI build) the comparison is skipped.

mata: st_local("gen", strofreal(nwg_comb_version()))
if `gen' < 6 {
	di as txt "fastkernels: plugin generation `gen' < 6, native kernels not available: SKIPPED"
	exit
}

capture program drop _fk_cmp
program define _fk_cmp
	args net kind
	local tri _003 _012 _021D _021U _021C _030T _030C _102 _111D _111U _120D _120U _120C _201 _210 _300
	tempvar cf co ef eo
	* clustering (binary measure)
	global NW_NOFASTKERNELS
	qui nwclustering `net', generate(`cf') silent
	local gf = r(cluster_global)
	local af = r(cluster_avg)
	global NW_NOFASTKERNELS 1
	qui nwclustering `net', generate(`co') silent
	local go = r(cluster_global)
	local ao = r(cluster_avg)
	global NW_NOFASTKERNELS
	capture assert (`cf' == `co') | (reldif(`cf', `co') < 1e-12)
	if _rc {
		di as err "clustering differs: `net' (`kind')"
		exit 9
	}
	foreach p in g a {
		if !((``p'f' == ``p'o') | (reldif(``p'f', ``p'o') < 1e-12)) {
			di as err "clustering scalar `p' differs: `net' (`kind')"
			exit 9
		}
	}
	* triad census
	qui nwtriads `net'
	foreach t of local tri {
		local f`t' = r(`t')
	}
	local trf = r(transitivity)
	global NW_NOFASTKERNELS 1
	qui nwtriads `net'
	global NW_NOFASTKERNELS
	local bad 0
	foreach t of local tri {
		* the Mata census forms the 003 count as n(n-1)(n-2)/6 - sum, which can carry a rounding error of
		* one unit in the last place (about 4e-12 at 28,643) that the exact integer of the native kernel lacks
		if abs(`f`t'' - r(`t')) > 1e-6 {
			di as err "triad `t' differs: `net' (`kind'): " %22.12f `f`t'' " vs " %22.12f r(`t')
			local bad 1
		}
	}
	if `bad' exit 9
	if !((`trf' == r(transitivity)) | reldif(`trf', r(transitivity)) < 1e-12) {
		di as err "transitivity differs: `net' (`kind')"
		exit 9
	}
	* the same comparison at double precision on the kernel itself (generate() variables are floats)
	_nwsyntax `net'
	mata: fk_cc = `netobj'->calculate_clustering(0)
	mata: fk_r = nwg_comb(26, `nodes', `netobj'->edgelist(), J(0, 1, .), `netobj'->is_directed_boolean() != 0, fk_aux = J(1, 4, .), fk_st = .)
	mata: st_local("md", strofreal(rows(fk_r) == rows(fk_cc) ? mreldif((fk_r[., 1], editvalue(fk_r[., 2], 0, .)), fk_cc[., (2, 3)]) : 99))
	if `md' != 0 {
		di as err "clustering kernel differs (`md'): `net' (`kind')"
		exit 9
	}
	* the triad kernel itself against the Mata census (not for loops, where the Mata census is undefined), and that kernel 28 answers
	mata: fk_el = `netobj'->edgelist()
	mata: fk_t = nwg_comb(27, `nodes', fk_el, J(0, 1, .), J(1, 0, .), fk_aux = J(1, 4, .), fk_st = .)
	mata: st_local("loops", strofreal(rows(fk_el) > 0 ? any(fk_el[., 1] :== fk_el[., 2]) : 0))
	mata: st_local("md", strofreal(fk_st == 0 & rows(fk_t) == 1 & cols(fk_t) == 16 ? (`loops' ? 0 : max(abs(fk_t - `netobj'->calculate_triadcensus()))) : 99))
	if `md' > 1e-6 {
		di as err "triad kernel differs (`md'): `net' (`kind')"
		exit 9
	}
	mata: fk_e = nwg_comb(28, `nodes', fk_el, J(0, 1, .), (0, 0), fk_aux, fk_st = .)
	mata: st_local("md", strofreal(fk_st == 0 & rows(fk_e) == `nodes' & cols(fk_e) == 1 ? 0 : 99))
	if `md' != 0 {
		di as err "evcent kernel did not answer: `net' (`kind')"
		exit 9
	}
	* eigenvector centrality: default, nosym, weighted, nosym weighted, in double variables
	foreach o in "" "nosym" "weighted" "nosym weighted" {
		qui gen double `ef' = .
		qui gen double `eo' = .
		global NW_NOFASTKERNELS
		qui nwevcent `net', generate(`ef') replace `o'
		global NW_NOFASTKERNELS 1
		qui nwevcent `net', generate(`eo') replace `o'
		global NW_NOFASTKERNELS
		qui gen double __fkd = reldif(`ef', `eo')
		qui count if (`ef' == .) != (`eo' == .)
		local nmis = r(N)
		qui sum __fkd
		local md = cond(r(N) > 0, r(max), 0)
		drop `ef' `eo' __fkd
		if `nmis' | `md' > 1e-10 {
			di as err "nwevcent (`o') differs (`md', `nmis' missing mismatches): `net' (`kind')"
			exit 9
		}
		if `md' > $fk_maxdiff {
			global fk_maxdiff = `md'
		}
	}
end

set seed 20261025
global fk_maxdiff 0
local nnet 0
local nloop 0
forvalues r = 1/72 {
	local n = 5 + floor(runiform()^2 * 295)
	local dir = mod(`r', 2)
	local val = (mod(`r', 3) == 0)
	local iso = (mod(`r', 4) < 2)
	local m = ceil(`n' * (0.4 + 3 * runiform()))
	clear
	qui set obs `m'
	local top `n'
	qui gen long a = ceil(runiform() * `top')
	qui gen long b = ceil(runiform() * `top')
	qui gen double w = ceil(runiform() * 5) - (runiform() < 0.1) * 3 * `val'
	if !`val' qui replace w = 1
	* multiple edges and self-loops in the edge list (the constructor keeps one tie per dyad)
	qui expand 2 in 1/3
	local opt = cond(`dir', "directed", "undirected")
	if `val' qui nwfromedge a b w, name(net) `opt'
	else qui nwfromedge a b, name(net) `opt'
	if `iso' qui nwaddnodes net, nodenames(iso_a iso_b iso_c)
	_fk_cmp net "r=`r' n=`n' dir=`dir' val=`val' iso=`iso'"
	local ++nnet
	nwclear
}

* networks with self-loops (nwtriads must hand these to the Mata census, clustering and evcent run native)
forvalues r = 1/6 {
	local n = 8 + 20 * `r'
	clear
	qui nwrandom `n', prob(.15) selfloop name(lp) `=cond(mod(`r',2), "undirected", "")'
	_fk_cmp lp "selfloop r=`r' n=`n'"
	local ++nnet
	nwclear
}

* two-mode networks (nwclustering hands over to nw2clustering; nwtriads and nwevcent run on the matrix)
forvalues r = 1/4 {
	clear
	qui set obs `=30 + 10 * `r''
	qui gen str5 a = "p" + string(ceil(runiform() * 12))
	qui gen str5 b = "e" + string(ceil(runiform() * (6 + 3 * `r')))
	qui nwfromedge a b, name(tm) twomode
	local tri _003 _012 _021D _021U _021C _030T _030C _102 _111D _111U _120D _120U _120C _201 _210 _300
	global NW_NOFASTKERNELS
	qui nwtriads tm
	foreach t of local tri {
		local f`t' = r(`t')
	}
	qui nwevcent tm, generate(__e1)
	global NW_NOFASTKERNELS 1
	qui nwtriads tm
	foreach t of local tri {
		assert abs(`f`t'' - r(`t')) < 1e-6
	}
	qui nwevcent tm, generate(__e2) replace
	global NW_NOFASTKERNELS
	assert (__e1 == __e2) | reldif(__e1, __e2) < 1e-6
	local ++nnet
	nwclear
}

* hand-checkable cases: a triangle, a 3-node path, an empty network, a directed 3-cycle
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri) undirected
qui nwclustering tri, generate(c) silent
assert c[1] == 1 & r(cluster_global) == 1
qui nwtriads tri
assert r(_300) == 1 & r(_003) == 0
qui nwevcent tri, generate(e)
assert reldif(e[1], 1/sqrt(3)) < 1e-6
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(pth) undirected
qui nwclustering pth, generate(c) silent
assert c[2] == 0 & c[1] == .
qui nwevcent pth, generate(e)
assert reldif(e[2], 1/sqrt(2)) < 1e-6
nwclear
nwset, mat((0,0,0,0\0,0,0,0\0,0,0,0\0,0,0,0)) name(emp) undirected
qui nwtriads emp
assert r(_003) == 4
qui nwevcent emp, generate(e)
assert e[1] == .
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(cyc)
qui nwtriads cyc
assert r(_030C) == 1
qui nwclustering cyc, generate(c) silent
assert c[1] == 0

di as txt "fastkernels: `nnet' random networks, all equal (max relative difference of nwevcent " as res %9.2e $fk_maxdiff as txt ")"
