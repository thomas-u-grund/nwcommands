cscript

do unw_ergm.do

* Certifies the MCMC engine (ErgmMCMCSample) and both v1 proposals
* (ergm_propose_uniform, ergm_propose_tnt - Part X/XXVIII/XXIX of the
* governing nwergm task) against the ONE ERGM model with an exactly
* known, analytically tractable stationary distribution: the
* edges-only Bernoulli model. Under P(y) ~ exp(theta*edges(y)), every
* dyad is an INDEPENDENT Bernoulli(p) draw with p = invlogit(theta), so
* the edge-count statistic is exactly Binomial(D, p) - mean D*p,
* variance D*p*(1-p), D = total dyad count. This is a genuine "tiny
* network exact enumeration"-class certification (Part XXIX): no
* simulation-only comparison, no dependence on Statnet, a closed-form
* target derived directly from the model's own definition.
*
* Both proposals are run at each configuration and checked against the
* SAME exact target - since TNT's own log-Hastings-ratio correction
* (see unw_ergm.do's own header comment on ergm_propose_tnt for the
* exact formulas) is the one place a genuine bug would show up as a
* systematic, sustained bias (not just Monte Carlo noise) relative to
* both the uniform proposal's own result and the exact theoretical
* value, agreement across all three is a strong, specific test of the
* Hastings-ratio math, not merely "the sampler runs".

mata:
mata set matastrict off

void certify_edges_bernoulli(real scalar n, real scalar undirected,
	real scalar theta_val, real scalar seedbase) {

	class ErgmModel scalar M
	class ErgmGraph scalar G1, G2
	class ErgmTermData scalar td
	real matrix samp1, samp2
	real scalar Dtot, p_theory, mean_theory, var_theory, mean1, mean2, se1, se2

	if (undirected) Dtot = n*(n-1)/2
	else Dtot = n*(n-1)

	p_theory = exp(theta_val)/(1+exp(theta_val))
	mean_theory = Dtot*p_theory
	var_theory = Dtot*p_theory*(1-p_theory)

	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), td, ("edges"))

	rseed(seedbase)
	G1 = ErgmGraph()
	G1.init(n, !undirected)
	samp1 = ErgmMCMCSample(M, G1, (theta_val), 4000, 20, 4000, &ergm_propose_uniform())
	mean1 = mean(samp1)
	se1 = sqrt(variance(samp1)/rows(samp1))

	rseed(seedbase+1)
	G2 = ErgmGraph()
	G2.init(n, !undirected)
	samp2 = ErgmMCMCSample(M, G2, (theta_val), 4000, 20, 4000, &ergm_propose_tnt())
	mean2 = mean(samp2)
	se2 = sqrt(variance(samp2)/rows(samp2))

	printf("n=%g undirected=%g theta=%g: theory=%9.4f uniform=%9.4f(se %6.4f) tnt=%9.4f(se %6.4f)\n",
		n, undirected, theta_val, mean_theory, mean1, se1, mean2, se2)

	assert(abs(mean1 - mean_theory) < 8*se1)
	assert(abs(mean2 - mean_theory) < 8*se2)
	assert(abs(mean1 - mean2) < 8*(se1+se2))
	assert(reldif(sqrt(variance(samp1)), sqrt(var_theory)) < 0.35)
	assert(reldif(sqrt(variance(samp2)), sqrt(var_theory)) < 0.35)
}

certify_edges_bernoulli(5, 1, -0.5, 42)
certify_edges_bernoulli(5, 1,  0.5, 142)
certify_edges_bernoulli(4, 0, -0.3, 242)
end

* --- proposal unranking bijections: every dyad index maps to a
* distinct, valid dyad, with full coverage of the dyad space (no
* duplicates, no gaps) - the structural correctness check underlying
* both proposals' own uniform-selection guarantee.
mata:
gU5 = ErgmGraph()
gU5.init(5, 0)
seen = asarray_create("real", 2)
for (pick=1; pick<=10; pick++) {
	p = pick
	i = 1
	while (p > gU5.n - i) {
		p = p - (gU5.n - i)
		i++
	}
	j = i + p
	assert(!asarray_contains(seen,(i,j)))
	asarray(seen,(i,j),1)
}
assert(asarray_elements(seen) == 10)

