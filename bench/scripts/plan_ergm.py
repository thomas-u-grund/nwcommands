"""One sanity check of the nwergm numbers (not a rerun of the nwergm benchmark): models B4 and B5, nwergm 1.3.0 against
ergm 4.12.0, 3 interleaved fits each, using the scripts and networks of docs/nwergm_idle (copied to data/ergm)."""
import os, sys, subprocess, csv, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import benchlib
BENCH = os.environ["BENCH"]; SCR = os.environ["SCR"]
STATA = os.environ.get("STATA", "/Applications/Stata/StataBE.app/Contents/MacOS/StataBE"); RSCRIPT = "/usr/local/bin/Rscript"
IDLE = SCR + "/idle"; NWERGM = SCR + "/ergm130t"
raw = BENCH + "/raw/ergm_sanity.csv"
os.chdir(IDLE)     # the nwergm scripts read the networks from their own folder
out = IDLE + "/sanity_out.csv"
if os.path.exists(out): os.remove(out)
fh = open(raw, "w", newline=""); w = csv.writer(fh); w.writerow(["model", "impl", "rep", "load1", "n_other", "secs", "converged", "iters", "estimates"])
for m in ["B4", "B5"]:
    for rep in (1, 2, 3):
        for impl in ("R", "nwergm130"):
            l1 = benchlib.load1(); no = benchlib.n_other()
            if os.path.exists(out): os.remove(out)
            if impl == "R":
                cmd = ["perl", "-e", "alarm 600; exec @ARGV", RSCRIPT, "one_r.R", m, str(rep), str(l1), out]
            else:
                with open("run_sanity.do", "w") as dof: dof.write('global NWERGM "%s"\nglobal MODEL "%s"\nglobal REP %d\nglobal LOAD %s\nglobal OUT "%s"\nglobal IMPL "v130"\ndo one.do\n' % (NWERGM, m, rep, l1, out))
                cmd = ["perl", "-e", "alarm 600; exec @ARGV", STATA, "-e", "do", "run_sanity.do"]
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if os.path.exists(out):
                f = open(out).read().strip().split("\n")[-1].split(",")
                w.writerow([m, impl, rep, l1, no, f[4], f[5], f[6], f[-1]]); fh.flush()
                print(m, impl, rep, f[4], flush=True)
            else:
                w.writerow([m, impl, rep, l1, no, "", "", "", "error"]); fh.flush()
fh.close()
