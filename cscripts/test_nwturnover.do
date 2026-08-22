cscript

do unw_core.do

* nwturnover is a new command implementing tie turnover/stability
* analysis between two waves of the same network (Stage 7's own
* explicit "smaller lift than the confirmed E status suggests" note -
* built entirely on already-existing infrastructure, no new NWdef
* method needed: get_matrix_mod() plus a small, command-local Mata
* comparison, matching nwqap.ado's own established pattern of keeping
* single-purpose Mata helpers local to the .ado file rather than adding
* them to unw_core.do).

* --- hand-computable case: wave1 edges {1-2, 1-3}, wave2 edges
* {1-2, 2-3} (undirected). Stable = {1-2} (1 tie). Formed = {2-3} (in
* wave2 only, 1 tie). Dissolved = {1-3} (in wave1 only, 1 tie).
* Jaccard = 1/(1+1+1) = 1/3. Persistence = 1/(1+1) = 1/2. Per-node
* turnover: node1's own ties are {2,3} at wave1, {2} at wave2 -
* stable=1(to 2), dissolved=1(to 3), rate=1/2; node2's are {1} then
* {1,3} - stable=1, formed=1, rate=1/2; node3's are {1} then {2} -
* dissolved=1, formed=1, stable=0, rate=0.
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) undirected name(wave1)
nwset, mat((0,1,0\1,0,1\0,1,0)) undirected name(wave2)
nwturnover wave1 wave2
assert _rc == 0
assert r(stable) == 1
assert r(formed) == 1
assert r(dissolved) == 1
assert reldif(r(jaccard), 1/3) < 1E-8
assert reldif(r(persistence), .5) < 1E-8
assert reldif(_turnover[1], .5) < 1E-8
assert reldif(_turnover[2], .5) < 1E-8
assert _turnover[3] == 0

* --- directed case: dw1 has A->B, A->C; dw2 has A->B, B->C. Stable =
* A->B (1). Formed = B->C (in dw2 only, 1). Dissolved = A->C (in dw1
* only, 1). Ordered pairs are compared independently - no halving,
* unlike the undirected case above.
nwclear
nwset, mat((0,1,1\0,0,0\0,0,0)) directed name(dw1)
nwset, mat((0,1,0\0,0,1\0,0,0)) directed name(dw2)
nwturnover dw1 dw2, silent
assert _rc == 0
assert r(stable) == 1
assert r(formed) == 1
assert r(dissolved) == 1

* --- identical networks: every tie is stable, nothing formed or
* dissolved - jaccard and persistence both exactly 1.
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) undirected name(same1)
nwset, mat((0,1,1\1,0,0\1,0,0)) undirected name(same2)
nwturnover same1 same2, silent
assert _rc == 0
assert r(formed) == 0
assert r(dissolved) == 0
assert r(jaccard) == 1
assert r(persistence) == 1

* --- net1 with zero ties: persistence is undefined (missing), not
* spuriously 0 or 1 - there is nothing that could have persisted.
nwclear
nwset, mat((0,0,0\0,0,0\0,0,0)) undirected name(empty1)
nwset, mat((0,1,0\1,0,0\0,0,0)) undirected name(empty2)
nwturnover empty1 empty2, silent
assert _rc == 0
assert missing(r(persistence))
assert r(formed) == 1
assert r(dissolved) == 0

* --- mismatched network size is rejected explicitly.
nwclear
nwset, mat((0,1\1,0)) name(small1)
nwset, mat((0,1,1\1,0,0\1,0,0)) name(big1)
capture nwturnover small1 big1
assert _rc != 0

* --- mismatched directedness (one directed, one undirected) is
* rejected explicitly - comparing them would silently mix conventions.
nwclear
nwset, mat((0,1\1,0)) undirected name(u1)
nwset, mat((0,1\0,0)) directed name(d1)
capture nwturnover u1 d1
assert _rc != 0

* --- generate()/replace: a custom name must be honored, and a second
* call without replace must be rejected.
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) undirected name(w1)
nwset, mat((0,1,0\1,0,1\0,1,0)) undirected name(w2)
nwturnover w1 w2, generate(mystab)
assert _rc == 0
capture confirm variable mystab, exact
assert _rc == 0
capture noisily nwturnover w1 w2, generate(mystab)
assert _rc != 0
nwturnover w1 w2, generate(mystab) replace
assert _rc == 0
