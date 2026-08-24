cscript

do unw_core.do

nwclear
set obs 10
gen x = 1
nwexpand x

nwsummarize
assert         r(density)       == 1
assert         r(edges_sum)     == 45
assert         r(edges)         == 45
assert         r(maxval)        == 1
assert         r(minval)        == 1
assert         r(missing_edges) == 10
assert         r(selfloops)     == 0
assert         r(nodes)         == 10

nwclear
set obs 10
gen x = _n
nwexpand x, mode(dist) 

nwsummarize
assert         r(density)       == 1
assert         r(arcs_value)    == 0
assert         r(arcs)          == 90
assert         r(maxval)        == 9
assert         r(minval)        == -9
assert         r(missing_edges) == 10
assert         r(selfloops)     == 0
assert         r(nodes)         == 10

nwexpand x, mode(absdist) nodes(3)
nwsummarize
assert         r(density)       == 1
assert         r(edges_sum)     == 4
assert         r(edges)         == 3
assert         r(maxval)        == 2
assert         r(minval)        == 1
assert         r(missing_edges) == 3
assert         r(selfloops)     == 0
assert         r(nodes)         == 3







* --- alpha-audit regression: network() referencing a nonexistent
* network used to crash with a raw, uninformative Mata "subscript
* invalid" instead of a clean "network not found" message. Also
* confirms nwexpand.sthlp's own corrected worked example (network()
* needs the actual per-wave name nwwebuse creates, e.g. glasgow1, not
* the bare dataset name glasgow) works end to end.
nwclear
capture noisily nwwebuse glasgow, nwclear
if _rc == 0 {
	capture noisily nwexpand sport1, mode(sender) network(glasgow1)
	assert _rc == 0
	capture noisily nwexpand sport1, mode(sender) network(glasgow) name(t2)
	assert _rc == 482
	di "=== network() REGRESSION VERIFIED ==="
}
else {
	di "=== network() REGRESSION SKIPPED (no network access to nwwebuse's own host) ==="
}

* --- alpha-audit regression: mode(absdistinv)'s own Mata formula had a
* doubled negation making every value negative, unrelated to what its
* own documentation described (a bounded max-minus-distance inverse,
* not the negative values the buggy code actually produced).
nwclear
set obs 5
gen x = _n
nwexpand x, mode(absdistinv) name(absdinvtest)
mata: __p = nw.nws.pdefs[nw.nws.get_index_of("absdinvtest")]
mata: st_numscalar("__minval", min(select(vec(*__p->get_matrix()), vec(*__p->get_matrix()) :!= .)))
assert __minval >= 0
mata: mata drop __p
di "=== absdistinv non-negativity REGRESSION VERIFIED ==="

* moderate-severity pass, generators_derived group: nodes(1) (a genuine,
* explicit request for a 1-node network) was indistinguishable from
* nodes() left unspecified - both silently expanded to _N observations.
nwclear
set obs 10
gen z = 1
nwexpand z, nodes(1) name(onenode)
nwsummarize onenode
assert r(nodes) == 1
di "=== explicit nodes(1) REGRESSION VERIFIED ==="

* moderate-severity pass: `noreplace' was a dead option and the actual
* collision error told the caller to "specify option replace", which
* nwexpand never exposed at all - replaced with a real, working replace.
nwclear
set obs 10
gen w = 1
nwexpand w, name(dupnet)
assert _rc == 0
capture noisily nwexpand w, name(dupnet)
assert _rc == 483
nwexpand w, name(dupnet) replace
assert _rc == 0
di "=== replace REGRESSION VERIFIED ==="
