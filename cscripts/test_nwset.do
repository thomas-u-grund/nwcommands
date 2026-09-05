cscript

clear mata
do unw_core.do
set more off

* An explicit name() collision now errors instead of silently
* auto-numbering to a different name (harmonisation unit: the
* overwrite/replace fix) - this used to certify the auto-numbering
* itself as correct, which is exactly the silently-diverging behavior
* that fix replaced. replace() is the way to get an intentional
* same-name replacement now.
nwclear
nwset, mat(J(4,4,2)) name("second")
capture nwset, mat(J(6,6,2)) name("second")
assert _rc == 483  // errNWsExists - consolidated from the old ad-hoc 6099 during the error-code coherence pass
nwset
assert `"`r(nets)'"' == `" second"'
assert         r(networks) == 1

nwset, mat(J(6,6,2)) name("second") replace
nwset
assert `"`r(nets)'"' == `" second"'
assert         r(networks) == 1
nwsummarize second
assert r(nodes) == 6

nwclear
set obs 4
gen v1 = 0
gen v2 = (_n == 3)
gen v3 = (_n < 3)
gen v4 = 0
gen v5 = (_n < 3)

nwset v*, name(netfromvar)
nwset
assert `"`r(nets)'"'  == " netfromvar"
assert `"`r(networks)'"' == `"1"'

nwclear
nwset, mat(J(4,4,1)) labs(a,b)
mata: st_local("lab1", nw.nws.pdefs[1]->nodes[1])
assert "`lab1'" == "a"

nwclear
nwset, mat(J(4,4,1)) labs(a,b,c,d,e,f,g,h)
mata: st_local("lab1", nw.nws.pdefs[1]->nodes[1])
assert "`lab1'" == "a"

nwclear
nwset, mat(J(4,4,1)) labs(a,a)
mata: st_local("lab1", nw.nws.pdefs[1]->nodes[1])
rcof `"assert "`lab1'" == "a""' != 0

nwclear
set obs 4
gen v1 = 0
gen v2 = (_n == 3)
gen v3 = (_n < 3)
gen v4 = 0
gen v5 = (_n < 3)
gen nodelab = "mynode" + string(_n)

nwset v*, labsfromvar(nodelab)
mata: st_local("lab1", nw.nws.pdefs[1]->nodes[1])
assert "`lab1'" == "mynode1"

nwclear
set obs 4
gen v1 = 0
gen v2 = (_n == 3)
gen v3 = (_n < 3)
gen v4 = 0
gen v5 = (_n < 3)
gen nodelab = "mynode" + string(_n)

nwset v*, labsfromvar(nodelab) bipartite
mata: st_local("lab1", nw.nws.pdefs[1]->nodes[6])
assert "`lab1'" == "mynode1"

nwclear
nwset, mat(J(4,4,2)) name("second")
mata: st_numscalar("val", strtoreal(nw.nws.pdefs[1]->get_edgelist(0)[1,3]))
assert val == .

nwclear
nwset, mat(J(4,4,2)) name("second") selfloop
mata: st_numscalar("val", strtoreal(nw.nws.pdefs[1]->get_edgelist(0)[1,3]))
assert val == 2

nwclear
nwset, mat(J(4,4,2)) name("second") bipartite
mata: st_numscalar("val1", strtoreal(nw.nws.pdefs[1]->get_edgelist(0)[2,3]))
assert val1 == .
mata: st_numscalar("val2", strtoreal(nw.nws.pdefs[1]->get_edgelist(0)[5,3]))
assert val2 == 2

