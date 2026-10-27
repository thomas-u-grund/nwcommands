"""nwsaom (v1.1.0) against RSiena 1.6.14: plan for the single-thread comparison of the 20 article models and X1-X8.
Run:  BENCH=... python3 plan_saom.py [main|extra|cores|all]"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import benchlib

BENCH = os.environ["BENCH"]
SCR = os.environ["SCR"]
STATA = "/Applications/Stata/StataBE.app/Contents/MacOS/StataBE"
RSCRIPT = "/usr/local/bin/Rscript"
NWC = SCR + "/r3100"
NWS = SCR + "/speed/nwsaom"
PLUS = SCR + "/speed/plus_empty"
os.makedirs(PLUS, exist_ok=True)
S = BENCH + "/scripts"
MAIN = "N1 N2 N4 N5 N6 N7 U1 U2 C1 C2 C3 R1 R2 R3 S100 S200 S500 T200 R4 R5".split()
EXTRA = "X1 X2 X3 X4 X5 X6 X7 X8".split()

def stata_impl(name, model, tree=NWS, cores=1):
    return dict(name=name, argv=[STATA, "-e", "do", S + "/saom_one.do"],
                env=dict(MODEL=model, SEED="{seed}", BENCH=BENCH, BENCH_PLUS=PLUS, NWC=NWC, CORES=str(cores),
                         BENCH_ADOPATH=":".join([NWC, NWC + "/lib", tree, tree + "/lib", tree + "/lib/plugins/macos"])))

def r_impl(name, model, nodes=1):
    return dict(name=name, argv=[RSCRIPT, S + "/saom_one.R", model, "{seed}", "{out}", str(nodes)], env=dict(BENCH=BENCH))

def cells(models, extra_impls=None):
    out = []
    for i, m in enumerate(models):
        out.append(dict(cell=m, group="saom_"+m, rank=i, impls=[r_impl("RSiena", m), stata_impl("nwsaom", m, cores=1)]))
    return out

if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    os.chdir(BENCH + "/logs")
    if what in ("main", "all"):
        benchlib.run_plan("saom", cells(MAIN), BENCH + "/raw/saom_main.csv", SCR + "/speed/work_saom")
    if what in ("extra", "all"):
        benchlib.run_plan("saom", cells(EXTRA), BENCH + "/raw/saom_extra.csv", SCR + "/speed/work_saom")
