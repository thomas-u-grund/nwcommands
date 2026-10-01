cscript

do unw_core.do
do unw_ergm.do
do unw_saom.do

* Covariate effects for several variables (2026-10-01): naming, order,
* interact(), ratecov(), simx() centring. Estimates are checked against
* RSiena in test_nwsaom_rsiena.do; this file checks the bookkeeping.

nwwebuse glasgow, nwclear
qui sum smoke1
gen double smkc = smoke1 - r(mean)
qui sum alcohol1
gen double alcc = alcohol1 - r(mean)
local w12 wave1(glasgow1) wave2(glasgow2)
local o k3(100) seed(1)

capture program drop _names
program define _names
	args want
	local got : colnames e(b)
	di as text "e(b): `got'"
	assert "`got'" == "`want'"
end

* one coefficient per (effect, variable), named <effect>_<variable>, in
* the order the variables are listed; a single variable keeps its name
nwsaom, `w12' outdegree reciprocity samex(smoke1 sport1) `o'
_names "outdegree reciprocity samex_smoke1 samex_sport1"
nwsaom, `w12' outdegree reciprocity samex(sport1 smoke1) `o'
_names "outdegree reciprocity samex_sport1 samex_smoke1"
nwsaom, `w12' outdegree reciprocity nodematch(smoke1) `o'
_names "outdegree reciprocity nodematch_smoke1"
nwsaom, `w12' outdegree reciprocity samex(smoke1) `o'
_names "outdegree reciprocity samex_smoke1"
* effect types in their fixed order (theta0() follows e(b)'s order)
nwsaom, `w12' outdegree reciprocity samex(smoke1) nodecov(alcc smkc) `o'
_names "outdegree reciprocity samex_smoke1 nodecov_alcc nodecov_smkc"
nwsaom, `w12' outdegree reciprocity samex(smoke1 sport1) egox(alcc smkc) altx(alcc smkc) simx(alcc smkc) `o'
_names "outdegree reciprocity samex_smoke1 samex_sport1 altx_alcc altx_smkc egox_alcc egox_smkc simx_alcc simx_smkc"
matrix __b0 = e(b)
local t0
forvalues j = 1/`=colsof(__b0)' {
	local t0 `t0' `=__b0[1,`j']'
}
nwsaom, `w12' outdegree reciprocity samex(smoke1 sport1) egox(alcc smkc) altx(alcc smkc) simx(alcc smkc) theta0(`t0') `o'
matrix __b1 = e(b)
assert mreldif(__b1, __b0) < 0.5
* a variable abbreviation and a wildcard expand as varlists
nwsaom, `w12' outdegree reciprocity samex(smoke1 sport*) `o'
_names "outdegree reciprocity samex_smoke1 samex_sport1 samex_sport2 samex_sport3"
capture nwsaom, `w12' outdegree reciprocity samex(nosuchvar) `o'
assert _rc == 111

