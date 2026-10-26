cscript

do unw_core.do

* Two-mode dispatch (3.8.0): a command that has a two-mode form of the same concept uses it on a two-mode network; onemode forces the one-mode computation.
*   nwdegree (nw2degree), nwclustering (nw2clustering), nwmotifs (nw2motifs), nwcloseness and nwbetween (twomode, now the default).
* 1  one-mode networks (undirected, directed, valued): the five commands give exactly what 3.7.0 gave (fixture cscripts/dispatch380_fixture.dta,
*    made by dispatch380_makefixture.do in a tree without the dispatch)
* 2  Southern women and a subsample of the Swedish directors: the main command equals the nw2 alias (variables and r()), equals the
*    earlier nw2 results of the fixture, and equals R (tnet, igraph, bmotif: numbers of test_twomodesupport and the bmotif fixture of test_nw2motifs)
* 3  onemode equals the earlier one-mode results (nwcloseness, nwbetween, nwmotifs without twomode)
* 4  errors, dialogs
* Prints "test_dispatch380: all passed".

local fx "cscripts/native380_fixture"

capture program drop _chk
program _chk
	args ok msg
	if `ok' == 0 {
		di as err "FAIL: `msg'"
		exit 9
	}
end

* ---- the fixture as Mata arrays: key "net|call|stat" -> values in the order of the nodes (a scalar has node 0)
preserve
qui use cscripts/dispatch380_fixture.dta, clear
qui gen key = net + "|" + call + "|" + stat
qui gen long ord = _n
sort key node
mata: FK = st_sdata(., "key"); FV = st_data(., "value")
restore
capture mata: mata drop d380_get() d380_diff() d380_sc() d380_eq()
mata:
real colvector d380_get(string scalar key)
{
	external string colvector FK
	external real colvector FV
	return(select(FV, FK :== key))
}
// largest absolute difference of a variable from the fixture values of the key; 1e9 if missingness differs, 1e11 if the key is unknown
real scalar d380_diff(string scalar varname, string scalar key)
{
	real colvector r, x
	r = d380_get(key)
	if (rows(r) == 0) return(1e11)
	x = st_data((1::rows(r)), varname)
	if (any((x :>= .) :!= (r :>= .))) return(1e9)
	return(max(abs(editmissing(x, 0) :- editmissing(r, 0))))
}
real scalar d380_sc(string scalar key)
{
	real colvector r
	r = d380_get(key)
	if (rows(r) != 1) return(.)
	return(r)
}
// largest difference of two variables (missing must coincide)
real scalar d380_eq(string scalar a, string scalar b)
{
	real colvector x, y
	x = st_data(., a); y = st_data(., b)
	if (any((x :>= .) :!= (y :>= .))) return(1e9)
	return(max(abs(editmissing(x, 0) :- editmissing(y, 0))))
}
end

capture program drop _fxv
program _fxv
	* _fxv varname key tol message
	args v key tol msg
	mata: st_numscalar("__d", d380_diff("`v'", "`key'"))
	_chk `=scalar(__d) <= `tol'' "`msg' (difference `=scalar(__d)')"
