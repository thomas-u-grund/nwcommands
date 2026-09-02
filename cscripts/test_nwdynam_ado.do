cscript

* End-to-end smoke test: nwdynam.ado through a REAL nwset ..., eventtime()
* declared network. The real cross-tool correctness check against
* goldfish's own reference numbers on real data lives in
* dev/dynam_unit1_choice_crosscheck.do (choice sub-model) and
* dev/dynam_unit2_rate_crosscheck.do (rate sub-model) - dev/ crosscheck
* convention, not cscripts/ - matching nwrem's own
* dev/rem_relevent_crosscheck.do precedent - this file only certifies
* the .ado wrapper's own option handling and failure paths, same role
* test_nwrem_ado.do plays for nwrem.

do unw_core.do
do unw_ergm.do
do unw_dynam.do

nwclear
clear
set obs 400
gen long sender = .
gen long receiver = .
gen eventtime = _n

mata:
mata set matastrict off
rseed(20260902)
n = 10
for (i=1; i<=400; i++) {
	pair = runiformint(1, 2, 1, n)
	while (pair[1] == pair[2]) pair = runiformint(1, 2, 1, n)
	st_store(i, "sender", pair[1])
	st_store(i, "receiver", pair[2])
}
end

nwset sender receiver, eventtime(eventtime) name(chatlog)

di as text "{hline 60}"
di as text "Test: nwdynam requires eventtime()-declared network, errors on an ordinary one"
di as text "{hline 60}"
nwrandom 8, prob(.3) name(ordinarynet)
capture noisily nwdynam ordinarynet
assert _rc == 198
di as text "  correctly rejected non-event network (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: nwdynam fits successfully on the real eventtime() network (default submodel(choice))"
di as text "{hline 60}"
nwdynam chatlog

assert e(N) == 400
assert e(nodes) == 10
assert !missing(e(ll))
assert rowsof(e(b)) == 1
assert colsof(e(b)) == 3
assert "`e(submodel)'" == "choice"

di as text "{hline 60}"
di as text "e(b): " e(b)[1,1] "  " e(b)[1,2] "  " e(b)[1,3]
di as text "e(ll): " e(ll)
di as text "{hline 60}"

di as text "{hline 60}"
di as text "Test: nwdynam, submodel(choice) explicitly given fits identically"
di as text "{hline 60}"
nwdynam chatlog, submodel(choice)
assert e(N) == 400
assert colsof(e(b)) == 3

di as text "{hline 60}"
di as text "Test: nwdynam, submodel(rate) fits successfully (Unit 2, no intercept)"
di as text "{hline 60}"
nwdynam chatlog, submodel(rate)
assert e(N) == 400
assert e(nodes) == 10
assert !missing(e(ll))
assert rowsof(e(b)) == 1
assert colsof(e(b)) == 2
assert "`e(submodel)'" == "rate"
di as text "  rate fit: " e(b)[1,1] "  " e(b)[1,2] "   e(ll)=" e(ll)

di as text "{hline 60}"
di as text "Test: nwdynam rejects an unrecognized submodel() value"
di as text "{hline 60}"
capture noisily nwdynam chatlog, submodel(bogus)
assert _rc == 198
di as text "  correctly rejected submodel(bogus) (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: effect selection (docs/DYNAM_ROADMAP.md) - choice sub-model"
di as text "{hline 60}"

* No flags given: default preserves the ORIGINAL all-effects behavior
* exactly (this must never silently change now that selection exists).
nwdynam chatlog
assert colsof(e(b)) == 3
assert "`e(effects)'" == "inertia recip indeg"

* A genuine subset - exactly the requested effects, in the FIXED
* declared order (inertia, recip, indeg), not the order flags were
* typed in the command line.
nwdynam chatlog, indeg inertia
assert colsof(e(b)) == 2
assert "`e(effects)'" == "inertia indeg"
di as text "  choice(inertia,indeg): " e(b)[1,1] " " e(b)[1,2]

nwdynam chatlog, recip
assert colsof(e(b)) == 1
assert "`e(effects)'" == "recip"
di as text "  choice(recip only): " e(b)[1,1]

