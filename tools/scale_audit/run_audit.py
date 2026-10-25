#!/usr/bin/env python3
"""Scaling audit runner for the nwcommands core package.

    python3 tools/scale_audit/run_audit.py --sizes 1000
    python3 tools/scale_audit/run_audit.py --sizes 5000,20000,100000

Writes tools/scale_audit/results.csv (resumable: rows already present are skipped).
Runs at most two Stata processes at a time, each under `perl -e 'alarm SECS; exec @ARGV'`
inside /usr/bin/time -l (for the peak resident set size). Nothing is ever pkill'ed.
"""
import argparse, csv, os, re, subprocess, sys, threading, time, shutil
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import spec as specmod

STATA = "/Applications/Stata/StataBE.app/Contents/MacOS/StataBE"
ALL_SIZES = [100, 300, 1000, 5000, 10000, 20000, 100000]
FIELDS = ["command", "N", "ties", "outcome", "seconds", "gen_seconds", "peak_mem_mb",
          "load_avg_1m", "rc", "message", "timestamp", "correct"]
lock = threading.Lock()

def prelude(plus):
    return f'''capture program drop nwinstall
set more off
set linesize 200
sysdir set PLUS "{plus}"
local nwa_dir "`c(pwd)'"
cd "{ROOT}"
quietly do unw_core.do
cd "`nwa_dir'"
adopath ++ "{ROOT}"
adopath ++ "{ROOT}/lib/plugins/macos"
'''

def build_do(rec, N, plus):
    s = prelude(plus)
    s += f'global NWA_N {N}\nglobal NWA_KIND {rec["net"]}\nglobal NWA_ATTR {1 if rec.get("attr") else 0}\n'
    s += f'do "{HERE}/network_gen.do"\n'
    s += 'display "NWAUDIT_SETUP_DONE"\n'
    s += f'quietly do "{HERE}/checks.do"\n'
    if rec["net"] in ("dir", "undir", "valued", "valuedu", "edges"):
        s += 'quietly nwa_truthinit\n'
    for l in rec.get("pre", []):
        s += f'capture noisily {l.replace("{N}", str(N))}\n'
        s += 'if _rc {\n    display "NWAUDIT_PRE_RC=" _rc\n    exit _rc\n}\n'
    line = rec["line"].replace("{N}", str(N))
    s += 'display "NWAUDIT_BEGINCMD"\ntimer clear 91\ntimer on 91\n'
    s += f'capture quietly {line}\nlocal nwa_rc = _rc\ncapture _return hold nwa_ret\ntimer off 91\n'
    s += 'quietly timer list 91\n'
    # quietly hides 'display as error' texts: for a quick failure run the line once more with
    # output on, only to learn the message (the reported seconds come from the first run)
    s += 'local nwa_t = r(t91)\nif `nwa_rc\' & `nwa_t\' < 20 {\n    display "NWAUDIT_RERUN"\n    capture noisily ' + line + '\n}\n'
    s += 'display "NWAUDIT_SECS=" `nwa_t\'\n'
    s += 'display "NWAUDIT_CMD_RC=`nwa_rc\'"\n'
    chk = rec.get("chk")
    if chk is None:
        chk = ["nwa_std bench"]
    s += 'global NWA_FAIL ""\n'
    if chk and True:
        s += 'if `nwa_rc\' == 0 {\n'
        for l in chk:
            s += '    capture _return restore nwa_ret, hold\n'
            s += f'    capture noisily {l.replace("{N}", str(N))}\n'
            s += '    if _rc global NWA_FAIL `"${NWA_FAIL}; check line failed rc=`=_rc\': ' + l.replace("{N}", str(N)).replace('"', "'").replace("`", "").replace("$", "") + '"\'\n'
        s += '}\n'
        s += 'if `"${NWA_FAIL}"\' == "" display "NWAUDIT_CHECK=ok"\nelse display "NWAUDIT_CHECK=FAIL" `"${NWA_FAIL}"\'\n'
    else:
        s += 'display "NWAUDIT_CHECK=none"\n'
    s += 'display "NWAUDIT_RC=`nwa_rc\'"\n'
    s += 'display "NWAUDIT_END"\n'
    return s

def classify(rc, msg, text):
    if rc == 484 or "materializing a dense" in text and rc != 0:
        return "REFUSED_GUARD"
    if rc == 900 and ("allows at most" in text or "do not fit into a Stata macro" in text):       # nwtostata: more columns than the flavour has variables
        return "REFUSED_GUARD"
    if rc == 920 or "macro substitution results in line that is too long" in msg:
        return "MACRO_LIMIT"
    return "OTHER_ERROR"

