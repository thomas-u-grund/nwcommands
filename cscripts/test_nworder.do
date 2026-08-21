cscript

do unw_core.do

* nworder had zero test coverage before this session, and crashed on
* every call with r(111) "no variables defined": it called
* "_nwsyntax _all, max(9999) name(allnets)", intending nw_syntax's
* name() option to export the resolved _all network list under a
* local literally called `allnets' - but nw_syntax's name() option is
* dead code (it sets a local, then never references it again
* anywhere in the file). `allnets' was therefore always empty, so the
* "foreach v in `allnets' { gen `v' = . }" loop that builds the
* reordering dataset never created any columns at all, and the
* subsequent "ds" found nothing.
*
* Separately, even once the network list is obtained correctly,
* "_nwsyntax _all, ..." clobbers the caller's OWN `netname' local
* (nworder's syntax line uses "anything(name=netname)" for the user's
* desired reorder specification) - a real local-name collision, not
* specific to the name()-option bug. Fixed by capturing the user's
* original reorder specification into a separate local before making
* the nw_syntax call, then restoring `netname' from it afterward.

* --- 3 single-node networks (all node A, so content doesn't matter -
* only the network *order* is being tested), reordered net3/net1/net2
nwclear
nwset, mat((0,1\1,0)) name(neta) labs(A,B)
nwset, mat((0,1\1,0)) name(netb) labs(A,B)
nwset, mat((0,1\1,0)) name(netc) labs(A,B)
nworder netc neta netb
nwset, detail
assert `"`r(nets)'"' == `" netc neta netb"'

* --- reordering must not lose or duplicate any network, or corrupt
* their data - spot check one network's matrix survives intact
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) name(x1) undirected labs(P,Q,R)
nwset, mat((0,1,0\1,0,1\0,1,0)) name(x2) undirected labs(P,Q,R)
nwset, mat((1,1,1\0,0,0\1,0,0)) name(x3) directed labs(P,Q,R)
nworder x3 x1 x2
nwset, detail
assert `"`r(nets)'"' == `" x3 x1 x2"'
assert r(networks) == 3
nwtomata x2, mat(M)
mata: assert(M[1,2] == 1)
mata: assert(M[1,3] == 0)
mata: assert(M[2,3] == 1)