* Explicitly flagging EVERY effect is equivalent to the default (both
* reach the native-eligible DynamFitUnit1() path, not DynamChoiceFitMulti()).
nwdynam chatlog, inertia recip indeg
assert colsof(e(b)) == 3

* outdeg is valid under BOTH sub-models (goldfish's own effect table -
* "choice sub-model only" was this file's own earlier documentation
* error, corrected 2026-09-02 - see unw_dynam.do's own Effect 8 header
* comment). ego() remains the only genuinely rate-only structural flag
* (already exercised below, once the xvars covariate dataset is loaded).
nwdynam chatlog, outdeg
assert colsof(e(b)) == 1
assert "`e(effects)'" == "outdeg"
di as text "  choice(outdeg only): " e(b)[1,1]

nwdynam chatlog, inertia outdeg
assert colsof(e(b)) == 2
assert "`e(effects)'" == "inertia outdeg"
di as text "  choice(inertia, outdeg): " e(b)[1,1] " " e(b)[1,2]

di as text "{hline 60}"
di as text "Test: effect selection - rate sub-model"
di as text "{hline 60}"

nwdynam chatlog, submodel(rate)
assert colsof(e(b)) == 2
assert "`e(effects)'" == "indeg outdeg"

nwdynam chatlog, submodel(rate) outdeg
assert colsof(e(b)) == 1
assert "`e(effects)'" == "outdeg"
di as text "  rate(outdeg only): " e(b)[1,1]

nwdynam chatlog, submodel(rate) indeg
assert colsof(e(b)) == 1
assert "`e(effects)'" == "indeg"

* A choice-only effect flag is rejected under submodel(rate).
capture noisily nwdynam chatlog, submodel(rate) inertia
assert _rc == 198
di as text "  correctly rejected inertia under submodel(rate) (rc=" _rc ")"
capture noisily nwdynam chatlog, submodel(rate) recip
assert _rc == 198
di as text "  correctly rejected recip under submodel(rate) (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: effect expansion - same()/diff()/sim() attribute effects (choice only)"
di as text "{hline 60}"

