cscript

do unw_core.do

* Newman's (2002) assortativity coefficient - a well-known, standard SNA
* measure confirmed genuinely absent from this package (no
* nwassortativity.ado/similar existed anywhere - not to be confused
* with nwmixing's own categorical E-I index/mixing matrix, a different
* question, or nwcorrelate's own neighborhood-profile correlation).

* star network: every tie connects the degree-3 hub to a degree-1 leaf
* - a textbook case of PERFECT disassortativity, r = -1 exactly (no
* variance around the deterministic high/low pairing).
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet) undirected labs(A,B,C,D)
nwassortativity starnet
assert reldif(r(assortativity), -1) < 1e-8
assert r(ties) == 3
assert `"`r(attribute)'"' == `"degree"'

* complete graph: every node has the identical degree - zero variance,
* correlation undefined, must return missing rather than a spurious
* value (the same convention this package uses elsewhere, e.g.
* nwclustering, for degree-undefined cases).
nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4net) undirected labs(A,B,C,D)
nwassortativity k4net, silent
assert r(assortativity) == .

* attribute() mode: an arbitrary numeric node attribute instead of
* degree, hand-computable for the same star network. x = 1,2,3,4 for
* A,B,C,D; every tie pairs x=1 (the hub) with x in {2,3,4} (a leaf).
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet2) undirected labs(A,B,C,D)
gen x = _n
nwload
nwassortativity starnet2, attribute(x)
assert reldif(r(assortativity), -.75) < 1e-6
assert `"`r(attribute)'"' == `"x"'

* directed network must run cleanly (symmetrized/connected-either-
* direction treatment, matching nwclustering's/nwclique's own
* established convention for directed input on measures with no
* natural directed generalization).
nwclear
nwset, mat((0,1,1\0,0,1\0,0,0)) name(dirnet) directed labs(A,B,C)
nwassortativity dirnet, silent
assert _rc == 0

* string attribute must error cleanly (attribute() requires numeric)
nwclear
nwset, mat((0,1\1,0)) name(net2) undirected labs(A,B)
gen s = "a"
nwload
capture nwassortativity net2, attribute(s)
assert _rc != 0
