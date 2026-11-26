* edge round 4: nwsummarize, detail on a two-mode network; results under a name in use; nwplot with an empty selection
clear all
do unw_core.do

nwclear
mata: B = (1,0,1 \ 0,1,1 \ 1,1,0 \ 0,0,1)
nwset, mat(B) name(tm) bipartite
nwsummarize tm, detail

* a name in use: the result gets a free name; the network of the name in use is not touched
foreach cmd in "nwrecode a (1=5), generate(z)" "nwdichotomize a, threshold(1) generate(z)" {
	nwclear
	set seed 3
	nwrandom 6, prob(.5) name(a) undirected
	nwrandom 6, prob(.9) name(z) undirected
	mata: Z = J(6, 6, 2) - 2 * I(6)
	nwreplace z = Z
	nwsummarize z
	local before "`r(valued)' `r(minval)' `r(maxval)'"
	tempfile lf
	quietly log using "`lf'", text replace name(r4m)
	`cmd'
	quietly log close r4m
	mata: assert(sum(strpos(cat(st_local("lf")), "Switched to netname") :> 0) > 0)
	nwsummarize z
	assert "`r(valued)' `r(minval)' `r(maxval)'" == "`before'"
	nwsummarize z_1
}
assert "`r(valued)'" == "false"
nwsimilar a, name(z)
nwdissimilar a, name(z)

* nwplot with a condition that no node meets
nwclear
nwrandom 6, prob(.5) name(a) undirected
gen k = _n
capture noisily nwplot a if k > 100
assert _rc == 198
nwds
assert "`r(netlist)'" == "a" | "`r(nets)'" == "a" | r(networks) == 1

display "PASS test_edge_round4_medium"
