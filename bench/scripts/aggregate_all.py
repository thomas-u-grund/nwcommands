"""Aggregates of all raw benchmark CSVs of the speed comparison (text/CSV only; runs nothing else).
Usage: python3 aggregate_all.py      writes ../summary/*.csv and prints the key numbers
Reads ../raw/*.csv and ../../nwergm_idle/idle_all.csv (+ r_se.csv); needs summarize.py next to it."""
import csv, os, sys, math, statistics as st
from collections import defaultdict
os.environ.setdefault("BENCH", "/x"); os.environ.setdefault("SCR", "/x")
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import summarize as S
RAW, SUM = S.RAW, S.SUM
ERGM = os.path.join(os.path.dirname(os.path.dirname(HERE)), "nwergm_idle")
if not os.path.isdir(ERGM): ERGM = os.path.join(os.path.dirname(HERE), "nwergm", "idle")   # layout of the public bench/ folder

def w(name, rows):
    if not rows: return
    keys = []
    for r in rows:
        for k in r:
            if k not in keys: keys.append(k)
    with open(os.path.join(SUM, name), "w", newline="") as fh:
        wr = csv.DictWriter(fh, keys); wr.writeheader(); wr.writerows(rows)

def f2(x, d=None):
    return "" if x is None else S.fmt(x, d)

# ---------------- nwsaom: main and extra (existing summaries regenerated), plus extra columns
tab_main, _ = S.saom(["saom_main.csv"], "saom_main.csv")
tab_extra, _ = S.saom(["saom_extra.csv"], "saom_extra.csv")
def ratio_range(tab):
    r = [(t["model"], float(t["ratio"])) for t in tab if t["ratio"]]
    return r
# ---------------- nwsaom: per-rep paired ratios (R fit i vs nwsaom fit i), range
def paired(rawfile, a="RSiena", b="nwsaom"):
    g = S.group(S.rows(rawfile)); out = []
    for cell, im in g.items():
        ra = {int(r["rep"]): S.fl(r["secs"]) for r in im.get(a, []) if r["status"] == "ok"}
        rb = {int(r["rep"]): S.fl(r["secs"]) for r in im.get(b, []) if r["status"] == "ok"}
        q = [ra[k] / rb[k] for k in ra if k in rb and ra[k] and rb[k]]
        out.append(dict(cell=cell, pairs=len(q), pair_ratio_min=f2(min(q), 2) if q else "", pair_ratio_max=f2(max(q), 2) if q else ""))
    return out
w("saom_main_pairs.csv", paired("saom_main.csv")); w("saom_extra_pairs.csv", paired("saom_extra.csv"))

# ---------------- nwsaom: plug-in disabled (Mata engine)
g = S.group(S.rows("saom_mata.csv")); mrows = []
for cell, im in sorted(g.items()):
    a = S.cellstats(im.get("nwsaom", [])); b = S.cellstats(im.get("nwsaom_mata", []))
    ag = S.max_diff(im.get("nwsaom", []), im.get("nwsaom_mata", [])) if b["n"] else None
    mrows.append(dict(cell=cell, plugin_n=a["n"], plugin_med=f2(a["med"]), mata_n=b["n"], mata_med=f2(b["med"]), mata_min=f2(b["lo"]), mata_max=f2(b["hi"]),
                      mata_errors=b["errors"], slowdown=f2(b["med"] / a["med"], 0) if a["med"] and b["med"] else "", note="" if b["n"] else "Mata engine does not support this model (error)"))
w("saom_mata.csv", mrows)

# ---------------- nwsaom: cores
g = S.group(S.rows("saom_cores.csv")); crow = []
for cell, im in sorted(g.items()):
    row = dict(cell=cell)
    for name in sorted(im, key=lambda n: (n.split("_")[0], int("".join(c for c in n.split("_")[-1] if c.isdigit())))):
        c = S.cellstats(im[name]); row[name + "_med"] = f2(c["med"]); row[name + "_n"] = c["n"]
    crow.append(row)
w("saom_cores.csv", crow)

# ---------------- nwsaom: versions
g = S.group(S.rows("saom_versions.csv")); vrow = []
for cell, im in sorted(g.items()):
    a = S.cellstats(im.get("nwsaom_1.0.10", [])); b = S.cellstats(im.get("nwsaom_1.1.0", []))
    vrow.append(dict(cell=cell, v1_0_10_n=a["n"], v1_0_10_med=f2(a["med"]), v1_1_0_n=b["n"], v1_1_0_med=f2(b["med"]), ratio=f2(a["med"] / b["med"], 2)))
