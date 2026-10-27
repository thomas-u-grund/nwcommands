"""Diagnostic (not timing): evaluator counts of nwrem fits (cells where nwrem needed less than 100 s), one fit per cell, seed 1."""
import csv, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import benchlib, plan_rem as P
B = P.BENCH; SCR = P.SCR
raw = B + "/raw/rem.csv"
cells = {}
for r in csv.DictReader(open(raw)):
    if r["impl"] == "nwrem" and r["status"] == "ok" and r["rep"] == "1" and float(r["secs"]) < 100:
        cells[r["cell"]] = (r["cell"].rsplit("_e", 1)[0], "e" + r["cell"].rsplit("_e", 1)[1])
tree = SCR + "/speed/nwrem_counted"
out = B + "/raw/rem_evalcounts.csv"
with open(out, "w", newline="") as fh:
    w = csv.writer(fh); w.writerow(["cell", "set", "size", "evals", "secs"])
    for cell, (st, sz) in cells.items():
        o = SCR + "/speed/work_rem/count.tsv"
        if os.path.exists(o): os.remove(o)
        env = dict(os.environ, SIZE=sz, SET=st, SEED="1", OUT=o, BENCH=B, BENCH_PLUS=P.PLUS, NWC=P.NWC, TREE=tree,
                   BENCH_ADOPATH=":".join([P.NWC, P.NWC + "/lib", tree, tree + "/lib"]))
        subprocess.run(["perl", "-e", "alarm 600; exec @ARGV", P.STATA, "-e", "do", B + "/scripts/rem_count.do"], env=env, cwd=B + "/logs",
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        d = benchlib.parse_out(o)
        w.writerow([cell, st, sz, d.get("evals", ""), d.get("secs", "")]); fh.flush()
        print(cell, d.get("evals"), d.get("secs"), flush=True)