nwload chatlog, xvars
gen floor = mod(_n, 3) + 1
* A second, genuinely different covariate - diff()/sim() on the SAME
* variable are perfectly collinear (sim = -diff exactly, see
* unw_dynam.do's own comment), so combining them in one model needs two
* different variables to stay identified; used below in the
* "every effect at once" smoke test for exactly that reason.
gen floor2 = mod(_n, 2) + 1

* same()/diff()/sim() are NEVER included by the "give nothing" default -
* a variable name has no sensible default.
nwdynam chatlog
assert colsof(e(b)) == 3
assert "`e(effects)'" == "inertia recip indeg"

nwdynam chatlog, same(floor)
assert colsof(e(b)) == 1
assert "`e(effects)'" == "same"
di as text "  choice(same(floor) only): " e(b)[1,1]

nwdynam chatlog, inertia diff(floor)
assert colsof(e(b)) == 2
assert "`e(effects)'" == "inertia diff"
di as text "  choice(inertia, diff(floor)): " e(b)[1,1] " " e(b)[1,2]

nwdynam chatlog, sim(floor)
assert colsof(e(b)) == 1
assert "`e(effects)'" == "sim"

* Naming EVERY effect explicitly (structural + attribute) still uses
* the Mata-only Multi engine (not the native Unit1 path, which has no
* attribute-effect support at all) - just confirming it fits without
* error, not asserting a specific native/non-native path here. diff()
* and sim() deliberately use DIFFERENT variables (floor vs. floor2) -
* on the SAME variable they are perfectly collinear (sim = -diff
* exactly) and the joint model is unidentified, a genuine finding (not
* a bug) from first drafting this test with one shared variable and
* hitting a real "flat region encountered" optimizer failure.
nwdynam chatlog, inertia recip indeg same(floor) diff(floor) sim(floor2)
assert colsof(e(b)) == 6

* same()/diff()/sim() are rejected under submodel(rate).
capture noisily nwdynam chatlog, submodel(rate) same(floor)
assert _rc == 198
di as text "  correctly rejected same() under submodel(rate) (rc=" _rc ")"
capture noisily nwdynam chatlog, submodel(rate) diff(floor)
assert _rc == 198
di as text "  correctly rejected diff() under submodel(rate) (rc=" _rc ")"
capture noisily nwdynam chatlog, submodel(rate) sim(floor)
assert _rc == 198
di as text "  correctly rejected sim() under submodel(rate) (rc=" _rc ")"

* same() requires a numeric variable - a string variable is rejected by
* the syntax parser itself (declared `varname numeric`, matching
* nwrem.ado's own covsnd() convention - see test_nwrem_ado.do's own
* comment on this same "caught before the body ever runs" situation).
gen str1 floorstr = "a"
capture noisily nwdynam chatlog, same(floorstr)
assert _rc == 109
di as text "  correctly rejected non-numeric same() (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: effect expansion - ego()/alter() attribute effects"
di as text "{hline 60}"

nwload chatlog, xvars

nwdynam chatlog, alter(floor)
assert colsof(e(b)) == 1
assert "`e(effects)'" == "alter"
di as text "  choice(alter(floor) only): " e(b)[1,1]

nwdynam chatlog, submodel(rate) ego(floor)
assert colsof(e(b)) == 1
assert "`e(effects)'" == "ego"
di as text "  rate(ego(floor) only): " e(b)[1,1]

nwdynam chatlog, submodel(rate) outdeg ego(floor)
assert colsof(e(b)) == 2
assert "`e(effects)'" == "outdeg ego"

* alter() is choice-only, ego() is rate-only - each rejected under the
* other submodel, matching goldfish's own effect table exactly.
capture noisily nwdynam chatlog, submodel(rate) alter(floor)
assert _rc == 198
di as text "  correctly rejected alter() under submodel(rate) (rc=" _rc ")"
capture noisily nwdynam chatlog, ego(floor)
assert _rc == 198
di as text "  correctly rejected ego() under submodel(choice) (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: effect expansion - inertiawindow()/recipwindow() (per-effect recency cutoff)"
di as text "{hline 60}"

* chatlog's own eventtime is 1..400 (integer sequence, gen eventtime = _n
* at the top of this file) - a window smaller than the full range
* genuinely restricts something, a window larger than it does not.
nwdynam chatlog, inertia inertiawindow(50)
assert colsof(e(b)) == 1
assert "`e(effects)'" == "inertia"
di as text "  choice(inertia, inertiawindow(50)): " e(b)[1,1]

* Genuinely DIFFERENT windows on inertia and recip in the SAME model -
* the whole point of the per-effect design (a single earlier command-
* level window() option could not express this at all).
nwdynam chatlog, inertia recip inertiawindow(50) recipwindow(200)
assert colsof(e(b)) == 2
assert "`e(effects)'" == "inertia recip"
di as text "  choice(inertia, recip, inertiawindow(50), recipwindow(200)): " e(b)[1,1] " " e(b)[1,2]

* inertiawindow()/recipwindow() are SELF-ACTIVATING, matching
* {help nwergm}'s own gwesp(real) convention exactly - giving the
* window option alone (with no separate inertia/recip flag) both
* selects that effect AND sets its window in one step, the same way
* gwesp(0.5) needs no separate "include gwesp" flag.
nwdynam chatlog, indeg inertiawindow(50)
assert colsof(e(b)) == 2
assert "`e(effects)'" == "inertia indeg"
di as text "  choice(indeg, inertiawindow(50) alone activates inertia too): " e(b)[1,1] " " e(b)[1,2]

nwdynam chatlog, recipwindow(50)
assert colsof(e(b)) == 1
assert "`e(effects)'" == "recip"
di as text "  choice(recipwindow(50) alone activates recip): " e(b)[1,1]

* Both are choice-only (indeg/outdeg's own window counterpart lives on
* the rate sub-model instead - see indegwindow()/outdegwindow() below).
capture noisily nwdynam chatlog, submodel(rate) inertiawindow(50)
assert _rc == 198
di as text "  correctly rejected inertiawindow() under submodel(rate) (rc=" _rc ")"
capture noisily nwdynam chatlog, submodel(rate) recipwindow(50)
assert _rc == 198
di as text "  correctly rejected recipwindow() under submodel(rate) (rc=" _rc ")"

