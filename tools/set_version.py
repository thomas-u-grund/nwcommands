#!/usr/bin/env python3
"""set_version.py [version [date]] -- write the version of the nwcommands core into every place that displays it.

Single source of truth: the file VERSION (line 1: MAJOR.MINOR.PATCH, line 2: release date in Stata format, e.g. 24oct2026).
With arguments the file is updated first. Run from the repository root.
Updates: nwversion.ado (constants and first line), nwversion.sthlp and the landing help pages (top line removed) and every other help file (footer: the visible version line as the very last lines),
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
    s = open(path, newline='').read(); t = fn(s)
    if t != s: open(path, "w", newline='').write(t)

sub("nwversion.ado", lambda s: re.sub(r'local nwv "[^"]*"', f'local nwv "{ver}"', re.sub(r'local nwd "[^"]*"', f'local nwd "{date}"',
    re.sub(r'^\*! version \S+  \S+', f'*! version {ver}  {date}', s))))
VIS_RE = r'(?m)^\{pstd\}\{it:nwcommands version [^\r\n]*\r?\n?'
HEADER_FILES = {"nwversion.sthlp", "nwcommands.sthlp", "nwintro.sthlp", "nwstart.sthlp", "nwtopical.sthlp", "nwalphabetical.sthlp"}
def footer(s, name):
    """every help file ends with: blank line, {hline}, the version line (marker {* nwversion}); an older line anywhere is removed"""
    if name in HEADER_FILES:   # the first-line comment of all other help files is left alone
        s = re.sub(r'\{\* \*! version [^}]*\}', '{* *! version %s  %s}' % (ver, date), s, count=1)
    s = re.sub(VIS_RE, '', s)
    eol = '\r\n' if '\r\n' in s else '\n'
    s = re.sub(r'(\r?\n\{hline\}[ \t]*\r?\n?|\s)+\Z', '', s) + eol   # drop trailing blank lines and a trailing bare {hline}
    return s + ('\n{hline}\n{pstd}{it:nwcommands version %s, %s} ({help nwversion:check your installed version}){p_end}{* nwversion}\n' % (ver, longdate)).replace('\n', eol)
for h in sorted(glob.glob("*.sthlp")):
    sub(h, lambda s, h=h: footer(s, h))
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
if len(sys.argv) > 1:   # a release: record the hash of the core Mata library (re-run tools/record_release_hash.py after a later rebuild of the library)
    import subprocess
    subprocess.call([sys.executable, os.path.join("tools", "record_release_hash.py")])
