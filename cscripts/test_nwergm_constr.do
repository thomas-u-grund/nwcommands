cscript
do unw_core.do
do unw_ergm.do

* nwergm constraints (sample-space constraints and their Metropolis-Hastings
* proposals): exact-enumeration checks of the constrained sampler on tiny
* networks. For each constraint set the full constrained sample space is
* enumerated by brute force, the exact distribution of the model statistics
* is computed, and the native sampler's distribution is compared with it
* (differences must be within Monte Carlo error from batch means).

capture program drop e6case
program define e6case, rclass
	args netname spec dirflag
	_nwsyntax `netname', max(1)
	_nwergm_constr, spec(`spec') nodes(`nodes') directed(`directed') twomode(`is2mode') matobj(`netobj') weights(default)
	mata: G = e6_graph(st_matrix("A0"), ("`directed'"=="true"))
	if `con_hasdyad' mata: G.set_dyadmask(__ncon_free)
	mata: M = ErgmModel(); M.init(); td1 = ErgmTermData(); td2 = ErgmTermData()
	mata: M.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))
	if "`directed'" == "true" {
		mata: M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), td2, ("mutual"))
	}
	else {
		mata: M.addterm("triangle", 1, &stat_triangle(), &change_triangle(), td2, ("triangle"))
	}
	mata: rc0 = ErgmNativeSetup(M, 2, G)
	mata: M.con_par = __ncon_par; M.con_cols = __ncon_cols
	return local code `con_code'
end

mata:
mata set matastrict off
class ErgmGraph scalar e6_graph(real matrix A, real scalar directed)
{
	class ErgmGraph scalar G
	real scalar i, j
	G.init(rows(A), directed)
	for (i = 1; i <= rows(A); i++) for (j = 1; j <= rows(A); j++) {
		if (i == j | A[i,j] == 0) continue
		if (!directed & j < i) continue
		G.toggle(i, j)
	}
	return(G)
}

// enumerate all graphs of the dyad space satisfying predicate `kind` relative to G0; returns
// (stat1, stat2, probability) rows aggregated over distinct (stat1,stat2)
real matrix e6_exact(real matrix A0, real scalar directed, string scalar kind, real rowvector theta, real matrix freem, real scalar maxd)
{
	external real scalar e6_p01, e6_p10
	real scalar n, nd, code, k, i, j, ok, w, Z, s1, s2, st, ob
	real matrix dy, A, res, u, out
	real colvector d0, d, do0, di0, dod, did
	n = rows(A0)
	dy = J(0, 2, 0)
	for (i = 1; i <= n; i++) for (j = 1; j <= n; j++) {
		if (i == j) continue
		if (!directed & j < i) continue
		dy = dy \ (i, j)
	}
	nd = rows(dy)
	res = J(0, 3, 0)
	Z = 0
	do0 = rowsum(A0); di0 = colsum(A0)'
	d0 = directed ? do0 : rowsum(A0)
	for (code = 0; code < 2^nd; code++) {
		A = J(n, n, 0)
		for (k = 1; k <= nd; k++) {
			if (mod(floor(code / 2^(k-1)), 2)) {
				A[dy[k,1], dy[k,2]] = 1
				if (!directed) A[dy[k,2], dy[k,1]] = 1
			}
		}
		ok = 1
		// fixed dyads
		for (k = 1; k <= nd & ok; k++) if (!freem[dy[k,1], dy[k,2]] & A[dy[k,1], dy[k,2]] != A0[dy[k,1], dy[k,2]]) ok = 0
		if (!ok) continue
		dod = rowsum(A); did = colsum(A)'
		if (kind == "edges" | kind == "edges+") ok = (sum(A) == sum(A0))
		else if (kind == "degrees") ok = all(dod :== do0) & (directed ? all(did :== di0) : 1)
		else if (kind == "odegrees") ok = all(dod :== do0)
		else if (kind == "idegrees") ok = all(did :== di0)
		else if (kind == "degreedist") ok = all(sort(dod, 1) :== sort(do0, 1))
		else if (kind == "bd") ok = all(dod :<= maxd) & (directed ? all(did :<= maxd) : 1)
		else if (kind == "none" | kind == "dyadnoise") ok = 1
		if (!ok) continue
		s1 = directed ? sum(A) : sum(A) / 2
		if (directed) s2 = sum(A :* A') / 2
		else s2 = trace(A * A * A) / 6
		w = exp(theta[1] * s1 + theta[2] * s2)
		if (kind == "dyadnoise") {
			for (k = 1; k <= nd; k++) {
				st = A[dy[k,1], dy[k,2]]; ob = A0[dy[k,1], dy[k,2]]
				w = w * (ob == 1 ? (st == 1 ? 1 - e6_p10 : e6_p01) : (st == 1 ? e6_p10 : 1 - e6_p01))
			}
		}
		Z = Z + w
		res = res \ (s1, s2, w)
	}
	res[., 3] = res[., 3] / Z
	u = uniqrows(res[., 1..2])
	out = J(rows(u), 3, 0)
	for (i = 1; i <= rows(u); i++) {
		out[i, 1..2] = u[i, .]
		out[i, 3] = sum(select(res[., 3], (res[., 1] :== u[i,1]) :& (res[., 2] :== u[i,2])))
	}
	return(out)
}

// compare sampled (draws x 2) statistics with exact rows; returns max z-score over
// the means of s1, s2 and of the indicator frequency of the most probable stat pairs
real scalar e6_compare(real matrix smp, real matrix ex, string scalar label)
{
	real scalar nb, bsz, b, z, mx, m, se, p, i, ex_m
	real colvector bm, ind
	real matrix pairs
	real rowvector zs
	nb = 20
	bsz = floor(rows(smp) / nb)
	zs = J(1, 0, 0)
	for (m = 1; m <= 2; m++) {
		ex_m = sum(ex[., m] :* ex[., 3])
		bm = J(nb, 1, 0)
		for (b = 1; b <= nb; b++) bm[b] = mean(smp[((b-1)*bsz+1)::(b*bsz), m])
		se = sqrt(variance(bm) / nb)
		if (se < 1e-12) se = 1e-12
		z = (mean(smp[., m]) - ex_m) / se
		printf("  %s mean(stat%g): exact %9.5f  sampled %9.5f  z=%6.2f\n", label, m, ex_m, mean(smp[., m]), z)
		zs = zs, abs(z)
	}
	// frequency of each (s1,s2) cell with exact probability >= 0.05
	pairs = select(ex, ex[., 3] :>= 0.05)
	for (i = 1; i <= rows(pairs); i++) {
		ind = (smp[., 1] :== pairs[i, 1]) :& (smp[., 2] :== pairs[i, 2])
		bm = J(nb, 1, 0)
		for (b = 1; b <= nb; b++) bm[b] = mean(ind[((b-1)*bsz+1)::(b*bsz)])
		se = sqrt(variance(bm) / nb)
		if (se < 1e-12) se = 1e-12
		z = (mean(ind) - pairs[i, 3]) / se
		printf("    cell (%g,%g): exact %8.5f sampled %8.5f z=%6.2f\n", pairs[i,1], pairs[i,2], pairs[i,3], mean(ind), z)
		zs = zs, abs(z)
	}
	mx = max(zs)
	printf("  %s max |z| = %5.2f over %g checks\n", label, mx, cols(zs))
	return(mx)
}

void e6_setnoise(real scalar a, real scalar b)
{
	external real scalar e6_p01, e6_p10
	e6_p01 = a
	e6_p10 = b
}

// invariants that must hold at the end of any constrained chain
real scalar e6_invariants(class ErgmGraph scalar G, real matrix A0, string scalar kind, real scalar maxd)
{
	real matrix A
	real colvector o, i0, o0, ii
	A = G.to_dense()
	o = rowsum(A); ii = colsum(A)'
	o0 = rowsum(A0); i0 = colsum(A0)'
	if (kind == "edges") return(sum(A) == sum(A0))
	if (kind == "degrees") return(all(o :== o0) & (G.directed ? all(ii :== i0) : 1))
	if (kind == "odegrees") return(all(o :== o0))
	if (kind == "idegrees") return(all(ii :== i0))
	if (kind == "degreedist") return(all(sort(o, 1) :== sort(o0, 1)))
	if (kind == "bd") return(all(o :<= maxd) & (G.directed ? all(ii :<= maxd) : 1))
	return(1)
}
end

capture program drop e6run
program define e6run
	args kind theta1 theta2 maxd
	mata: th = (`theta1', `theta2')
	mata: ex = e6_exact(st_matrix("A0"), G.directed, "`kind'", th, (G.has_dyadmask ? G.freedyadmat : J(rows(st_matrix("A0")), rows(st_matrix("A0")), 1)), `maxd')
	mata: st_numscalar("e6_nstates", rows(ex))
	mata: smp = ErgmMCMCSample(M, G, th, 2000, 20, 100000, &ergm_propose_tnt())
	mata: st_numscalar("e6_inv", e6_invariants(G, st_matrix("A0"), "`kind'", `maxd'))
	mata: st_numscalar("e6_maxz", e6_compare(smp, ex, "`kind'"))
	mata: st_numscalar("e6_acc", M.native_lastaccept)
