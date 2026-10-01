cscript

do unw_core.do
do unw_ergm.do
do unw_saom.do

* Which simulator a fit used: e(engine) is "native" (the C plugin) or
* "mata", with e(engine_why) and a note in the output when it is Mata
* (2026-10-01). Every model the plugin covers must run natively; this
* test fits one model per effect family and path and asserts it, so that
* a silent fallback to Mata (minutes instead of seconds) cannot go
* unnoticed. Fits use k3(100) (phase 3 only checks convergence here).

capture program drop _eng
program define _eng
	args want
	di as text "engine: `e(engine)' `e(engine_why)'"
	assert "`e(engine)'" == "`want'"
	if "`want'" == "mata" assert "`e(engine_why)'" != ""
end

nwwebuse glasgow, nwclear
qui sum smoke1
gen double smkc = smoke1 - r(mean)
qui sum alcohol1
gen double alcc = alcohol1 - r(mean)
local w2 wave1(glasgow1) wave2(glasgow2)
local o k3(100) seed(1)

* structural effects, conditional and unconditional
nwsaom, `w2' outdegree reciprocity transtrip cycle3 `o'
_eng native
nwsaom, `w2' outdegree reciprocity transtrip cycle3 unconditional `o'
_eng native
nwsaom, `w2' outdegree reciprocity transrectrip transmedtrip `o'
_eng native
nwsaom, `w2' outdegree reciprocity indegpopularity outactivity outpopularity inactivity `o'
_eng native
nwsaom, `w2' outdegree reciprocity isolatenet outiso antiiniso antiiniso2 inplus3 `o'
_eng native
* antiiso and isolatepop ran in Mata before 2026-10-01
nwsaom, `w2' outdegree reciprocity antiiso `o'
_eng native
* (isolatepop is not identified on these data, phase 3 fails; the model's
* native eligibility is checked directly)
capture nwsaom, `w2' outdegree reciprocity isolatepop `o'
mata: __engcfg = SaomNativeSetup(__nwsaom_last_M)
mata: assert(__engcfg.eligible == 1)
nwsaom, `w2' outdegree reciprocity outoutass ininass outinass inoutass `o'
_eng native
nwsaom, `w2' outdegree reciprocity cycle4 gwesp(.69) transties `o'
_eng native
nwsaom, `w2' outdegree reciprocity balance `o'
_eng native

* covariates, several variables per effect, simx() centred (protocol 9)
nwsaom, `w2' outdegree reciprocity samex(smoke1 sport1) nodecov(alcc) `o'
_eng native
nwsaom, `w2' outdegree reciprocity egox(alcc smkc) altx(alcc smkc) simx(alcc smkc) `o'
_eng native
* interactions: old single-variable syntax, per-variable syntax, aliases
nwsaom, `w2' outdegree reciprocity samex(smoke1) interact(samex#reciprocity) `o'
_eng native
nwsaom, `w2' outdegree reciprocity nodematch(smoke1 sport1) interact(nodematch_sport1#reciprocity samex_smoke1#reciprocity) `o'
_eng native
nwsaom, `w2' outdegree reciprocity egox(alcc smkc) interact(egox_alcc#reciprocity) `o'
_eng native
* covariate-dependent rate, two variables
nwsaom, `w2' outdegree reciprocity ratecov(smkc alcc) `o'
_eng native

* multi-wave, missing data, composition change
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip samex(smoke1 sport1) `o'
_eng native
gen byte p1 = 1
gen byte p2 = _n != 3
nwsaom, `w2' outdegree reciprocity present(p1 p2) unconditional `o'
_eng native

* non-directed relations
nwtomata glasgow1, mat(__g1)
nwtomata glasgow2, mat(__g2)
mata: __s1 = (__g1 + __g1') :> 0
mata: __s2 = (__g2 + __g2') :> 0
nwset, mat(__s1) undirected name(u1)
nwset, mat(__s2) undirected name(u2)
nwsaom, wave1(u1) wave2(u2) outdegree samex(smoke1 sport1) `o'
_eng native
nwsaom, wave1(u1) wave2(u2) outdegree symtype(joint) unconditional `o'
_eng native

* co-evolution (network side with two covariates)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity samex(sport1 alcohol1) behsim ///
	behavior(smoke1 smoke2 smoke3) linear quadratic avalt `o'
_eng native

* multiplex
nwsaom multiplex, netawave1(glasgow1) netawave2(glasgow2) netbwave1(glasgow2) netbwave2(glasgow3) k3(100) seed(1)
_eng native

* formerly Mata-only (native from protocol 11, 2026-10-01): network
* endowment/creation, structural(), three-way interactions, behavior
* endowment/creation
nwsaom, `w2' outdegree reciprocityendow reciprocitycreation `o'
_eng native
nwsaom, `w2' outdegree reciprocityendow reciprocitycreation unconditional `o'
_eng native
nwtomata glasgow1, mat(__a1)
nwtomata glasgow2, mat(__a2)
mata: __st = J(50, 50, 0)
mata: __st[1..10, 1..10] = (__a1[1..10, 1..10] :== __a2[1..10, 1..10]) :* (1 :- I(10))
mata: st_matrix("__structfrozen", __st)
nwsaom, `w2' outdegree reciprocity structural(__structfrozen) `o'
_eng native
nwsaom, `w2' outdegree reciprocity samex(smoke1) egox(alcc) interact(samex#reciprocity#egox) `o'
_eng native
* (the behavior endowment/creation models do not converge on these data;
* the simulator chosen is checked)
capture nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity behavior(smoke1 smoke2 smoke3) ///
	linear quadratic avaltendow avaltcreation `o'
mata: st_local("__eng", __nwsaom_engine)
di as text "engine (behavior endowment/creation): `__eng'"
assert "`__eng'" == "native"
* estat gof of a co-evolution fit and of an endowment/creation fit run
* natively too (no engine flag; they must run and be quick)
nwsaom, `w2' outdegree reciprocityendow reciprocitycreation `o'
timer clear 9
timer on 9
estat gof, nsim(50) seed(3)
timer off 9
qui timer list 9
di as text "estat gof (endowment/creation, 50 simulations): " r(t9) " s"
assert r(t9) < 20

di as text "test_nwsaom_engine: all checks passed"
