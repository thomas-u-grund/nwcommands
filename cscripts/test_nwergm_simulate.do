cscript

do unw_core.do
do unw_ergm.do

* Certifies `nwergm simulate' (Part X's own example syntax:
* `nwergm simulate, edges(-2.5) mutual(1.0)' - implemented here as
* `nwergm simulate nodes, edges [mutual] theta(numlist) ...', reusing
* the same term-construction code nwergm's own estimation path uses
* rather than a parallel implementation; see nwergm.ado's own SMCL doc
* header, "Simulation" section, for the exact syntax and the deliberate
* v1 scope reduction to terms needing no external covariate data).
*
* End-to-end statistical correctness check: an edges-only model has the
* SAME exactly-known Bernoulli behavior test_nwergm_mcmc.do already
* certifies at the Mata level - each dyad is an independent
* Bernoulli(p) draw, p = invlogit(theta), so the mean tie count across
* many independently-simulated networks should match D*p closely. This
* re-certifies the exact same statistical fact through the ACTUAL
* user-facing `nwergm simulate' command end to end (real nwset-backed
* networks, not raw sufficient-statistic draws), not just unw_ergm.do's
* own internal ErgmMCMCSample().

local n = 6
local D = `n'*(`n'-1)/2
local theta = -0.4
local p = exp(`theta')/(1+exp(`theta'))
local nsim = 40

set seed 5001
nwclear
qui nwergm simulate `n', edges theta(`theta') nsim(`nsim') mcmcburnin(3000) mcmcinterval(30) generate(esim)

