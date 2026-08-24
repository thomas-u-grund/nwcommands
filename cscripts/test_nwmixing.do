cscript

do unw_core.do

* nwmixing had zero test coverage and was completely non-functional -
* found while investigating a Pending item flagged (not fixed) during
* harmonisation unit 103's own benchmark setup validation. Two
* independent bugs, both root-caused here:
*
* (1) nwmixing.ado referenced `attribute'_nwego/`attribute'_nwalter,
* but nwtoedge.ado's own egovars()/altervars() option materializes
* `attribute'_ego/`attribute'_alter (confirmed directly from
* nwtoedge.ado's own rename logic: it concatenates the attribute name
* with the ego()/alter() option's own default value, "_ego"/"_alter"
* per unw_defs.ado - never "_nwego"/"_nwalter"). A pure naming
* mismatch - nwmixing could never have found the variables it needed.
*
* (2) Once past that, a second, independent crash: rep_EIvar() (this
* file's own permutation-test helper) is declared to take a `real
* matrix' as its network argument, but was called with
* `netobj'->get_matrix() - a POINTER to a matrix, never dereferenced.
* Fixed by dereferencing it (*`netobj'->get_matrix()). Also removed
* two leftover bare `net1'/`attr' statements inside rep_EIvar() itself
* - harmless without unit 109's own bug class (Mata auto-displays any
* uncaptured top-level expression) but clearly forgotten debug output,
* not intentional.

nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(net1) undirected
gen x = _n
nwload
nwmixing net1, attribute(x) permutations(50)
assert _rc == 0
assert r(EI_index) != .
assert r(EI_pvalue) != .

* directed network
nwclear
nwset, mat((0,1,1,0\1,0,0,1\1,0,0,1\0,1,1,0)) name(net2) directed
gen y = mod(_n,2)
nwload
nwmixing net2, attribute(y) permutations(50)
assert _rc == 0
assert r(EI_index) != .

* valued network
nwclear
nwset, mat((0,2,0,3\2,0,1,0\0,1,0,1\3,0,1,0)) name(net3) undirected
gen z = _n
nwload
nwmixing net3, attribute(z) permutations(50)
assert _rc == 0
assert r(EI_index) != .

* string (categorical) attribute, via label-encoding path
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(net4) undirected
gen w = cond(mod(_n,2)==0, "red", "blue")
nwload
nwmixing net4, attribute(w) permutations(50)
assert _rc == 0
assert r(EI_index) != .
