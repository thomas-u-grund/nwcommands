"""Diagnostic: is nwsaom 1.1.0 slower than 1.0.10 on the larger models?  R4 and S200 with the released tree of 1.1.0 and of 1.0.10
(both with core 3.10.0), 3 fits each, interleaved."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import benchlib, plan_saom as P
old = P.SCR + "/r370m/nwsaom"
cells = [dict(cell=m, group="saomver", rank=i, impls=[P.stata_impl("nwsaom_1.1.0", m), P.stata_impl("nwsaom_1.0.10", m, tree=old)], maxreps=3) for i, m in enumerate(["S200", "R4"])]
os.chdir(P.BENCH + "/logs")
benchlib.run_plan("saom", cells, P.BENCH + "/raw/saom_versions.csv", P.SCR + "/speed/work_saom")
