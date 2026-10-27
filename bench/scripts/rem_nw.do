* One timed nwrem fit in its own Stata process.  Environment: SIZE, SET, SEED, OUT, BENCH, BENCH_PLUS, BENCH_ADOPATH, NWC.
* Untimed warm-up fit (e200, S1) first; the timer covers the nwrem command only (the network is loaded before).
version 17
set more off
local T = char(9)
local bdir : env BENCH
local size : env SIZE
local set : env SET
local seed : env SEED
local out : env OUT
do "`bdir'/scripts/hdr.do"
local opts_S1_nodsnd_nidrec "nodsnd nidrec"
local opts_S2_degree4 "nodsnd nidrec nidsnd nodrec"
local opts_S3_degree4_inertia "nodsnd nidrec nidsnd nodrec frpsndsnd frrecsnd"
local opts_S4_recency "nodsnd nidrec rsndsnd rrecsnd"
local opts_S5_covariates "nodsnd nidrec covsnd(covsnd) covrec(covrec) covint(covint)"

capture program drop _rem_load
program define _rem_load
	args id bdir
	nwclear
	qui import delimited "`bdir'/data/rem/`id'_events.csv", clear varnames(1)
	qui nwset sender receiver, eventtime(eventtime) name(bnet)
	qui import delimited "`bdir'/data/rem/`id'_cov.csv", clear varnames(1)
	tempfile cv
	qui save `cv'
	qui nwload bnet, xvars
	qui merge 1:1 _n using `cv', nogenerate
end

_rem_load e200 "`bdir'"
qui nwrem bnet, nodsnd nidrec seed(100)
_rem_load `size' "`bdir'"
timer clear 1
timer on 1
capture noisily quietly nwrem bnet, `opts_`set'' seed(`seed')
local rc = _rc
timer off 1
qui timer list 1
local secs = r(t1)
if `rc' exit `rc'
tempname b V
matrix `b' = e(b)
matrix `V' = e(V)
local names ""
local ests ""
local ses ""
local nm0 : colnames `b'
local j 0
foreach nm of local nm0 {
	local ++j
	local names "`names'`=cond("`names'"=="","","`T'")'`nm'"
	local ests  "`ests'`=cond("`ests'"=="","","`T'")'`=string(`b'[1,`j'], "%18.10g")'"
	local ses   "`ses'`=cond("`ses'"=="","","`T'")'`=string(sqrt(`V'[`j',`j']), "%18.10g")'"
}
file open fh using "`out'", write text replace
file write fh "secs`T'`=string(`secs', "%12.4f")'" _n
file write fh "converged`T'1" _n
file write fh "iters`T'." _n
file write fh "ll`T'`=string(e(ll), "%18.8f")'" _n
file write fh "names`T'`names'" _n
file write fh "ests`T'`ests'" _n
file write fh "ses`T'`ses'" _n
file write fh "version`T'nwrem `e(version)' stata `c(stata_version)'" _n
file close fh
