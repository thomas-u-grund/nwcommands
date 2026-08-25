/*
	Benchmark 7 (harmonisation unit 92, native wave 2): 2000-node
	SPARSE directed network, edges + mutual + nodematch + odegree(2) +
	idegree(2) + gwodegree + gwidegree - a representative "several terms
	from the degree-count family at once" specification, all of which
	are native-eligible as of wave 2 (previously ANY of odegree()/
	idegree() present would have forced the whole model onto Mata, even
	though mutual/nodematch/gwodegree/gwidegree were already native).
	Not exhaustive - one example, per the user's own explicit
	instruction.
*/
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_core.do"
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_ergm.do"
run "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/nwergm.ado"

local ddir "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"

set seed 20260902
nwclear
nwrandom 2000, prob(0.003) directed name(bench7)
gen grp = ceil(3*runiform())

nw_syntax bench7, max(1)
capture erase "`ddir'/net_degfam.csv"
mata:
mata set matastrict off
M = *`netobj'->get_matrix_mod(1,1)
_editmissing(M, 0)
fh = fopen("`ddir'/net_degfam.csv", "w")
for (i=1; i<=rows(M); i++) fput(fh, invtokens(strofreal(M[i,.]), ","))
fclose(fh)
printf("exported net_degfam.csv: %g x %g, %g ties\n", rows(M), cols(M), sum(M))
end

outsheet grp using "`ddir'/attr_degfam.csv", comma nonames replace

preserve
local ndyad = 2000*1999
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
nwset ego alter value, edgelist directed name(bench7_fit)
restore
* grp is back (preserve/restore snapshot), still 2000 obs in node order.

timer clear 1
set seed 999
timer on 1
nwergm bench7_fit, edges mutual nodematch(grp) odegree(2) idegree(2) gwodegree(.5) gwidegree(.5)
timer off 1
timer list 1

di
di "======================================"
di "STATA nwergm: 2000-node directed, edges+mutual+nodematch+odegree(2)+idegree(2)+gwodegree+gwidegree"
di "======================================"
di "Wall time: " %8.3f r(t1) " seconds"
di "Native backend used: " e(native)
di "Converged: " e(converged)
di "MCMLE iterations: " e(mcmle_iterations)
matrix list e(b)
matrix list e(V)
