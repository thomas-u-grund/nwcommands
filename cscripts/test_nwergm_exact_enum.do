cscript

do unw_ergm.do

* Certifies ErgmMCMCSample() (both proposals) against a full-ENUMERATION
* exact gold standard for a genuinely DYAD-DEPENDENT model (Part XXIX of
* the governing nwergm task) - edges + mutual on a 3-node directed
* network (6 possible arcs, 2^6 = 64 possible graphs, small enough to
* enumerate exhaustively). This is a STATNET-INDEPENDENT certification:
* the "gold standard" here is the model's own exact definition
* (P(y) = exp(theta'g(y)) / Z, Z = sum over ALL possible graphs),
* not a comparison against any external software - exactly the kind of
* check the governing brief calls for as the strongest possible
* validation for a small enough network. Unlike the edges-only Bernoulli
* certification in test_nwergm_mcmc.do (analytically tractable in closed
* form because dyads are independent), mutual makes this a genuinely
* dyad-DEPENDENT model - the normalizing constant and expectations have
* no closed form and must be computed by literal exhaustive summation,
* making this the first real test of the sampler against a case where
* dyad independence cannot be leaned on at all.

mata:
mata set matastrict off

M = ErgmModel()
M.init()
td1 = ErgmTermData()
M.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))
td2 = ErgmTermData()
M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), td2, ("mutual"))

theta = (0.3, 0.7)
n = 3
ndyad = n*(n-1)

// enumerate all 2^ndyad directed graphs on 3 nodes (dyads ordered
// (1,2),(2,1),(1,3),(3,1),(2,3),(3,2)), compute each graph's own
// (edges,mutual) statistic and unnormalized weight exp(theta'stat).
dyads = J(ndyad, 2, 0)
pos = 1
for (i=1; i<=n; i++) {
	for (j=1; j<=n; j++) {
		if (i==j) continue
		dyads[pos,1] = i
		dyads[pos,2] = j
		pos++
	}
}

G = ErgmGraph()
G.init(n, 1)

ngraphs = 2^ndyad
Z = 0
Esum_edges = 0
Esum_mutual = 0
Esum_edges2 = 0
for (code=0; code<=ngraphs-1; code++) {
	// reset G to empty, then toggle on according to code's own bits
	for (k=1; k<=ndyad; k++) {
		if (G.has_edge(dyads[k,1], dyads[k,2])) G.toggle(dyads[k,1], dyads[k,2])
	}
	rem = code
	for (k=1; k<=ndyad; k++) {
		bit = mod(rem, 2)
		rem = floor(rem/2)
		if (bit==1) G.toggle(dyads[k,1], dyads[k,2])
	}
	s = M.full_statistic(G)
	w = exp(theta*s')
	Z = Z + w
	Esum_edges = Esum_edges + w*s[1]
	Esum_mutual = Esum_mutual + w*s[2]
}
exact_mean_edges = Esum_edges / Z
exact_mean_mutual = Esum_mutual / Z

printf("Exact (full enumeration, %g graphs): E[edges]=%9.6f E[mutual]=%9.6f\n", ngraphs, exact_mean_edges, exact_mean_mutual)

// reset G to empty before simulating
for (k=1; k<=ndyad; k++) {
	if (G.has_edge(dyads[k,1], dyads[k,2])) G.toggle(dyads[k,1], dyads[k,2])
}
rseed(9001)
samp_u = ErgmMCMCSample(M, G, theta, 5000, 25, 5000, &ergm_propose_uniform())
mc_mean_edges_u = mean(samp_u[.,1])
mc_mean_mutual_u = mean(samp_u[.,2])
se_edges_u = sqrt(variance(samp_u[.,1])/rows(samp_u))
se_mutual_u = sqrt(variance(samp_u[.,2])/rows(samp_u))
printf("MCMC (uniform proposal): E[edges]=%9.6f (se %6.4f) E[mutual]=%9.6f (se %6.4f)\n", mc_mean_edges_u, se_edges_u, mc_mean_mutual_u, se_mutual_u)

for (k=1; k<=ndyad; k++) {
	if (G.has_edge(dyads[k,1], dyads[k,2])) G.toggle(dyads[k,1], dyads[k,2])
}
rseed(9002)
samp_t = ErgmMCMCSample(M, G, theta, 5000, 25, 5000, &ergm_propose_tnt())
mc_mean_edges_t = mean(samp_t[.,1])
mc_mean_mutual_t = mean(samp_t[.,2])
se_edges_t = sqrt(variance(samp_t[.,1])/rows(samp_t))
se_mutual_t = sqrt(variance(samp_t[.,2])/rows(samp_t))
printf("MCMC (tnt proposal):     E[edges]=%9.6f (se %6.4f) E[mutual]=%9.6f (se %6.4f)\n", mc_mean_edges_t, se_edges_t, mc_mean_mutual_t, se_mutual_t)

// both proposals must land within a generous, but genuine, multiple of
// their own Monte Carlo standard error of the EXACT value.
assert(abs(mc_mean_edges_u - exact_mean_edges) < 8*se_edges_u)
assert(abs(mc_mean_mutual_u - exact_mean_mutual) < 8*se_mutual_u)
assert(abs(mc_mean_edges_t - exact_mean_edges) < 8*se_edges_t)
assert(abs(mc_mean_mutual_t - exact_mean_mutual) < 8*se_mutual_t)

// sanity bound: exact means must lie within the statistic's own
// achievable range (edges in [0,6], mutual in [0,3]).
assert(exact_mean_edges > 0 & exact_mean_edges < 6)
assert(exact_mean_mutual > 0 & exact_mean_mutual < 3)
end