w("saom_versions.csv", vrow)

# ---------------- nwsaom: X2 ablation (drop one effect from X2)
g = S.group(S.rows("saom_x2abl.csv")); xrow = []
xrow.append(dict(cell="X2 (all five effects)", rsiena_n=7, rsiena_med=[t for t in tab_extra if t["model"] == "X2"][0]["rsiena_med"],
                 nwsaom_n=7, nwsaom_med=[t for t in tab_extra if t["model"] == "X2"][0]["nwsaom_med"], ratio=[t for t in tab_extra if t["model"] == "X2"][0]["ratio"]))
for cell, im in sorted(g.items()):
    a = S.cellstats(im.get("RSiena", [])); b = S.cellstats(im.get("nwsaom", []))
    xrow.append(dict(cell=cell, rsiena_n=a["n"], rsiena_med=f2(a["med"]), nwsaom_n=b["n"], nwsaom_med=f2(b["med"]), ratio=f2(a["med"] / b["med"], 2),
                     rsiena_conv="%d/%d" % (a["conv"], a["n"]), nwsaom_conv="%d/%d" % (b["conv"], b["n"])))
w("saom_x2abl.csv", xrow)

# ---------------- nwsaom: first pass of the large cells (earlier, same machine, separate file)
tab_fp, _ = S.saom(["saom_main_firstpass_S500_R5_slowphase.csv"], "saom_firstpass.csv")

# ---------------- nwrem
import plan_rem as PR
order = [s + "_" + z for s in PR.SETS for z in PR.SIZES]
def pmap_rem(r):
    n = r["names"].split("\t"); e = S.vec(r["ests"]); s = S.vec(r["ses"]); out = {}
    for a, b, c in zip(n, e, s):
        a = a.lower()
        if "_" in a and a.split("_")[0] == a.split("_")[1]: a = a.split("_")[0] + ".1"
        out[a] = (b, c)
    return out
S.pmap = pmap_rem
tab_rem, _ = S.compare("rem.csv", "rem.csv", "nwrem", ["relevent_hessT", "relevent_hessF"], order)
g = S.group(S.rows("rem.csv")); rr = []
for t in tab_rem:
    cell = t["cell"]; im = g[cell]
    a = S.cellstats(im.get("nwrem", [])); b = S.cellstats(im.get("relevent_hessT", [])); c = S.cellstats(im.get("relevent_hessF", []))
    row = dict(cell=cell, nwrem_n=a["n"], nwrem_med=t["nwrem_med"], relT_med=t["relevent_hessT_med"], relF_med=t["relevent_hessF_med"],
               ratio_T=f2(b["med"] / a["med"], 2) if a["med"] and b["med"] else "", ratio_F=f2(c["med"] / a["med"], 2) if a["med"] and c["med"] else "",
               hessian_share=f2(1 - c["med"] / b["med"], 2) if b["med"] and c["med"] else "",
               relT_status="" if b["n"] else t["relevent_hessT_med"], relF_status="" if c["n"] else t["relevent_hessF_med"],
               nwrem_conv=t["nwrem_conv"], relT_conv=t["relevent_hessT_conv"], relF_conv=t["relevent_hessF_conv"],
               agree_hessT=t.get("agree_relevent_hessT", ""), agree_hessF=t.get("agree_relevent_hessF", ""))
    rr.append(row)
w("rem_ratios.csv", rr)

# ---------------- nwdynam
import plan_dynam as PD
order = [s + "_" + z for s in PD.SETS for z in PD.SIZES]
g = S.group(S.rows("dynam.csv")); drow = []
def pm_dyn(r):
    n = r["names"].split("\t"); e = S.vec(r["ests"]); s = S.vec(r["ses"])
    return {a.lower(): (b, c) for a, b, c in zip(n, e, s)}
