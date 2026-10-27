import csv, statistics as st, collections
rows=list(csv.DictReader(open('idle_all.csv')))
se=collections.defaultdict(list)
for r in csv.DictReader(open('r_se.csv')): se[r['model']].append(float(r['se']))
M=["B1","B2","B3","B4","B5","B6","Lazega","Mesa"]
res={}
for m in M:
    est={}
    for i in ("R","v123","v130"):
        v=[[float(x) for x in r['estimates'].split(';')] for r in rows if r['model']==m and r['impl']==i]
        est[i]=[st.mean(c) for c in zip(*v)]
        est[i+'sd']=[st.stdev(c) for c in zip(*v)]
    s=se[m]; assert len(s)==len(est['R'])==len(est['v130']),m
    for i in ("v123","v130"):
        d=[(a-b)/c for a,b,c in zip(est[i],est['R'],s)]
        res[(m,i)]=max(abs(x) for x in d)
    res[(m,'sdR')]=max(a/c for a,c in zip(est['Rsd'],s))
    res[(m,'sd130')]=max(a/c for a,c in zip(est['v130sd'],s))
if __name__=="__main__":
    for m in M: print(m, "max|mean diff|/SE_R: 1.2.3 %.2f  1.3.0 %.2f ; max seed-sd/SE R %.2f 1.3.0 %.2f"%(res[(m,'v123')],res[(m,'v130')],res[(m,'sdR')],res[(m,'sd130')]))
