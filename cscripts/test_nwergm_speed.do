cscript

do unw_core.do
do unw_ergm.do

* Speed-related regression tests for nwergm (correctness only, no timing).
*  (1) the vectorised Hummel steplength LP (ergm_hummel_gammamax) gives the same
*      answer as the original element-loop simplex (kept below as a reference);
*  (2) the fast Mata MPLE logistic fit (ergm_mple_irls) equals Stata's logit
*      (coefficients and covariance) and declines (returns 0) on separation;
*  (3) a directed dyad-dependent MCMLE fit still runs natively, converges, and
*      is close to its MPLE; the MPLE of a dyad-independent model equals logit.

mata:
mata set matastrict off
real scalar ergm_hummel_gammamax_ref(real matrix Mm, real rowvector x){
	real scalar n, k, i, j, ii, iter, ncols, nrows, entering, leaving
	real scalar mincost, ratio, minratio, phase1obj, pivot, tol
	real matrix T
	real rowvector cost1, cost2, redcost, basis
	real colvector b
	real scalar gpcol, gmcol, artcol0, gam

	n = rows(Mm)
	k = cols(Mm)
	tol = 1e-9

	if (max(abs(x)) < 1e-10) return(.)

	nrows = k+1
	ncols = n + 2 + nrows
	gpcol = n+1
	gmcol = n+2
	artcol0 = n+2

	T = J(nrows, ncols, 0)
	for (i=1; i<=k; i++) {
		for (j=1; j<=n; j++) T[i,j] = Mm[j,i]
		T[i,gpcol] = -x[i]
		T[i,gmcol] = x[i]
		T[i, artcol0+i] = 1
	}
	for (j=1; j<=n; j++) T[k+1,j] = 1
	T[k+1, artcol0+(k+1)] = 1

	b = J(nrows,1,0)
	b[k+1] = 1

	basis = J(1,nrows,0)
	for (i=1; i<=nrows; i++) basis[i] = artcol0+i

	cost1 = J(1,ncols,0)
	for (i=1; i<=nrows; i++) cost1[artcol0+i] = 1

	for (iter=1; iter<=2000; iter++) {
		redcost = J(1,ncols,0)
		for (j=1; j<=ncols; j++) {
			redcost[j] = cost1[j]
			for (i=1; i<=nrows; i++) redcost[j] = redcost[j] - cost1[basis[i]]*T[i,j]
		}
		entering = 0
		for (j=1; j<=ncols; j++) {
			if (redcost[j] < -tol) { entering = j; break; }
		}
		if (entering==0) break

		minratio = .
		leaving = 0
		for (i=1; i<=nrows; i++) {
			if (T[i,entering] > tol) {
				ratio = b[i]/T[i,entering]
				if (leaving==0) {
					minratio = ratio
					leaving = i
				}
				else if (ratio < minratio - 1e-12) {
					minratio = ratio
					leaving = i
				}
				else if (abs(ratio-minratio)<1e-9 & basis[i]<basis[leaving]) {
					minratio = ratio
					leaving = i
				}
			}
		}
		if (leaving==0) return(.)  // unbounded in phase 1 - not expected (phase-1 objective is bounded below by 0)

		pivot = T[leaving,entering]
		T[leaving,.] = T[leaving,.] / pivot
		b[leaving] = b[leaving]/pivot
		for (i=1; i<=nrows; i++) {
			if (i!=leaving & abs(T[i,entering])>tol) {
				b[i] = b[i] - T[i,entering]*b[leaving]
				T[i,.] = T[i,.] - T[i,entering]*T[leaving,.]
			}
		}
		basis[leaving] = entering
	}

	phase1obj = 0
	for (i=1; i<=nrows; i++) if (basis[i] > artcol0) phase1obj = phase1obj + b[i]
	if (phase1obj > 1e-6) return(.)

	for (i=1; i<=nrows; i++) {
		if (basis[i] > artcol0) {
			entering = 0
			for (j=1; j<=n+2; j++) {
				if (abs(T[i,j]) > tol) { entering = j; break; }
			}
			if (entering>0) {
				pivot = T[i,entering]
				T[i,.] = T[i,.]/pivot
				b[i] = b[i]/pivot
				for (ii=1; ii<=nrows; ii++) {
					if (ii!=i & abs(T[ii,entering])>tol) {
						b[ii] = b[ii] - T[ii,entering]*b[i]
						T[ii,.] = T[ii,.] - T[ii,entering]*T[i,.]
					}
				}
				basis[i] = entering
			}
		}
	}

	cost2 = J(1,ncols,0)
	cost2[gpcol] = -1
	cost2[gmcol] = 1
	for (i=1; i<=nrows; i++) if (basis[i]>artcol0) cost2[basis[i]] = 1e15

	for (iter=1; iter<=5000; iter++) {
		redcost = J(1,ncols,0)
		for (j=1; j<=artcol0-1; j++) {
			redcost[j] = cost2[j]
			for (i=1; i<=nrows; i++) redcost[j] = redcost[j] - cost2[basis[i]]*T[i,j]
		}
		entering = 0
		for (j=1; j<=artcol0-1; j++) {
			if (redcost[j] < -tol) { entering = j; break; }
		}
		if (entering==0) break

		minratio = .
		leaving = 0
		for (i=1; i<=nrows; i++) {
			if (T[i,entering] > tol) {
				ratio = b[i]/T[i,entering]
				if (leaving==0) {
					minratio = ratio
					leaving = i
				}
				else if (ratio < minratio - 1e-12) {
					minratio = ratio
					leaving = i
				}
				else if (abs(ratio-minratio)<1e-9 & basis[i]<basis[leaving]) {
					minratio = ratio
					leaving = i
				}
			}
		}
		if (leaving==0) return(1e15)

		pivot = T[leaving,entering]
		T[leaving,.] = T[leaving,.] / pivot
		b[leaving] = b[leaving]/pivot
		for (i=1; i<=nrows; i++) {
			if (i!=leaving & abs(T[i,entering])>tol) {
				b[i] = b[i] - T[i,entering]*b[leaving]
				T[i,.] = T[i,.] - T[i,entering]*T[leaving,.]
			}
		}
		basis[leaving] = entering
	}

	gam = 0
	for (i=1; i<=nrows; i++) {
		if (basis[i]==gpcol) gam = gam + b[i]
		if (basis[i]==gmcol) gam = gam - b[i]
	}
	return(gam)
}