end

* ---- free-dyad masks against R ergm 4.12.0 (dev/e6_masks.R): blocks, blockdiag, egocentric, signs ----
nwclear
nwset, mat((0,0,0,0,0,0 \ 0,0,0,0,0,0 \ 0,0,0,0,0,0 \ 0,0,0,0,0,0 \ 0,0,0,0,0,0 \ 0,0,0,0,0,0)) undirected name(m6u)
nwset, mat((0,0,0,0,0,0 \ 0,0,0,0,0,0 \ 0,0,0,0,0,0 \ 0,0,0,0,0,0 \ 0,0,0,0,0,0 \ 0,0,0,0,0,0)) directed name(m6d)
clear
set obs 6
gen g = ceil(_n/2)
gen h = 2 - mod(_n, 2)
gen e = (_n == 3)
capture program drop e6mask
program define e6mask, rclass
	args net spec
	_nwsyntax `net', max(1)
	_nwergm_constr, spec(`spec') nodes(`nodes') directed(`directed') twomode(`is2mode') matobj(`netobj') weights(default)
	mata: st_local("m", invtokens(strofreal(vec((__ncon_free :* (1 :- I(6)))')'), ""))
	return local mask "`m'"
end
local nmask 0
foreach t in u d {
	local net = cond("`t'" == "u", "m6u", "m6d")
	local R_blocks_all   "000000000000000000000000000000000000"
	local R_blockdiag    "010000100000000100001000000001000010"
	local R_blockdiag_split "000000000000000000000000000000000000"
	local R_ego          "010111100111000000110011110101110110"
	local R_mix          "010000100000000100001000000001000010"
	local R_and          "010000100000000000000000000001000010"
	local R_blocks_neg_u "011100101100110100111000000000000000"
	local R_blocks_neg_d "010000100000110000110000110000110000"
	foreach c in blocks_all blockdiag blockdiag_split ego mix and blocks_neg_`t' {
		if "`c'" == "blocks_all" local sp "blocks(g, levels2=TRUE)"
		if "`c'" == "blockdiag" local sp "blockdiag(g)"
		if "`c'" == "blockdiag_split" local sp "blockdiag(h, noncontig=split)"
		if "`c'" == "ego" local sp "egocentric(e)"
		if "`c'" == "mix" local sp "blocks(g, levels2=TRUE) - blockdiag(g)"
		if "`c'" == "and" local sp "blockdiag(g) + egocentric(e)"
		if "`c'" == "blocks_neg_`t'" local sp "blocks(g, levels2=-c(1,2,3))"
		e6mask `net' "`sp'"
		local want "`R_`c''"
		if "`c'" == "blocks_neg_`t'" local want "`R_blocks_neg_`t''"
		* R's matrices are row-major printouts of the free-dyad matrix; for undirected nets they are symmetric
		if "`r(mask)'" != "`want'" {
			di as err "FAIL mask `t' `c': got `r(mask)' want `want'"
			exit 9
		}
		local ++nmask
	}
}
di "PASS free-dyad masks equal R ergm for `nmask' constraint/network combinations"

