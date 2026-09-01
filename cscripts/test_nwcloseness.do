cscript

do unw_core.do

* nwcloseness had zero test coverage before this session, and was
* silently producing WRONG output on every call: it used the
* deprecated _nwsyntax wrapper, whose own re-export line
* ("c_local netname `name'") referenced a local that was never set
* (should have been `netname', the local nw_syntax itself actually
* sets) - so the caller's netname local was always emptied out after
* the call. Because the per-network processing loop is
* "foreach netname_temp in `netname' { ... }", an empty netname meant
* the loop silently ran zero iterations: no error, no output
* variables created, just an empty results table with a blank
* "Network name:" banner. Fixed at the root in _nwsyntax.ado (the
* single c_local line), which also benefits every other remaining
* caller of that shared wrapper.
*
* Fixing the netname bug then exposed a second, previously-masked
* problem: nwcloseness also calls the deprecated _nwsyntax_other for
* the "current node count" - which is itself incompatible with the
* modern network storage architecture (references the legacy
* nw_mata`id' global, which no longer exists), crashing with
* "invalid syntax" the moment the loop actually ran. Fixed by
* replacing _nwsyntax_other with a direct nw_syntax call (the same
* pattern already used to fix nwqap this session).

* --- path-like network A-B-C-D (undirected): hand-computed
* Sabidussi closeness/farness/nearness.
*   farness(A)=1+1+2=4, farness(B)=1+1+2=4, farness(C)=1+1+1=3,
*   farness(D)=2+2+1=5
*   closeness_i = (n-1)/farness_i = 3/farness_i:
*     A=.75, B=.75, C=1, D=.6
*   nearness_i = 1/farness_i: A=.25, B=.25, C=.3333333, D=.2
nwclear
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwcloseness net1
assert reldif(_farness[1], 4) < 1e-6
assert reldif(_farness[2], 4) < 1e-6
assert reldif(_farness[3], 3) < 1e-6
assert reldif(_farness[4], 5) < 1e-6
assert reldif(_closeness[1], .75) < 1e-6
assert reldif(_closeness[3], 1) < 1e-6
assert reldif(_closeness[4], .6) < 1e-6
assert reldif(_nearness[3], 1/3) < 1e-6
assert reldif(_nearness[4], .2) < 1e-6

* --- netlist (multi-network) support: nwcloseness already had a
* real (if numeric-suffix, not netname-suffix) multi-network
* convention ("local k = 1" before the loop, incremented each
* iteration) - it was just unreachable because of the netname bug
* above. 3-node path X-Y-Z as the second network:
*   farness X=1+2=3, Y=1+1=2, Z=2+1=3
*   closeness = (n-1)/farness = 2/farness: X=.6667, Y=1, Z=.6667
nwclear
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwset, mat((0,1,0\1,0,1\0,1,0)) name(net2) undirected labs(X,Y,Z)
nwcloseness net1 net2
confirm variable _closeness1
confirm variable _closeness2
gen __row = _n
sum __row if _nwnode == "A"
assert reldif(_farness1[r(mean)], 4) < 1e-6
sum __row if _nwnode == "Y"
assert reldif(_farness2[r(mean)], 2) < 1e-6
assert reldif(_closeness2[r(mean)], 1) < 1e-6
drop __row

* moderate-severity pass, centrality group: nwcloseness had no replace
* option and no "already exists" guard at all - always silently
* clobbered its output variables. generate() silently fell back to the
* hardcoded defaults unless it contained exactly 3 words.
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) undirected labs(A,B,C) name(net3)
gen _closeness = 999
capture noisily nwcloseness net3
assert _rc == 99
assert _closeness[1] == 999
nwcloseness net3, replace
assert _rc == 0
assert _closeness[1] != 999

nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) undirected labs(A,B,C) name(net4)
capture noisily nwcloseness net4, generate(myclose)
assert _rc == 198
capture confirm variable myclose
assert _rc != 0
di "=== replace guard / generate() validation REGRESSION VERIFIED ==="

* missing_test finding, centrality group: directed-network default
* (symmetrized) vs nosym were never compared - locks in the fix already
* in place (nosym is opt-OUT of the documented default symmetrization,
* not a pure no-op).
nwclear
nwset, mat((0,1,1\0,0,0\0,0,0)) name(startest) directed labs(A,B,C)
nwcloseness startest, generate(c1 f1 n1)
assert reldif(c1[2], .6666667) < 1E-6
nwcloseness startest, generate(c2 f2 n2) nosym replace
assert missing(c2[2])
di "=== directed default-vs-nosym REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwcloseness nonexistent
assert _rc == 482
