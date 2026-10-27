import csv, statistics as st, collections, sys
rows=list(csv.DictReader(open('idle_all.csv')))
M=["B1","B2","B3","B4","B5","B6","Lazega","Mesa"]; I=["R","v123","v130"]
d=collections.defaultdict(list)
bad=[r for r in rows if r['rc']!='0']
for r in rows:
    if r['rc']=='0': d[(r['model'],r['impl'])].append(r)
def med(m,i): return st.median([float(r['secs']) for r in d[(m,i)]])
out={}
for m in M:
    for i in I:
        v=[float(r['secs']) for r in d[(m,i)]]; it=[int(r['iter']) for r in d[(m,i)]]
        cv=sum(int(r['converged']) for r in d[(m,i)])
        out[(m,i)]=(len(v),st.median(v),min(v),max(v),min(it),max(it),cv)
loads=[float(r['load1']) for r in rows]
if __name__=="__main__":
    print("bad rows",len(bad))
    for m in M:
        s=[out[(m,i)] for i in I]
        print(m, " | ".join("%d: %.3g (%.3g-%.3g) it %d-%d conv %d"%x for x in s), "ratioR/130 %.2f  123/130 %.1f  130/R %.2f"%(s[0][1]/s[2][1], s[1][1]/s[2][1], s[2][1]/s[0][1]))
    print("load min/med/mean/max", min(loads), st.median(loads), st.mean(loads), max(loads), len(loads))
    for i in I: 
        l=[float(r['load1']) for r in rows if r['impl']==i]; print(i, st.mean(l))
