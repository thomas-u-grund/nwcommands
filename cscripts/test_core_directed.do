cscript

do unw_core.do

* nwbetween, nwcloseness, nwevcent recognise the type of the network: a directed network is analysed as it is (shortest
* paths follow the direction of the ties), sym asks for the larger of the two directions of each tie first, nosym is
* accepted and the same as the default, an undirected network needs no copy. Every call says which case it ran.
* Run from the repository root. References: igraph 2.3.2 (betweenness(directed = TRUE), closeness(mode = "out",
* normalized = TRUE), weights 1/value for the valued network) and the results of nwcommands 3.34.0 for sym
* (the csv files in cscripts/directed_fixture, node by node, 1e-9).

local tol 1e-9

capture mata: mata drop tcd_readcsv()
mata:
// numeric csv file with one header line (and, for the adjacency file, none): fields separated by commas, "." is missing
real matrix tcd_readcsv(string scalar f, real scalar skip)
{
	string colvector L
	real matrix M
	real scalar i
	L = cat(f)
	L = L[|1 + skip \ rows(L)|]
	M = strtoreal(tokens(subinstr(L[1], ",", " ")))
	M = J(rows(L), cols(M), .)
	for (i = 1; i <= rows(L); i++) M[i, .] = strtoreal(tokens(subinstr(L[i], ",", " ")))
	return(M)
}
end

