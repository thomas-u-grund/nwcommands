cscript

do unw_core.do

* Layouts that use the tie values (nwplot layout(kk) and layout(frucht), nwmovie waves): igraph's layout_with_fr(weights=)
* (attraction multiplied by the tie value) and layout_with_kk(weights=) with the edge length 1/value (the values are
* strengths).  On a valued network the default layouts use the values; option binary does not; a tie value that is not
* positive (signed network) makes the layout ignore the values (as igraph's plot() does, with a warning); a one-mode
* network whose ties all have the same value, a two-mode network and an unvalued network keep the unweighted layouts.
* Prints "wlayout: all passed" on success.

set graphics off

* ---- helper: distance of two nodes in the generated coordinates
capture program drop wl_d
program wl_d, rclass
	args xv yv i j
	return scalar d = sqrt((`xv'[`i'] - `xv'[`j'])^2 + (`yv'[`i'] - `yv'[`j'])^2)
end

* ---- unvalued networks: bit-identical to the layouts before weighted layouts existed (values from origin/develop of 2026-10-26)
nwclear
set seed 123
nwrandom 12, prob(.25) name(u12) undirected
set seed 11
nwplot u12, generate(kx ky) noopen
set seed 11
nwplot u12, layout(frucht) iterations(30) generate(fx fy) noopen
assert reldif(kx[1], 0.303127527237) < 1e-9 & reldif(ky[1], 0.730015695095) < 1e-9
assert reldif(kx[2], 1.001404523849) < 1e-9 & reldif(ky[2], 0.398880392313) < 1e-9
assert reldif(kx[4], 1.25) < 1e-9 & reldif(ky[4], 0.855154991150) < 1e-9
assert reldif(fx[1], -0.342961788177) < 1e-9 & reldif(fy[1], -0.939349293709) < 1e-9
assert reldif(fx[3], 0.093055047095) < 1e-9 & reldif(fy[3], -0.299707412720) < 1e-9
di "unvalued kk and frucht unchanged: ok"

* ---- a chain of 6 nodes, the tie 3-4 strong (5), the others 1; and two cliques (value 4) joined by two weak ties (1)
nwclear
nwset, mat((0,1,0,0,0,0\1,0,1,0,0,0\0,1,0,1,0,0\0,0,1,0,1,0\0,0,0,1,0,1\0,0,0,0,1,0)) name(chain) undirected
nwduplicate chain, name(chainv)
mata: C = (0,1,0,0,0,0\1,0,1,0,0,0\0,1,0,5,0,0\0,0,5,0,1,0\0,0,0,1,0,1\0,0,0,0,1,0)
nwreplacemat chainv, newmat(C)
mata: K = J(10,10,0); K[1::5,1::5] = J(5,5,4); K[6::10,6::10] = J(5,5,4); _diag(K,0); K[5,6] = 1; K[6,5] = 1; K[4,7] = 1; K[7,4] = 1
nwset, mat(K) name(twoc) undirected

* kk: the strong pair is closer than the weak pairs; binary: all pairs about equally far
forvalues s = 1/4 {
	set seed `s'
	nwplot chainv, generate(x y) noopen
	qui wl_d x y 3 4
	local strong = r(d)
	local weak = 0
	foreach p in "1 2" "2 3" "4 5" "5 6" {
		qui wl_d x y `p'
		local weak = `weak' + r(d)/4
	}
	assert `strong' < 0.6 * `weak'
	set seed `s'
	nwplot chainv, generate(xb yb) noopen binary
	qui wl_d xb yb 3 4
	local strongb = r(d)
	assert `strongb' > 0.6 * `weak'
	di "kk seed `s': strong/weak weighted " %5.3f `strong'/`weak' ", binary " %5.3f `strongb'/`weak'
	drop x y xb yb
}
* frucht: the same
forvalues s = 1/4 {
	set seed `s'
	nwplot chainv, layout(frucht) iterations(100) generate(x y) noopen
	qui wl_d x y 3 4
	local strong = r(d)
	local weak = 0
	foreach p in "1 2" "2 3" "4 5" "5 6" {
		qui wl_d x y `p'
		local weak = `weak' + r(d)/4
	}
	di "frucht seed `s': strong/weak " %5.3f `strong'/`weak'
	assert `strong' < `weak'
	drop x y
}
di "strong tie closer (kk, frucht): ok"

* value hierarchy on the cliques with weak bridges: the weighted layouts pull the cliques tighter relative to the bridge
set seed 3
nwplot twoc, generate(x y) noopen
qui wl_d x y 5 6
local bridge = r(d)
qui wl_d x y 1 2
local inner = r(d)
set seed 3
nwplot twoc, generate(xb yb) noopen binary
qui wl_d xb yb 5 6
local bridgeb = r(d)
qui wl_d xb yb 1 2
local innerb = r(d)
assert `bridge'/`inner' > `bridgeb'/`innerb'
drop x y xb yb
di "cliques and weak bridges: ok"

* ---- binary: equals the layout of the dichotomized (unvalued) network, coordinates and all
nwuse data/gang, nwclear
qui nwdichotomize gang_valued, threshold(0.5) generate(gang01)
set seed 5
nwplot gang_valued, generate(vx vy) noopen binary
set seed 5
nwplot gang01, generate(bx by) noopen
assert vx == bx & vy == by
set seed 5
nwplot gang_valued, layout(frucht) iterations(20) generate(vfx vfy) noopen binary
set seed 5
nwplot gang01, layout(frucht) iterations(20) generate(bfx bfy) noopen
assert vfx == bfx & vfy == bfy
* default on a valued network differs from binary and is deterministic under the seed
set seed 5
nwplot gang_valued, generate(wx wy) noopen
assert r(edgewidth) == "values" | "`r(edgewidth)'" == "values"
count if abs(wx - vx) > 1e-6 | abs(wy - vy) > 1e-6
assert r(N) > 0
set seed 5
nwplot gang_valued, generate(w2x w2y) noopen
assert wx == w2x & wy == w2y
* coordinates in the usual box
qui sum wx
assert r(min) >= -1e-9 & r(max) <= 1.5 + 1e-9
qui sum wy
assert r(min) >= -1e-9 & r(max) <= 1 + 1e-9
set seed 5
nwplot gang_valued, layout(frucht) iterations(20) generate(wfx wfy) noopen
count if abs(wfx - vfx) > 1e-6
assert r(N) > 0
drop vx vy bx by vfx vfy bfx bfy wx wy w2x w2y wfx wfy
di "binary equals the dichotomized layout; default differs and is deterministic: ok"

* ---- all ties of one value (valued network): the unweighted layout
nwclear
set seed 8
nwrandom 15, prob(.2) name(r15) undirected
nwtomata r15, mat(M)
mata: M = editmissing(M, 0) :* 3
nwduplicate r15, name(r15v)
nwreplacemat r15v, newmat(M)
set seed 2
nwplot r15v, generate(ax ay) noopen
set seed 2
nwplot r15, generate(bx by) noopen
assert ax == bx & ay == by
drop ax ay bx by

* ---- signed network (a negative tie): the values are ignored, with a note; same layout as binary
nwuse data/senate114, nwclear
set seed 4
log using "wlayout_note.log", text replace
nwplot senate114, generate(sx sy) noopen
log close
set seed 4
nwplot senate114, generate(sbx sby) noopen binary
assert sx == sbx & sy == sby
mata: st_local("nnote", strofreal(sum(strpos(cat("wlayout_note.log"), "tie values that are not positive") :> 0)))
assert `nnote' == 1
erase wlayout_note.log
di "signed network ignores the values with one note: ok"

* ---- two-mode valued network: unchanged
nwuse data/davis, nwclear
nwduplicate davis, name(davis_v)
nwtomata davis_v, mat(D)
mata: D = editmissing(D, 0); D = D :* (1 :+ mod(rowshape(1::rows(D)*cols(D), rows(D)), 4))
mata: D = lowertriangle(D, 0); D = D + D'
nwreplacemat davis_v, newmat(D)
set seed 6
nwplot davis_v, generate(dx dy) noopen
set seed 6
nwplot davis_v, generate(dbx dby) noopen binary
assert dx == dbx & dy == dby
drop dx dy dbx dby
di "two-mode layout unchanged: ok"

* ---- nwmovie: valued waves run (per-wave kk uses the values), binary too
nwclear
set seed 21
nwrandom 14, prob(.25) name(mw1) undirected
nwtomata mw1, mat(M)
mata: M = editmissing(M, 0); M = M :* (1 :+ mod(rowshape(1::rows(M)*cols(M), rows(M)), 3)); M = lowertriangle(M, 0); M = M + M'
nwduplicate mw1, name(mw2)
nwduplicate mw1, name(mw3)
nwreplacemat mw1, newmat(M)
mata: M2 = M; M2[1,2] = 7; M2[2,1] = 7
nwreplacemat mw2, newmat(M2)
nwreplacemat mw3, newmat(M)
capture erase wl_movie.html
nwmovie mw1 mw2 mw3, noopen fname(wl_movie) duration(300)
assert fileexists("wl_movie.html")
erase wl_movie.html
nwmovie mw1 mw2 mw3, noopen fname(wl_movie) duration(300) binary
assert fileexists("wl_movie.html")
erase wl_movie.html
di "nwmovie with valued waves: ok"

di "wlayout: all passed"
