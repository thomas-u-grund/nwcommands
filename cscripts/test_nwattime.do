cscript

do unw_core.do

* nwattime turns a temporal network into an ordinary static network -
* the ties active at a given timepoint, per the temporal network's own
* declared semantics (snapshot/interval/event). This is the "temporal
* network -> select edges active at t -> static graph view -> ordinary
* nw algorithm" conceptual model the two-mode/temporal architecture
* initiative asked for: the resulting network is completely ordinary
* and usable with any existing nw* command, not a special new type.

* --- snapshot: exact timepoint match, hand-verifiable directly.
nwclear
clear
input str10 ego str10 alter wave
"A" "B" 1
"B" "C" 2
"A" "C" 3
end
nwset ego alter, time(wave) name(snapnet) undirected

nwattime snapnet, at(1) name(w1)
assert _rc == 0
assert r(ties) == 2
assert r(at) == 1
nwname w1
assert `"`r(temporal)'"' == "false"
nw_syntax w1
mata: e = *(`netobj'->get_matrix_unvalued())
mata: a_id = first_index_match(`netobj'->get_nodenames(), "A")
mata: b_id = first_index_match(`netobj'->get_nodenames(), "B")
mata: c_id = first_index_match(`netobj'->get_nodenames(), "C")
mata: assert(e[a_id,b_id] == 1)
mata: assert(e[a_id,c_id] == 0)
mata: assert(e[b_id,c_id] == 0)

* the static view is a completely ordinary network - runs through an
* unrelated, unmodified command with zero special-casing.
nwdegree w1
assert _rc == 0

* an out-of-range timepoint produces an empty (but valid) network, not
* an error - a legitimate "nothing was active at this time" answer.
nwattime snapnet, at(99) name(wnone)
assert _rc == 0
assert r(ties) == 0

* --- provenance recorded on the resulting static view, and the
* SOURCE network's own name/type are shown correctly - not the new
* view's own name (a real bug found and fixed while building this:
* the second internal nw_syntax call overwrites the `netname' local
* nwattime.ado's own display/provenance code would otherwise read).
nwattime snapnet, at(2) name(provcheck)
nwname provcheck
assert strpos(`"`r(provenance)'"', "snapnet") > 0
assert strpos(`"`r(provenance)'"', "snapshot") > 0

* --- interval: documented convention start<=t<end, boundary cases
* checked exactly (start==t included, end==t excluded), plus an
* open-ended (missing end) tie confirmed still active far in the
* future.
nwclear
clear
input str10 ego str10 alter startw endw
"A" "B" 1 3
"B" "C" 2 .
end
nwset ego alter, interval(startw endw) name(ivnet) undirected

* t=1: A-B's own start==t is included (start<=t), B-C not yet started.
* r(ties) counts directed triplet rows (matching nw2project's own
* r(ties) convention) - one true undirected tie is 2 rows (both
* directions), not 1.
nwattime ivnet, at(1) name(ivt1)
assert r(ties) == 2
nw_syntax ivt1
mata: e = *(`netobj'->get_matrix_unvalued())
mata: a_id = first_index_match(`netobj'->get_nodenames(), "A")
mata: b_id = first_index_match(`netobj'->get_nodenames(), "B")
mata: c_id = first_index_match(`netobj'->get_nodenames(), "C")
mata: assert(e[a_id,b_id] == 1)
mata: assert(e[b_id,c_id] == 0)

* t=3: A-B's own end==t is EXCLUDED (t<end, not <=), B-C (open-ended)
* is active
nwattime ivnet, at(3) name(ivt3)
assert r(ties) == 2
nw_syntax ivt3
mata: e = *(`netobj'->get_matrix_unvalued())
mata: assert(e[first_index_match(`netobj'->get_nodenames(),"A"), first_index_match(`netobj'->get_nodenames(),"B")] == 0)
mata: assert(e[first_index_match(`netobj'->get_nodenames(),"B"), first_index_match(`netobj'->get_nodenames(),"C")] == 1)

* t=1000: A-B long over, B-C (missing end = open-ended) still active
nwattime ivnet, at(1000) name(ivfar)
assert r(ties) == 2
nw_syntax ivfar
mata: e = *(`netobj'->get_matrix_unvalued())
mata: assert(e[first_index_match(`netobj'->get_nodenames(),"B"), first_index_match(`netobj'->get_nodenames(),"C")] == 1)

* --- event: exact-timestamp match; two events at the same instant
* between the same pair collapse to one static tie, not a duplicate-
* edge corruption of the resulting network.
nwclear
clear
input str10 sender str10 receiver evtime
"A" "B" 1.5
"A" "B" 1.5
"B" "C" 3.1
end
nwset sender receiver, eventtime(evtime) name(evnet)
nwattime evnet, at(1.5) name(evview)
assert _rc == 0
assert r(ties) == 1
nw_syntax evview
assert `"`directed'"' == "true"
mata: e = *(`netobj'->get_matrix_unvalued())
mata: assert(e[first_index_match(`netobj'->get_nodenames(),"A"), first_index_match(`netobj'->get_nodenames(),"B")] == 1)

* an instant with no matching events at all - empty, not an error.
nwattime evnet, at(999) name(evnone)
assert r(ties) == 0

* --- regression guard: an ordinary (non-temporal) network is rejected
* with a clear error, not silently accepted or crashing.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(onemode) undirected labs(A,B,C)
capture noisily nwattime onemode, at(1)
assert _rc != 0

* --- failure paths: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482); at() is a
* required option (rejected by Stata's own syntax parser without it).
capture noisily nwattime nonexistent, at(1)
assert _rc == 482

capture noisily nwattime onemode
assert _rc != 0
