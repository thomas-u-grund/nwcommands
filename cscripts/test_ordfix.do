cscript

* Regression test: sorts whose ties were broken by the state of the random-number generator (Mata's sort() and order()
* break ties at random, not by input order). Each block runs the command under several seeds and checks that the result
* is the same and that ties are listed in a fixed order (equal sizes: ascending id).

do unw_core.do

* --- nwkcore: coreness 2 for the triangle {A,B,C}, coreness 1 for D, E, F (pendants of A): two classes of size 3
forvalues s = 1/12 {
	set seed `s'
	nwclear
	nwset, mat((0,1,1,1,1,1\1,0,1,0,0,0\1,1,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0\1,0,0,0,0,0)) name(kc) undirected labs(A,B,C,D,E,F)
	quietly nwkcore kc, generate(_kc`s')
	matrix M = r(core_sizeid)
	assert M[1,2] == 1 & M[2,2] == 2
	assert M[1,1] == 3 & M[2,1] == 3
}
di as text "  PASS: nwkcore lists classes of equal size by ascending id under 12 seeds"

* --- nwmodularity: two groups of equal size
forvalues s = 1/12 {
	set seed `s'
	nwclear
	nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) undirected labs(A,B,C,D,E,F) name(bridge)
	capture drop tg
	gen tg = 1 in 1/3
	replace tg = 2 in 4/6
	quietly nwmodularity bridge, group(tg)
	matrix M = r(comm_sizeid)
	assert M[1,2] == 1 & M[2,2] == 2
}
di as text "  PASS: nwmodularity lists groups of equal size by ascending id under 12 seeds"

* --- nwconcor: two disjoint cliques of four nodes: two blocks of equal size
forvalues s = 1/12 {
	set seed `s'
	nwclear
	nwset, mat((0,1,1,1,0,0,0,0\1,0,1,1,0,0,0,0\1,1,0,1,0,0,0,0\1,1,1,0,0,0,0,0\0,0,0,0,0,1,1,1\0,0,0,0,1,0,1,1\0,0,0,0,1,1,0,1\0,0,0,0,1,1,1,0)) undirected name(cc)
	capture drop _blk*
	quietly nwconcor cc, generate(_blk)
	matrix M = r(block_sizeid)
	assert M[1,1] == M[2,1]
	assert M[1,2] < M[2,2]
}
di as text "  PASS: nwconcor lists blocks of equal size by ascending id under 12 seeds"

* --- nwspectral: the star with four leaves has the eigenvalue 1 three times: the vector of the second eigenvalue
*     must not depend on the seed
nwclear
nwset, mat((0,1,1,1,1\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0)) undirected name(star5)
set seed 1
quietly nwspectral star5, generate(_fv)
generate double _fv_ref = _fv
forvalues s = 2/12 {
	set seed `s'
	quietly nwspectral star5, generate(_fv) replace
	assert reldif(_fv, _fv_ref) < 1e-10 | missing(_fv)
	quietly count if abs(_fv - _fv_ref) > 1e-10 & !missing(_fv)
	assert r(N) == 0
}
di as text "  PASS: nwspectral gives the same vector under 12 seeds"

* --- nwplotmatrix with group(): nodes of one group keep their order; the exported graph is the same under every seed
nwclear
nwset, mat((0,1,1,0,1,0,0,0\1,0,0,1,0,1,0,0\1,0,0,1,0,0,1,0\0,1,1,0,0,0,0,1\1,0,0,0,0,1,1,0\0,1,0,0,1,0,0,1\0,0,1,0,1,0,0,1\0,0,0,1,0,1,1,0)) undirected name(g8)
generate grp = 1 + mod(_n, 2) in 1/8
forvalues s = 1/6 {
	set seed `s'
	quietly nwplotmatrix g8, group(grp)
	quietly graph export ordfix_pm`s'.png, width(400) replace
	quietly checksum ordfix_pm`s'.png
	local cks`s' = r(checksum)
	erase ordfix_pm`s'.png
	assert `cks`s'' == `cks1'
}
di as text "  PASS: nwplotmatrix draws the same matrix under 6 seeds"

* --- nwmovie, event mode: events with the same time stay in the order of the network
capture mata: mata drop ordfix_events()
mata:
string scalar ordfix_events(string scalar path) {
	string scalar s, chunk
	transmorphic fh
	real scalar i, j
	s = ""
	fh = fopen(path, "r")
	chunk = fread(fh, 1000000)
	while (chunk != J(0,0,"")) {
		s = s + chunk
		chunk = fread(fh, 1000000)
	}
	fclose(fh)
	i = strpos(s, `""events":["')
	j = strpos(substr(s, i, .), "]")
	return(substr(s, i, j))
}
end
clear
input sender receiver t
1 2 1
3 4 1
2 3 1
4 1 2
1 3 2
2 4 2
3 1 2
4 2 3
end
nwset sender receiver, eventtime(t) name(evlog) directed
forvalues s = 1/6 {
	set seed `s'
	quietly nwmovie evlog, noopen fname(ordfix_mv`s')
	mata: st_local("evs`s'", ordfix_events("ordfix_mv`s'.html"))
	erase ordfix_mv`s'.html
	assert `"`evs`s''"' == `"`evs1'"'
}
di as text "  PASS: nwmovie lists tied events in the same order under 6 seeds"

* --- nwplot: layered layout (hierarchy), two-mode layout (bipartite) and the order of components of equal size
*     (the coordinates must not depend on the seed)
nwclear
nwset, mat((0,1,1,1,1,0\0,0,0,0,0,1\0,0,0,0,0,1\0,0,0,0,0,1\0,0,0,0,0,1\0,0,0,0,0,0)) directed name(dag)
forvalues s = 1/10 {
	set seed `s'
	capture drop gx gy
	quietly nwplot dag, layout(hierarchy) generate(gx gy) noopen
	if `s' == 1 mata: ordfix_ref = st_data(., ("gx", "gy"))
	mata: assert(max(abs(st_data(., ("gx", "gy")) :- ordfix_ref)) < 1e-9)
}
di as text "  PASS: nwplot layout(hierarchy) gives the same coordinates under 10 seeds"

nwclear
mata: __bipmat = J(4, 2, 1)
nwset, mat(__bipmat) bipartite name(bip4)
mata: mata drop __bipmat
forvalues s = 1/10 {
	set seed `s'
	capture drop gx gy
	quietly nwplot bip4, layout(bipartite) generate(gx gy) noopen
	if `s' == 1 mata: ordfix_ref = st_data(., ("gx", "gy"))
	mata: assert(max(abs(st_data(., ("gx", "gy")) :- ordfix_ref)) < 1e-9)
}
di as text "  PASS: nwplot layout(bipartite) gives the same coordinates under 10 seeds"

nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) undirected name(tri2)
forvalues s = 1/10 {
	set seed `s'
	capture drop gx gy
	quietly nwplot tri2, layout(mdsclassical) components(2) generate(gx gy) noopen
	if `s' == 1 mata: ordfix_ref = st_data((1::3), ("gx", "gy"))
	mata: assert(max(abs(st_data((1::3), ("gx", "gy")) :- ordfix_ref)) < 1e-9)
}
di as text "  PASS: nwplot places the first of two equal components in the same place under 10 seeds"

di as result "ALL TESTS PASSED"
