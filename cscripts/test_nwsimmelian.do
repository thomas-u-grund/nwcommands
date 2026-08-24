cscript

do unw_core.do

nwwebuse florentine, nwclear
nwsimmelian flomarriage, name(simmel)
nwload simmel
assert peruzzi[15] == 1
assert pazzi[14] == 0

* moderate-severity pass, cohesion_subgroups group: this test file was
* far thinner than every sibling's own test file - extended to cover
* the nwreplace collision guard, a directed non-reciprocated tie, and
* the strength-blindness gap documented in nwsimmelian.sthlp's own
* Supported network types section.

* --- nwreplace collision guard: default name (_simmelian) collision.
nwclear
nwrandom 3, prob(1) name(dupnet)
nwset, mat((0,1\1,0)) name(_simmelian)
capture noisily nwsimmelian dupnet
assert _rc == 483
nwsimmelian dupnet, nwreplace
assert _rc == 0
di "=== nwreplace collision guard REGRESSION VERIFIED ==="

* --- directed network: a non-reciprocated tie (A->B, no B->A) must NOT
* be flagged as Simmelian, since reciprocity is required.
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) directed labs(A,B,C) name(dirnet)
nwsimmelian dirnet, name(simdir)
nwtomata simdir, mat(Md)
mata: assert(Md[1,2] == 0)
di "=== directed non-reciprocated REGRESSION VERIFIED ==="

* --- strength-blindness: a weak reciprocated tie (value 1) in a closed
* triad is flagged identically to a strong one (value 5) - documented,
* deliberate behavior (this command implements the reciprocated-triad
* structure only, no tie-strength threshold), pinned down as a
* regression so a future change to this is a conscious decision, not
* an accident.
nwclear
nwset, mat((0,1,5\1,0,5\5,5,0)) undirected labs(A,B,C) name(mixedtri)
nwsimmelian mixedtri, name(simmix)
nwtomata simmix, mat(Mm)
mata: assert(Mm[1,2] == 1)
di "=== strength-blindness (documented behavior) REGRESSION VERIFIED ==="