S.pmap = pm_dyn
for cell in order:
    if cell not in g: continue
    im = g[cell]; cs = {k: S.cellstats(im[k]) for k in im}
    nw = cs.get("nwdynam"); row = dict(cell=cell)
    for k in ("gf_default", "gf_default_c", "gf_gather", "nwdynam", "nwdynam_mata"):
        if k in cs:
            row[k + "_n"] = cs[k]["n"]; row[k + "_med"] = f2(cs[k]["med"]); row[k + "_min"] = f2(cs[k]["lo"]); row[k + "_max"] = f2(cs[k]["hi"])
            row[k + "_conv"] = "%d/%d" % (cs[k]["conv"], cs[k]["n"])
    for k in ("gf_default", "gf_default_c", "gf_gather"):
        row["ratio_" + k] = f2(cs[k]["med"] / nw["med"], 2) if k in cs and cs[k]["med"] and nw["med"] else ""
    if "nwdynam_mata" in cs and cs["nwdynam_mata"]["med"]:
        row["ratio_mata_vs_gf_default_c"] = f2(cs["gf_default_c"]["med"] / cs["nwdynam_mata"]["med"], 2)
        row["plugin_speedup_over_mata"] = f2(cs["nwdynam_mata"]["med"] / nw["med"], 2)
    row["agree_vs_gf_default_c_SE"] = f2(S.max_diff(im["gf_default_c"], im["nwdynam"]), 3)
    row["gf_preprocess_secs_med"] = ""
    pp = []
    for r in im["gf_default_c"]:
        if "preprocess_only_secs" in r["info"]:
            try: pp.append(float(r["info"].split("preprocess_only_secs")[1].split()[0]))
            except Exception: pass
    row["gf_preprocess_secs_med"] = f2(st.median(pp)) if pp else ""
    drow.append(row)
w("dynam.csv", drow)

# ---------------- nwergm (idle machine run, 7 interleaved fits, 8 models)
rows = list(csv.DictReader(open(os.path.join(ERGM, "idle_all.csv"))))
gm = defaultdict(lambda: defaultdict(list))
for r in rows: gm[r["model"]][r["impl"]].append(r)
se = defaultdict(list)
for r in csv.DictReader(open(os.path.join(ERGM, "r_se.csv"))): se[r["model"]].append(float(r["se"]))
erow = []
for m in ["B1", "B2", "B3", "B4", "B5", "B6", "Lazega", "Mesa"]:
    row = dict(model=m); med = {}
    est = {}
    for i, nm in (("R", "R"), ("v123", "nwergm123"), ("v130", "nwergm130")):
        rs = gm[m][i]; t = [float(r["secs"]) for r in rs]; it = [int(float(r["iter"])) for r in rs if r["iter"] not in ("", "NA")]
        med[i] = st.median(t)
        row.update({nm + "_n": len(t), nm + "_med": f2(med[i]), nm + "_min": f2(min(t)), nm + "_max": f2(max(t)),
                    nm + "_conv": "%d/%d" % (sum(1 for r in rs if r["converged"] in ("1", "TRUE", "true")), len(rs)), nm + "_iters": "%d-%d" % (min(it), max(it))})
        v = [[float(x) for x in r["estimates"].split(";")] for r in rs]; est[i] = [st.mean(c) for c in zip(*v)]; est[i + "sd"] = [st.stdev(c) for c in zip(*v)]
    row["ratio_R_over_130"] = f2(med["R"] / med["v130"], 1); row["ratio_R_over_123"] = f2(med["R"] / med["v123"], 2); row["ratio_123_over_130"] = f2(med["v123"] / med["v130"], 1)
    s = se[m]
    row["agree_130_SE"] = f2(max(abs(a - b) / c for a, b, c in zip(est["v130"], est["R"], s)), 2)
    row["agree_123_SE"] = f2(max(abs(a - b) / c for a, b, c in zip(est["v123"], est["R"], s)), 2)
    row["seed_sd_R_SE"] = f2(max(a / c for a, c in zip(est["Rsd"], s)), 2); row["seed_sd_130_SE"] = f2(max(a / c for a, c in zip(est["v130sd"], s)), 2)
    erow.append(row)
w("ergm_idle.csv", erow)

# ---------------- load statistics
def lstat(name, rs):
    rs = [r for r in rs if r.get("status", "ok") != "skipped"]
    l = sorted(S.fl(r["load1"]) for r in rs if S.fl(r["load1"]) is not None)
    if not l: return None
    o = sum(1 for r in rs if r.get("n_other", "0") not in ("0", ""))
    return dict(file=name, fits=len(l), load_min=f2(l[0], 2), load_median=f2(st.median(l), 2), load_mean=f2(st.mean(l), 2), load_p90=f2(l[int(0.9 * len(l))], 2),
                load_max=f2(l[-1], 2), share_below_4=f2(sum(1 for x in l if x < 4) / len(l), 2), fits_with_other_R_or_Stata_process=o)
