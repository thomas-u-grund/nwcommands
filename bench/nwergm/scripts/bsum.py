import sys, statistics as st, collections
def load(f):
    d=collections.OrderedDict()
    try:
        for l in open(f):
            p=l.strip().split(',')
            if len(p)<3 or p[2]=='TIMEOUT': d.setdefault(p[0],[]).append(None); continue
            d.setdefault(p[0],[]).append((float(p[2]), p[3], p[4], p[5]))
    except FileNotFoundError: pass
    return d
files=sys.argv[1:]
data=[load(f) for f in files]
models=list(data[0].keys()) if data[0] else []
for m in models:
    row=[m]
    for d in data:
        v=d.get(m)
        if not v: row.append('-'); continue
        if None in v: row.append('TIMEOUT'); continue
        its=[x[1] for x in v]
        row.append('%.2f (it %s)'%(st.median(x[0] for x in v), ','.join(its)))
    print('  '.join(row))