* Both must be positive.
capture noisily nwdynam chatlog, inertia inertiawindow(-5)
assert _rc == 198
di as text "  correctly rejected non-positive inertiawindow() (rc=" _rc ")"
capture noisily nwdynam chatlog, inertia inertiawindow(0)
assert _rc == 198
di as text "  correctly rejected inertiawindow(0) (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: effect expansion - indegwindow()/outdegwindow() (rate sub-model's"
di as text "own recency cutoff on indeg/outdeg, matching inertiawindow()/recipwindow()'s"
di as text "own self-activating convention)"
di as text "{hline 60}"

nwdynam chatlog, submodel(rate) indegwindow(50)
assert colsof(e(b)) == 1
assert "`e(effects)'" == "indeg"
di as text "  rate(indegwindow(50) alone activates indeg): " e(b)[1,1]

nwdynam chatlog, submodel(rate) outdegwindow(50)
assert colsof(e(b)) == 1
assert "`e(effects)'" == "outdeg"
di as text "  rate(outdegwindow(50) alone activates outdeg): " e(b)[1,1]

nwdynam chatlog, submodel(rate) indegwindow(50) outdegwindow(200)
assert colsof(e(b)) == 2
assert "`e(effects)'" == "indeg outdeg"
di as text "  rate(indegwindow(50), outdegwindow(200)): " e(b)[1,1] " " e(b)[1,2]

* Both are rate-only (inertia/recip's own window counterpart lives on
* the choice sub-model instead - see inertiawindow()/recipwindow() above).
capture noisily nwdynam chatlog, indegwindow(50)
assert _rc == 198
di as text "  correctly rejected indegwindow() under default (choice) submodel (rc=" _rc ")"
capture noisily nwdynam chatlog, submodel(choice) outdegwindow(50)
assert _rc == 198
di as text "  correctly rejected outdegwindow() under submodel(choice) (rc=" _rc ")"

* Both must be positive.
capture noisily nwdynam chatlog, submodel(rate) indegwindow(-5)
assert _rc == 198
di as text "  correctly rejected non-positive indegwindow() (rc=" _rc ")"
capture noisily nwdynam chatlog, submodel(rate) outdegwindow(0)
assert _rc == 198
di as text "  correctly rejected outdegwindow(0) (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: effect expansion - weightedinertia/weightedrecip/weightedindeg/"
di as text "weightedoutdeg (goldfish's own weighted=TRUE argument, self-activating)"
di as text "{hline 60}"

nwdynam chatlog, weightedinertia
assert colsof(e(b)) == 1
assert "`e(effects)'" == "inertia"
di as text "  choice(weightedinertia alone activates inertia): " e(b)[1,1]

nwdynam chatlog, weightedindeg
assert colsof(e(b)) == 1
assert "`e(effects)'" == "indeg"
di as text "  choice(weightedindeg): " e(b)[1,1]

nwdynam chatlog, submodel(rate) weightedindeg weightedoutdeg
assert colsof(e(b)) == 2
assert "`e(effects)'" == "indeg outdeg"
di as text "  rate(weightedindeg, weightedoutdeg): " e(b)[1,1] " " e(b)[1,2]

* weighted and window are mutually exclusive for the SAME effect.
capture noisily nwdynam chatlog, weightedinertia inertiawindow(50)
assert _rc == 198
di as text "  correctly rejected weightedinertia + inertiawindow() together (rc=" _rc ")"
capture noisily nwdynam chatlog, submodel(rate) weightedindeg indegwindow(50)
assert _rc == 198
di as text "  correctly rejected weightedindeg + indegwindow() together (rc=" _rc ")"

* weightedinertia/weightedrecip are choice-only.
capture noisily nwdynam chatlog, submodel(rate) weightedinertia
assert _rc == 198
di as text "  correctly rejected weightedinertia under submodel(rate) (rc=" _rc ")"
capture noisily nwdynam chatlog, submodel(rate) weightedrecip
assert _rc == 198
di as text "  correctly rejected weightedrecip under submodel(rate) (rc=" _rc ")"

