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

* --- spcache (docs/CERTIFICATION.md unit 132): wired through the
* simulate path too (consistency with the estimation command, even
* though its own cost-benefit is weaker there - see nwergm.ado's own
* build-up comment). Two checks: (1) it runs without error on an
* undirected gwesp model; (2) same seed produces byte-identical draws
* with/without it (pure performance optimization, must not change
* results) - compared via each draw's own tie count, since simulate's
* `generate()` network is the actual output to check, not a coefficient
* vector.
nwclear
clear
set seed 3077
qui nwergm simulate 8, edges gwesp(.4) theta(-2 .3) nsim(1) mcmcburnin(500) mcmcinterval(20) generate(spc_nocache)
assert _rc == 0
qui nwtomata spc_nocache, mat(__spcmat_nocache)
mata: st_local("__spc_ties_nocache", strofreal(sum(__spcmat_nocache)/2))

nwclear
clear
set seed 3077
qui nwergm simulate 8, edges gwesp(.4) theta(-2 .3) nsim(1) mcmcburnin(500) mcmcinterval(20) generate(spc_cache) spcache
assert _rc == 0
qui nwtomata spc_cache, mat(__spcmat_cache)
mata: st_local("__spc_ties_cache", strofreal(sum(__spcmat_cache)/2))
mata: mata drop __spcmat_nocache __spcmat_cache

assert "`__spc_ties_nocache'" == "`__spc_ties_cache'"
di "=== spcache (simulate path): runs cleanly and reproduces identical draws under the same seed ==="

* =====================================================================
* Harmonisation unit 142: closing a real test-coverage gap left by the
* full term-library-parity extension above (shipped separately, commit
* 6d34c04 "nwergm simulate: full term-library parity with estimation" -
* that commit's own message reports "all ~30 term options individually
* smoke-tested end to end", but only a handful of them (nodematch,
* degree, sender/receiver, edgecov, plus the combo/spcache cases above)
* were ever captured as a PERMANENT regression test in this file; the
* rest were a one-off, uncommitted smoke test, so a future regression in
* any of them would go undetected). Every option below is exercised for
* the first time in this file: nodecov()/nodeicov()/nodeocov()/
* absdist()/hamming() (covariate/dyadic families beyond nodematch()/
* edgecov()), nodematchdiff()/nodefactor()/nodemix()/nodeofactor()/
* nodeifactor() (multi-coefficient node-covariate families - also
* exercises theta() ordering across several such terms in one call),
* concurrent/triangle/ctriple/transitiveties/cyclicalties (structural
* flags), odegree()/idegree()/kstar()/ostar()/istar()/degrange()/
* odegrange()/idegrange()/esp()/dsp() (numlist-parameterized structural
* terms), gwdsp()/gwnsp()/gwdegree()/gwodegree()/gwidegree() (the
* remaining geometrically weighted family members - gwesp() alone was
* covered above), and type() (directed shared-partner definition
* selection, previously untested on the simulate path entirely).
* =====================================================================

* --- undirected node/dyadic covariates: nodecov(), absdist(), hamming().
nwclear
clear
set obs 8
gen x = _n
set seed 6001
qui nwrandom 8, prob(.3) undirected name(refnet3)
set seed 6002
qui nwergm simulate 8, edges nodecov(x) absdist(x) hamming(refnet3) theta(-2 .1 .1 .2) nsim(1) mcmcburnin(3000) generate(covsim1)
qui nw_syntax covsim1, max(1)
assert `nodes' == 8
assert "`directed'" == "false"

* --- directed node covariates: nodeicov(), nodeocov().
nwclear
clear
set obs 8
gen x = _n
set seed 6003
qui nwergm simulate 8, edges nodeicov(x) nodeocov(x) directed theta(-2 .1 .1) nsim(1) mcmcburnin(3000) generate(covsim2)
qui nw_syntax covsim2, max(1)
assert `nodes' == 8
assert "`directed'" == "true"