capture program drop _tcd_cmp
program _tcd_cmp
	* variable v (rows 1..n) against a Mata column vector expr, absolute tolerance, missing equals missing
	args v expr tol label
	mata: __d = st_data((1, rows(`expr')), "`v'"); __e = `expr'; st_numscalar("__bad", sum((__d :>= .) :!= (__e :>= .)) + sum(abs(select(__d, (__d :< .) :& (__e :< .)) - select(__e, (__d :< .) :& (__e :< .))) :> `tol'))
	mata: mata drop __d __e
	if scalar(__bad) != 0 {
		di as err "FAIL: `label' (`=scalar(__bad)' nodes differ)"
		exit 9
	}
	scalar drop __bad
end

capture program drop _tcd_log
program _tcd_log
	* run a command with the log on and look for the note it must print
	args needle cmd
	tempfile lg
	qui log using `"`lg'"', text replace name(tcdlog)
	`cmd'
	qui log close tcdlog
	mata: st_local("__f", strofreal(any(strpos(cat(st_local("lg")), st_local("needle")))))
	if !`__f' {
		di as err `"FAIL: the output of {`cmd'} does not contain "`needle'""'
		exit 9
	}
end

set linesize 120
local NS "directed network: shortest paths follow the direction of the ties"
local NC "directed network: distances follow the direction of the ties"
local NE "directed network: the centrality of a node comes from the nodes that send ties to it"
local SY "directed network symmetrized: the larger of the two directions of a tie"
local UN "undirected network"

* ---------------------------------------------------------------- A. directed network with known values (igraph)
* D8 = edges 1>2 2>1 2>3 3>1 3>4 4>5 5>6 6>4 6>7 7>8 8>7 1>5
nwclear
mata: D8 = J(8,8,0)
mata: E = (1,2\2,1\2,3\3,1\3,4\4,5\5,6\6,4\6,7\7,8\8,7\1,5)
mata: for (k = 1; k <= rows(E); k++) D8[E[k,1], E[k,2]] = 1
nwset, mat(D8) name(d8) directed
qui nwbetween d8, generate(bd)
_tcd_cmp bd "(7,1.5,1.5,3,12.5,11.5,6,0)'" `tol' "nwbetween default on D8 = igraph directed"
qui nwbetween d8, generate(bn) nosym
_tcd_cmp bn "(7,1.5,1.5,3,12.5,11.5,6,0)'" `tol' "nwbetween nosym on D8"
qui nwbetween d8, generate(bs) sym
_tcd_cmp bs "(3,0,3,5,5,10,6,0)'" `tol' "nwbetween sym on D8 = igraph on the collapsed network"
qui nwbetween d8, generate(bz) standardize
_tcd_cmp bz "(7,1.5,1.5,3,12.5,11.5,6,0)' :/ 42" `tol' "nwbetween default standardized, directed (n-1)(n-2)"
qui nwcloseness d8, generate(cd fd nd)
_tcd_cmp cd "(0.4375,0.388888888888889,0.388888888888889,0.4,0.5,0.666666666666667,1,1)'" `tol' "nwcloseness default on D8 = igraph mode out"
qui nwcloseness d8, generate(cn fn nn) nosym
_tcd_cmp cn "(0.4375,0.388888888888889,0.388888888888889,0.4,0.5,0.666666666666667,1,1)'" `tol' "nwcloseness nosym on D8"
qui nwcloseness d8, generate(cs fs ns) sym
qui nwset, detail
assert `"`r(nets)'"' == `" d8"'
* sym closeness equals the closeness of the collapsed undirected network
nwset, mat(D8) name(d8u) directed
qui nwsym d8u, mode(max) generate(d8s)
qui nwcloseness d8s, generate(cu fu nu)
mata: CU = st_data((1,8), "cu")
_tcd_cmp cs "CU" `tol' "nwcloseness sym = closeness of nwsym max"

* ---------------------------------------------------------------- B. directed out-star, by hand
nwclear
nwset, mat((0,1,1,1\0,0,0,0\0,0,0,0\0,0,0,0)) name(ostar) directed
qui nwbetween ostar, generate(b0)
_tcd_cmp b0 "(0,0,0,0)'" 0 "out-star: nobody lies between two others"
qui nwbetween ostar, generate(b1) sym
_tcd_cmp b1 "(3,0,0,0)'" 0 "out-star symmetrized: centre 3"
qui nwcloseness ostar, generate(c0 f0 n0)
assert c0[1] == 1 & f0[1] == 3
assert missing(c0[2]) & missing(c0[3]) & missing(c0[4])
qui nwcloseness ostar, generate(c1 f1 n1) sym
assert c1[1] == 1
assert reldif(c1[2], .6) < 1e-12
qui nwevcent ostar, generate(e1) sym
assert reldif(e1[1], 1/sqrt(2)) < 1e-6 & reldif(e1[2], 1/sqrt(6)) < 1e-6
* directed cycle: every node the same
nwset, mat((0,1,0\0,0,1\1,0,0)) name(cyc) directed
qui nwevcent cyc, generate(ec)
assert reldif(ec[1], 1/sqrt(3)) < 1e-6 & reldif(ec[3], 1/sqrt(3)) < 1e-6
qui nwevcent cyc, generate(ec2) nosym
assert ec2[1] == ec[1] & ec2[2] == ec[2] & ec2[3] == ec[3]

* ---------------------------------------------------------------- C. options: nosym is the default, sym + nosym is an error
foreach c in nwbetween nwevcent {
	capture `c' ostar, generate(xx) sym nosym
	assert _rc == 198
	capture confirm variable xx
	assert _rc != 0
}
capture nwcloseness ostar, generate(x1 x2 x3) sym nosym
assert _rc == 198
capture confirm variable x1
assert _rc != 0
* no helper network is left behind
nwset, detail
assert `"`r(nets)'"' == `" ostar cyc"'

* ---------------------------------------------------------------- D. undirected networks: unchanged, sym and nosym change nothing
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(upath) undirected labs(A,B,C,D,E)
qui nwbetween upath, generate(bu)
_tcd_cmp bu "(0,3,4,3,0)'" 0 "undirected path betweenness"
foreach o in sym nosym {
	qui nwbetween upath, generate(bu_`o') `o'
	_tcd_cmp bu_`o' "(0,3,4,3,0)'" 0 "undirected path betweenness, `o'"
	qui nwcloseness upath, generate(cu_`o' fu_`o' nu_`o') `o'
	qui nwevcent upath, generate(eu_`o') `o'
}
qui nwcloseness upath, generate(cu fu nu)
qui nwevcent upath, generate(eu)
forvalues i = 1/5 {
	foreach o in sym nosym {
		assert cu_`o'[`i'] == cu[`i'] & fu_`o'[`i'] == fu[`i'] & eu_`o'[`i'] == eu[`i']
	}
}
nwset, detail
assert `"`r(nets)'"' == `" upath"'

* ---------------------------------------------------------------- E. the analysed network is the current network, in every mode
nwclear
nwset, mat((0,1,1,1\0,0,0,0\0,0,0,0\0,0,0,0)) name(ostar) directed
nwset, mat((0,1,0\1,0,1\0,1,0)) name(upath3) undirected
foreach nt in ostar upath3 {
	foreach o in "" sym nosym {
		local other = cond("`nt'" == "ostar", "upath3", "ostar")
		qui nwcurrent `other'
		qui nwbetween `nt', generate(bq) replace `o'
		qui nwcurrent
		assert "`r(current)'" == "`nt'"
		qui nwcurrent `other'
		qui nwcloseness `nt', generate(cq fq nq) replace `o'
		qui nwcurrent
		assert "`r(current)'" == "`nt'"
		qui nwcurrent `other'
		qui nwevcent `nt', generate(eq) replace `o'
		qui nwcurrent
		assert "`r(current)'" == "`nt'"
	}
}

* ---------------------------------------------------------------- F. the printed notes
_tcd_log "(`NS')" "nwbetween ostar, generate(bq) replace"
_tcd_log "(`NS')" "nwbetween ostar, generate(bq) replace nosym"
_tcd_log "(`SY')" "nwbetween ostar, generate(bq) replace sym"
_tcd_log "(`UN')" "nwbetween upath3, generate(bq) replace"
_tcd_log "(`UN')" "nwbetween upath3, generate(bq) replace sym"
_tcd_log "(`NC')" "nwcloseness ostar, generate(cq fq nq) replace"
_tcd_log "(`NC')" "nwcloseness ostar, generate(cq fq nq) replace nosym"
_tcd_log "(`SY')" "nwcloseness ostar, generate(cq fq nq) replace sym"
_tcd_log "(`UN')" "nwcloseness upath3, generate(cq fq nq) replace"
_tcd_log "(`NE')" "nwevcent ostar, generate(eq) replace"
_tcd_log "(`NE')" "nwevcent ostar, generate(eq) replace nosym"
_tcd_log "(`SY')" "nwevcent ostar, generate(eq) replace sym"
_tcd_log "(`UN')" "nwevcent upath3, generate(eq) replace"

