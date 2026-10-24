#!/usr/bin/env python3
"""Summarise results.csv into a markdown report.

    python3 tools/scale_audit/report.py [--csv results.csv] [--out FILE.md]
"""
import argparse, csv, os, collections, re

HERE = os.path.dirname(os.path.abspath(__file__))

def fnum(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None

def scaling_class(rows):
    """rows: list of result dicts for one command, any sizes."""
    ok = sorted([(int(r["N"]), fnum(r["seconds"])) for r in rows if r["outcome"] == "OK" and fnum(r["seconds"]) is not None])
    outs = {int(r["N"]): r["outcome"] for r in rows}
    big = max((n for n, o in outs.items() if o == "OK"), default=0)
    worst = None
    if any(o in ("TIMEOUT", "MEMORY_KILLED", "CRASH") for o in outs.values()):
        worst = "timeout"
    if any(o == "REFUSED_GUARD" for o in outs.values()):
        worst = "dense-guarded"
    if any(o == "MACRO_LIMIT" for o in outs.values()):
        worst = "macro-limit"
    if len(ok) >= 2:
        (n0, t0), (n1, t1) = ok[0], ok[-1]
        if t0 is not None and t1 is not None and n1 > n0 and max(t0, .05) > 0:
            e = __import__("math").log(max(t1, .05) / max(t0, .05)) / __import__("math").log(n1 / n0)
            cls = "sparse/near-linear" if e < 1.3 else "moderate" if e < 1.8 else "quadratic or worse"
            return (cls if not worst else f"{cls}, then {worst}"), e
    if worst:
        return worst, None
    if ok and ok[-1][1] is not None:
        return ("fast at this size (single size only)" if ok[-1][1] < 1 else "slow already at this size"), None
    return "n/a", None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", default=os.path.join(HERE, "results.csv"))
    ap.add_argument("--out", default="")
    a = ap.parse_args()
    rows = list(csv.DictReader(open(a.csv)))
    by = collections.OrderedDict()
    for r in rows:
        by.setdefault(r["command"], []).append(r)
    sizes = sorted({int(r["N"]) for r in rows})
    out = []
    out.append(f"# Scaling audit results ({os.path.basename(a.csv)})\n")
    cnt = collections.Counter()
    for c, rs in by.items():
        for r in rs:
            if int(r["N"]) == max(sizes):
                cnt[r["outcome"]] += 1
    out.append(f"{len(by)} recipes; sizes run: {', '.join(map(str, sizes))}. "
               f"Outcomes at N={max(sizes)}: " + ", ".join(f"{k} {v}" for k, v in sorted(cnt.items())) + ".\n")
    out.append("Seconds are the wall time of the command only (Stata timer); memory is the peak resident "
               "set size of the whole Stata process (it includes the network build and the ~130 MB Stata base). "
               "Timings of runs that overlapped with another Stata process carry noise; see load_avg_1m in the CSV.\n")
    hdr = "| command | " + " | ".join(f"N={n}" for n in sizes) + " | peak MB (largest OK) | class |"
    out.append(hdr)
    out.append("|" + "---|" * (len(sizes) + 3))
    for c, rs in by.items():
        d = {int(r["N"]): r for r in rs}
        cells = []
        for n in sizes:
            r = d.get(n)
            if not r:
                cells.append("-")
            elif r["outcome"] == "OK":
                cells.append(f'{fnum(r["seconds"]):.2f}s')
            elif r["outcome"] == "NOT_TRIED_PREV_FAILED":
                cells.append("skipped")
            else:
                cells.append(r["outcome"])
        okn = [n for n in sizes if n in d and d[n]["outcome"] == "OK"]
        mem = d[okn[-1]]["peak_mem_mb"] if okn else ""
        cls, e = scaling_class(rs)
        out.append(f"| `{c}` | " + " | ".join(cells) + f" | {mem} | {cls} |")
    out.append("")
    bad = [(c, r) for c, rs in by.items() for r in rs if r["outcome"] not in ("OK", "NOT_TRIED_PREV_FAILED", "NOT_TRIED_CAP")]
    if bad:
        out.append("## Failures and messages\n")
        out.append("| command | N | outcome | rc | message |")
        out.append("|---|---|---|---|---|")
        for c, r in bad:
            out.append(f'| `{c}` | {r["N"]} | {r["outcome"]} | {r["rc"]} | {r["message"][:140].replace("|", "/")} |')
        out.append("")
    txt = "\n".join(out)
    if a.out:
        open(a.out, "w").write(txt)
    else:
        print(txt)

if __name__ == "__main__":
    main()