* same()/diff()/sim()/ego()/alter() require the current dataset to have exactly one
* row per actor, matching nwrem.ado's own covsnd() row-count check.
clear
set obs 5
gen mismatched = _n
capture noisily nwdynam chatlog, same(mismatched)
assert _rc != 0
di as text "  correctly rejected wrong-row-count same() (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: effect expansion - trans/cycle/commonsender/commonreceiver/four (choice-only"
di as text "two-path closure effects) and nodetrans (both sub-models)"
di as text "{hline 60}"

nwdynam chatlog, trans
assert colsof(e(b)) == 1
assert "`e(effects)'" == "trans"
di as text "  choice(trans only): " e(b)[1,1]

nwdynam chatlog, cycle commonsender commonreceiver four
assert colsof(e(b)) == 4
assert "`e(effects)'" == "cycle commonsender commonreceiver four"
di as text "  choice(cycle, commonsender, commonreceiver, four): " e(b)[1,1] " " e(b)[1,2] " " e(b)[1,3] " " e(b)[1,4]

nwdynam chatlog, nodetrans
assert colsof(e(b)) == 1
assert "`e(effects)'" == "nodetrans"
di as text "  choice(nodetrans only): " e(b)[1,1]

nwdynam chatlog, submodel(rate) nodetrans
assert colsof(e(b)) == 1
assert "`e(effects)'" == "nodetrans"
di as text "  rate(nodetrans only): " e(b)[1,1]

* trans/cycle/commonsender/commonreceiver/four are choice-only (unlike
* nodetrans, which - like indeg/outdeg - is valid under both sub-models).
capture noisily nwdynam chatlog, submodel(rate) trans
assert _rc == 198
di as text "  correctly rejected trans under submodel(rate) (rc=" _rc ")"
capture noisily nwdynam chatlog, submodel(rate) four
assert _rc == 198
di as text "  correctly rejected four under submodel(rate) (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: effect expansion - tertius() (both sub-models) and egoalterint() (choice-only)"
di as text "{hline 60}"

clear
nwload chatlog, xvars
gen floor2 = mod(_n, 2) + 1

nwdynam chatlog, tertius(floor)
assert colsof(e(b)) == 1
assert "`e(effects)'" == "tertius"
di as text "  choice(tertius(floor) only): " e(b)[1,1]

nwdynam chatlog, submodel(rate) tertius(floor)
assert colsof(e(b)) == 1
assert "`e(effects)'" == "tertius"
di as text "  rate(tertius(floor) only): " e(b)[1,1]

nwdynam chatlog, egoalterint(floor floor2)
assert colsof(e(b)) == 1
assert "`e(effects)'" == "egoalterint"
di as text "  choice(egoalterint(floor,floor2) only): " e(b)[1,1]

capture noisily nwdynam chatlog, submodel(rate) egoalterint(floor floor2)
assert _rc == 198
di as text "  correctly rejected egoalterint() under submodel(rate) (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: nwdynam requires a directed network (v1 scope, choice_coordination not yet implemented)"
di as text "{hline 60}"
nwclear
clear
set obs 20
gen long sender = .
gen long receiver = .
gen eventtime = _n
mata:
rseed(20260902)
n = 6
for (i=1; i<=20; i++) {
	pair = runiformint(1, 2, 1, n)
	while (pair[1] == pair[2]) pair = runiformint(1, 2, 1, n)
	st_store(i, "sender", pair[1])
	st_store(i, "receiver", pair[2])
}
end
nwset sender receiver, eventtime(eventtime) name(undirectedchatlog) undirected
capture noisily nwdynam undirectedchatlog
assert _rc == 198
di as text "  correctly rejected undirected network (rc=" _rc ")"

* Two-mode rejection is NOT independently exercised here - same
* genuinely-unreachable-via-the-public-interface situation
* test_nwrem_ado.do's own comment documents (nwset's own
* time()/interval()/eventtime() cannot currently be combined with
* twomode/bipartite in the same call).

