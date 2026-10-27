"""Summaries of the raw benchmark CSVs: per-cell medians, ranges, ratios, convergence, agreement, load statistics.
Usage: python3 summarize.py [saom|rem|dynam|load|all]   (reads ../raw/*.csv, writes ../summary/*.csv)"""
import csv, os, statistics as st, sys, math
from collections import defaultdict
HERE = os.path.dirname(os.path.abspath(__file__)); B = os.path.dirname(HERE)
RAW = B + "/raw"; SUM = B + "/summary"
os.makedirs(SUM, exist_ok=True)

def rows(*files):
    out = []
    for f in files:
        p = os.path.join(RAW, f)
        if os.path.exists(p):
            out += list(csv.DictReader(open(p)))
    return out

def fl(x):
    try:
        v = float(x)
        return None if math.isnan(v) else v
    except Exception:
        return None

def vec(s):
    return [fl(x) for x in s.split("\t")] if s else []

def fmt(x, d=None):
    if x is None: return ""
    if d is None:
        d = 3 if x < 1 else 2 if x < 10 else 1 if x < 100 else 0
    return f"{x:.{d}f}"

def cellstats(rs):
    """rs: rows of one (cell, impl).  Returns dict(n, ok, timeouts, med, lo, hi, conv, loadmed)"""
    ok = [r for r in rs if r["status"] == "ok" and fl(r["secs"]) is not None]
    t = [fl(r["secs"]) for r in ok]
    d = dict(n=len(ok), timeouts=sum(r["status"] == "timeout" for r in rs), errors=sum(r["status"] == "error" for r in rs),
             skipped=sum(r["status"] == "skipped" for r in rs))
    d["med"] = st.median(t) if t else None
    d["lo"] = min(t) if t else None; d["hi"] = max(t) if t else None
    d["conv"] = sum(1 for r in ok if r["converged"] == "1")
    it = [fl(r["iters"]) for r in ok if fl(r["iters"]) is not None]
    d["iters"] = (min(it), st.median(it), max(it)) if it else None
    return d

def group(rows_):
    g = defaultdict(lambda: defaultdict(list))
    for r in rows_:
        g[r["cell"]][r["impl"]].append(r)
    return g

def load_stats(allrows):
    l = [fl(r["load1"]) for r in allrows if fl(r["load1"]) is not None and r["status"] != "skipped"]
    o = sum(1 for r in allrows if r["status"] != "skipped" and r["n_other"] not in ("0", ""))
    l.sort()
    q = lambda p: l[min(len(l) - 1, int(p * len(l)))]
    return dict(n=len(l), min=l[0], median=st.median(l), mean=st.mean(l), p90=q(0.9), max=l[-1], with_other=o)

# ---------------------------------------------------------------- nwsaom
NAMES = {'outdegree': 'outdegree', 'reciprocity': 'reciprocity', 'transtrip': 'transtrip', 'indegpopularity': 'inpop',
         'outactivity': 'outact', 'behsim': 'behsim', 'beh_linear': 'linear', 'beh_quadratic': 'quadratic',
         'beh_avalt': 'avalt', 'beh_avsim': 'avsim', 'transrectrip': 'transrectrip', 'outpopularity': 'outpop'}
def canon_nw(p):
    if p in NAMES: return NAMES[p]
    if p.startswith('gwesp'): return 'gwesp'
    for pre, c in (('samex', 'sameX'), ('nodematch', 'sameX'), ('egox', 'egoX'), ('altx', 'altX'), ('simx', 'simX')):
        if p.lower().startswith(pre): return c
    return p
