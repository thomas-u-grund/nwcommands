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
sort deg
list _nwnode deg in -5/-1
nwplot, layout(circle) scheme(s1network) size(deg) export("plot_prefattach.svg") replace

* nwlattice: a structured grid, exactly 4 neighbors per node with wrap
nwlattice 4 4, xwrap ywrap
nwsummarize
nwplot, layout(grid) label(_nwnode) scheme(s1network) export("plot_lattice.svg") replace
