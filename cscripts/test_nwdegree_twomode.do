cscript

do unw_core.do

* nwdegree gained two-mode awareness (part of the two-mode/temporal
* architecture initiative's Category-A command migration - "the
* existing operation has a natural two-mode definition, so the
* ordinary command should automatically use the correct bipartite
* definition"). Confirmed a genuine, previously-undiscovered gap
* before this fix: nwdegree had *zero* two-mode awareness at all - it
* silently computed an ordinary one-mode degree on a bipartite
* network's own raw adjacency matrix, a plausible-looking but
* meaningless number, with no error or note of any kind.
*
* Fixed by redirecting to nw2degree (the existing, already-tested
* bipartite degree command) whenever the network's own is2mode
* property is true - the exact same, already-established pattern
* nwclustering.ado already uses for its identical situation, not a
* new algorithm. This is NOT automatic projection (nothing here
* collapses the two-mode network to one mode) - it is choosing the
* correct NATIVE two-mode formula, which is the explicitly-requested
* "Category A" behaviour, distinct from "Category C" commands that
* have no native bipartite definition and must require an explicit
* projection request instead (see docs/NETWORK_TYPE_MATRIX.md).

* --- basic redirect: nwdegree on a two-mode network must produce
* nw2degree's own output (a "_2degree"-named variable, not a
* "_degree" one), not silently run the wrong one-mode formula.
nwclear
clear
input str10 person str10 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Tim" "Oxford"
"Peter" "LiU"
"Tim" "LiU"
"Thomas" "LiU"
end
nwset person org, twomode name(mynet)
nwdegree mynet
assert _rc == 0
capture confirm variable _2degree, exact
assert _rc == 0
capture confirm variable _degree, exact
assert _rc != 0

* --- cross-check: the redirect must produce IDENTICAL results to
* calling nw2degree directly on the same network - not merely "some
* plausible-looking number", the actual correct bipartite formula.
nwclear
clear
input str10 person str10 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Tim" "Oxford"
"Peter" "LiU"
"Tim" "LiU"
"Thomas" "LiU"
end
nwset person org, twomode name(viaredirect)
nwdegree viaredirect
tempname redirectresult
mata: `redirectresult' = st_data(., "_2degree")

nwclear
clear
input str10 person str10 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Tim" "Oxford"
"Peter" "LiU"
"Tim" "LiU"
"Thomas" "LiU"
end
nwset person org, twomode name(viadirect)
nw2degree viadirect
mata: assert(st_data(., "_2degree") == `redirectresult')
mata: mata drop `redirectresult'

* --- ignored one-mode-specific options (no bipartite equivalent) must
* not silently vanish - the command still runs (rather than erroring),
* but is expected to note what was ignored; checked here only that the
* command still completes cleanly with such an option present.
nwclear
clear
input str10 person str10 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Tim" "Oxford"
end
nwset person org, twomode name(mynet)
nwdegree mynet, isolates standardize replace
assert _rc == 0

* --- an ordinary one-mode network must be completely unaffected - a
* regression guard confirming the new redirect branch only fires for
* genuinely two-mode networks.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(onemode) undirected labs(A,B,C)
nwdegree onemode
assert _rc == 0
capture confirm variable _degree, exact
assert _rc == 0
count if _degree == 2
assert r(N) == 3

* --- netlist support: a mixed one-mode + two-mode netlist call must
* correctly dispatch each network to its own correct formula in the
* same call - the one-mode network still gets an ordinary (suffixed)
* one-mode degree variable, the two-mode network gets redirected.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(onemode) undirected labs(A,B,C)
clear
input str10 person str10 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Tim" "Oxford"
end
nwset person org, twomode name(mynet)
nwdegree onemode mynet
assert _rc == 0
capture confirm variable _degree_onemode, exact
assert _rc == 0
capture confirm variable _2degree, exact
assert _rc == 0
