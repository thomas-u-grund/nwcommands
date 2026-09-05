cscript

do unw_core.do

* nwset gained time()/interval()/eventtime() options (two-mode/temporal
* architecture initiative, Part II - groundwork only, per the user's
* own explicit scope limit: no full temporal-network modelling
* subsystem, just metadata + per-edge time storage + basic at()
* slicing, the latter tested separately in test_nwattime.do). Three
* semantics distinguished exactly per the user's own specification:
* snapshot (one timepoint per tie), interval (start<=t<end per tie),
* event (timestamped relational events, NOT persistent ties). Per-edge
* time values are resolved by node LABEL, not row/node position -
* nwfromedge's own node numbering sorts the combined label set of both
* edgelist variables together, so a positional assumption would be
* wrong (the exact same lesson unit 41's nw2fromedge mode-assignment
* fix already established for two-mode data).

* --- snapshot: metadata + per-edge time values, hand-verified against
* the raw input data directly.
nwclear
clear
input str10 ego str10 alter wave
"A" "B" 1
"B" "C" 2
"A" "C" 3
end
nwset ego alter, time(wave) name(snapnet) undirected
assert _rc == 0
_nwsyntax snapnet
assert `"`istemporal'"' == "true"
assert `"`temporaltype'"' == "snapshot"
nwname snapnet
assert `"`r(temporal)'"' == "true"
assert `"`r(temporaltype)'"' == "snapshot"
assert `"`r(timevar)'"' == "wave"
mata: et = *(`netobj'->get_edge_time())
mata: ab = et[first_index_match(`netobj'->get_nodenames(), "A"), first_index_match(`netobj'->get_nodenames(), "B")]
mata: bc = et[first_index_match(`netobj'->get_nodenames(), "B"), first_index_match(`netobj'->get_nodenames(), "C")]
mata: ac = et[first_index_match(`netobj'->get_nodenames(), "A"), first_index_match(`netobj'->get_nodenames(), "C")]
mata: assert(ab == 1)
mata: assert(bc == 2)
mata: assert(ac == 3)
* symmetric (undirected): the reverse direction carries the same time
mata: assert(et[first_index_match(`netobj'->get_nodenames(), "B"), first_index_match(`netobj'->get_nodenames(), "A")] == 1)

* --- interval: start/end per-edge values, same label-resolution check.
nwclear
clear
input str10 ego str10 alter startw endw
"A" "B" 1 3
"B" "C" 2 .
end
nwset ego alter, interval(startw endw) name(ivnet) undirected
assert _rc == 0
_nwsyntax ivnet
assert `"`temporaltype'"' == "interval"
nwname ivnet
assert `"`r(startvar)'"' == "startw"
assert `"`r(endvar)'"' == "endw"
mata: es = *(`netobj'->get_edge_start())
mata: ee = *(`netobj'->get_edge_end())
mata: a_id = first_index_match(`netobj'->get_nodenames(), "A")
mata: b_id = first_index_match(`netobj'->get_nodenames(), "B")
mata: c_id = first_index_match(`netobj'->get_nodenames(), "C")
mata: assert(es[a_id,b_id] == 1)
mata: assert(ee[a_id,b_id] == 3)
mata: assert(es[b_id,c_id] == 2)
mata: assert(ee[b_id,c_id] == .)

* --- event: raw sender/receiver/eventtime triplets, NOT folded into
* the ordinary edge matrix (a plain, non-temporal nwdegree-style read
* of this network would be meaningless - the network's own is2mode-
* style edge matrix is a byproduct of nwfromedge's own topology build,
* not the authoritative event record).
nwclear
clear
input str10 sender str10 receiver evtime
"A" "B" 1.5
"A" "B" 2.7
"B" "C" 3.1
end
nwset sender receiver, eventtime(evtime) name(evnet)
assert _rc == 0
_nwsyntax evnet
assert `"`temporaltype'"' == "event"
nwname evnet
assert `"`r(eventtimevar)'"' == "evtime"
mata: ev = *(`netobj'->get_eventlist())
mata: assert(rows(ev) == 3)
* input's default float storage can't represent 1.5/2.7/3.1 exactly -
* an elementwise absolute-difference tolerance, not ==
mata: assert(sum(abs(ev[.,3] :- 1.5) :< 1e-6) == 1)
mata: assert(sum(abs(ev[.,3] :- 2.7) :< 1e-6) == 1)
mata: assert(sum(abs(ev[.,3] :- 3.1) :< 1e-6) == 1)

* --- mutual exclusivity: time/interval/eventtime cannot be combined.
nwclear
clear
input str10 ego str10 alter t1 t2
"A" "B" 1 2
end
capture noisily nwset ego alter, time(t1) interval(t1 t2)
assert _rc != 0

* --- temporal + bipartite (wide affiliation matrix) is rejected with a
* clear, explicit error (nwset.ado's own validation: bipartite's shape
* has no per-row time value to attach) - `twomode' (edgelist shape) is
* the one that DOES support temporal composability, checked separately
* right after. BUGFIX (test-only, found while re-verifying this file
* 2026-09-01): this used to assert `time()+twomode' itself was
* rejected too, but nwset.ado's own current error message for the
* bipartite case explicitly says "Use twomode instead ... two-mode +
* temporal composability is supported there" - confirmed directly
* (`nwset ego alter, time(t1) twomode' now succeeds, `_rc==0', not a
* stale assumption). The assertion below was simply never updated once
* that support was added.
nwclear
clear
input str10 ego str10 alter t1
"A" "B" 1
end
capture noisily nwset ego alter, time(t1) bipartite
assert _rc != 0

capture noisily nwset ego alter, time(t1) twomode
assert _rc == 0
nwset
assert r(networks) > 0

* --- wrong variable count is rejected with a clear error.
nwclear
clear
input str10 ego t
"A" 1
end
capture noisily nwset ego, time(t)
assert _rc != 0

* --- a plain, non-temporal nwset call is completely unaffected - the
* regression guard confirming the new dispatch branch only fires when
* time()/interval()/eventtime() is actually given, and that an
* ordinary network's own `istemporal' correctly defaults to false (not
* a stray Mata missing-value truthy trap - see unw_core.do's own
* is_temporal_boolean() comment for the bug this specifically guards).
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(onemode) undirected labs(A,B,C)
assert _rc == 0
nwname onemode
assert `"`r(temporal)'"' == "false"
_nwsyntax onemode
assert `"`istemporal'"' == "false"
