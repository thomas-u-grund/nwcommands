cscript

do unw_core.do

* --- Star network: A tied to B,C,D (undirected).
* Hand-computed with alpha=0.5:
*   A: 3 direct neighbors at distance 1 -> 3*0.5 = 1.5
*   B: A at dist 1 (0.5), C at dist 2 via A (0.25), D at dist 2 via A (0.25) -> 1.0
*   (same for C, D by symmetry)
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet) undirected labs(A,B,C,D)

nwkatz starnet, alpha(0.5) generate(mykatz)
assert reldif(mykatz[1], 1.5) < 1E-6
assert reldif(mykatz[2], 1.0) < 1E-6
assert reldif(mykatz[3], 1.0) < 1E-6
assert reldif(mykatz[4], 1.0) < 1E-6


* --- replace guard: must actually error without replace, and actually
* work with replace (regression test for a real bug - `replace' was
* previously absorbed by the trailing `*' catch-all instead of being
* declared as a real option, so it silently never worked at all, and
* the existing-variable guard printed a warning but never stopped
* execution)
capture nwkatz starnet, alpha(0.5) generate(mykatz)
assert _rc == 110

nwkatz starnet, alpha(0.5) generate(mykatz) replace
assert reldif(mykatz[1], 1.5) < 1E-6


* --- directed network: A->B, A->C (out-degree 2 at A, no return paths).
* Hand-computed with alpha=0.5, GENUINELY DIRECTED (nosym - see the
* alpha-audit regression below for the now-correct symmetrized default):
*   out-reach of A: B at dist 1 (0.5), C at dist 1 (0.5) -> 1.0
*   out-reach of B, C: 0 (no outgoing ties)
*   in-reach of A: 0 (nobody points to A)
*   in-reach of B: A points to it at dist 1 -> 0.5
*   in-reach of C: A points to it at dist 1 -> 0.5
* This is also a regression test for a real bug: out/in were swapped
* (out was computed as a column sum - "how reachable am I from
* others" - and in as a row sum - "how far can I reach" - backwards
* relative to this package's own row=source/column=target convention,
* confirmed against get_outdegree()/get_indegree() in unw_core.do).
nwclear
nwset, mat((0,1,1\0,0,0\0,0,0)) name(dirnet) directed labs(A,B,C)

nwkatz dirnet, alpha(0.5) generate(dkatz) nosym
assert reldif(dkatz_out[1], 1.0) < 1E-6
assert dkatz_out[2] == 0
assert dkatz_out[3] == 0
assert dkatz_in[1] == 0
assert reldif(dkatz_in[2], 0.5) < 1E-6
assert reldif(dkatz_in[3], 0.5) < 1E-6

* --- alpha-audit regression: nwkatz's own .sthlp documents "the
* network is otherwise symmetrized for the underlying distance
* calculation unless geodesic_options specifies nosym" - but neither
* `nosym' nor `sym' was ever declared in nwkatz's own syntax line, so
* an explicit `nosym' (forwarded via the trailing `*' catch-all) was a
* no-op against nwgeodesic's own opt-in `sym' toggle (already off by
* default), and the DEFAULT (no nosym at all) never actually
* symmetrized despite the printed "Network has been symmetrized for
* calculation." message unconditionally claiming otherwise. Hand-
* computed with alpha=0.5 on the SAME A->B,A->C network, now genuinely
* symmetrized to an undirected star A-B,A-C:
*   A: 2 neighbors at distance 1 -> 2*0.5 = 1.0
*   B: A at dist 1 (0.5), C at dist 2 via A (0.25) -> 0.75
*   C: symmetric to B -> 0.75
* in/out must be identical to each other once genuinely symmetrized.
nwclear
nwset, mat((0,1,1\0,0,0\0,0,0)) name(dirnet3) directed labs(A,B,C)
nwkatz dirnet3, alpha(0.5) generate(dkatz3)
assert reldif(dkatz3_in[1], 1.0) < 1E-6
assert reldif(dkatz3_in[2], 0.75) < 1E-6
assert reldif(dkatz3_in[3], 0.75) < 1E-6
assert dkatz3_in[1] == dkatz3_out[1]
assert dkatz3_in[2] == dkatz3_out[2]
di "=== nosym/default symmetrization REGRESSION VERIFIED ==="


* --- geodesic_options passthrough: nwgeodesic's own unconnected()
* option should be forwardable (documented in nwkatz's .sthlp synopsis
* as "geodesic_options" but never actually forwarded to the internal
* nwgeodesic call before this fix - `options' was captured by the
* trailing `*' but never appended to that call)
nwclear
nwset, mat((0,1,1\0,0,0\0,0,0)) name(dirnet2) directed labs(A,B,C)
nwkatz dirnet2, alpha(0.5) generate(dkatz2) unconnected(99)
assert _rc == 0


* --- invalid geodesic_options still error cleanly (confirms the
* passthrough is real, not just silently swallowed)
capture nwkatz dirnet2, alpha(0.5) generate(dkatz3) bogusoption123
assert _rc != 0
