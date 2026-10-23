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
	real scalar n, nd, code, k, i, j, ok, w, Z, s1, s2
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
		else if (kind == "none") ok = 1
		if (!ok) continue
		s1 = directed ? sum(A) : sum(A) / 2
		if (directed) s2 = sum(A :* A') / 2
		else s2 = trace(A * A * A) / 6
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
end

capture program drop e6run
program define e6run
	args kind theta1 theta2 maxd
	mata: th = (`theta1', `theta2')
	mata: ex = e6_exact(st_matrix("A0"), G.directed, "`kind'", th, (G.has_dyadmask ? G.freedyadmat : J(rows(st_matrix("A0")), rows(st_matrix("A0")), 1)), `maxd')
	mata: st_numscalar("e6_nstates", rows(ex))
	mata: smp = ErgmMCMCSample(M, G, th, 2000, 20, 100000, &ergm_propose_tnt())
	mata: st_numscalar("e6_maxz", e6_compare(smp, ex, "`kind'"))
	mata: st_numscalar("e6_acc", M.native_lastaccept)
end

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
	if scalar(e6_maxz) > 4.5 {
		di as err "FAIL: `c' max |z| = " scalar(e6_maxz)
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
	if scalar(e6_maxz) > 4.5 {
		di as err "FAIL: `c' max |z| = " scalar(e6_maxz)
		local failed 1
	}
}
if `failed' == 0 di "PASS nwergm constraints exact enumeration (undirected)"
else exit 9