EFF = {
 'X1': {'dep|density|||eval|': 'outdegree', 'dep|inPopSqrt|||eval|': 'indegpopularity', 'dep|cycle4|||eval|': 'cycle4'},
 'X2': {'dep|density|||eval|': 'outdegree', 'dep|inPopSqrt|||eval|': 'indegpopularity', 'dep|outAct|||eval|': 'outactivity',
        'dep|cycle4|||eval|': 'cycle4', 'dep|outIso|||eval|': 'outiso', 'dep|antiInIso2|||eval|': 'antiiniso2'},
 'X3': {'friend|density|||eval|': 'net1_outdegree', 'friend|recip|||eval|': 'net1_reciprocity', 'friend|crprod|net2||eval|': 'net1_x_crprod',
        'net2|density|||eval|': 'net2_outdegree', 'net2|recip|||eval|': 'net2_reciprocity'},
 'X6': {'net|density|||eval|': 'net1_outdegree', 'net|crprod|adv||eval|': 'net1_x_crprod',
        'adv|density|||eval|': 'net2_outdegree', 'adv|recip|||eval|': 'net2_reciprocity'},
 'X7': {'net|density|||eval|': 'outdegree', 'net|recip|||eval|': 'reciprocity', 'net|gwespFF|||eval|': 'gwesp_.69',
        'net|sameXTransTrip|smoke1||eval|': 'samextranstrip_smoke1', 'net|altXOutAct|alc1||eval|': 'altxoutact_alcohol1',
        'net|egoPlusAltSqX|alc1||eval|': 'egoplusaltsqx_alcohol1'},
 'X8': {'net|density|||eval|': 'outdegree', 'net|recip|||eval|': 'reciprocity', 'net|transTrip1|||eval|': 'nat_transtrip1',
        'net|transRecTrip2|||eval|': 'nat_transrectrip2', 'net|Jout|||eval|': 'nat_jout'},
}
EFF['X4'] = {k: v for k, v in EFF['X3'].items() if 'crprod' not in k}
EFF['X4'].update({'friend|density|||eval|': 'net1_outdegree', 'smoke|linear|||eval|': 'beh_linear', 'smoke|quad|||eval|': 'beh_quadratic',
                  'smoke|avAlt|friend||eval|': 'beh_avalt', 'smoke|avAlt|net2||eval|': 'beh2_avalt'})
EFF['X5'] = {k: v for k, v in EFF['X3'].items() if 'crprod' not in k}
EFF['X5'].update({'friend|egoX|smoke||eval|': 'net1_behegox', 'friend|altX|smoke||eval|': 'net1_behaltx', 'friend|simX|smoke||eval|': 'net1_behsim',
                  'friend|sameWWClosure|net2|smoke|eval|': 'net1_natb_xc_samewwclosure', 'smoke|linear|||eval|': 'beh_linear',
                  'smoke|quad|||eval|': 'beh_quadratic', 'smoke|avAlt|friend||eval|': 'beh_avalt'})
DEPS = {'X1': ['dep'], 'X2': ['dep'], 'X3': ['friend', 'net2'], 'X4': ['friend', 'net2', 'smoke'], 'X5': ['friend', 'net2', 'smoke'],
        'X6': ['net', 'adv'], 'X7': ['net'], 'X8': ['net']}
def rate_map(m):
    multi = m in ('X3', 'X4', 'X5', 'X6'); out = {}
    for k, dp in enumerate(DEPS[m], 1):
        for p in (1, 2):
            out[f'{dp}|Rate|||rate|{p}'] = f'rate{k}_{p}' if multi else f'rate{p}'
    return out

def params(r):
    n = r["names"].split("\t"); e = vec(r["ests"]); s = vec(r["ses"])
    return {a: (b, c) for a, b, c in zip(n, e, s)}

def agreement(m, rs_rows, nw_rows):
    """max over matched parameters of |mean(nw) - mean(rs)| / mean(se_rs)"""
    rs_p = [params(r) for r in rs_rows if r["status"] == "ok" and r["converged"] == "1"]; nw_p = [params(r) for r in nw_rows if r["status"] == "ok" and r["converged"] == "1"]
    if not rs_p or not nw_p: return None, None
    if m.startswith("X"):
        pm = {**EFF[m], **rate_map(m)}
        pairs = [(a, b) for a, b in pm.items()]
    else:
        nwn = {canon_nw(k): k for k in nw_p[0]}
        pairs = [(k, nwn[k]) for k in rs_p[0] if k in nwn]
    worst = 0.0; wname = None
    for a, b in pairs:
        try:
            er = [p[a][0] for p in rs_p]; sr = [p[a][1] for p in rs_p]
            en = [p[b][0] for p in nw_p]
        except KeyError:
            continue
        if None in er or None in en or None in sr: continue
        d = abs(st.mean(en) - st.mean(er)) / st.mean(sr)
        if d > worst: worst, wname = d, a
    return worst, wname

def saom(raw_files, out):
    R = rows(*raw_files)
    g = group(R)
    tab = []
    for cell, impls in g.items():
        a = cellstats(impls.get("RSiena", [])); b = cellstats(impls.get("nwsaom", []))
        c = cellstats(impls.get("nwsaom_mata", []))
        ag, an = agreement(cell, impls.get("RSiena", []), impls.get("nwsaom", []))
        tab.append(dict(model=cell, n_rsiena=a["n"], n_nwsaom=b["n"], rsiena_med=fmt(a["med"]), rsiena_min=fmt(a["lo"]), rsiena_max=fmt(a["hi"]),
                        nwsaom_med=fmt(b["med"]), nwsaom_min=fmt(b["lo"]), nwsaom_max=fmt(b["hi"]),
                        ratio=fmt(a["med"] / b["med"], 2) if a["med"] and b["med"] else "",
                        conv_rsiena=f'{a["conv"]}/{a["n"]}', conv_nwsaom=f'{b["conv"]}/{b["n"]}',
                        max_diff_se=fmt(ag, 2) if ag is not None else "", worst_param=an or ""))
    if tab:
        with open(os.path.join(SUM, out), "w", newline="") as fh:
            w = csv.DictWriter(fh, list(tab[0])); w.writeheader(); w.writerows(tab)
    return tab, R


