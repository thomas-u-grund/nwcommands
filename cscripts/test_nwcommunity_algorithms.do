* nwcommunity algorithm(leiden) and algorithm(infomap) (3.28.0)
* fixture (cscripts/nwcommunity_fixture, made by make_fixture.R): R 4.6, igraph cluster_louvain, cluster_leiden (modularity), cluster_infomap, cluster_label_prop
clear all
set more off
nwclear
run nwcommunity.ado
local fx "cscripts/nwcommunity_fixture"
local nfail = 0

mata:
real matrix nwtest_csv(string scalar f, real scalar skip)
{
	real scalar fh, k
	string scalar line
	real matrix X
	fh = fopen(f, "r")
	X = J(0, 0, .)
	k = 0
	while ((line = fget(fh)) != J(0, 0, "")) {
		k++
		if (k <= skip) continue
		if (rows(X) == 0) X = strtoreal(tokens(subinstr(line, ",", " ")))
		else X = X \ strtoreal(tokens(subinstr(line, ",", " ")))
	}
	fclose(fh)
	return(X)
}
// adjusted Rand index of two partitions
real scalar nwtest_ari(real colvector a, real colvector b)
{
	real matrix tab
	real scalar n, s, sa, sb, e
	real colvector ua, ub
	ua = nw_cm_dense(a)
	ub = nw_cm_dense(b)
	tab = J(max(ua), max(ub), 0)
	for (n = 1; n <= rows(ua); n++) tab[ua[n], ub[n]] = tab[ua[n], ub[n]] + 1
	n = rows(ua)
	s = sum(tab :* (tab :- 1) :/ 2)
	sa = sum(rowsum(tab) :* (rowsum(tab) :- 1) :/ 2)
	sb = sum(colsum(tab)' :* (colsum(tab)' :- 1) :/ 2)
	e = sa * sb / (n * (n - 1) / 2)
	if (sa + sb == 0) return(1)
	return((s - e) / ((sa + sb) / 2 - e))
}
end

