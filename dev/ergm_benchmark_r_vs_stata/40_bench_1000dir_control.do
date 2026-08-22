/*
	Canonical benchmark 5 (user-requested control): 1000-node directed
	sparse network, edges + mutual + nodematch - NO gwesp/shared-partner
	computation - to isolate how much overhead remains at large n when
	the expensive shared-partner machinery is absent.

	At n=1000, the "import wide CSV + reshape long" edgelist-loading
	approach used for the smaller benchmarks hits a genuine, hard
	environmental limit: Stata BE (Basic Edition)'s own c(maxvar) is
	FIXED at 2048 and cannot be raised (`set maxvar` itself errors,
	r(198)) - reshape's own internal wide/long bookkeeping apparently
	needs headroom beyond the 1000 literal v1..v1000 columns, so it
	silently fails to build a real `alter' index variable ("variable
	alter contains all missing values") rather than raising a maxvar
	error directly. Confirmed via an isolated repro independent of this
	benchmark entirely. Side-stepped by building the (ego,alter,value)
	edgelist directly in Mata from the SAME adjacency matrix and
	`st_store()`-ing it straight into a 3-variable long dataset - never
	creating a wide, many-column intermediate at all.
*/
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_core.do"
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_ergm.do"
run "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/nwergm.ado"

local ddir "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"

set seed 20260826
nwclear
nwrandom 1000, prob(0.006) directed name(bench1000)
gen grp = ceil(3*runiform())
outsheet grp using "`ddir'/attr1000.csv", comma nonames replace

nw_syntax bench1000, max(1)
capture erase "`ddir'/net1000.csv"
mata:
mata set matastrict off
M = *`netobj'->get_matrix_mod(1,1)
_editmissing(M, 0)
fh = fopen("`ddir'/net1000.csv", "w")
for (i=1; i<=rows(M); i++) fput(fh, invtokens(strofreal(M[i,.]), ","))
fclose(fh)
printf("exported net1000.csv: %g x %g, %g ties\n", rows(M), cols(M), sum(M))
end

preserve
local ndyad = 1000*999
qui drop _all
qui set obs `ndyad'
gen ego = .
gen alter = .
gen value = .
mata:
mata set matastrict off
n = rows(M)
ego_v = J(n*(n-1), 1, 0)
alt_v = J(n*(n-1), 1, 0)
val_v = J(n*(n-1), 1, 0)
pos = 1
for (i=1; i<=n; i++) {
	for (j=1; j<=n; j++) {
		if (i==j) continue
		ego_v[pos] = i
		alt_v[pos] = j
		val_v[pos] = M[i,j]
		pos = pos + 1
	}
}
st_store(., "ego", ego_v)
st_store(., "alter", alt_v)
st_store(., "value", val_v)
end
nwset ego alter value, edgelist directed name(bench1000_fit)
restore
* grp is back (preserve/restore snapshot), still 1000 obs in node order.

timer clear 1
set seed 999
timer on 1
nwergm bench1000_fit, edges mutual nodematch(grp)
timer off 1
timer list 1

di
di "======================================"
di "STATA nwergm: 1000-node directed CONTROL (no gwesp), edges + mutual + nodematch"
di "======================================"
di "Wall time: " %8.3f r(t1) " seconds"
di "Converged: " e(converged)
di "MCMLE iterations: " e(mcmle_iterations)
matrix list e(b)
matrix list e(V)
