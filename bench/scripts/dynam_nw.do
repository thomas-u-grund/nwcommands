* One timed nwdynam fit in its own Stata process.
* Environment: SIZE, SET (C1 C2 C3 R1 R2), OUT, BENCH, BENCH_PLUS, BENCH_ADOPATH, NWC.
* Untimed warm-up fit first (200 events); the timer covers the nwdynam command only.
version 17
set more off
local T = char(9)
local bdir : env BENCH
local size : env SIZE
local set : env SET
local out : env OUT
do "`bdir'/scripts/hdr.do"

local opt_C1 ""
local opt_C2 "inertia recip indeg same(group)"
local opt_C3 "inertia trans"
local opt_R1 "submodel(rate)"
local opt_R2 "submodel(rate) indeg outdeg ego(x)"

capture program drop _dyn_load
program define _dyn_load
	args id bdir
	nwclear
	qui import delimited "`bdir'/data/dynam/`id'_events.csv", clear varnames(1)
	qui nwset sender receiver, eventtime(eventtime) name(evnet)
	qui import delimited "`bdir'/data/dynam/`id'_actors.csv", clear varnames(1)
	tempfile av
	qui save `av'
	qui nwload evnet, xvars
	qui merge 1:1 _n using `av', nogenerate
end

_dyn_load e200_n20 "`bdir'"
qui nwdynam evnet, `opt_C1'
_dyn_load `size' "`bdir'"
timer clear 1
timer on 1
capture noisily nwdynam evnet, `opt_`set''
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
file write fh "version`T'nwdynam `e(version)' stata `c(stata_version)'" _n
file close fh
