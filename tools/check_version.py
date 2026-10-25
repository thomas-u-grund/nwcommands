#!/usr/bin/env python3
"""check_version.py -- verify that every display of the nwcommands core version agrees with VERSION (exit 1 on a mismatch)."""
import re, os, glob, sys
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(root)
ver, date = open("VERSION").read().split()[:2]
import datetime
longdate = datetime.datetime.strptime(date, "%d%b%Y").strftime("%-d %B %Y")
bad = []
def need(path, pat, what):
    s = open(path).read()
    if not re.search(pat, s): bad.append(f"{path}: {what}")
need("nwversion.ado", r'local nwv "%s"' % re.escape(ver), "nwv constant")
need("nwversion.ado", r'local nwd "%s"' % re.escape(date), "nwd constant")
need("nwversion.ado", r'^\*! version %s  %s' % (re.escape(ver), date), "first line")
HEADER_FILES = ["nwversion.sthlp", "nwcommands.sthlp", "nwintro.sthlp", "nwstart.sthlp", "nwtopical.sthlp", "nwalphabetical.sthlp"]
for h in HEADER_FILES:
    need(h, r'\{\* \*! version %s  %s\}' % (re.escape(ver), date), "header")
want = '{pstd}{it:nwcommands version %s, %s} ({help nwversion:check your installed version}){p_end}{* nwversion}' % (ver, longdate)
for h in sorted(glob.glob("*.sthlp")):   # every help file ends with the same footer, exactly once
    L = open(h, newline='').read().replace("\r\n", "\n").rstrip("\n").split("\n")
    vis = [i for i, l in enumerate(L) if re.match(r'\{pstd\}\{it:nwcommands version ', l)]
    if len(vis) != 1: bad.append(f"{h}: expected exactly one version line, found {len(vis)}")
    elif vis[0] != len(L) - 1: bad.append(f"{h}: the version line must be the very last line (is line {vis[0]+1} of {len(L)}; a leftover top line?)")
    elif L[-1] != want: bad.append(f"{h}: last line is not exactly: {want}")
    elif L[-2] != "{hline}" or L[-3].strip() != "": bad.append(f"{h}: the version line must be preceded by a blank line and {{hline}}")
for p in glob.glob("nwcommands*.pkg"):
    need(p, r'(?m)^d Distribution-Date: %s$' % date, "Distribution-Date"); need(p, r'(?m)^d Version: %s$' % re.escape(ver), "Version")
need("stata.toc", r'version %s' % re.escape(ver), "toc")
need("CITATION.cff", r'(?m)^version: "%s"' % re.escape(ver), "CITATION version")
need("CHANGELOG.md", r'## \[%s\]' % re.escape(ver), "CHANGELOG entry")
import subprocess
if subprocess.call([sys.executable, os.path.join("tools", "check_help_index.py")]) != 0: bad.append("tools/check_help_index.py failed (see above)")
# the Mata library of the core against the hash recorded at the last release (a warning, not a failure)
import hashlib
_lib, _rec = os.path.join("lib", "lnwcommands.mlib"), os.path.join("lib", "lnwcommands.mlib.release.sha256")
if os.path.exists(_lib) and os.path.exists(_rec):
    if hashlib.sha256(open(_lib, "rb").read()).hexdigest() != open(_rec).read().split()[0]:
        print("\n" + "*" * 100 + "\nWARNING: Mata library changed: rebuild and re-release nwsaom and nwergm in step\n"
              "  (lib/lnwcommands.mlib differs from the hash recorded at the last release, lib/lnwcommands.mlib.release.sha256;\n"
              "   nwdynam and nwrem too if their libraries use changed classes; see 'Whenever the core library changes' in RELEASING.md)\n"
              "  After the release run: python3 tools/record_release_hash.py\n" + "*" * 100 + "\n")
elif os.path.exists(_lib):
    print("WARNING: lib/lnwcommands.mlib.release.sha256 is missing: run python3 tools/record_release_hash.py")
if bad: print("\n".join(bad)); sys.exit(1)
print("version display consistent:", ver, date)
