cscript

* End-to-end smoke test: nwrem.ado through a REAL nwset ..., eventtime()
* declared network, not RemFitUnit1() called directly on a hand-built
* matrix (that's what cscripts/test_nwrem_mata.do already certifies).
* Matches cscripts/test_nwsaom_ado.do's own role in the nwsaom suite.

do unw_core.do
do unw_ergm.do
do unw_rem.do

nwclear
clear
set obs 400
gen long sender = .
gen long receiver = .
gen eventtime = _n

mata:
mata set matastrict off
rseed(20260828)
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
di as text "Test: nwrem requires eventtime()-declared network, errors on an ordinary one"
di as text "{hline 60}"
nwrandom 8, prob(.3) name(ordinarynet)
capture noisily nwrem ordinarynet, nodsnd nidrec
assert _rc == 198
di as text "  correctly rejected non-event network (rc=" _rc ")"

di as text "{hline 60}"
di as text "Test: nwrem fits successfully on the real eventtime() network"
di as text "{hline 60}"
nwrem chatlog, nodsnd nidrec

assert e(N) == 400
assert e(nodes) == 10
assert !missing(e(ll))
assert rowsof(e(b)) == 1
assert colsof(e(b)) == 2

di as text "{hline 60}"
di as text "e(b): " e(b)[1,1] "  " e(b)[1,2]
di as text "e(ll): " e(ll)
di as text "{hline 60}"

di as text "{hline 60}"
di as text "Test: nwrem covevent() - requires edgelist declaration, rejects a mismatched network,"
di as text "fits successfully on a matching one"
di as text "{hline 60}"

* Deliberately WITHOUT the edgelist option first, confirming this really
* does resolve to a DIFFERENT (wide-matrix) network shape rather than
* erroring outright - found the hard way while writing nwrem.sthlp's own
* covevent() worked example (a same-node-count coincidence let it run
* silently on the wrong data instead of failing loudly). Certified here
* so a future change to nwset's own default-shape behavior cannot
* silently reintroduce the same trap unnoticed.
clear
input i j value
1 2 5
2 1 5
1 3 2
3 1 2
2 3 8
3 2 8
end
nwset i j value, name(seatdist_wrongshape)
nw_syntax seatdist_wrongshape, max(1)
assert `nodes' == 3
mata: st_local("wrongshape_names", invtokens(`netobj'->get_nodenames()))
assert "`wrongshape_names'" == "i j value"
di as text "  confirmed: nwset WITHOUT edgelist on 3 bare variables reads a wide matrix (node names 'i j value'), not an edgelist - covevent() callers must always pass edgelist"

di as text "  mismatched node count is rejected:"
nwrandom 5, prob(.3) name(seatdist_mismatch)
capture noisily nwrem chatlog, nodsnd covevent(seatdist_mismatch)
assert _rc == 198
di as text "  correctly rejected covevent() network with a different actor count (rc=" _rc ")"

* covevent() network must have the SAME actor count as chatlog (10) -
* a symmetric pairwise covariate over all 10 actors, both directions
* given explicitly (nwset does not auto-symmetrize).
clear
set obs 0
gen long i = .
gen long j = .
gen double value = .
mata:
rows_i = J(0,1,0)
rows_j = J(0,1,0)
rows_v = J(0,1,0)
for (a=1; a<=10; a++) {
	for (b=a+1; b<=10; b++) {
		rows_i = (rows_i \ a \ b)
		rows_j = (rows_j \ b \ a)
		rows_v = (rows_v \ (a+b) \ (a+b))
	}
}
st_addobs(rows(rows_i))
st_store(1::rows(rows_i), "i", rows_i)
st_store(1::rows(rows_i), "j", rows_j)
st_store(1::rows(rows_i), "value", rows_v)
end
nwset i j value, name(seatdist10) edgelist

nwrem chatlog, nodsnd covevent(seatdist10)
assert e(N) == 400
assert colsof(e(b)) == 2
di as text "  covevent() fit: " e(b)[1,1] "  " e(b)[1,2]

di as text "{hline 60}"
di as text "Test: nwrem rsndsnd/rrecsnd (recency effects) fit successfully on the real"
di as text "eventtime() network, both together and individually"
di as text "{hline 60}"

nwrem chatlog, nodsnd rsndsnd
assert e(N) == 400
assert colsof(e(b)) == 2
di as text "  rsndsnd fit: " e(b)[1,1] "  " e(b)[1,2]

nwrem chatlog, rrecsnd
assert e(N) == 400
assert colsof(e(b)) == 1
di as text "  rrecsnd fit: " e(b)[1,1]

nwload chatlog, xvars
gen seniority = _n
nwrem chatlog, nodsnd nidrec rsndsnd rrecsnd covsnd(seniority) covevent(seatdist10)
assert e(N) == 400
assert colsof(e(b)) == 6
di as text "  all-families fit (degree+recency+covariates): " colsof(e(b)) " coefficients"

di as text "{hline 60}"
di as text "Test: nwrem requires at least one effect option"
di as text "{hline 60}"
capture noisily nwrem chatlog
assert _rc == 198
di as text "  correctly rejected zero-effect call (rc=" _rc ")"

* Two-mode rejection (nwrem.ado's own explicit guard, see its header
* comment) is NOT exercised here: nwset's own time()/interval()/
* eventtime() options cannot currently be combined with twomode/
* bipartite in the same call (docs/ROADMAP.md's own tracked
* composability gap), so no live network can reach is2mode()=="true"
* while also being an event-type network via the public interface
* today - the same "genuinely unreachable from outside, not a bug"
* situation this project's own nwtab2/nwtab3 dispatch guards are in
* (see cscripts/test_nwtab2.do). Revisit once that composability gap
* closes.

di as text "{hline 60}"
di as result "ALL TESTS PASSED"