def child_rss_mb(pid):
    """RSS (MB) of the grandchild actually running Stata under /usr/bin/time (read-only ps/pgrep)."""
    try:
        kids = subprocess.run(["pgrep", "-P", str(pid)], capture_output=True, text=True).stdout.split()
        if not kids:
            return 0.0, None
        k = int(kids[0])
        out = subprocess.run(["ps", "-o", "rss=", "-p", str(k)], capture_output=True, text=True).stdout.strip()
        return (int(out) / 1024.0 if out else 0.0), k
    except Exception:
        return 0.0, None

def watch(p, hard_timeout, maxmem_gb):
    """Wait for the child; kill ONLY our own Stata child if it exceeds the memory cap."""
    t0 = time.time()
    while True:
        r = p.poll()
        if r is not None:
            return r, False
        mb, kid = child_rss_mb(p.pid)
        if kid and mb > maxmem_gb * 1024:
            try:
                os.kill(kid, 9)
            except OSError:
                pass
            p.wait()
            return -9, True
        if time.time() - t0 > hard_timeout:
            p.kill()
            p.wait()
            return -9, False
        time.sleep(0.5)

SSC_DEPS = ["gsample", "moremata", "labellist", "tabplot"]   # installed on demand by nwdyadprob/nwhomophily, nwplot, nwtabulate

def ensure_seed_plus(workdir):
    """A scratch PLUS holding the SSC packages that some commands install on first use.
    Without it the first call of nwdyadprob/nwhomophily/nwplot/nwtabulate measures the download
    (about 20 s). Built once (needs internet), copied into every run's private PLUS."""
    seed = os.path.join(workdir, "seed_plus")
    if os.path.isdir(os.path.join(seed, "g")) and os.path.isdir(os.path.join(seed, "m")):
        return seed
    shutil.rmtree(seed, ignore_errors=True)
    os.makedirs(seed)
    d = os.path.join(workdir, "seed_build")
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    with open(os.path.join(d, "seed.do"), "w") as f:
        f.write(f'sysdir set PLUS "{seed}"\n')
        for pkg in SSC_DEPS:
            f.write(f"capture ssc install {pkg}\n")
    with open(os.path.join(d, "o.txt"), "w") as so:
        subprocess.run(["perl", "-e", "alarm shift; exec @ARGV", "300", STATA, "-e", "do", "seed.do"],
                       cwd=d, stdout=so, stderr=so, env=dict(os.environ, PWD=d))
    return seed

