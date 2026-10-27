"""nwrem v1.0.10 against relevent 1.2.1 (rem.dyad, hessian = TRUE and FALSE).  Run: SCR=... BENCH=... python3 plan_rem.py"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import benchlib
BENCH = os.environ["BENCH"]; SCR = os.environ["SCR"]
STATA = os.environ.get("STATA", "/Applications/Stata/StataBE.app/Contents/MacOS/StataBE"); RSCRIPT = "/usr/local/bin/Rscript"
NWC = SCR + "/r3100"; PLUS = SCR + "/speed/plus_empty"; S = BENCH + "/scripts"; TREE = SCR + "/speed/nwrem"
SIZES = ["e200", "e1000", "e5000_n20", "e5000", "e5000_n100", "e20000"]       # events and actors: 200/20, 1000/30, 5000/20, 5000/50, 5000/100, 20000/100
SETS = ["S1_nodsnd_nidrec", "S2_degree4", "S3_degree4_inertia", "S4_recency", "S5_covariates"]
def nw(size, st):
    return dict(name="nwrem", argv=[STATA, "-e", "do", S + "/rem_nw.do"],
                env=dict(SIZE=size, SET=st, SEED="{seed}", BENCH=BENCH, BENCH_PLUS=PLUS, NWC=NWC,
                         BENCH_ADOPATH=":".join([NWC, NWC + "/lib", TREE, TREE + "/lib"])))
def rr(name, size, st, hess):
    return dict(name=name, argv=[RSCRIPT, S + "/rem_one.R", size, st, hess, "{out}"], env=dict(BENCH=BENCH))
def cells():
    out = []
    for st in SETS:
        for i, sz in enumerate(SIZES):
            out.append(dict(cell=st + "_" + sz, group="rem_" + st, rank=i,
                            impls=[rr("relevent_hessT", sz, st, "TRUE"), rr("relevent_hessF", sz, st, "FALSE"), nw(sz, st)]))
    return out
if __name__ == "__main__":
    os.chdir(BENCH + "/logs")
    benchlib.run_plan("rem", cells(), BENCH + "/raw/rem.csv", SCR + "/speed/work_rem")
