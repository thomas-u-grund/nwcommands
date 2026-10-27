* One timed nwsaom fit in its own Stata process.
* Environment: MODEL, SEED, OUT, CORES (default 1), BENCH (speed_all folder), BENCH_PLUS, BENCH_ADOPATH, NWC.
* A cheap untimed warm-up fit (N1, seed 100) loads the Mata library and the plugin first; the timer covers the nwsaom
* command only (data are built before the timer).
version 17
local T = char(9)
set more off
local bdir : env BENCH
local model : env MODEL
local seed : env SEED
local out : env OUT
local cores : env CORES
if "`cores'" == "" local cores 1
do "`bdir'/scripts/hdr.do"
global XDIR "`bdir'/data/saom"
include "`bdir'/scripts/bench_models.do"
include "`bdir'/scripts/saom_models_x.do"
mata: __nwsaom_cores = `cores'

_bench_data N1
qui nwsaom, `cmd_N1' seed(100) cores(1)

local isx = inlist("`model'", "X1", "X2", "X3", "X4", "X5", "X6", "X7", "X8")
local multi = inlist("`model'", "X3", "X4", "X5", "X6")
if `isx' _x_data `model'
else _bench_data `model'
local cmd "`cmd_`model''"
local cmdov : env CMD
if `"`cmdov'"' != "" local cmd `"`cmdov'"'
timer clear 1
timer on 1
if `multi' capture noisily nwsaom `cmd' seed(`seed')
else capture noisily nwsaom, `cmd' seed(`seed') cores(`cores')
local rc = _rc
timer off 1
qui timer list 1
local secs = r(t1)
if `rc' exit `rc'

local tmax = e(tconv_max)
tempname b V
matrix `b' = e(b)
matrix `V' = e(V)
local names ""
local ests ""
local ses ""
local names0 : colnames `b'
local j 0
foreach nm of local names0 {
	local ++j
	local names "`names'`=cond("`names'"=="","","`T'")'`nm'"
	local ests  "`ests'`=cond("`ests'"=="","","`T'")'`=string(`b'[1,`j'], "%18.10g")'"
	local ses   "`ses'`=cond("`ses'"=="","","`T'")'`=string(sqrt(`V'[`j',`j']), "%18.10g")'"
}
if `multi' {
	tempname R
	matrix `R' = e(rates)
	local K = rowsof(`R') / 2
	forvalues k = 1/`K' {
		forvalues p = 1/`=colsof(`R')' {
			local names "`names'`T'rate`k'_`p'"
			local ests  "`ests'`T'`=string(`R'[`k',`p'], "%18.10g")'"
			local ses   "`ses'`T'`=string(`R'[`K'+`k',`p'], "%18.10g")'"
		}
	}
}
else {
	capture confirm matrix e(rates)
	if _rc == 0 {
		tempname r rs
		matrix `r' = e(rates)
		matrix `rs' = e(rates_se)
		forvalues p = 1/`=colsof(`r')' {
			local names "`names'`T'rate`p'"
			local ests  "`ests'`T'`=string(`r'[1,`p'], "%18.10g")'"
			local ses   "`ses'`T'`=string(`rs'[1,`p'], "%18.10g")'"
		}
	}
	else {
		local names "`names'`T'rate1"
		local ests  "`ests'`T'`=string(e(rate), "%18.10g")'"
		local ses   "`ses'`T'`=string(e(rate_se), "%18.10g")'"
	}
	capture confirm matrix e(rates_beh)
	if _rc == 0 {
		tempname r rs
		matrix `r' = e(rates_beh)
		matrix `rs' = e(rates_beh_se)
		forvalues p = 1/`=colsof(`r')' {
			local names "`names'`T'brate`p'"
			local ests  "`ests'`T'`=string(`r'[1,`p'], "%18.10g")'"
			local ses   "`ses'`T'`=string(`rs'[1,`p'], "%18.10g")'"
		}
	}
}
local eng "`e(engine)'"
file open fh using "`out'", write text replace
file write fh "secs`T'`=string(`secs', "%12.4f")'" _n
file write fh "tconv_max`T'`=string(`tmax', "%12.5f")'" _n
file write fh "converged`T'`=(`tmax' < 0.25)'" _n
file write fh "iters`T'." _n
file write fh "ll`T'." _n
file write fh "names`T'`names'" _n
file write fh "ests`T'`ests'" _n
file write fh "ses`T'`ses'" _n
file write fh "version`T'`e(version)' engine `eng' stata `c(stata_version)'" _n
file close fh
