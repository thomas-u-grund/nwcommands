"""nwdynam v1.2.0 (plugin and Mata-only) against goldfish 1.6.12 (engines default, default_c, gather_compute).
Run:  SCR=... BENCH=... python3 plan_dynam.py"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import benchlib
BENCH = os.environ["BENCH"]; SCR = os.environ["SCR"]
STATA = os.environ.get("STATA", "/Applications/Stata/StataBE.app/Contents/MacOS/StataBE"); RSCRIPT = "/usr/local/bin/Rscript"
NWC = SCR + "/r3100"; PLUS = SCR + "/speed/plus_empty"; S = BENCH + "/scripts"
TREE = SCR + "/speed/nwdynam"; TREE_NP = SCR + "/speed/nwdynam_noplug"
SIZES = ["e200_n20", "e1000_n30", "e5000_n20", "e5000_n50", "e5000_n100", "e20000_n100"]
SETS = ["C1", "C2", "C3", "R1", "R2"]
PLUGIN_SETS = ["C1", "R1"]       # the original effect sets: the plugin is used only for these
def nw(name, size, st, tree):
    return dict(name=name, argv=[STATA, "-e", "do", S + "/dynam_nw.do"],
                env=dict(SIZE=size, SET=st, BENCH=BENCH, BENCH_PLUS=PLUS, NWC=NWC,
                         BENCH_ADOPATH=":".join([NWC, NWC + "/lib", tree, tree + "/lib"] + ([tree + "/lib/plugins/macos"] if tree == TREE else []))))
def gf(name, size, st, eng):
    return dict(name=name, argv=[RSCRIPT, S + "/dynam_gf.R", size, st, eng, "{out}"], env=dict(BENCH=BENCH))
def cells():
    out = []
    for st in SETS:
        for i, sz in enumerate(SIZES):
            im = [gf("gf_default", sz, st, "default"), gf("gf_default_c", sz, st, "default_c"),
                  gf("gf_gather", sz, st, "gather_compute"), nw("nwdynam", sz, st, TREE)]
            if st in PLUGIN_SETS: im.append(nw("nwdynam_mata", sz, st, TREE_NP))
            out.append(dict(cell=st + "_" + sz, group="dyn_" + st, rank=i, impls=im))
    return out
if __name__ == "__main__":
    os.chdir(BENCH + "/logs")
    benchlib.run_plan("dynam", cells(), BENCH + "/raw/dynam.csv", SCR + "/speed/work_dynam")