def run_one(rec, N, timeout, workdir, maxmem_gb=20):
    cmd = rec["command"]
    d = os.path.join(workdir, f"{cmd}_{N}")
    shutil.rmtree(d, ignore_errors=True)
    seed = ensure_seed_plus(workdir)
    shutil.copytree(seed, os.path.join(d, "plus"))
    dofile = os.path.join(d, "audit.do")
    with open(dofile, "w") as f:
        f.write(build_do(rec, N, os.path.join(d, "plus")))
    load = os.getloadavg()[0]
    t0 = time.time()
    shell = ["/usr/bin/time", "-l", "perl", "-e", "alarm shift; exec @ARGV", str(timeout),
             STATA, "-e", "do", "audit.do"]
    with open(os.path.join(d, "time.txt"), "w") as te, open(os.path.join(d, "stdout.txt"), "w") as so:
        p = subprocess.Popen(shell, cwd=d, stdout=so, stderr=te,
                             env=dict(os.environ, PWD=d))
        ret, memkilled = watch(p, timeout + 60, maxmem_gb)
    wall = time.time() - t0
    log = ""
    lp = os.path.join(d, "audit.log")
    if os.path.exists(lp):
        log = open(lp, errors="replace").read()
    tt = open(os.path.join(d, "time.txt"), errors="replace").read()
    m = re.search(r"(\d+)\s+maximum resident set size", tt)
    mem = round(int(m.group(1)) / 1048576, 1) if m else ""
    def g(key):
        mm = re.search(r"^" + key + r"=(-?[0-9.e+]+)\s*$", log, re.M)
        return mm.group(1) if mm else ""
    ties = g("NWAUDIT_TIES") or ""
    gen_secs = g("NWAUDIT_GEN_SECS")
    row = dict(command=cmd, N=N, ties=ties, outcome="", seconds="", gen_seconds=gen_secs,
               peak_mem_mb=mem, load_avg_1m=round(load, 2), rc="", message="",
               timestamp=time.strftime("%Y-%m-%d %H:%M:%S"))
    def first_msg(after, before):
        mi = re.search(r"^" + after, log, re.M)
        i = mi.start() if mi else -1
        mj = re.search(r"^" + before, log[i + 1:], re.M) if i >= 0 else None
        j = i + 1 + mj.start() if mj else -1
        seg = log[i + len(after):j if j > 0 else None] if i >= 0 else log[-2000:]
        for ln in seg.splitlines():
            ln = ln.strip()
            if ln and not ln.startswith(". ") and not ln.startswith("> ") and ln != "." \
               and not ln.startswith("NWAUDIT") and not ln.startswith("end of do-file") \
               and not ln.startswith("=") and not re.match(r"^\([\d,]+ (real changes? made|observations? )", ln):
                return ln[:300]
        return ""
    if re.search(r"^NWAUDIT_END", log, re.M):
        rc = int(g("NWAUDIT_RC") or 0)
        row["seconds"] = g("NWAUDIT_SECS")
        row["rc"] = rc
        mc = re.search(r"^NWAUDIT_CHECK=(.*)$", log, re.M)
        row["correct"] = (mc.group(1).strip()[:400] if mc else "")
        if rc != 0:
            row["correct"] = "n/a"
        if rc == 0:
            row["outcome"] = "OK"
            if row["correct"].startswith("FAIL"):
                row["outcome"] = "WRONG_RESULT"
        else:
            msg = first_msg("NWAUDIT_BEGINCMD", "NWAUDIT_SECS")
            row["message"] = msg
            row["outcome"] = classify(rc, msg, log)
    elif re.search(r"^NWAUDIT_PRE_RC=", log, re.M):
        rc = int(g("NWAUDIT_PRE_RC"))
        msg = first_msg("NWAUDIT_SETUP_DONE", "NWAUDIT_PRE_RC")
        row.update(rc=rc, message="SETUP(pre): " + msg)
        row["outcome"] = "SETUP_" + classify(rc, msg, log)
    elif re.search(r"^NWAUDIT_GEN_RC=", log, re.M):
        rc = int(g("NWAUDIT_GEN_RC"))
        # the error message is printed (noisily capture) between the TIES and GEN_SECS lines
        msg = first_msg("NWAUDIT_TIES", "NWAUDIT_GEN_SECS")
        row.update(rc=rc, message="SETUP: " + msg)
        row["outcome"] = "SETUP_" + classify(rc, msg, log)
    elif memkilled and re.search(r"^NWAUDIT_SECS=", log, re.M) and g("NWAUDIT_CMD_RC") == "0":
        # the timed command finished and returned 0; the memory cap was hit afterwards, in the correctness check
        # (which materialises matrices of its own). Report the command's own result, say that it is unchecked.
        row["seconds"] = g("NWAUDIT_SECS")
        row["rc"] = 0
        row["outcome"] = "OK"
        row["correct"] = "UNCHECKED (the check exceeded the memory cap)"
        row["message"] = f"command finished; check killed: RSS above {maxmem_gb} GB after {wall:.0f}s"
    else:
        if memkilled:
            row["outcome"] = "MEMORY_KILLED"
        elif ret in (139, -11, 11) or "Segmentation" in tt or "Bus error" in tt or ret in (138, 135, 134, 133):
            row["outcome"] = "CRASH"
        elif wall >= timeout - 3:
            row["outcome"] = "TIMEOUT"
        elif ret in (142, -14) or "Alarm clock" in tt:
            row["outcome"] = "TIMEOUT"
        else:
            row["outcome"] = "CRASH"
        tail = [l.strip() for l in log.splitlines() if l.strip()][-3:]
        row["message"] = f"exit={ret} wall={wall:.0f}s" + (" > " + " | ".join(tail)[:200] if row["outcome"] == "CRASH" else "")
        if memkilled:
            row["message"] = f"killed by the harness: RSS above {maxmem_gb} GB after {wall:.0f}s"
        # a setup-phase timeout shows as TIMEOUT with no SETUP_DONE
        if not re.search(r"^NWAUDIT_SETUP_DONE", log, re.M) and row["outcome"] == "TIMEOUT":
            row["message"] += " (in network setup)"
        row["seconds"] = round(wall, 1) if row["outcome"] in ("TIMEOUT", "MEMORY_KILLED") else ""
    return row

def load_results(path):
    if not os.path.exists(path):
        return []
    with open(path, newline="") as f:
        return list(csv.DictReader(f))

