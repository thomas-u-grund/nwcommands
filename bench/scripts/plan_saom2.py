"""Further nwsaom runs: (1) multi-core comparison, (2) nwsaom on the Mata engine (plugin-free tree), (3) X2 ablation.
Run: SCR=... BENCH=... python3 plan_saom2.py {cores|mata|x2|all}"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import benchlib, plan_saom as P
BENCH = P.BENCH; SCR = P.SCR
NWS_NP = SCR + "/speed/nwsaom_noplug"
W = SCR + "/speed/work_saom"
def cores_cells():
    out = []
    for i, m in enumerate(["R1", "R4"]):
        im = [P.r_impl("RSiena_1", m, 1), P.r_impl("RSiena_5", m, 5), P.r_impl("RSiena_10", m, 10)]
        im += [P.stata_impl("nwsaom_c%d" % c, m, cores=c) for c in (1, 2, 5, 10)]
        out.append(dict(cell=m, group="saomcores", rank=i, impls=im, maxreps=3))
    return out
def mata_cells():
    out = []
    for i, m in enumerate(["N1", "U1", "N2"]):
        out.append(dict(cell=m, group="saommata", rank=i, impls=[P.stata_impl("nwsaom", m), P.stata_impl("nwsaom_mata", m, tree=NWS_NP)], maxreps=3))
    return out
X2EFF = [("outdegree", "density"), ("indegpopularity", "inPopSqrt"), ("outactivity", "outAct"), ("cycle4", "cycle4"), ("outiso", "outIso"), ("antiiniso2", "antiInIso2")]
def x2_cells():
    full = "waves(tm1 tm2 tm3) outdegree indegpopularity outactivity cycle4 outiso antiiniso2 unconditional"
    out = []
    for i, (nwo, rso) in enumerate(X2EFF):
        cmd = full.replace(" " + nwo + " ", " ", 1)
        if nwo == "outdegree": cmd = full.replace("outdegree ", "", 1)
        a = P.stata_impl("nwsaom", "X2"); a["env"] = dict(a["env"], CMD=cmd)
        r = P.r_impl("RSiena", "X2")
        if rso != "density": r["env"] = dict(r["env"], DROP=rso)
        else: continue   # RSiena always keeps the density (outdegree) effect; not ablated
        out.append(dict(cell="X2_no_" + nwo, group="saomx2", rank=i, impls=[r, a], maxreps=5))
    return out
if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    os.chdir(BENCH + "/logs")
    if what in ("cores", "all"): benchlib.run_plan("saom", cores_cells(), BENCH + "/raw/saom_cores.csv", W)
    if what in ("mata", "all"): benchlib.run_plan("saom", mata_cells(), BENCH + "/raw/saom_mata.csv", W, maxreps=3)
    if what in ("x2", "all"): benchlib.run_plan("saom", x2_cells(), BENCH + "/raw/saom_x2abl.csv", W)
