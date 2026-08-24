cscript

do unw_core.do


nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet) undirected labs(A,B,C,D)
nwburt starnet, silent
assert reldif(_effsize[1], 3) < 1e-6
di "=== STAR NETWORK: effsize=3 as documented, VERIFIED ==="

nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4net) undirected labs(A,B,C,D)
nwburt k4net, silent
assert reldif(_effsize[1], 1) < 1e-6
di "=== COMPLETE GRAPH K4: effsize=1 as documented, VERIFIED ==="

nwclear
nwset, mat((0,4,3,2\4,0,2,0\3,2,0,0\2,0,0,0)) name(mynet) undirected labs(A,B,C,D)
nwburt mynet, dyadredundancy dyadconstraint silent
mata:
onenet = (0,4,3,2\4,0,2,0\3,2,0,0\2,0,0,0)
net2 = onenet * onenet
outdeg = rowsum(onenet)
dyadred_ref = onenet :* (net2 :/ outdeg)
_editmissing(dyadred_ref, 0)
p = onenet :/ rowsum(onenet)
_editmissing(p, 0)
p2 = p * p
c = p + p2
dyadcon_ref = onenet :* (c :* c)
_editmissing(dyadcon_ref, 0)
_diag(dyadcon_ref, 0)
effsize_ref = rowsum(onenet) - rowsum(dyadred_ref)
efficiency_ref = effsize_ref :/ rowsum(onenet)
constraint_ref = rowsum(dyadcon_ref)
N = rowsum(onenet)
avgc = rowsum(dyadcon_ref) :/ N
z = rowsum(onenet :* (dyadcon_ref :/ avgc) :* log(dyadcon_ref :/ avgc))
H_ref = z :/ (N :* log(N))
_editmissing(H_ref, 1)
M = (N :== 0)
_editvalue(M,1,.)
H_ref = H_ref :+ M
st_matrix("effsize_ref", effsize_ref)
st_matrix("efficiency_ref", efficiency_ref)
st_matrix("constraint_ref", constraint_ref)
st_matrix("H_ref", H_ref)
end
mata: st_numscalar("r(match_eff)", mreldif(st_matrix("effsize_ref"), st_data((1::4),"_effsize")) < 1e-6)
mata: st_numscalar("r(match_effic)", mreldif(st_matrix("efficiency_ref"), st_data((1::4),"_efficiency")) < 1e-6)
mata: st_numscalar("r(match_constr)", mreldif(st_matrix("constraint_ref"), st_data((1::4),"_constraint")) < 1e-6)
mata: st_numscalar("r(match_h)", mreldif(st_matrix("H_ref"), st_data((1::4),"_hierarchy")) < 1e-6)
assert r(match_eff) == 1
assert r(match_effic) == 1
assert r(match_constr) == 1
assert r(match_h) == 1
di "=== REGRESSION CERTIFICATION vs HISTORICAL FORMULAS: ALL 4 MEASURES MATCH (float precision) ==="

nwset, detail
assert `"`r(nets)'"' == `" mynet dyadredundancy dyadconstraint"'
di "=== dyadredundancy/dyadconstraint SAVED NETWORKS VERIFIED ==="

nwclear
nwset, mat((0,1,0\1,0,0\0,0,0)) name(isonet) undirected labs(A,B,C)
nwburt isonet, silent
di "isolate node C: effsize=" _effsize[3] " efficiency=" _efficiency[3] " constraint=" _constraint[3]
di "=== ISOLATE-NODE CASE: RAN WITHOUT ERROR ==="

nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet2) undirected labs(A,B,C,D)
nwburt starnet2, silent
capture nwburt starnet2, silent
assert _rc == 99
nwburt starnet2, silent replace
assert _rc == 0
di "=== replace OPTION / OVERWRITE-PROTECTION VERIFIED ==="

nwclear
nwset, mat((0,1,1\0,0,1\0,0,0)) name(dirnet) directed labs(A,B,C)
nwburt dirnet, silent
di "directed net ran OK, effsize[1]=" _effsize[1]
di "=== DIRECTED NETWORK CASE: RAN WITHOUT ERROR ==="

nwclear
nwset, mat((0,0,0\0,0,0\0,0,0)) name(emptynet) undirected labs(A,B,C)
nwburt emptynet, silent
di "empty net effsize[1]=" _effsize[1] " (expect 0, no ties)"
di "=== EMPTY NETWORK CASE: RAN WITHOUT ERROR ==="

* drive-by fix, positions_equivalence group (found while writing this
* command's own Examples section): several capture'd probes (the
* collision-guard confirm-variable loop, the capture drop calls) each
* leave a stale, harmless nonzero _rc on the ordinary no-collision case,
* and neither return scalar nor sum refresh it - an entirely successful
* nwburt call could leak a stale nonzero _rc to its own caller.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) undirected labs(A,B,C) name(freshnet)
nwburt freshnet
assert _rc == 0
nwburt freshnet, silent replace
assert _rc == 0
di "=== stale _rc leak REGRESSION VERIFIED ==="