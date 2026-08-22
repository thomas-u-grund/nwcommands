cscript

do unw_ergm.do

* Certifies ErgmModel::build_mple_data() (the MPLE design-matrix builder:
* one row per dyad, columns = the "toward tie present" change statistics,
* final column = the observed tie indicator) by feeding its output into
* Stata's own native `logit ..., noconstant` (per Part XII of the
* governing nwergm task: exploit Stata's existing logistic estimation
* rather than reimplementing IRLS) and comparing against REAL Statnet
* `ergm` MPLE output, independently generated via
* dev/ergm_reference/ref_mple.R (R 4.6.0, ergm 4.12.0) on the same two
* canonical networks test_nwergm_statistics.do uses.
*
* `noconstant` is required: the `edges` term already plays the role of
* an intercept, so a second constant would make the design
* rank-deficient.

* --- undirected edges-only: MPLE == logit(observed density) exactly.
* This network has 5 ties out of 10 possible dyads (density = 0.5
* exactly), so the exact answer is logit(0.5) = 0.
clear
mata:
mata set matastrict off
gU = ErgmGraph()
gU.init(5, 0)
gU.toggle(1,2)
gU.toggle(1,3)
gU.toggle(2,3)
gU.toggle(3,4)
gU.toggle(4,5)

M1 = ErgmModel()
M1.init()
td1 = ErgmTermData()
M1.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))
D1 = M1.build_mple_data(gU)
st_matrix("D1", D1)
end
matrix colnames D1 = edges y
svmat D1, names(col)
qui logit y edges, noconstant
assert abs(_b[edges]) < 1e-6

* --- undirected edges + nodematch(sex): Statnet reference both ~0
* (this network's own dyad-independent MPLE happens to sit almost
* exactly at the origin for both coefficients).
clear
mata:
tdmatch = ErgmTermData()
tdmatch.attr = (1\1\2\2\1)
M2 = ErgmModel()
M2.init()
td2a = ErgmTermData()
M2.addterm("edges", 1, &stat_edges(), &change_edges(), td2a, ("edges"))
M2.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), tdmatch, ("nodematch"))
D2 = M2.build_mple_data(gU)
st_matrix("D2", D2)
end
clear
matrix colnames D2 = edges nodematch y
svmat D2, names(col)
qui logit y edges nodematch, noconstant
assert abs(_b[edges]) < 1e-4
assert abs(_b[nodematch]) < 1e-4

* --- directed edges + mutual: Statnet reference edges=-0.91629073186161214,
* mutual=0.22314355130166649 (a genuinely nonzero, exactly-reproducible
* case - not a degenerate near-zero result like the two above).
clear
mata:
gD = ErgmGraph()
gD.init(5, 1)
gD.toggle(1,2)
gD.toggle(2,1)
gD.toggle(1,3)
gD.toggle(3,4)
gD.toggle(4,5)
gD.toggle(5,1)

M3 = ErgmModel()
M3.init()
td3a = ErgmTermData()
M3.addterm("edges", 1, &stat_edges(), &change_edges(), td3a, ("edges"))
td3b = ErgmTermData()
M3.addterm("mutual", 1, &stat_mutual(), &change_mutual(), td3b, ("mutual"))
D3 = M3.build_mple_data(gD)
st_matrix("D3", D3)
end
clear
matrix colnames D3 = edges mutual y
svmat D3, names(col)
qui logit y edges mutual, noconstant
assert reldif(_b[edges], -0.91629073186161214) < 1e-4
assert reldif(_b[mutual], 0.22314355130166649) < 1e-4
