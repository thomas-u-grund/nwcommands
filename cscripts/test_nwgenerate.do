cscript

do unw_core.do

// check network expressions
nwrandom 5, prob(1) name(mynet1)
nwgen mynet2 = 2 * mynet1
nwvalue mynet2, ego("n1") alter("n2")
assert         r(value)       == 2

gen attr = _n
nwgen mynet3 = mynet2 * attr
nwvalue mynet3, ego("n2") alter("n1")
assert         r(value)       == 4

nwgen mynet4 = mynet3 * mynet2
nwvalue mynet4, ego("n2") alter("n1")
assert         r(value)       == 8

// check if condition
nwgen mynet5 = mynet4 if attr >=3
nwsummarize mynet5
assert         r(nodes)         == 3
assert `"`r(vars)'"'     == `"n3 n4 n5"'

nwgen mynet6 = 2 * exp(mynet1) if _n >=2
nwvalue mynet6, ego("n2") alter("n3")
assert floor( r(value)) == 5







* --- variable-producing shortcuts (nwgen VAR = fcn(netname)), a
* SEPARATE keyword family from the network-producing ones tested
* above. Until this fix, 16 keywords parsed without error (recognized
* by this file's own `nwgenopt' vocabulary) but had NO dispatch branch
* at all, so e.g. "nwgen x = isolates(net)" silently left `x' never
* created - a real, previously-undiscovered bug that had already
* caused two real problems inside this package itself (nwplot.ado's
* own mdsclassical layout used exactly three of these internally
* before being fixed to route around the gap - see
* docs/CERTIFICATION.md unit 33). 13 of the 16 map cleanly to an
* already-existing, already-tested command's own generate() option -
* each checked here against a hand-computable 4-node directed star
* (A -> B, A -> C, A -> D: A's true outdegree is 3/indegree 0, B/C/D's
* true outdegree is 0/indegree 1, nobody is isolated, betweenness is
* concentrated entirely on A) and, separately, an undirected version
* of the same shape for the shortcuts that don't need directedness
* distinguished.

nwclear
nwset, mat((0,1,1,1\0,0,0,0\0,0,0,0\0,0,0,0)) directed name(dirstar) labs(A,B,C,D)

nwgen d_out = outdegree(dirstar)
assert d_out[1] == 3
assert d_out[2] == 0

nwgen d_in = indegree(dirstar)
assert d_in[1] == 0
assert d_in[2] == 1

* "degree(" on a directed network is out+in summed (igraph's own
* default convention for a directed graph's degree()) - not otherwise
* documented anywhere in this package, so pinned down explicitly here.
nwgen d_deg = degree(dirstar)
assert d_deg[1] == 3
assert d_deg[2] == 1

nwgen d_iso = isolates(dirstar)
assert d_iso[1] == 0
assert d_iso[2] == 0

nwgen d_betw = between(dirstar)
* nwbetween auto-symmetrizes by default (its own "nosym" option skips
* this - not passed here), so this comes out identical to the
* undirected star's own betweenness below (A=3, leaves=0) - verified
* directly rather than assumed, confirming the shortcut reaches
* nwbetween correctly with its own established default behaviour.
assert d_betw[1] == 3
assert d_betw[2] == 0

* replace: the directed "degree(" branch combines two nwdegree-
* generated temp variables into the target via a plain "gen", which
* (unlike nwdegree's own generate()) has no built-in replace-awareness
* of its own - fixed explicitly, checked directly here since it was a
* real bug found and fixed while building this (a stale, always-empty
* dedicated `replace' local was checked instead of the raw option text
* actually carrying it).
nwgen d_deg = degree(dirstar), replace
assert _rc == 0
capture noisily nwgen d_deg = degree(dirstar)
assert _rc == 99

nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) undirected name(undstar) labs(A,B,C,D)

nwgen u_deg = degree(undstar)
assert u_deg[1] == 3
assert u_deg[2] == 1

nwgen u_iso = isolates(undstar)
assert u_iso[1] == 0

nwgen u_comp = components(undstar)
assert u_comp[1] == u_comp[2]

nwgen u_lgc = lgc(undstar)
assert u_lgc[1] == 1
assert u_lgc[2] == 1

nwgen u_clust = clustering(undstar)
assert _rc == 0

nwgen u_close = closeness(undstar)
assert u_close[1] == 1

nwgen u_far = farness(undstar)
assert u_far[1] == 3
assert u_far[2] == 5

nwgen u_near = nearness(undstar)
assert _rc == 0

nwgen u_betw = between(undstar)
assert u_betw[1] == 3
assert u_betw[2] == 0

nwgen u_evc = evcent(undstar)
assert u_evc[1] > u_evc[2]

gen myattr = _n
nwgen u_ctx = context(undstar), attribute(myattr)
assert _rc == 0

* --- the 3 keywords that do NOT reduce to a single per-node variable
* (nwaddnodes mutates a network's own node set; nwsubset produces a
* new NETWORK, not a variable; nwcollapse needs separate design work)
* must fail with a clear, immediate, explanatory error - not silently
* do nothing, the exact bug this whole block fixes.
capture noisily nwgen x1 = addnodes(undstar)
assert _rc == 199
capture confirm variable x1
assert _rc != 0

capture noisily nwgen x2 = collapse(undstar)
assert _rc == 199
capture confirm variable x2
assert _rc != 0

capture noisily nwgen x3 = subset(undstar)
assert _rc == 199
capture confirm variable x3
assert _rc != 0
