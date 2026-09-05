cscript

do unw_core.do

* nwbrokerage is a new command (harmonisation unit 23, Part XVII special
* priority: structural equivalence and classical SNA). It implements the
* five Gould-Fernandez (1989) brokerage roles via a new
* NWdef::calculate_brokerage() Mata method (unw_core.do), using the sparse
* neighbors()/neighbors_in() accessors directly (the same primitives
* calculate_components()/calculate_kcore() already use), so it scales the
* same way those do rather than needing a dense adjacency matrix.
*
* While building this, a genuinely non-obvious, previously-undocumented
* (in this session) Stata gotcha was found: _rc is only refreshed by a
* command that goes through Stata's normal *displayed* execution path -
* quietly-prefixed commands, mata: blocks, local-macro assignment, and
* inherently-silent commands like a bare "confirm" do NOT update _rc even
* when they succeed (confirmed directly: "qui sum x" and a bare
* "confirm variable x" both leave a prior nonzero _rc completely
* untouched; only a *captured* command deterministically sets _rc to
* exactly its own wrapped result, e.g. "capture confirm variable x" does
* reset it to 0 when x exists). nwbrokerage.ado's own display block uses
* "qui sum" in a loop (to build a compact role/total table) rather than a
* single visible "tab" call the way nwcomponents/nwcommunity/nwconcor/
* nwcoreperiphery's own display blocks do - so it was the one place in
* this session's new commands that actually hit this: the earlier,
* perfectly normal "capture confirm variable ..., exact" already-exists
* probes (expected to fail, since the variable doesn't exist yet) left
* _rc=111 stuck all the way through a fully successful call, silently
* misleading any caller checking _rc right afterward. Fixed with one
* explicit, silent "capture confirm variable <a variable just created>"
* at the end of each iteration - deterministically resets _rc to 0 with
* no visible side effects. Directly regression-tested below (a check the
* command's own final _rc is 0 after a fully successful call - something
* worth checking in future commands built on this same display pattern,
* not just this one).

* --- a network built to test all 5 broker roles simultaneously through
* a single node (b=node 3), with in-neighbors {1,2,4} and out-neighbors
* {5,6} and hand-assigned groups chosen so every one of the 6 possible
* (a,c) two-paths through b lands in a different, exactly predictable
* role: (1,5)=coordinator, (1,6)=representative, (2,5)=gatekeeper,
* (2,6)=consultant, (4,5)=gatekeeper, (4,6)=liaison - hand-derived from
* the role definitions themselves (see nwbrokerage.ado's own doc header)
* before running the code, not reverse-engineered from its output.
nwclear
mata:
M = J(6,6,0)
M[1,3] = 1
M[2,3] = 1
M[4,3] = 1
M[3,5] = 1
M[3,6] = 1
st_matrix("M", M)
end
nwset, mat(M) name(net1) directed labs(n1,n2,n3,n4,n5,n6)
gen grp = .
replace grp = 2 in 1
replace grp = 1 in 2
replace grp = 2 in 3
replace grp = 3 in 4
replace grp = 2 in 5
replace grp = 1 in 6
nwbrokerage net1, group(grp) generate(_broker)
assert _rc == 0
assert r(pairs) == 6
assert _broker_coordinator[3] == 1
assert _broker_gatekeeper[3] == 2
assert _broker_representative[3] == 1
assert _broker_consultant[3] == 1
assert _broker_liaison[3] == 1
* every other node has no in-and-out neighbor pair to classify at all
* (nodes 1,2,4 have no outgoing ties; nodes 5,6 have no incoming ties)
* - all-zero rows are the only correct answer, not merely "untested".
forvalues i = 1/6 {
	if `i' != 3 {
		assert _broker_coordinator[`i'] == 0
		assert _broker_gatekeeper[`i'] == 0
		assert _broker_representative[`i'] == 0
		assert _broker_consultant[`i'] == 0
		assert _broker_liaison[`i'] == 0
	}
}

* --- _rc regression: the command's own final _rc must be 0 after a
* fully successful call - see this file's header comment for the bug
* this guards against.
nwclear
nwset, mat(M) name(net1) directed labs(n1,n2,n3,n4,n5,n6)
gen grp = .
replace grp = 2 in 1
replace grp = 1 in 2
replace grp = 2 in 3
replace grp = 3 in 4
replace grp = 2 in 5
replace grp = 1 in 6
nwbrokerage net1, group(grp) generate(_broker) replace
assert _rc == 0
nwbrokerage net1, group(grp) generate(_broker) replace silent
assert _rc == 0

* --- generate()/replace: a custom stem must be honored (producing 5
* suffixed variables), and a second call without replace must be
* rejected.
nwbrokerage net1, group(grp) generate(custombrk)
assert _rc == 0
foreach role in coordinator gatekeeper representative consultant liaison {
	capture confirm variable custombrk_`role', exact
	assert _rc == 0
}
capture noisily nwbrokerage net1, group(grp) generate(custombrk)
assert _rc != 0
nwbrokerage net1, group(grp) generate(custombrk) replace
assert _rc == 0

* --- netlist support: multiple networks in one call, each getting its
* own suffixed set of 5 output variables.
nwclear
nwset, mat(M) name(net1) directed labs(n1,n2,n3,n4,n5,n6)
nwset, mat(M) name(net2) directed labs(n1,n2,n3,n4,n5,n6)
gen grp = .
replace grp = 2 in 1
replace grp = 1 in 2
replace grp = 2 in 3
replace grp = 3 in 4
replace grp = 2 in 5
replace grp = 1 in 6
nwbrokerage net1 net2, group(grp) generate(_broker)
assert _rc == 0
capture confirm variable _broker_coordinator1, exact
assert _rc == 0
capture confirm variable _broker_coordinator2, exact
assert _rc == 0

* --- regression: a two-path a->b->c must NOT be counted when a already
* has a direct tie to c - Gould-Fernandez brokerage requires a genuine
* structural hole for b to fill; if a can already reach c directly,
* there is nothing on that specific path for b to broker. Bug found and
* fixed while cross-checking calculate_brokerage() against the real
* `statnet/sna` C source (src/gli.c's own brokerage_R(), which only
* classifies a two-path when `!snaIsAdjacent(a,c,...,0)` - "does a
* already send an edge to c"): the original implementation here counted
* every a->b->c two-path unconditionally, silently inflating every
* role's count (especially coordinator) on any network with real
* transitivity. The two test networks above happen to have no direct
* a-c ties at all among their classified two-paths, so neither one
* exercised this - isolated here in a minimal 4-node network with all
* nodes in one group (so classification itself is not in question,
* only whether the excluded pair is dropped).
*
* Node "brk" (node 3) has one in-neighbor "a1" (node 1) and two
* out-neighbors "c1" (node 2, no direct a1->c1 tie - must count) and
* "c2" (node 4, WITH a direct a1->c2 tie - must be excluded).
nwclear
mata:
M2 = J(4,4,0)
M2[1,3] = 1	// a1 -> brk
M2[3,2] = 1	// brk -> c1
M2[3,4] = 1	// brk -> c2
M2[1,4] = 1	// a1 -> c2 directly - the a1-brk-c2 two-path must be excluded
st_matrix("M2", M2)
end
nwset, mat(M2) name(brknet) directed labs(a1,c1,brk,c2)
gen grp3 = 1
nwbrokerage brknet, group(grp3) generate(_broker) replace
assert _rc == 0
assert r(pairs) == 1
assert _broker_coordinator[3] == 1
assert _broker_gatekeeper[3] == 0
assert _broker_representative[3] == 0
assert _broker_consultant[3] == 0
assert _broker_liaison[3] == 0

* --- undirected networks: incoming and outgoing ties are identical, so
* a and c both range over the same neighbor set - must run cleanly, no
* special option needed (unlike nwcommunity's own explicit symmetrize
* requirement).
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,1,0\0,0,1,0,0,0\0,0,1,0,0,0\0,0,0,0,0,0)) name(unet) undirected labs(A,B,C,D,E,F)
gen grp2 = .
replace grp2 = 1 in 1
replace grp2 = 1 in 2
replace grp2 = 2 in 3
replace grp2 = 3 in 4
replace grp2 = 3 in 5
replace grp2 = 4 in 6
nwbrokerage unet, group(grp2) generate(_broker) replace
assert _rc == 0

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwbrokerage nonexistent, group(grp2)
assert _rc == 482
