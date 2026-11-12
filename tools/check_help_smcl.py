#!/usr/bin/env python3
"""Static checks of SMCL help files (.sthlp) for the layout faults that break Stata's help Viewer.

Usage: python3 tools/check_help_smcl.py [files or directories ...]   (default: *.sthlp of the current directory)
Exit status 1 when a fault is found. Works for the core and for the model packages (pass their directory).

Checks (each one cost a debugging session; see GOTCHA.md, "Help files that render as one block"):
  1. a {synopt:}/{p2col:} entry that is not closed by {p_end} before the next entry starts
  2. braces that do not balance within a paragraph
  3. a paragraph directive ({pstd}, {phang}, {p ...}) that follows a paragraph that is still open: from there on Stata
     no longer ends paragraphs at blank lines, and the rest of the file runs together with markup printed literally
  4. a directive argument that runs over a line break ({it:... newline ...}); it is printed literally
  5. {help a}/{help b}: the second link is printed literally (write {help a} / {help b})
  6. source lines longer than 255 characters: the Viewer drops text in them (the console does not)
  7. tab-indented plain lines wider than 80 columns outside examples: they do not wrap
"""
import os, re, sys

PSTART = re.compile(r'^\{(pstd|phang|phang2|pmore|pmore2|pin|psee|p\s|p\})')
PARA = re.compile(r'^\{(pstd|phang|phang2|pmore|pmore2|pin|psee|p\s|p\}|p\d|synopt:|p2col:|p2col\s|syntab)')


def vis(s):
    for _ in range(4):
        s = re.sub(r'\{[a-z]+[0-9]*(?:\s[^{}:]*)?:([^{}]*)\}', r'\1', s)
    return re.sub(r'\{[^{}]*\}', '', s)


def check(f):
    out = []
    L = open(f, encoding='utf-8', errors='replace').read().split('\n')
    entry = None
    inpara = False

    for i, l in enumerate(L, 1):
        s = l.strip()
        # 1
        if l.startswith(('{synopt:', '{p2col:')):
            if entry:
                out.append((entry, 'entry not closed by {p_end} before line %d' % i))
            entry = i
        elif l.startswith('{') and not l.startswith(('{opt', '{cmd', '{it', '{bf', '{help', '{c ')):
            entry = None
        if entry and ('{p_end}' in l or not s):
            entry = None
        # 3
        if PSTART.match(l) and inpara and i > 1 and L[i - 2].strip() and not L[i - 2].rstrip().endswith(('{p_end}', '{...}')):
            out.append((i, 'paragraph directive while the previous paragraph is still open (end it with {p_end})'))
        was_inpara = inpara
        if not s:
            inpara = False
        elif PARA.match(l):
            inpara = True
        if '{p_end}' in l:
            inpara = False
        # 2 and 4
        d = 0
        for ch in l:
            d += (ch == '{') - (ch == '}')
        if d > 0 and not l.startswith('{*') and '{cmd:.' not in l and i < len(L) and L[i].strip():
            out.append((i, 'directive argument continues on the next line'))
        # 5
        if re.search(r'\}/\{help ', l):
            out.append((i, '{help a}/{help b}: write {help a} / {help b}'))
        # 6
        if len(l) > 255:
            out.append((i, 'source line of %d characters (keep below 256)' % len(l)))
        # 7
        if l.startswith('\t') and not was_inpara and '{cmd:.' not in l and '{bf:.' not in l and not s.startswith('.') and not l.startswith('\t\t') and not any(
                t in l for t in ('{com}', '{res}', '{txt}', '{col', '{c |}')) and len(vis(l).expandtabs(8)) > 80:
            out.append((i, 'tab-indented line wider than 80 columns does not wrap'))
    return out


def main(args):
    files = []
    for a in args or ['.']:
        if os.path.isdir(a):
            files += sorted(os.path.join(a, x) for x in os.listdir(a) if x.endswith('.sthlp'))
        else:
            files.append(a)
    n = 0
    for f in files:
        for line, msg in check(f):
            print('%s:%d: %s' % (f, line, msg))
            n += 1
    print('%d help files checked, %d faults' % (len(files), n))
    return 1 if n else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
