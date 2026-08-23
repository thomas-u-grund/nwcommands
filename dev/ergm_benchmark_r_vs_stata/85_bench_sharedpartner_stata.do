/*
	Benchmark 8 (harmonisation unit 92, native wave 3): 1000-node
	SPARSE undirected network, edges + gwesp + gwnsp - a representative
	"several shared-partner-family terms at once" specification. Before
	wave 3, gwnsp present alongside gwesp would have forced the whole
	model onto Mata even though gwesp alone was already native. NOT
	edges+gwesp+gwdsp+triangle (all three tried first): gwesp/gwdsp/
	triangle are all near-duplicate measures of the SAME clustering
	structure, and on a sparse, near-triangle-free random network they
	are collinear enough that the MPLE design matrix (always built
	first, as MCMLE's own starting value) fails to converge ("logit:
	convergence not achieved", r(430)) - a genuine statistical
	degeneracy from this specific term COMBINATION, not a code bug
	(confirmed: each of these three terms passes its own dedicated
	native-vs-Mata equivalence check individually and pairwise
	elsewhere - cscripts/test_nwergm_native.do). gwnsp (untied-dyad
	shared partners) is a natural complement to gwesp (tied-dyad shared
	partners) rather than a near-duplicate of it, avoiding this
	specific pitfall while still exercising the SAME wave-3 composition
	dispatch path (gwnsp = gwdsp - gwesp) in native/ergm_mcmc.c. Not
	exhaustive - one example, per the user's own explicit instruction.
*/
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_core.do"
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_ergm.do"
run "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/nwergm.ado"

local ddir "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"

set seed 20260903
nwclear
nwrandom 1000, prob(0.006) undirected name(bench8)

nw_syntax bench8, max(1)
capture erase "`ddir'/net_sp.csv"
mata:
mata set matastrict off
M = *`netobj'->get_matrix_mod(1,0)
_editmissing(M, 0)
fh = fopen("`ddir'/net_sp.csv", "w")
for (i=1; i<=rows(M); i++) fput(fh, invtokens(strofreal(M[i,.]), ","))
fclose(fh)
printf("exported net_sp.csv: %g x %g, %g ties\n", rows(M), cols(M), sum(M)/2)
end

preserve
local ndyad = 1000*999/2
qui drop _all
qui set obs `ndyad'
gen ego = .
gen alter = .
gen value = .
mata:
mata set matastrict off
n = rows(M)
ego_v = J(n*(n-1)/2, 1, 0)
alt_v = J(n*(n-1)/2, 1, 0)
val_v = J(n*(n-1)/2, 1, 0)
pos = 1
for (i=1; i<=n-1; i++) {
	for (j=i+1; j<=n; j++) {
		ego_v[pos] = i
		alt_v[pos] = j
		val_v[pos] = M[i,j]
		pos = pos + 1
	}
}
st_store((1::rows(ego_v)), "ego", ego_v)
st_store((1::rows(alt_v)), "alter", alt_v)
st_store((1::rows(val_v)), "value", val_v)
end
qui drop if missing(ego)
nwset ego alter value, edgelist undirected name(bench8_fit)
restore

timer clear 1
set seed 999
timer on 1
nwergm bench8_fit, edges gwesp(.5) gwnsp(.5)
timer off 1
timer list 1

di
di "======================================"
di "STATA nwergm: 1000-node undirected, edges + gwesp + gwnsp"
di "======================================"
di "Wall time: " %8.3f r(t1) " seconds"
di "Native backend used: " e(native)
di "Converged: " e(converged)
di "MCMLE iterations: " e(mcmle_iterations)
matrix list e(b)
matrix list e(V)
