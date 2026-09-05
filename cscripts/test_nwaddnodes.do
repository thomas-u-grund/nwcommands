cscript

do unw_core.do
nwrandom 5, prob(.2) 
nwaddnodes, nodenames(Thomas Grund, Peter, Mathilde Turcotte)
nwsummarize

assert `"`r(mode2)'"'    == `"false"'
assert `"`r(netname)'"'  == `"random"'
assert `"`r(name)'"'     == `"random"'
assert `"`r(labs)'"'     == `"n1,n2,n3,n4,n5,Thomas Grund,Peter,Mathilde Turcotte"'
assert `"`r(valued)'"'   == `"false"'
assert `"`r(directed)'"' == `"true"'
assert `"`r(selfloop)'"' == `"false"'
assert `"`r(vars)'"'     == `"n1 n2 n3 n4 n5 Thomas_Grund Peter Mathilde_Turcotte"'


nwclear
nwrandom 5, prob(.2) name(mynet)
nwaddnodes, nodenames(Thomas Grund, Peter, Mathilde Turcotte) generate(newnet)
nwsummarize mynet
assert         r(nodes)         == 5

nwsummarize newnet
assert         r(nodes)         == 8

* --- harmonisation unit 158: mode() - fixes the previously-documented
* gap ("does not offer a way to choose which mode the new (isolate)
* nodes belong to - not recommended for two-mode networks until that is
* clarified/documented"). Also the supported, disclosed way to add an
* isolate a plain edgelist import can never represent (nwset/nwfromedge/
* nw2fromedge all build their own node set purely from labels that
* actually appear in the edgelist).
nwclear
clear
input person event
1 1
2 1
3 2
end
nwset person event, twomode name(bipnet)
nwsummarize bipnet
assert r(nodes) == 5

* mode() required on a two-mode network - never a silent mode-1 default.
capture noisily nwaddnodes bipnet, nodenames(NewPerson)
assert _rc == 198

* mode() rejected on a one-mode network - meaningless there.
nwrandom 5, prob(.2) name(onemodecheck)
capture noisily nwaddnodes onemodecheck, nodenames(ExtraIsolate) mode(1)
assert _rc == 198

* one value per node, in order.
nwaddnodes bipnet, nodenames(NewPerson, NewInstitution) mode(1 2)
assert _rc == 0
nwsummarize bipnet
assert r(nodes) == 7
_nwsyntax bipnet, max(1)
mata: st_local("__t158_modes", `netobj'->get_modes_labeled_string())
assert `"`__t158_modes'"' == `"n1=1,n2=1,n3=1,n4=2,n5=2,NewPerson=1,NewInstitution=2"'

* a single value broadcasts to every new node.
nwclear
clear
input person event
1 1
2 1
3 2
end
nwset person event, twomode name(bipnet2)
nwaddnodes bipnet2, nodenames(A, B, C) mode(1)
assert _rc == 0
_nwsyntax bipnet2, max(1)
mata: st_local("__t158_modes2", `netobj'->get_modes_labeled_string())
assert `"`__t158_modes2'"' == `"n1=1,n2=1,n3=1,n4=2,n5=2,A=1,B=1,C=1"'

* mismatched mode()/nodenames() counts, and an out-of-range mode value,
* both rejected explicitly.
nwclear
clear
input person event
1 1
2 1
3 2
end
nwset person event, twomode name(bipnet3)
capture noisily nwaddnodes bipnet3, nodenames(A, B) mode(1 2 3)
assert _rc == 198
capture noisily nwaddnodes bipnet3, nodenames(A) mode(3)
assert _rc == 198

* a multi-word node name (an internal space, like "Thomas Grund" above)
* combined with mode() still resolves to exactly one node, correctly
* moded - the real regression this unit's own first implementation
* attempt introduced and caught before shipping: collapsing the
* tokenize() pass into a single space-joined local and re-splitting it
* via `foreach ... of local' silently re-split "Thomas Grund" into two
* separate one-word nodes.
nwclear
clear
input person event
1 1
2 1
3 2
end
nwset person event, twomode name(bipnet4)
nwaddnodes bipnet4, nodenames(New Person, Org X) mode(1 2)
assert _rc == 0
nwsummarize bipnet4
assert r(nodes) == 7
_nwsyntax bipnet4, max(1)
mata: st_local("__t158_modes4", `netobj'->get_modes_labeled_string())
assert `"`__t158_modes4'"' == `"n1=1,n2=1,n3=1,n4=2,n5=2,New Person=1,Org X=2"'

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwaddnodes nonexistent, nodenames(X)
assert _rc == 482
