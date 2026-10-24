#!/usr/bin/env python3
"""check_help_index.py -- check nwtopical.sthlp and nwalphabetical.sthlp against the help files of the core (exit 1 on a problem).

 1. every {help X} entry of the two lists has a help file X.sthlp in the core;
 2. every core command (X.ado, not starting with "_") with a help file is listed in both lists;
 3. every other help file with a {marker topic} (topic pages without .ado) is listed in nwtopical;
 4. the four model packages are listed in both lists as web links, not as {help} links;
 5. every file named in _pkg_hlp.txt exists.
Help files without .ado and without {marker topic} are landing/companion pages (DOC_ONLY below), never listed.
If this fails after adding a command: give its help file a {marker topic} line, then regenerate with _nwdeploy (see GOTCHA.md).
"""
import re, os, glob, sys
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(root)
MODELS = ["nwsaom", "nwergm", "nwdynam", "nwrem"]
DOC_ONLY = {"nwcommands", "nwintro", "nwstart", "nwtopical", "nwalphabetical", "nwprogramming", "nwinternals", "nwtab1", "nwtab2", "nwtab3"}
NOT_A_COMMAND = {"nwinstall_models"}   # worker of "nwinstall, models", documented in nwinstall.sthlp
bad = []
def names(path):
    s = open(path, encoding="utf-8", errors="replace").read()
    return set(re.findall(r'\{p2col:\s*\{bf:\{help (\S+) \}\}', s)), set(re.findall(r'\{bf:\{browse "https://nwcommands\.org/(\w+)/":', s))
top_help, top_web = names("nwtopical.sthlp"); alp_help, alp_web = names("nwalphabetical.sthlp")
sthlp = {f[:-6] for f in glob.glob("*.sthlp")}; ado = {f[:-4] for f in glob.glob("*.ado")}
cmds = {c for c in ado if not c.startswith("_") and c not in NOT_A_COMMAND and c in sthlp}
def hastopic(c): return "{marker topic}" in open(c + ".sthlp", encoding="utf-8", errors="replace").read()
topics = {c for c in sthlp if not c.startswith("_") and c not in ado and c not in DOC_ONLY and c not in MODELS}
for lst, name in ((top_help, "nwtopical"), (alp_help, "nwalphabetical")):
    for c in sorted(lst):
        if c not in sthlp and c not in NOT_A_COMMAND and not (c in ado or c.startswith("_")):
            bad.append(f"{name}: lists {{help {c}}} but {c}.sthlp does not exist")
for c in sorted(cmds):
    if c not in top_help: bad.append(f"{c}: has .ado and .sthlp but is missing from nwtopical (check its {{marker topic}} block)")
    if c not in alp_help: bad.append(f"{c}: has .ado and .sthlp but is missing from nwalphabetical")
for c in sorted(topics):
    if not hastopic(c): bad.append(f"{c}.sthlp: no .ado and no {{marker topic}}: add it to DOC_ONLY in this script or give it a topic")
    elif c not in top_help: bad.append(f"{c}.sthlp: has a topic but is missing from nwtopical")
for m in MODELS:
    for lst, web, name in ((top_help, top_web, "nwtopical"), (alp_help, alp_web, "nwalphabetical")):
        if m not in web: bad.append(f"{name}: model package {m} is not listed with its web link")
        if m in lst: bad.append(f"{name}: {m} must not be a {{help}} link (the model packages are not in the core)")
for l in open("_pkg_hlp.txt"):
    if l.startswith("f ") and not os.path.exists(l[2:].strip()): bad.append(f"_pkg_hlp.txt: {l[2:].strip()} does not exist")
if bad:
    print("help index problems:"); print("\n".join("  " + b for b in bad)); sys.exit(1)
print(f"help index consistent: {len(cmds)} commands + {len(topics)} topic pages + {len(MODELS)} model packages listed in nwtopical and nwalphabetical")
