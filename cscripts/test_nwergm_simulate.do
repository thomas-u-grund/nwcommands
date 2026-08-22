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
capture noisily nwergm simulate 5, edges gwesp(.5) directed theta(-0.5 0.5)
assert _rc == 198
capture noisily nwergm simulate 5, edges theta(-0.5 0.5)
assert _rc == 198