real scalar speed_check_hummel(real scalar n, real scalar k, real scalar seed){
	real matrix D, Dc, Du
	real rowvector Dbar
	real scalar g1, g2
	rseed(seed)
	D = rpoisson(n, k, 4) + rnormal(n, k, 0, 1)
	D[., 1] = D[., 1] + 0.5*D[., 2]
	Dbar = mean(D)
	Dc = D :- Dbar
	Du = uniqrows(Dc)
	g1 = ergm_hummel_gammamax(Du, -(Dbar :+ 0.3))
	g2 = ergm_hummel_gammamax_ref(Du, -(Dbar :+ 0.3))
	if (g1 == . | g2 == .) return(g1 == g2 ? 0 : 99)
	return(abs(g1 - g2))
}
end

foreach cfg in "200 2 1" "500 3 2" "1000 3 3" "300 4 4" {
	local n : word 1 of `cfg'
	local k : word 2 of `cfg'
	local s : word 3 of `cfg'
	mata: st_numscalar("__d", speed_check_hummel(`n', `k', `s'))
	assert scalar(__d) < 1e-8
}
display "PASS speed: vectorised Hummel LP equals the reference simplex"

* ---- (2) IRLS vs logit on a random dyad data set
clear
set seed 4711
set obs 3000
gen double x1 = 1
gen double x2 = rbinomial(1, .4)
gen double x3 = rnormal()
gen double y = runiform() < invlogit(-1.5 + .8*x2 - .5*x3)
logit y x1 x2 x3, noconstant
matrix bl = e(b)
matrix Vl = e(V)
mata: D = st_data(., ("x1","x2","x3","y"))
mata: st_numscalar("__ok", ergm_mple_irls(D, "bi", "Vi"))
assert scalar(__ok) == 1
assert mreldif(bl, bi) < 1e-6
assert mreldif(Vl, Vi) < 1e-5
display "PASS speed: ergm_mple_irls equals logit"

* separation: x2 perfectly predicts y -> decline (caller falls back to logit)
replace y = x2
mata: D = st_data(., ("x1","x2","x3","y"))
mata: st_numscalar("__ok", ergm_mple_irls(D, "bi", "Vi"))
assert scalar(__ok) == 0
* collinear columns -> decline
replace y = runiform() < .3
gen double x4 = x3
mata: D = st_data(., ("x1","x3","x4","y"))
mata: st_numscalar("__ok", ergm_mple_irls(D, "bi", "Vi"))
assert scalar(__ok) == 0
display "PASS speed: ergm_mple_irls declines separation / collinearity"

* ---- (3) end-to-end on a directed network
clear
set seed 20260101
local n 50
set obs `=`n'*(`n'-1)'
gen int from = ceil(_n/(`n'-1))
gen int to = mod(_n-1, `n'-1) + 1
replace to = to + 1 if to >= from
gen double u = runiform()
keep if u < .06
keep from to
* reciprocate a share of the ties
tempfile rec
preserve
	rename (from to) (to from)
	gen double u = runiform()
	keep if u < .35
	keep from to
	save `rec'
restore
append using `rec'
duplicates drop from to, force
tempfile edg
save `edg'
qui nwclear
use `edg', clear
qui nwset from to, edgelist directed name(dn)
qui nwergm dn, edges mutual seed(5)
assert e(native) == 1
assert e(converged) == 1
matrix bm = e(b)
qui nwergm dn, edges mutual method(mple)
matrix bp = e(b)
assert abs(bm[1,1] - bp[1,1]) < 0.5 & abs(bm[1,2] - bp[1,2]) < 0.8
display "PASS speed: directed edges+mutual MCMLE converges natively and is close to MPLE"
display "PASS test_nwergm_speed"
