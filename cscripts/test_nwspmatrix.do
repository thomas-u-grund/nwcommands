* nwspmatrix: spatial weighting matrix from a network (3.28.0)
* fixture: R 4.6, sna 2.8 lnam(alcohol2, cbind(1, smoke2, sport2), W1 = row-normalised glasgow2); Stata 17 spregress, ml
clear all
set more off
nwclear
clear
set obs 4
gen double v = _n
nwset, mat((0,1,1,0\0,0,1,0\1,0,0,0\0,0,0,0)) name(d4) directed
gen double y = _n^2
nwspmatrix d4, name(W) replace silent
assert r(isolates) == 1 & r(nodes) == 4 & r(ties) == 4 & "`r(normalize)'" == "row"
spmatrix matafromsp B ids = W
mata: assert(B == (0, .5, .5, 0 \ 0, 0, 1, 0 \ 1, 0, 0, 0 \ 0, 0, 0, 0))
mata: assert(ids == (1::4))
* in, symmetric, mutual, none
nwspmatrix d4, name(Wi) direction(in) normalize(none) replace silent
spmatrix matafromsp B ids = Wi
mata: assert(B == (0, 0, 1, 0 \ 1, 0, 0, 0 \ 1, 1, 0, 0 \ 0, 0, 0, 0))
nwspmatrix d4, name(Ws) direction(symmetric) normalize(none) replace silent
spmatrix matafromsp B ids = Ws
mata: assert(B == (0, 1, 1, 0 \ 1, 0, 1, 0 \ 1, 1, 0, 0 \ 0, 0, 0, 0))
nwspmatrix d4, name(Wm) direction(mutual) normalize(none) replace silent matrix(M)
assert r(ties) == 2 & r(isolates) == 2
matrix list M
assert M[1,3] == 1 & M[3,1] == 1 & M[1,2] == 0
* valued network and weights(valued) / binary
nwset, mat((0,3,0\3,0,1\0,1,0)) name(v3) undirected
nwspmatrix v3, name(Wv) weights(valued) normalize(none) replace silent
spmatrix matafromsp B ids = Wv
mata: assert(B == (0, 3, 0 \ 3, 0, 1 \ 0, 1, 0))
nwspmatrix v3, name(Wv) weights(valued) replace silent
spmatrix matafromsp B ids = Wv
mata: assert(B == (0, 1, 0 \ .75, 0, .25 \ 0, 1, 0))
nwspmatrix v3, name(Wv) weights(binary) normalize(minmax) replace silent
* identifier variable and an existing spset
nwspmatrix v3, name(Wv) replace silent
assert r(ties) == 4
* errors
capture nwspmatrix d4, name(W)
assert _rc == 111
capture nwspmatrix d4, name(W) weights(xx) replace
assert _rc == 198
capture nwspmatrix d4, name(W) direction(xx) replace
assert _rc == 198
capture nwspmatrix d4, name(W) normalize(xx) replace
assert _rc == 198
capture nwspmatrix nonet, name(W) replace
assert _rc != 0
nwset, mat((0,-1,0\-1,0,1\0,1,0)) name(neg3) undirected
capture nwspmatrix neg3, name(Wn) weights(valued) replace
assert _rc == 198
nwspmatrix neg3, name(Wn) weights(binary) replace silent
preserve
keep in 1/2
capture nwspmatrix d4, name(W) replace
assert _rc == 198
restore
* two-mode networks are refused
nwset, mat((1,0,1\0,1,1)) name(tm) bipartite
capture nwspmatrix tm, name(W) replace
assert _rc != 0
* agreement with sna::lnam (R)
nwclear
clear
nwuse data/glasgow, nwclear
nwspmatrix glasgow2, name(W) replace silent
assert r(nodes) == 50 & r(ties) == 116 & r(isolates) == 3
spregress alcohol2 smoke2 sport2, ml dvarlag(W) nolog
assert abs(_b[smoke2] - 0.6445292964) < 1e-4
assert abs(_b[sport2] - 0.0571862565) < 1e-4
assert abs(_b[_cons] - 1.5441213832) < 1e-4
assert abs(_b[W:alcohol2] - 0.1601493737) < 1e-4
assert abs(e(ll) - (-71.9802955376)) < 1e-4
assert abs(_se[smoke2] - 0.2037696) < 1e-4
assert abs(_se[W:alcohol2] - 0.1201003) < 1e-4
di "test_nwspmatrix: all passed"
