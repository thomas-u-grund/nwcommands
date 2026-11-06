* Tutorial 5: Generating Networks
* Run from a directory with nwcommands net-installed (not a dev checkout).

* nwrandom: Erdos-Renyi - each potential tie has the same probability
nwclear
nwrandom 15, prob(.2) undirected
nwsummarize

* ...or fix the exact density instead of leaving tie count to chance
nwrandom 15, density(.2) undirected name(randdens)
nwsummarize randdens

* weights() assigns a value to each placed tie, independent of how it
* was placed
nwrandom 15, prob(.2) undirected weights(0.0, 0.3, 0.7) name(randval)
nwsummarize randval

* nwsmall: Watts-Strogatz small-world - start from a ring lattice
* (each node tied to its k nearest neighbors), then rewire a fraction
* of ties at random
nwsmall 20, k(2) prob(.1) undirected
nwsummarize
nwplot, layout(circle) scheme(s1network) export("plot_smallworld.svg") replace

* nwpref: Barabasi-Albert preferential attachment - new nodes are more
* likely to connect to already well-connected ones, producing hubs
nwpref 20, undirected
nwsummarize
nwdegree, generate(deg)
sort deg _nwnode
list _nwnode deg in -5/-1
nwplot, layout(circle) scheme(s1network) size(deg) export("plot_prefattach.svg") replace

* nwlattice: a structured grid, exactly 4 neighbors per node with wrap
nwlattice 4 4, xwrap ywrap
nwsummarize
nwplot, layout(grid) label(_nwnode) scheme(s1network) export("plot_lattice.svg") replace

* nwrandom, degree(): a random network in which every node has a given
* degree (Havel-Hakimi construction, then random tie swaps)
set seed 2026
nwrandom 8, degree(3 3 2 2 2 2 1 1) name(randdeg)
nwdegree randdeg, generate(d_randdeg)
list _nwnode d_randdeg in 1/8, noobs
* a list no network can have is refused
capture noisily nwrandom 3, degree(1 1 1) name(bad)

* the degrees of a real network: random networks with the degrees of the
* Florentine marriage network, and otherwise random
nwwebuse florentine, nwclear
nwdegree flomarriage, generate(d_flo)
nwrandom 16, degree(d_flo) name(floran) xvars
nwclustering flomarriage, generate(cc1) replace
nwclustering floran, generate(cc2) replace