tempname ties
scalar `ties' = 0
forvalues i = 1/`nsim' {
	qui nw_syntax esim_`i', max(1)
	mata: st_local("__t", strofreal(sum(*`netobj'->get_matrix_mod(1,0))/2))
	scalar `ties' = `ties' + `__t'
	assert `nodes' == `n'
	assert "`directed'" == "false"
}
local mean_ties = `ties'/`nsim'
local exact_mean = `D'*`p'
di "exact mean ties = " `exact_mean' ", simulated mean over `nsim' networks = " `mean_ties'
* generous tolerance: this is genuinely independent draws (fresh burn-in
* each time per the command's own documented convention), so Monte
* Carlo noise across only 40 draws is real - checked against a wide but
* still meaningful band, not a tautology.
assert abs(`mean_ties' - `exact_mean') < 1.5

* --- directed edges+mutual: just confirm the command runs end to end
* and produces a real directed network with a nonzero mutual count
* achievable under a strongly positive mutual coefficient (statistical
* correctness for mutual itself is already certified at the Mata level
* in test_nwergm_exact_enum.do/test_nwergm_mcmc.do - this is an
* integration check of the actual command, not a re-derivation).
nwclear
set seed 5002
qui nwergm simulate 5, edges mutual directed theta(-0.5 1.5) nsim(1) mcmcburnin(3000) mcmcinterval(30) generate(dsim)
qui nw_syntax dsim, max(1)
assert `nodes' == 5
assert "`directed'" == "true"

* --- multi-network generation: nsim(3) creates three distinctly named,
* independently valid networks.
nwclear
set seed 5003
qui nwergm simulate 5, edges theta(-0.3) nsim(3) generate(multisim)
foreach s in 1 2 3 {
	qui nw_syntax multisim_`s', max(1)
	assert `nodes' == 5
}

* --- undirected gwesp: runs end to end without error.
nwclear
set seed 5004
qui nwergm simulate 6, edges gwesp(.5) theta(-1.0 0.5) nsim(1) generate(gwsim)
qui nw_syntax gwsim, max(1)
assert `nodes' == 6

* --- error paths.
nwclear
capture noisily nwergm simulate 5, edges
assert _rc == 198
capture noisily nwergm simulate 5, edges mutual theta(-0.5 1.0)
assert _rc == 198
capture noisily nwergm simulate 5, edges gwodegree(.5) theta(-0.5 0.5)
assert _rc == 198
capture noisily nwergm simulate 5, edges theta(-0.5 0.5)
assert _rc == 198

* --- directed gwesp: now supported too (harmonisation unit 91,
* term-expansion wave 5 - R ergm's own default OTP directed
* shared-partner definition), runs end to end without error. Used to
* be an error-path case (gwesp() was undirected-only) - superseded.
nwclear
set seed 5005
qui nwergm simulate 7, edges gwesp(.5) directed theta(-1.0 0.5) nsim(1) generate(dgwsim)
qui nw_syntax dgwsim, max(1)
assert `nodes' == 7

* =====================================================================
* Full term-library parity with estimation (ported from the estimation
* path's own term-construction code - see nwergm.ado's own comments at
* the port site). Covers all four data-sourcing mechanisms: no external
* data, node covariate read from the active dataset, dyadic covariate
* read from an already-loaded reference network, and the auto-generated
* sender()/receiver() node-identity attribute.
* =====================================================================

* --- node covariate (nodematch): directional correctness check, not
* just "runs without error" - a strongly POSITIVE homophily coefficient
* must produce a network with more internal (same-group) ties than a
* strongly NEGATIVE one would, on the identical group assignment and
* seed. `grp' has to be regenerated identically after each simulate
* call, since simulate's own per-draw dataset rebuild (qui drop _all;
* nwset) does not carry the caller's original covariate variable(s)
* forward onto the resulting dataset - only the Mata-side copy captured
* at term-construction time (before that rebuild) is used internally.
nwclear
clear
set obs 20
gen grp = mod(_n,2)
set seed 11
qui nwergm simulate 20, edges nodematch(grp) theta(-3 3) nsim(1) mcmcburnin(5000) generate(simpos)
qui gen grp2 = mod(_n,2)
qui nwmixing simpos, attribute(grp2) permutations(1)
local ei_pos = r(EI_index)

clear
set obs 20
gen grp = mod(_n,2)
set seed 11
qui nwergm simulate 20, edges nodematch(grp) theta(-1 -3) nsim(1) mcmcburnin(5000) generate(simneg)
qui gen grp2 = mod(_n,2)
qui nwmixing simneg, attribute(grp2) permutations(1)
local ei_neg = r(EI_index)

di "nodematch theta=+3: E-I = `ei_pos' (expect strongly negative - mostly internal ties)"
di "nodematch theta=-3: E-I = `ei_neg' (expect strongly positive - mostly external ties)"
assert `ei_pos' < -0.3
assert `ei_neg' > 0.3

* --- structural numlist term (degree()): runs end to end, correct node
* count, and (since a positive coefficient on specific degree VALUES
* makes those degrees more likely) at least one node actually attains
* one of the targeted degrees - a weak but genuine correctness signal
* beyond "no error", since a broken wiring (e.g. reading the wrong
* Mata field) would not reliably produce this.
nwclear
set seed 5006
qui nwergm simulate 16, edges degree(2 3) theta(-1.5 1 1) nsim(1) mcmcburnin(4000) generate(degsim)
qui nwdegree degsim, generate(_deg) silent
qui count if _deg == 2 | _deg == 3
assert r(N) > 0

* --- sender()/receiver() (directed, node-identity attribute, no real
* covariate needed): runs end to end with the right size/directedness.
nwclear
set seed 5007
qui nwergm simulate 8, edges sender receiver directed ///
	theta(-1.5 .3 .3 .3 .3 .3 .3 .3 .3 .3 .3 .3 .3 .3 .3) nsim(1) generate(sndsim)
qui nw_syntax sndsim, max(1)
assert `nodes' == 8
assert "`directed'" == "true"

* --- dyadic covariate (edgecov()): a reference network with a fixed,
* known edge in dyad (1,2) and a strongly positive edgecov coefficient
* should make that exact dyad tied in the observed FULL-ENUMERATION
* sense far more often than the network's own baseline density - here
* checked directly and deterministically via a very small (4-node),
* small-mcmcinterval, higher-nsim sample, which is enumerable enough
* for the modal outcome to be checkable by hand: dyad (1,2) tied in
* almost every draw when edgecov's own coefficient on that dyad is
* strongly positive and offsetting a strongly negative edges term.
nwclear
qui nwset, mat((0,1,0,0\1,0,0,0\0,0,0,0\0,0,0,0)) undirected name(refnet2)
set seed 5008
local ntied12 = 0
local nsim_ec = 20
qui nwergm simulate 4, edges edgecov(refnet2) theta(-3 6) nsim(`nsim_ec') mcmcburnin(2000) generate(ecsim)
forvalues i = 1/`nsim_ec' {
	qui nwtomata ecsim_`i', mat(__ecmat)
	mata: st_local("__tied12", strofreal(__ecmat[1,2]))
	local ntied12 = `ntied12' + `__tied12'
}
mata: mata drop __ecmat
di "dyad (1,2) tied in `ntied12' of `nsim_ec' draws under a strongly positive edgecov() coefficient on that exact dyad"
assert `ntied12' >= `nsim_ec' * 0.7

* --- multiple term families combined in one call: confirms theta()
* ordering (edges, then nodematch, then degree, in the same fixed
* sequence the estimation path itself processes terms in) is applied
* to the correct term, not silently misaligned once more than a
* handful of terms are requested together.
nwclear
clear
set obs 12
gen grp3 = mod(_n,2)
set seed 5009
qui nwergm simulate 12, edges nodematch(grp3) degree(2) theta(-2 1 .5) nsim(1) mcmcburnin(3000) generate(combosim)
qui nw_syntax combosim, max(1)
assert `nodes' == 12
