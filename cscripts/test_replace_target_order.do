* name(T) replace where T exists: created before the source, with another network after it (and with the source last).
* A drop moves the stored networks; the result must come from the source all the same.
clear all
do unw_core.do

capture program drop _mk
program _mk
	* target (4 nodes) first, then source (6) and another network (9), or source last
	args order
	nwclear
	nwrandom 4, prob(.5) name(tgt) undirected
	if "`order'" == "last" nwrandom 9, prob(.3) name(oth) undirected
	nwrandom 6, prob(.6) name(src) undirected
	if "`order'" == "middle" nwrandom 9, prob(.3) name(oth) undirected
end
capture program drop _same
program _same
	args a b
	tempname A B
	nwtomata `a', mat(`A')
	nwtomata `b', mat(`B')
	mata: assert(rows(`A') == rows(`B') & cols(`A') == cols(`B'))
	mata: assert(mreldif(editmissing(`A', -99), editmissing(`B', -99)) < 1e-10)
	mata: mata drop `A' `B'
end

foreach order in middle last {
	set seed 11
	_mk `order'
	nwlambda src, name(ctl)
	nwlambda src, name(tgt) replace
	_same tgt ctl

	set seed 11
	_mk `order'
	nwsimindex src, name(ctl)
	nwsimindex src, name(tgt) replace
	_same tgt ctl

	set seed 11
	_mk `order'
	gen grp = mod(_n, 2) in 1/6
	nwneighbor src, ego(1) subnet(ctl)
	nwneighbor src, ego(1) subnet(tgt) subreplace
	_same tgt ctl

	* keepexpand replaces the network same_grp
	set seed 11
	nwclear
	nwrandom 4, prob(.5) name(same_grp) undirected
	if "`order'" == "last" nwrandom 9, prob(.3) name(oth) undirected
	nwrandom 6, prob(.6) name(src) undirected
	if "`order'" == "middle" nwrandom 9, prob(.3) name(oth) undirected
	capture drop grp
	gen grp = mod(_n, 2) in 1/6
	nwcorrelate src, attribute(grp) mode(same) keepexpand permutations(5)
	nwsummarize same_grp
	assert r(nodes) == 6

	* two-mode source
	nwclear
	nwrandom 4, prob(.5) name(tgt) undirected
	mata: B = (1,0,1 \ 0,1,1 \ 1,1,0 \ 0,0,1)
	if "`order'" == "last" nwrandom 9, prob(.3) name(oth) undirected
	nwset, mat(B) name(src) bipartite
	if "`order'" == "middle" nwrandom 9, prob(.3) name(oth) undirected
	nw2project src, project(1) name(ctl)
	nw2project src, project(1) name(tgt) replace
	_same tgt ctl

	* temporal source
	nwclear
	nwrandom 4, prob(.5) name(tgt) undirected
	if "`order'" == "last" nwrandom 9, prob(.3) name(oth) undirected
	clear
	input str1 a str1 b t
	a b 1
	b c 1
	c d 2
	d e 2
	a e 2
	end
	nwset a b, time(t) name(src) directed
	if "`order'" == "middle" nwrandom 9, prob(.3) name(oth) undirected
	nwattime src, at(2) name(ctl)
	nwattime src, at(2) name(tgt) replace
	_same tgt ctl
}

* a target that is the source is refused and the source stays
set seed 11
_mk middle
foreach cmd in "nwlambda src, name(src) replace" "nwsimindex src, name(src) replace" "nwneighbor src, ego(1) subnet(src) subreplace" {
	capture noisily `cmd'
	assert _rc == 483
	nwsummarize src
	assert r(nodes) == 6
}

display "PASS test_replace_target_order"
