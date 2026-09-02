cscript

* Two-mode (bipartite) DyNAM support (docs/DYNAM_ROADMAP.md's "effect
* expansion" scope, batch 9, resolved 2026-09-02, user: "continue" -
* the two-mode/opportunitiesList/choice_coordination/cross-network/
* WITH-INTERCEPT items flagged as large standalone efforts).
*
* Previously rejected outright by nwdynam.ado; the guard's own stated
* reason (nwset's own twomode/eventtime() composability not yet
* available) was resolved 2026-08-31 - see docs/ROADMAP.md's "Two-mode/
* temporal architecture initiative". This file certifies the .ado
* wrapper's own two-mode option handling and failure paths - the real
* cross-tool correctness check against goldfish's own real numbers
* lives in dev/dynam_unit12_twomode_crosscheck.R/.do (direct Mata
* calls, matching this package's own dev/ crosscheck convention).
*
* SCOPE (verified against real goldfish, not assumed - see
* unw_dynam.do's own header comments for the full account): goldfish's
* own two-mode DyNAM architecture is STRICTLY one-directional (mode 1
* only sends, mode 2 only receives). Effects verified WORKING and
* implemented, with an EXACT numerical match to real goldfish: inertia,
* indeg (choice, alter type), outdeg (rate, ego type). Effects goldfish
* itself hard-rejects for two-mode (mirrored here, not guessed): recip,
* outdeg (choice), commonReceiver, indeg (rate). EVERY attribute effect
* (same/diff/sim/alter/ego/egoalterint/tertius) is ALSO rejected - a
* real limitation found DURING verification, not assumed safe: direct
* comparison against goldfish's own reconstructed statistics showed
* even the simplest attribute effects (same, ego) silently computing
* something different from a naive combined-covariate-vector approach,
* traced to goldfish's own internal two-mode array applying its
* self-tie convention by raw row/column INDEX rather than real actor
* identity - not confidently reverse-engineered in the time available,
* so disclosed as a gap rather than shipped with an unverified formula.
* trans/cycle/commonSender/four/nodeTrans are also excluded (goldfish's
* own doc warns some effects redefine their own formula for two-mode,
* not just restrict the risk set - not independently re-derived).
* Windowed/weighted effects also rejected outright - not yet verified
* together with two-mode.

do unw_core.do
do unw_ergm.do
do unw_dynam.do

* Toy two-mode affiliation network: 6 "people" (mode 1), 4 "orgs"
* (mode 2), 60 events, people always sending to orgs (never the
* reverse) - matching dev/dynam_unit12_twomode_crosscheck.R's own
* dataset exactly (same seed, same construction), so the .do-level
* fits below can be checked against the SAME real-goldfish reference
* numbers documented in that file's own header.
nwclear
clear
import delimited "dev/dynam_crosscheck_twomode_events.csv", clear varnames(1)
encode sender, gen(sendernum)
encode receiver, gen(receivernum)
gen eventtime = time
nwset sendernum receivernum, twomode eventtime(eventtime) name(afftest)

di as text "{hline 60}"
di as text "Test: nwdynam fits successfully on a two-mode event network (choice, default)"
di as text "{hline 60}"
nwdynam afftest
assert colsof(e(b)) == 2
assert "`e(effects)'" == "inertia indeg"
di as text "  default choice(two-mode): " e(b)[1,1] " " e(b)[1,2]
* Real goldfish reference (captured 2026-09-02, goldfish 1.6.12, see
* dev/dynam_unit12_twomode_crosscheck.R): inertia=-0.73342, indeg=0.23018
assert abs(e(b)[1,1] - (-0.73342)) < 0.001
assert abs(e(b)[1,2] - 0.23018) < 0.001

di as text "{hline 60}"
di as text "Test: nwdynam fits successfully on a two-mode event network (rate, default)"
di as text "{hline 60}"
nwdynam afftest, submodel(rate)
assert colsof(e(b)) == 1
assert "`e(effects)'" == "outdeg"
di as text "  default rate(two-mode): " e(b)[1,1]
* Real goldfish reference: outdeg=0.23797
assert abs(e(b)[1,1] - 0.23797) < 0.001

di as text "{hline 60}"
di as text "Test: recip is rejected for two-mode under submodel(choice)"
di as text "{hline 60}"
capture noisily nwdynam afftest, recip
assert _rc == 198
di as text "  correctly rejected recip (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: outdeg is rejected for two-mode under submodel(choice)"
di as text "{hline 60}"
capture noisily nwdynam afftest, outdeg
assert _rc == 198
di as text "  correctly rejected outdeg under submodel(choice) (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: indeg is rejected for two-mode under submodel(rate)"
di as text "{hline 60}"
capture noisily nwdynam afftest, submodel(rate) indeg
assert _rc == 198
di as text "  correctly rejected indeg under submodel(rate) (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: unverified two-mode effects (trans, tertius, nodetrans) are rejected"
di as text "{hline 60}"
capture noisily nwdynam afftest, trans
assert _rc == 198
di as text "  correctly rejected trans (rc=" _rc ")"
capture noisily nwdynam afftest, submodel(rate) nodetrans
assert _rc == 198
di as text "  correctly rejected nodetrans under submodel(rate) (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: windowed and weighted effects are rejected for two-mode"
di as text "{hline 60}"
capture noisily nwdynam afftest, inertia inertiawindow(5)
assert _rc == 198
di as text "  correctly rejected inertiawindow() (rc=" _rc ")"
capture noisily nwdynam afftest, weightedinertia
assert _rc == 198
di as text "  correctly rejected weightedinertia (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: same()/diff()/sim()/alter()/ego()/egoalterint()/tertius() are ALL"
di as text "rejected for two-mode - a real limitation found during verification"
di as text "(goldfish's own internal two-mode representation applies its self-tie"
di as text "convention by raw row/column index, not real actor identity - see"
di as text "unw_dynam.do's own header comment), not silently shipped unverified"
di as text "{hline 60}"

preserve
import delimited "dev/dynam_crosscheck_twomode_actorcov.csv", clear varnames(1)
sort id
assert _N == 10
mata: sharedvec = st_data(1::10, "shared")'
restore

nwload afftest, xvars
mata: st_store(1::10, st_addvar("double", "shared"), sharedvec')

capture noisily nwdynam afftest, same(shared)
assert _rc == 198
di as text "  correctly rejected same() for two-mode (rc=" _rc ")"

capture noisily nwdynam afftest, diff(shared)
assert _rc == 198
di as text "  correctly rejected diff() for two-mode (rc=" _rc ")"

capture noisily nwdynam afftest, alter(shared)
assert _rc == 198
di as text "  correctly rejected alter() for two-mode (rc=" _rc ")"

capture noisily nwdynam afftest, egoalterint(shared shared)
assert _rc == 198
di as text "  correctly rejected egoalterint() for two-mode (rc=" _rc ")"

capture noisily nwdynam afftest, submodel(rate) ego(shared)
assert _rc == 198
di as text "  correctly rejected ego() for two-mode (rc=" _rc ")"

capture noisily nwdynam afftest, submodel(rate) tertius(shared)
assert _rc == 198
di as text "  correctly rejected tertius() for two-mode (rc=" _rc ")"

di as text "{hline 60}"
di as result "ALL TESTS PASSED"