lrows = []
for f in sorted(os.listdir(RAW)):
    if f.endswith(".csv") and f != "ergm_sanity.csv":
        x = lstat(f, list(csv.DictReader(open(os.path.join(RAW, f)))))
        if x: lrows.append(x)
main_files = [f for f in os.listdir(RAW) if f.endswith(".csv") and f not in ("ergm_sanity.csv", "saom_main_firstpass_S500_R5_slowphase.csv")]
allr = []
for f in main_files: allr += list(csv.DictReader(open(os.path.join(RAW, f))))
lrows.append(lstat("ALL raw files (without first pass and sanity)", allr))
lrows.append(lstat("ergm_idle (nwergm run, 27 Oct 2026)", [dict(r, n_other="0") for r in rows]))
w("load.csv", lrows)

# ---------------- ergm sanity file (R side only: the Stata side did not run)
sr = list(csv.DictReader(open(os.path.join(RAW, "ergm_sanity.csv"))))
w("ergm_sanity.csv", [dict(model=m, R_fits=sum(1 for r in sr if r["model"] == m and r["impl"] == "R" and r["secs"]),
        R_median_secs=f2(st.median(float(r["secs"]) for r in sr if r["model"] == m and r["impl"] == "R" and r["secs"]), 2),
        nwergm_fits_ok=sum(1 for r in sr if r["model"] == m and r["impl"] == "nwergm130" and r["secs"])) for m in sorted({r["model"] for r in sr})])

# ---------------- pooled counts
def pool(tab, label):
    q = [float(t["ratio"]) for t in tab if t["ratio"]]
    return dict(set=label, cells=len(q), median_ratio=f2(st.median(q), 2), min_ratio=f2(min(q), 2), max_ratio=f2(max(q), 2), cells_below_1=sum(1 for x in q if x < 1))
w("saom_pooled.csv", [pool(tab_main, "saom_main"), pool(tab_extra, "saom_extra"), pool(tab_main + tab_extra, "saom_all")])
for x in lrows: print(x)
print([pool(tab_main, "main"), pool(tab_extra, "extra")])

# ---------------- fit counts per package and implementation (all raw files of that package)
cnt = defaultdict(lambda: dict(fits=0, ok=0, converged=0, timeout=0, error=0, skipped=0))
for f in sorted(os.listdir(RAW)):
    if not f.endswith(".csv") or f in ("ergm_sanity.csv", "saom_main_firstpass_S500_R5_slowphase.csv"): continue
    for r in csv.DictReader(open(os.path.join(RAW, f))):
        key = (r["pkg"], r["impl"].split("_")[0] if r["pkg"] == "saom" and r["impl"].startswith(("RSiena_", "nwsaom_c")) else r["impl"])
        c = cnt[key]; c["fits"] += 1
        c[{"ok": "ok", "timeout": "timeout", "error": "error", "skipped": "skipped"}[r["status"]]] += 1
        if r["status"] == "ok" and r["converged"] == "1": c["converged"] += 1
for i in ("R", "v123", "v130"):
    c = cnt[("ergm", {"R": "ergm 4.12.0", "v123": "nwergm 1.2.3", "v130": "nwergm 1.3.0"}[i])]
    for r in rows:
        if r["impl"] == i: c["fits"] += 1; c["ok"] += 1; c["converged"] += r["converged"] in ("1", "TRUE", "true")
w("fit_counts.csv", [dict(pkg=k[0], impl=k[1], **v) for k, v in sorted(cnt.items())])
def mx(col, tab): 
    v = []
    for t in tab:
        try: v.append(float(t[col]))
        except Exception: pass
    return max(v) if v else None
print("max agreement saom main/extra", mx("max_diff_se", tab_main), mx("max_diff_se", tab_extra), "rem T/F", mx("agree_hessT", rr), mx("agree_hessF", rr), "dynam", mx("agree_vs_gf_default_c_SE", drow))
for k, v in sorted(cnt.items()): print(k, v)
