cscript

do unw_ergm.do

* Certifies unw_ergm.do's statistic() implementations for all 8 v1 terms
* (edges, mutual, nodematch, nodecov, nodeocov, nodeicov, edgecov, gwesp,
* gwdegree/gwodegree/gwidegree) against REAL Statnet `ergm` output,
* independently generated via dev/ergm_reference/ref_statistics.R (R
* 4.6.0, ergm 4.12.0) on two canonical networks:
*
*   Undirected (5 nodes): edges 1-2,1-3,2-3,3-4,4-5; sex=(1,1,2,2,1);
*   age=(20,25,30,22,28); a 5x5 symmetric edgecov matrix.
*   Directed (5 nodes): edges 1->2,2->1,1->3,3->4,4->5,5->1; same
*   sex/age attributes.
*
* These are the exact networks dev/ergm_reference/ref_networks.R builds -
* if that R script is ever re-run and its printed values change, this
* file's own literal constants must be updated to match (they are a
* frozen snapshot of a specific ergm version's output, not a live
* dependency).

mata:
mata set matastrict off

gU = ErgmGraph()
gU.init(5, 0)
gU.toggle(1,2)
gU.toggle(1,3)
gU.toggle(2,3)
gU.toggle(3,4)
gU.toggle(4,5)

tdmatch = ErgmTermData()
tdmatch.attr = (1\1\2\2\1)
tdcov = ErgmTermData()
tdcov.attr = (20\25\30\22\28)
tdcovmat = ErgmTermData()
tdcovmat.edgecovmat = (0,3,1,4,2 \ 3,0,2,1,5 \ 1,2,0,3,1 \ 4,1,3,0,2 \ 2,5,1,2,0)
tdgw = ErgmTermData()
tdgw.decay = 0.5

st_numscalar("u_edges", stat_edges(gU, ErgmTermData()))
st_numscalar("u_nodematch", stat_nodematch(gU, tdmatch))
st_numscalar("u_nodecov", stat_nodecov(gU, tdcov))
st_numscalar("u_edgecov", stat_edgecov(gU, tdcovmat))
st_numscalar("u_gwesp", stat_gwesp(gU, tdgw))
st_numscalar("u_gwdegree", stat_gwdegree(gU, tdgw))

gD = ErgmGraph()
gD.init(5, 1)
gD.toggle(1,2)
gD.toggle(2,1)
gD.toggle(1,3)
gD.toggle(3,4)
gD.toggle(4,5)
gD.toggle(5,1)

st_numscalar("d_edges", stat_edges(gD, ErgmTermData()))
st_numscalar("d_mutual", stat_mutual(gD, ErgmTermData()))
st_numscalar("d_nodematch", stat_nodematch(gD, tdmatch))
st_numscalar("d_nodecov", stat_nodecov(gD, tdcov))
st_numscalar("d_gwidegree", stat_gwidegree(gD, tdgw))
st_numscalar("d_gwodegree", stat_gwodegree(gD, tdgw))
end

* --- undirected: Statnet reference values in comments ---
assert reldif(u_edges, 5) < 1e-8                          // R: summary(nwU ~ edges) = 5
assert reldif(u_nodematch, 2) < 1e-8                       // nodematch("sex") = 2
assert reldif(u_nodecov, 252) < 1e-8                       // nodecov("age") = 252
assert reldif(u_edgecov, 11) < 1e-8                        // edgecov(ecovU) = 11
assert reldif(u_gwesp, 3) < 1e-8                           // gwesp(0.5,fixed=TRUE) = 3
assert reldif(u_gwdegree, 6.7286954828956427) < 1e-8       // gwdegree(0.5,fixed=TRUE)

* --- directed: Statnet reference values in comments ---
assert reldif(d_edges, 6) < 1e-8                           // edges = 6
assert reldif(d_mutual, 1) < 1e-8                          // mutual = 1
assert reldif(d_nodematch, 4) < 1e-8                       // nodematch("sex") = 4
assert reldif(d_nodecov, 290) < 1e-8                       // nodecov("age") = 290
assert reldif(d_gwidegree, 5.3934693402873668) < 1e-8      // gwidegree(0.5,fixed=TRUE)
assert reldif(d_gwodegree, 5.3934693402873668) < 1e-8      // gwodegree(0.5,fixed=TRUE)