di as text "{hline 60}"
di as text "Test: nwdynam requires at least 2 events to fit a model"
di as text "{hline 60}"
nwclear
clear
set obs 1
gen long sender = 1
gen long receiver = 2
gen eventtime = 1
nwset sender receiver, eventtime(eventtime) name(onevent)
capture noisily nwdynam onevent
assert _rc == 2001
di as text "  correctly rejected a single-event network (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: nwdynam rejects a self-loop event (sender == receiver)"
di as text "{hline 60}"
* 3 distinct actors, not 2 - nwset's own directed-vs-undirected
* auto-detection (unrelated to nwdynam, a pre-existing nw_syntax
* quirk found while writing this test) mis-resolves a purely
* 2-actor eventtime() network as undirected, which would make this
* test hit nwdynam's OWN directed-only guard instead of the self-loop
* guard being certified here.
nwclear
clear
input long sender long receiver eventtime
1 2 1
2 3 2
1 1 3
end
nwset sender receiver, eventtime(eventtime) name(selfloopnet)
capture noisily nwdynam selfloopnet
assert _rc != 0
di as text "  correctly rejected self-loop event (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: opportunities() (batch 10, 2026-09-02) - goldfish's own"
di as text "opportunitiesList, choice sub-model only. Real cross-tool"
di as text "correctness check against goldfish is dev/dynam_unit13_"
di as text "opportunities_crosscheck.do (direct Mata) and dev/dynam_unit13b_"
di as text "opportunities_ado_crosscheck.do (through this same .ado command) -"
di as text "this block only certifies the .ado wrapper's own option handling"
di as text "and failure paths."
di as text "{hline 60}"
nwclear
clear
input long sender long receiver long eventtime
1 2 1
2 3 2
3 4 3
4 5 4
5 1 5
1 3 6
2 4 7
3 5 8
4 1 9
5 2 10
end
nwset sender receiver, eventtime(eventtime) name(oppsmall)

nwdynam oppsmall, submodel(choice) inertia
di as text "  fits successfully without opportunities() (baseline)"

* One row per (event, available-actor) pair - a genuinely different
* dataset shape from same()/diff()/sim()/alter()/ego()/tertius()/
* egoalterint(), which is why opportunities() cannot be combined with
* them in one call (documented in unw_dynam.do's/nwdynam.ado's own
* header comments as a real v1 limitation).
clear
input long oppevent long oppactor
1 1
1 2
1 3
1 4
1 5
2 1
2 2
2 3
2 4
2 5
end
forvalues e = 3/10 {
	forvalues a = 1/5 {
		local __n = _N + 1
		set obs `__n'
		replace oppevent = `e' in `__n'
		replace oppactor = `a' in `__n'
	}
}
nwdynam oppsmall, submodel(choice) inertia opportunities(oppevent oppactor)
di as text "  fits successfully WITH opportunities() (full risk set every event)"

di as text "{hline 60}"
di as text "Test: opportunities() rejected under submodel(rate)"
di as text "{hline 60}"
capture noisily nwdynam oppsmall, submodel(rate) opportunities(oppevent oppactor)
assert _rc == 198
di as text "  correctly rejected (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: opportunities() rejects an out-of-range event sequence number"
di as text "{hline 60}"
clear
input long oppevent long oppactor
99 1
end
capture noisily nwdynam oppsmall, submodel(choice) inertia opportunities(oppevent oppactor)
assert _rc == 198
di as text "  correctly rejected (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: opportunities() rejects an out-of-range actor ID"
di as text "{hline 60}"
clear
input long oppevent long oppactor
1 99
end
capture noisily nwdynam oppsmall, submodel(choice) inertia opportunities(oppevent oppactor)
assert _rc == 198
di as text "  correctly rejected (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: submodel(choice_coordination) (batch 11, 2026-09-02) - goldfish's"
di as text "own third DyNAM sub-model, a multinomial-multinomial joint model over"
di as text "unordered actor pairs, for undirected tie-formation events. Real"
di as text "cross-tool correctness check against goldfish is dev/dynam_unit14_"
di as text "coordination_crosscheck.do (direct Mata) and dev/dynam_unit14b_"
di as text "coordination_ado_crosscheck.do (through this same .ado command) -"
di as text "this block only certifies the .ado wrapper's own option handling"
di as text "and failure paths."
di as text "{hline 60}"
nwclear
clear
input long sender long receiver long eventtime
1 2 1
2 3 2
3 4 3
4 5 4
5 1 5
1 3 6
2 4 7
3 5 8
4 1 9
5 2 10
end
nwset sender receiver, eventtime(eventtime) name(coordsmall) undirected

