/*
	Canonical benchmark 4 (user-requested): 500-node SPARSE undirected
	network, edges + nodematch + gwesp - the pair the user flagged as
	most informative for whether Mata's own architecture holds up,
	since it exercises common_neighbors()/change_gwesp() (shared-
	partner machinery) at real scale, not just edges/mutual.
*/
adopath + "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/lib"
adopath + "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016"
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_core.do"
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_ergm.do"
run "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/nwergm.ado"

local ddir "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"

set seed 20260825
nwclear
nwrandom 500, prob(0.012) undirected name(bench500)
gen grp = ceil(3*runiform())

nw_syntax bench500, max(1)
capture erase "`ddir'/net500.csv"
mata:
mata set matastrict off
M = *`netobj'->get_matrix_mod(1,0)
_editmissing(M, 0)
fh = fopen("`ddir'/net500.csv", "w")
for (i=1; i<=rows(M); i++) fput(fh, invtokens(strofreal(M[i,.]), ","))
fclose(fh)
printf("exported net500.csv: %g x %g, %g ties\n", rows(M), cols(M), sum(M)/2)
end

outsheet grp using "`ddir'/attr500.csv", comma nonames replace

preserve
import delimited using "`ddir'/net500.csv", clear varnames(nonames)
gen ego = _n
reshape long v, i(ego) j(alter)
rename v value
drop if ego == alter
nwset ego alter value, edgelist undirected name(bench500_fit)
restore

timer clear 1
set seed 999
timer on 1
nwergm bench500_fit, edges nodematch(grp) gwesp(.5)
timer off 1
timer list 1

di
di "======================================"
di "STATA nwergm: 500-node sparse undirected, edges + nodematch + gwesp"
di "======================================"
di "Wall time: " %8.3f r(t1) " seconds"
di "Converged: " e(converged)
di "MCMLE iterations: " e(mcmle_iterations)
matrix list e(b)
matrix list e(V)
