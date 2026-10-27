* Diagnostic (not a timing run): count the likelihood-plus-gradient evaluations of one nwrem fit.
* Uses a copy of the nwrem v1.0.10 tree whose rem_eval_multi() increments a Stata scalar (the only change).
* Environment: SIZE, SET, SEED, OUT, BENCH, BENCH_PLUS, BENCH_ADOPATH, NWC, TREE.
version 17
set more off
local T = char(9)
local bdir : env BENCH
local size : env SIZE
local set : env SET
local seed : env SEED
local out : env OUT
local tree : env TREE
do "`bdir'/scripts/hdr.do"
qui do "`tree'/unw_rem.do"
local opts_S1_nodsnd_nidrec "nodsnd nidrec"
local opts_S2_degree4 "nodsnd nidrec nidsnd nodrec"
local opts_S3_degree4_inertia "nodsnd nidrec nidsnd nodrec frpsndsnd frrecsnd"
local opts_S4_recency "nodsnd nidrec rsndsnd rrecsnd"
local opts_S5_covariates "nodsnd nidrec covsnd(covsnd) covrec(covrec) covint(covint)"
nwclear
qui import delimited "`bdir'/data/rem/`size'_events.csv", clear varnames(1)
qui nwset sender receiver, eventtime(eventtime) name(bnet)
qui import delimited "`bdir'/data/rem/`size'_cov.csv", clear varnames(1)
tempfile cv
qui save `cv'
qui nwload bnet, xvars
qui merge 1:1 _n using `cv', nogenerate
scalar __nwrem_ne = 0
timer clear 1
timer on 1
qui nwrem bnet, `opts_`set'' seed(`seed')
timer off 1
qui timer list 1
file open fh using "`out'", write text replace
file write fh "secs`T'`=string(r(t1), "%12.4f")'" _n
file write fh "evals`T'`=scalar(__nwrem_ne)'" _n
file close fh