* interact(): the old syntax with one variable, a variable's effect by its
* coefficient name, either spelling, and the ambiguous case
nwsaom, `w12' outdegree reciprocity samex(smoke1) interact(samex#reciprocity) `o'
_names "outdegree reciprocity samex_smoke1 interact_nodematch_reciprocity"
assert "`e(engine)'" == "native"
nwsaom, `w12' outdegree reciprocity samex(smoke1 sport1) interact(samex_sport1#reciprocity) `o'
* (interact_samex_sport1_reciprocity has 33 characters, one more than a
* Stata name allows: ix_ instead of interact_)
_names "outdegree reciprocity samex_smoke1 samex_sport1 ix_samex_sport1_reciprocity"
assert "`e(engine)'" == "native"
matrix __bi = e(b)
* the same interaction named with the other spelling
nwsaom, `w12' outdegree reciprocity samex(smoke1 sport1) interact(nodematch_sport1#reciprocity) `o'
matrix __bi2 = e(b)
assert mreldif(__bi2, __bi) < 1e-12
* the interaction uses sport1, not smoke1: different from interacting smoke1
nwsaom, `w12' outdegree reciprocity samex(smoke1 sport1) interact(samex_smoke1#reciprocity) `o'
matrix __bi3 = e(b)
assert mreldif(__bi3, __bi) > 1e-6
capture noisily nwsaom, `w12' outdegree reciprocity samex(smoke1 sport1) interact(samex#reciprocity) `o'
assert _rc == 198
capture noisily nwsaom, `w12' outdegree reciprocity samex(smoke1) interact(samex_sport1#reciprocity) `o'
assert _rc == 198
* the component instance is recorded (native slot of sport1's term)
mata: __cfg = SaomNativeSetup(__nwsaom_last_M)
nwsaom, `w12' outdegree reciprocity samex(smoke1 sport1) interact(samex_sport1#reciprocity) `o'
mata: __cfg = SaomNativeSetup(__nwsaom_last_M)
mata: assert(__cfg.termcodes[5] == 30 & __cfg.attridx[5] == 4 & __cfg.p1[5] == 2)

* ratecov(): one coefficient per variable; one variable keeps the scalars
nwsaom, `w12' outdegree reciprocity ratecov(smkc) `o'
assert e(ratecoef) < . & e(ratecoef_se) < .
matrix __rc = e(ratecoefs)
assert colsof(__rc) == 1 & reldif(__rc[1,1], e(ratecoef)) < 1e-12
nwsaom, `w12' outdegree reciprocity ratecov(smkc alcc) ratecovcoef(0.5 0) `o'
matrix __rc = e(ratecoefs)
local rn : colnames __rc
assert "`rn'" == "smkc alcc"
assert e(ratecoef) == .
local tn : colnames e(tconv)
assert "`tn'" == "outdegree reciprocity ratecoef_smkc ratecoef_alcc"
capture noisily nwsaom, `w12' outdegree reciprocity ratecov(smkc alcc) ratecovcoef(0.5 0 1) `o'
assert _rc == 198

* simx() is centred by the similarity mean of the covariate (RSiena):
* the similarity mean of alcohol1 over all ordered pairs
mata:
__x = st_data(., "alcohol1")
__D = 1 :- abs(__x * J(1, rows(__x), 1) - J(rows(__x), 1, 1) * __x') :/ (max(__x) - min(__x))
__m = (sum(__D) - trace(__D)) / (rows(__x) * (rows(__x) - 1))
assert(abs(SaomSimMean(__x) - __m) < 1e-12)
end

* covariates are centred by their means by default, like RSiena's
* coCovar(centered = TRUE): egox() of the raw variable gives the same
* fit as egox() of the centred variable; nocenter keeps the raw values
* (then the outdegree coefficient changes, the egox coefficient does not
* in expectation); e(covmeans) holds the means, e(centered) the choice
nwsaom, `w12' outdegree reciprocity egox(alcohol1) altx(alcohol1) `o'
matrix __braw = e(b)
assert e(centered) == 1
matrix __cm = e(covmeans)
local cn : colnames __cm
assert "`cn'" == "alcohol1"
qui sum alcohol1
assert reldif(__cm[1,1], r(mean)) < 1e-12
nwsaom, `w12' outdegree reciprocity egox(alcc) altx(alcc) `o'
matrix __bc = e(b)
assert mreldif(__braw, __bc) < 1e-8
nwsaom, `w12' outdegree reciprocity egox(alcohol1) altx(alcohol1) nocenter `o'
assert e(centered) == 0
matrix __bn = e(b)
assert abs(__bn[1,1] - __braw[1,1]) > 0.1
* ratecov() is centred too
nwsaom, `w12' outdegree reciprocity ratecov(smoke1) `o'
local r1 = e(ratecoef)
nwsaom, `w12' outdegree reciprocity ratecov(smkc) `o'
assert reldif(e(ratecoef), `r1') < 1e-8
* RSiena's effect names, in e(b)'s order
nwsaom, `w12' outdegree reciprocity samex(smoke1) egox(alcohol1) interact(reciprocity#egox) `o'
assert `"`e(rsiena_labels)'"' == "outdegree (density)|reciprocity|same smoke1|alcohol1 ego|alcohol1 ego x reciprocity"
di as text "test_nwsaom_covariates: all checks passed"
