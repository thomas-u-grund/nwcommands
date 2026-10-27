"""Sequential benchmark driver: one process (R or Stata) at a time, interleaved implementations, per-fit load record.

A plan is a list of cells.  A cell is one problem (model, size, effect set) and has several implementations
(R, Stata plugin, Stata Mata, ...).  Within a cell the implementations run in turn for rep 1, then rep 2, ...
(interleaved).  The number of reps follows the rule: 7; 5 if a first-round fit exceeded 60 s; 3 if it exceeded
200 s; 1 if a fit hit the kill switch.  An implementation that timed out or exceeded 300 s on a smaller cell of
the same `group` is not run on larger cells (recorded as 'skipped').

Every fit is a separate process started with `perl -e 'alarm 600; exec @ARGV'` (kill switch 600 s); the
process writes key<TAB>values lines to its OUT file (secs, converged, iters, ll, names, ests, ses, ...).
Raw rows go to the CSV named by `raw`: one row per fit with the 1-minute load average read just before the
start and the number of other R/Stata processes on the machine (should be 0).
"""
import csv, fcntl, os, subprocess, sys, time, signal

KILL = 600
FIELDS = ["pkg", "cell", "group", "rank", "impl", "rep", "status", "load1", "n_other", "wall", "secs", "converged",
          "iters", "ll", "names", "ests", "ses", "info", "start"]

def load1():
    try:
        s = subprocess.check_output(["sysctl", "-n", "vm.loadavg"], text=True).strip("{} \n").split()
        return float(s[0])
    except Exception:
        return float("nan")

def n_other():
    out = subprocess.check_output(["ps", "-Ao", "pid,comm"], text=True).splitlines()[1:]
    n = 0
    for l in out:
        comm = l.strip().split(None, 1)[-1]
        base = os.path.basename(comm)
        if base in ("StataBE", "StataSE", "StataMP", "R", "Rscript") or comm.endswith("/exec/R"):
            n += 1
    return n

def parse_out(path):
    d = {}
    if not os.path.exists(path):
        return d
    for l in open(path):
        l = l.rstrip("\n")
        if "\t" in l:
            k, v = l.split("\t", 1)
            d[k] = v
    return d

def run_one(argv, env, out, logdir, tag):
    """Run one fit; returns (status, wall)."""
    if os.path.exists(out):
        os.remove(out)
    e = dict(os.environ); e.update(env); e["OUT"] = out
    cmd = ["perl", "-e", "alarm %d; exec @ARGV" % KILL] + argv
    os.makedirs(logdir, exist_ok=True)
    t0 = time.time()
    with open(os.path.join(logdir, tag + ".out"), "w") as lf:
        p = subprocess.Popen(cmd, env=e, cwd=logdir, stdout=lf, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            rc = p.wait(timeout=KILL + 20)
        except subprocess.TimeoutExpired:
            os.killpg(p.pid, signal.SIGKILL)   # our own process group only
            rc = -9
            p.wait()
    wall = time.time() - t0
    if os.path.exists(out):
        status = "ok"
    elif wall >= KILL - 2 or rc in (-14, 142, -9):
        status = "timeout"
    else:
        status = "error"
    # remove the per-fit logs of good fits, keep the failures
    if status == "ok":
        for ext in (".out", ".log"):
            q = os.path.join(logdir, tag + ext)
            if os.path.exists(q): os.remove(q)
    return status, wall

def read_done(raw):
    done = {}
    if os.path.exists(raw):
        for r in csv.DictReader(open(raw)):
            done[(r["cell"], r["impl"], int(r["rep"]))] = r
    return done

def run_plan(pkg, cells, raw, workdir, maxreps=7, log=print):
    """cells: list of dict(cell, group, rank, impls=[dict(name, argv(list with {rep},{out}), env(dict with {rep},{out}))])"""
    os.makedirs(workdir, exist_ok=True)
    # one driver at a time on the machine: a second driver blocks here until the first has finished
    global _LOCK
    _LOCK = open(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "logs", ".bench.lock"), "w")
    fcntl.flock(_LOCK, fcntl.LOCK_EX)
    done = read_done(raw)
    new = not os.path.exists(raw)
    fh = open(raw, "a", newline="")
    w = csv.DictWriter(fh, FIELDS)
    if new: w.writeheader()
    bad = {}   # (group, impl) -> True once timed out / > 300 s
    for r in done.values():
        if r["status"] in ("timeout",) or (r["secs"] not in ("", "NA") and float(r["secs"]) > 300):
            bad[(r["group"], r["impl"])] = True
    def record(c, im, rep, status, wall, d, l1, no):
        row = dict(pkg=pkg, cell=c["cell"], group=c["group"], rank=c["rank"], impl=im["name"], rep=rep, status=status,
                   load1=l1, n_other=no, wall="%.2f" % wall, secs=d.get("secs", ""), converged=d.get("converged", ""),
                   iters=d.get("iters", ""), ll=d.get("ll", ""), names=d.get("names", ""),
                   ests=d.get("ests", ""), ses=d.get("ses", ""),
                   info=d.get("version", d.get("info", "")), start=time.strftime("%Y-%m-%d %H:%M:%S"))
        w.writerow(row); fh.flush()
        return row
    def fit(c, im, rep):
        key = (c["cell"], im["name"], rep)
        if key in done:
            return done[key]
        # the machine must be idle apart from this process: wait (bounded) for stray R/Stata processes of others
        for _ in range(30):
            no = n_other()
            if no == 0: break
            time.sleep(2)
        l1 = load1()
        out = os.path.join(workdir, "out_%s_%s_%d.tsv" % (c["cell"], im["name"], rep))
        fmt = dict(rep=rep, out=out, seed=rep)
        argv = [a.format(**fmt) for a in im["argv"]]
        env = {k: v.format(**fmt) for k, v in im.get("env", {}).items()}
        tag = "%s_%s_%d" % (c["cell"], im["name"], rep)
        status, wall = run_one(argv, env, out, os.path.join(workdir, "failed"), tag)
        d = parse_out(out) if status == "ok" else {}
        if status == "ok" and os.path.exists(out): os.remove(out)
        row = record(c, im, rep, status, wall, d, l1, no)
        log("%s %-14s %-12s rep %d %-8s %8s s  load %.2f  other %d" % (pkg, c["cell"], im["name"], rep, status, row["secs"] or "-", l1, no))
        if status == "timeout" or (row["secs"] and float(row["secs"]) > 300):
            bad[(c["group"], im["name"])] = True
        return row
    for c in cells:
        impls = []
        for im in c["impls"]:
            if (c["group"], im["name"]) in bad:
                key = (c["cell"], im["name"], 1)
                if key not in done:
                    record(c, im, 1, "skipped", 0.0, {}, load1(), 0)
                    log("%s %-14s %-12s skipped (too slow on a smaller cell)" % (pkg, c["cell"], im["name"]))
            else:
                impls.append(im)
        if not impls: continue
        first = [fit(c, im, 1) for im in impls]
        tmax = 0.0; to = False
        for r in first:
            if r["status"] == "timeout": to = True
            elif r["secs"] not in ("", "NA"): tmax = max(tmax, float(r["secs"]))
        reps = 1 if (to or tmax > 400) else (3 if tmax > 200 else 5 if tmax > 60 else maxreps)
        reps = min(reps, c.get("maxreps", maxreps))
        for rep in range(2, reps + 1):
            for im in impls:
                if any(r["status"] == "timeout" for r in first if r["impl"] == im["name"]):
                    continue
                fit(c, im, rep)
    fh.close()
