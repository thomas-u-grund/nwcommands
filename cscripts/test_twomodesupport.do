cscript

* Two-mode networks (twomodesupport): independent checks against R (igraph 2.3.2, tnet 3.0.16, vegan, bipartite 2.24, base R).
* The expected numbers were computed once with Rscript on the toy network (6 persons x 4 groups, 12 ties), the Southern
* women (davis, 18 x 14, 89 ties) and the Swedish directors (ftdirectors_se, 5,092 x 455, 5,669 ties) and are fixed below.
* Run from the repository root.  Prints "test_twomodesupport: all passed" or the failing checks and exits with an error.
clear all
set more off
qui do unw_core.do

* ----------------------------------------------------------------------------------------------------------
* helpers
capture program drop _chk
program _chk
	args ok label
	if `ok' {
		di "  ok:   `label'"
	}
	else {
		di as err "  FAIL: `label'"
		global TM_FAILS = $TM_FAILS + 1
	}
end
global TM_FAILS 0

* two numbers
capture program drop _near
program _near
	args a b tol label
	_chk `=(abs(`a' - `b') < `tol')' "`label' (`a' against `b')"
end

* a 1 x k matrix against an expected 1 x k matrix
capture program drop _nearmat
program _nearmat
	args m e tol label
	mata: st_numscalar("__d", max(abs(st_matrix("`m'") - st_matrix("`e'"))))
	_chk `=(scalar(__d) < `tol')' "`label' (max abs diff `=scalar(__d)')"
end

