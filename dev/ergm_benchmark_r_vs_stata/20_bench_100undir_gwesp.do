/*
	Canonical benchmark 3 (user-requested): 100-node undirected network,
	edges + gwesp(0.5, fixed). No node attribute needed. Exercises
	common_neighbors()/change_gwesp() - the shared-partner machinery -
	at a scale where it might start to matter, per the user's own point
	that "GWESP is where the computational architecture really gets
	tested."
*/
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_core.do"
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_ergm.do"
run "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/nwergm.ado"

local ddir "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"

set seed 20260824
nwclear
nwrandom 100, prob(0.04) undirected name(bench100undir)

nw_syntax bench100undir, max(1)
capture erase "`ddir'/net100undir.csv"
mata:
mata set matastrict off
M = *`netobj'->get_matrix_mod(1,0)
_editmissing(M, 0)
fh = fopen("`ddir'/net100undir.csv", "w")
for (i=1; i<=rows(M); i++) fput(fh, invtokens(strofreal(M[i,.]), ","))
fclose(fh)
printf("exported net100undir.csv: %g x %g, %g ties\n", rows(M), cols(M), sum(M)/2)
end

import delimited using "`ddir'/net100undir.csv", clear varnames(nonames)
gen ego = _n
reshape long v, i(ego) j(alter)
rename v value
drop if ego == alter
* full symmetric edgelist kept (both (i,j) and (j,i), identical values,
* since M is already symmetric) rather than only i<j - avoids relying
* on any assumption about whether nwset's own `undirected' option
* expects one-sided or fully-symmetric edgelist input; giving it the
* already-symmetric full representation is unambiguously correct
* either way.
nwset ego alter value, edgelist undirected name(bench100undir_fit)

timer clear 1
set seed 999
timer on 1
nwergm bench100undir_fit, edges gwesp(.5)
timer off 1
timer list 1

di
di "======================================"
di "STATA nwergm: 100-node undirected, edges + gwesp(.5)"
di "======================================"
di "Wall time: " %8.3f r(t1) " seconds"
di "Converged: " e(converged)
di "MCMLE iterations: " e(mcmle_iterations)
matrix list e(b)
matrix list e(V)
