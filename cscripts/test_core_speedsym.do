cscript

do unw_core.do

* nwbetween / nwcloseness skip the symmetrised temporary copy for an undirected network that is already symmetric.
* Results must equal the copy path (a directed network with the same symmetric matrix is symmetrised by a real copy),
* and the current network after the call must be the one of the earlier versions.

set seed 20261122
mata:
void st_symmat(real scalar n, real scalar p, real scalar valued)
{
	real matrix A, B
	A = (runiform(n,n) :< p)
	if (valued) A = A :* ceil(4*runiform(n,n))
	B = A'
	A = (A :> B) :* A + (A :<= B) :* B
	A = A - diag(diagonal(A))
	st_matrix("__A", A)
}
end

foreach valued in 0 1 {
	* a disconnected (sparse) and a connected (dense) case
	foreach p in 0.06 0.3 {
		nwclear
		mata: st_symmat(30, `p', `valued')
		nwset, mat(__A) name(first) undirected
		nwset, mat(__A) name(und) undirected
		nwset, mat(__A) name(dirsym) directed
		nwset, mat((0,1\1,0)) name(last) undirected

		* betweenness: symmetric undirected (copy skipped) vs the same matrix as a directed network (real copy)
		foreach o in "" "standardize" "binary" {
			nwcurrent last
			nwbetween und, generate(bu) `o'
			qui nwcurrent
			assert "`r(current)'" == "und"
			nwcurrent last
			nwbetween dirsym, generate(bd) `o'
			qui nwcurrent
			assert "`r(current)'" == "dirsym"
			if "`o'" == "standardize" {
				* the directed network is standardised with its own denominator: compare raw scores only
				drop bu bd
				continue
			}
			forvalues i = 1/30 {
				assert reldif(bu[`i'], bd[`i']) < 1e-12 | (bu[`i'] == . & bd[`i'] == .)
			}
			drop bu bd
		}

		* closeness: same comparison, and the current network: the first network in memory (as before), nosym leaves it untouched
		foreach o in "" "binary" "legacy" {
			nwcurrent last
			nwcloseness und, generate(cu fu nu) `o'
			qui nwcurrent
			assert "`r(current)'" == "first"
			nwcurrent last
			nwcloseness dirsym, generate(cd fd nd) `o'
			forvalues i = 1/30 {
				assert reldif(cu[`i'], cd[`i']) < 1e-12 | (cu[`i'] == . & cd[`i'] == .)
				assert reldif(fu[`i'], fd[`i']) < 1e-12 | (fu[`i'] == . & fd[`i'] == .)
			}
			drop cu fu nu cd fd nd
		}
		nwcurrent last
		nwcloseness und, generate(cu fu nu) nosym
		qui nwcurrent
		assert "`r(current)'" == "last"
		drop cu fu nu

		* directed without symmetrisation is unaffected: twice the undirected betweenness (ordered pairs)
		nwbetween und, generate(bu) nosym
		nwbetween dirsym, generate(bd) nosym
		forvalues i = 1/30 {
			assert reldif(2*bu[`i'], bd[`i']) < 1e-12 | (bu[`i'] == . & bd[`i'] == .)
		}
		drop bu bd
	}
}

* the first network in memory is the analysed one: current stays on it
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(only) undirected
nwbetween only, generate(b)
qui nwcurrent
assert "`r(current)'" == "only"
nwcloseness only, generate(c f n)
qui nwcurrent
assert "`r(current)'" == "only"

di "PASS test_core_speedsym"
