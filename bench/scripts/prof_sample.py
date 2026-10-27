"""Profile one model with the macOS `sample` tool and add up the samples at the top of the stack by binary image.
Usage: BENCH=... SCR=... python3 prof_sample.py {R|nwsaom|nwsaom_mata} MODEL [REPS] [SECS] [DROP/CMD env via environment]
Not a timing run: the process fits MODEL repeatedly; after DELAY seconds `sample` looks at it for SECS seconds (1 ms interval).
Output: logs/prof_<impl>_<model>.txt (raw sample report) and a line appended to summary/profiles.csv:
impl,model,total_samples,<image>=<samples> ..."""
import os, re, subprocess, sys, time, signal, collections, csv
BENCH = os.environ["BENCH"]; SCR = os.environ["SCR"]
impl, model = sys.argv[1], sys.argv[2]
reps = sys.argv[3] if len(sys.argv) > 3 else "200"
secs = int(sys.argv[4]) if len(sys.argv) > 4 else 15
delay = float(os.environ.get("PROF_DELAY", "4"))
NWC = SCR + "/r3100"; PLUS = SCR + "/speed/plus_empty"
tree = SCR + "/speed/nwsaom" if impl == "nwsaom" else SCR + "/speed/nwsaom_noplug"
env = dict(os.environ, MODEL=model, REPS=reps, BENCH=BENCH, BENCH_PLUS=PLUS, NWC=NWC,
           BENCH_ADOPATH=":".join([NWC, NWC + "/lib", tree, tree + "/lib"] + ([tree + "/lib/plugins/macos"] if impl == "nwsaom" else [])))
wd = SCR + "/speed/work_prof"; os.makedirs(wd, exist_ok=True)
if os.path.exists(wd + "/ready.txt"): os.remove(wd + "/ready.txt")
if impl == "R":
    argv = ["/usr/local/bin/Rscript", BENCH + "/scripts/prof_loop.R", model, reps]
else:
    argv = ["/Applications/Stata/StataBE.app/Contents/MacOS/StataBE", "-e", "do", BENCH + "/scripts/prof_loop.do"]
p = subprocess.Popen(argv, env=env, cwd=wd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
for _ in range(120):                      # bounded wait for the fit loop to start
    if os.path.exists(wd + "/ready.txt"): break
    time.sleep(1)
time.sleep(delay)
rep = BENCH + "/logs/prof_%s_%s.txt" % (impl, model)
subprocess.run(["/usr/bin/sample", str(p.pid), str(secs), "1", "-file", rep], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
alive = p.poll() is None
os.killpg(p.pid, signal.SIGKILL)         # our own process group only
p.wait()
txt = open(rep, errors="replace").read()
sec = txt.split("Sort by top of stack, same collapsed")[-1]
cnt = collections.Counter(); fn = collections.Counter()
for l in sec.splitlines():
    m = re.match(r"^\s+(.+?)\s+\(in (.+?)\)\s+(?:\+\s*\d+\s+)?\[?.*?\]?\s*(\d+)\s*$", l)
    if m:
        cnt[m.group(2)] += int(m.group(3)); fn[(m.group(2), m.group(1))] += int(m.group(3))
tot = sum(cnt.values())
os.makedirs(BENCH + "/summary", exist_ok=True)
with open(BENCH + "/summary/profiles.csv", "a", newline="") as fh:
    w = csv.writer(fh)
    w.writerow([impl, model, tot, alive] + ["%s=%d" % kv for kv in cnt.most_common(8)])
print(impl, model, "samples", tot, "still running at end:", alive)
for k, v in cnt.most_common(8): print("  %-40s %6d  %5.1f%%" % (k, v, 100 * v / max(tot, 1)))
for (im, f), v in fn.most_common(12): print("    %-30s %-50s %6d" % (im, f[:50], v))
