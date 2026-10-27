import csv, collections, statistics as st, re, sys
def load(f):
    d = collections.OrderedDict()
    for r in csv.DictReader(open(f)):
        d.setdefault(r['model'], collections.OrderedDict()).setdefault(r['term'], []).append(r)
    return d
R = load('cmp_r.csv'); O = load('cmp_old.csv'); N = load(sys.argv[1] if len(sys.argv)>1 else 'cmp_new.csv')
norm = lambda x: re.sub(r'[^a-z0-9]', '', x.lower())
print("%-14s %-24s %9s %9s %9s | %7s %7s | %7s %7s | %6s %6s" % ("model","term","R mean","old mean","new mean","dOld","dNew","seR","seNew","t_old","t_new"))
alld_old=[]; alld_new=[]
for m in R:
    if m not in O or m not in N: continue
    rt = list(R[m].keys()); ot = list(O[m].keys()); nt = list(N[m].keys())
    if len(rt)!=len(ot) or len(rt)!=len(nt): print(m,"term mismatch",rt,ot,nt); continue
    for j in range(len(rt)):
        rb=[float(r['b']) for r in R[m][rt[j]]]; rse=[float(r['se']) for r in R[m][rt[j]]]
        ob=[float(r['b']) for r in O[m][ot[j]]]; nb=[float(r['b']) for r in N[m][nt[j]]]
        nse=[float(r['se']) for r in N[m][nt[j]]]
        ts=lambda L: st.mean(float(r['secs']) for r in L) if L else float('nan')
        se=st.mean(rse)
        do=(st.mean(ob)-st.mean(rb))/se; dn=(st.mean(nb)-st.mean(rb))/se
        if m not in ('toy',) : pass
        alld_old.append(abs(do)); alld_new.append(abs(dn))
        print("%-14s %-24s %9.4f %9.4f %9.4f | %7.3f %7.3f | %7.4f %7.4f | %6.2f %6.2f" % (m, rt[j][:24], st.mean(rb), st.mean(ob), st.mean(nb), do, dn, se, st.mean(nse), ts(O[m][ot[j]]), ts(N[m][nt[j]])))
print("max|d| old %.3f new %.3f ; mean|d| old %.3f new %.3f" % (max(alld_old), max(alld_new), st.mean(alld_old), st.mean(alld_new)))