di as text "Test: submodel(choice_coordination) requires an undirected network"
clear
input long sender long receiver long eventtime
1 2 1
2 3 2
3 4 3
4 5 4
5 1 5
1 3 6
2 4 7
3 5 8
4 1 9
5 2 10
end
nwset sender receiver, eventtime(eventtime) name(directedsmall)
capture noisily nwdynam directedsmall, submodel(choice_coordination)
assert _rc == 198
di as text "  correctly rejected directed network (rc=" _rc ")"

di as text "Test: submodel(choice_coordination) fits successfully (default: inertia indeg)"
nwdynam coordsmall, submodel(choice_coordination)
di as text "  fits successfully with the default effect set"

di as text "Test: submodel(choice_coordination) fits a genuine subset with same()"
nwload coordsmall, xvars
gen floor = mod(_n, 2)
nwdynam coordsmall, submodel(choice_coordination) inertia same(floor)
di as text "  fits successfully with inertia + same(floor)"

di as text "Test: submodel(choice_coordination) fits nodetrans/trans (batch 12, 2026-09-02)"
nwdynam coordsmall, submodel(choice_coordination) nodetrans
di as text "  fits successfully with nodetrans"
nwdynam coordsmall, submodel(choice_coordination) trans
di as text "  fits successfully with trans"

di as text "Test: submodel(choice_coordination) fits tertius()/four (batch 13, 2026-09-02)"
nwdynam coordsmall, submodel(choice_coordination) tertius(floor)
di as text "  fits successfully with tertius(floor)"
nwdynam coordsmall, submodel(choice_coordination) four
di as text "  fits successfully with four"

di as text "Test: submodel(choice_coordination) fits egoalterint() (batch 14, 2026-09-02)"
gen floor2 = mod(_n+1, 3)
nwdynam coordsmall, submodel(choice_coordination) egoalterint(floor floor2)
di as text "  fits successfully with egoalterint(floor floor2)"

di as text "{hline 60}"
di as text "Test: choice-only/rate-only effects rejected under choice_coordination"
di as text "{hline 60}"
capture noisily nwdynam coordsmall, submodel(choice_coordination) recip
assert _rc == 198
di as text "  correctly rejected recip (rc=" _rc ")"
capture noisily nwdynam coordsmall, submodel(choice_coordination) outdeg
assert _rc == 198
di as text "  correctly rejected outdeg (rc=" _rc ")"
capture noisily nwdynam coordsmall, submodel(choice_coordination) cycle
assert _rc == 198
di as text "  correctly rejected cycle (rc=" _rc ")"
capture noisily nwdynam coordsmall, submodel(choice_coordination) ego(floor)
assert _rc == 198
di as text "  correctly rejected ego() (rc=" _rc ")"
capture noisily nwdynam coordsmall, submodel(choice_coordination) commonsender
assert _rc == 198
di as text "  correctly rejected commonsender (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: opportunities()/weightedindeg/window options rejected under"
di as text "choice_coordination"
di as text "{hline 60}"
capture noisily nwdynam coordsmall, submodel(choice_coordination) opportunities(floor floor)
assert _rc == 198
di as text "  correctly rejected opportunities() (rc=" _rc ")"
capture noisily nwdynam coordsmall, submodel(choice_coordination) weightedindeg
assert _rc == 198
di as text "  correctly rejected weightedindeg (rc=" _rc ")"
capture noisily nwdynam coordsmall, submodel(choice_coordination) indegwindow(3)
assert _rc == 198
di as text "  correctly rejected indegwindow() (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: tie() (cross-network effects, v1 scope, 2026-09-02) - goldfish's"
di as text "own tie(network) effect, reading presence in a SEPARATE, STATIC"
di as text "exogenous network. Real cross-tool correctness check against goldfish"
di as text "is dev/dynam_unit18_tie_crosscheck.do (direct Mata) and dev/dynam_"
di as text "unit18b_tie_ado_crosscheck.do (through this same .ado command) - this"
di as text "block only certifies the .ado wrapper's own option handling and"
di as text "failure paths."
di as text "{hline 60}"
clear
input long sender long receiver long eventtime
1 2 1
2 3 2
3 4 3
4 5 4
5 1 5
1 3 6
2 4 7
3 5 8
4 1 9
5 2 10
end
nwset sender receiver, eventtime(eventtime) name(tiesmall)
nwset, mat((0,1,1,0,1\1,0,0,1,0\1,0,0,0,1\0,1,0,0,1\1,0,1,1,0)) name(statsmall) directed labs(A1,A2,A3,A4,A5)

