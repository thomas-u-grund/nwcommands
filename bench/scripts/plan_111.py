"""nwsaom 1.1.1 against RSiena 1.6.14, same design as plan_saom.py (1.1.0). Order: extra, small main, cores, large main last."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import benchlib, plan_saom as P
P.NWS = P.SCR + "/rel111"
P.PLUS = P.SCR + "/speed111/plus_empty"
def si(name, model, tree=None, cores=1):
    return P.stata_impl(name, model, tree=tree or P.NWS, cores=cores)
def cells(models):
    return [dict(cell=m, group="saom_"+m, rank=i, impls=[P.r_impl("RSiena", m), si("nwsaom", m)]) for i, m in enumerate(models)]
def cores_cells(models=("R1", "R4")):
    out = []
    for i, m in enumerate(models):
        im = [P.r_impl("RSiena_1", m, 1), P.r_impl("RSiena_5", m, 5), P.r_impl("RSiena_10", m, 10)]
        im += [si("nwsaom_c%d" % c, m, cores=c) for c in (1, 2, 5, 10)]
        out.append(dict(cell=m, group="saomcores", rank=i, impls=im, maxreps=3))
    return out
EXTRA = "X2 X1 X3 X4 X5 X6 X7 X8".split()
SMALL = "N1 U2 C1 R1 U1 C3 R3 N2 N4 N5 N6 N7 C2 R2 S100".split()
LARGE = "S200 T200 R4 R5 S500".split()
if __name__ == "__main__":
    what = sys.argv[1]
    os.chdir(P.BENCH + "/logs")
    W = P.SCR + "/speed111/work"
    if what == "extra": benchlib.run_plan("saom", cells(EXTRA), P.BENCH + "/raw/saom_extra.csv", W)
    if what == "small": benchlib.run_plan("saom", cells(SMALL), P.BENCH + "/raw/saom_main.csv", W)
    if what == "large": benchlib.run_plan("saom", cells(LARGE), P.BENCH + "/raw/saom_main.csv", W)
    if what == "cores2": benchlib.run_plan("saom", cores_cells(("R5", "S500")), P.BENCH + "/raw/saom_cores.csv", W)
    if what == "calib":
        cs = cells(["N2", "R1"])
        for c in cs: c["maxreps"] = 3
        benchlib.run_plan("saom", cs, P.BENCH + "/raw/calib_%s.csv" % sys.argv[2], W, maxreps=3)
    if what == "s500":
        benchlib.run_plan("saom", cells(["S500"]), P.BENCH + "/raw/saom_main.csv", W)
    if what == "cores3": benchlib.run_plan("saom", cores_cells(("R5",)), P.BENCH + "/raw/saom_cores.csv", W)
    if what == "cores": benchlib.run_plan("saom", cores_cells(), P.BENCH + "/raw/saom_cores.csv", W)