* vars() lets a caller explicitly name the Stata variables nwload will
* materialize this network into, overriding the auto-derived-from-node-
* names default - documented since at least this file's own doc header,
* but the option itself had been silently dropped from the syntax line
* at some point (found while fixing nwlattice.ado, which depends on it -
* "option vars() not allowed" on every call). Confirms both that the
* option is accepted again and that nwload actually produces variables
* under the requested names, not just that no error is thrown.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(mynet) vars(myvar1 myvar2 myvar3)
nwload
foreach v in myvar1 myvar2 myvar3 {
	capture confirm variable `v'
	assert _rc == 0
}
capture confirm variable n1
assert _rc != 0

* wrong count must error cleanly, not silently truncate/pad
nwclear
capture nwset, mat((0,1,1\1,0,1\1,1,0)) name(mynet) vars(myvar1 myvar2)
assert _rc != 0

* `nwset, clear' was completely broken - it called `nwdrop _all,
* netonly', an option nwdrop.ado has never actually accepted -
* meaning every single call errored ("option netonly not allowed").
* Found while investigating a separate, related bug (see below).
nwclear
nwset, mat((0,1\1,0)) name(clearme)
nwset, clear
assert _rc == 0
nwset, detail
assert r(networks) == 0
capture confirm variable _nwnode
assert _rc == 0

* clear/nwclear used to `exit' unconditionally, even when the same
* call also carried a creation request - silently dropping the
* creation instead of running it (nwset never reported an error, so
* the only symptom was the never-created network not existing later).
* mat()-based creation (unlike edgelist/twomode, which need the
* current dataset's own columns to survive - nwclear wipes those too,
* so combining them is inherently incoherent, not fixed by this) now
* works correctly combined with either clear or nwclear.
nwclear
nwset, mat((0,1\1,0)) name(x)
nwset, mat((0,1,1\1,0,1\1,1,0)) name(y) nwclear
assert _rc == 0
nwset, detail
assert r(networks) == 1
assert `"`r(nets)'"' == `" y"'
nwsummarize y
assert r(nodes) == 3

* the `overwrite' option was declared in the syntax line but never
* actually wired to anything - a name collision on an EXPLICITLY
* requested name() always silently auto-picked a different valid name
* via nw_validate and warned, regardless of whether overwrite/replace
* was given, leaving the caller's own "foo" silently untouched (a
* silent-destructive-operation trap in the other direction: later
* references to "foo" kept hitting stale data). An explicit name()
* collision without replace now errors instead, matching
* nwgenerate's own create/replace convention; `replace' (with
* `overwrite' kept as a backward-compatible alias) genuinely replaces
* the existing network under the SAME requested name. An UNSPECIFIED
* name (the anonymous "network"/"network_1"/... default) keeps the
* old auto-numbering behavior unchanged, since the caller expressed
* no intent about a specific name there.
nwclear
nwset, mat((0,1\1,0)) name(foo)
capture nwset, mat((0,1,1\1,0,1\1,1,0)) name(foo)
assert _rc == 483  // errNWsExists - consolidated from the old ad-hoc 6099 during the error-code coherence pass
nwsummarize foo
assert r(nodes) == 2
nwset, detail
assert r(networks) == 1

nwclear
nwset, mat((0,1\1,0))
nwset, mat((0,1,1\1,0,1\1,1,0))
nwset, detail
assert r(networks) == 2
assert `"`r(nets)'"' == `" network network_1"'

nwclear
nwset, mat((0,1\1,0)) name(foo)
nwset, mat((0,1,1\1,0,1\1,1,0)) name(foo) replace
assert _rc == 0
nwset, detail
assert r(networks) == 1
nwsummarize foo
assert r(nodes) == 3

* overwrite alias behaves identically to replace
nwclear
nwset, mat((0,1\1,0)) name(foo)
nwset, mat((0,1,1,1\1,0,1,0\1,1,0,1\1,0,1,0)) name(foo) overwrite
assert _rc == 0
nwset, detail
assert r(networks) == 1
nwsummarize foo
assert r(nodes) == 4

* replacing one network must not disturb a different, separately
* named network - and must correctly rebuild the shared network
* registry even when the network being replaced was the only one
* registered (nwdrop itself drops the whole registry object once the
* last network in it is gone, confirmed directly - the replace path
* has to rebuild it before creating the replacement).
nwclear
nwset, mat((0,1\1,0)) name(foo)
nwset, mat((0,1\1,0)) name(bar)
nwset, mat((0,1,1\1,0,1\1,1,0)) name(foo) replace
assert _rc == 0
nwset, detail
assert r(networks) == 2
assert `"`r(nets)'"' == `" bar foo"'
nwsummarize bar
assert r(nodes) == 2
nwsummarize foo
assert r(nodes) == 3

* _nwsyntax (called by nearly every command in this package to resolve
* a network name) raised a raw Mata "type mismatch: exp.exp:
* transmorphic found where struct expected" (r(3000)) instead of its
* own documented, clean "Network X not found" (errNWsNotFound) when NO
* network had ever been created this session - a missing `capture' on
* its own lookup line meant an uncaptured Mata error aborted before
* the surrounding "not found" fallback could run. Not a corner case:
* this fires for literally the first invalid network reference in any
* fresh session, and was what made the nwset/nwclear silent-no-op bug
* above look like memory corruption rather than a clean not-found
* error when something later referenced the never-created network.
nwclear
capture _nwsyntax nonexistent_network_xyz
assert _rc == 482

* mat() has always evaluated its own argument as a bare Mata
* expression - a literal expression parses directly as an anonymous
* Mata matrix constant regardless, and a bare MATA variable name works
* too (Mata variables are themselves valid bare expressions), but a
* bare NAME referring to an existing STATA matrix does not auto-import
* into Mata (confirmed directly: "X not found", r(3499), before this
* fix) - found while auditing the Pending list for other nwset.ado
* gaps, not user-reported this time. Fixed by detecting an existing
* Stata matrix name via `confirm matrix' and copying it into Mata
* explicitly via st_matrix() first.
nwclear
matrix define X = (0,1,1\1,0,1\1,1,0)
nwset, mat(X) name(netX)
assert _rc == 0
nwsummarize netX
assert r(nodes) == 3
nwtomata netX, mat(Xcheck)
mata: assert(max(abs(Xcheck :- (0,1,1\1,0,1\1,1,0))) < 1e-8)

* literal expression and bare Mata variable name must keep working
* exactly as before (not broken by the new Stata-matrix-name path).
nwclear
nwset, mat((0,1\1,0)) name(netLit)
assert _rc == 0
nwsummarize netLit
assert r(nodes) == 2

nwclear
mata: __nwset_test_var = (0,1,0\1,0,1\0,1,0)
nwset, mat(__nwset_test_var) name(netMata)
assert _rc == 0
nwsummarize netMata
assert r(nodes) == 3
mata: mata drop __nwset_test_var

* --- two-mode + temporal composability (two-mode/temporal architecture
* initiative): `twomode' combined with `time()'/`interval()'/
* `eventtime()' in the same nwset call - previously an unconditional,
* explicit error ("not yet supported... use nwattime once composability
* lands"). A real bug found while building this (not caught by
* inspection): nw2fromedge's own internal nwfromedge delegation
* REPLACES the current dataset, so the mode-1/mode-2/time variables no
* longer exist in the calling dataset by the time this code tried to
* read them back - confirmed directly ("person not found" on the first
* end-to-end trial). Fixed by capturing every row-level value into Mata
* BEFORE calling nw2fromedge, replicating its own two collision-
* handling rules (numeric-range offset; string-overlap "m1_"/"m2_"
* prefix) on that captured copy.
nwclear
clear
input str10 person str10 org time
"A" "X" 1
"B" "X" 1
"A" "Y" 2
"C" "Y" 2
end
nwset person org, twomode time(time) name(tm1)
_nwsyntax tm1
mata: st_numscalar("__tm1_is2mode", `netobj'->is_2mode_boolean())
mata: st_numscalar("__tm1_istemporal", `netobj'->is_temporal_boolean())
assert __tm1_is2mode == 1
assert __tm1_istemporal == 1
scalar drop __tm1_is2mode __tm1_istemporal

* numeric ids on both modes with OVERLAPPING ranges - exercises
* nw2fromedge's own numeric-offset collision handling; confirms label
* resolution correctly follows the offset values (4 distinct nodes,
* not 3 - "id 1" of each mode must not collide).
nwclear
clear
input person org time
1 1 5
2 1 5
1 2 6
end
nwset person org, twomode time(time) name(tm2)
_nwsyntax tm2
mata: st_numscalar("__tm2_nodes", `netobj'->get_nodes())
assert __tm2_nodes == 4
scalar drop __tm2_nodes

* eventtime() two-mode.
nwclear
clear
input str10 person str10 org evt
"A" "X" 100
"B" "X" 105
"A" "Y" 110
end
nwset person org, twomode eventtime(evt) name(tm3)
_nwsyntax tm3
mata: st_numscalar("__tm3_istemporal", `netobj'->is_temporal_boolean())
assert __tm3_istemporal == 1
scalar drop __tm3_istemporal

* bipartite + temporal remains explicitly, cleanly unsupported (its own
* wide-affiliation-matrix shape has no natural per-row time value) -
* deliberately NOT composable, unlike twomode above.
nwclear
clear
input x1 x2
1 0
0 1
end
capture nwset x1 x2, bipartite time(x1) name(tmbad)
assert _rc == 198

* plain twomode (no temporal option) is completely unchanged.
nwclear
clear
input str10 person str10 org
"A" "X"
"B" "X"
end
nwset person org, twomode name(tmplain)
_nwsyntax tmplain
mata: st_numscalar("__tmplain_istemporal", `netobj'->is_temporal_boolean())
assert __tmplain_istemporal == 0
scalar drop __tmplain_istemporal

di "=== nwset twomode + temporal composability REGRESSION VERIFIED ==="

* --- BUGFIX regression (adversarial-input pressure test): mat() with a
* non-square matrix for a plain (non-bipartite) one-mode network used
* to crash uncleanly two different ways - check_bipartite()'s own
* non-bipartite branch silently truncates to the smaller-dimension
* square submatrix with no warning, then a modes-vector sizing
* mismatch (sized off the truncated matrix, indexed via the ORIGINAL
* untruncated one) indexed out of bounds and crashed with a raw
* "subscript invalid" (r3301). An empty (0x0) matrix hit an identical
* crash one function earlier. Both now rejected cleanly.
nwclear
capture noisily nwset, mat((1,2,3\4,5,6))
assert _rc == 198
capture noisily nwset, mat(J(0,0,0))
assert _rc == 198
nwset, mat((0,1,1\1,0,1\1,1,0)) name(stillworks)
assert _rc == 0
di "=== nwset mat() non-square/empty-matrix REGRESSION VERIFIED ==="