def append_row(path, row):
    with lock:
        new = not os.path.exists(path)
        with open(path, "a", newline="") as f:
            w = csv.DictWriter(f, FIELDS)
            if new:
                w.writeheader()
            w.writerow(row)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sizes", default="1000")
    ap.add_argument("--out", default=os.path.join(HERE, "results.csv"))
    ap.add_argument("--commands", default="", help="comma list, default all")
    ap.add_argument("--timeout", type=int, default=0, help="override seconds per run")
    ap.add_argument("--workdir", default="/private/tmp/nwscale_work")
    ap.add_argument("--jobs", type=int, default=2, help="parallel Stata processes (max 2)")
    ap.add_argument("--maxmem-gb", type=float, default=20, help="kill our own Stata child above this RSS")
    ap.add_argument("--noskip", action="store_true", help="run every recipe, even if it failed or was slow at the previous size")
    ap.add_argument("--keep", action="store_true", help="keep per-run working dirs")
    a = ap.parse_args()
    sizes = [int(x) for x in a.sizes.split(",")]
    jobs = min(a.jobs, 2)
    recs = specmod.SPEC
    if a.commands:
        want = set(a.commands.split(","))
        recs = [r for r in recs if r["command"] in want]
    os.makedirs(a.workdir, exist_ok=True)
    ensure_seed_plus(a.workdir)      # before any parallel work starts

    def prev_row(cmd, N):
        rows = load_results(a.out)
        smaller = [s for s in ALL_SIZES if s < N]
        if not smaller:
            return None
        ps = smaller[-1]
        for r in reversed(rows):
            if r["command"] == cmd and int(r["N"]) == ps:
                return r
        return None

    def work(rec):
        for N in sizes:
            done = {(r["command"], int(r["N"])) for r in load_results(a.out)}
            if (rec["command"], N) in done:
                continue
            base = dict(command=rec["command"], N=N, ties="", seconds="", gen_seconds="",
                        peak_mem_mb="", load_avg_1m=round(os.getloadavg()[0], 2), rc="",
                        message="", timestamp=time.strftime("%Y-%m-%d %H:%M:%S"))
            maxn = rec.get("maxn")
            if maxn and N > maxn:
                append_row(a.out, dict(base, outcome="NOT_TRIED_CAP",
                                       message=f"capped at N={maxn}: {rec.get('cat','')}"))
                continue
            pr = None if a.noskip else prev_row(rec["command"], N)
            longrun = False
            if pr is not None:
                try:
                    slow5 = float(pr["seconds"] or 0) > 90
                except ValueError:
                    slow5 = False
                if N in (10000, 20000) and (pr["outcome"] in ("TIMEOUT", "REFUSED_GUARD") or slow5 or pr["outcome"].startswith("SETUP_")):
                    longrun = True           # stage-2 rule: run once with the longer limit
                    pr = None
            if pr is not None:
                bad = pr["outcome"] in ("TIMEOUT", "CRASH", "MEMORY_KILLED", "NOT_TRIED_PREV_FAILED", "NOT_TRIED_CAP")
                if N >= 100000 and pr["outcome"] != "OK":
                    bad = bad or pr["outcome"] == "REFUSED_GUARD"
                    try:
                        bad = bad or float(pr["seconds"] or 0) > 60
                    except ValueError:
                        pass
                if N >= 100000 and pr["outcome"] == "OK":
                    try:
                        bad = bad or float(pr["seconds"] or 0) > 60
                    except ValueError:
                        pass
                if bad:
                    append_row(a.out, dict(base, outcome="NOT_TRIED_PREV_FAILED",
                                           message=f"N={pr['N']}: {pr['outcome']} {pr['seconds']}s"))
                    continue
            to = a.timeout or (60 if N <= 1000 else 180)
            if not a.timeout and (longrun or rec.get("tmo")):
                to = max(300, rec.get("tmo") or 0)
            row = run_one(rec, N, to, a.workdir, a.maxmem_gb)
            append_row(a.out, row)
            print(f"{rec['command']:16s} N={N:<7d} {row['outcome']:22s} {row['seconds']!s:>8s}s  {row['message'][:70]}", flush=True)
            if not a.keep:
                shutil.rmtree(os.path.join(a.workdir, f"{rec['command']}_{N}"), ignore_errors=True)

    par = [r for r in recs if not r.get("solo")]
    solo = [r for r in recs if r.get("solo")]
    with ThreadPoolExecutor(jobs) as ex:
        list(ex.map(work, par))
    for r in solo:      # memory hogs: one at a time, nothing else running from this script
        work(r)

if __name__ == "__main__":
    main()