capture program drop nwt_load
program nwt_load
	args nm
	tempname T
	mata: `T' = nwtest_csv("cscripts/nwcommunity_fixture/g_`nm'.csv", 0)
	mata: n = max(`T'[., 1::2]); `T' = `T' \ (`T'[., 2], `T'[., 1], `T'[., 3])
	mata: st_local("nn", strofreal(n))
	capture nwdrop `nm'
	_nwsetsparse, triplets(`T') nodes(`nn') name(`nm') undirected
	mata: mata drop `T'
end

mata: SM = nwtest_csv("`fx'/summary.csv", 1)
* summary.csv columns: 1 graph (text), 2 n, 3 m, 4 weighted (text), 5-6 louvain Q k, 7-8 leiden Q k, 9-10 infomap Q k, 11 codelength,
* 12-13 label propagation Q k, 14-17 range of single Louvain / Leiden runs, 18-19 ARI, 20-21 leiden with resolution 2
local gi = 0
foreach nm in karate pp100 ppw100 pp1000 lazega_adv lazega_cow lazega_fr {
	local ++gi
	nwt_load `nm'
	mata: R = nwtest_csv("`fx'/res_`nm'.csv", 1)
	mata: nr = rows(R)
	foreach alg in leiden infomap {
		timer clear 1
		timer on 1
		qui nwcommunity `nm', algorithm(`alg') seed(20261119) generate(cm) replace silent
		timer off 1
		qui timer list 1
		local q = r(modularity)
		local t = r(t1)
		local kk = r(communities)
		local cl = r(codelength)
		mata: M = st_data((1::nr), "cm")
		qui nwcommunity `nm', algorithm(`alg') seed(20261119) generate(cm) replace silent
		mata: st_local("same", strofreal(all(M :== st_data((1::nr), "cm"))))
		local col = cond("`alg'" == "leiden", 3, 4)
		mata: st_local("ari", strofreal(nwtest_ari(M, R[., `col'])))
		local cq = cond("`alg'" == "leiden", 7, 9)
		local ck = `cq' + 1
		mata: st_local("qR", strofreal(SM[`gi', `cq']))
		mata: st_local("kR", strofreal(SM[`gi', `ck']))
		mata: st_local("clR", strofreal(SM[`gi', 11]))
		di "RESULT `nm' `alg': Q " %7.4f `q' " (R " %7.4f `qR' ") k `kk' (R `kR') ARI " %6.4f `ari' " codelength `cl' (igraph `clR') time " `t' " s"
		if `same' != 1 {
			di as err "FAIL `nm' `alg': not reproducible with the same seed"
			local ++nfail
		}
		if "`alg'" == "leiden" {
			* modularity of the best of 10 runs: equal to or within 0.003 of igraph's best of 30; where Q agrees, the partition agrees
			if `q' < `qR' - 0.003 {
				di as err "FAIL `nm' leiden: Q `q' below igraph `qR'"
				local ++nfail
			}
			if abs(`q' - `qR') < 1e-6 & `ari' < 0.99 {
				di as err "FAIL `nm' leiden: same Q but ARI `ari'"
				local ++nfail
			}
			* resolution 2 against igraph
			qui nwcommunity `nm', algorithm(leiden) resolution(2) trials(30) seed(1) generate(cm) replace silent
			mata: M2 = st_data((1::nr), "cm")
			local q2 = r(modularity)
			mata: st_local("qR2", strofreal(SM[`gi', 20]))
			mata: st_local("ari2", strofreal(nwtest_ari(M2, R[., 6])))
			di "RESULT `nm' leiden resolution(2): Q " %7.4f `q2' " (R " %7.4f `qR2' ") ARI " %6.4f `ari2'
			if `q2' < `qR2' - 0.006 {
				di as err "FAIL `nm' leiden resolution(2): Q `q2' below igraph `qR2'"
				local ++nfail
			}
		}
		else {
			* Infomap: the same number of modules as igraph and the same partition where there is structure
			if `kk' != `kR' {
				di as err "FAIL `nm' infomap: `kk' modules, igraph `kR'"
				local ++nfail
			}
			if `kR' > 1 & `ari' < 0.9 {
				di as err "FAIL `nm' infomap: ARI `ari'"
				local ++nfail
			}
		}
	}
}

* planted partitions are recovered by every method (ARI >= 0.9 with the truth)
foreach nm in pp100 pp1000 ppw100 {
	nwt_load `nm'
	mata: R = nwtest_csv("`fx'/res_`nm'.csv", 1)
	mata: nr = rows(R)
	foreach alg in louvain labelprop leiden infomap {
		* label propagation only on the unweighted planted partitions (it does not optimise anything, see the help)
		if "`alg'" == "labelprop" & "`nm'" == "ppw100" continue
		qui nwcommunity `nm', algorithm(`alg') seed(5) generate(cm) replace silent
		mata: st_local("ari", strofreal(nwtest_ari(st_data((1::nr), "cm"), (R[., 7] \ J(0, 1, .))[1::nr])))
		di "RESULT `nm' `alg': ARI with the planted partition " %6.4f `ari'
		if `ari' < 0.9 {
			di as err "FAIL `nm' `alg': ARI with the planted partition `ari'"
			local ++nfail
		}
	}
}

* ---- options and error paths ----
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(u6) undirected
nwset, mat((0,1,1,0,0,0\0,0,1,0,0,0\1,0,0,1,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,0,0)) name(d6) directed
mata: M = (1,1,0\1,0,0\0,1,1\0,0,1\1,0,1)
nw2set, mat(M) name(b2)
foreach alg in leiden infomap {
	qui nwcommunity u6, algorithm(`alg') generate(cm) replace silent seed(3)
	assert r(communities) == 2 & r(modularity) > 0.35
	capture nwcommunity d6, algorithm(`alg') generate(cm) replace silent
	assert _rc == 198
	qui nwcommunity d6, algorithm(`alg') symmetrize generate(cm) replace silent seed(3)
	assert r(communities) >= 1
	capture nwcommunity b2, algorithm(`alg') generate(cm) replace silent
	assert _rc == 198
	qui nwcommunity b2, algorithm(`alg') onemode generate(cm) replace silent seed(3)
	capture nwcommunity u6, algorithm(`alg') trials(0) generate(cm) replace silent
	assert _rc == 198
}
capture nwcommunity u6, algorithm(infomap) resolution(2) generate(cm) replace silent
assert _rc == 198
capture nwcommunity u6, algorithm(leiden) beta(0) generate(cm) replace silent
assert _rc == 198
capture nwcommunity u6, algorithm(leiden) iterations(0) generate(cm) replace silent
assert _rc == 198
capture nwcommunity u6, algorithm(nosuch) generate(cm) replace silent
assert _rc != 0
* iterations(-1): until the partition no longer changes; the infomap codelength is returned
qui nwcommunity u6, algorithm(leiden) iterations(-1) trials(3) generate(cm) replace silent seed(2)
assert r(communities) == 2
qui nwcommunity u6, algorithm(infomap) trials(3) generate(cm) replace silent seed(2)
assert r(codelength) > 0 & r(codelength) < 3
* a network without ties: every node is a community of its own
nwset, mat((0,0,0\0,0,0\0,0,0)) name(empty3) undirected
foreach alg in leiden infomap {
	capture nwcommunity empty3, algorithm(`alg') generate(cm) replace silent
	if _rc di "(note: algorithm(`alg') on a network without ties: rc " _rc ")"
}

di
if `nfail' == 0 di "PASS nwcommunity leiden and infomap against igraph, options and error paths"
else di as err "FAIL: `nfail' comparisons"
