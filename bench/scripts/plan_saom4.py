"""Second pass of the four largest nwsaom/RSiena cells (S500, T200, R4, R5), fully interleaved: the first pass ran during a
period in which nwsaom was about 45 percent slower than in a later check with an unchanged load average (see SPEED_ALL.md)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import benchlib, plan_saom as P
os.chdir(P.BENCH + "/logs")
benchlib.run_plan("saom", P.cells(["T200", "R4", "R5", "S500"]), P.BENCH + "/raw/saom_main.csv", P.SCR + "/speed/work_saom")