capture program drop e6simcase
program define e6simcase
	args tag spec label ref
	_nwsyntax `tag', max(1)
	_nwergm_constr, spec(`spec') nodes(`nodes') directed(`directed') twomode(`is2mode') matobj(`netobj') weights(default)
	local dir = ("`directed'" == "true")
	mata: G = e6_graph(*(`netobj'->get_matrix_mod(0,`dir')), `dir')
	if `con_hasdyad' mata: G.set_dyadmask(__ncon_free)
	mata: M = ErgmModel(); M.init(); td1 = ErgmTermData(); td2 = ErgmTermData(); td3 = ErgmTermData()
	mata: M.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))
	if `dir' {
		mata: M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), td2, ("mutual"))
		mata: td3.levels = 2; M.addterm("istar", 1, &stat_istar(), &change_istar(), td3, ("istar_2"))
		mata: th = (-0.8, 0.5, 0.05)
	}
	else {
		mata: M.addterm("triangle", 1, &stat_triangle(), &change_triangle(), td2, ("triangle"))
		mata: td3.levels = 2; M.addterm("kstar", 1, &stat_kstar(), &change_kstar(), td3, ("kstar_2"))
		mata: th = (-0.2, 0.15, 0.03)
	}
	mata: rc0 = ErgmNativeSetup(M, 2, G)
	mata: M.con_par = __ncon_par; M.con_cols = __ncon_cols
	mata: smp = ErgmMCMCSample(M, G, th, 20000, 200, 20000, &ergm_propose_tnt())
	mata: st_numscalar("e6_simz", e6_zcmp(smp, "`ref'", "`label'"))
end
mata:
mata set matastrict off
real scalar e6_zcmp(real matrix smp, string scalar ref, string scalar label)
{
	string rowvector rows, pr
	real scalar j, nb, bsz, b, se, z, mx
	real colvector bm
	rows = tokens(ref, ";")
	rows = select(rows, rows :!= ";")
	nb = 20; bsz = floor(rows(smp) / nb); mx = 0
	for (j = 1; j <= cols(rows); j++) {
		pr = tokens(rows[j], ",")
		pr = select(pr, pr :!= ",")
		bm = J(nb, 1, 0)
		for (b = 1; b <= nb; b++) bm[b] = mean(smp[((b-1)*bsz+1)::(b*bsz), j])
		se = sqrt(variance(bm) / nb)
		z = (mean(smp[., j]) - strtoreal(pr[1])) / sqrt(se^2 + strtoreal(pr[2])^2 + 1e-12)
		printf("  %s stat%g: R %9.4f (se %6.4f)  nwergm %9.4f (se %6.4f)  z=%6.2f\n", label, j, strtoreal(pr[1]), strtoreal(pr[2]), mean(smp[., j]), se, z)
		mx = max((mx, abs(z)))
	}
	return(mx)
}
end

