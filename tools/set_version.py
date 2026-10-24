#!/usr/bin/env python3
"""set_version.py [version [date]] -- write the version of the nwcommands core into every place that displays it.

Single source of truth: the file VERSION (line 1: MAJOR.MINOR.PATCH, line 2: release date in Stata format, e.g. 24oct2026).
With arguments the file is updated first. Run from the repository root.
Updates: nwversion.ado (constants and first line), nwversion.sthlp and the landing help pages (visible version line),
every nwcommands*.pkg (d Distribution-Date, d Version), stata.toc, README.md (Version line), CITATION.cff.
"""
import re, sys, os, glob, datetime
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(root)
if len(sys.argv) > 1:
    ver = sys.argv[1]
    date = sys.argv[2] if len(sys.argv) > 2 else datetime.date.today().strftime("%d%b%Y").lstrip("0").lower()
    open("VERSION", "w").write(ver + "\n" + date + "\n")
ver, date = open("VERSION").read().split()[:2]
longdate = datetime.datetime.strptime(date, "%d%b%Y").strftime("%-d %B %Y")
iso = datetime.datetime.strptime(date, "%d%b%Y").strftime("%Y-%m-%d")

def sub(path, fn):
    s = open(path).read(); t = fn(s)
    if t != s: open(path, "w").write(t)

sub("nwversion.ado", lambda s: re.sub(r'local nwv "[^"]*"', f'local nwv "{ver}"', re.sub(r'local nwd "[^"]*"', f'local nwd "{date}"',
    re.sub(r'^\*! version \S+  \S+', f'*! version {ver}  {date}', s))))
for h in ["nwversion.sthlp", "nwcommands.sthlp", "nwintro.sthlp", "nwstart.sthlp"]:
    def f(s, h=h):
        s = re.sub(r'\{\* \*! version [^}]*\}', '{* *! version %s  %s}' % (ver, date), s, count=1)
        vis = '{pstd}{it:nwcommands version %s, %s}{p_end}\n' % (ver, longdate)
        if re.search(r'\{pstd\}\{it:nwcommands version [^}]*\}\{p_end\}\n', s):
            s = re.sub(r'\{pstd\}\{it:nwcommands version [^}]*\}\{p_end\}\n', vis, s)
        elif h != "nwversion.sthlp":
            m = re.search(r'\{\* \*! version[^\n]*\n', s)
            s = s[:m.end()] + "\n" + vis + s[m.end():]
        return s
    sub(h, f)
sub("nwcommands.sthlp", lambda s: re.sub(r'\*! Version\s*:\s*\S+', '*! Version     : %s' % ver, re.sub(r'\*! Date\s*:\s*[^\n]*', '*! Date        :  %s' % longdate, s)))
for p in glob.glob("nwcommands*.pkg"):
    def f(s):
        s = re.sub(r'(?m)^d Version: .*\n', '', s)
        s = re.sub(r'(?m)^(d Distribution-Date: ).*$', r'\g<1>%s\nd Version: %s' % (date, ver), s)
        return s
    sub(p, f)
sub("stata.toc", lambda s: re.sub(r'(?m)^d nwcommands: Network Analysis for Stata.*$', 'd nwcommands: Network Analysis for Stata (version %s, %s)' % (ver, date), s))
if os.path.exists("README.md"):
    sub("README.md", lambda s: re.sub(r'(?m)^\*\*Version [^\n]*\n', '**Version %s** (%s)\n' % (ver, longdate), s))
sub("CITATION.cff", lambda s: re.sub(r'(?m)^version: .*$', 'version: "%s"' % ver, re.sub(r'(?m)^date-released: .*$', 'date-released: "%s"' % iso, s)))
print("version", ver, date)
