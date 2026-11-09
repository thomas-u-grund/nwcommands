#!/usr/bin/env python3
"""make_help_index.py -- write nwtopical.sthlp and nwalphabetical.sthlp from the help files of the core.

Each command's help file gives its section in the line after {marker topic}, e.g.
    {helpb nwtopical##analysis_centrality:[NW-2.6.1] Centrality}
and its one-line description in its title, e.g.
    {p2col :nwdegree {hline 2}}Degree centrality and distribution{p_end}
Sections are ordered by their number; [NW-2.6.x] are the subsections of Analysis.
Help files whose name starts with "_" are internal and not listed. Run from anywhere; then run
tools/check_help_index.py. The version footer is written by tools/set_version.py.
"""
import glob, os, re
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(root)

MODELS = [
    ("nwsaom", "Stochastic actor-oriented models (SAOM): network and behavior dynamics between observed waves"),
    ("nwergm", "Exponential random graph models (ERGM) for cross-sectional networks"),
    ("nwdynam", "Dynamic network actor models (DyNAM): choice and rate models for event sequences"),
    ("nwrem", "Relational event models (REM) for timed interaction events"),
]
NOT_A_COMMAND = {"nwinstall_models"}
MODELS_INTRO = ('{pstd}\nThe statistical network models are separate packages that need the core. Install them with\n'
                '{stata "nwinstall, models":nwinstall, models} (see {help nwinstall}; {help nwversion} shows which are installed).\n'
                'Which package do you need? See {browse "https://nwcommands.org/which-package/"}.\n{p_end}\n')

def read(f): return open(f, encoding="utf-8", errors="replace").read()

def footer_of(path):
    s = read(path) if os.path.exists(path) else ""
    i = s.rfind("\n{hline}\n{pstd}{it:nwcommands version")
    return s[i:] if i >= 0 else "\n"

def header_of(path):
    s = read(path) if os.path.exists(path) else ""
    m = re.match(r"\{smcl\}\n(\{\* \*! version[^\n]*\n)", s)
    return m.group(1) if m else ""

def desc(cmd):
    for line in read(cmd + ".sthlp").split("\n"):
        j = line.find("{hline 2}}")
        if j >= 0:
            d = line[j + len("{hline 2}}"):]
            return d[:-len("{p_end}")] if d.endswith("{p_end}") else d
    raise SystemExit(f"{cmd}.sthlp: no title line with {{hline 2}}")

def topic(cmd):
    m = re.search(r"\{marker topic\}\n\{helpb nwtopical##(\w+):\[NW-([\d.]+)\] ([^}]*)\}", read(cmd + ".sthlp"))
    return (m.group(1), m.group(2), m.group(3)) if m else None

def box(title):
    w = max(24, len(title) + 14)
    return ("\n{col 8}   {c TLC}{hline %d}{c TRC}\n{col 8}{hline 3}{c RT}       {it:%s}{col %d}{c LT}{hline}\n"
            "{col 8}   {c BLC}{hline %d}{c BRC}\n" % (w, title, 12 + w, w))

helpfiles = sorted(f[:-6] for f in glob.glob("*.sthlp") if not f.startswith("_"))
ados = {f[:-4] for f in glob.glob("*.ado")}

# ---- topical
secs = {}
for c in helpfiles:
    t = topic(c)
    if t: secs.setdefault((t[1], t[0], t[2]), []).append(c)
key = lambda k: tuple(int(x) for x in k[0].split("."))
order = sorted(secs, key=key)
out = ["{smcl}", header_of("nwtopical.sthlp").rstrip("\n"), "{phang}",
       "{help nwcommands:NW-2 topical} {hline 2} Topical list of network commands", "", "{title:Contents}", "",
       "{col 14}Section{col 33}Description", "{col 14}{hline 50}"]
analysis = False
for num, mk, title in order:
    if num.count(".") == 2:
        if not analysis:
            out.append("{help nwtopical##analysis:{col 14}{bf:[NW-2.6]}{col 33}{bf:Analysis}}"); analysis = True
        out.append("{help nwtopical##%s:{col 16}[NW-%s]{col 35}%s}" % (mk, num, title))
    else:
        out.append("{help nwtopical##%s:{col 14}{bf:[NW-%s]}{col 33}{bf:%s}}" % (mk, num, title))
out.append("{help nwtopical##models:{col 14}{bf:[NW-2.10]}{col 33}{bf:Statistical models (separate packages)}}")
out.append("")
analysis = False
for k in order:
    num, mk, title = k
    if num.count(".") == 2:
        if not analysis:
            out += [""]; out.append("{marker analysis}{...}" + box("Analysis").rstrip("\n")); analysis = True
        out += ["", "{marker %s}{...}" % mk, "{p 11 11 2}{bf:{it:%s}}{p_end}" % title]
    else:
        out += [""]; out.append("{marker %s}{...}" % mk + box(title).rstrip("\n"))
    out.append("{p2colset 12 35 36 2}")
    out += ["{p2col:    {bf:{help %s }}}%s{p_end}" % (c, desc(c)) for c in secs[k]]
out += [""]; out.append("{marker models}{...}" + box("Statistical models (separate packages)").rstrip("\n"))
out += ["", MODELS_INTRO.rstrip("\n"), "", "{p2colset 12 35 36 2}"]
out += ['{p2col:    {bf:{browse "https://nwcommands.org/%s/":%s}}}%s{p_end}' % (m, m, d) for m, d in MODELS]
out.append("{p2colreset}{...}")
open("nwtopical.sthlp", "w", encoding="utf-8").write("\n".join(l for l in out if l is not None) + footer_of("nwtopical.sthlp"))

# ---- alphabetical
rows = [(c, "{p2col:{bf:{help %s }}}%s{p_end}" % (c, desc(c)))
        for c in helpfiles if c in ados and c not in NOT_A_COMMAND]
rows += [(m, '{p2col:{bf:{browse "https://nwcommands.org/%s/":%s}}}%s (separate package){p_end}' % (m, m, d)) for m, d in MODELS]
rows.sort()
out = ["{smcl}", header_of("nwalphabetical.sthlp").rstrip("\n"), "{phang}",
       "{help nwcommands:NW-3 alphabetical} {hline 2} Alphabetical list of network commands", "",
       "{col 5}{hline}", "{p2colset 5 32 34 2}"] + [r for _, r in rows] + ["{p2colreset}{...}", "", MODELS_INTRO.rstrip("\n")]
open("nwalphabetical.sthlp", "w", encoding="utf-8").write("\n".join(out) + footer_of("nwalphabetical.sthlp"))
print(f"nwtopical: {sum(len(v) for v in secs.values())} entries in {len(order)} sections; nwalphabetical: {len(rows)} entries")
