* xt_meas_plot.do -- extended tests for the coordinates of nwplot, generate() (no graph is looked at).
* Run with Stata 17; every check passes since the fixes of the measure suite (fixes-xt).
*
* Covers: layout(circle) node order on 4 nodes (from circlelayout() in unw_core.do: node i at angle
* i x 2 pi / N, so node 4 has the largest x, node 2 the smallest, node 1 the largest y, node 3 the
* smallest); the generate() -> nodexy() round trip (documented as a matched pair); the same seed gives the
* same kk layout; a valued network with binary = its unvalued copy; layout(grid) with columns() including
* columns(1) and more columns than nodes (rows == 1 branch of gridlayout()); layout(bipartite) on a two-mode
* network and the error on a one-mode network; 1 node, 2 nodes, isolates; generate() with one name;
* an if condition (the rows of the plotted nodes); an invalid layout (6556).
* set graphics off: no window is opened; noopen keeps interactive pages closed.
* Run from the repository root.

clear all
set more off
set graphics off
do unw_core.do
run cscripts/xt_meas_00_helpers.do
xt_minit xt_meas_plot
nwclear

* ---------------------------------------------------------------- (1) circle: node order
nwclear
clear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(p4) undirected
nwplot p4, layout(circle) generate(cx cy) noopen
xa cx < . & cy < . in 1/4
qui summarize cx in 1/4
xa cx[4] == r(max) & cx[2] == r(min)
qui summarize cy in 1/4
xa cy[1] == r(max) & cy[3] == r(min)
xa reldif(cx[1], cx[3]) < 1e-6 & reldif(cy[2], cy[4]) < 1e-6
* direction does not matter for the circle
nwset, mat((0,1,0,0\0,0,1,0\0,0,0,1\0,0,0,0)) name(d4) directed
nwplot d4, layout(circle) generate(dx dy) noopen
xa reldif(dx, cx) < 1e-9 & reldif(dy, cy) < 1e-9 in 1/4
graph drop _all
di "(1) circle: ok"

* ---------------------------------------------------------------- (2) generate() -> nodexy() round trip; seeds
nwclear
clear
set seed 3
nwrandom 12, prob(.3) undirected name(r12)
set seed 21
nwplot r12, generate(x1 y1) noopen
nwplot r12, nodexy(x1 y1) generate(x2 y2) noopen
xa abs(x2 - x1) < 1e-6 & abs(y2 - y1) < 1e-6 in 1/12
* the same seed: the same kk layout
set seed 21
nwplot r12, generate(x3 y3) noopen
xa x3 == x1 & y3 == y1 in 1/12
* a valued copy with binary = the unvalued network (same seed)
nwtomata r12, mat(R)
mata: V = R :* 3.5
nwset, mat(V) name(r12v) undirected
set seed 21
nwplot r12v, generate(x4 y4) binary noopen
xa reldif(x4, x1) < 1e-9 & reldif(y4, y1) < 1e-9 in 1/12
mata: mata drop R V
graph drop _all
di "(2) round trip and seeds: ok"

* ---------------------------------------------------------------- (3) grid and bipartite
nwclear
clear
nwset, mat(J(4,4,0) + (0,1,0,0\1,0,0,0\0,0,0,1\0,0,1,0)) name(g4) undirected
nwplot g4, layout(grid, columns(2)) generate(gx gy) noopen
xm assert(rows(uniqrows(st_data((1,4), "gx"))) == 2)
xm assert(rows(uniqrows(st_data((1,4), "gy"))) == 2)
* SUSPECTED BUG: gridlayout() divides by (cols - 1): columns(1) gives missing x coordinates
nwplot g4, layout(grid, columns(1)) generate(g1x g1y) noopen
xa g1x < . & g1y < . in 1/4    // fixed: CONFIRMED BUG M15a
* SUSPECTED BUG: more columns than nodes -> rows == 1 and J(cols, 1, .5) does not fit N rows (r(3200))
capture noisily nwplot g4, layout(grid, columns(6)) generate(g6x g6y) noopen
xa _rc == 0    // fixed: CONFIRMED BUG M15b
xa g6x < . & g6y < . in 1/4    // fixed: CONFIRMED BUG M15b
* bipartite needs a two-mode network
capture nwplot g4, layout(bipartite) generate(bx by) noopen
xa _rc != 0
clear
input str10 person str10 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Tim" "Oxford"
"Peter" "LiU"
"Tim" "LiU"
end
nwset person org, twomode name(tm)
clear
nwplot tm, layout(bipartite) generate(bx by) noopen
* the two modes lie on two lines: one coordinate takes exactly two values
xm assert(rows(uniqrows(st_data((1,5), "by"))) == 2 | rows(uniqrows(st_data((1,5), "bx"))) == 2)
graph drop _all
di "(3) grid and bipartite: ok"

* ---------------------------------------------------------------- (4) tiny networks, generate() names, if, errors
nwclear
clear
nwset, mat((0)) name(one) undirected
nwplot one, generate(ox oy) noopen
xa ox[1] < . & oy[1] < .
nwset, mat((0,1\1,0)) name(two) undirected
nwplot two, generate(tx ty) noopen
xa tx < . & ty < . in 1/2
nwset, mat(J(5,5,0)) name(iso5) undirected
* a network without ties: the nodes are plotted and generate() exports their coordinates like for any network
capture noisily nwplot iso5, generate(ix iy) noopen
xa _rc == 0
capture confirm variable ix iy, exact
xa _rc == 0
xa ix < . & iy < . in 1/5
* generate() needs two names: one name is an error (198), never a silent _x_coord/_y_coord
capture nwplot two, generate(onlyx) noopen
xa _rc == 198
if _rc == 0 {
	capture confirm variable onlyx, exact
	xa _rc == 0    // fixed: CONFIRMED BUG M15c
}
* an existing variable is not overwritten without replace (the other measure commands stop with r(99))
gen byte tx2 = 7
capture nwplot two, generate(tx2 ty2) noopen
xa _rc == 99 & tx2[1] == 7    // fixed: CONFIRMED BUG M15c
nwplot two, generate(tx2 ty2) replace noopen
xa tx2 < . & ty2 < . in 1/2
xa "`: type tx2'" == "double"
* if: the coordinates of the plotted nodes are on the rows of those nodes
clear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(p4) undirected
set obs 4
gen keep = _n >= 3
nwplot p4 if keep == 1, layout(circle) generate(kx ky) noopen
* NOT A BUG (M15d): the data rows are re-keyed by node name (_nwnode) and the plotted nodes come first, so
* rows 1..rows(Coord) are the rows of the plotted nodes c and d; check by _nwnode, not by row number
xa kx < . & ky < . if inlist(_nwnode, "c", "d")
xa kx == . & ky == . if inlist(_nwnode, "a", "b")
xa _N == 4
* errors
capture nwplot p4, layout(spiral) generate(ex ey) noopen
xa _rc == 6556
capture nwplot nosuchnet, generate(ex ey) noopen
xa _rc != 0
graph drop _all
di "(4) tiny, names, if, errors: ok"

nwclear
xt_mend
di "ALL PASS"
