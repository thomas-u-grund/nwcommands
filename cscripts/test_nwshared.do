cscript

do unw_core.do

nwwebuse florentine, nwclear
nwshared flomarriage, name(shared)
nwload shared
assert peruzzi[15] == 2
assert pazzi[14] == 0



* --- alpha-audit regression: `undirected' was documented but never
* declared in the syntax line (rejected outright), and its own body
* passed nwsym's output-name option as name() instead of the real
* generate() - both fixed.
nwclear
nwset, mat((0,1,0,1\0,0,1,0\0,0,0,1\1,0,0,0)) name(dnet2) directed
capture noisily nwshared dnet2, name(sharedundir) undirected
assert _rc == 0
di "=== undirected REGRESSION VERIFIED ==="

* moderate-severity pass, generators_derived group: naming consistency -
* nwreplace was the only collision-override option in this group
* prefixed "nw"; added `replace' as the primary name, kept `nwreplace'
* working as a backward-compatible alias.
nwwebuse florentine, nwclear
nwshared flomarriage, name(shared2)
assert _rc == 0
capture noisily nwshared flomarriage, name(shared2)
assert _rc == 483
nwshared flomarriage, name(shared2) replace
assert _rc == 0
nwshared flomarriage, name(shared2) nwreplace
assert _rc == 0
capture noisily nwshared flomarriage, name(shared2) replace nwreplace
assert _rc == 198
di "=== replace/nwreplace alias REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwshared nonexistent
assert _rc == 482