# ---------------------------------------------------------------- generic two-implementation comparison (nwrem, nwdynam)
def pmap(r):
    n = r["names"].split("\t"); e = vec(r["ests"]); s = vec(r["ses"])
    return {a.lower(): (b, c) for a, b, c in zip(n, e, s)}

def max_diff(ref_rows, rows_, refse_rows=None):
    """max over parameters of |mean(rows_) - mean(ref)| / mean(se of ref)"""
    P = [pmap(r) for r in ref_rows if r["status"] == "ok" and r["converged"] == "1"]; Q = [pmap(r) for r in rows_ if r["status"] == "ok" and r["converged"] == "1"]
    if refse_rows: S = [pmap(r) for r in refse_rows if r["status"] == "ok" and r["converged"] == "1"]
    else: S = P
    if not P or not Q or not S: return None
    worst = 0.0
    for k in P[0]:
        if k not in Q[0] or k not in S[0]: continue
        er = [p[k][0] for p in P]; en = [q[k][0] for q in Q]; se = [p[k][1] for p in S]
        if None in er or None in en or None in se: continue
        worst = max(worst, abs(st.mean(en) - st.mean(er)) / st.mean(se))
    return worst

def compare(rawfile, out, ref, others, order):
    R = rows(rawfile)
    g = group(R)
    tab = []
    for cell in order:
        if cell not in g: continue
        impls = g[cell]
        row = dict(cell=cell, group=next(iter(impls.values()))[0]["group"])
        cs = {}
        for name in [ref] + others:
            c = cellstats(impls.get(name, []))
            cs[name] = c
            if not impls.get(name): st_ = ""
            elif c["n"]: st_ = ""
            elif c["timeouts"]: st_ = ">600 (time-out)"
            elif c["skipped"]: st_ = "not run"
            else: st_ = "failed"
            row[name + "_n"] = c["n"]
            row[name + "_med"] = fmt(c["med"]) if c["med"] is not None else st_
            row[name + "_min"] = fmt(c["lo"]); row[name + "_max"] = fmt(c["hi"])
            row[name + "_iters"] = "" if not c["iters"] else "%g-%g" % (c["iters"][0], c["iters"][2])
            row[name + "_conv"] = "%d/%d" % (c["conv"], c["n"]) if c["n"] else ""
            if name != ref:
                row["agree_" + name] = fmt(max_diff(impls.get(ref, []), impls.get(name, [])), 2) if impls.get(name) and impls.get(ref) else ""
        tab.append(row)
    if tab:
        keys = []
        for r in tab:
            for k in r:
                if k not in keys: keys.append(k)
        with open(os.path.join(SUM, out), "w", newline="") as fh:
            w = csv.DictWriter(fh, keys); w.writeheader(); w.writerows(tab)
    return tab, R

if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what in ("saom", "all"):
        for files, out in ((["saom_main.csv"], "saom_main.csv"), (["saom_extra.csv"], "saom_extra.csv")):
            tab, R = saom(files, out)
            for t in tab: print(t["model"], t["rsiena_med"], t["nwsaom_med"], t["ratio"], t["max_diff_se"], t["conv_rsiena"], t["conv_nwsaom"])
    if what in ("rem", "all"):
        import plan_rem as PR
        order = [st + "_" + sz for st in PR.SETS for sz in PR.SIZES]
        tab, R = compare("rem.csv", "rem.csv", "nwrem", ["relevent_hessT", "relevent_hessF"], order)
        for t in tab: print(t["cell"], t["nwrem_med"], t["relevent_hessT_med"], t["relevent_hessF_med"], t.get("agree_relevent_hessT"), t["nwrem_n"], t["relevent_hessT_n"])
    if what in ("dynam", "all"):
        import plan_dynam as PD
        order = [st + "_" + sz for st in PD.SETS for sz in PD.SIZES]
        tab, R = compare("dynam.csv", "dynam.csv", "nwdynam", ["nwdynam_mata", "gf_default", "gf_default_c", "gf_gather"], order)
    if what in ("load", "all"):
        allr = rows(*sorted(f for f in os.listdir(RAW) if f.endswith(".csv")))
        print(load_stats(allr))
