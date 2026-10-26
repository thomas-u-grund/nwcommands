cscript

do unw_core.do

* Native kernels 51..53 of the nwgraph plugin (generation 12) against R and against the Mata code they replace:
*   51 node-by-node similarities of nwsimilar, nwdissimilar and nwcorrelate (all types and contexts; R: the definition
*      written out in tools/verify_native390.R, igraph::similarity on the pairs that are not adjacent; native = Mata code)
*   52 DIRT_LPA+ communities of nwcommunity, algorithm(dirtlpa) on two-mode networks (R: bipartite::DIRT_LPA_wb_plus;
*      Barber's Q recomputed independently from the ties)
*   53 null models of the two-mode nwcug (vegan::nullmodel r00, r0, c0, curveball; exact margins, null means)
* Without a plugin of generation 12 (Linux and Windows binaries before the CI build, or an old plugin) the test is skipped.
* Prints "native390: all equal" on success.

mata: st_local("gen", strofreal(nwg_comb_version()))
if `gen' < 12 {
	di as txt "native390: plugin generation `gen' < 12, native kernels not available: SKIPPED"
	exit
}
local fx "cscripts/native390_fixture"
local nfail 0

* ---------------------------------------------------------------------------------------------------------
* A. similarities
* ---------------------------------------------------------------------------------------------------------
import delimited using "`fx'/sim_nets.csv", clear asdouble
mata: SN = st_data(., ("net", "i", "j", "w", "dir"))
import delimited using "`fx'/sim_expected.csv", clear stringcols(2 3) asdouble
mata: SE_t = st_sdata(., ("type", "ctx"))
mata: SE_n = st_data(., ("net", "i", "j"))
mata: SE_v = st_data(., "v")
clear

