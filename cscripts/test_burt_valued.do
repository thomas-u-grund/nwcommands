cscript

do unw_core.do

* nwburt on VALUED networks: Burt's (1992) weighted measures (native kernel 40, plugin generation 9) against an
* independent dense implementation in R (tools/verify_burt.R, which also agrees with igraph::constraint(weights=) to 1e-15
* and with networkx.effective_size/constraint(weight=) to 1e-14). Fixture: 60 random networks (undirected and directed,
* integer and non-integer weights, isolates, self-loops, repeated ties added up), in cscripts/burt_valued_fixture/.
* The option binary (every positive value is a tie) is checked on the undirected networks against the same R code
* run on the dichotomized matrix. Prints "burt valued: ... all equal" on success.

mata: st_local("gen", strofreal(nwg_comb_version()))
if `gen' < 9 {
	di as txt "burt valued: plugin generation `gen' < 9, weighted kernel not available: SKIPPED"
	exit
}

local fx "cscripts/burt_valued_fixture"
tempfile cells nets
preserve
qui import delimited using "`fx'/cells.csv", clear
qui save `cells'
qui import delimited using "`fx'/nets.csv", clear
qui save `nets'
qui import delimited using "`fx'/expected.csv", clear case(preserve)
tempfile exp
qui save `exp'
restore

mata: bv_maxd = 0; bv_maxb = 0
local nn 0
forvalues b = 1/60 {
	preserve
	qui use `nets', clear
	qui keep if net == `b'
	local n = n[1]
	local dir = directed[1]
	qui use `cells', clear
	qui keep if net == `b'
	mata: bv_el = st_data(., ("i", "j", "w"))
	restore
	mata: bv_M = J(`n', `n', 0)
	mata: for (bv_k = 1; bv_k <= rows(bv_el); bv_k++) bv_M[bv_el[bv_k, 1], bv_el[bv_k, 2]] = bv_el[bv_k, 3]
	nwclear
	if `dir' nwset, mat(bv_M) name(bvnet)
	else nwset, mat(bv_M) name(bvnet) undirected
	qui nwburt bvnet, replace silent
	preserve
	qui use `exp', clear
	qui keep if net == `b'
	sort node
	tempname E
	mkmat es eff con hier, matrix(`E')
	restore
	mata: bv_E = st_matrix("`E'")
	mata: bv_G = st_data((1::`n'), ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
	mata: st_local("d", strofreal(mreldif(editvalue(bv_E, ., -99), editvalue(bv_G, ., -99))))
	if `d' > 1e-10 {
		di as err "weighted burt differs from R in network `b': reldif `d'"
		exit 9
	}
	mata: bv_maxd = max((bv_maxd, `d'))
	local ++nn

	* binary option on the undirected networks: dichotomized matrix, same R formulas
	if !`dir' {
		qui nwburt bvnet, replace silent binary
		preserve
		qui use `exp', clear
		qui keep if net == `b'
		sort node
		tempname EB
		mkmat bes beff bcon bhier, matrix(`EB')
		restore
		mata: bv_E = st_matrix("`EB'")
		mata: bv_G = st_data((1::`n'), ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
		mata: st_local("d", strofreal(mreldif(editvalue(bv_E, ., -99), editvalue(bv_G, ., -99))))
		if `d' > 1e-10 {
			di as err "binary burt differs from R in network `b': reldif `d'"
			exit 9
		}
		mata: bv_maxb = max((bv_maxb, `d'))
	}
}

* binary option: gang_valued (values 1-4) with binary equals the unvalued result of its dichotomized network exactly
nwclear
qui nwuse data/gang, nwclear
qui nwdichotomize gang_valued, threshold(0.5) generate(gang01)
qui nwburt gang01, silent replace
mata: bv_A = st_data((1::54), ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
qui nwburt gang_valued, silent replace binary
mata: bv_B = st_data((1::54), ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
mata: st_local("same", strofreal(bv_A == bv_B))
assert `same' == 1
* a valued network is weighted by default, and differs from the binary result
qui nwburt gang_valued, silent replace
assert r(weighted) == 1
mata: bv_C = st_data((1::54), ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
mata: st_local("same", strofreal(bv_A == bv_C))
assert `same' == 0
* effective size and efficiency stay within their bounds (1 <= ES <= number of contacts for a node with contacts)
assert _effsize <= 54 & _efficiency <= 1 + 1e-12 & _efficiency > 0 if _efficiency != .
* an unvalued network is not weighted
qui nwburt gang01, silent replace
assert r(weighted) == 0

* dyadic options: refused for a valued network, allowed with binary
capture nwburt gang_valued, dyadredundancy
assert _rc == 198
capture nwburt gang_valued, dyadredundancy dyadconstraint binary replace silent
assert _rc == 0

* without the native kernels a valued network gives a clear error (no slow fallback)
global NW_NOFASTKERNELS 1
capture nwburt gang_valued, replace silent
assert _rc == 198
capture nwburt gang_valued, replace silent binary
assert _rc == 198
global NW_NOFASTKERNELS
* ... an unvalued network still runs through the Mata method
global NW_NOFASTKERNELS 1
qui nwburt gang01, replace silent
mata: bv_D = st_data((1::54), ("_effsize", "_efficiency", "_constraint", "_hierarchy"))
global NW_NOFASTKERNELS
mata: st_local("md", strofreal(mreldif(editvalue(bv_A, ., -99), editvalue(bv_D, ., -99))))
assert `md' < 1e-10

* negative values are refused
nwclear
nwset, mat((0,2,-1\2,0,1\-1,1,0)) name(neg) undirected
capture nwburt neg, silent
assert _rc == 198

* the dialog opens (with the option binary)
capture db nwburt
assert _rc == 0

mata: st_local("maxd", strofreal(bv_maxd, "%9.2e")); st_local("maxb", strofreal(bv_maxb, "%9.2e"))
di as txt "burt valued: `nn' random valued networks against R, max reldif `maxd'; binary `maxb', all equal"
