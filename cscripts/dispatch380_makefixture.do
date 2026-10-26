cscript

* Makes cscripts/dispatch380_fixture.dta: what the commands nwdegree, nwclustering, nwcloseness, nwbetween and nwmotifs give on one-mode
* networks, and what the earlier calls (nwcloseness and nwbetween without twomode, nwmotifs, nw2degree, nw2clustering, nw2motifs) give on two-mode
* networks, in a tree WITHOUT the two-mode dispatch (3.7.0, or the branch motifs380 of 3.8.0).  Run from the repository root of such a tree;
* the fixture is then compared with the dispatching code by cscripts/test_dispatch380.do.
*   long: net (network), call, stat (variable or r() name), node (row of the data set; 0 for a scalar), value

do unw_core.do

local fx "cscripts/native380_fixture"
tempfile res
tempname post
postfile `post' str24 net str24 call str16 stat double node double value using `res', replace

capture program drop _pvar
program _pvar
	args post net call stat
	forvalues i = 1/`=_N' {
		post `post' ("`net'") ("`call'") ("`stat'") (`i') (`stat'[`i'])
	}
end
capture program drop _pscal
program _pscal
	args post net call stat val
	post `post' ("`net'") ("`call'") ("`stat'") (0) (`val')
end

* ---- one-mode networks: undirected binary, directed, valued
foreach d in flomarriage glasgow3 gahuku gang {
	local f = cond("`d'" == "flomarriage", "florentine", cond("`d'" == "glasgow3", "glasgow", "`d'"))
	nwclear
	nwuse data/`f', nwclear
	nwsummarize `d'
	local dir = ("`r(directed)'" == "true")
	if "`d'" == "gahuku" | "`d'" == "gang" {
		nwuse data/`f', nwclear
	}
	if `dir' {
		nwdegree `d', generate(dgo dgi) silent
		foreach v in dgo dgi {
			_pvar `post' `d' nwdegree `v'
		}
	}
	else {
		nwdegree `d', generate(dg) silent
		_pvar `post' `d' nwdegree dg
	}
	nwclustering `d', generate(cl) silent
	_pvar `post' `d' nwclustering cl
	_pscal `post' `d' nwclustering avg `=r(cluster_avg)'
	_pscal `post' `d' nwclustering glob `=r(cluster_global)'
	nwcloseness `d', generate(c1 f1 n1) silent
	foreach v in c1 f1 n1 {
		_pvar `post' `d' nwcloseness `v'
	}
	nwbetween `d', generate(b1) silent
	_pvar `post' `d' nwbetween b1
	_pscal `post' `d' nwbetween central `=r(bw_central)'
	nwmotifs `d', silent
	foreach s in path star cycle paw diamond k4 disconnected {
		_pscal `post' `d' nwmotifs `s' `=r(`s')'
	}
}

* ---- two-mode networks: the Southern women and a subsample of the directors (the net 4 of the fixture of test_nw2motifs)
foreach d in davis dsub {
	nwclear
	if "`d'" == "davis" {
		nwuse data/davis, nwclear
		local net davis
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
	}
	* the earlier calls, without twomode: the one-mode result (equal to onemode of 3.8.0)
	nwcloseness `net', generate(c1 f1 n1) silent
	foreach v in c1 f1 n1 {
		_pvar `post' `d' closeness_1m `v'
	}
	nwbetween `net', generate(b1) silent
	_pvar `post' `d' between_1m b1
	_pscal `post' `d' between_1m central `=r(bw_central)'
	nwmotifs `net', silent
	foreach s in path star cycle paw diamond k4 disconnected {
		_pscal `post' `d' motifs_1m `s' `=r(`s')'
	}
	* with twomode (the new default)
	nwcloseness `net', generate(c2 f2 n2) twomode silent
	foreach v in c2 f2 n2 {
		_pvar `post' `d' closeness_2m `v'
	}
	nwbetween `net', generate(b2) twomode silent
	_pvar `post' `d' between_2m b2
	* the nw2 commands
	nw2degree `net', generate(dg) silent
	_pvar `post' `d' nw2degree dg
	nw2degree `net', generate(dr) raw silent
	_pvar `post' `d' nw2degree_raw dr
	nw2clustering `net', generate(k1) level(1)
	_pvar `post' `d' nw2clust1 k1
	_pscal `post' `d' nw2clust1 glob `=r(C_global)'
	_pscal `post' `d' nw2clust1 avg `=r(C_avg)'
	nw2clustering `net', generate(k2) level(2)
	_pvar `post' `d' nw2clust2 k2
	nw2clustering `net', ra
	_pscal `post' `d' nw2ra ra `=r(ra)'
	_pscal `post' `d' nw2ra c4 `=r(C4)'
	_pscal `post' `d' nw2ra l3 `=r(L3)'
	nw2motifs `net', generate(np) normalise silent
	matrix MT = r(motifs)
	forvalues j = 1/`=colsof(MT)' {
		forvalues i = 1/`=rowsof(MT)' {
			post `post' ("`d'") ("nw2motifs") ("mot`j'") (`i') (MT[`i', `j'])
		}
	}
	forvalues j = 1/46 {
		_pvar `post' `d' nw2motifs np`j'
	}
}
postclose `post'
use `res', clear
compress
save cscripts/dispatch380_fixture.dta, replace
di as txt "dispatch380_fixture: " _N " values"