mata:
real scalar n390_cmp(real matrix A, real matrix rr)
{
	real scalar k, d, a
	d = 0
	for (k = 1; k <= rows(rr); k++) {
		a = A[rr[k, 1], rr[k, 2]]
		if ((a >= .) != (rr[k, 3] >= .)) d = 1e9
		else if (a < .) d = max((d, abs(a - rr[k, 3])))
	}
	return(d)
}
end
local nnet = 4
local ncmp 0
local maxd 0
foreach sm in dense sparse {
	global NW_SIMMODE `sm'
	forvalues s = 1/`nnet' {
		mata: st_local("n", strofreal(sqrt(sum(SN[., 1] :== `s'))))
		mata: st_local("dir", strofreal(SN[min(selectindex(SN[., 1] :== `s')), 5]))
		mata: M = rowshape(select(SN[., 4], SN[., 1] :== `s'), `n')'
		* the cells are listed by column in R (which(.., arr.ind)): row i, column j
		nwset, mat(M) name(rn) `=cond(`dir', "directed", "undirected")'
		foreach ty in pearson matches jaccard hamming crossproduct euclidean manhatten nonmatches djaccard dhamming {
			foreach cx in both incoming outgoing {
				if "`ty'" == "pearson" & "`cx'" != "outgoing" continue
				local cmd = cond(inlist("`ty'", "pearson", "matches", "jaccard", "hamming", "crossproduct"), "nwsimilar", "nwdissimilar")
				local rt = cond("`ty'" == "djaccard", "jaccard", cond("`ty'" == "dhamming", "hamming", "`ty'"))
				qui `cmd' rn, type(`rt') context(`cx') name(rs)
				qui _nwsyntax rs
				mata: A = *`netobj'->get_matrix()
				mata: sel = selectindex((SE_t[., 1] :== "`ty'") :& (SE_t[., 2] :== "`cx'") :& (SE_n[., 1] :== `s'))
				mata: rr = SE_n[sel, 2], SE_n[sel, 3], SE_v[sel]
				* pearson: the diagonal of a node correlation network is missing (nwcorrelate); R gives NA where a profile has no variance (nwcommands returns a fallback value): compared only where R is defined
				mata: ok = ((rr[., 3] :< .) :& (rr[., 1] :!= rr[., 2])) :| ("`ty'" != "pearson")
				mata: rr = select(rr, ok)
				mata: d = n390_cmp(A, rr)
				mata: st_local("d", strofreal(d))
				local ++ncmp
				if `d' > `maxd' & `d' < 1e8 local maxd = `d'
				if `d' > 1e-9 {
					di as err "A: `sm' net `s' `ty' `cx' differs from R by `d'"
					local ++nfail
				}
				nwdrop rs
			}
		}
		nwdrop rn
	}
}
global NW_SIMMODE
di as txt "A: `ncmp' (network, type, context) combinations equal to the R definition; largest difference `maxd'"

* the same, native kernel against the Mata code, on random networks (binary, valued, negative values, directed or not)
set seed 390
mata:
real matrix n390_rnet(real scalar n, real scalar dens, real scalar kind, real scalar dir)
{
	real matrix M
	M = (runiform(n, n) :< dens)
	if (kind == 1) M = M :* ceil(runiform(n, n) * 5)
	if (kind == 2) M = M :* (round((runiform(n, n) * 20 :- 8) :* 100) :/ 100)
	if (kind == 3) M = M :* round(runiform(n, n) * 4 :- 1)
	_diag(M, J(n, 1, 0))
	if (!dir) {
		M = lowertriangle(M, 0)
		M = M + M'
	}
	return(M)
}
end
local ncmp2 0
local maxd2 0
foreach sm in dense sparse {
	global NW_SIMMODE `sm'
	foreach dens in 0.15 0.03 {
		foreach kind in 0 1 2 3 {
			foreach dir in 0 1 {
				mata: M = n390_rnet(31, `dens', `kind', `dir')
				nwset, mat(M) name(tn) `=cond(`dir', "directed", "undirected")'
				foreach ty in pearson matches jaccard hamming crossproduct euclidean manhatten nonmatches djaccard dhamming {
					foreach cx in both incoming outgoing {
						local cmd = cond(inlist("`ty'", "pearson", "matches", "jaccard", "hamming", "crossproduct"), "nwsimilar", "nwdissimilar")
						local rt = cond("`ty'" == "djaccard", "jaccard", cond("`ty'" == "dhamming", "hamming", "`ty'"))
						global NW_NOFASTKERNELS 1
						qui `cmd' tn, type(`rt') context(`cx') name(s_mata)
						global NW_NOFASTKERNELS
						qui `cmd' tn, type(`rt') context(`cx') name(s_nat)
						qui _nwsyntax s_mata
						mata: A = *`netobj'->get_matrix()
						qui _nwsyntax s_nat
						mata: B = *`netobj'->get_matrix()
						mata: st_local("d", strofreal(max(abs(editmissing(A, -9) :- editmissing(B, -9)))))
						mata: st_local("dm", strofreal(sum((A :>= .) :!= (B :>= .))))
						local ++ncmp2
						if `d' > `maxd2' local maxd2 = `d'
						if `d' > 1e-9 | `dm' > 0 {
							di as err "A: `sm' dens `dens' kind `kind' dir `dir' `ty' `cx': native differs from Mata by `d' (`dm' missing differ)"
							local ++nfail
						}
						nwdrop s_mata s_nat
					}
				}
				nwdrop tn
			}
		}
	}
}
global NW_SIMMODE
* nwcorrelate (the node correlations) in the three contexts
foreach cx in outgoing incoming both {
	mata: M = n390_rnet(25, 0.12, 1, 1)
	nwset, mat(M) name(tn) directed
	global NW_NOFASTKERNELS 1
	qui nwcorrelate tn, name(c_mata) context(`cx')
	global NW_NOFASTKERNELS
	qui nwcorrelate tn, name(c_nat) context(`cx')
	qui _nwsyntax c_mata
	mata: A = *`netobj'->get_matrix()
	qui _nwsyntax c_nat
	mata: B = *`netobj'->get_matrix()
	mata: st_local("d", strofreal(max(abs(editmissing(A, -9) :- editmissing(B, -9)))))
	local ++ncmp2
	if `d' > 1e-9 {
		di as err "A: nwcorrelate context(`cx') native differs from Mata by `d'"
		local ++nfail
	}
	nwdrop c_mata c_nat tn
}
di as txt "A: `ncmp2' native-versus-Mata comparisons; largest difference `maxd2'"
* a network with missing values goes to the Mata code (the result is the Mata result)
mata: M = (0,1,.,0 \ 1,0,2,0 \ 0,3,0,1 \ 1,0,1,0)
nwset, mat(M) name(mm) directed
global NW_NOFASTKERNELS 1
qui nwsimilar mm, type(jaccard) name(a1)
global NW_NOFASTKERNELS
qui nwsimilar mm, type(jaccard) name(a2)
qui _nwsyntax a1
mata: A = *`netobj'->get_matrix()
qui _nwsyntax a2
mata: B = *`netobj'->get_matrix()
mata: st_local("d", strofreal(max(abs(editmissing(A, -9) :- editmissing(B, -9)))))
if `d' > 1e-12 {
	di as err "A: a network with missing values must give the Mata result"
	local ++nfail
}
nwclear

* ---------------------------------------------------------------------------------------------------------
* B. DIRT_LPA+ of nwcommunity, algorithm(dirtlpa)
* ---------------------------------------------------------------------------------------------------------
mata:
// Barber's Q of a membership (modules of the nodes, mode 1 nodes first in the fixture order), from the ties (row, column, weight)
real scalar n390_barber(real matrix t, real colvector mem1, real colvector mem2)
{
	real scalar m, q, k
	real colvector r, c
	m = sum(t[., 3])
	r = J(rows(mem1), 1, 0)
	c = J(rows(mem2), 1, 0)
	for (k = 1; k <= rows(t); k++) {
		r[t[k, 1]] = r[t[k, 1]] + t[k, 3]
		c[t[k, 2]] = c[t[k, 2]] + t[k, 3]
	}
	q = 0
	for (k = 1; k <= rows(t); k++) if (mem1[t[k, 1]] == mem2[t[k, 2]]) q = q + t[k, 3]
	for (k = 1; k <= rows(mem1); k++) q = q - r[k] * sum(c :* (mem2 :== mem1[k])) / m
	return(q / m)
}
end
import delimited using "`fx'/dirt_expected.csv", clear asdouble
mata: DX_n = st_sdata(., "net")
mata: DX_best = st_data(., "rdirt_best")
clear
foreach nm in davis ftdirectors_se {
	import delimited using "`fx'/`nm'_ties.csv", clear asdouble
	mata: TT = st_data(., ("i", "j", "w"))
	qui nwuse data/`nm', nwclear
	qui _nwsyntax `nm'
	mata: MD = strtoreal(`netobj'->get_modes())'
	local reps = cond("`nm'" == "davis", 10, 1)
	foreach sd in 1 2 3 {
		qui nwcommunity `nm', generate(dl) algorithm(dirtlpa) seed(`sd') reps(`reps') replace silent
		local q = r(modularity)
		mata: mem = st_data((1::rows(MD)), "dl")
		mata: st_local("qi", strofreal(n390_barber(TT, select(mem, MD :== 1), select(mem, MD :== 2)), "%21.15g"))
		if abs(`q' - `qi') > 1e-10 {
			di as err "B: `nm' seed `sd': r(modularity) `q' differs from Barber's Q recomputed from the ties `qi'"
			local ++nfail
		}
		if "`nm'" == "davis" {
			mata: st_local("rq", strofreal(select(DX_best, DX_n :== "davis"), "%21.15g"))
		}
		else {
			* no R reference for the whole network (hours of R); the Louvain search of nwcommunity is the reference
			qui nwcommunity `nm', generate(lv) algorithm(louvain) seed(1) starts(30) replace silent
			local rq = r(modularity)
		}
		if `q' < `rq' - 1e-3 {
			di as err "B: `nm' seed `sd': Q `q' is more than .001 below the reference Q `rq'"
			local ++nfail
		}
		if "`nm'" == "davis" & abs(`q' - 0.3455371796) > 1e-8 {
			di as err "B: davis Q `q' is not the known best 0.34554"
			local ++nfail
		}
		* the same seed gives the same modules
		mata: memA = mem
		qui nwcommunity `nm', generate(dl) algorithm(dirtlpa) seed(`sd') reps(`reps') replace silent
		mata: st_local("same", strofreal(all(memA :== st_data((1::rows(MD)), "dl"))))
		if "`same'" != "1" {
			di as err "B: `nm' seed `sd': two runs with the same seed differ"
			local ++nfail
		}
		di as txt "B: `nm' seed `sd': Q `q' (independent `qi'); R best `rq'"
	}
}
* the first 120 directors against bipartite::DIRT_LPA_wb_plus (R: best of 5 runs), the kernel called on the list of ties
import delimited using "`fx'/ft120_ties.csv", clear asdouble
mata: T3 = st_data(., ("i", "j", "w"))
clear
mata: n1 = max(T3[., 1]); n2 = 455; MD3 = (J(n1, 1, 1) \ J(n2, 1, 2)); E3 = (T3[., 1], T3[., 2] :+ n1, T3[., 3])
foreach sd in 1 2 3 {
	mata: AUX = J(1, 4, .); ST = .; R3 = nwg_comb(52, n1 + n2, E3, MD3, (4, 10, `sd'), AUX, ST)
	mata: st_local("q3", strofreal(n390_barber(T3, R3[1::n1], R3[(n1 + 1)::(n1 + n2)]), "%21.15g"))
	mata: st_local("rq3", strofreal(select(DX_best, DX_n :== "ft120"), "%21.15g"))
	mata: st_local("st3", strofreal(ST))
	if `st3' != 0 | `q3' < `rq3' - 1e-3 {
		di as err "B: first 120 directors, seed `sd': Q `q3' against the best Q of bipartite::DIRT_LPA_wb_plus `rq3' (status `st3')"
		local ++nfail
	}
	di as txt "B: first 120 directors, seed `sd': Q `q3'; R best `rq3'"
}
* options and refusals
qui nwuse data/davis, nwclear
capture nwcommunity davis, generate(dl) algorithm(dirtlpa) onemode replace silent
if _rc != 198 {
	di as err "B: algorithm(dirtlpa) with onemode must stop with 198"
	local ++nfail
}
capture nwcommunity davis, generate(dl) algorithm(dirtlpa) resolution(2) replace silent
if _rc != 198 {
	di as err "B: algorithm(dirtlpa) with resolution() must stop with 198"
	local ++nfail
}
capture nwcommunity davis, generate(dl) algorithm(dirtlpa) reps(0) replace silent
if _rc != 198 {
	di as err "B: reps(0) must stop with 198"
	local ++nfail
}
qui nwuse data/florentine, nwclear
capture nwcommunity flomarriage, generate(dl) algorithm(dirtlpa) replace silent
if _rc != 198 {
	di as err "B: algorithm(dirtlpa) on a one-mode network must stop with 198 (got `=_rc')"
	local ++nfail
}

* ---------------------------------------------------------------------------------------------------------
* C. null models of the two-mode nwcug
* ---------------------------------------------------------------------------------------------------------
mata:
real colvector n390_deg(real colvector id, real scalar n)
{
	real colvector d
	real scalar k
	d = J(n, 1, 0)
	for (k = 1; k <= rows(id); k++) d[id[k]] = d[id[k]] + 1
	return(d)
}
end
foreach nm in davis ftdirectors_se {
	qui nwuse data/`nm', nwclear
	qui _nwsyntax `nm'
	mata: MD = strtoreal(`netobj'->get_modes())'; EL = `netobj'->edgelist()
	mata: EL = select(EL, (MD[EL[., 1]] :== 1) :& (MD[EL[., 2]] :== 2) :& (EL[., 3] :!= 0))
	mata: NN = rows(MD); AUX = J(1, 4, .); ST = .
	foreach model in 1 2 3 4 {
		mata: R = nwg_comb(53, NN, EL, MD, (`model', 77 + `model', 4000), AUX, ST)
		mata: ok = (ST == 0 & rows(R) == rows(EL) & cols(R) == 3)
		* cross-mode ties only, no tie twice, the values of the ties are the same multiset
		mata: ok = ok & all(MD[R[., 1]] :== 1) & all(MD[R[., 2]] :== 2) & (rows(uniqrows(R[., 1..2])) == rows(R)) & all(sort(R[., 3], 1) :== sort(EL[., 3], 1))
		mata: d1 = n390_deg(EL[., 1], NN); d2 = n390_deg(EL[., 2], NN); e1 = n390_deg(R[., 1], NN); e2 = n390_deg(R[., 2], NN)
		if `model' == 2 | `model' == 4 mata: ok = ok & all(d1 :== e1)
		if `model' == 3 | `model' == 4 mata: ok = ok & all(d2 :== e2)
		* the ties moved
		mata: ok = ok & (sum((R[., 1] :* 100000 :+ R[., 2]) :== (EL[., 1] :* 100000 :+ EL[., 2])) < rows(EL))
		mata: st_local("ok", strofreal(ok))
		if "`ok'" != "1" {
			di as err "C: `nm' model `model': the draw breaks a constraint of its null model"
			local ++nfail
		}
	}
}
* the null distribution of a statistic against vegan::nullmodel (r00, r0, c0, curveball), 1,000 draws of nw2nested
import delimited using "`fx'/cug_expected.csv", clear asdouble
mata: CX_m = st_sdata(., "model")
mata: CX_mean = st_data(., "mean")
mata: CX_sd = st_data(., "sd")
clear
qui nwuse data/davis, nwclear
mata: st_local("robs", strofreal(select(CX_mean, CX_m :== "observed"), "%21.15g"))
foreach cond in density mode1degree mode2degree degrees {
	local vm = cond("`cond'" == "density", "r00", cond("`cond'" == "mode1degree", "r0", cond("`cond'" == "mode2degree", "c0", "curveball")))
	qui nwcug davis, stat(nw2nested ##net##) rname(nodf) reps(1000) seed(5) condition(`cond') silent
	local mn = r(mean_null)
	local sdn = r(sd_null)
	local ob = r(obs)
	mata: st_local("rm", strofreal(select(CX_mean, CX_m :== "`vm'")))
	mata: st_local("rs", strofreal(select(CX_sd, CX_m :== "`vm'")))
	local tol = 4 * sqrt(`sdn'^2 / 1000 + `rs'^2 / 3000)
	if abs(`mn' - `rm') > `tol' | abs(`ob' - `robs') > 1e-6 | abs(`sdn' / `rs' - 1) > 0.2 {
		di as err "C: `cond': null mean `mn' (sd `sdn') against vegan `vm' mean `rm' (sd `rs'), tolerance `tol'; observed `ob' against `robs'"
		local ++nfail
	}
	di as txt "C: `cond': null mean `=round(`mn', .001)' (sd `=round(`sdn', .001)'); vegan `vm' `=round(`rm', .001)' (`=round(`rs', .001)')"
}
* the same seed gives the same draws; the active data set is not touched
local n0 = _N
gen keepme = _n
qui nwcug davis, stat(nw2nested ##net##) rname(nodf) reps(30) seed(9) condition(degrees) silent
local a = r(mean_null)
qui nwcug davis, stat(nw2nested ##net##) rname(nodf) reps(30) seed(9) condition(degrees) silent
if abs(`a' - r(mean_null)) > 1e-12 {
	di as err "C: the same seed must give the same null distribution"
	local ++nfail
}
capture confirm variable keepme
if _rc | _N != `n0' {
	di as err "C: nwcug changed the active data set"
	local ++nfail
}
capture nwcug davis, stat(nw2nested ##net##) rname(nodf) reps(5) condition(census)
if _rc != 198 {
	di as err "C: condition(census) on a two-mode network must stop with 198"
	local ++nfail
}
qui nwuse data/florentine, nwclear
capture nwcug flomarriage, stat(nwdegree ##net##) rname(mean) reps(5) condition(degrees)
if _rc != 198 {
	di as err "C: condition(degrees) on a one-mode network must stop with 198 (got `=_rc')"
	local ++nfail
}
nwclear

* ---------------------------------------------------------------------------------------------------------
* D. weighted Kamada-Kawai sweeps (kernel 54, _nwwlayout): the Mata layout from the same start coordinates
* ---------------------------------------------------------------------------------------------------------
mata:
real matrix n390_rw(real scalar n, real scalar dens)
{
	real matrix M
	M = (runiform(n, n) :< dens) :* ceil(runiform(n, n) * 9)
	_diag(M, J(n, 1, .))
	M = lowertriangle(M, 0)
	M = M + M'
	_diag(M, J(n, 1, .))
	return(M)
}
end
foreach n in 10 60 300 {
	local dd = cond(`n' == 10, 0.4, 4 / `n')
	mata: P = n390_rw(`n', `dd'); P0 = runiform(`n', 2)
	global NW_NOFASTKERNELS 1
	qui _nwwlayout, pmat(P) method(kk) iterations(30) out(L1) start(P0)
	global NW_NOFASTKERNELS
	qui _nwwlayout, pmat(P) method(kk) iterations(30) out(L2) start(P0)
	mata: st_local("d", strofreal(max(abs(L1 :- L2))))
	if `d' > 1e-9 {
		di as err "D: weighted kk, `n' nodes: native layout differs from the Mata layout by `d'"
		local ++nfail
	}
	di as txt "D: weighted kk, `n' nodes: largest coordinate difference `d'"
}

* dialogs of the commands that gained options
foreach c in nwcommunity nwcug nwsimilar nwdissimilar nwcorrelate {
	capture db `c'
	if _rc {
		di as err "dialog `c' does not open (rc `=_rc')"
		local ++nfail
	}
}

if `nfail' > 0 {
	di as err "native390: `nfail' FAILURES"
	exit 9
}
di as txt "native390: all equal"
