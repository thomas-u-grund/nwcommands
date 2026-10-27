* Profiling helper (not a timing run): fits MODEL REPS times in one Stata process so that an external sampler
* (prof_sample.py, macOS `sample`) can look at it for a few seconds.  Environment as saom_one.do plus REPS.
version 17
set more off
local bdir : env BENCH
local model : env MODEL
local reps : env REPS
local cores : env CORES
if "`cores'" == "" local cores 1
do "`bdir'/scripts/hdr.do"
global XDIR "`bdir'/data/saom"
include "`bdir'/scripts/bench_models.do"
include "`bdir'/scripts/saom_models_x.do"
mata: __nwsaom_cores = `cores'
local isx = inlist("`model'", "X1", "X2", "X3", "X4", "X5", "X6", "X7", "X8")
local multi = inlist("`model'", "X3", "X4", "X5", "X6")
if `isx' _x_data `model'
else _bench_data `model'
local cmd "`cmd_`model''"
local cmdov : env CMD
if `"`cmdov'"' != "" local cmd `"`cmdov'"'
file open fh using "ready.txt", write text replace
file write fh "start" _n
file close fh
forvalues r = 1/`reps' {
	if `multi' qui nwsaom `cmd' seed(`r')
	else qui nwsaom, `cmd' seed(`r') cores(`cores')
}
