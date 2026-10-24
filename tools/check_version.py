#!/usr/bin/env python3
"""check_version.py -- verify that every display of the nwcommands core version agrees with VERSION (exit 1 on a mismatch)."""
import re, os, glob, sys
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(root)
ver, date = open("VERSION").read().split()[:2]
bad = []
def need(path, pat, what):
    s = open(path).read()
    if not re.search(pat, s): bad.append(f"{path}: {what}")
need("nwversion.ado", r'local nwv "%s"' % re.escape(ver), "nwv constant")
need("nwversion.ado", r'local nwd "%s"' % re.escape(date), "nwd constant")
need("nwversion.ado", r'^\*! version %s  %s' % (re.escape(ver), date), "first line")
for h in ["nwversion.sthlp", "nwcommands.sthlp", "nwintro.sthlp", "nwstart.sthlp"]:
    need(h, r'\{\* \*! version %s  %s\}' % (re.escape(ver), date), "header")
    need(h, r'nwcommands version %s,' % re.escape(ver), "visible version line")
for p in glob.glob("nwcommands*.pkg"):
    need(p, r'(?m)^d Distribution-Date: %s$' % date, "Distribution-Date"); need(p, r'(?m)^d Version: %s$' % re.escape(ver), "Version")
need("stata.toc", r'version %s' % re.escape(ver), "toc")
need("CITATION.cff", r'(?m)^version: "%s"' % re.escape(ver), "CITATION version")
need("CHANGELOG.md", r'## \[%s\]' % re.escape(ver), "CHANGELOG entry")
if bad: print("\n".join(bad)); sys.exit(1)
print("version display consistent:", ver, date)
