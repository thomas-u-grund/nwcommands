cscript

do unw_core.do

* nwbalance, reps(): random signs on the observed ties (3.20.1)

* all ties positive: every draw is all positive, so every draw is fully balanced
nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(pos) undirected
nwbalance pos, reps(50) seed(1)
assert r(closed_triad) == 4
assert r(balance) == 1
assert r(p_positive) == 1
assert r(null_mean) == 1
assert r(null_sd) == 0
assert r(null_ge) == 50
assert r(null_expected) == 1

* all ties negative in a triangle: never balanced
nwset, mat((0,-1,-1\-1,0,-1\-1,-1,0)) name(neg) undirected
nwbalance neg, reps(20) seed(1)
assert r(balance) == 0
assert r(p_positive) == 0
assert r(null_mean) == 0
assert r(null_ge) == 20

* counts unchanged by reps(); without reps() the extra results are not set
nwset, mat((0,1,1,-1\1,0,1,-1\1,1,0,1\-1,-1,1,0)) name(signednet) undirected
nwbalance signednet
assert r(closed_triad) == 4 & r(balanced_triad) == 2
assert r(reps) == .
nwbalance signednet, reps(100) seed(7)
assert r(closed_triad) == 4 & r(balanced_triad) == 2 & r(balance) == 0.5
assert reldif(r(p_positive), 4/6) < 1e-9
assert r(reps) == 100
local m1 = r(null_mean)
nwbalance signednet, reps(100) seed(7)
assert r(null_mean) == `m1'

* tribes: half the ties positive, the mean over many draws is close to the formula
nwwebuse gahuku, nwclear
nwbalance gahuku, reps(2000) seed(12)
assert r(closed_triad) == 68 & r(balanced_triad) == 59
assert reldif(r(p_positive), 0.5) < 1e-9
assert abs(r(null_mean) - r(null_expected)) < 0.01
assert r(null_ge) == 0

* directed: a pair counts as tied in either direction
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(cyc)
nwbalance cyc, reps(10) seed(1)
assert r(closed_triad) == 1 & r(null_mean) == 1

* no closed triads and invalid reps()
nwset, mat(J(3,3,0)) name(empty) undirected
nwbalance empty, reps(10)
rcof "nwbalance empty, reps(-1)" == 198
