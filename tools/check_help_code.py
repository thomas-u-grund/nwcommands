#!/usr/bin/env python3
"""Compare each help file with its command's code: options, stored results, numeric defaults.

Usage: python3 tools/check_help_code.py [dir] [command ...]     (default: current directory, all commands)

For <cmd>.sthlp it reads <cmd>.ado (and the .ado files of programs that <cmd>.ado calls whose names start
with _<cmd> or <cmd>_), and reports
  OPT-UNDOC   an option of the syntax statement that the help file never mentions as {opt ...}/{opth ...}
  OPT-GONE    an option listed in the help file's option table ({synopt:...}) that no syntax statement accepts
  RES-UNDOC   an r()/e() result the code returns that the help file does not mention
  RES-GONE    an r()/e() result listed under Stored results that the code never returns
  DEFAULT     the help text of an option says "default N" but the syntax statement has another default
It is a screening tool: every line is a candidate to read, not a verdict (options can be parsed by hand,
results can be returned by a called program). Exit status 0.
"""
import os, re, sys

SYN = re.compile(r'^\s*syntax\b(.*)$')


def ado_text(d, cmd):
    files = []
    p = os.path.join(d, cmd + '.ado')
    if os.path.exists(p):
        files.append(p)
    for f in sorted(os.listdir(d)):
        if f.endswith('.ado') and (f.startswith('_' + cmd) or f.startswith(cmd + '_')) and os.path.join(d, f) not in files:
            files.append(os.path.join(d, f))
    txt = ''
    for f in files:
        txt += open(f, encoding='utf-8', errors='replace').read() + '\n'
    return txt, files


def syntax_options(txt):
    """{name: default or None} from all syntax statements (with /// continuations)."""
    lines = txt.split('\n')
    opts = {}
    i = 0
    while i < len(lines):
        m = SYN.match(lines[i])
        if m and not lines[i].lstrip().startswith('*'):
            s = m.group(1)
            while s.rstrip().endswith('///') and i + 1 < len(lines):
                s = s.rstrip()[:-3] + ' ' + lines[i + 1].strip()
                i += 1
            s = re.sub(r'//.*$', '', s)
            if ',' in s:
                part = s[s.index(',') + 1:]
                part = part.replace('[', ' ').replace(']', ' ').replace('*', ' ')
                for tok in re.finditer(r'([A-Za-z_][A-Za-z0-9_]*)(\(([^()]*(?:\([^()]*\))?[^()]*)\))?', part):
                    name = tok.group(1)
                    arg = tok.group(3)
                    full = name.lower()
                    dflt = None
                    if arg:
                        a = arg.split()
                        if len(a) >= 2 and re.match(r'^-?[0-9.]+$', a[-1]):
                            dflt = a[-1]
                    opts.setdefault(full, dflt)
        i += 1
    return opts


def help_info(path):
    s = open(path, encoding='utf-8', errors='replace').read()
    mentioned = set(m.group(1).lower() for m in re.finditer(r'\{opth?\s+([A-Za-z_][A-Za-z0-9_]*)', s))
    mentioned |= set(m.group(1).lower() for m in re.finditer(r'\{cmd:([a-z_][a-z0-9_]*)\(', s))
    mentioned |= set(m.group(1).lower() for m in re.finditer(r'\{cmd:,?\s*([a-z_][a-z0-9_]*)\}', s))
    table = {}
    for m in re.finditer(r'^\{synopt:\{opth?\s+([A-Za-z_][A-Za-z0-9_]*)[^}]*\}[^\n]*?\}(.*)$', s, re.M):
        table[m.group(1).lower()] = m.group(2)
    # stored results section
    res_doc = set()
    sec = re.search(r'\{title:Stored results\}(.*?)(\{title:|\Z)', s, re.S)
    if sec:
        res_doc = set(re.findall(r'\b([re])\(([A-Za-z_][A-Za-z0-9_]*)\)', sec.group(1)))
    res_any = set(re.findall(r'\b([re])\(([A-Za-z_][A-Za-z0-9_]*)\)', s))
    return mentioned, table, res_doc, res_any, s


def code_results(txt):
    out = set()
    for m in re.finditer(r'^\s*(e?return)\s+(scalar|local|matrix|hidden scalar|hidden local)\s+([A-Za-z_][A-Za-z0-9_]*)', txt, re.M):
        out.add(('e' if m.group(1) == 'ereturn' else 'r', m.group(3)))
    for m in re.finditer(r'st_(?:num)?(?:scalar|global|matrix)\(\s*"([re])\(([A-Za-z_][A-Za-z0-9_]*)\)"', txt):
        out.add((m.group(1), m.group(2)))
    return out


def unabbrev_match(name, opts):
    return name in opts or any(o.startswith(name) or name.startswith(o) for o in opts)


def main(argv):
    d = argv[0] if argv and os.path.isdir(argv[0]) else '.'
    cmds = argv[1:] if argv and os.path.isdir(argv[0]) else argv
    if not cmds:
        cmds = sorted(f[:-6] for f in os.listdir(d) if f.endswith('.sthlp'))
    n = 0
    for cmd in cmds:
        hp = os.path.join(d, cmd + '.sthlp')
        if not os.path.exists(hp) or not os.path.exists(os.path.join(d, cmd + '.ado')):
            continue
        txt, files = ado_text(d, cmd)
        opts = syntax_options(txt)
        mentioned, table, res_doc, res_any, s = help_info(hp)
        for o in sorted(opts):
            if o in ('replace',) and 'replace' in s:
                continue
            if not any(m == o or o.startswith(m) or m.startswith(o) for m in mentioned) and o not in s:
                print('%s: OPT-UNDOC %s' % (cmd, o)); n += 1
        for o in sorted(table):
            if not unabbrev_match(o, opts) and not unabbrev_match('no' + o, opts) and not (o.startswith('no') and unabbrev_match(o[2:], opts)):
                print('%s: OPT-GONE %s' % (cmd, o)); n += 1
            m = re.search(r'default(?:s)?\s*(?:is|=|:)?\s*(-?[0-9][0-9,]*\.?[0-9]*)', table[o])
            sd = opts.get(o)
            if m and sd is not None:
                hv = m.group(1).replace(',', '').rstrip('.')
                try:
                    if float(hv) != float(sd):
                        print('%s: DEFAULT %s help says %s, syntax %s' % (cmd, o, hv, sd)); n += 1
                except ValueError:
                    pass
        cres = code_results(txt)
        for k, r in sorted(cres):
            if (k, r) not in res_any:
                print('%s: RES-UNDOC %s(%s)' % (cmd, k, r)); n += 1
        for k, r in sorted(res_doc):
            if (k, r) not in cres and r not in txt:
                print('%s: RES-GONE %s(%s)' % (cmd, k, r)); n += 1
    print('%d candidates' % n)


if __name__ == '__main__':
    main(sys.argv[1:])
