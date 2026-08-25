/*
	Canonical benchmark 2 (user-requested): 100-node directed network,
	edges + mutual + nodematch. Generates the network + a 3-level
	categorical node attribute once (fixed seed), exports both as plain
	CSVs for R to read identically, fits via nwergm with default control
	settings, times the whole call.
*/
adopath + "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/lib"
adopath + "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016"
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_core.do"
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_ergm.do"
run "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/nwergm.ado"

local ddir "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"

set seed 20260823
nwclear
nwrandom 100, prob(0.03) name(bench100dir)
gen grp = ceil(3*runiform())

nw_syntax bench100dir, max(1)
capture erase "`ddir'/net100dir.csv"
mata:
mata set matastrict off
M = *`netobj'->get_matrix_mod(1,1)
_editmissing(M, 0)
fh = fopen("`ddir'/net100dir.csv", "w")
for (i=1; i<=rows(M); i++) fput(fh, invtokens(strofreal(M[i,.]), ","))
fclose(fh)
printf("exported net100dir.csv: %g x %g, %g ties\n", rows(M), cols(M), sum(M))
end

outsheet grp using "`ddir'/attr100dir.csv", comma nonames replace

* --- reload via the edgelist path (nwset's own mat() bare-name bug -
* see docs/CERTIFICATION.md's Pending list - the literal-expression
* workaround doesn't scale past ~30 nodes either, hitting Stata's own
* "too many tokens" command-line limit) and re-attach the SAME
* attribute in the SAME row order.
preserve
import delimited using "`ddir'/net100dir.csv", clear varnames(nonames)
gen ego = _n
reshape long v, i(ego) j(alter)
rename v value
drop if ego == alter
nwset ego alter value, edgelist directed name(bench100dir_fit)
restore
* `grp' is back (preserve/restore snapshot), still 100 obs in node order.

timer clear 1
set seed 999
timer on 1
nwergm bench100dir_fit, edges mutual nodematch(grp)
timer off 1
timer list 1

di
di "======================================"
di "STATA nwergm: 100-node directed, edges + mutual + nodematch"
di "======================================"
di "Wall time: " %8.3f r(t1) " seconds"
di "Converged: " e(converged)
di "MCMLE iterations: " e(mcmle_iterations)
matrix list e(b)
matrix list e(V)