nwdynam tiesmall, submodel(choice) tie(statsmall)
di as text "  fits successfully with tie(statsmall)"

di as text "Test: tie() rejected under submodel(rate)"
capture noisily nwdynam tiesmall, submodel(rate) tie(statsmall)
assert _rc == 198
di as text "  correctly rejected (rc=" _rc ")"

di as text "Test: tie() fits under submodel(choice_coordination) (batch 16, 2026-09-02)"
nwdynam coordsmall, submodel(choice_coordination) tie(statsmall)
di as text "  fits successfully with tie(statsmall)"

di as text "Test: tie() with a mismatched actor count rejected"
nwrandom 4, prob(.3) name(tiny4)
capture noisily nwdynam tiesmall, submodel(choice) tie(tiny4)
assert _rc == 198
di as text "  correctly rejected (rc=" _rc ")"

di as text "Test: tie() with an event-type (temporal) network rejected"
capture noisily nwdynam tiesmall, submodel(choice) tie(tiesmall)
assert _rc == 198
di as text "  correctly rejected (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: intercept (WITH-INTERCEPT rate sub-model, batch 17, 2026-09-02) -"
di as text "goldfish's own genuinely continuous-time competing-risks hazard"
di as text "variant. Real cross-tool correctness check against goldfish is dev/"
di as text "dynam_unit20_rateintercept_crosscheck.do (direct Mata) and dev/"
di as text "dynam_unit20b_rateintercept_ado_crosscheck.do (through this same"
di as text ".ado command) - this block only certifies the .ado wrapper's own"
di as text "option handling and failure paths."
di as text "{hline 60}"
nwdynam tiesmall, submodel(rate) intercept indeg
di as text "  fits successfully with intercept + indeg, e(effects)=`e(effects)'"
assert "`e(effects)'" == "Intercept indeg"

di as text "Test: intercept rejected under submodel(choice)"
capture noisily nwdynam tiesmall, submodel(choice) intercept
assert _rc == 198
di as text "  correctly rejected (rc=" _rc ")"

di as text "Test: intercept rejected under submodel(choice_coordination)"
capture noisily nwdynam coordsmall, submodel(choice_coordination) intercept
assert _rc == 198
di as text "  correctly rejected (rc=" _rc ")"

di as text "Test: intercept rejected combined with indegwindow()/outdegwindow()"
capture noisily nwdynam tiesmall, submodel(rate) intercept indegwindow(3)
assert _rc == 198
di as text "  correctly rejected indegwindow() (rc=" _rc ")"
capture noisily nwdynam tiesmall, submodel(rate) intercept outdegwindow(3)
assert _rc == 198
di as text "  correctly rejected outdegwindow() (rc=" _rc ")"

di as text "Test: intercept rejected combined with weightedindeg/weightedoutdeg"
capture noisily nwdynam tiesmall, submodel(rate) intercept weightedindeg
assert _rc == 198
di as text "  correctly rejected weightedindeg (rc=" _rc ")"
capture noisily nwdynam tiesmall, submodel(rate) intercept weightedoutdeg
assert _rc == 198
di as text "  correctly rejected weightedoutdeg (rc=" _rc ")"

di as text "{hline 60}"
di as result "ALL TESTS PASSED"