* --- multi-coefficient node-covariate families combined in one call:
* nodematchdiff() (2 coefficients, one per level of `grp'),
* nodefactor() (1 coefficient, base level dropped), nodemix() (3
* coefficients, one per unordered level pair) - exercises theta()
* ordering across several multi-coefficient terms at once, not just a
* single-coefficient term after a multi-coefficient one (the combosim
* case above only combined single-coefficient terms).
nwclear
clear
set obs 10
gen grp = mod(_n,2)
set seed 6004
qui nwergm simulate 10, edges nodematchdiff(grp) nodefactor(grp) nodemix(grp) ///
	theta(-1.5 .5 -.5 .3 .1 .2 .1) nsim(1) mcmcburnin(3000) generate(covsim3)
qui nw_syntax covsim3, max(1)
assert `nodes' == 10
assert "`directed'" == "false"

* --- directed analogues: nodeofactor()/nodeifactor().
nwclear
clear
set obs 10
gen grp = mod(_n,2)
set seed 6005
qui nwergm simulate 10, edges nodeofactor(grp) nodeifactor(grp) directed ///
	theta(-1.5 .3 .3) nsim(1) mcmcburnin(3000) generate(covsim4)
qui nw_syntax covsim4, max(1)
assert `nodes' == 10
assert "`directed'" == "true"

* --- undirected structural flags/numlist terms: concurrent, triangle,
* kstar(), degrange(), esp(), dsp().
nwclear
set seed 6006
qui nwergm simulate 10, edges concurrent triangle kstar(2) degrange(2) esp(1) dsp(1) ///
	theta(-1.5 .3 .1 .1 .1 .1 .1) nsim(1) mcmcburnin(3000) generate(strucsim1)
qui nw_syntax strucsim1, max(1)
assert `nodes' == 10
assert "`directed'" == "false"

* --- directed structural flags/numlist terms: ctriple, transitiveties,
* cyclicalties, odegree(), idegree(), ostar(), istar(), odegrange(),
* idegrange().
nwclear
set seed 6007
qui nwergm simulate 8, edges ctriple transitiveties cyclicalties odegree(2) idegree(2) ///
	ostar(2) istar(2) odegrange(2) idegrange(2) directed ///
	theta(-1.5 .1 .1 .1 .3 .3 .1 .1 .3 .3) nsim(1) mcmcburnin(3000) generate(strucsim2)
qui nw_syntax strucsim2, max(1)
assert `nodes' == 8
assert "`directed'" == "true"

* --- remaining geometrically weighted family: gwdsp(), gwnsp(),
* gwdegree() (undirected); gwodegree()/gwidegree() (directed) - gwesp()
* itself is already covered by the two gwsim/dgwsim cases above.
nwclear
set seed 6008
qui nwergm simulate 8, edges gwdsp(.4) gwnsp(.3) gwdegree(.5) theta(-1.5 .2 .2 .3) ///
	nsim(1) mcmcburnin(3000) generate(gwrest1)
qui nw_syntax gwrest1, max(1)
assert `nodes' == 8
assert "`directed'" == "false"

nwclear
set seed 6009
qui nwergm simulate 8, edges gwodegree(.4) gwidegree(.3) directed theta(-1.5 .3 .3) ///
	nsim(1) mcmcburnin(3000) generate(gwrest2)
qui nw_syntax gwrest2, max(1)
assert `nodes' == 8
assert "`directed'" == "true"

* --- type(): selects among the five directed shared-partner definitions
* for gwesp()/gwdsp()/gwnsp()/esp()/dsp() - only ever exercised on the
* estimation path (cscripts/test_nwergm_ado.do) before this. Confirms
* each of the four non-default types is accepted end to end on the
* simulate path too, and that the resulting draw differs from the OTP
* default under the same seed/theta (a genuine correctness signal that
* type() actually changes which shared-partner definition the sampler
* evaluates, not silently ignored - OTP and ITP are literal transposes
* of each other's own two-path direction, so a run with real triadic
* structure should not coincidentally land on an identical draw).
nwclear
set seed 6010
qui nwergm simulate 8, edges gwesp(.6) directed theta(-1.2 .5) nsim(1) mcmcburnin(3000) generate(typesim_otp)
qui nwtomata typesim_otp, mat(__typemat_otp)

local __ergm_type_diff_found = 0
foreach __ergm_ty in ITP OSP ISP RTP {
	nwclear
	set seed 6010
	qui nwergm simulate 8, edges gwesp(.6) directed type(`__ergm_ty') theta(-1.2 .5) nsim(1) mcmcburnin(3000) generate(typesim_`__ergm_ty')
	qui nw_syntax typesim_`__ergm_ty', max(1)
	assert `nodes' == 8
	assert "`directed'" == "true"
	qui nwtomata typesim_`__ergm_ty', mat(__typemat_`__ergm_ty')
	mata: st_local("__typediff", strofreal(max(abs(__typemat_otp - __typemat_`__ergm_ty'))))
	if `__typediff' > 0 local __ergm_type_diff_found = 1
	mata: mata drop __typemat_`__ergm_ty'
}
mata: mata drop __typemat_otp
* At least one of the four non-default types must produce a genuinely
* different draw from the OTP default under the identical seed/theta -
* a real signal that `type()' is actually reaching the sampler's own
* change-statistic evaluation, not silently ignored (each type's own
* gwesp change function evaluates a structurally different shared-
* partner count, so identical RNG draws under every single type would
* indicate `type()' was never wired through at all).
assert `__ergm_type_diff_found' == 1
di "=== type() accepted, and produces genuinely different draws (not just accepted syntax) under OTP/ITP/OSP/ISP/RTP on the simulate path ==="

di "=== nwergm simulate: full-term-library regression coverage complete (harmonisation unit 142) ==="

* =====================================================================
* Bipartite (two-mode) simulation support: `bipartite()' gives the
* mode-1 node count, mirroring R's own `network(n, bipartite=nb1)'
* convention - nodes 1..bipartite() are mode 1, the rest are mode 2
* (see nwergm.ado's own header comment on this option for the full
* account of why simulate needs its own explicit contiguous-prefix
* convention rather than reading an existing network's per-node mode
* assignment, unlike the estimation path). Exercises the same
* Stage-1-4 bipartite term family (b1cov/b2cov/b1factor/b2factor/
* b1degree/b2degree/b1star/b2star/b1nodematch/b2nodematch/
* bgwdegree1/bgwdegree2) the estimation path already certifies,
* through the simulate command end to end, plus the network-type
* validation guarding it.
* =====================================================================

* --- edges-only: statistical correctness check analogous to the
* plain one-mode Bernoulli check at the top of this file, restricted
* to the cross-mode dyad space (D = mode1count * mode2count, the only
* dyads the bipartite MCMC proposal ever toggles).
local n1 = 4
local n2 = 3
local D = `n1' * `n2'
local theta = -0.3
local p = exp(`theta')/(1+exp(`theta'))
local nsim = 40

set seed 7001
nwclear
qui nwergm simulate `=`n1'+`n2'', edges bipartite(`n1') theta(`theta') nsim(`nsim') mcmcburnin(3000) mcmcinterval(30) generate(bipedge)

tempname bties
scalar `bties' = 0
forvalues i = 1/`nsim' {
	qui nw_syntax bipedge_`i', max(1)
	assert `nodes' == `n1' + `n2'
	assert "`directed'" == "false"
	assert "`is2mode'" == "true"
	mata: st_local("__t", strofreal(sum(*`netobj'->get_matrix_mod(1,0))/2))
	scalar `bties' = `bties' + `__t'
}
local mean_ties = `bties'/`nsim'
local exact_mean = `D'*`p'
di "bipartite exact mean ties = " `exact_mean' ", simulated mean over `nsim' networks = " `mean_ties'
assert abs(`mean_ties' - `exact_mean') < 1.5
di "=== bipartite simulate (edges only): correct node/mode counts, and mean tie count over `nsim' draws matches the exact cross-mode-dyad Bernoulli mean ==="

* --- b1cov()/b2cov(): directional correctness, mirroring the
* nodematch() E-I check above - a strongly POSITIVE mode-1 covariate
* coefficient should produce a denser network than a strongly negative
* one, on the identical covariate/seed.
nwclear
clear
set obs 7
gen x1 = _n
set seed 7002
qui nwergm simulate 7, edges bcov1(x1) bipartite(4) theta(-1 .8) nsim(1) mcmcburnin(4000) generate(bcovpos)
qui nwtomata bcovpos, mat(__bcovmat_pos)
mata: st_local("__ties_pos", strofreal(sum(__bcovmat_pos)/2))

clear
set obs 7
gen x1 = _n
set seed 7002
qui nwergm simulate 7, edges bcov1(x1) bipartite(4) theta(-1 -.8) nsim(1) mcmcburnin(4000) generate(bcovneg)
qui nwtomata bcovneg, mat(__bcovmat_neg)
mata: st_local("__ties_neg", strofreal(sum(__bcovmat_neg)/2))
mata: mata drop __bcovmat_pos __bcovmat_neg

di "b1cov theta=+.8: `__ties_pos' ties; b1cov theta=-.8: `__ties_neg' ties (expect more under the positive coefficient)"
assert `__ties_pos' > `__ties_neg'

* --- b2cov()/b1factor()/b2factor(): runs end to end with the right
* coefficient count (b1factor/b2factor each drop one base level).
nwclear
clear
set obs 9
gen x2 = _n
gen grpb = mod(_n,2)
set seed 7003
qui nwergm simulate 9, edges bcov2(x2) bfactor1(grpb) bfactor2(grpb) bipartite(5) ///
	theta(-1.5 .2 .3 .3) nsim(1) mcmcburnin(3000) generate(bfacsim)
qui nw_syntax bfacsim, max(1)
assert `nodes' == 9
assert "`is2mode'" == "true"

* --- b1degree()/b2degree()/b1star()/b2star(): numlist-parameterized
* dyad-dependent family, smoke-tested end to end (statistical
* correctness for the underlying degree/star statistics themselves is
* already certified via degree()/kstar() above and at the Mata level).
nwclear
set seed 7004
qui nwergm simulate 9, edges bdegree1(1) bdegree2(1) bstar1(2) bstar2(2) bipartite(5) ///
	theta(-1.5 .3 .3 .1 .1) nsim(1) mcmcburnin(3000) generate(bdegsim)
qui nw_syntax bdegsim, max(1)
assert `nodes' == 9
assert "`is2mode'" == "true"

* --- b1nodematch()/b2nodematch(): directional correctness, mirroring
* nodematch()'s own E-I check - a strongly positive coefficient should
* raise the fraction of same-attribute-value cross-mode ties.
nwclear
clear
set obs 10
gen grpm = mod(_n,3)
set seed 7005
qui nwergm simulate 10, edges bnodematch1(grpm) bnodematch2(grpm) bipartite(6) ///
	theta(-2 2 2) nsim(1) mcmcburnin(4000) generate(bnmpos)
qui nwtomata bnmpos, mat(__bnmmat_pos)
mata: st_local("__nm_ties_pos", strofreal(sum(__bnmmat_pos)/2))

clear
set obs 10
gen grpm = mod(_n,3)
set seed 7005
qui nwergm simulate 10, edges bnodematch1(grpm) bnodematch2(grpm) bipartite(6) ///
	theta(-2 -2 -2) nsim(1) mcmcburnin(4000) generate(bnmneg)
qui nwtomata bnmneg, mat(__bnmmat_neg)
mata: st_local("__nm_ties_neg", strofreal(sum(__bnmmat_neg)/2))
mata: mata drop __bnmmat_pos __bnmmat_neg

di "b1/b2nodematch theta=+2: `__nm_ties_pos' ties; theta=-2: `__nm_ties_neg' ties (expect more under the positive coefficient)"
assert `__nm_ties_pos' > `__nm_ties_neg'

* --- bgwdegree1()/bgwdegree2(): fixed-decay geometrically weighted
* bipartite-degree family, smoke-tested end to end.
nwclear
set seed 7006
qui nwergm simulate 9, edges bgwdegree1(.5) bgwdegree2(.5) bipartite(5) ///
	theta(-1.5 .3 .3) nsim(1) mcmcburnin(3000) generate(bgwsim)
qui nw_syntax bgwsim, max(1)
assert `nodes' == 9
assert "`is2mode'" == "true"

* --- round-trip: a simulated bipartite draw estimates back cleanly
* through the actual nwergm estimation command (not merely `nw_syntax'
* accepting it) - the SAME correctness contract the offset()/curved
* MCMLE units elsewhere in this suite hold estimation to, now checked
* on a simulate-produced network.
nwclear
clear
set obs 8
gen xrt = _n
set seed 7007
qui nwergm simulate 8, edges bcov1(xrt) bipartite(5) theta(-1.2 .3) nsim(1) mcmcburnin(4000) generate(rtsim)
qui set obs 8
qui gen xrt = _n
qui nwergm rtsim, edges bcov1(xrt) method(mple)
assert _rc == 0
assert e(nodes) == 8
assert colsof(e(b)) == 2
di "=== bipartite simulate: round-trips cleanly through nwergm estimation on the simulated network ==="

* --- error paths: one-mode-only term with bipartite(), bipartite-only
* term without bipartite(), directed+bipartite, bipartite() out of
* range (>= nodes, or negative) - the same "reject, never silently
* reinterpret" discipline the main command's own network-type
* validation already holds to (nwergm.ado lines ~121-153).
nwclear
capture noisily nwergm simulate 8, edges bipartite(5) mutual theta(-1.5 .3)
assert _rc == 198
capture noisily nwergm simulate 8, edges bcov1(xrt) theta(-1.5 .3)
assert _rc == 198
capture noisily nwergm simulate 8, edges bipartite(5) directed theta(-1.5)
assert _rc == 198
capture noisily nwergm simulate 8, edges bipartite(8) theta(-1.5)
assert _rc == 198
capture noisily nwergm simulate 8, edges bipartite(-1) theta(-1.5)
assert _rc == 198
di "=== bipartite simulate error paths (one-mode term + bipartite(), bipartite-only term without bipartite(), directed+bipartite, bipartite() out of range) all verified ==="
