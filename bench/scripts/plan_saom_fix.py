"""Re-run the RSiena side of the cells whose RSiena fits were wrongly skipped by the first driver (T200, R4, R5)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import benchlib, plan_saom as P
os.chdir(P.BENCH + "/logs")
benchlib.run_plan("saom", P.cells(["T200", "R4", "R5"]), P.BENCH + "/raw/saom_main.csv", P.SCR + "/speed/work_saom")