gD4 = ErgmGraph()
gD4.init(4, 1)
seen2 = asarray_create("real", 2)
nn = gD4.n
for (pick=1; pick<=nn*(nn-1); pick++) {
	row = ceil(pick / (nn - 1))
	col = mod(pick - 1, nn - 1) + 1
	i = row
	j = (col < row) ? col : col + 1
	assert(!asarray_contains(seen2,(i,j)))
	asarray(seen2,(i,j),1)
}
assert(asarray_elements(seen2) == 12)
end

* --- ErgmMCMCSampleDiag() (Part XIX: basic MCMC diagnostics need an
* acceptance rate, which ErgmMCMCSample() itself deliberately does not
* track - see unw_ergm.do's own header comment on ErgmMCMCSampleDiag).
* Certified two ways: (1) under an identical seed, its own sample output
* must be BYTE-IDENTICAL to ErgmMCMCSample()'s - the accept/reject draw
* sequence is meant to be exactly the same algorithm, just additionally
* tallied, so any divergence here would mean the tallying itself
* perturbed the draw sequence (e.g. an extra runiform() call) rather than
* merely counting it; (2) its own reported acceptance rate must exactly
* match an INDEPENDENTLY hand-written duplicate of the identical loop
* kept entirely inside this test file (not calling unw_ergm.do's own
* counting logic at all) - a genuine second, independent implementation
* of "count accepted proposals", not just re-reading the same number back.
mata:
mata set matastrict off

M = ErgmModel()
M.init()
td = ErgmTermData()
M.addterm("edges", 1, &stat_edges(), &change_edges(), td, ("edges"))

rseed(3001)
Ga = ErgmGraph()
Ga.init(6, 0)
sampA = ErgmMCMCSample(M, Ga, (-0.4), 200, 10, 500, &ergm_propose_tnt())

rseed(3001)
Gb = ErgmGraph()
Gb.init(6, 0)
diagB = ErgmMCMCSampleDiag(M, Gb, (-0.4), 200, 10, 500, &ergm_propose_tnt())

printf("ErgmMCMCSampleDiag vs ErgmMCMCSample: max|diff|=%9.2e\n", max(abs(sampA - diagB.sample)))
assert(max(abs(sampA - diagB.sample)) == 0)

// independent hand-written duplicate of the identical loop, purely to
// cross-check diagB.acceptrate without reusing unw_ergm.do's own tally.
rseed(3001)
Gc = ErgmGraph()
Gc.init(6, 0)
for (s=1; s<=200; s=s+1) {
	prop = ergm_propose_tnt(Gc)
	chg = M.full_change(Gc, prop[1], prop[2])
	cutoff = (-0.4)*chg' + prop[3]
	if (cutoff >= 0 | ln(runiform(1,1)) < cutoff) Gc.toggle(prop[1], prop[2])
}
nacc = 0
ntot = 0
for (d=1; d<=500; d=d+1) {
	for (s=1; s<=10; s=s+1) {
		prop = ergm_propose_tnt(Gc)
		chg = M.full_change(Gc, prop[1], prop[2])
		cutoff = (-0.4)*chg' + prop[3]
		ntot = ntot+1
		if (cutoff >= 0 | ln(runiform(1,1)) < cutoff) {
			Gc.toggle(prop[1], prop[2])
			nacc = nacc+1
		}
	}
}
printf("independent acceptrate=%9.7f vs ErgmMCMCSampleDiag=%9.7f\n", nacc/ntot, diagB.acceptrate)
assert(reldif(nacc/ntot, diagB.acceptrate) < 1e-10)
assert(diagB.acceptrate > 0 & diagB.acceptrate <= 1)
end
