cscript

do unw_core.do

* nwturnover, formation (3.20.1). Directed hand case: wave1 1->2, 2->3; wave2 adds 2->1 (returns
* 1->2), 1->3 (closes 1->2->3) and 3->1 (neither). Formed 3: returning 1/3, closing 1/3. Pairs
* without a tie in wave1: (1,3) (2,1) (3,1) (3,2); returning (2,1) (3,2) = 2/4; closing (1,3) = 1/4.
nwclear
nwset, mat((0,1,0\0,0,1\0,0,0)) name(w1)
nwset, mat((0,1,1\1,0,1\1,0,0)) name(w2)
nwturnover w1 w2, generate(_t) formation
assert r(formed) == 3
assert r(absent) == 4
assert reldif(r(formed_recip), 1/3) < 1e-8
assert reldif(r(formed_closure), 1/3) < 1e-8
assert reldif(r(absent_recip), 2/4) < 1e-8
assert reldif(r(absent_closure), 1/4) < 1e-8

* without the option: the same counts, and no formation results
nwturnover w1 w2, generate(_t) replace
assert r(formed) == 3 & r(stable) == 2 & r(dissolved) == 0
assert r(absent) == .
assert r(formed_recip) == .

* undirected: pairs counted once, no returned ties. wave1 1-2, 2-3; wave2 adds 1-3 (closes 1-2-3)
nwset, mat((0,1,0\1,0,1\0,1,0)) undirected name(u1)
nwset, mat((0,1,1\1,0,1\1,1,0)) undirected name(u2)
nwturnover u1 u2, generate(_t) replace formation
assert r(absent) == 1
assert r(formed_closure) == 1 & r(absent_closure) == 1
assert r(formed_recip) == .

* silent still returns the results
nwturnover w1 w2, generate(_t) replace formation silent
assert r(absent) == 4

* two-mode networks are refused
nwclear
nw2set, mat((0,1\1,1)) name(t1)
nw2set, mat((1,1\1,0)) name(t2)
capture nwturnover t1 t2, generate(_t) replace formation
assert _rc == 198
di "test_nwturnover_formation: all passed"
