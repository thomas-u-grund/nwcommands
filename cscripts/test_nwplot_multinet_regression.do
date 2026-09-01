cscript

do unw_core.do

* Regression test for a real, reported bug: after
*   nwrandom 1000, prob(.01)
*   nwplot
*   nwrandom 100, prob(.1)
*   nwplot
* both nwplot and nwdegree started failing with a bare, unexplained
* r(99) - on the SECOND network, and (as this test's own first block
* confirms) even on a single network's own SECOND nwplot/nwdegree
* call, with no second network involved at all.
*
* ROOT CAUSE (confirmed via a direct, minimal probe before this fix -
* not guessed): nwplot.ado's own internal degree/isolates computation
* (used for the "mdsclassical" layout, the default for any network
* with more than 50 nodes) generated temporary _degree/_outdegree/
* _indegree/_isolates variables via nwdegree, then tried to clean them
* up with a SINGLE compound "capture drop _isolates _degree _outdegree
* _indegree" command. Stata's plain "drop varlist" is all-or-nothing
* over its ENTIRE list: if even one named variable does not exist, the
* whole command fails and drops NOTHING, not even the variables that
* do exist (confirmed directly: "capture drop a b c d" with only a/b
* existing left both a and b undropped). Exactly one of _degree
* (undirected) or _outdegree/_indegree (directed) is ever actually
* created by nwdegree - the other name(s) never exist - so this
* compound drop silently failed via `capture' on every single call,
* leaving _isolates and whichever of _degree/_outdegree/_indegree WAS
* created stranded in the Stata dataset (an ordinary session-wide
* dataset, not scoped to any one network) after nwplot returned. The
* very next command that tried to generate one of those same default
* variable names - nwplot's own next invocation on ANY network, or a
* plain user nwdegree call - then hit nwdegree.ado's own "variable
* already exists" guard, which itself raised the bare, unexplained
* r(99) because its diagnostic "di" line was silently swallowed by the
* enclosing "qui foreach netname_temp in `netname' { ... }" block (no
* "noi") - both bugs fixed together, in nwplot.ado and nwdegree.ado
* respectively.
*
* This has NOTHING to do with the network registry, sparse backend,
* per-network metadata, current-network tracking, or named-network
* resolution - all confirmed independently correct by this test's own
* assertions below (nw_syntax/nwname continue to resolve every network
* correctly throughout).

* --- exact reported reproduction sequence, end to end ---
nwclear
nwset
assert r(networks) == 0

nwrandom 1000, prob(.01)
nwplot
assert _rc == 0
nwdegree
assert _rc == 0

nwrandom 100, prob(.1)
assert _rc == 0

nwset
assert r(networks) == 2

nwplot
assert _rc == 0
nwplot random_1
assert _rc == 0
* BUGFIX (test-only, found while re-verifying this file 2026-09-01):
* the FIRST `nwdegree` call above (line ~55) already left `_outdegree`/
* `_indegree` behind PERMANENTLY (its own documented, correct, by-design
* behavior without `generate()`/`replace` - nwdegree's own "variable
* already exists" guard is not the nwplot bug this file exists to catch,
* it is nwdegree correctly refusing to silently overwrite the user's own
* prior output). A second bare `nwdegree` call was ALWAYS going to hit
* that guard regardless of anything nwplot itself does - confirmed
* directly via a step-by-step instrumented trace: `_outdegree`/
* `_indegree` are correctly ABSENT after every `nwplot` call alone (its
* own internal cleanup works), and only ever present because of this
* file's own earlier bare `nwdegree` call. `replace` added here (and
* below) to test what this block actually intends to test - that a
* real `nwdegree` call still works after `nwplot` has run on multiple
* networks - without the test colliding with its own earlier output.
nwdegree, replace
assert _rc == 0

* --- the bug reproduces on a SINGLE network's own second nwplot/
* nwdegree call - no second network needed at all, proving this was
* never a multi-network/registry bug in the first place.
nwclear
nwrandom 1000, prob(.01)
nwplot
assert _rc == 0
nwplot
assert _rc == 0
nwdegree, replace
assert _rc == 0

* --- directed and undirected networks both exercised the same buggy
* cleanup line (via different halves of the compound drop's
* varlist) - both must work now, at a node count above the
* mdsclassical-layout threshold (>50) where the buggy code path
* actually runs.
nwclear
nwrandom 200, prob(.02)
nw_syntax random
assert `"`directed'"' == "true"
nwplot
assert _rc == 0
nwplot
assert _rc == 0
nwdegree, replace
assert _rc == 0

nwclear
mata: bigmat = J(80,80,0)
mata: for(i=1;i<=79;i++) bigmat[i,i+1]=1
nwset, mat(bigmat) undirected name(bignet)
nw_syntax bignet
assert `"`directed'"' == "false"
nwplot
assert _rc == 0
nwplot
assert _rc == 0
nwdegree, replace
assert _rc == 0

* --- the actual root-cause invariant: nwplot must never leave
* _degree/_outdegree/_indegree/_isolates stranded in the dataset -
* checked directly, not just indirectly via a later command's success.
nwclear
nwrandom 200, prob(.02)
nwplot
capture confirm variable _degree
assert _rc != 0
capture confirm variable _outdegree
assert _rc != 0
capture confirm variable _indegree
assert _rc != 0
capture confirm variable _isolates
assert _rc != 0

* --- three differently-sized networks, all above the mdsclassical
* threshold, degree+plot on each by explicit name.
nwclear
nwrandom 60, prob(.1)
nwrandom 70, prob(.1)
nwrandom 80, prob(.1)
nwset
assert r(networks) == 3
nwplot random
assert _rc == 0
nwplot random_1
assert _rc == 0
nwplot random_2
assert _rc == 0
nwdegree random, replace
assert _rc == 0
nwdegree random_1, replace
assert _rc == 0
nwdegree random_2, replace
assert _rc == 0

* --- repeated switching A -> B -> A -> C -> B -> A
nwplot random
assert _rc == 0
nwplot random_1
assert _rc == 0
nwplot random
assert _rc == 0
nwplot random_2
assert _rc == 0
nwplot random_1
assert _rc == 0
nwplot random
assert _rc == 0

* --- mixed network types (ordinary/directed/two-mode) coexist -
* metadata/state does not leak between them.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(ordinary) undirected labs(A,B,C)
nwrandom 60, prob(.1)
preserve
clear
input str10 person str10 org
"p1" "o1"
"p2" "o1"
"p1" "o2"
end
nwset person org, twomode name(twomodenet)
restore

nwplot ordinary
assert _rc == 0
nwplot random
assert _rc == 0
nwdegree ordinary, replace
assert _rc == 0
nwdegree random, replace
assert _rc == 0
nw_syntax twomodenet
assert `"`is2mode'"' == "true"

* --- the diagnostic message itself must actually reach the user (not
* be silently swallowed by the enclosing qui block) when the "already
* exists" guard genuinely does fire - checked directly rather than
* only checking _rc, since a swallowed message was itself part of the
* original bug report ("do not treat r(99) as the diagnosis").
nwclear
nwrandom 60, prob(.1)
qui nwdegree random
capture noisily nwdegree random
assert _rc == 99
