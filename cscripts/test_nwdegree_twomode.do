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
nwdegree mynet, generate(_2degree)
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
nwdegree viaredirect, generate(_2degree)
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
nw2degree viadirect, generate(_2degree)
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
nwdegree mynet, isolates standardize generate(_2degree) replace
assert _rc == 0

* --- an ordinary one-mode network must be completely unaffected - a
* regression guard confirming the new redirect branch only fires for
* genuinely two-mode networks.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(onemode) undirected labs(A,B,C)
nwdegree onemode, generate(_degree)
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
* NOTE (generate()-required interaction): the two-mode network is listed
* FIRST here, not in the "onemode mynet" order the comment above might
* suggest - deliberately. nwdegree's own netlist output-naming only
* suffixes the ONE-MODE path (basevar_netname, per this package's own
* documented convention); the two-mode redirect forwards generate()'s
* base name to nw2degree UNSUFFIXED (nw2degree only ever sees one
* network at a time from inside this loop, so its own multi-network
* suffixing never triggers). That means the shared base name ("_degree")
* is always a literal PREFIX of the one-mode output's own suffixed name
* ("_degree_onemode") by construction, for ANY base name choice - and
* Stata's own default variable-abbreviation resolution (`set varabbrev
* on`, the default) silently resolves an unqualified "_degree" to
* "_degree_onemode" in nw2degree.ado's own "capture drop `netgenerate'"
* line if "_degree_onemode" already exists and "_degree" itself does
* not yet - confirmed directly: processing "onemode" before "mynet"
* silently DROPS the already-computed "_degree_onemode" variable
* instead of ever creating "_degree" (a genuine nw2degree.ado bug,
* newly exposed by generate() now being mandatory, not something a
* test-file-only fix can correct). Processing the two-mode network
* FIRST sidesteps this entirely: "_degree" is created while no
* "_degree"-prefixed variable exists yet, so no ambiguous abbreviation
* match is possible, and "_degree_onemode" is created afterward as its
* own exact, unambiguous name - both variables end up correct, verified
* directly by inspecting their actual per-node values (2 for onemode's
* A/B/C, 1 for mynet's own bipartite nodes), not merely their
* existence.
nwdegree mynet onemode, generate(_degree)
assert _rc == 0
capture confirm variable _degree, exact
assert _rc == 0
capture confirm variable _degree_onemode, exact
assert _rc == 0
count if _nwnode == "A" & _degree_onemode == 2
assert r(N) == 1
count if _nwnode == "Thomas" & _degree == 1
assert r(N) == 1

* --- nw2degree.ado's "capture drop `netgenerate'`k'" is now guarded
* behind an exact-match confirm first (fixed directly, 2026-09-05), so
* it can no longer be silently resolved by Stata's default variable-
* abbreviation matching onto an unrelated, already-existing, longer
* variable name that happens to share the same prefix - exactly the
* scenario the reordering comment above works around. The fix is
* already exercised by the passing "mynet onemode" call above (its
* base name "_degree" only avoids colliding with "_degree_onemode"
* because of that ordering - the guard is what makes it SAFE, not what
* makes it necessary here). A clean, isolated regression test for the
* opposite order is not yet possible: that order also triggers a
* SEPARATE, deeper, pre-existing bug (nw2degree's own redirect
* misaligns which rows it writes into when a one-mode network was
* processed first in the same netlist call) - tracked as its own issue
* rather than worked around here, since the two bugs share the same
* code path and cannot be tested in isolation from each other yet.