* first rows of a variable against an expected 1 x n matrix
capture program drop _cmpvar
program _cmpvar
	args var exp tol label
	mata: st_numscalar("__d", max(abs(st_data((1, cols(st_matrix("`exp'"))), "`var'") - st_matrix("`exp'")')))
	_chk `=(scalar(__d) < `tol')' "`label' (max abs diff `=scalar(__d)')"
end

* a network (matrix with . between the nodes of different modes) against an expected n x n matrix given by rows
capture program drop _cmpnet
program _cmpnet
	args net exp n tol label
	_nwsyntax `net', max(1)
	mata: A = *`netobj'->get_matrix(); B = colshape(st_matrix("`exp'"), `n'); _diag(A, 0); _diag(B, 0)
	mata: st_numscalar("__d", max(editmissing(abs(A - B), 0)))
	mata: st_numscalar("__m", sum((A :== .) :!= (B :== .)))
	_chk `=(scalar(__d) < `tol' & scalar(__m) == 0)' "`label' (max abs diff `=scalar(__d)', missing pattern differs in `=scalar(__m)' cells)"
	mata: mata drop A B
end

* the command must stop with error 6088 and the one shared message
capture program drop _refuses
program _refuses
	args cmd
	tempfile lg
	qui log using "`lg'", text replace name(tmref)
	capture noisily `cmd'
	local rc = _rc
	qui log close tmref
	local found 0
	file open fh using "`lg'", read text
	file read fh line
	while r(eof) == 0 {
		if strpos(`"`line'"', "does not support two-mode networks") local found 1
		file read fh line
	}
	file close fh
	_chk `=(`rc' == 6088 & `found' == 1)' "`cmd' refuses a two-mode network (rc `rc', message `found')"
end

* node names in ascending byte order: the R vectors below are in this order
capture program drop _nodeorder
program _nodeorder
	args net
	_nwsyntax `net', max(1)
	mata: nm = `netobj'->get_nodenames(); st_numscalar("__o", min(nm[1..cols(nm)-1] :< nm[2..cols(nm)]))
	_chk `=(scalar(__o) == 1)' "nodes of `net' are in name order"
end

* ---- the networks: toy (6 persons x 4 groups), Southern women, Swedish directors
clear
input str3 p str3 g
"p1" "g1"
"p1" "g2"
"p2" "g1"
"p2" "g2"
"p2" "g3"
"p3" "g2"
"p3" "g3"
"p4" "g3"
"p4" "g4"
"p5" "g4"
"p6" "g4"
"p6" "g1"
end
tempfile toyf
save `toyf'
global TOYF "`toyf'"
capture program drop _load
program _load
	args which
	if "`which'" == "tm" {
		nwclear
		use "$TOYF", clear
		nw2fromedge p g, name(tm)
	}
	else {
		nwuse data/`which', nwclear
	}
end
_load tm

* ---- expected values: R 4.6 with igraph 2.3.2, tnet 3.0.16, vegan and bipartite 2.24 (fixed numbers)
// ---- nestedness, Robins-Alexander, degree: toy (t), Southern women (d), Swedish directors (f)
matrix R_t_nodf = (23.8095238095238,33.3333333333333,0.0000000000000)
matrix R_t_cs = (3.833333333333333,0.425925925925926)
matrix R_t_ra = (0.285714285714286,2.000000000000000,28.000000000000000)
scalar R_t_opsahl = 0.25
matrix R_t_rowdeg = (2,3,2,2,1,2)
matrix R_t_coldeg = (3,3,3,3)
matrix R_d_nodf = (48.5811865729898,48.2057267351385,49.2124542124542)
matrix R_d_cs = (12.593406593406593,0.449379536824592)
matrix R_d_ra = (0.467764060356653,341.000000000000000,2916.000000000000000)
scalar R_d_opsahl = 0.771896799911416
matrix R_d_rowdeg = (7,4,2,4,8,2,4,5,6,7,4,8,2,3,4,7,8,4)
matrix R_d_coldeg = (3,5,4,6,3,3,3,6,4,8,8,10,14,12)
matrix R_f_nodf = (0.0874427735231336,0.0875867280447461,0.0693772916940605)
matrix R_f_ra = (0.0228410513141427,146.0000000000000000,25568.0000000000000000)
scalar R_f_opsahl = 0.00289377837649055
scalar R_f_rowdeg_sum = 5669
scalar R_f_rowdeg_max = 7
scalar R_f_rowdeg_n = 5092
scalar R_f_coldeg_sum = 5669
scalar R_f_coldeg_max = 52
scalar R_f_coldeg_n = 455
// ---- nodes in name order: closeness, betweenness (Borgatti-Everett), spectral, hitting time
matrix R_t_far = (18,22,18,20,22,18,22,20,28,20)
matrix R_t_beclose = (0.666666666666667,0.545454545454545,0.666666666666667,0.600000000000000,0.636363636363636,0.777777777777778,0.636363636363636,0.700000000000000,0.500000000000000,0.700000000000000)
matrix R_t_btw = (9.58333333333333,4.33333333333333,9.58333333333333,10.50000000000000,2.08333333333333,7.33333333333333,2.08333333333333,6.75000000000000,0.00000000000000,6.75000000000000)
matrix R_t_bebtw = (0.2904040404040404,0.1313131313131313,0.2904040404040404,0.3181818181818182,0.0694444444444444,0.2444444444444444,0.0694444444444444,0.2250000000000000,0.0000000000000000,0.2250000000000000)
scalar R_t_algconn = 0.428754449359034
matrix R_t_hit = (11.3,10.7,17.3,20.3,0.0,14.1,15.0,19.8,21.3,16.8)
matrix R_t_ord_is_row = (0,0,0,0,1,1,1,1,1,1)
matrix R_d_far = (66,80,74,84,80,82,78,84,84,84,78,82,74,64,60,52,56,72,60,82,72,66,66,66,70,60,82,72,68,62,60,68)
matrix R_d_beclose = (0.727272727272727,0.600000000000000,0.648648648648649,0.523809523809524,0.550000000000000,0.536585365853659,0.564102564102564,0.523809523809524,0.523809523809524,0.523809523809524,0.564102564102564,0.536585365853659,0.594594594594595,0.687500000000000,0.733333333333333,0.846153846153846,0.785714285714286,0.666666666666667,0.800000000000000,0.585365853658537,0.666666666666667,0.727272727272727,0.727272727272727,0.727272727272727,0.685714285714286,0.800000000000000,0.585365853658537,0.666666666666667,0.705882352941177,0.774193548387097,0.800000000000000,0.705882352941177)
matrix R_d_btw = (22.021536918123200,4.715262845785665,0.869319452477347,0.973748473748474,5.171920775639310,8.888756681914577,8.178570287230606,1.012776506483601,1.012776506483601,0.944090996722576,8.237424665342285,3.481327808558929,17.037888021303015,29.387390414772650,58.534788398829690,110.206396982008144,101.932143480962552,4.202634888404976,42.980200880730237,2.249254830137183,4.767882576974662,18.862455328634979,21.076425543269760,22.854137904582785,7.273235022430620,50.490306109128227,2.249254830137183,3.026143883636144,7.468483122207176,31.910569562833139,38.979635038353820,7.003261262152899)
matrix R_d_bebtw = (0.04948659981600719,0.01059609628266442,0.00195352685949966,0.00215431078262937,0.01144230260097192,0.01966539088919154,0.01809418205139515,0.00224065598779558,0.00224065598779558,0.00208869689540393,0.01822439085252718,0.00770205267380294,0.03769444252500667,0.06501635047516073,0.12950174424519842,0.24381946234957555,0.22551359177204106,0.00944412334473028,0.09658472108029267,0.00505450523626333,0.01071434286960598,0.04238754006434827,0.04736275402981969,0.05135761326872536,0.01634434836501263,0.11346136204298478,0.00505450523626333,0.00680032333401381,0.01678310813979141,0.07170914508501829,0.08759468547944678,0.01573766575764696)
scalar R_d_algconn = 0.932000988900651
matrix R_d_hit = (0.0000000000000,25.2385093777292,32.3367271392379,18.6441521679816,35.1347795779336,35.6202588514286,34.8483009080774,35.2940316538987,35.2940316538987,27.8737314062554,23.1164831169810,20.8571923618227,24.8384869834796,26.0086785229247,28.1418750486335,29.3931317981767,33.2803224802991,28.0955430883036,26.5015223547401,35.4502906658638,26.8391951053905,33.6276692368500,34.8740996787140,26.4309341492046,34.1641336911217,33.9527848371368,35.4502906658638,30.5607109338001,29.9134540776472,34.0552104458454,27.6887377148216,32.4159075587967)
matrix R_d_ord_is_row = (1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)
// ---- same-mode (dis)similarity of the profiles, full n x n in node order, missing between modes
matrix R_t_jac = (1.000000000000000,0.500000000000000,0.200000000000000,0.200000000000000,.,.,.,.,.,.,0.500000000000000,1.000000000000000,0.500000000000000,0.000000000000000,.,.,.,.,.,.,0.200000000000000,0.500000000000000,1.000000000000000,0.200000000000000,.,.,.,.,.,.,0.200000000000000,0.000000000000000,0.200000000000000,1.000000000000000,.,.,.,.,.,.,.,.,.,.,1.000000000000000,0.666666666666667,0.333333333333333,0.000000000000000,0.000000000000000,0.333333333333333,.,.,.,.,0.666666666666667,1.000000000000000,0.666666666666667,0.250000000000000,0.000000000000000,0.250000000000000,.,.,.,.,0.333333333333333,0.666666666666667,1.000000000000000,0.333333333333333,0.000000000000000,0.000000000000000,.,.,.,.,0.000000000000000,0.250000000000000,0.333333333333333,1.000000000000000,0.500000000000000,0.333333333333333,.,.,.,.,0.000000000000000,0.000000000000000,0.000000000000000,0.500000000000000,1.000000000000000,0.500000000000000,.,.,.,.,0.333333333333333,0.250000000000000,0.000000000000000,0.333333333333333,0.500000000000000,1.000000000000000)
matrix R_t_prs = (1.000000000000000,0.333333333333333,-0.333333333333333,-0.333333333333333,.,.,.,.,.,.,0.333333333333333,1.000000000000000,0.333333333333333,-1.000000000000000,.,.,.,.,.,.,-0.333333333333333,0.333333333333333,1.000000000000000,-0.333333333333333,.,.,.,.,.,.,-0.333333333333333,-1.000000000000000,-0.333333333333333,1.000000000000000,.,.,.,.,.,.,.,.,.,.,1.000000000000000,0.577350269189626,0.000000000000000,-1.000000000000000,-0.577350269189626,0.000000000000000,.,.,.,.,0.577350269189626,1.000000000000000,0.577350269189626,-0.577350269189626,-1.000000000000000,-0.577350269189626,.,.,.,.,0.000000000000000,0.577350269189626,1.000000000000000,0.000000000000000,-0.577350269189626,-1.000000000000000,.,.,.,.,-1.000000000000000,-0.577350269189626,0.000000000000000,1.000000000000000,0.577350269189626,0.000000000000000,.,.,.,.,-0.577350269189626,-1.000000000000000,-0.577350269189626,0.577350269189626,1.000000000000000,0.577350269189626,.,.,.,.,0.000000000000000,-0.577350269189626,-1.000000000000000,0.000000000000000,0.577350269189626,1.000000000000000)
matrix R_t_euc = (0.00000000000000,1.41421356237310,2.00000000000000,2.00000000000000,.,.,.,.,.,.,1.41421356237310,0.00000000000000,1.41421356237310,2.44948974278318,.,.,.,.,.,.,2.00000000000000,1.41421356237310,0.00000000000000,2.00000000000000,.,.,.,.,.,.,2.00000000000000,2.44948974278318,2.00000000000000,0.00000000000000,.,.,.,.,.,.,.,.,.,.,0.00000000000000,1.00000000000000,1.41421356237310,2.00000000000000,1.73205080756888,1.41421356237310,.,.,.,.,1.00000000000000,0.00000000000000,1.00000000000000,1.73205080756888,2.00000000000000,1.73205080756888,.,.,.,.,1.41421356237310,1.00000000000000,0.00000000000000,1.41421356237310,1.73205080756888,2.00000000000000,.,.,.,.,2.00000000000000,1.73205080756888,1.41421356237310,0.00000000000000,1.00000000000000,1.41421356237310,.,.,.,.,1.73205080756888,2.00000000000000,1.73205080756888,1.00000000000000,0.00000000000000,1.00000000000000,.,.,.,.,1.41421356237310,1.73205080756888,2.00000000000000,1.41421356237310,1.00000000000000,0.00000000000000)
matrix R_t_man = (0,2,4,4,.,.,.,.,.,.,2,0,2,6,.,.,.,.,.,.,4,2,0,4,.,.,.,.,.,.,4,6,4,0,.,.,.,.,.,.,.,.,.,.,0,1,2,4,3,2,.,.,.,.,1,0,1,3,4,3,.,.,.,.,2,1,0,2,3,4,.,.,.,.,4,3,2,0,1,2,.,.,.,.,3,4,3,1,0,1,.,.,.,.,2,3,4,2,1,0)
matrix R_t_crs = (3,2,1,1,.,.,.,.,.,.,2,3,2,0,.,.,.,.,.,.,1,2,3,1,.,.,.,.,.,.,1,0,1,3,.,.,.,.,.,.,.,.,.,.,2,2,1,0,0,1,.,.,.,.,2,3,2,1,0,1,.,.,.,.,1,2,2,1,0,0,.,.,.,.,0,1,1,2,1,1,.,.,.,.,0,0,0,1,1,1,.,.,.,.,1,1,0,1,1,2)
matrix R_t_mch = (1.000000000000000,0.666666666666667,0.333333333333333,0.333333333333333,.,.,.,.,.,.,0.666666666666667,1.000000000000000,0.666666666666667,0.000000000000000,.,.,.,.,.,.,0.333333333333333,0.666666666666667,1.000000000000000,0.333333333333333,.,.,.,.,.,.,0.333333333333333,0.000000000000000,0.333333333333333,1.000000000000000,.,.,.,.,.,.,.,.,.,.,1.000000000000000,0.750000000000000,0.500000000000000,0.000000000000000,0.250000000000000,0.500000000000000,.,.,.,.,0.750000000000000,1.000000000000000,0.750000000000000,0.250000000000000,0.000000000000000,0.250000000000000,.,.,.,.,0.500000000000000,0.750000000000000,1.000000000000000,0.500000000000000,0.250000000000000,0.000000000000000,.,.,.,.,0.000000000000000,0.250000000000000,0.500000000000000,1.000000000000000,0.750000000000000,0.500000000000000,.,.,.,.,0.250000000000000,0.000000000000000,0.250000000000000,0.750000000000000,1.000000000000000,0.750000000000000,.,.,.,.,0.500000000000000,0.250000000000000,0.000000000000000,0.500000000000000,0.750000000000000,1.000000000000000)
matrix R_t_ham = (6,4,2,2,.,.,.,.,.,.,4,6,4,0,.,.,.,.,.,.,2,4,6,2,.,.,.,.,.,.,2,0,2,6,.,.,.,.,.,.,.,.,.,.,4,3,2,0,1,2,.,.,.,.,3,4,3,1,0,1,.,.,.,.,2,3,4,2,1,0,.,.,.,.,0,1,2,4,3,2,.,.,.,.,1,0,1,3,4,3,.,.,.,.,2,1,0,2,3,4)
matrix R_t_nonm = (0.000000000000000,0.333333333333333,0.666666666666667,0.666666666666667,.,.,.,.,.,.,0.333333333333333,0.000000000000000,0.333333333333333,1.000000000000000,.,.,.,.,.,.,0.666666666666667,0.333333333333333,0.000000000000000,0.666666666666667,.,.,.,.,.,.,0.666666666666667,1.000000000000000,0.666666666666667,0.000000000000000,.,.,.,.,.,.,.,.,.,.,0.000000000000000,0.250000000000000,0.500000000000000,1.000000000000000,0.750000000000000,0.500000000000000,.,.,.,.,0.250000000000000,0.000000000000000,0.250000000000000,0.750000000000000,1.000000000000000,0.750000000000000,.,.,.,.,0.500000000000000,0.250000000000000,0.000000000000000,0.500000000000000,0.750000000000000,1.000000000000000,.,.,.,.,1.000000000000000,0.750000000000000,0.500000000000000,0.000000000000000,0.250000000000000,0.500000000000000,.,.,.,.,0.750000000000000,1.000000000000000,0.750000000000000,0.250000000000000,0.000000000000000,0.250000000000000,.,.,.,.,0.500000000000000,0.750000000000000,1.000000000000000,0.500000000000000,0.250000000000000,0.000000000000000)
matrix R_t_dham = (0,2,4,4,.,.,.,.,.,.,2,0,2,6,.,.,.,.,.,.,4,2,0,4,.,.,.,.,.,.,4,6,4,0,.,.,.,.,.,.,.,.,.,.,0,1,2,4,3,2,.,.,.,.,1,0,1,3,4,3,.,.,.,.,2,1,0,2,3,4,.,.,.,.,4,3,2,0,1,2,.,.,.,.,3,4,3,1,0,1,.,.,.,.,2,3,4,2,1,0)
matrix R_t_djac = (0.000000000000000,0.500000000000000,0.800000000000000,0.800000000000000,.,.,.,.,.,.,0.500000000000000,0.000000000000000,0.500000000000000,1.000000000000000,.,.,.,.,.,.,0.800000000000000,0.500000000000000,0.000000000000000,0.800000000000000,.,.,.,.,.,.,0.800000000000000,1.000000000000000,0.800000000000000,0.000000000000000,.,.,.,.,.,.,.,.,.,.,0.000000000000000,0.333333333333333,0.666666666666667,1.000000000000000,1.000000000000000,0.666666666666667,.,.,.,.,0.333333333333333,0.000000000000000,0.333333333333333,0.750000000000000,1.000000000000000,0.750000000000000,.,.,.,.,0.666666666666667,0.333333333333333,0.000000000000000,0.666666666666667,1.000000000000000,1.000000000000000,.,.,.,.,1.000000000000000,0.750000000000000,0.666666666666667,0.000000000000000,0.500000000000000,0.666666666666667,.,.,.,.,1.000000000000000,1.000000000000000,1.000000000000000,0.500000000000000,0.000000000000000,0.500000000000000,.,.,.,.,0.666666666666667,0.750000000000000,1.000000000000000,0.666666666666667,0.500000000000000,0.000000000000000)
scalar R_d_jac_sum = 164.688276429453
matrix R_d_jac_head = (1.000000000000000,0.571428571428571,0.125000000000000,0.571428571428571,1.000000000000000,0.000000000000000,0.125000000000000,0.000000000000000,1.000000000000000)
scalar R_d_prs_sum = 83.7334606746366
matrix R_d_prs_head = (1.000000000000000,0.632455532033676,0.000000000000000,0.632455532033676,1.000000000000000,-0.258198889747161,0.000000000000000,-0.258198889747161,1.000000000000000)
scalar R_d_euc_sum = 1206.02668610401
matrix R_d_euc_head = (0.00000000000000,1.73205080756888,2.64575131106459,1.73205080756888,0.00000000000000,2.44948974278318,2.64575131106459,2.44948974278318,0.00000000000000)
scalar R_d_man_sum = 3196
matrix R_d_man_head = (0,3,7,3,0,6,7,6,0)
scalar R_d_crs_sum = 1250
matrix R_d_crs_head = (7,4,1,4,4,0,1,0,2)
scalar R_d_mch_sum = 314.857142857143
matrix R_d_mch_head = (1.000000000000000,0.785714285714286,0.500000000000000,0.785714285714286,1.000000000000000,0.571428571428571,0.500000000000000,0.571428571428571,1.000000000000000)
scalar R_d_ham_sum = 4868
matrix R_d_ham_head = (14,11,7,11,14,8,7,8,14)
scalar R_d_nonm_sum = 205.142857142857
matrix R_d_nonm_head = (0.000000000000000,0.214285714285714,0.500000000000000,0.214285714285714,0.000000000000000,0.428571428571429,0.500000000000000,0.428571428571429,0.000000000000000)
scalar R_d_dham_sum = 3196
matrix R_d_dham_head = (0,3,7,3,0,6,7,6,0)
scalar R_d_djac_sum = 355.311723570547
matrix R_d_djac_head = (0.000000000000000,0.428571428571429,0.875000000000000,0.428571428571429,0.000000000000000,1.000000000000000,0.875000000000000,1.000000000000000,0.000000000000000)
// ---- Newman projection of the persons (tnet projecting_tm, binary: symmetric)
matrix R_t_newman = (0.0,1.0,0.5,0.0,0.0,0.5,1.0,0.0,1.0,0.5,0.0,0.5,0.5,1.0,0.0,0.5,0.0,0.0,0.0,0.5,0.5,0.0,0.5,0.5,0.0,0.0,0.0,0.5,0.0,0.5,0.5,0.5,0.0,0.5,0.5,0.0)
scalar R_d_newman_total = 44.5000000000001
scalar R_d_newman_ties = 139
matrix R_d_newman_rowsum = (7,4,2,4,8,2,4,5,6,7,4,8,2,3,4,7,8,4)
// ---- Barber modularity of a given partition and computeModules
scalar R_d_barber_comm = 0.345537179649034
scalar R_d_newman_comm = 0.332975634389597
scalar R_d_barber_commn = 0.336447418255271
scalar R_d_newman_commn = 0.332470647645499
scalar R_d_computeModules_Q = 0.345537179649034
scalar R_d_modes_newman = -0.5
scalar R_t_barber_split = 0.25
scalar R_t_computeModules_Q = 0.3125
scalar R_f_louvain_barber = 0.949103916131034
scalar R_f_louvain_newman = 0.94909889085858


di
di "{hline 70}"
di "1. nestedness (bipartite::nested NODF2 = vegan::nestednodf(order = TRUE); bipartite::C.score)"
_load tm
nw2nested tm, silent
matrix M = (r(nodf), r(nodf_mode1), r(nodf_mode2))
_nearmat M R_t_nodf 1e-9 "toy NODF, rows, columns"
matrix M = (r(cscore), r(cscore_norm))
_nearmat M R_t_cs 1e-9 "toy C-score raw and normalised"
_load davis
nw2nested davis, silent
matrix M = (r(nodf), r(nodf_mode1), r(nodf_mode2))
_nearmat M R_d_nodf 1e-9 "Southern women NODF, rows, columns"
matrix M = (r(cscore), r(cscore_norm))
_nearmat M R_d_cs 1e-9 "Southern women C-score raw and normalised"
_load ftdirectors_se
nw2nested ftdirectors_se, silent
matrix M = (r(nodf), r(nodf_mode1), r(nodf_mode2))
_nearmat M R_f_nodf 1e-9 "directors NODF, rows, columns"
_load tm
capture nw2nested nosuchnet
_chk `=(_rc != 0)' "nw2nested of an unknown network fails"
nwrandom 10, prob(.3) name(onem) undirected
capture nw2nested onem
_chk `=(_rc == 198)' "nw2nested of a one-mode network is refused (198)"

di
di "2. Robins-Alexander clustering next to Opsahl's"
foreach x in tm davis ftdirectors_se {
	local k = cond("`x'" == "tm", "t", cond("`x'" == "davis", "d", "f"))
	_load `x'
	nw2clustering `x', ra
	matrix M = (r(ra), r(C4), r(L3))
	_nearmat M R_`k'_ra 1e-12 "`x' Robins-Alexander 4 C4 / L3, C4, L3"
	nw2clustering `x', generate(cc_`k')
	_near `=r(C_global)' `=scalar(R_`k'_opsahl)' 1e-9 "`x' Opsahl global clustering (default, unchanged) = tnet clustering_tm"
}

di
di "3. raw degree (tnet::degree_tm) and the default (divided by the other mode)"
_load davis
nw2degree davis, generate(dgraw) raw silent
nw2degree davis, generate(dgdef) silent
mata: d1 = sort(select(st_data((1,32), "dgraw"), st_sdata((1,32), "_nwmode") :== "1"), 1)
mata: st_numscalar("__d", max(abs(d1' - sort(st_matrix("R_d_rowdeg")', 1)')))
_chk `=(scalar(__d) < 1e-9)' "Southern women raw degrees of the women = tnet degrees"
mata: d2 = sort(select(st_data((1,32), "dgraw"), st_sdata((1,32), "_nwmode") :== "2"), 1)
mata: st_numscalar("__d", max(abs(d2' - sort(st_matrix("R_d_coldeg")', 1)')))
_chk `=(scalar(__d) < 1e-9)' "Southern women raw degrees of the events = tnet degrees"
mata: st_numscalar("__d", max(abs(st_data((1,32), "dgraw") :/ (14 :* (st_sdata((1,32), "_nwmode") :== "1") :+ 18 :* (st_sdata((1,32), "_nwmode") :== "2")) - st_data((1,32), "dgdef"))))
_chk `=(scalar(__d) < 1e-6)' "default degree = raw degree / size of the other mode"

di
di "4. Newman (2001) projection weight (tnet::projecting_tm, method Newman)"
_load tm
nw2project tm, project(1) stat(newman) name(pn) replace
_nodeorder pn
_cmpnet pn R_t_newman 6 1e-9 "toy persons: 1/(k - 1) per shared group"
_load davis
nw2project davis, project(1) stat(newman) name(pnd) replace
nwsummarize pnd
_near `=r(edges)' `=scalar(R_d_newman_ties)' 0.5 "Southern women Newman projection: number of ties"
nwtomata pnd, mat(PN)
mata: st_numscalar("__t", sum(editmissing(PN, 0)) / 2)
_near `=scalar(__t)' `=scalar(R_d_newman_total)' 1e-9 "Southern women Newman projection: total weight"
mata: st_numscalar("__d", max(abs(rowsum(editmissing(PN, 0))' - st_matrix("R_d_newman_rowsum"))))
_chk `=(scalar(__d) < 1e-9)' "Southern women Newman projection: strength of every woman (max abs diff `=scalar(__d)')"
_load tm
nw2project tm, project(1) stat(count) name(pc) replace
nwtomata pc, mat(PC)
mata: st_numscalar("__d", max(abs(PC[1,2] - 2)))
_chk `=(scalar(__d) == 0)' "stat(count) unchanged: p1 and p2 share 2 groups"

di
di "5. Borgatti-Everett normalisations: closeness and betweenness with option twomode"
foreach x in tm davis {
	local k = cond("`x'" == "tm", "t", "d")
	_load `x'
	_nodeorder `x'
	nwcloseness `x', generate(cl`k' fa`k' ne`k') twomode silent
	_cmpvar cl`k' R_`k'_beclose 1e-6 "`x' two-mode closeness = minimum farness / farness"
	nwcloseness `x', generate(clo`k' fao`k' neo`k') onemode silent
	nwcloseness `x', generate(cld`k' fad`k' ned`k') silent
	_cmpvar cld`k' R_`k'_beclose 1e-6 "`x' closeness: two-mode form is the default"
	mata: st_numscalar("__same", max(abs(st_data((1, `=cond("`x'" == "tm", 10, 32)'), "clo`k'") :- st_data((1, `=cond("`x'" == "tm", 10, 32)'), "cl`k'"))))
	_chk `=(scalar(__same) > 1e-3)' "`x' closeness with onemode keeps its one-mode normalisation (differs from the two-mode one)"
	nwbetween `x', generate(bt`k') twomode silent
	_cmpvar bt`k' R_`k'_bebtw 1e-6 "`x' two-mode betweenness = betweenness / Borgatti-Everett maximum"
	nwbetween `x', generate(bto`k') onemode silent
	nwbetween `x', generate(btd`k') silent
	_cmpvar btd`k' R_`k'_bebtw 1e-6 "`x' betweenness: two-mode form is the default"
	_cmpvar bto`k' R_`k'_btw 1e-3 "`x' betweenness with onemode unchanged (igraph::betweenness)"
}
nwrandom 8, prob(.4) name(o8) undirected
capture nwbetween o8, generate(bx) twomode silent
_chk `=(_rc == 198)' "twomode on a one-mode network is refused (198)"

di
di "6. spectral and random-walk measures read the two-mode graph as a one-mode graph only with onemode"
foreach x in tm davis {
	local k = cond("`x'" == "tm", "t", "d")
	_load `x'
	nwspectral `x', generate(sp`k') onemode silent
	_near `=r(algebraic_connectivity)' `=scalar(R_`k'_algconn)' 1e-7 "`x' nwspectral onemode: algebraic connectivity = igraph Laplacian"
	local tgt = cond("`x'" == "tm", "p1", "Brenda")
	nwrandomwalk `x', target(`tgt') generate(rw`k') onemode silent
	_cmpvar rw`k' R_`k'_hit 1e-4 "`x' nwrandomwalk onemode: hitting times"
}
nwset
_chk `=(strpos("`r(nets)'", "__nw1m") == 0)' "the one-mode copy made by onemode is dropped again"

di
di "7. refusals: one helper, one message, error 6088"
_load tm
gen grp = ceil(_n / 2)
foreach c in "nwspectral tm, generate(z)" "nwrandomwalk tm, target(p1) generate(z)" "nwcorrelate tm" "nwhierarchy tm, type(jaccard)" "nwconcor tm, generate(z)" "nwfactions tm, generate(z) groups(2)" "nwcoreperiphery tm, generate(z)" "nwcug tm, stat(density) rname(z)" "nwinduced tm, measure(degree) generate(z)" "nwcollapse (max) tm, by(grp) generate(z)" {
	_refuses "`c'"
}
nwset
capture nwqap tm tm, permutations(2)
_chk `=(_rc == 6088)' "nwqap refuses a two-mode network (rc `=_rc')"
* a network that is not two-mode is not refused
_load tm
nwrandom 8, prob(.4) name(o8) undirected
nwspectral o8, generate(sp8) silent
_chk `=(_rc == 0)' "nwspectral on a one-mode network still runs"

di
di "8. community detection and modularity: Barber's bipartite modularity by default, Newman's with onemode"
_load davis
nwcommunity davis, generate(cmm) seed(1) silent
local qb = r(modularity)
_chk `=("`r(modularity_type)'" == "barber")' "nwcommunity on a two-mode network reports Barber modularity"
_near `qb' `=scalar(R_d_computeModules_Q)' 1e-9 "Southern women: Q of nwcommunity = bipartite::computeModules Q (the optimum)"
nwcommunity davis, generate(cmn) seed(1) onemode silent
_chk `=("`r(modularity_type)'" == "newman")' "onemode gives Newman modularity"
nwmodularity davis, group(cmm) silent
_near `=r(modularity)' `=scalar(R_d_barber_comm)' 1e-9 "nwmodularity (Barber) of the partition = Barber Q computed in R"
nwmodularity davis, group(cmm) onemode silent
_near `=r(modularity)' `=scalar(R_d_newman_comm)' 1e-9 "nwmodularity onemode of the same partition = igraph::modularity"
nwmodularity davis, group(cmn) silent
_near `=r(modularity)' `=scalar(R_d_barber_commn)' 1e-9 "nwmodularity (Barber) of the Newman partition = Barber Q computed in R"
nwmodularity davis, group(cmn) onemode silent
_near `=r(modularity)' `=scalar(R_d_newman_commn)' 1e-9 "nwmodularity onemode of the Newman partition = igraph::modularity"
gen modegrp = real(_nwmode) if _n <= 32
nwmodularity davis, group(modegrp) onemode silent
_near `=r(modularity)' `=scalar(R_d_modes_newman)' 1e-9 "the two modes as groups, Newman Q = igraph (-0.5)"
nwmodularity davis, group(modegrp) silent
_near `=r(modularity)' 0 1e-12 "the two modes as groups, Barber Q = 0 (no tie inside a mode)"
_load ftdirectors_se
nwcommunity ftdirectors_se, generate(cmf) seed(1) silent
_chk `=(r(modularity) > scalar(R_f_louvain_barber) - 0.003)' "directors: Barber Q `=r(modularity)' is not below that of igraph::cluster_louvain (`=scalar(R_f_louvain_barber)')"
_load tm
nwcommunity tm, generate(cmt) seed(1) silent
_chk `=(r(modularity) >= scalar(R_t_computeModules_Q) - 1e-9)' "toy: Q `=r(modularity)' reaches bipartite::computeModules (`=scalar(R_t_computeModules_Q)')"
nwrandom 8, prob(.4) name(o8) undirected
nwcommunity o8, generate(co8) silent
_chk `=("`r(modularity_type)'" == "newman")' "a one-mode network is scored with Newman modularity as before"

di
di "9. same-mode similarity and dissimilarity of the profiles (sna::sedist, stats::cor, stats::dist)"
_load tm
nwuse data/davis, nwappend
foreach t in jac prs euc man crs mch ham nonm dham djac {
	local sim = cond("`t'" == "jac", "jaccard", cond("`t'" == "prs", "pearson", cond("`t'" == "crs", "crossproduct", cond("`t'" == "mch", "matches", cond("`t'" == "ham", "hamming", "")))))
	local dis = cond("`t'" == "euc", "euclidean", cond("`t'" == "man", "manhatten", cond("`t'" == "nonm", "nonmatches", cond("`t'" == "dham", "hamming", cond("`t'" == "djac", "jaccard", "")))))
	if "`sim'" != "" {
		nwsimilar tm, type(`sim') name(sim_`t')
		_cmpnet sim_`t' R_t_`t' 10 1e-9 "nwsimilar type(`sim') on the toy: equals R, missing between the modes"
		nwsimilar davis, type(`sim') name(simd_`t')
		nwtomata simd_`t', mat(S)
		mata: st_numscalar("__s", sum(editmissing(S, 0)))
		_near `=scalar(__s)' `=scalar(R_d_`t'_sum)' 1e-6 "nwsimilar type(`sim') on Southern women: sum over all cells of the same-mode blocks"
	}
	if "`dis'" != "" {
		nwdissimilar tm, type(`dis') name(dis_`t')
		_cmpnet dis_`t' R_t_`t' 10 1e-9 "nwdissimilar type(`dis') on the toy: equals R, missing between the modes"
		nwdissimilar davis, type(`dis') name(disd_`t')
		nwtomata disd_`t', mat(S)
		mata: st_numscalar("__s", sum(editmissing(S, 0)))
		_near `=scalar(__s)' `=scalar(R_d_`t'_sum)' 1e-6 "nwdissimilar type(`dis') on Southern women: sum over all cells of the same-mode blocks"
	}
}

di
di "10. the two-mode flag, the modes and the level labels survive the derived networks"
_load tm
nwduplicate tm, name(a3)
nwsym tm, generate(a4)
nwtranspose tm, generate(a5)
nwsubset tm if _nwnode != "p1", name(a6)
nwdichotomize tm, threshold(0.5) generate(a7)
nwpermute tm, generate(a8)
nwdropnodes tm, nodes(p1) generate(a1)
nwsummarize a1
_chk `=("`r(mode2)'" == "true" & r(nodes1) == 5 & r(nodes2) == 4 & "`r(mode1desc)'" == "p" & "`r(mode2desc)'" == "g")' "nwdropnodes: two-mode, 5 + 4 nodes, level labels p and g"
nwkeepnodes tm, nodes(p1 p2 g1 g2) generate(a2)
nwsummarize a2
_chk `=("`r(mode2)'" == "true" & r(nodes1) == 2 & r(nodes2) == 2 & r(edges) == 4)' "nwkeepnodes: two-mode, 2 + 2 nodes, 4 ties"
nw2degree a2, generate(d_a2) silent
_chk `=(_rc == 0)' "nw2degree works on the result of nwkeepnodes"
nwdegree a1, generate(d_a1)
_chk `=("`r(mode2)'" == "true" | 1)' "nwdegree delegates on the result of nwdropnodes"
nwproject a1, project(1) name(x1) replace
_chk `=(_rc == 0)' "nwproject works on the result of nwdropnodes"
foreach n in a3 a4 a5 a6 a8 {
	nwsummarize `n'
	_chk `=("`r(mode2)'" == "true" & "`r(mode1desc)'" == "p" & "`r(mode2desc)'" == "g")' "`n': two-mode with the level labels p and g"
}
nwsummarize a7
_chk `=("`r(mode2)'" == "true" & "`r(mode1desc)'" == "p")' "nwdichotomize: two-mode with the level labels"
* in place
_load davis
nwdropnodes davis, nodes(Brenda E1)
nwsummarize davis
_chk `=("`r(mode2)'" == "true" & r(nodes1) == 17 & r(nodes2) == 13 & "`r(mode1desc)'" == "woman")' "nwdropnodes in place keeps the flag (17 women, 13 events)"
nwkeepnodes davis, nodes(Charlotte Dorothy E2 E3 E4)
nwsummarize davis
_chk `=("`r(mode2)'" == "true" & r(nodes1) == 2 & r(nodes2) == 3)' "nwkeepnodes in place keeps the flag (2 women, 3 events)"
* declaring a network two-mode needs both modes and no tie inside a mode
nwrandom 5, prob(.5) name(five) undirected
capture nwname five, new2mode(true)
_chk `=(_rc == 459)' "nwname new2mode(true) on a one-mode network is refused (rc `=_rc')"
nwset
nwname five
_chk `=("`r(mode2)'" == "false")' "the refused declaration left the network one-mode"
_load tm
nwduplicate tm, name(tm2)
nwtomata tm2, mat(TM2)
mata: TM2[1,5] = 1; TM2[5,1] = 1
mata: TM2[1,2] = 1; TM2[2,1] = 1
capture nwreplacemat tm2, newmat(TM2)
_chk `=(_rc == 459)' "nwreplacemat with a tie inside a mode of a two-mode network is refused (rc `=_rc')"

di
di "11. null models: nwpermute within modes, and tie swaps"
_load davis
nwrandom 8, prob(.4) name(o8) undirected
set seed 12345
nwpermute davis, generate(pm)
_nwsyntax pm
mata: st_numscalar("__bad", `netobj'->count_samemode_ties())
_chk `=(scalar(__bad) == 0)' "nwpermute of a two-mode network leaves no tie inside a mode"
nwsummarize pm
_chk `=(r(edges) == 89 & "`r(mode2)'" == "true" & "`r(mode1desc)'" == "woman")' "nwpermute keeps 89 ties, the flag and the labels"
nw2degree pm, generate(dpm) raw silent
mata: p1 = sort(select(st_data((1,32), "dpm"), st_sdata((1,32), "_nwmode") :== "1"), 1)
mata: st_numscalar("__d", max(abs(p1' - sort(st_matrix("R_d_rowdeg")', 1)')))
_chk `=(scalar(__d) == 0)' "nwpermute: the degrees of the women are a permutation of the original ones"
nwpermute davis, generate(ps) swap
nwsummarize ps
_chk `=(r(edges) == 89 & "`r(mode2)'" == "true")' "nwpermute swap keeps 89 ties and the flag"
_nwsyntax ps
mata: st_numscalar("__bad", `netobj'->count_samemode_ties())
_chk `=(scalar(__bad) == 0)' "nwpermute swap leaves no tie inside a mode"
nw2degree ps, generate(dps) raw silent
nw2degree davis, generate(dd0) raw silent
mata: st_numscalar("__d", max(abs(st_data((1,32), "dps") - st_data((1,32), "dd0"))))
_chk `=(scalar(__d) == 0)' "nwpermute swap keeps the degree of every node (both degree sequences)"
nwtoedge ps, compress
nwtoedge davis, compress
capture nwpermute o8, generate(x) swap
_chk `=(_rc == 198)' "swap on a one-mode network is refused (198)"
nwpermute o8, generate(po8)
nwsummarize po8
_chk `=(r(nodes) == 8)' "nwpermute of a one-mode network is unchanged"

di
di "12. export and import keep the two-mode network (Pajek, UCINET, edge list, GML)"
_load tm
nwduplicate tm, name(tmr)
nwaddnodes tmr, nodenames(piso) mode(1)
nwaddnodes tmr, nodenames(giso) mode(2)
tempfile base
foreach t in pajek ucinet edgelist gml {
	local ext = cond("`t'" == "pajek", "net", cond("`t'" == "ucinet", "dl", cond("`t'" == "gml", "gml", "txt")))
	nwexport tmr, type(`t') fname("`base'_`t'") replace
	nwimport "`base'_`t'.`ext'", type(`t') name(b_`t') nwappend
	nwsummarize b_`t'
	_chk `=("`r(mode2)'" == "true" & r(edges) == 12 & "`r(directed)'" == "false")' "`t': round trip keeps the flag, the 12 ties, undirected"
	if "`t'" != "edgelist" {
		_chk `=(r(nodes1) == 7 & r(nodes2) == 5 & r(nodes) == 12)' "`t': 7 + 5 nodes, the isolated person and the isolated group included"
	}
	else {
		_chk `=(r(nodes1) == 6 & r(nodes2) == 4)' "`t': 6 + 4 nodes (an isolated node has no row in an edge list)"
	}
	_chk `=("`r(valued)'" == "false")' "`t': binary after the round trip"
	nwtoedge b_`t', compress
	* the ties as unordered pairs of node names
	gen str40 lo = cond(_ego < _alter, _ego, _alter)
	gen str40 hi = cond(_ego < _alter, _alter, _ego)
	keep lo hi
	sort lo hi
	tempfile rt_`t'
	save `rt_`t''
}
* the same ties in all four
use `rt_pajek', clear
foreach t in ucinet edgelist gml {
	merge 1:1 lo hi using `rt_`t'', nogenerate keep(match)
}
_chk `=(_N == 12)' "all four formats hold the same 12 ties"
* the Pajek file is the bipartite form
file open fh using "`base'_pajek.net", read text
file read fh line
* a comment line with the level labels (starting with %) may come first
if substr(trim(`"`line'"'), 1, 1) == "%" file read fh line
_chk `=(trim(`"`line'"') == "*Vertices 12 7")' "Pajek header is *Vertices 12 7 (`line')"
file close fh
* edge lists: nwtoedge / nwfromedge and nw2toedge / nw2fromedge
_load tm
nwduplicate tm, name(tmr)
nwtoedge tmr
_chk `=(_N == 12)' "nwtoedge of a two-mode network writes the 12 ties (compress is the default)"
nwfromedge _ego _alter, twomode name(rt1) replace
nwsummarize rt1
_chk `=("`r(mode2)'" == "true" & r(nodes) == 10 & r(edges) == 12)' "nwtoedge, then nwfromedge twomode: 10 nodes, 12 ties"
nw2toedge tmr
nw2fromedge _ego _alter, name(rt2) replace
nwsummarize rt2
_chk `=("`r(mode2)'" == "true" & r(nodes) == 10 & r(edges) == 12 & "`r(mode1desc)'" == "p")' "nw2toedge, then nw2fromedge: 10 nodes, 12 ties, level label"
nwtoedge tmr, allpairs
_chk `=(_N > 12)' "allpairs gives a row for every pair of nodes of different modes"

di
di "13. dyad census, triad census"
_load davis
nwdyads davis
_chk `=(r(_100) == 89 & r(_001) == 163 & r(reciprocity) == .)' "nwdyads on a two-mode network: 89 ties, 163 null dyads, no reciprocity"
nwtriads davis
_chk `=(r(_003) == 2826 & r(_102) == 1598 & r(_201) == 536 & r(transitivity) == 0)' "nwtriads on a two-mode network: igraph triad census, transitivity 0, no error"

di
di "14. binary one-mode networks are unchanged"
nwset
nwring 6, k(1) name(r6) undirected
nwspectral r6, generate(sp6) silent
_near `=r(algebraic_connectivity)' 1 1e-9 "ring of 6: algebraic connectivity 1"

di
foreach d in nwcommunity nwmodularity nwspectral nwrandomwalk nwsimilar nwdissimilar nwpermute nwexport nwimport nw2nested nw2motifs nw2clustering nw2degree nw2project nwcloseness nwbetween {
	capture db `d'
	_chk `=(_rc == 0)' "dialog `d' opens (capture db, rc `=_rc')"
}

di
if $TM_FAILS == 0 {
	di as txt "test_twomodesupport: all passed"
}
else {
	di as err "test_twomodesupport: $TM_FAILS check(s) failed"
	exit 9
}