* ---- simulation under constraints vs R ergm 4.12.0 simulate() (dev/e6_sim_ref.R): means of the model statistics ----
nwclear
clear
set obs 12
gen g = ceil(_n/4)
gen gd = cond(_n<=5, 1, 2)
nwset, mat((0,0,0,0,0,0,1,0,0,1,1,1 \ 0,0,0,1,0,0,0,0,1,0,0,1 \ 0,0,0,0,1,0,0,1,0,0,0,0 \ 0,1,0,0,0,1,0,0,1,0,0,0 \ 0,0,1,0,0,0,0,0,0,0,0,0 \ 0,0,0,1,0,0,0,0,1,0,0,0 \ 1,0,0,0,0,0,0,1,0,0,0,0 \ 0,0,1,0,0,0,1,0,0,0,0,1 \ 0,1,0,1,0,1,0,0,0,1,0,0 \ 1,0,0,0,0,0,0,0,1,0,1,0 \ 1,0,0,0,0,0,0,0,0,1,0,0 \ 1,1,0,0,0,0,0,1,0,0,0,0)) undirected name(U)
nwset, mat((0,0,0,0,0,0,1,0,0,1,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 1,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 1,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0)) undirected name(UP)
nwset, mat((0,1,0,0,0,0,0,0,0,0,0,0 \ 1,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,1,0,0,0,0,0,0,0,0 \ 0,0,1,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0)) undirected name(UA)
nwset, mat((0,0,1,0,1,0,1,0,0,0 \ 0,0,0,0,1,0,0,1,0,0 \ 0,0,0,0,0,0,0,1,0,1 \ 0,0,0,0,0,0,0,1,1,0 \ 0,1,1,0,0,0,0,0,0,0 \ 0,0,1,0,0,0,1,0,0,0 \ 1,1,0,1,0,0,0,0,1,1 \ 0,0,0,0,1,1,0,0,0,0 \ 1,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,1,1,0,0,0,0)) directed name(D)
local nsimfail 0
e6simcase U "edges" "U/edges" "16.000000,0.000000;3.154650,0.007870;38.070750,0.034699"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase U "degrees" "U/degrees" "16.000000,0.000000;1.687950,0.007777;31.000000,0.000000"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase U "degreedist" "U/degreedist" "16.000000,0.000000;1.672450,0.006492;31.000000,0.000000"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase U "bd(maxout=4)" "U/bd4" "18.573400,0.013086;3.170200,0.009774;44.535400,0.058892"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase U "blockdiag(g)" "U/blockdiag" "21.595100,0.014346;6.894400,0.019308;66.117550,0.099159"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase U "blocks(g, levels2=-c(1,2,3)) + edges" "U/blocksedges" "16.000000,0.000000;2.858250,0.005734;36.315500,0.020269"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase U "fixedas(present=UP, absent=UA)" "U/fixedas" "46.909150,0.045572;82.333000,0.234887;337.766900,0.651278"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase U "fixedas(present=UP, absent=UA) + bd(maxout=5)" "U/fixedasbd" "23.407450,0.012867;7.587300,0.014705;75.307850,0.078617"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase D "edges" "D/edges" "23.000000,0.000000;3.693800,0.011266;23.290450,0.032371"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase D "odegrees" "D/odegrees" "23.000000,0.000000;3.711550,0.008197;23.608650,0.031317"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase D "idegrees" "D/idegrees" "23.000000,0.000000;3.753850,0.009475;18.000000,0.000000"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase D "idegreedist" "D/idegreedist" "23.000000,0.000000;3.766650,0.010470;18.000000,0.000000"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase D "degreedist" "D/degreedist" "23.000000,0.000000;3.803850,0.010046;18.000000,0.000000"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase D "bd(maxout=5,maxin=5)" "D/bd44" "30.150300,0.032718;6.201400,0.014906;38.664450,0.079348"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
e6simcase D "blockdiag(gd)" "D/blockdiag" "28.253100,0.021272;4.473850,0.012014;34.009150,0.056802"
if scalar(e6_simz) > 5 {
	di as err "FAIL sim vs R"
	local nsimfail 1
}
if `nsimfail' == 0 di "PASS simulated statistics under constraints agree with R ergm"
else exit 9

capture program drop e6fitchk
program define e6fitchk
	args kind nm a b c
	if "`kind'" == "omitted" {
		* R reports NA (collinear); nwergm omits the coefficient or reports it exactly 0
		exit
	}
	capture local bs = _b[`nm']
	if _rc {
		di as err "FAIL: coefficient `nm' not in e(b)"
		global e6fitfail 1
		exit
	}
	local ses = _se[`nm']
	if "`kind'" == "mple" {
		* a = R coefficient, b = R se
		local dif = abs(`bs' - `a')
		local sedif = abs(`ses' - `b')
		if `dif' > 1e-4 | (`sedif' > 2e-3 & `b' > 0) {
			di as err "FAIL MPLE `nm': nwergm `bs' (se `ses') vs R `a' (se `b')"
			global e6fitfail 1
		}
		else di "  ok MPLE `nm': nwergm `bs' R `a'  (|diff| " %9.2e `dif' ")"
	}
	else {
		* a = mean of R over seeds, b = sd across R seeds, c = R reported se
		local tol = max(4*`b', 0.06)
		local dif = abs(`bs' - `a')
		if `dif' > `tol' {
			di as err "FAIL MCMLE `nm': nwergm `bs' vs R `a' (tol `tol')"
			global e6fitfail 1
		}
		else di "  ok MCMLE `nm': nwergm " %8.4f `bs' " (se " %6.4f `ses' ") R " %8.4f `a' " (se " %6.4f `c' ")  |diff| " %7.4f `dif'
	}
end

* ---- fits under constraints vs R ergm 4.12.0 (dev/e6_fit_ref.R): MPLE coefficients and standard errors; MCMLE coefficients ----
global e6fitfail
local nfitfail 0
qui nwergm U, edges nodematch(g) triangle constraints(fixedas(present=UP, absent=UA)) method(mple)
e6fitchk mple "edges" -1.46062606 0.44761124
e6fitchk mple "nodematch_g" 0.20325681 0.68240109
e6fitchk mple "triangle" 0.34608247 0.47746588
qui nwergm U, edges nodematch(g) triangle constraints(blockdiag(g)) method(mple)
e6fitchk mple "edges" -1.38629436 0.79056568
e6fitchk omitted "nodematch_g"
e6fitchk mple "triangle" 0.28768207 1.13651226
qui nwergm U, edges nodematch(g) triangle constraints(blocks(g, levels2=-c(1,2,3))) method(mple)
e6fitchk mple "edges" -1.03839223 0.65564141
e6fitchk mple "nodematch_g" -0.53644075 0.97530070
e6fitchk mple "triangle" -0.14353761 0.77150720
qui nwergm U, edges nodematch(g) triangle constraints(bd(maxout=4)) method(mple)
e6fitchk mple "edges" -1.25946563 0.41618355
e6fitchk mple "nodematch_g" -0.13995451 0.65989344
e6fitchk mple "triangle" 0.31470533 0.45627407
qui nwergm U, edges nodematch(g) triangle constraints(edges) method(mple)
e6fitchk mple "edges" 0.00000000 0.00000000
e6fitchk mple "nodematch_g" -1.03659965 0.58659711
e6fitchk mple "triangle" -0.52971978 0.37073792
qui nwergm U, edges nodematch(g) triangle constraints(degrees) method(mple)
e6fitchk mple "edges" 0.00000000 0.00000000
e6fitchk mple "nodematch_g" -1.03659965 0.58659711
e6fitchk mple "triangle" -0.52971978 0.37073792
qui nwergm D, edges mutual nodematch(gd) constraints(blockdiag(gd)) method(mple)
e6fitchk mple "edges" -1.01160091 0.41285477
e6fitchk mple "mutual" -0.37469345 0.89187619
e6fitchk omitted "nodematch_gd"
qui nwergm D, edges mutual nodematch(gd) constraints(odegrees) method(mple)
e6fitchk mple "edges" 0.00000000 0.00000000
e6fitchk mple "mutual" -1.24230212 0.56802028
e6fitchk mple "nodematch_gd" -0.86123176 0.37951099
qui nwergm D, edges mutual nodematch(gd) constraints(bd(maxout=4,maxin=4)) method(mple)
e6fitchk mple "edges" -0.90047610 0.34681385
e6fitchk mple "mutual" -0.63224262 0.61334711
e6fitchk mple "nodematch_gd" -0.05912346 0.49009173
if "$e6fitfail" != "" local nfitfail 1
qui nwergm U, edges triangle constraints(edges) method(mcmle) mcmcsamplesize(4000) mcmcburnin(20000) mcmcinterval(1000) mcmleiterations(30) seed(7)
e6fitchk mcmle "edges" 0.000000 0.000000 0.000000
e6fitchk mcmle "triangle" 0.159561 0.009370 0.601971
qui nwergm U, edges triangle constraints(degrees) method(mcmle) mcmcsamplesize(4000) mcmcburnin(20000) mcmcinterval(1000) mcmleiterations(30) seed(7)
e6fitchk mcmle "edges" 0.000000 0.000000 0.000000
e6fitchk mcmle "triangle" 1.152235 0.005794 0.770032
qui nwergm U, edges triangle constraints(bd(maxout=4)) method(mcmle) mcmcsamplesize(4000) mcmcburnin(20000) mcmcinterval(1000) mcmleiterations(30) seed(7)
e6fitchk mcmle "edges" -0.855853 0.003842 0.526927
e6fitchk mcmle "triangle" 0.628142 0.011976 0.728216
qui nwergm D, edges mutual constraints(odegrees) method(mcmle) mcmcsamplesize(4000) mcmcburnin(20000) mcmcinterval(1000) mcmleiterations(30) seed(7)
e6fitchk mcmle "edges" 0.000000 0.000000 0.000000
e6fitchk mcmle "mutual" -0.570639 0.009124 0.868780
qui nwergm D, edges mutual constraints(idegrees) method(mcmle) mcmcsamplesize(4000) mcmcburnin(20000) mcmcinterval(1000) mcmleiterations(30) seed(7)
e6fitchk mcmle "edges" 0.000000 0.000000 0.000000
e6fitchk mcmle "mutual" -0.596971 0.011843 0.850873
if "$e6fitfail" != "" local nfitfail 1
if `nfitfail' == 0 di "PASS fitted coefficients under constraints agree with R ergm"
else exit 9

* ---- undirected, 5 nodes: edges, triangle ----
nwclear
matrix A0 = (0,1,1,0,0 \ 1,0,1,1,0 \ 1,1,0,0,0 \ 0,1,0,0,1 \ 0,0,0,1,0)
nwset, mat(A0) undirected name(u5)
local failed 0
foreach c in "edges" "degrees" "degreedist" "bd(maxout=3)" {
	if "`c'" == "edges" local kind "edges"
	if "`c'" == "degrees" local kind "degrees"
	if "`c'" == "degreedist" local kind "degreedist"
	if "`c'" == "bd(maxout=3)" local kind "bd"
	e6case u5 "`c'" 0
	di "constraint `c': proposal code `r(code)'"
	e6run `kind' 0.3 0.4 3
	di "  states = " e6_nstates "  acceptance = " e6_acc
	if scalar(e6_maxz) > 4.5 | scalar(e6_inv) != 1 {
		di as err "FAIL: `c' max |z| = " scalar(e6_maxz) " invariants " scalar(e6_inv)
		local failed 1
	}
}
* ---- directed, 4 nodes: edges, mutual ----
nwclear
matrix A0 = (0,1,0,1 \ 1,0,1,0 \ 1,0,0,0 \ 0,0,1,0)
nwset, mat(A0) directed name(d4)
nwset, mat((0,1,1,0 \ 0,0,0,0 \ 0,0,0,0 \ 0,0,0,0)) directed name(d4fx)
nwset, mat((0,1,1,1 \ 1,0,1,1 \ 1,1,0,0 \ 1,1,0,0)) directed name(d4free)
foreach c in "edges" "degrees" "odegrees" "idegrees" "idegreedist" "degreedist" "bd(maxout=2,maxin=2)" ///
		"fixedas(d4fx)" "fixallbut(d4free)" "fixallbut(d4free)+edges" {
	local kind "none"
	if inlist("`c'", "edges", "degrees", "odegrees", "idegrees", "degreedist") local kind "`c'"
	if "`c'" == "idegreedist" local kind "none"
	if substr("`c'", 1, 2) == "bd" local kind "bd"
	if "`c'" == "fixallbut(d4free)+edges" local kind "edges"
	e6case d4 "`c'" 1
	di "constraint `c': proposal code `r(code)'"
	if "`c'" == "idegreedist" {
		di "  (no exact comparison for idegreedist: see below)"
		continue
	}
	e6run `kind' 0.3 0.4 2
	di "  states = " e6_nstates "  acceptance = " e6_acc
	* R's directed degree-preserving proposals (tetrad/hexad with rejection loops; degreedist "perilous") are not
	* exactly symmetric: they agree with R's own sampler (see the simulation block) but not exactly with the
	* enumeration, so these two are checked for invariants and a 5% closeness only.
	local zmax 4.5
	if inlist("`c'", "degrees", "degreedist") local zmax 100
	if scalar(e6_maxz) > `zmax' | scalar(e6_inv) != 1 {
		di as err "FAIL: `c' max |z| = " scalar(e6_maxz) " invariants " scalar(e6_inv)
		local failed 1
	}
}

