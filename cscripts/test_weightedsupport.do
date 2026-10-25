* Valued networks (weighted support): independent checks against R (igraph 2.3.2, tnet 3.0.16, base R).
* Expected values were computed once with Rscript on the five test networks below and are fixed in this file:
*   N1  undirected, 8 nodes, connected, values 0.5 ... 5
*   N2  directed, 9 nodes: node 7 has no in-ties, node 8 no out-ties (dangling), node 9 is an isolate
*   N3  undirected, 7 nodes, connected, shares in (0,1]
*   N5  N3 plus an isolate (8 nodes)
*   B   two-mode 4 x 5 with values 1 ... 5
* Run from the repository root.  Prints "test_weightedsupport: all passed" or the failing checks and exits with an error.
clear all
set more off
capture program drop _chk
program _chk
	args ok label
	if `ok' {
		di "  ok:   `label'"
	}
	else {
		di as err "  FAIL: `label'"
		global WS_FAILS = $WS_FAILS + 1
	}
end
global WS_FAILS 0

* variable (first rows) against an expected 1 x n matrix, absolute tolerance
capture program drop _cmpvar
program _cmpvar
	args var exp tol label
	mata: st_numscalar("__d", max(abs(st_data((1, cols(st_matrix("`exp'"))), "`var'") - st_matrix("`exp'")')))
	_chk `=(scalar(__d) < `tol')' "`label' (max abs diff `=scalar(__d)')"
end

* n x n network (diagonal ignored, missing = unreachable) against an expected matrix, -1 = unreachable
capture program drop _cmpnet
program _cmpnet
	args net exp tol label
	_nwsyntax `net', max(1)
	mata: A = *`netobj'->get_matrix(); B = editvalue(st_matrix("`exp'"), -1, .)
	mata: _diag(A, 0); _diag(B, 0)
	mata: st_numscalar("__d", max(editmissing(abs(A - B), 0)))
	mata: st_numscalar("__m", sum((A :== .) :!= (B :== .)))
	_chk `=(scalar(__d) < `tol' & scalar(__m) == 0)' "`label' (max abs diff `=scalar(__d)', pattern of unreachable pairs differs in `=scalar(__m)')"
	mata: mata drop A B
end

capture program drop _countnote
program _countnote, rclass
	args cmd
	tempfile lg
	qui log using "`lg'", text replace name(wsnote)
	capture noisily `cmd'
	local rc = _rc
	qui log close wsnote
	local found 0
	file open fh using "`lg'", read text
	file read fh line
	while r(eof) == 0 {
		if strpos(`"`line'"', "tie values are ignored") local ++found
		file read fh line
	}
	file close fh
	return scalar found = `found'
	return scalar rc = `rc'
end

* ---- the test networks and the expected numbers (R)

matrix R_N1_mat = (0,3,1,0,0,0,0,0\3,0,2,4,0,0,0,0\1,2,0,0,1.5,0.5,0,0\0,4,0,0,2,1,0,0\0,0,1.5,2,0,0,3,0\0,0,0.5,1,0,0,5,2.5\0,0,0,0,3,5,0,1\0,0,0,0,0,2.5,1,0)
matrix R_N1_str = (4,9,5,7,6.5,9,9,3.5)
matrix R_N1_deg = (2,3,4,3,3,4,3,2)
matrix R_N1_btw = (0,7,0,8,6,6,4,0)
matrix R_N1_btw_bin = (0,1.33333333333333,6.33333333333333,2.33333333333333,2.33333333333333,6.33333333333333,1.33333333333333,0)
matrix R_N1_pr = (0.0836491474130859,0.169081588965842,0.0999570423888074,0.129746776924894,0.121331448604747,0.162938854354488,0.16087931031776,0.0724158310303758)
matrix R_N1_pr_bin = (0.0887445104243306,0.125879973786732,0.161545966359639,0.123829549429299,0.123829549429299,0.161545966359639,0.125879973786732,0.0887445104243306)
matrix R_N1_dist1 = (0,0.333333333333333,0.833333333333333,0.583333333333333,1.08333333333333,1.58333333333333,1.41666666666667,1.98333333333333\0.333333333333333,0,0.5,0.25,0.75,1.25,1.08333333333333,1.65\0.833333333333333,0.5,0,0.75,0.666666666666667,1.2,1,1.6\0.583333333333333,0.25,0.75,0,0.5,1,0.833333333333333,1.4\1.08333333333333,0.75,0.666666666666667,0.5,0,0.533333333333333,0.333333333333333,0.933333333333333\1.58333333333333,1.25,1.2,1,0.533333333333333,0,0.2,0.4\1.41666666666667,1.08333333333333,1,0.833333333333333,0.333333333333333,0.2,0,0.6\1.98333333333333,1.65,1.6,1.4,0.933333333333333,0.4,0.6,0)
matrix R_N1_distm1 = (0,3,1,2.5,2.5,1.5,5,4\3,0,2,3.5,3.5,2.5,6,5\1,2,0,1.5,1.5,0.5,4,3\2.5,3.5,1.5,0,2,1,4.5,3.5\2.5,3.5,1.5,2,0,2,3,4\1.5,2.5,0.5,1,2,0,3.5,2.5\5,6,4,4.5,3,3.5,0,1\4,5,3,3.5,4,2.5,1,0)
matrix R_N2_mat = (0,2,0,0,1.5,0,0,0,0\0,0,4,0,0,0,0,3,0\1,0,0,3,0,0,0,0,0\0,2.5,0,0,2,0,0,0,0\0,0.5,0,0,0,1,0,0,0\0,0,0,5,0,0,0,1,0\2,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0\0,0,0,0,0,0,0,0,0)
matrix R_N2_str_out = (3.5,7,4,4.5,1.5,6,2,0,0)
matrix R_N2_str_in = (3,5,4,8,3.5,1,0,4,0)
matrix R_N2_deg_out = (2,2,2,2,2,2,1,0,0)
matrix R_N2_deg_in = (2,3,1,2,2,1,0,2,0)
matrix R_N2_btw = (6,16,9,15,5,5,0,0,0)
matrix R_N2_btw_bin = (9,13.5,8,7,6,2.5,0,0,0)
matrix R_N2_pr = (0.0831082428892717,0.194934660770298,0.125222283391867,0.184368539357327,0.13046521658936,0.104470023275502,0.0305397338748649,0.116351565976646,0.0305397338748649)
matrix R_N2_pr_bin = (0.11374035059853,0.193066532234301,0.116720400689121,0.123478852434209,0.135485285778457,0.0922483709453869,0.0346671244895428,0.15592595834091,0.0346671244895428)
matrix R_N2_dist1 = (0,0.5,0.75,1.08333333333333,0.666666666666667,1.66666666666667,-1,0.833333333333333,-1\1.25,0,0.25,0.583333333333333,1.08333333333333,2.08333333333333,-1,0.333333333333333,-1\1,0.733333333333333,0,0.333333333333333,0.833333333333333,1.83333333333333,-1,1.06666666666667,-1\1.65,0.4,0.65,0,0.5,1.5,-1,0.733333333333333,-1\2.85,1.6,1.85,1.2,0,1,-1,1.93333333333333,-1\1.85,0.6,0.85,0.2,0.7,0,-1,0.933333333333333,-1\0.5,1,1.25,1.58333333333333,1.16666666666667,2.16666666666667,0,1.33333333333333,-1\-1,-1,-1,-1,-1,-1,-1,0,-1\-1,-1,-1,-1,-1,-1,-1,-1,0)
matrix R_N2_distm1 = (0,2,6,7.5,1.5,2.5,-1,3.5,-1\5,0,4,7,6.5,7.5,-1,3,-1\1,3,0,3,2.5,3.5,-1,4.5,-1\7.5,2.5,6.5,0,2,3,-1,4,-1\5.5,0.5,4.5,6,0,1,-1,2,-1\12.5,7.5,11.5,5,7,0,-1,1,-1\2,4,8,9.5,3.5,4.5,0,5.5,-1\-1,-1,-1,-1,-1,-1,-1,0,-1\-1,-1,-1,-1,-1,-1,-1,-1,0)
matrix R_N3_mat = (0,0.2,0.5,0,0,0,0\0.2,0,1,0,0,0,0.1\0.5,1,0,0.75,0,0,0\0,0,0.75,0,0.3,0.9,0\0,0,0,0.3,0,0.6,0\0,0,0,0.9,0.6,0,0.4\0,0.1,0,0,0,0.4,0)
matrix R_N3_str = (0.7,1.3,2.25,1.95,0.9,1.9,0.5)
matrix R_N3_deg = (2,3,3,3,2,3,2)
matrix R_N3_btw = (0,0,9,9,0,9,0)
matrix R_N3_btw_bin = (0,2.5,4,4,0,2.5,2)
matrix R_N3_pr = (0.0815784069202622,0.136936430354386,0.223638161452748,0.193147835420827,0.100028784776216,0.198726660826178,0.0659437202493828)
matrix R_N3_pr_bin = (0.114393919211088,0.165101657297787,0.1630113348758,0.1630113348758,0.114393919211088,0.165101657297787,0.114986177230651)
matrix R_N3_dist1 = (0,3,2,3.33333333333333,6.11111111111111,4.44444444444444,6.94444444444444\3,0,1,2.33333333333333,5.11111111111111,3.44444444444444,5.94444444444444\2,1,0,1.33333333333333,4.11111111111111,2.44444444444444,4.94444444444444\3.33333333333333,2.33333333333333,1.33333333333333,0,2.77777777777778,1.11111111111111,3.61111111111111\6.11111111111111,5.11111111111111,4.11111111111111,2.77777777777778,0,1.66666666666667,4.16666666666667\4.44444444444444,3.44444444444444,2.44444444444444,1.11111111111111,1.66666666666667,0,2.5\6.94444444444444,5.94444444444444,4.94444444444444,3.61111111111111,4.16666666666667,2.5,0)
matrix R_N3_distm1 = (0,0.2,0.5,1.25,1.3,0.7,0.3\0.2,0,0.7,1.4,1.1,0.5,0.1\0.5,0.7,0,0.75,1.05,1.2,0.8\1.25,1.4,0.75,0,0.3,0.9,1.3\1.3,1.1,1.05,0.3,0,0.6,1\0.7,0.5,1.2,0.9,0.6,0,0.4\0.3,0.1,0.8,1.3,1,0.4,0)
matrix R_N5_mat = (0,0.2,0.5,0,0,0,0,0\0.2,0,1,0,0,0,0.1,0\0.5,1,0,0.75,0,0,0,0\0,0,0.75,0,0.3,0.9,0,0\0,0,0,0.3,0,0.6,0,0\0,0,0,0.9,0.6,0,0.4,0\0,0.1,0,0,0,0.4,0,0\0,0,0,0,0,0,0,0)
matrix R_N5_str = (0.7,1.3,2.25,1.95,0.9,1.9,0.5,0)
matrix R_N5_deg = (2,3,3,3,2,3,2,0)
matrix R_N5_btw = (0,0,9,9,0,9,0,0)
matrix R_N5_btw_bin = (0,2.5,4,4,0,2.5,2,0)
matrix R_N5_pr = (0.0798669718100469,0.134063638109189,0.218946451771921,0.189095782929481,0.0979302788018903,0.194557570039615,0.0645602855588363,0.020979020979021)
matrix R_N5_pr_bin = (0.111994046780086,0.161637986165665,0.159591516661622,0.159591516661622,0.111994046780086,0.161637986165665,0.112573879806231,0.020979020979021)
matrix R_N5_dist1 = (0,3,2,3.33333333333333,6.11111111111111,4.44444444444444,6.94444444444444,-1\3,0,1,2.33333333333333,5.11111111111111,3.44444444444444,5.94444444444444,-1\2,1,0,1.33333333333333,4.11111111111111,2.44444444444444,4.94444444444444,-1\3.33333333333333,2.33333333333333,1.33333333333333,0,2.77777777777778,1.11111111111111,3.61111111111111,-1\6.11111111111111,5.11111111111111,4.11111111111111,2.77777777777778,0,1.66666666666667,4.16666666666667,-1\4.44444444444444,3.44444444444444,2.44444444444444,1.11111111111111,1.66666666666667,0,2.5,-1\6.94444444444444,5.94444444444444,4.94444444444444,3.61111111111111,4.16666666666667,2.5,0,-1\-1,-1,-1,-1,-1,-1,-1,0)
matrix R_N5_distm1 = (0,0.2,0.5,1.25,1.3,0.7,0.3,-1\0.2,0,0.7,1.4,1.1,0.5,0.1,-1\0.5,0.7,0,0.75,1.05,1.2,0.8,-1\1.25,1.4,0.75,0,0.3,0.9,1.3,-1\1.3,1.1,1.05,0.3,0,0.6,1,-1\0.7,0.5,1.2,0.9,0.6,0,0.4,-1\0.3,0.1,0.8,1.3,1,0.4,0,-1\-1,-1,-1,-1,-1,-1,-1,0)
matrix R_N1_tnet_a05_out = (2.82842712474619,5.19615242270663,4.47213595499958,4.58257569495584,4.41588043316392,6,5.19615242270663,2.64575131106459)
matrix R_N2_tnet_a05_out = (2.64575131106459,3.74165738677394,2.82842712474619,3,1.73205080756888,3.46410161513775,1.4142135623731,0,0)
matrix R_N2_tnet_a05_in = (2.44948974278318,3.87298334620742,2,4,2.64575131106459,1,0,2.82842712474619,0)
matrix R_N1_clo = (0.895522388059702,1.20343839541547,1.06870229007634,1.3166144200627,1.45833333333333,1.13513513513514,1.28048780487805,0.817120622568093)
matrix R_N1_clo_bin = (0.5,0.538461538461538,0.7,0.636363636363636,0.636363636363636,0.7,0.538461538461538,0.5)
matrix R_N1_evc = (0.294652165058953,0.580813146450862,0.403781149347822,0.634768336165605,0.669311773757988,0.961720886105651,1,0.467372749811314)
matrix R_N1_evc_bin = (0.559997633506193,0.758461263068528,1,0.821663771549163,0.821663771549163,1,0.758461263068527,0.559997633506193)
matrix R_N3_clo = (0.232258064516129,0.288,0.378947368421053,0.413793103448276,0.250580046403712,0.384341637010676,0.213438735177866)
matrix R_N3_clo_bin = (0.5,0.6,0.666666666666667,0.666666666666667,0.5,0.6,0.6)
matrix R_N3_evc = (0.393263236065559,0.681268172606256,1,0.986643364970787,0.473174145107756,0.782578452490643,0.235590805877609)
matrix R_N3_evc_bin = (0.72536424417201,0.915822232021282,1,1,0.72536424417201,0.915822232021282,0.693493049639755)
matrix R_N2s_clo = (1.33333333333333,1.75732217573222,1.54411764705882,1.56716417910448,1.16666666666667,1.23529411764706,0.848484848484849,1.16991643454039)
matrix R_N2s_clo_bin = (0.7,0.777777777777778,0.636363636363636,0.636363636363636,0.7,0.583333333333333,0.4375,0.538461538461538)
matrix R_N2s_evc = (0.386041340214928,0.890180617373696,0.793140457022658,1,0.4209057954009,0.662373971383386,0.0881518397328388,0.380532641080661)
matrix R_N2s_evc_bin = (0.765072047018292,1,0.718274539666357,0.87060849821631,0.880630534051574,0.595759019945362,0.208497108413701,0.434875568491048)
matrix R_N2s_mat = (0,2,1,0,1.5,0,2,0\2,0,4,2.5,0.5,0,0,3\1,4,0,3,0,0,0,0\0,2.5,3,0,2,5,0,0\1.5,0.5,0,2,0,1,0,0\0,0,0,5,1,0,0,1\2,0,0,0,0,0,0,0\0,3,0,0,0,1,0,0)
matrix R_N2_evc_right = (0.586810448044477,0.811956978910455,0.757292258459316,0.746140278984244,0.376867066168643,1,0.314584516918631,0,0)
matrix R_N2_evc_sym = (0.386041340214928,0.890180617373697,0.793140457022658,1,0.4209057954009,0.662373971383385,0.0881518397328388,0.38053264108066,0)
matrix R_N1_ht6 = (13.8138263219164,13.1640020078391,11.7632992641483,11.1269851441265,9.11644398876465,0,4.28598891416488,2.22456826118996)
matrix R_N3_ht1 = (0,12.2943245209799,12.6822701916081,18.6543778801843,21.0053359204463,20.6808149405773,20.0035168566578)
matrix R_N1_ht6_bin = (8.375,8,6.75,5.875,6.625,0,4.25,3.125)
matrix R_N1_path18 = (1,2,4,6,8)
matrix R_N1_path18_cost = (1.98333333333333)
matrix R_N2_path16 = (1,5,6)
matrix R_N2_path16_cost = (1.66666666666667)
matrix R_N1_path18_len = (1,3,6,8)
matrix R_N1_path18_len_cost = (4)
matrix R_B_match_weight = (15)
matrix R_B_match_size = (4)
matrix R_B_mat = (3,0,2,0,1\0,4,1,0,2\5,1,0,2,0\0,0,3,4,1)
matrix R_B_brute = (15)
matrix R_N1_assort_str = (-0.366305377249289)
matrix R_N1_assort_deg = (-0.235294117647057)
matrix R_N1_assort_w = (-0.300628580706515)
matrix R_N3_assort_str = (-0.230545454545456)
matrix R_N3_assort_deg = (-0.499999999999998)
matrix R_N3_assort_w = (-0.314005813808612)
matrix R_N2_alpha_c = (1.37533206032583,1.88330150814567,1.75332060325827,2.10738502164639,1.62777681337815,1.16277768133782,1,1.68126822057748,1)
matrix R_B_str1 = (1.2,1.4,1.6,1.6)
matrix R_B_str2 = (2,1.25,1.5,1.5,1)
matrix R_B_deg1 = (0.6,0.6,0.6,0.6)
matrix R_B_deg2 = (0.5,0.5,0.75,0.5,0.75)

* Create the five networks.  Matrices with values other than 0 and 1 are valued at creation.
nwclear
nwset, mat(R_N1_mat) name(n1) undirected
nwset, mat(R_N2_mat) name(n2) directed
nwset, mat(R_N3_mat) name(n3) undirected
nwset, mat(R_N5_mat) name(n5) undirected
* binary versions (same ties, no values)
mata: st_matrix("S1", st_matrix("R_N1_mat") :> 0)
mata: st_matrix("S2", st_matrix("R_N2_mat") :> 0)
nwset, mat(S1) name(b1) undirected
nwset, mat(S2) name(b2) directed

* ---------------------------------------------------------------- (A) the valued flag is set when a network is created
di as txt _n "(A) valued flag at creation"
capture program drop _isval
program _isval, rclass
	_nwsyntax `0', max(1)
	return local valued "`valued'"
end
_isval n1
_chk `=("`r(valued)'" == "true")' "nwset from a valued matrix is valued"
_isval b1
_chk `=("`r(valued)'" == "false")' "nwset from a 0/1 matrix is binary"
capture program drop _mkedges
program _mkedges
	clear
	set obs 3
	gen str3 e = "n" + string(_n)
	gen str3 a = "n" + string(mod(_n, 3) + 1)
	gen double w = 1
end
preserve
_mkedges
nwfromedge e a w, name(ones) directed
restore
_isval ones
_chk `=("`r(valued)'" == "true")' "nwfromedge with a value variable is valued, also when every value is 1"
preserve
_mkedges
nwfromedge e a, name(nov) directed
restore
_isval nov
_chk `=("`r(valued)'" == "false")' "nwfromedge without a value variable is binary"
preserve
_mkedges
nwfromedge e a w, name(ones_u) directed unvalued
restore
_isval ones_u
_chk `=("`r(valued)'" == "false")' "nwfromedge, unvalued overrides"
preserve
_mkedges
nwfromedge e a, name(nov_v) directed valued
restore
_isval nov_v
_chk `=("`r(valued)'" == "true")' "nwfromedge, valued overrides"
* an all-1 valued network keeps its flag through transformations; a dichotomized network is binary
nwtranspose ones, generate(ones_t)
_isval ones_t
_chk `=("`r(valued)'" == "true")' "nwtranspose keeps the flag"
nwsym ones, generate(ones_s)
_isval ones_s
_chk `=("`r(valued)'" == "true")' "nwsym keeps the flag"
nwduplicate ones, name(ones_d)
_isval ones_d
_chk `=("`r(valued)'" == "true")' "nwduplicate keeps the flag"
nwdichotomize n1, threshold(2) generate(n1_d)
_isval n1_d
_chk `=("`r(valued)'" == "false")' "nwdichotomize gives a binary network"
_isval n1
_chk `=("`r(valued)'" == "true")' "the source of nwdichotomize stays valued"
* nwset, valued / unvalued
nwset, mat(S1) name(b1v) undirected valued
_isval b1v
_chk `=("`r(valued)'" == "true")' "nwset, valued"
nwset, mat(R_N1_mat) name(n1u) undirected unvalued
_isval n1u
_chk `=("`r(valued)'" == "false")' "nwset, unvalued"
* nwsave / nwuse keep the flag, also for all-1 valued and for values in (0,1]
tempfile fsv
qui nwsave "`fsv'.nwdta", replace
nwclear
qui nwuse "`fsv'.nwdta"
_isval ones
local a "`r(valued)'"
_isval b1
local b "`r(valued)'"
_isval n3
local c "`r(valued)'"
_chk `=("`a'" == "true" & "`b'" == "false" & "`c'" == "true")' "nwsave/nwuse round trip keeps the flag (all-1 valued, binary, shares)"
* imports
tempfile fp fg fg0
file open fh using "`fp'.net", write text replace
file write fh "*Vertices 3" _n `"1 "a""' _n `"2 "b""' _n `"3 "c""' _n "*Edges" _n "1 2 1" _n "2 3 1" _n
file close fh
nwimport "`fp'.net", type(pajek) name(pj_w) nwappend
_isval pj_w
_chk `=("`r(valued)'" == "true")' "nwimport pajek with tie values (all 1) is valued"
file open fh using "`fp'0.net", write text replace
file write fh "*Vertices 3" _n `"1 "a""' _n `"2 "b""' _n `"3 "c""' _n "*Edges" _n "1 2" _n "2 3" _n
file close fh
nwimport "`fp'0.net", type(pajek) name(pj_b) nwappend
_isval pj_b
_chk `=("`r(valued)'" == "false")' "nwimport pajek without tie values is binary"
file open fh using "`fg'.gml", write text replace
file write fh "graph [" _n "directed 0" _n "node [ id 1 label " `""a""' " ]" _n "node [ id 2 label " `""b""' " ]" _n "node [ id 3 label " `""c""' " ]" _n
file write fh "edge [ source 1 target 2 value 1 ]" _n "edge [ source 2 target 3 value 1 ]" _n "]" _n
file close fh
nwimport "`fg'.gml", type(gml) name(gm_w) nwappend
_isval gm_w
_chk `=("`r(valued)'" == "true")' "nwimport gml with edge values (all 1) is valued"
file open fh using "`fg0'.gml", write text replace
file write fh "graph [" _n "directed 0" _n "node [ id 1 label " `""a""' " ]" _n "node [ id 2 label " `""b""' " ]" _n "node [ id 3 label " `""c""' " ]" _n
file write fh "edge [ source 1 target 2 ]" _n "edge [ source 2 target 3 ]" _n "]" _n
file close fh
nwimport "`fg0'.gml", type(gml) name(gm_b) nwappend
_isval gm_b
_chk `=("`r(valued)'" == "false")' "nwimport gml without edge values is binary"
nwclear
nwset, mat(R_N1_mat) name(n1) undirected
nwset, mat(R_N2_mat) name(n2) directed
nwset, mat(R_N3_mat) name(n3) undirected
nwset, mat(R_N5_mat) name(n5) undirected
nwset, mat(S1) name(b1) undirected
nwset, mat(S2) name(b2) directed

* ---------------------------------------------------------------- (B) degree and strength
di as txt _n "(B) nwdegree"
nwdegree n1, generate(d1) silent
_cmpvar d1 R_N1_str 1e-12 "nwdegree default on a valued network = igraph::strength"
nwdegree n1, generate(d1b) silent binary
_cmpvar d1b R_N1_deg 1e-12 "nwdegree, binary = igraph::degree"
nwdegree n1, generate(d1c) silent alpha(0)
_cmpvar d1c R_N1_deg 1e-12 "nwdegree, alpha(0) = number of ties"
nwdegree n1, generate(d1d) silent alpha(.5)
_cmpvar d1d R_N1_tnet_a05_out 1e-12 "nwdegree, alpha(.5) = tnet::degree_w"
nwdegree n1, generate(d1e) silent ties(t1e)
_cmpvar d1e R_N1_str 1e-12 "nwdegree with ties(): strength"
_cmpvar t1e R_N1_deg 1e-12 "nwdegree with ties(): number of ties"
nwdegree n2, generate(o2 i2) silent ties(to2 ti2)
_cmpvar o2 R_N2_str_out 1e-12 "nwdegree directed, out-strength"
_cmpvar i2 R_N2_str_in 1e-12 "nwdegree directed, in-strength"
_cmpvar to2 R_N2_deg_out 1e-12 "nwdegree directed, out-ties"
_cmpvar ti2 R_N2_deg_in 1e-12 "nwdegree directed, in-ties"
nwdegree n2, generate(oa2 ia2) silent alpha(.5)
_cmpvar oa2 R_N2_tnet_a05_out 1e-12 "nwdegree directed alpha(.5) out = tnet"
_cmpvar ia2 R_N2_tnet_a05_in 1e-12 "nwdegree directed alpha(.5) in = tnet"
nwdegree n5, generate(d5 iso5) silent isolates replace
_chk `=(iso5[8] == 1 & iso5[1] == 0)' "nwdegree, isolates on a valued network (node 8)"
nwdegree n5, generate(d5s iso5s) silent isolates ties(c5) 
_cmpvar d5s R_N5_str 1e-12 "nwdegree strength with an isolate"
capture nwdegree n1, generate(dx) binary alpha(1)
_chk `=(_rc == 198)' "nwdegree: binary and alpha(1) cannot be combined"
nwdegree b1, generate(db) silent
_cmpvar db R_N1_deg 1e-12 "nwdegree on a binary network = igraph::degree"

di as txt _n "(B2) nw2degree"
preserve
clear
input str3 p str3 g double v
p1 g1 3
p1 g3 2
p1 g5 1
p2 g2 4
p2 g3 1
p2 g5 2
p3 g1 5
p3 g2 1
p3 g4 2
p4 g3 3
p4 g4 4
p4 g5 1
end
nwfromedge p g v, name(tm) twomode
restore
nw2degree tm, generate(t2) silent
mata: st_numscalar("__d", max(abs(sort(st_data((1,9), "t2"), 1) - sort((st_matrix("R_B_str1"), st_matrix("R_B_str2"))', 1))))
_chk `=(scalar(__d) < 1e-12)' "nw2degree default on a valued two-mode network = strength / size of the other mode"
nw2degree tm, generate(t2b) silent binary
mata: st_numscalar("__d", max(abs(sort(st_data((1,9), "t2b"), 1) - sort((st_matrix("R_B_deg1"), st_matrix("R_B_deg2"))', 1))))
_chk `=(scalar(__d) < 1e-6)' "nw2degree, binary = number of ties / size of the other mode"

* ---------------------------------------------------------------- (C) geodesic, closeness
di as txt _n "(C) nwgeodesic, nwcloseness"
qui nwgeodesic n1, name(g1)
_cmpnet g1 R_N1_dist1 1e-12 "nwgeodesic default on a valued network: cost 1/value (igraph::distances, weights 1/w)"
qui nwgeodesic n1, name(g1m) alpha(-1)
_cmpnet g1m R_N1_distm1 1e-12 "nwgeodesic, alpha(-1) = igraph::distances with weights as lengths"
qui nwgeodesic n1, name(g1b) binary
qui nwgeodesic b1, name(g1c)
_nwsyntax g1b
mata: A = *`netobj'->get_matrix(); _diag(A, 0)
_nwsyntax g1c
mata: B = *`netobj'->get_matrix(); _diag(B, 0)
mata: st_numscalar("__d", max(abs(A - B)))
mata: mata drop A B
_chk `=(scalar(__d) == 0)' "nwgeodesic, binary on a valued network = the result on the binary network (hops)"
qui nwgeodesic n2, name(g2) 
_cmpnet g2 R_N2_dist1 1e-12 "nwgeodesic directed, with unreachable pairs and an isolate"
qui nwgeodesic n5, name(g5)
_cmpnet g5 R_N5_dist1 1e-12 "nwgeodesic on shares in (0,1], with an isolate"
nwcloseness n1, generate(c1 f1 nn1) silent
_cmpvar c1 R_N1_clo 1e-6 "nwcloseness default on a valued network = igraph::closeness(weights 1/w)"
nwcloseness n1, generate(c1b f1b nn1b) silent binary
_cmpvar c1b R_N1_clo_bin 1e-6 "nwcloseness, binary = igraph::closeness unweighted"
nwcloseness n3, generate(c3 f3 nn3) silent
_cmpvar c3 R_N3_clo 1e-6 "nwcloseness on shares"
nwsubset n2 if _n <= 8, name(n2c)
nwcloseness n2c, generate(c2 f2 nn2) silent
_cmpvar c2 R_N2s_clo 1e-6 "nwcloseness on a directed valued network (symmetrized)"

* ---------------------------------------------------------------- (D) betweenness
di as txt _n "(D) nwbetween"
nwbetween n1, generate(b1v) silent
_cmpvar b1v R_N1_btw 1e-9 "nwbetween default on a valued network = igraph::betweenness(weights 1/w)"
nwbetween n1, generate(b1w) silent weighted
_cmpvar b1w R_N1_btw 1e-9 "nwbetween, weighted (synonym) gives the same"
nwbetween n1, generate(b1b) silent binary
_cmpvar b1b R_N1_btw_bin 1e-6 "nwbetween, binary = igraph::betweenness unweighted"
nwbetween n3, generate(b3) silent
_cmpvar b3 R_N3_btw 1e-9 "nwbetween on shares (tied shortest paths)"
nwbetween n5, generate(b5) silent
_cmpvar b5 R_N5_btw 1e-9 "nwbetween with an isolate"
nwbetween n2, generate(b2) silent nosym
_cmpvar b2 R_N2_btw 1e-9 "nwbetween directed (nosym), dangling node and isolate"
nwbetween n2, generate(b2b) silent nosym binary
_cmpvar b2b R_N2_btw_bin 1e-6 "nwbetween directed, binary"
nwbetween b1, generate(bb1) silent
_cmpvar bb1 R_N1_btw_bin 1e-6 "nwbetween on a binary network is unchanged"
capture nwbetween n1, generate(bx) binary weighted
_chk `=(_rc == 198)' "nwbetween: binary and weighted cannot be combined"

* ---------------------------------------------------------------- (E) eigenvector centrality
di as txt _n "(E) nwevcent"
foreach nm in n1 n3 {
	local u = upper(substr("`nm'", 1, 1)) + substr("`nm'", 2, .)
	nwevcent `nm', generate(ev_`nm') replace
	mata: st_store((1, 8), "ev_`nm'", st_data((1, 8), "ev_`nm'") :/ max(st_data((1, 8), "ev_`nm'")))
}
mata: st_numscalar("__d", max(abs(st_data((1, 8), "ev_n1") - st_matrix("R_N1_evc")')))
_chk `=(scalar(__d) < 1e-6)' "nwevcent default on a valued network = igraph::eigen_centrality (max 1), diff `=scalar(__d)'"
mata: st_numscalar("__d", max(abs(st_data((1, 7), "ev_n3") - st_matrix("R_N3_evc")')))
_chk `=(scalar(__d) < 1e-6)' "nwevcent on shares, diff `=scalar(__d)'"
nwevcent n1, generate(evb) binary
mata: st_numscalar("__d", max(abs(st_data((1, 8), "evb") :/ max(st_data((1, 8), "evb")) - st_matrix("R_N1_evc_bin")')))
_chk `=(scalar(__d) < 1e-6)' "nwevcent, binary = igraph weights = NA, diff `=scalar(__d)'"
nwevcent n1, generate(evw) weighted
mata: st_numscalar("__d", max(abs(st_data((1, 8), "evw") :/ max(st_data((1, 8), "evw")) - st_matrix("R_N1_evc")')))
_chk `=(scalar(__d) < 1e-6)' "nwevcent, weighted (synonym) gives the same"
nwevcent n2, generate(ev2)
mata: st_numscalar("__d", max(abs(st_data((1, 9), "ev2") :/ max(st_data((1, 9), "ev2")) - st_matrix("R_N2_evc_sym")')))
_chk `=(scalar(__d) < 1e-6)' "nwevcent on a directed valued network (symmetrized, max), isolate included, diff `=scalar(__d)'"
nwevcent b1, generate(evbb)
mata: st_numscalar("__d", max(abs(st_data((1, 8), "evbb") :/ max(st_data((1, 8), "evbb")) - st_matrix("R_N1_evc_bin")')))
_chk `=(scalar(__d) < 1e-6)' "nwevcent on a binary network is unchanged"

* ---------------------------------------------------------------- (F) PageRank and random-walk hitting time
di as txt _n "(F) nwpagerank, nwrandomwalk"
foreach p in 1 2 3 5 {
	nwpagerank n`p', generate(pr`p') silent replace
}
_cmpvar pr1 R_N1_pr 1e-8 "nwpagerank default on a valued network = igraph::page_rank (weights)"
_cmpvar pr2 R_N2_pr 1e-8 "nwpagerank directed, dangling node and isolate"
_cmpvar pr3 R_N3_pr 1e-8 "nwpagerank on shares"
_cmpvar pr5 R_N5_pr 1e-8 "nwpagerank with an isolate"
nwpagerank n1, generate(prb) silent binary
_cmpvar prb R_N1_pr_bin 1e-8 "nwpagerank, binary = igraph::page_rank(weights = NA)"
nwpagerank n2, generate(prb2) silent binary
_cmpvar prb2 R_N2_pr_bin 1e-8 "nwpagerank directed, binary"
nwpagerank b1, generate(prbb) silent
_cmpvar prbb R_N1_pr_bin 1e-8 "nwpagerank on a binary network is unchanged"
* hitting time: the formula (D_s - W) h = s on the nodes other than the target, solved in base R
nwrandomwalk n1, target(n6) generate(h1) silent
_cmpvar h1 R_N1_ht6 1e-9 "nwrandomwalk default on a valued network (steps in proportion to the values)"
nwrandomwalk n1, target(n6) generate(h1b) silent binary
_cmpvar h1b R_N1_ht6_bin 1e-9 "nwrandomwalk, binary (simple random walk)"
nwrandomwalk n3, target(n1) generate(h3) silent
_cmpvar h3 R_N3_ht1 1e-9 "nwrandomwalk on shares"
nwrandomwalk b1, target(n6) generate(h1bb) silent
_cmpvar h1bb R_N1_ht6_bin 1e-9 "nwrandomwalk on a binary network is unchanged"

* ---------------------------------------------------------------- (G) nwpath
di as txt _n "(G) nwpath"
nwpath n1, egoid(1) alterid(8) nopaths
matrix pm = r(paths_matrix)
mata: st_numscalar("__d", max(abs(st_matrix("pm") - st_matrix("R_N1_path18"))))
_chk `=(scalar(__d) == 0 & r(paths) == 1)' "nwpath default on a valued network = igraph::shortest_paths(weights 1/w)"
_chk `=(abs(r(path_cost) - 1.98333333333333) < 1e-12 & r(path_length) == 4)' "nwpath cost 1/value summed (igraph distances) and number of steps"
nwpath n1, egoid(1) alterid(8) nopaths alpha(-1)
matrix pm = r(paths_matrix)
mata: st_numscalar("__d", max(abs(st_matrix("pm") - st_matrix("R_N1_path18_len"))))
_chk `=(scalar(__d) == 0 & abs(r(path_cost) - 4) < 1e-12)' "nwpath, alpha(-1) = igraph with weights as lengths"
nwpath n1, egoid(1) alterid(8) nopaths binary
_chk `=(r(path_length) == 3 & r(paths) >= 1)' "nwpath, binary: fewest steps"
nwpath n2, egoid(1) alterid(6) nopaths
matrix pm = r(paths_matrix)
mata: st_numscalar("__d", max(abs(st_matrix("pm") - st_matrix("R_N2_path16"))))
_chk `=(scalar(__d) == 0 & abs(r(path_cost) - 1.66666666666667) < 1e-12)' "nwpath directed"
nwpath n2, egoid(1) alterid(9) nopaths
_chk `=(r(paths) == 0 & r(path_length) == -1)' "nwpath to an isolate: no path"
nwpath n1, egoid(1) alterid(8) nopaths generate(pth)
capture _nwsyntax pth_1, max(1)
_chk `=(_rc == 0)' "nwpath with generate() creates the path network"
nwpath b1, egoid(1) alterid(8) nopaths
_chk `=(r(path_length) == 3)' "nwpath on a binary network is unchanged (hops)"

* ---------------------------------------------------------------- (H) nwmatching
di as txt _n "(H) nwmatching"
nwmatching tm, generate(mt) silent
_chk `=(abs(r(weight) - 15) < 1e-12 & r(matched) == 4)' "nwmatching default on a valued two-mode network: total value = igraph::max_bipartite_match (15) = brute force"
nwmatching tm, generate(mtb) silent binary
_chk `=(r(matched) == 4)' "nwmatching, binary: maximum number of pairs (4)"
preserve
clear
input str3 p str3 g double v
p1 g1 1
p1 g2 5
p2 g2 1
end
nwfromedge p g v, name(tm2) twomode
restore
nwmatching tm2, generate(m2) silent
_chk `=(abs(r(weight) - 5) < 1e-12 & r(matched) == 1)' "nwmatching: one heavy tie (5) beats two light ones (1 + 1), as igraph"
nwmatching tm2, generate(m2b) silent binary
_chk `=(r(matched) == 2)' "nwmatching, binary: two pairs"

* ---------------------------------------------------------------- (I) assortativity
di as txt _n "(I) nwassortativity"
qui nwassortativity n1
_chk `=(abs(r(assortativity) - (-0.366305377249289)) < 1e-12)' "nwassortativity default on a valued network: attribute = strength (igraph::assortativity, values = strength)"
_chk `=("`r(attribute)'" == "strength")' "nwassortativity names the attribute"
qui nwassortativity n1, binary
_chk `=(abs(r(assortativity) - (-0.235294117647057)) < 1e-12 & "`r(attribute)'" == "degree")' "nwassortativity, binary = igraph::assortativity_degree"
qui nwassortativity n3
_chk `=(abs(r(assortativity) - (-0.230545454545456)) < 1e-12)' "nwassortativity on shares"
qui nwassortativity n1, weighted
_chk `=(abs(r(assortativity) - (-0.300628580706515)) < 1e-12)' "nwassortativity, weighted (Leung and Chau) on strength"
qui nwassortativity b1
_chk `=(abs(r(assortativity) - (-0.235294117647057)) < 1e-12)' "nwassortativity on a binary network is unchanged"

* ---------------------------------------------------------------- (J) Katz with walks, induced centrality
di as txt _n "(J) nwkatz, nwinduced"
clear
nwkatz n2, walks alpha(.1) generate(kz) replace
_cmpvar kz_in R_N2_alpha_c 1e-10 "nwkatz, walks on a valued directed network (in) = igraph::alpha_centrality(weights)"
nwkatz n2, walks alpha(.1) generate(kzb) replace binary
mata: st_numscalar("__d", max(abs(st_data((1,9), "kzb_in") - st_data((1,9), "kz_in")))) 
_chk `=(scalar(__d) > 1e-6)' "nwkatz, binary walks differ from weighted walks"
clear
nwinduced n1, measure(degree) generate(ind) replace silent
mata: st_numscalar("__d", max(abs(st_data((1,8), "ind_endog") - st_matrix("R_N1_deg")')))
_chk `=(scalar(__d) == 0)' "nwinduced, measure(degree) counts ties"
nwinduced n1, measure(evcent) generate(ine) replace silent
mata: st_numscalar("__d", max(abs(st_data((1,8), "ine_endog") :/ max(st_data((1,8), "ine_endog")) - st_matrix("R_N1_evc")')))
_chk `=(scalar(__d) < 1e-6)' "nwinduced, measure(evcent) inherits the weighted default"

* ---------------------------------------------------------------- (K) commands without a weighted form in R: one note on a valued network
di as txt _n "(K) one-line note for binary measures"
nwdegree n1, generate(grp0) silent binary
gen grp = mod(_n, 2) if _n <= 8
local k 0
foreach c in ///
	"nwbridges @, name(zz_@) nwreplace" ///
	"nwdyads @" ///
	"nwtriads @" ///
	"nwmotifs @" ///
	"nwcohesion @, generate(zc_@) replace" ///
	"nwcomponents @, generate(zk_@) replace" ///
	"nwkcomponents @, generate(zkc_@) replace" ///
	"nwkplex @, generate(zp_@) replace" ///
	"nwnclan @, generate(zn_@) replace" ///
	"nwnclique @, generate(zq_@) replace" ///
	"nwsimmelian @, name(zs_@) nwreplace" ///
	"nwshared @, name(zh_@) nwreplace" ///
	"nwsimindex @, measure(jaccard) name(zi_@) replace" ///
	"nwego @, sizevar(ze_@) densvar(zd_@) replace" ///
	"nwneighbor @, ego(n1)" ///
	"nwtabulate @" ///
	"nwmixing @, attribute(grp)" ///
	"nwbrokerage @, group(grp) generate(zb_@) replace" ///
	"nwreach @" ///
	"nwclique @, generate(zl_@) replace" ///
	"nwkcore @, generate(zr_@) replace" {
	local ++k
	local cmd1 = subinstr("`c'", "@", "n1", .)
	local cmd0 = subinstr("`c'", "@", "b1", .)
	_countnote `"`cmd1'"'
	local f1 = r(found)
	local rc1 = r(rc)
	_countnote `"`cmd0'"'
	local f0 = r(found)
	_chk `=(`f1' == 1 & `f0' == 0)' "note on a valued network only: `cmd1' (rc `rc1')"
}
nwset, mat(R_N1_mat) name(n1x) undirected
_countnote "nwturnover n1 n1x, generate(zt) replace"
_chk `=(r(found) == 1)' "note for nwturnover on valued networks"
* the note is not printed when the command runs quietly
qui _countnote "qui nwkcore n1, generate(zq1) replace"
_chk `=(r(found) == 0)' "no note under quietly"

* ---------------------------------------------------------------- (L) flag through nwcollapse / nwreplacemat, dialogs
di as txt _n "(L) more flag paths and dialogs"
nwclear
nwset, mat(R_N1_mat) name(c1) undirected
nwset, mat(S1) name(c0) undirected
nwset, mat(S1) name(c0v) undirected valued
clear
set obs 8
gen grp = ceil(_n / 3)
nwcollapse (max) c0, by(grp) generate(c0_max)
_isval c0_max
_chk `=("`r(valued)'" == "false")' "nwcollapse of a binary network with (max) stays binary"
nwcollapse (sum) c0, by(grp) generate(c0_sum)
_isval c0_sum
_chk `=("`r(valued)'" == "true")' "nwcollapse (sum) of a binary network creates values: valued"
nwcollapse (max) c0v, by(grp) generate(c0v_max)
_isval c0v_max
_chk `=("`r(valued)'" == "true")' "nwcollapse of a valued network (all 1 after max) keeps the flag"
nwcollapse (max) c1, by(grp) generate(c1_max)
_isval c1_max
_chk `=("`r(valued)'" == "true")' "nwcollapse of a valued network keeps the flag"
foreach d in nwdegree nw2degree nwgeodesic nwcloseness nwbetween nwevcent nwpagerank nwpath nwassortativity nwkatz nwfromedge {
	capture db `d'
	_chk `=(_rc == 0)' "dialog `d' opens (capture db, rc `=_rc')"
}

di
if $WS_FAILS == 0 {
	di as txt "test_weightedsupport: all passed"
}
else {
	di as err "test_weightedsupport: $WS_FAILS check(s) failed"
	exit 9
}
