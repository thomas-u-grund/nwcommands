#!/usr/bin/env python3
"""Generates gen_effects.tex (the effects reference), gen_missing.tex (what RSiena has and nwsaom does not yet) and gen_counts.tex
from the effects inventory (docs/SAOM_EFFECTS_INVENTORY.csv, which is gitignored: pass its path as argv[1])."""
import csv, sys, re, collections
src = sys.argv[1] if len(sys.argv) > 1 else "../../../docs/SAOM_EFFECTS_INVENTORY.csv"
rows = list(csv.DictReader(open(src)))

def tex(s):
    s = s or ""
    s = s.replace("\\", "\\textbackslash{}")
    for a, b in (("&", "\\&"), ("%", "\\%"), ("$", "\\$"), ("#", "\\#"), ("_", "\\_"), ("{", "\\{"), ("}", "\\}"), ("~", "\\~{}"), ("^", "\\^{}")):
        s = s.replace(a, b)
    s = s.replace("\\textbackslash\\{\\}", "\\textbackslash{}")
    return s
def tt(s):
    return "\\texttt{" + tex(s) + "}" if s else ""
def shorten(s, n):
    s = (s or "").strip()
    return s if len(s) <= n else s[:n - 1] + "\u2026"

def st(x):
    return x["nwsaom_status"].split(" (")[0]
cnt = collections.Counter(st(x) for x in rows)
plannable = len(rows) - cnt["NOT PLANNED"]
with open("gen_counts.tex", "w") as f:
    f.write("\\newcommand{\\nImpl}{%d}\\newcommand{\\nPartial}{%d}\\newcommand{\\nNotImpl}{%d}\\newcommand{\\nNotPlanned}{%d}\\newcommand{\\nTotal}{%d}\\newcommand{\\nPlannable}{%d}\\newcommand{\\pctImpl}{%.0f}\n"
            % (cnt["IMPLEMENTED"], cnt["PARTIAL"], cnt["NOT IMPLEMENTED"], cnt["NOT PLANNED"], len(rows), plannable, 100.0 * cnt["IMPLEMENTED"] / plannable))

# ---- the effects reference: implemented rows, by section
bysec = collections.OrderedDict()
for x in rows:
    bysec.setdefault(x["section"], []).append(x)
with open("gen_effects.tex", "w") as f:
    for sec, xs in sorted(bysec.items()):
        done = [x for x in xs if st(x) in ("IMPLEMENTED", "PARTIAL")]
        if not done:
            continue
        f.write("\\subsection*{%s}\n" % tex(sec))
        f.write("\\footnotesize\n\\begin{longtable}{@{}p{2.6cm}p{3.2cm}p{2.9cm}p{5.4cm}@{}}\n\\toprule\nRSiena name & Network / context & Validated & nwsaom option\\\\\n\\midrule\n\\endhead\n")
        for x in done:
            ctx = x["variable_type"] + ((" + " + x["interaction_context"]) if x["interaction_context"] else "")
            opt = re.sub(r"^IMPLEMENTED \(as (.*)\)$", r"\1", x["nwsaom_status"])
            if opt == x["nwsaom_status"] or opt.startswith("IMPLEMENTED") or opt.startswith("PARTIAL"):
                opt = x["nwsaom_option"] or ("(partial)" if st(x) == "PARTIAL" else "")
            val = {"yes": "siena07", "unknown": "", "": ""}.get(x["validated_against_RSiena"], x["validated_against_RSiena"])
            f.write("%s & %s & %s & %s\\\\\n" % (tt(x["RSiena_shortName"]), tex(shorten(ctx, 60)), tex(val), tt(shorten(opt, 90))))
        f.write("\\bottomrule\n\\end{longtable}\n\\normalsize\n\n")

# ---- what RSiena has and nwsaom does not (yet)
def reason(x):
    t, c, n = x["variable_type"], x["interaction_context"], x["notes"]
    name = x["RSiena_shortName"]
    if t.startswith("gmm") or "gmm" in name.lower():
        return "GMoM statistics (the generalised method of moments estimator is not implemented)"
    if x["section"].startswith("O."):
        return "RSiena's settings model (a different simulation procedure)"
    if "another network" in c and ("behavior" in c.lower() and "behavior variable" in c):
        return "cross-network effects that also involve a behavior variable (needs behavior inside nwsaom multinet)"
    if t.startswith("two-mode") and "another network" in c:
        return "several networks with a two-mode member (nwsaom multinet supports directed and non-directed members only)"
    if t.startswith("non-directed") and "another network" in c:
        return "non-directed network with another network: not validated or differs from siena07 (see the notes)"
    if t.startswith("rate"):
        return "rate effects (covariates on the rate of two-mode networks and behaviors, exposure and infection effects)"
    if t.startswith("behavior") and ("another network + another network" in c or "another network" in c):
        return "behavior effects of two networks / further behavior-network effects"
    return "other (see the effect notes)"
miss = [x for x in rows if st(x) == "NOT IMPLEMENTED"]
groups = collections.OrderedDict()
for x in miss:
    groups.setdefault(reason(x), []).append(x)
with open("gen_missing.tex", "w") as f:
    for g, xs in sorted(groups.items(), key=lambda kv: -len(kv[1])):
        f.write("\\subsection*{%s (%d rows)}\n" % (tex(g[0].upper() + g[1:]), len(xs)))
        f.write("\\footnotesize\n\\begin{longtable}{@{}p{2.8cm}p{4.6cm}p{6.5cm}@{}}\n\\toprule\nRSiena name & Network / context & Note\\\\\n\\midrule\n\\endhead\n")
        for x in xs:
            ctx = x["variable_type"] + ((" + " + x["interaction_context"]) if x["interaction_context"] else "")
            f.write("%s & %s & %s\\\\\n" % (tt(x["RSiena_shortName"]), tex(shorten(ctx, 70)), tex(shorten(x["notes"], 160))))
        f.write("\\bottomrule\n\\end{longtable}\n\\normalsize\n\n")
    np = [x for x in rows if st(x) == "NOT PLANNED"]
    f.write("\\subsection*{Deliberately out of scope (%d rows)}\n\\noindent Continuous (SDE) dependent variables and their effects are not part of nwsaom (%d rows of the RSiena effects table).\n\n" % (len(np), len(np)))
print(dict(cnt), len(groups))