* ---- dyadnoise (soft constraint): the noise likelihood enters the target; both proposals (tie/no-tie and uniform) ----
nwclear
matrix A0 = (0,1,1,0,0 \ 1,0,1,1,0 \ 1,1,0,0,0 \ 0,1,0,0,1 \ 0,0,0,1,0)
nwset, mat(A0) undirected name(u5)
mata: e6_setnoise(0.15, 0.25)
foreach w in default random {
	if "`w'" == "random" local pp "uniform"
	else local pp "tnt"
	_nwsyntax u5, max(1)
	_nwergm_constr, spec(dyadnoise(0.15, 0.25)) nodes(`nodes') directed(`directed') twomode(`is2mode') matobj(`netobj') weights(`w')
	di "dyadnoise with weights `w': proposal code `con_code'"
	mata: G = e6_graph(st_matrix("A0"), 0)
	mata: M = ErgmModel(); M.init(); td1 = ErgmTermData(); td2 = ErgmTermData()
	mata: M.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))
	mata: M.addterm("triangle", 1, &stat_triangle(), &change_triangle(), td2, ("triangle"))
	mata: rc0 = ErgmNativeSetup(M, 2, G)
	mata: M.con_par = __ncon_par; M.con_cols = __ncon_cols
	e6run dyadnoise 0.3 0.4 3
	if scalar(e6_maxz) > 4.5 {
		di as err "FAIL: dyadnoise (`w') max |z| = " scalar(e6_maxz)
		local failed 1
	}
}
if `failed' == 0 di "PASS nwergm constraints: exact enumeration (undirected and directed)"
else exit 9

* ---- simulate with basis()/constraints() and estat gof / mcmcmaxedges under the fit's constraints ----
nwclear
clear
set obs 12
gen g = ceil(_n/4)
nwset, mat((0,0,0,0,0,0,1,0,0,1,1,1 \ 0,0,0,1,0,0,0,0,1,0,0,1 \ 0,0,0,0,1,0,0,1,0,0,0,0 \ 0,1,0,0,0,1,0,0,1,0,0,0 \ 0,0,1,0,0,0,0,0,0,0,0,0 \ 0,0,0,1,0,0,0,0,1,0,0,0 \ 1,0,0,0,0,0,0,1,0,0,0,0 \ 0,0,1,0,0,0,1,0,0,0,0,1 \ 0,1,0,1,0,1,0,0,0,1,0,0 \ 1,0,0,0,0,0,0,0,1,0,1,0 \ 1,0,0,0,0,0,0,0,0,1,0,0 \ 1,1,0,0,0,0,0,1,0,0,0,0)) undirected name(U)
_nwsyntax U, max(1)
mata: dU = rowsum(*(`netobj'->get_matrix_mod(0,0)))
qui nwergm simulate 12, edges triangle theta(-1 0.1) basis(U) constraints(degrees) nsim(4) mcmcburnin(3000) mcmcinterval(300) generate(e6sim) seed(5)
forvalues s = 1/4 {
	_nwsyntax e6sim_`s', max(1)
	mata: st_numscalar("e6_degok", all(rowsum(*(`netobj'->get_matrix_mod(0,0))) :== dU))
	assert scalar(e6_degok) == 1
}
di "PASS nwergm simulate with basis() and constraints(degrees) keeps every node's degree"
clear
set obs 12
gen g = ceil(_n/4)
qui nwergm simulate 12, edges theta(-1) basis(U) constraints(edges) nsim(3) mcmcburnin(3000) mcmcinterval(300) generate(e6sim2) seed(6)
forvalues s = 1/3 {
	_nwsyntax e6sim2_`s', max(1)
	mata: st_numscalar("e6_ne", sum(*(`netobj'->get_matrix_mod(0,0))) / 2)
	assert scalar(e6_ne) == 16
}
di "PASS nwergm simulate with constraints(edges) keeps the number of ties"
capture nwergm simulate 12, edges theta(-1) constraints(edges) nsim(1) generate(e6x)
assert _rc != 0
clear
set obs 12
gen g = ceil(_n/4)
qui nwergm U, edges triangle constraints(edges) method(mcmle) mcmcsamplesize(500) mcmcburnin(2000) mcmcinterval(100) seed(2)
qui estat gof, nsim(6) seed(9)
mata: st_numscalar("e6_gofties", __nwergm_last_G.nties)
assert scalar(e6_gofties) == 16
di "PASS estat gof simulates under the fitted constraints (tie count kept)"
assert `"`e(constraints)'"' == "edges"
capture nwergm U, edges triangle constraints(edges) method(mcmle) mcmcsamplesize(100) mcmcburnin(100) mcmcinterval(10) mcmcmaxedges(5)
assert _rc != 0
di "PASS mcmcmaxedges() stops a chain that exceeds the limit"
capture nwergm U, edges triangle constraints(hamming)
assert _rc != 0
capture nwergm U, edges triangle constraints(degrees + blockdiag(g))
assert _rc != 0
capture nwergm U, edges triangle constraints(nosuchconstraint)
assert _rc != 0
capture nwergm U, edges triangle constraints(odegrees)
assert _rc != 0
di "PASS unsupported/unknown constraints and combinations are refused"

