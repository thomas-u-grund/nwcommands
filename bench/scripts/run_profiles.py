"""Sampling profiles (macOS `sample`), strictly one process at a time.  Not timing runs."""
import os, subprocess, sys
S = os.environ["BENCH"] + "/scripts"
jobs = [("R", "N1"), ("nwsaom", "N1"), ("R", "N2"), ("nwsaom", "N2"), ("R", "R1"), ("nwsaom", "R1"),
        ("R", "X2"), ("nwsaom", "X2"), ("R", "X1"), ("nwsaom", "X1"), ("nwsaom_mata", "N1")]
for impl, m in jobs:
    subprocess.run([sys.executable, S + "/prof_sample.py", impl, m, "400", "12"], check=False)
