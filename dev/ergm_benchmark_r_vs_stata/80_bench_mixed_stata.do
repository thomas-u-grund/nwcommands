/*
	Benchmark 6 (harmonisation unit 92 - "move all effects to C" native
	backend relaxation): 1000-node SPARSE undirected network,
	edges + gwesp + nodefactor + nodecov - exactly the "gwesp mixed with
	other terms" case that used to force a full Mata fallback before
	this unit's own native wave 1 (attribute/factor family). Not an
	exhaustive combinatorial sweep - one representative example showing
	the fix actually holds at real scale, per the user's own explicit
	instruction.
*/
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_core.do"
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_ergm.do"
run "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/nwergm.ado"

local ddir "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"

set seed 20260901
nwclear
nwrandom 1000, prob(0.006) undirected name(bench6)
gen grp = ceil(3*runiform())
gen cov = round(rnormal(0,5), .01)

nw_syntax bench6, max(1)
capture erase "`ddir'/net_mixed.csv"
mata:
mata set matastrict off
M = *`netobj'->get_matrix_mod(1,0)
_editmissing(M, 0)
fh = fopen("`ddir'/net_mixed.csv", "w")
for (i=1; i<=rows(M); i++) fput(fh, invtokens(strofreal(M[i,.]), ","))
fclose(fh)
printf("exported net_mixed.csv: %g x %g, %g ties\n", rows(M), cols(M), sum(M)/2)
end

outsheet grp cov using "`ddir'/attr_mixed.csv", comma nonames replace

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
nwset ego alter value, edgelist undirected name(bench6_fit)
restore
* grp/cov are back (preserve/restore snapshot), still 1000 obs in node order.

timer clear 1
set seed 999
timer on 1
nwergm bench6_fit, edges gwesp(.5) nodefactor(grp) nodecov(cov)
timer off 1
timer list 1

di
di "======================================"
di "STATA nwergm: 1000-node undirected, edges + gwesp + nodefactor + nodecov (MIXED)"
di "======================================"
di "Wall time: " %8.3f r(t1) " seconds"
di "Native backend used: " e(native)
di "Converged: " e(converged)
di "MCMLE iterations: " e(mcmle_iterations)
matrix list e(b)
matrix list e(V)