end
capture program drop _fxs
program _fxs
	* _fxs value key tol message
	args val key tol msg
	mata: st_numscalar("__f", d380_sc("`key'"))
	_chk `=abs(`val' - scalar(__f)) <= `tol'' "`msg' (`val' against `=scalar(__f)')"
end
capture program drop _same
program _same
	args a b tol msg
	mata: st_numscalar("__d", d380_eq("`a'", "`b'"))
	_chk `=scalar(__d) <= `tol'' "`msg' (difference `=scalar(__d)')"
end

* =====  1. one-mode networks: identical to 3.7.0
foreach d in flomarriage glasgow3 gahuku gang {
	local f = cond("`d'" == "flomarriage", "florentine", cond("`d'" == "glasgow3", "glasgow", "`d'"))
	nwclear
	nwuse data/`f', nwclear
	nwsummarize `d'
	local dir = ("`r(directed)'" == "true")
	if `dir' {
		nwdegree `d', generate(dgo dgi) silent
		_fxv dgo "`d'|nwdegree|dgo" 0 "`d': nwdegree outdegree as 3.7.0"
		_fxv dgi "`d'|nwdegree|dgi" 0 "`d': nwdegree indegree as 3.7.0"
	}
	else {
		nwdegree `d', generate(dg) silent
		_fxv dg "`d'|nwdegree|dg" 0 "`d': nwdegree as 3.7.0"
	}
	nwclustering `d', generate(cl) silent
	_fxv cl "`d'|nwclustering|cl" 0 "`d': nwclustering as 3.7.0"
	_fxs `=r(cluster_avg)' "`d'|nwclustering|avg" 0 "`d': nwclustering average as 3.7.0"
	_fxs `=r(cluster_global)' "`d'|nwclustering|glob" 0 "`d': nwclustering global as 3.7.0"
	nwcloseness `d', generate(c1 f1 n1) silent
	foreach v in c1 f1 n1 {
		_fxv `v' "`d'|nwcloseness|`v'" 0 "`d': nwcloseness `v' as 3.7.0"
	}
	nwbetween `d', generate(b1) silent
	_fxv b1 "`d'|nwbetween|b1" 0 "`d': nwbetween as 3.7.0"
	_fxs `=r(bw_central)' "`d'|nwbetween|central" 0 "`d': nwbetween centralisation as 3.7.0"
	nwmotifs `d', silent
	foreach s in path star cycle paw diamond k4 disconnected {
		_fxs `=r(`s')' "`d'|nwmotifs|`s'" 0 "`d': nwmotifs `s' as 3.7.0"
	}
	* onemode on a one-mode network changes nothing
	nwcloseness `d', generate(c9 f9 n9) onemode silent
	_same c1 c9 0 "`d': onemode on a one-mode network (closeness)"
	nwbetween `d', generate(b9) onemode silent
	_same b1 b9 0 "`d': onemode on a one-mode network (betweenness)"
}
di as txt "1. one-mode networks (undirected, directed, valued): nwdegree, nwclustering, nwcloseness, nwbetween, nwmotifs equal 3.7.0 exactly"

* =====  2./3. two-mode networks
* R values (tnet 3.0.16, igraph 2.3.2; test_twomodesupport): Southern women
matrix R_d_rowdeg = (7,4,2,4,8,2,4,5,6,7,4,8,2,3,4,7,8,4)
matrix R_d_coldeg = (3,5,4,6,3,3,3,6,4,8,8,10,14,12)
scalar R_d_opsahl = 0.771896799911416
matrix R_d_ra = (0.467764060356653,341,2916)