* ---------------------------------------------------------------- G. Lazega advice (directed, binary): igraph and 3.34.0
nwuse data/lazega, nwclear
mata: FXL = tcd_readcsv("cscripts/directed_fixture/lazega_adv_v3340_igraph.csv", 1)
qui nwbetween lazega_adv, generate(b_d)
_tcd_cmp b_d "FXL[.,4]" `tol' "lazega_adv: nwbetween default = igraph directed"
qui nwbetween lazega_adv, generate(b_n) nosym
_tcd_cmp b_n "FXL[.,4]" `tol' "lazega_adv: nwbetween nosym"
qui nwbetween lazega_adv, generate(b_z) standardize
_tcd_cmp b_z "FXL[.,6]" `tol' "lazega_adv: nwbetween standardize = igraph / ((n-1)(n-2))"
qui nwbetween lazega_adv, generate(b_s) sym
_tcd_cmp b_s "FXL[.,1]" `tol' "lazega_adv: nwbetween sym = 3.34.0 default"
qui nwcloseness lazega_adv, generate(c_d f_d n_d)
_tcd_cmp c_d "FXL[.,5]" `tol' "lazega_adv: nwcloseness default = igraph mode out"
qui nwcloseness lazega_adv, generate(c_n f_n n_n) nosym
_tcd_cmp c_n "FXL[.,5]" `tol' "lazega_adv: nwcloseness nosym"
qui nwcloseness lazega_adv, generate(c_s f_s n_s) sym
_tcd_cmp c_s "FXL[.,2]" `tol' "lazega_adv: nwcloseness sym = 3.34.0 default"
qui nwevcent lazega_adv, generate(e_s) sym
_tcd_cmp e_s "FXL[.,3]" `tol' "lazega_adv: nwevcent sym = 3.34.0 default"
qui nwevcent lazega_adv, generate(e_d)
qui nwevcent lazega_adv, generate(e_n) nosym
mata: assert(st_data(., "e_d") == st_data(., "e_n"))

* ---------------------------------------------------------------- H. a directed valued network (50 nodes, values 1 to 5): cost 1/value
nwclear
mata: D4 = editmissing(tcd_readcsv("cscripts/directed_fixture/d4_adj.csv", 0), 0)
nwset, mat(D4) name(d4) directed
mata: FXV = tcd_readcsv("cscripts/directed_fixture/d4_v3340_igraph.csv", 1)
qui nwbetween d4, generate(v_bd)
_tcd_cmp v_bd "FXV[.,4]" `tol' "d4 valued: nwbetween default = igraph directed, weights 1/value"
qui nwbetween d4, generate(v_bn) nosym
_tcd_cmp v_bn "FXV[.,4]" `tol' "d4 valued: nwbetween nosym"
qui nwbetween d4, generate(v_bs) sym
_tcd_cmp v_bs "FXV[.,1]" `tol' "d4 valued: nwbetween sym = 3.34.0 default"
qui nwcloseness d4, generate(v_cd v_fd v_nd)
_tcd_cmp v_cd "FXV[.,5]" `tol' "d4 valued: nwcloseness default = igraph mode out"
qui nwcloseness d4, generate(v_cs v_fs v_ns) sym
_tcd_cmp v_cs "FXV[.,2]" `tol' "d4 valued: nwcloseness sym = 3.34.0 default"
qui nwevcent d4, generate(v_es) sym
_tcd_cmp v_es "FXV[.,3]" `tol' "d4 valued: nwevcent sym = 3.34.0 default"
qui nwbetween d4, generate(v_bb) binary
qui nwbetween d4, generate(v_bbs) binary sym
mata: assert(any(abs(st_data(., "v_bb") - st_data(., "v_bbs")) :> 1e-6))

* ---------------------------------------------------------------- I. a netlist: directed and undirected network in one call
nwclear
nwset, mat((0,1,1,1\0,0,0,0\0,0,0,0\0,0,0,0)) name(ostar) directed
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(upath4) undirected
qui nwbetween ostar upath4, generate(nb)
assert nb_ostar[1] == 0 & nb_upath4[2] == 2
qui nwbetween ostar upath4, generate(nb2) sym replace
assert nb2_ostar[1] == 3 & nb2_upath4[2] == 2
qui nwcloseness ostar upath4, generate(nc nf nn)
qui nwcurrent
assert "`r(current)'" == "upath4"

di "PASS: test_core_directed"
