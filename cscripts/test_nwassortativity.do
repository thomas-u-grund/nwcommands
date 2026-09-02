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

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwassortativity nonexistent
assert _rc == 482

* --- weighted assortativity (Leung & Chau 2007), added 2026-09-02 -
* closes a real gap flagged during the same NETWORK_TYPE_MATRIX.md
* audit that found nw2degree's/nwaltergen's own gaps: r_w is the
* WEIGHTED Pearson correlation of the identical (attr_i,attr_j) pair
* list plain nwassortativity already builds, weighted by each pair's
* own tie weight - not a different construction. Self-verified here
* via an INDEPENDENT cross-check rather than hand-arithmetic (error-
* prone for a correlation formula): for integer tie weights, a
* weighted Pearson correlation is mathematically identical to a PLAIN
* correlation of the same pair list with each pair physically repeated
* `weight' times - built directly in Mata below using only basic
* primitives (J()/repeated rows via `#'), deliberately NOT reusing
* WeightedPearsonCorr() itself, so this is a genuine independent check,
* not a tautology.
*
* Network: triangle A-B-C plus a pendant A-D (degrees A=3,B=2,C=2,D=1).
* Weights: A-D is heavily weighted (10) relative to the triangle's own
* ties (1 each) - chosen specifically so the weighted and unweighted
* coefficients differ (a symmetric/perfectly-linear toy network would
* give the same r either way, masking a completely ignored weight).
nwclear
nwset, mat((0,1,1,10\1,0,1,0\1,1,0,0\10,0,0,0)) name(wassort) undirected labs(A,B,C,D)
nwassortativity wassort
local r_unweighted = r(assortativity)
nwassortativity wassort, weighted
local r_weighted = r(assortativity)
assert `"`r(weighted)'"' == `"true"'
* the two coefficients must genuinely differ - confirms the weight is
* actually entering the calculation, not silently ignored.
assert abs(`r_weighted' - `r_unweighted') > 0.05

mata:
mata set matastrict off
degrees = (3\2\2\1)    // A,B,C,D connected-degree
// undirected edge list (each edge once): (from, to, weight)
edges = (1,2,1 \ 1,3,1 \ 1,4,10 \ 2,3,1)
xrep = J(0,1,.)
yrep = J(0,1,.)
for (e=1; e<=rows(edges); e++) {
	i = edges[e,1]
	j = edges[e,2]
	w = edges[e,3]
	// both directions, matching connected_neighbors()'s own
	// edge-doubling convention, each repeated `w' times
	xrep = xrep \ J(w,1,degrees[i]) \ J(w,1,degrees[j])
	yrep = yrep \ J(w,1,degrees[j]) \ J(w,1,degrees[i])
}
indepcorr = correlation((xrep,yrep))
st_numscalar("r_indep", indepcorr[2,1])
end
assert reldif(`r_weighted', r_indep) < 1e-8
di "=== weighted assortativity (Leung & Chau 2007) independently cross-verified REGRESSION VERIFIED ==="

* --- on a BINARY (unvalued) network, every present tie has weight 1,
* so weighted and unweighted assortativity must agree exactly.
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(binassort) undirected labs(A,B,C,D)
nwassortativity binassort, silent
local r_bin_unw = r(assortativity)
nwassortativity binassort, weighted silent
local r_bin_w = r(assortativity)
assert reldif(`r_bin_w', `r_bin_unw') < 1e-8
di "=== weighted assortativity on a binary network matches unweighted exactly REGRESSION VERIFIED ==="