foreach d in davis dsub {
	nwclear
	if "`d'" == "davis" {
		nwuse data/davis, nwclear
		local net davis
		local bnet 2
	}
	else {
		preserve
		qui import delimited using "`fx'/nets.csv", clear
		qui keep if net == 4
		local n1 = n1[1]
		local n2 = n2[1]
		qui import delimited using "`fx'/cells.csv", clear
		qui keep if net == 4
		mata: C = st_data(., ("i", "j"))
		restore
		mata: M = J(`n1', `n2', 0); for (k = 1; k <= rows(C); k++) M[C[k, 1], C[k, 2]] = 1
		mata: M = M'
		nw2set, mat(M) name(bnet)
		local net bnet
		local bnet 4
	}
	_nwsyntax `net', max(1)
	mata: md = strtoreal(`netobj'->get_modes())'
	qui nwload
	* ---- degree
	nwdegree `net', generate(dg) silent
	_fxv dg "`d'|nw2degree|dg" 0 "`d': nwdegree equals the earlier nw2degree"
	nwdegree `net', generate(dr) raw silent
	_fxv dr "`d'|nw2degree_raw|dr" 0 "`d': nwdegree, raw equals the earlier nw2degree, raw"
	nw2degree `net', generate(da) silent
	_same dg da 0 "`d': nw2degree equals nwdegree"
	nw2degree `net', generate(dar) raw silent
	_same dr dar 0 "`d': nw2degree, raw equals nwdegree, raw"
	if "`d'" == "davis" {
		* tnet::degree_tm: women 7 4 2 ..., events 3 5 4 ... in the order of the nodes of the mode
		mata: x = st_data(., "dr"); a = sort(select(x, md :== 1), 1); b = sort(select(x, md :== 2), 1)
		mata: st_numscalar("__d", max(abs(a :- sort(st_matrix("R_d_rowdeg")', 1))) + max(abs(b :- sort(st_matrix("R_d_coldeg")', 1))))
		_chk `=scalar(__d) == 0' "davis: raw degree equals tnet::degree_tm (difference `=scalar(__d)')"
	}
	* the degree is the number of ties over the size of the other mode
	mata: x = st_data(., "dr"); y = st_data(., "dg"); n1 = sum(md :== 1); n2 = sum(md :== 2); st_numscalar("__d", max(abs(y :- x :/ (n2 :* (md :== 1) :+ n1 :* (md :== 2)))))
	_chk `=scalar(__d) < 1e-6' "`d': default degree = ties / size of the other mode"
	* onemode: the number of ties of the bipartite graph (as the one-mode degree)
	nwdegree `net', generate(d1) onemode silent
	_same d1 dr 0 "`d': nwdegree, onemode counts the ties"
	capture noisily nwdegree `net', generate(d8) onemode raw silent
	_chk `=_rc == 198' "nwdegree: onemode with raw is refused"

	* ---- clustering
	nwclustering `net', generate(k1) level(1)
	_fxv k1 "`d'|nw2clust1|k1" 0 "`d': nwclustering, level(1) equals the earlier nw2clustering"
	_fxs `=r(C_global)' "`d'|nw2clust1|glob" 0 "`d': nwclustering global coefficient"
	nwclustering `net', generate(k2) level(2)
	_fxv k2 "`d'|nw2clust2|k2" 0 "`d': nwclustering, level(2) equals the earlier nw2clustering"
	nwclustering `net', generate(k3)
	_same k3 k1 0 "`d': nwclustering without level() is level(1)"
	nw2clustering `net', generate(k4) level(1)
	_same k4 k1 0 "`d': nw2clustering equals nwclustering"
	local g1 = r(C_global)
	nwclustering `net', ra
	_fxs `=r(ra)' "`d'|nw2ra|ra" 0 "`d': nwclustering, ra"
	_fxs `=r(C4)' "`d'|nw2ra|c4" 0 "`d': nwclustering, ra: four-cycles"
	_fxs `=r(L3)' "`d'|nw2ra|l3" 0 "`d': nwclustering, ra: three-paths"
	nw2clustering `net', ra
	if "`d'" == "davis" {
		nwclustering `net', generate(k5) replace
		_chk `=abs(r(C_global) - scalar(R_d_opsahl)) < 1e-12' "davis: Opsahl clustering equals tnet::clustering_tm"
		nwclustering `net', ra
		_chk `=abs(r(ra) - R_d_ra[1,1]) < 1e-12 & r(C4) == R_d_ra[1,2] & r(L3) == R_d_ra[1,3]' "davis: Robins-Alexander coefficient equals R (4 C4 / L3)"
	}
	capture noisily nwclustering `net', generate(k6) onemode ra
	_chk `=_rc == 198' "nwclustering: onemode with ra is refused"

	* ---- motifs
	nwmotifs `net', generate(np) normalise silent
	matrix MT = r(motifs)
	local r_sixnode = r(sixnode)
	forvalues j = 1/46 {
		_fxv np`j' "`d'|nw2motifs|np`j'" 0 "`d': nwmotifs position `j' equals the earlier nw2motifs"
	}
	forvalues j = 1/`=colsof(MT)' {
		mata: st_numscalar("__d", max(abs(st_matrix("MT")[., `j'] :- d380_get("`d'|nw2motifs|mot`j'"))))
		_chk `=scalar(__d) == 0' "`d': nwmotifs motif table column `j' equals the earlier nw2motifs"
	}
	* bmotif::mcount (fixture of test_nw2motifs): the frequencies
	preserve
	qui import delimited using "`fx'/freq.csv", clear asdouble
	qui keep if net == `bnet'
	sort motif
	mata: BF = st_data(., "frequency")
	restore
	mata: st_numscalar("__d", max(abs(st_matrix("MT")[., 3] :- BF[1::rows(st_matrix("MT"))])))
	_chk `=scalar(__d) == 0' "`d': nwmotifs frequencies equal bmotif::mcount (difference `=scalar(__d)')"
	nw2motifs `net', generate(npa) normalise silent
	matrix MA = r(motifs)
	mata: st_numscalar("__d", max(abs(st_matrix("MA") :- st_matrix("MT"))))
	_chk `=scalar(__d) == 0' "`d': nw2motifs equals nwmotifs (table)"
	_same np1 npa1 0 "`d': nw2motifs equals nwmotifs (position 1)"
	_same np46 npa46 0 "`d': nw2motifs equals nwmotifs (position 46)"
	* onemode: the 4-node census of the bipartite graph, as before
	nwmotifs `net', onemode silent
	foreach s in path star cycle paw diamond k4 disconnected {
		_fxs `=r(`s')' "`d'|motifs_1m|`s'" 0 "`d': nwmotifs, onemode: `s' as 3.7.0"
	}
	capture noisily nwmotifs `net', onemode sixnode silent
	_chk `=_rc == 198' "nwmotifs: onemode with sixnode is refused"

	* ---- closeness and betweenness
	nwcloseness `net', generate(cd fd nd) silent
	foreach v in cd fd nd {
		_fxv `v' "`d'|closeness_2m|`=substr("`v'", 1, 1)'2" 0 "`d': nwcloseness default equals twomode (`v')"
	}
	nwcloseness `net', generate(ct ft nt) twomode silent
	_same cd ct 0 "`d': twomode is a synonym of the default (closeness)"
	nwcloseness `net', generate(co fo no) onemode silent
	foreach v in co fo no {
		_fxv `v' "`d'|closeness_1m|`=substr("`v'", 1, 1)'1" 0 "`d': nwcloseness, onemode equals 3.7.0 (`v')"
	}
	nwbetween `net', generate(bd) silent
	_fxv bd "`d'|between_2m|b2" 0 "`d': nwbetween default equals twomode"
	nwbetween `net', generate(bt) twomode silent
	_same bd bt 0 "`d': twomode is a synonym of the default (betweenness)"
	nwbetween `net', generate(bo) onemode silent
	_fxv bo "`d'|between_1m|b1" 0 "`d': nwbetween, onemode equals 3.7.0"
	_fxs `=r(bw_central)' "`d'|between_1m|central" 1e-12 "`d': nwbetween centralisation from the raw scores"
	nwbetween `net', generate(bd2) silent
	_fxs `=r(bw_central)' "`d'|between_1m|central" 1e-12 "`d': centralisation of the default form is computed from the raw scores"
	capture noisily nwbetween `net', generate(bx) onemode twomode silent
	_chk `=_rc == 198' "nwbetween: onemode with twomode is refused"
	capture noisily nwcloseness `net', generate(cx fx nx) onemode twomode silent
	_chk `=_rc == 198' "nwcloseness: onemode with twomode is refused"
	di as txt "  `d': nwdegree, nwclustering, nwmotifs, nwcloseness, nwbetween equal their nw2 forms, the earlier results and R"
}
* R (igraph, tnet): Southern women, Borgatti-Everett normalisations are in test_twomodesupport (twomode = default here)
di as txt "2. two-mode networks: main command = alias = earlier nw2 result = R (tnet, igraph, bmotif)"
di as txt "3. onemode equals the earlier one-mode results"

* =====  4. errors and one-mode refusal of the aliases, dialogs
nwclear
nwuse data/florentine, nwclear
foreach c in nw2degree nw2clustering nw2motifs {
	capture noisily `c' flomarriage, generate(zz)
	_chk `=_rc == 198' "`c' of a one-mode network is refused (198)"
}
capture noisily nwdegree flomarriage, generate(zz) raw silent
nwcloseness flomarriage, generate(a1 a2 a3) silent
capture noisily nwcloseness flomarriage, generate(b1 b2 b3) twomode silent
_chk `=_rc == 198' "twomode on a one-mode network is still refused"
capture noisily nwmotifs flomarriage, sixnode silent
_chk `=_rc == 198' "nwmotifs: sixnode on a one-mode network is refused"
foreach c in nwdegree nwclustering nwcloseness nwbetween nw2degree nw2clustering nw2motifs {
	capture db `c'
	_chk `=(_rc == 0)' "dialog `c' opens (capture db, rc `=_rc')"
}
di as txt "4. errors, dialogs"

di as txt "test_dispatch380: all passed"
