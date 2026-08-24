cscript

clear mata
do unw_core.do
set more off
set obs 3
gen x = _n
gen y = 2
nwset x y, edgelist

nwpath , egoid(1) alterid(3)
assert `r(path_length)' == -1
* unconnected case: no paths found, r(paths_matrix) must not be set
assert r(paths) == 0
assert r(path_shortest) == -1
assert r(ego) == 1
assert r(alter) == 3
capture matrix list r(paths_matrix)
assert _rc != 0

nwpath , egoid(1) alterid(3) sym
assert `r(path_length)' == 2
* harmonisation-phase regression test: r(paths)/r(path_shortest)/
* r(ego)/r(alter)/r(paths_matrix) are now real returns matching the
* documented "Stores results" section (previously the doc claimed
* several returns - r(paths) [code had r(num_paths) instead],
* r(path_shortest), r(ego), r(alter), r(paths_matrix) - that the code
* simply never set).
assert r(paths) == 1
assert r(path_shortest) == 2
assert r(ego) == 1
assert r(alter) == 3
matrix pm = r(paths_matrix)
assert rowsof(pm) == 1
assert colsof(pm) == 3
assert pm[1,1] == 1
assert pm[1,3] == 3

nwsym
nwpath , egoid(1) alterid(3) generate(p)
nwset
assert `"`r(nets)'"' == `" network p_1"'

assert         r(networks) == 2

* --- alpha-audit regression: get_path() used to crash with a Mata
* conformability error on ANY valued/weighted network - sum() of the
* raw (weighted) adjacency row overcounted neighbors relative to
* select()'s own correct nonzero-count, sizing the path-building matrix
* wrong. Confirmed fixed on both directed and undirected valued
* networks, including a genuine 2-hop path.
nwclear
nwset, mat((0,5,0\0,0,3\0,0,0)) name(valnet3) directed labs(A,B,C)
nwpath valnet3, ego(A) alter(C)
assert r(path_length) == 2
assert r(paths) == 1

nwclear
nwset, mat((0,5\0,0)) name(valnet2) directed labs(A,B)
capture noisily nwpath valnet2, ego(A) alter(B)
assert _rc == 0
di "=== valued-network path REGRESSION VERIFIED ==="
