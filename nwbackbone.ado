*! nwbackbone: backbone extraction for valued networks and bipartite projections: global, disparity, lans, mlf, sdsm, fdsm, fixedrow, fixedcol, fixedfill (3.28.0)
capture program drop nwbackbone
program nwbackbone, rclass
	version 15
	syntax [anything(name=netname)] , Method(string) [ALpha(real 0.05) THReshold(numlist min=1 max=2) MTC(string) ///
		SIGned KEEPvalues MISSingaszero Project(integer 1) TRIals(integer 0) seed(integer -1) GENerate(string) replace silent]

	local method = lower("`method'")
	_opts_oneof "global disparity lans mlf sdsm fdsm fixedrow fixedcol fixedfill" "method" "`method'"
	local weighted = inlist("`method'", "global", "disparity", "lans", "mlf")
	if "`mtc'" == "" local mtc "none"
	if !inlist("`mtc'", "none", "holm", "hochberg", "hommel", "bonferroni", "BH", "BY", "fdr") {
		di "{err}mtc() must be one of {bf:none holm hochberg hommel bonferroni BH BY fdr}."
		exit 198
	}
	if `alpha' < 0 | `alpha' > 1 {
		di "{err}alpha() must be a number between 0 and 1."
		exit 198
	}
	if "`method'" == "global" {
		if "`threshold'" == "" {
			di "{err}{bf:method(global)} needs the option {bf:threshold()}: ties with a value above it are kept (two numbers keep the ties above the larger one as +1 and the ties below the smaller one as -1)."
			exit 198
		}
		if "`signed'" != "" {
			di "{err}{bf:signed} is not available with {bf:method(global)}; give two numbers in {bf:threshold()} for a signed backbone."
			exit 198
		}
		if "`mtc'" != "none" {
			di "{err}{bf:mtc()} is not available with {bf:method(global)}, which tests nothing."
			exit 198
		}
	}
	else if "`threshold'" != "" {
		di "{err}{bf:threshold()} is only for {bf:method(global)}."
		exit 198
	}
	if "`method'" != "fdsm" & `trials' != 0 {
		di "{err}{bf:trials()} is only for {bf:method(fdsm)}."
		exit 198
	}
	if `trials' < 0 {
		di "{err}trials() must be a positive integer."
		exit 198
	}
	if `project' != 1 & `project' != 2 {
		di "{err}project() must be 1 or 2."
		exit 198
	}

	_nwsyntax `netname', max(1)
	if `nodes' < 3 {
		di "{err}The network needs at least 3 nodes."
		exit 198
	}
	if `weighted' {
		if "`is2mode'" == "true" {
			di "{err}{p 0 0 2}{bf:method(`method')} extracts the backbone of a one-mode valued network; {bf:`netname'} is two-mode. Use {bf:sdsm}, {bf:fdsm}, {bf:fixedrow}, {bf:fixedcol} or {bf:fixedfill} for its projection, or make a weighted projection first ({help nwproject}).{p_end}"
			exit 198
		}
		if `project' != 1 {
			di "{err}{bf:project()} is only for a two-mode network."
			exit 198
		}
	}
	else {
		if "`is2mode'" != "true" {
			di "{err}{p 0 0 2}{bf:method(`method')} extracts the backbone of the projection of a two-mode network; {bf:`netname'} is one-mode. Use {bf:global}, {bf:disparity}, {bf:lans} or {bf:mlf} for a valued one-mode network.{p_end}"
			exit 198
		}
	}
	local name "`generate'"
	if "`name'" == "" local name "backbone"
	if `seed' != -1 set seed `seed'

	// the data
	nwtomatafast `netname'
	local srcmata "`r(mata)'"
	local trh = 0
	local tr1 = 0
	local tr2 = 0
	if "`threshold'" != "" {
		local tr1 : word 1 of `threshold'
		local tr2 : word 2 of `threshold'
		if "`tr2'" == "" local tr2 = `tr1'
		else if `tr2' > `tr1' {
			local tmp = `tr1'
			local tr1 = `tr2'
			local tr2 = `tmp'
		}
		local trh : word count `threshold'
	}
	tempname M tri nm
	mata: `M' = editmissing(`srcmata', 0)
	if `weighted' {
		mata: st_local("isbin", strofreal(all((`M' :== 0) :| (`M' :== 1))))
		mata: st_local("hasneg", strofreal(min(`M') < 0))
		mata: st_local("nonint", strofreal(any(`M' :!= floor(`M'))))
		if `isbin' {
			mata: mata drop `M'
			di "{err}{p 0 0 2}The network {bf:`netname'} holds only the tie values 0 and 1; a backbone of a valued network needs tie values (for a binary network from a two-mode network see {bf:sdsm} and the other projection methods).{p_end}"
			exit 198
		}
		if `hasneg' & "`method'" != "global" {
			mata: mata drop `M'
			di "{err}{bf:method(`method')} needs non-negative tie values."
			exit 198
		}
		if `nonint' & "`method'" == "mlf" {
			mata: mata drop `M'
			di "{err}{bf:method(mlf)} models tie values as counts and needs integer tie values."
			exit 198
		}
		mata: `nm' = `netobj'->get_nodenames()
		local nn = `nodes'
		local dirflag = ("`directed'" == "true")
	}
	else {
		mata: st_local("isbin", strofreal(all((`M' :== 0) :| (`M' :== 1))))
		if !`isbin' {
			mata: mata drop `M'
			di "{err}{p 0 0 2}{bf:method(`method')} needs a binary two-mode network (affiliation matrix); the network {bf:`netname'} has tie values other than 0 and 1.{p_end}"
			exit 198
		}
		mata: `nm' = `netobj'->get_nodenames()
		mata: nw_bb_selmodes(`netobj'->get_modes(), `project', `M', `nm')
		mata: st_local("nn", strofreal(rows(`M')))
		if `nn' < 3 {
			mata: mata drop `M' `nm'
			di "{err}Mode `project' of the network has fewer than 3 nodes."
			exit 198
		}
		local dirflag = 0
	}

	// the backbone
	local mz = ("`missingaszero'" != "")
	local sg = ("`signed'" != "")
	local trg = `trials'
	mata: `tri' = nw_backbone(`M', "`method'", `alpha', "`mtc'", `sg', `mz', `trg', `tr1', `tr2', `trh', `dirflag', "`keepvalues'" != "")
	mata: st_local("nstat", strofreal(rows(`tri')))
	mata: mata drop `M'

	// the new network
	nwvalidate `name'
	if "`r(exists)'" == "true" {
		if "`replace'" == "" {
			mata: mata drop `tri' `nm'
			di "{err}{p 0 0 2}Network `name' already exists. Specify option {bf:replace} to overwrite it.{p_end}"
			exit 483
		}
		nwdrop `name'
	}
	local und = cond(`dirflag', "", "undirected")
	_nwsetsparse, triplets(`tri') nodes(`nn') name(`name') nodenames(`nm') `und'
	_nwsyntax `name'
	local prov "backbone (`method') of network `netname'"
	if `weighted' == 0 local prov "`prov', mode `project'"
	if "`method'" == "global" local prov "`prov', threshold `threshold'"
	else local prov "`prov', alpha `alpha', mtc `mtc'"
	mata: `netobj'->set_provenance(`"`prov'"')
	capture mata: mata drop `tri' `nm'

	local pct = .
	if `nin' > 0 local pct = 100 * (`nin' - `nout') / `nin'
	return local network "`netname'"
	return local backbone "`name'"
	return local method "`method'"
	return local mtc "`mtc'"
	return scalar alpha = `alpha'
	return scalar nodes = `nn'
	return scalar ties_in = `nin'
	return scalar ties = `nout'
	return scalar removed = `pct'
	if "`method'" == "fdsm" return scalar trials = `ntrials'
	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network name: {res}`netname'"
		di "{txt}  Backbone network: {res}`name'{txt} (`nn' nodes)"
		if `weighted' == 0 di "{txt}  Projection of mode: {res}`project'"
		di "{txt}  Method: {res}`method'" _c
		if "`method'" == "global" di "{txt}, threshold {res}`threshold'"
		else if "`method'" == "fdsm" di "{txt}, alpha {res}`alpha'{txt}, multiple-testing correction {res}`mtc'{txt}, Monte Carlo draws {res}`ntrials'"
		else di "{txt}, alpha {res}`alpha'{txt}, multiple-testing correction {res}`mtc'"
		di "{txt}  Ties tested: {res}`nin'{txt}; kept: {res}`nout'{txt} (" %4.1f `pct' "{txt}% removed)"
	}
end

capture mata: mata drop nw_bb_selmodes()
capture mata: mata drop nw_backbone()
capture mata: mata drop nw_bb_pvals()
capture mata: mata drop nw_bb_retain()
capture mata: mata drop nw_bb_adjustmat()
capture mata: mata drop nw_bb_padjust()
capture mata: mata drop nw_bb_pmin()
capture mata: mata drop nw_bb_setmiss()
capture mata: mata drop nw_bb_bicm()
capture mata: mata drop nw_bb_bicm_core()
capture mata: mata drop nw_bb_rna()
capture mata: mata drop nw_bb_fdsm()
capture mata: mata drop nw_bb_ntrials()
capture mata: mata drop nw_bb_fixedfill()
capture mata: mata drop nw_bb_lans()
capture mata: mata drop nw_bb_cummax()
capture mata: mata drop nw_bb_ord()
capture mata: mata drop nw_bb_hypcdf()
capture mata: mata drop nw_bb_hyptail()
mata:
// Replaces the n x n matrix M by the incidence block of the chosen mode (rows: the nodes of mode `mode', columns:
// the nodes of the other mode) and nm by the names of the chosen mode.
void nw_bb_selmodes(string rowvector modes, real scalar mode, real matrix M, string rowvector nm)
{
	real colvector s1, s2
	s1 = selectindex(modes :== strofreal(mode))'
	s2 = selectindex(modes :!= strofreal(mode))'
	M = M[s1, s2]
	nm = nm[1, s1']
}

// stable ascending order of p (ties by position)
real colvector nw_bb_ord(real colvector p, real scalar desc)
{
	real scalar n
	n = rows(p)
	if (desc) return(order((-p, (1::n)), (1, 2)))
	return(order((p, (1::n)), (1, 2)))
}

real colvector nw_bb_cummax(real colvector x)
{
	real colvector y
	real scalar i
	y = x
	for (i = 2; i <= rows(y); i++) if (y[i] < y[i-1]) y[i] = y[i-1]
	return(y)
}

// elementwise minimum, missing if either is missing
real matrix nw_bb_pmin(real matrix X, real matrix Y)
{
	real matrix Z
	Z = (X :< Y) :* X + (X :>= Y) :* Y
	return(Z)
}

void nw_bb_setmiss(real matrix X, real matrix mask)
{
	real scalar j
	real colvector i
	for (j = 1; j <= cols(X); j++) {
		i = selectindex(mask[., j])
		if (rows(i) > 0) X[i, j] = J(rows(i), 1, .)
	}
}

// R's p.adjust for a vector without missing values (n = its length)
real colvector nw_bb_padjust(real colvector p, string scalar method)
{
	real scalar n, m, q1, qq
	real colvector o, ro, ix, v, pp, q, pa, v1
	real rowvector i1, i2
	n = rows(p)
	if (n <= 1) return(p)
	if (method == "fdr") method = "BH"
	if (n == 2 & method == "hommel") method = "hochberg"
	ix = (1::n)
	if (method == "bonferroni") {
		v = p :* n
		return(v :* (v :<= 1) :+ (v :> 1))
	}
	if (method == "holm") {
		o = nw_bb_ord(p, 0)
		ro = order(o, 1)
		v = nw_bb_cummax((n :+ 1 :- ix) :* p[o])
		v = v :* (v :<= 1) :+ (v :> 1)
		return(v[ro])
	}
	if (method == "hochberg" | method == "BH" | method == "BY") {
		o = nw_bb_ord(p, 1)
		ro = order(o, 1)
		// i = n, n-1, ..., 1 along the descending order
		if (method == "hochberg") v = (1::n) :* p[o]
		else {
			qq = 1
			if (method == "BY") qq = sum(1 :/ (1::n))
			v = (n :/ (n :+ 1 :- ix)) :* qq :* p[o]
		}
		// cumulative minimum
		for (m = 2; m <= n; m++) if (v[m] > v[m-1]) v[m] = v[m-1]
		v = v :* (v :<= 1) :+ (v :> 1)
		return(v[ro])
	}
	// hommel
	o = nw_bb_ord(p, 0)
	ro = order(o, 1)
	pp = p[o]
	q = pa = J(n, 1, min(n :* pp :/ ix))
	for (m = n - 1; m >= 2; m--) {
		i1 = 1..(n - m + 1)
		i2 = (n - m + 2)..n
		q1 = min(m :* pp[i2'] :/ (2::m))
		q[i1'] = nw_bb_pmin(m :* pp[i1'], J(rows(i1'), 1, q1))
		q[i2'] = J(rows(i2'), 1, q[n - m + 1])
		pa = (pa :>= q) :* pa + (pa :< q) :* q
	}
	v = (pa :>= pp) :* pa + (pa :< pp) :* pp
	return(v[ro])
}

// p.adjust over the non-missing cells of a matrix (column-major order as in R)
real matrix nw_bb_adjustmat(real matrix U, string scalar mtc)
{
	real colvector v, idx, a
	real matrix R
	real scalar j, m
	m = rows(U)
	v = vec(U)
	idx = selectindex(v :< .)
	if (rows(idx) == 0) return(U)
	a = nw_bb_padjust(v[idx], mtc)
	v[idx] = a
	R = U
	for (j = 1; j <= cols(U); j++) R[., j] = v[((j - 1) * m + 1)::(j * m)]
	return(R)
}

// the retained ties (1; with sgn: 1 upper tail, -1 lower tail) from the upper (and lower) p-values
real matrix nw_bb_retain(real matrix upper, real matrix lower, real scalar sgn, real scalar alpha, string scalar mtc)
{
	real matrix U, B, ut, neg
	real scalar i, j, n, sym
	n = rows(upper)
	if (!sgn) {
		U = upper
		for (i = 1; i <= n; i++) U[i, i] = .
		if (mtc != "none") {
			sym = all(U :== U')
			if (sym) for (j = 2; j <= n; j++) for (i = 1; i < j; i++) U[i, j] = .
			U = nw_bb_adjustmat(U, mtc)
			if (sym) for (j = 2; j <= n; j++) for (i = 1; i < j; i++) U[i, j] = U[j, i]
		}
		return(U :< alpha)
	}
	alpha = alpha / 2
	U = nw_bb_pmin(upper, lower)
	for (i = 1; i <= n; i++) U[i, i] = .
	neg = (upper :>= lower) :& (upper :< .) :& (lower :< .)
	for (i = 1; i <= n; i++) neg[i, i] = 0
	if (mtc != "none") {
		sym = all(U :== U')
		if (sym) for (j = 2; j <= n; j++) for (i = 1; i < j; i++) U[i, j] = .
		U = nw_bb_adjustmat(U, mtc)
		if (sym) for (j = 2; j <= n; j++) for (i = 1; i < j; i++) U[i, j] = U[j, i]
	}
	B = (U :< alpha)
	return(B :* (1 :- 2 :* neg))
}

// Poisson-binomial tail by the refined normal approximation of the R package backbone (.pb), all pairs at once.
// P = observed counts, probs = row x column probabilities; lower = 1 asks also for the lower tail
void nw_bb_rna(real matrix P, real matrix probs, real scalar sgn, real matrix upper, real matrix lower)
{
	real matrix p2, p3, mu, s2, gm, sg, x
	p2 = probs :^ 2
	p3 = probs :^ 3
	mu = probs * probs'
	s2 = mu - p2 * p2'
	gm = mu - 3 :* (p2 * p2') + 2 :* (p3 * p3')
	sg = sqrt(s2)
	x = (P :- 1 :+ 0.5 :- mu) :/ sg
	upper = normal(-x) - gm :/ (6 :* sg :^ 3) :* (1 :- x :^ 2) :* normalden(x)
	upper = upper :* (upper :>= 0) :* (upper :<= 1) :+ (upper :> 1)
	if (sgn) {
		x = (P :+ 0.5 :- mu) :/ sg
		lower = normal(x) + gm :/ (6 :* sg :^ 3) :* (1 :- x :^ 2) :* normalden(x)
		lower = lower :* (lower :>= 0) :* (lower :<= 1) :+ (lower :> 1)
	}
}

// maximum likelihood of the bipartite configuration model with the degrees of the rows and columns of the incidence
// matrix M (no zero or full degrees); fixed point iteration over the classes of equal degree. Returns the tie
// probabilities.
real matrix nw_bb_bicm_core(real matrix M)
{
	real colvector dr, dc, ur, uc, mr, mc, x, y, gx, gy, ir, ic, sr, sc
	real scalar nr, nc, it, E, err
	real matrix W
	dr = rowsum(M)
	dc = colsum(M)'
	E = sum(dr)
	ur = uniqrows(dr)
	uc = uniqrows(dc)
	nr = rows(ur)
	nc = rows(uc)
	mr = J(nr, 1, 0)
	mc = J(nc, 1, 0)
	ir = J(rows(dr), 1, 0)
	ic = J(rows(dc), 1, 0)
	for (it = 1; it <= nr; it++) {
		ir = ir + (dr :== ur[it]) :* it
		mr[it] = sum(dr :== ur[it])
	}
	for (it = 1; it <= nc; it++) {
		ic = ic + (dc :== uc[it]) :* it
		mc[it] = sum(dc :== uc[it])
	}
	x = ur :/ (sqrt(E) + 1)
	y = uc :/ (sqrt(E) + 1)
	for (it = 1; it <= 100000; it++) {
		// Gauss-Seidel: rows then columns
		W = 1 :/ (1 :+ x * y')
		x = ur :/ (W * (mc :* y))
		W = 1 :/ (1 :+ x * y')
		y = uc :/ (W' * (mr :* x))
		if (mod(it, 5) == 0 | it < 5) {
			W = (x * y') :/ (1 :+ x * y')
			gx = ur - W * mc
			gy = uc - W' * mr
			err = max((max(abs(gx)), max(abs(gy))))
			if (err < 1e-12) break
		}
	}
	x = x[ir]
	y = y[ic]
	W = x * y'
	return(W :/ (1 :+ W))
}

// BICM probabilities with the structural zeros and ones removed first (as backbone::bicm)
real matrix nw_bb_bicm(real matrix M)
{
	real matrix probs, rb
	real colvector gr, gc, fr, fc, keepr, keepc
	real scalar nr, nc, removed
	nr = rows(M)
	nc = cols(M)
	probs = J(nr, nc, 0)
	gr = (1::nr)
	gc = (1::nc)
	rb = M
	while (rows(rb) > 0 & cols(rb) > 0) {
		removed = 0
		keepr = selectindex(rowsum(rb) :> 0)
		keepc = selectindex(colsum(rb)' :> 0)
		if (rows(keepr) < rows(rb) | rows(keepc) < cols(rb)) {
			removed = 1
			rb = rb[keepr, keepc]
			gr = gr[keepr]
			gc = gc[keepc]
			if (rows(rb) == 0 | cols(rb) == 0) break
		}
		fr = selectindex(rowsum(rb) :== cols(rb))
		fc = selectindex(colsum(rb)' :== rows(rb))
		if (rows(fr) > 0) probs[gr[fr], gc] = J(rows(fr), rows(gc), 1)
		if (rows(fc) > 0) probs[gr, gc[fc]] = J(rows(gr), rows(fc), 1)
		if (rows(fr) + rows(fc) > 0) {
			removed = 1
			keepr = selectindex(rowsum(rb) :< cols(rb))
			keepc = selectindex(colsum(rb)' :< rows(rb))
			rb = rb[keepr, keepc]
			gr = gr[keepr]
			gc = gc[keepc]
		}
		if (!removed) break
	}
	if (rows(rb) > 0 & cols(rb) > 0) probs[gr, gc] = nw_bb_bicm_core(rb)
	return(probs)
}

// FDSM: Monte Carlo p-values of the projection counts under uniformly random binary matrices with the observed
// margins (curveball trades, 5 per row of the shorter dimension between draws)
void nw_bb_fdsm(real matrix I, real matrix P, real scalar trials, real scalar sgn, real matrix upper, real matrix lower)
{
	real matrix X, Pst
	real scalar rot, t, k, a, b, na, nb, nr
	real rowvector ra, rb, ia, ib
	real colvector u, pu
	rot = (rows(I) > cols(I))
	X = rot ? I' : I
	nr = rows(X)
	upper = J(rows(P), cols(P), 0)
	lower = J(rows(P), cols(P), 0)
	for (t = 1; t <= trials; t++) {
		for (k = 1; k <= 5 * nr; k++) {
			a = ceil(uniform(1, 1) * nr)
			b = ceil(uniform(1, 1) * (nr - 1))
			if (b >= a) b++
			ra = X[a, .]
			rb = X[b, .]
			ia = selectindex(ra :& !rb)
			ib = selectindex(rb :& !ra)
			na = cols(ia)
			nb = cols(ib)
			if (na == 0 | nb == 0) continue
			u = jumble((ia, ib)')
			X[a, .] = (ra :& rb)
			X[b, .] = (ra :& rb)
			X[a, u[1::na]'] = J(1, na, 1)
			X[b, u[(na + 1)::(na + nb)]'] = J(1, nb, 1)
		}
		Pst = rot ? cross(X, X) : X * X'
		upper = upper + (Pst :>= P)
		if (sgn) lower = lower + (Pst :<= P)
	}
	upper = upper :/ trials
	lower = lower :/ trials
}

// default number of FDSM draws (backbone:::.fdsm)
real scalar nw_bb_ntrials(real matrix P, real scalar alpha, string scalar mtc, real scalar sgn, real scalar mz)
{
	real scalar ta, tests, p1, p2, d, qu, pbar, v1, v2, nn
	ta = sgn ? alpha / 2 : alpha
	if (mtc != "none") {
		tests = mz ? rows(P) * (rows(P) - 1) / 2 : (sum(P :!= 0) - sum(diagonal(P) :!= 0)) / 2
		ta = ta / tests
	}
	p1 = ta * (1 - alpha)
	p2 = ta
	d = abs(p1 - p2)
	qu = invnormal(1 - alpha)
	pbar = (p1 + p2) / 2
	v1 = p1 * (1 - p1)
	v2 = p2 * (1 - p2)
	nn = ((qu * sqrt(2 * pbar * (1 - pbar)) + invnormal(1 - alpha) * sqrt(v1 + v2)) / d) :^ 2
	return(ceil(nn / 2))
}

// fixed fill model (Neal, Domagalski and Sagan 2021): exact distribution of the common neighbours of two rows
void nw_bb_fixedfill(real matrix I, real matrix P, real scalar sgn, real matrix upper, real matrix lower)
{
	real scalar m, n, f, maxw, k, lb, ub, r, s, k2
	real colvector probs, cu, cl
	m = rows(I)
	n = cols(I)
	f = sum(I)
	maxw = max(P)
	probs = J(maxw + 2, 1, 0)
	for (k = 0; k <= maxw; k++) {
		lb = max((0, n + k - f))
		ub = min((n - k, (m - 1) * n + k - f))
		s = 0
		for (r = lb; r <= ub; r++) {
			s = s + exp(ln(2) * (n - k - r) + lnfactorial(n) - lnfactorial(k) - lnfactorial(r) - lnfactorial(n - k - r) ///
				+ lnfactorial((m - 2) * n) - lnfactorial(f - n - k + r) - lnfactorial((m - 2) * n - (f - n - k + r)) ///
				- (lnfactorial(m * n) - lnfactorial(f) - lnfactorial(m * n - f)))
		}
		probs[k + 1] = s
	}
	probs[maxw + 2] = 1 - sum(probs[1::(maxw + 1)])
	// upper[k] = sum(probs[(k+1):(maxw+2)]), lower[k] = sum(probs[1:(k+1)])
	cu = J(maxw + 2, 1, 0)
	cl = J(maxw + 2, 1, 0)
	cu[maxw + 2] = probs[maxw + 2]
	for (k2 = maxw + 1; k2 >= 1; k2--) cu[k2] = cu[k2 + 1] + probs[k2]
	cl[1] = probs[1]
	for (k2 = 2; k2 <= maxw + 2; k2++) cl[k2] = cl[k2 - 1] + probs[k2]
	upper = J(rows(P), cols(P), .)
	lower = J(rows(P), cols(P), .)
	for (k2 = 1; k2 <= rows(P); k2++) {
		upper[k2, .] = cu[P[k2, .] :+ 1]'
		if (sgn) lower[k2, .] = cl[P[k2, .] :+ 1]'
	}
}

// LANS p-values (Foti, Hughes and Rockmore 2011)
void nw_bb_lans(real matrix A, real scalar sgn, real matrix upper, real matrix lower)
{
	real scalar n, i, k, t
	real colvector v, o, cle, cge, nzi
	real rowvector pr
	n = rows(A)
	upper = J(n, n, .)
	lower = J(n, n, .)
	for (i = 1; i <= n; i++) {
		if (sum(A[i, .]) == 0) continue
		pr = A[i, .] :/ sum(A[i, .])
		nzi = selectindex(pr :!= 0)'
		k = rows(nzi)
		v = pr[nzi']'
		o = order((v, (1::k)), (1, 2))
		// cle = number of nonzero values <= each value, cge = number >= each value
		cle = J(k, 1, 0)
		cge = J(k, 1, 0)
		cle[k] = k
		for (t = k - 1; t >= 1; t--) cle[t] = (v[o[t]] == v[o[t + 1]]) ? cle[t + 1] : t
		cge[1] = k
		for (t = 2; t <= k; t++) cge[t] = (v[o[t]] == v[o[t - 1]]) ? cge[t - 1] : k - t + 1
		upper[i, .] = J(1, n, 1)
		upper[i, nzi'] = (1 :- cle[order(o, 1)] :/ k)'
		if (sgn) {
			lower[i, .] = J(1, n, 1)
			lower[i, nzi'] = (1 :- cge[order(o, 1)] :/ k)'
		}
	}
	if (all(A :== A')) {
		upper = nw_bb_pmin(upper, upper')
		if (sgn) lower = nw_bb_pmin(lower, lower')
	}
}

// p-values (upper tail; with sgn also lower tail) of the ties of a weighted matrix or of the projection of an
// incidence matrix
void nw_bb_pvals(string scalar method, real matrix A, real scalar sgn, real scalar mz, real scalar trials, real scalar alpha, string scalar mtc, ///
	real matrix upper, real matrix lower, real scalar ntrials)
{
	real matrix P, probs, pv, outv, inv, Pr, x
	real colvector s, bin, rs, cc, p
	real rowvector cs, cb
	real scalar n, T, i, j, sigma, m, mu, gamma
	ntrials = .
	lower = J(0, 0, .)
	if (method == "disparity") {
		n = rows(A)
		s = rowsum(A)
		bin = rowsum(A :!= 0)
		if (all(A :== A')) {
			pv = (1 :- A :/ s) :^ (bin :- 1)
			upper = nw_bb_pmin(pv, pv')
			if (sgn) lower = 1 :- upper
		}
		else {
			outv = (1 :- A :/ s) :^ (bin :- 1)
			cs = colsum(A)
			cb = colsum(A :!= 0)
			inv = (1 :- A :/ cs) :^ (cb :- 1)
			upper = nw_bb_pmin(inv, outv)
			if (sgn) lower = 1 :- upper
		}
		if (!mz) {
			nw_bb_setmiss(upper, A :== 0)
			if (sgn) nw_bb_setmiss(lower, A :== 0)
		}
		return
	}
	if (method == "lans") {
		nw_bb_lans(A, sgn, upper, lower)
		if (!mz) {
			nw_bb_setmiss(upper, A :== 0)
			if (sgn) nw_bb_setmiss(lower, A :== 0)
		}
		return
	}
	if (method == "mlf") {
		n = rows(A)
		if (all(A :== A')) {
			T = sum(A) / 2
			s = rowsum(A)
			Pr = (s * s') :/ (2 * T^2)
		}
		else {
			T = sum(A)
			Pr = (rowsum(A) * colsum(A)) :/ (T^2)
		}
		upper = binomialtail(T, A, Pr)
		if (sgn) lower = binomial(T, A, Pr)
		if (!mz) {
			nw_bb_setmiss(upper, A :== 0)
			if (sgn) nw_bb_setmiss(lower, A :== 0)
		}
		return
	}
	// projection methods: A is the incidence matrix
	P = A * A'
	if (method == "sdsm") {
		probs = nw_bb_bicm(A)
		nw_bb_rna(P, probs, sgn, upper, lower)
	}
	else if (method == "fixedrow") {
		rs = rowsum(A)
		n = rows(A)
		upper = J(n, n, .)
		if (sgn) lower = J(n, n, .)
		for (i = 1; i < n; i++) for (j = i + 1; j <= n; j++) {
			upper[i, j] = P[i, j] <= 0 ? 1 : nw_bb_hyptail(cols(A), rs[i], rs[j], P[i, j])
			upper[j, i] = upper[i, j]
			if (sgn) {
				lower[i, j] = nw_bb_hypcdf(cols(A), rs[i], rs[j], P[i, j])
				lower[j, i] = lower[i, j]
			}
		}
	}
	else if (method == "fixedcol") {
		cc = colsum(A)'
		m = rows(A)
		p = (cc :* (cc :- 1)) :/ (m * (m - 1))
		mu = sum(p)
		sigma = sqrt(sum(p :* (1 :- p)))
		gamma = sum(p :* (1 :- p) :* (1 :- 2 :* p))
		x = (P :- 1 :+ 0.5 :- mu) :/ sigma
		upper = 1 :- (normal(x) + gamma / (6 * sigma^3) :* (1 :- x :^ 2) :* normalden(x))
		if (sgn) {
			x = (P :+ 0.5 :- mu) :/ sigma
			lower = normal(x) + gamma / (6 * sigma^3) :* (1 :- x :^ 2) :* normalden(x)
		}
	}
	else if (method == "fixedfill") {
		nw_bb_fixedfill(A, P, sgn, upper, lower)
	}
	else if (method == "fdsm") {
		if (trials <= 0) {
			trials = nw_bb_ntrials(P, alpha, mtc, sgn, mz)
			if (trials > 1000000) printf("{txt}note: the default number of Monte Carlo draws is {res}%s{txt}; this can take a long time. Set {bf:trials()} to a smaller number to stop earlier.\n", strofreal(trials, "%15.0gc"))
		}
		ntrials = trials
		nw_bb_fdsm(A, P, trials, sgn, upper, lower)
	}
	for (i = 1; i <= rows(P); i++) {
		upper[i, i] = .
		if (sgn) lower[i, i] = .
	}
	if (!mz) {
		nw_bb_setmiss(upper, P :== 0)
		if (sgn) nw_bb_setmiss(lower, P :== 0)
	}
}

// cumulative probability P(X <= x) of the hypergeometric distribution; Stata's hypergeometric() returns missing for x below
// the support (x < max(0, K+n-N)), where the probability is 0
real scalar nw_bb_hypcdf(real scalar N, real scalar K, real scalar n, real scalar x)
{
	if (x < max((0, K + n - N))) return(0)
	if (x >= min((K, n))) return(1)
	return(hypergeometric(N, K, n, x))
}

// upper tail P(X >= w) of the hypergeometric distribution (N items, K marked, n drawn); a sum of the probabilities
// when the tail is small, to keep precision
real scalar nw_bb_hyptail(real scalar N, real scalar K, real scalar n, real scalar w)
{
	real scalar r, x, s
	r = 1 - nw_bb_hypcdf(N, K, n, w - 1)
	if (r > 1e-6) return(r)
	s = 0
	for (x = max((w, K + n - N, 0)); x <= min((K, n)); x++) s = s + hypergeometricp(N, K, n, x)
	return(s)
}

// the backbone as a list of ties (row, column, value) in node numbers of the (chosen mode of the) network;
// undirected: each tie in both directions. Sets the locals nin (ties tested), nout (ties kept) and ntrials (draws) of the caller.
real matrix nw_backbone(real matrix A, string scalar method, real scalar alpha, string scalar mtc, real scalar sgn, real scalar mz, ///
	real scalar trials, real scalar thr1, real scalar thr2, real scalar nthr, real scalar directed, real scalar keepvalues)
{
	real matrix upper, lower, B, V
	real colvector k, vv
	real scalar n, ntr, i
	real rowvector info
	n = rows(A)
	if (method == "global") {
		V = A
		B = mz ? (A :> thr1) : ((A :> thr1) :& (A :!= 0))
		if (nthr == 2) B = B - (mz ? (A :< thr2) : ((A :< thr2) :& (A :!= 0)))
		info = (sum(A :!= 0) - sum(diagonal(A) :!= 0), 0, .)
	}
	else {
		if (method == "disparity" | method == "lans" | method == "mlf") V = A
		else V = A * A'
		nw_bb_pvals(method, A, sgn, mz, trials, alpha, mtc, upper, lower, ntr)
		B = nw_bb_retain(upper, lower, sgn, alpha, mtc)
		info = (sum(V :!= 0) - sum(diagonal(V) :!= 0), 0, ntr)
		if (method != "disparity" & method != "lans" & method != "mlf" & mz) info[1] = n * (n - 1)
	}
	if (!directed) info[1] = info[1] / 2
	info[2] = sum(B :!= 0) - sum(diagonal(B) :!= 0)
	if (!directed) info[2] = info[2] / 2
	// the counts go to the calling ado program
	st_local("nin", strofreal(info[1]))
	st_local("nout", strofreal(info[2]))
	st_local("ntrials", strofreal(info[3]))
	k = selectindex(vec(B :!= 0))
	if (rows(k) == 0) return(J(0, 3, .))
	if (keepvalues) vv = vec(V)[k]
	else vv = vec(B)[k]
	return((mod(k :- 1, n) :+ 1, floor((k :- 1) :/ n) :+ 1, vv))
}
end