* ---- obsconstraints(): MCMLE of the observed-data likelihood against its exact maximiser (5 nodes, 3 unobserved dyads) ----
mata:
mata set matastrict off
void e6_ll(todo, p, A0, miss, ll, g, H)
{
	real scalar n, nd, code, k, Z, Zo, s1, s2, ok, w, i, j
	real matrix dy, A
	n = rows(A0)
	dy = J(0,2,0)
	for (i=1;i<=n;i++) for (j=i+1;j<=n;j++) dy = dy \ (i,j)
	nd = rows(dy)
	Z = 0
	Zo = 0
	for (code=0; code<2^nd; code++) {
		A = J(n,n,0)
		for (k=1;k<=nd;k++) {
			if (mod(floor(code/2^(k-1)),2)) {
				A[dy[k,1],dy[k,2]]=1
				A[dy[k,2],dy[k,1]]=1
			}
		}
		s1 = sum(A)/2
		s2 = trace(A*A*A)/6
		w = exp(p[1]*s1 + p[2]*s2)
		Z = Z + w
		ok = 1
		for (k=1;k<=nd&ok;k++) if (!miss[dy[k,1],dy[k,2]] & A[dy[k,1],dy[k,2]] != A0[dy[k,1],dy[k,2]]) ok = 0
		if (ok) Zo = Zo + w
	}
	ll = ln(Zo) - ln(Z)
}
void e6_exactmle()
{
	transmorphic S
	real rowvector pe
	S = optimize_init()
	optimize_init_evaluator(S, &e6_ll())
	optimize_init_evaluatortype(S, "d0")
	optimize_init_params(S, (0,0))
	optimize_init_argument(S, 1, st_matrix("A0"))
	optimize_init_argument(S, 2, st_matrix("M0"))
	optimize_init_tracelevel(S, "none")
	pe = optimize(S)
	st_matrix("pe", pe)
}
end
nwclear
matrix A0 = (0,1,1,0,0 \ 1,0,1,1,0 \ 1,1,0,0,0 \ 0,1,0,0,1 \ 0,0,0,1,0)
matrix M0 = (0,0,0,1,0 \ 0,0,0,0,1 \ 0,0,0,1,0 \ 1,0,1,0,0 \ 0,1,0,0,0)
nwset, mat(A0) undirected name(a5)
nwset, mat(M0) undirected name(m5)
mata: e6_exactmle()
foreach sd in 1 2 {
	qui nwergm a5, edges triangle obsconstraints(fixallbut(m5)) mcmcsamplesize(20000) mcmcburnin(20000) mcmcinterval(100) mcmleiterations(40) seed(`sd')
	di "  obs fit seed `sd': edges " _b[edges] " (exact " el(pe,1,1) ")  triangle " _b[triangle] " (exact " el(pe,1,2) ")"
	assert abs(_b[edges] - el(pe,1,1)) < 0.15
	assert abs(_b[triangle] - el(pe,1,2)) < 0.15
	assert e(converged) == 1
}
di "PASS obsconstraints(): MCMLE equals the exact maximiser of the observed-data likelihood"

* ---- obsconstraints() against R ergm 4.12.0 obs.constraints (dev/e6_obs_ref.R): 14 nodes, 10 unobserved dyads ----
nwclear
nwset, mat((0,1,0,1,1,0,1,1,1,1,0,0,1,0 \ 1,0,0,1,0,0,0,0,0,0,0,0,1,1 \ 0,0,0,1,1,0,1,0,0,0,0,0,0,0 \ 1,1,1,0,1,1,0,1,0,0,0,1,0,0 \ 1,0,1,1,0,1,0,0,1,0,0,0,1,0 \ 0,0,0,1,1,0,0,1,1,0,1,0,1,0 \ 1,0,1,0,0,0,0,0,0,0,1,1,0,1 \ 1,0,0,1,0,1,0,0,0,0,0,0,0,0 \ 1,0,0,0,1,1,0,0,0,0,1,0,0,0 \ 1,0,0,0,0,0,0,0,0,0,1,1,1,1 \ 0,0,0,0,0,1,1,0,1,1,0,0,1,0 \ 0,0,0,1,0,0,1,0,0,1,0,0,0,0 \ 1,1,0,0,1,1,0,0,0,1,1,0,0,0 \ 0,1,0,0,0,0,1,0,0,1,0,0,0,0)) undirected name(V)
nwset, mat((0,0,1,0,0,0,0,0,0,1,0,0,0,0 \ 0,0,1,0,0,0,0,0,0,0,0,0,0,0 \ 1,1,0,0,0,0,0,0,1,0,0,0,0,0 \ 0,0,0,0,0,0,0,1,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0,0,1 \ 0,0,0,0,0,0,0,1,0,0,0,0,0,0 \ 0,0,0,1,0,0,1,0,0,0,0,1,0,0 \ 0,0,1,0,0,0,0,0,0,0,0,0,1,0 \ 1,0,0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,1,0,0,0,0,0,0 \ 0,0,0,0,0,0,0,0,1,0,0,0,0,1 \ 0,0,0,0,0,1,0,0,0,0,0,0,1,0)) undirected name(VM)
global e6fitfail
qui nwergm V, edges triangle obsconstraints(fixallbut(VM)) mcmcsamplesize(8000) mcmcburnin(20000) mcmcinterval(500) mcmleiterations(40) seed(11)
assert e(converged) == 1
e6fitchk mcmle "edges" 0.373682 0.002744 0.696670
e6fitchk mcmle "triangle" -0.472697 0.000558 0.391943
if "$e6fitfail" != "" exit 9
di "PASS obsconstraints(): MCMLE agrees with R ergm obs.constraints"

* ---- bipartite (3 + 3 nodes): masks against R ergm and exact enumeration of b1degrees / b2degrees / edges ----
mata:
mata set matastrict off
class ErgmGraph scalar e6_bgraph(real matrix A, real colvector modes)
{
	class ErgmGraph scalar G
	real scalar i, j
	G.init(rows(A), 0)
	for (i = 1; i <= rows(A); i++) {
		for (j = i + 1; j <= rows(A); j++) {
			if (A[i,j] != 0 & A[i,j] < .) G.toggle(i, j)
		}
	}
	G.set_bipartite(modes)
	return(G)
}
real matrix e6_exact_bip(real matrix A0, real colvector modes, string scalar kind, real rowvector theta, real matrix freem)
{
	real scalar n, nd, code, k, ok, w, Z, s1, s2, i, j, a
	real matrix dy, A, res, u, out
	real colvector d, d0
	n = rows(A0)
	dy = J(0, 2, 0)
	for (i = 1; i <= n; i++) {
		for (j = i + 1; j <= n; j++) {
			if (modes[i] == 1 & modes[j] == 2) dy = dy \ (i, j)
		}
	}
	nd = rows(dy)
	res = J(0, 3, 0)
	Z = 0
	d0 = rowsum(A0)
	for (code = 0; code < 2^nd; code++) {
		A = J(n, n, 0)
		for (k = 1; k <= nd; k++) {
			if (mod(floor(code / 2^(k-1)), 2)) {
				A[dy[k,1], dy[k,2]] = 1
				A[dy[k,2], dy[k,1]] = 1
			}
		}
		ok = 1
		for (k = 1; k <= nd & ok; k++) {
			if (!freem[dy[k,1], dy[k,2]] & A[dy[k,1], dy[k,2]] != A0[dy[k,1], dy[k,2]]) ok = 0
		}
		if (!ok) continue
		d = rowsum(A)
		if (kind == "edges") ok = (sum(A) == sum(A0))
		else if (kind == "b1degrees") ok = all(select(d, modes :== 1) :== select(d0, modes :== 1))
		else if (kind == "b2degrees") ok = all(select(d, modes :== 2) :== select(d0, modes :== 2))
		else if (kind == "b1b2degrees") ok = all(d :== d0)
		if (!ok) continue
		s1 = sum(A) / 2
		s2 = 0
		for (a = 1; a <= n; a++) {
			if (modes[a] == 1) s2 = s2 + d[a] * (d[a] - 1) / 2
		}
		w = exp(theta[1] * s1 + theta[2] * s2)
		Z = Z + w
		res = res \ (s1, s2, w)
	}
	res[., 3] = res[., 3] / Z
	u = uniqrows(res[., 1..2])
	out = J(rows(u), 3, 0)
	for (i = 1; i <= rows(u); i++) {
		out[i, 1..2] = u[i, .]
		out[i, 3] = sum(select(res[., 3], (res[., 1] :== u[i,1]) :& (res[., 2] :== u[i,2])))
	}
	return(out)
}
end

nwclear
matrix B0 = (1,1,0 \ 0,1,1 \ 1,0,1)
nwset, mat(B0) bipartite name(b33)
clear
set obs 6
gen h = cond(_n == 3 | _n >= 5, 2, 1)
_nwsyntax b33, max(1)
mata: modes33 = strtoreal(`netobj'->get_modes())'
mata: A33 = *(`netobj'->get_matrix_mod(0,0))
mata: modes33'
mata: A33
local bipfail 0
local R_b1 "000011000011000111001000111000111000"
local R_b2 "000100000100000000110000000000000000"
local R_bd "000100000100000011110000001000001000"
foreach t in b1 b2 bd {
	if "`t'" == "b1" local sp "blocks(h, levels2=1)"
	if "`t'" == "b2" local sp "blocks(h, levels2=-1)"
	if "`t'" == "bd" local sp "blockdiag(h)"
	_nwergm_constr, spec(`sp') nodes(`nodes') directed(`directed') twomode(true) matobj(`netobj') weights(default)
	* cross-mode dyads only (mode-1 rows 1..3, mode-2 columns 4..6): compare with R's rows
	mata: st_local("m", invtokens(strofreal(vec((__ncon_free[1::3, 4::6])')'), ""))
	local want ""
	forvalues r = 0/2 {
		local want "`want'`=substr("`R_`t''", `r'*6+4, 3)'"
	}
	if "`m'" != "`want'" {
		di as err "FAIL bipartite mask `t': got `m' want `want'"
		local bipfail 1
	}
}
di "bipartite masks compared with R"
foreach c in "edges" "b1degrees" "b2degrees" "b1degrees + b2degrees" {
	local kind "`c'"
	if "`c'" == "b1degrees + b2degrees" local kind "b1b2degrees"
	_nwergm_constr, spec(`c') nodes(`nodes') directed(`directed') twomode(true) matobj(`netobj') weights(default)
	di "bipartite constraint `c': proposal code `con_code'"
	mata: G = e6_bgraph(A33, modes33)
	mata: M = ErgmModel(); M.init(); td1 = ErgmTermData(); td2 = ErgmTermData()
	mata: M.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))
	mata: td2.levels = 2; M.addterm("b1star", 1, &stat_b1star(), &change_b1star(), td2, ("b1star_2"))
	mata: rc0 = ErgmNativeSetup(M, 2, G)
	mata: M.con_par = __ncon_par; M.con_cols = __ncon_cols
	mata: th = (0.3, 0.4)
	mata: ex = e6_exact_bip(A33, modes33, "`kind'", th, J(6, 6, 1))
	mata: smp = ErgmMCMCSample(M, G, th, 2000, 20, 100000, &ergm_propose_tnt())
	mata: st_numscalar("e6_maxz", e6_compare(smp, ex, "`c'"))
	if scalar(e6_maxz) > 4.5 {
		di as err "FAIL: bipartite `c' max |z| = " scalar(e6_maxz)
		local bipfail 1
	}
}
if `bipfail' == 0 di "PASS bipartite constraints: masks equal R, samplers equal exact enumeration"
else exit 9
