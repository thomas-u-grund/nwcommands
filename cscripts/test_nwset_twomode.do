cscript

do unw_core.do

* nwset gained a new "twomode" option (part of the two-mode/temporal
* architecture initiative) declaring a two-mode network directly from
* an edgelist of two (or three, for a valued network) id variables -
* the literal syntax requested: "nwset person organisation, twomode".
* That exact input shape already existed as the separate nw2fromedge
* command, unchanged and still directly callable - twomode's own job
* is purely making it reachable through nwset itself too, matching how
* the pre-existing one-mode "edgelist" option makes nwfromedge
* reachable through nwset. Internally, nwset's own twomode branch
* delegates straight to nw2fromedge - no algorithm duplicated.
*
* Deliberately kept as a genuinely distinct option from the
* pre-existing "bipartite" option (which declares a two-mode network
* from a Mata matrix or a *wide* affiliation-matrix varlist, a
* different input shape entirely) rather than folded into it, since
* the two shapes cannot be told apart from a bare varlist alone -
* combining both options is rejected as an explicit, immediate error.

* --- basic edgelist declaration: mode counts, human-readable mode
* descriptions (auto-derived from the variable names), and per-node
* mode membership must all come out correct. 6 affiliation rows among
* 3 people (Thomas, Peter, Tim) and 2 institutions (Oxford, LiU) -
* hand-countable directly from the input data.
nwclear
clear
input str10 person str10 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Tim" "Oxford"
"Peter" "LiU"
"Tim" "LiU"
"Thomas" "LiU"
end
nwset person org, twomode name(mynet)
assert _rc == 0
nwname mynet
assert `"`r(mode2)'"' == `"true"'
assert r(nodes1) == 3
assert r(nodes2) == 2
assert `"`r(mode1desc)'"' == `"person"'
assert `"`r(mode2desc)'"' == `"org"'

* --- valued two-mode: a third variable is the tie value, matching the
* same positional convention nwset's own one-mode "edgelist" option
* already uses (fromid toid value, edgelist) rather than a new,
* inconsistent weight() option.
nwclear
clear
input str10 person str10 org years
"Thomas" "Oxford" 5
"Peter" "Oxford" 7
"Tim" "Oxford" 4
"Peter" "LiU" 1
"Tim" "LiU" 1
"Thomas" "LiU" 1
end
nwset person org years, twomode name(valnet)
assert _rc == 0
nwname valnet
assert `"`r(valued)'"' == `"true"'
assert `"`r(mode2)'"' == `"true"'

* --- twomode and bipartite together is an explicit, immediate error -
* the two option's input shapes cannot be told apart from a bare
* varlist, so this must never be silently guessed at.
nwclear
clear
input str10 a str10 b
"x" "y"
end
capture noisily nwset a b, twomode bipartite
assert _rc != 0

* --- wrong variable count (twomode needs exactly 2 or 3) is rejected
* with a clear error, not a confusing downstream crash.
capture noisily nwset a, twomode
assert _rc != 0

* --- a plain one-mode nwset call (no twomode/bipartite at all) must
* be completely unaffected by any of this - a regression guard that
* adding twomode's own early-dispatch branch didn't change ordinary
* nwset behaviour.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(onemode) undirected labs(A,B,C)
assert _rc == 0
nwname onemode
assert `"`r(mode2)'"' == `"false"'
assert r(nodes) == 3

* --- the pre-existing bipartite option (Mata matrix form) must also
* be completely unaffected - a second regression guard, since twomode
* was added to the same syntax line.
nwclear
mata: bip = (1,1 \ 1,0 \ 0,1)
mata: st_matrix("bip", bip)
nwset, mat(bip) bipartite name(net1) labs(E1,E2,A,B,C)
assert _rc == 0
nwname net1
assert `"`r(mode2)'"' == `"true"'
assert r(nodes1) == 2
assert r(nodes2) == 3
