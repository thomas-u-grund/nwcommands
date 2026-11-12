cscript

do unw_core.do

set graphics off

* --- nwaddnodes: names are separated by commas and may contain spaces
nwclear
nwrandom 3, prob(0) name(t1)
nwaddnodes t1, nodenames(Thomas Grund, Peter)
nwsummarize t1
assert r(nodes) == 5
assert `"`r(labs)'"' == `"n1,n2,n3,Thomas Grund,Peter"'
nwaddnodes t1, nodenames("Anna Maria")
nwsummarize t1
assert r(nodes) == 6
assert `"`r(labs)'"' == `"n1,n2,n3,Thomas Grund,Peter,Anna Maria"'
di "PASS nwaddnodes"

* --- nw2fromedge leaves the id variables unchanged (numeric ids that overlap)
nwclear
clear
input person event
1 1
2 1
3 2
end
tempfile ed
save `ed'
nw2fromedge person event, name(aff)
nwname aff
assert `"`r(mode2)'"' == "true"
assert r(nodes1) == 3
assert r(nodes2) == 2
assert `"`r(mode1desc)'"' == "person"
assert `"`r(mode2desc)'"' == "event"
* an error after the shift (the name exists, no replace) used to leave the shifted ids in the data
use `ed', clear
capture noisily nw2fromedge person event, name(aff)
assert _rc != 0
assert event[1] == 1 & event[3] == 2
assert person[1] == 1 & person[3] == 3
* the if condition is evaluated on the original ids
use `ed', clear
nw2fromedge person event if event == 1, name(aff1)
nwname aff1
assert r(nodes1) == 2
assert r(nodes2) == 1
* string ids that overlap get the prefixes in the node names only
nwclear
clear
input str3 person str3 event
a a
b a
c b
end
tempfile es
save `es'
nw2fromedge person event, name(affs)
nwname affs
assert strpos(`"`r(labs)'"', "m1_a") > 0
assert strpos(`"`r(labs)'"', "m2_a") > 0
use `es', clear
capture noisily nw2fromedge person event, name(affs)
assert _rc != 0
assert person[1] == "a" & event[1] == "a"
di "PASS nw2fromedge"

* --- nwattime keeps the two-mode flag, the modes and the level labels
nwclear
clear
input str10 ego str10 alter t1
"A" "X" 1
"B" "X" 1
"C" "Y" 2
end
nwset ego alter, time(t1) twomode name(tm)
nwname tm
local srcmodes `"`r(modes)'"'
assert `"`r(mode2)'"' == "true"
nwattime tm, at(1) name(s1)
assert r(ties) > 0
nwname s1
assert `"`r(mode2)'"' == "true"
assert `"`r(modes)'"' == `"`srcmodes'"'
assert r(nodes1) == 3
assert r(nodes2) == 2
* the tie values of the slice are the ties at t = 1
_nwsyntax s1
mata: __t_e = *(`netobj'->get_matrix())
mata: __t_n = `netobj'->get_nodenames()
mata: assert(__t_e[selectindex(__t_n :== "A"), selectindex(__t_n :== "X")] == 1)
mata: assert(__t_e[selectindex(__t_n :== "C"), selectindex(__t_n :== "Y")] == 0)
mata: mata drop __t_e __t_n
* a one-mode temporal network stays one-mode
nwclear
clear
input str10 ego str10 alter t1
"A" "B" 1
"B" "C" 2
end
nwset ego alter, time(t1) name(om)
nwattime om, at(1) name(o1)
nwname o1
assert `"`r(mode2)'"' == "false"
di "PASS nwattime"

* --- nwdendrogram: errors of the graph are reported, non-nested levels stop with 459
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwhierarchy net1
nwdendrogram _clus_1
assert _rc == 0
capture noisily nwdendrogram _clus_1, bogusoption(3)
assert _rc == 198
nwdendrogram _clus_1, lab
assert _rc == 0
* the data are unchanged after an error
capture confirm variable __lev1
assert _rc != 0
nwwebuse florentine, nwclear
nwhierarchy flomarriage
nwdendrogram _clus_1
assert _rc == 0
di "PASS nwdendrogram"

* --- nwcontext: mat() without generate(); both together
nwclear
nwset, mat((0,1,1\1,0,0\0,1,0)) name(c3) directed
if _N < 3 quietly set obs 3
gen x = _n * 10
capture mata: mata drop __t_ctx
nwcontext c3, attribute(x) mat(__t_ctx)
assert _rc == 0
mata: assert(__t_ctx == (25 \ 10 \ 20))
nwcontext c3, attribute(x) mat(__t_ctx2) generate(ctx)
assert ctx[1] == 25 & ctx[2] == 10 & ctx[3] == 20
mata: assert(__t_ctx2 == (25 \ 10 \ 20))
capture noisily nwcontext c3, attribute(x)
assert _rc == 198
mata: mata drop __t_ctx __t_ctx2
di "PASS nwcontext"

* --- nwstack refuses two-mode networks
nwclear
clear
input person event
1 1
2 1
3 2
end
nw2fromedge person event, name(b1)
nwset, mat((0,1\1,0)) name(o2) undirected nooutput
nwset, mat((0,1\1,0)) name(o3) undirected nooutput
clear
capture noisily nwstack o2 b1, name(st)
assert _rc == 6088
capture mata: __nwstack_S
assert _rc != 0
nwstack o2 o3, name(st)
assert r(N) == 4
di "PASS nwstack"

* --- _nwnodelab: node ids below 1 are out of bounds
nwclear
nwset, mat((0,1\1,0)) name(nl) labs(a,b) nooutput
_nwnodelab nl, nodeid(2)
assert `"`r(nodelab)'"' == "b"
* the error of a node id above the number of nodes (unchanged) is the error for ids below 1 too
capture noisily _nwnodelab nl, nodeid(3)
local rcbig = _rc
assert `rcbig' != 0
capture noisily _nwnodelab nl, nodeid(0)
assert _rc == `rcbig'
capture noisily _nwnodelab nl, nodeid(-1)
assert _rc == `rcbig'
di "PASS _nwnodelab"

* --- nwdyadprob, density(): tie values above 1 are relative weights (no invlogit)
nwclear
set seed 4711
* dyads among nodes 1-5 have weight 1000, all other dyads 0.001
mata: __t_w = J(10, 10, 0.001); __t_w[1..5, 1..5] = J(5, 5, 1000); _diag(__t_w, 0)
nwset, mat(__t_w) name(wnet) nooutput
nwdyadprob wnet, density(0.2) name(dp)
nwtomata dp, mat(__t_dp)
mata: st_numscalar("__t_in", sum(__t_dp[1..5, 1..5]))
mata: st_numscalar("__t_all", sum(__t_dp))
assert scalar(__t_all) == 18
* with the old invlogit (weights near 1 and 0.5) about half of the ties fell outside the block
assert scalar(__t_in) >= 17
* the same with mat()
nwdyadprob, mat(__t_w) density(0.2) name(dpm)
nwtomata dpm, mat(__t_dpm)
mata: st_numscalar("__t_in", sum(__t_dpm[1..5, 1..5]))
assert scalar(__t_in) >= 17
* negative weights are refused with density()
mata: __t_neg = J(4, 4, 1); __t_neg[1,2] = -1; _diag(__t_neg, 0)
capture noisily nwdyadprob, mat(__t_neg) density(0.2) name(dpn)
assert _rc == 198
* without density() the invlogit of values outside 0-1 is kept: weight 1000 -> probability 1
nwdyadprob wnet, name(dpi)
nwtomata dpi, mat(__t_dpi)
mata: st_numscalar("__t_in", sum(__t_dpi[1..5, 1..5]))
assert scalar(__t_in) == 20
mata: mata drop __t_w __t_dp __t_dpm __t_neg __t_dpi
scalar drop __t_in __t_all
di "PASS nwdyadprob"

di "ALL PASS"
