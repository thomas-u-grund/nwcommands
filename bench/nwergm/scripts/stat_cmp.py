import csv, collections, statistics as st, sys, re
def load(f):
    d=collections.OrderedDict()
    for r in csv.DictReader(open(f)):
        d.setdefault(r['model'],collections.OrderedDict()).setdefault(r['term'],[]).append(r)
    return d
R=load('stat_r.csv'); N=load(sys.argv[1] if len(sys.argv)>1 else 'stat_new.csv')
norm=lambda x: re.sub(r'[^a-z0-9]','',x.lower())
print("%-8s %-22s %8s %8s | %7s | %6s %6s | %6s %6s | %5s %5s"%("model","term","R mean","N mean","d (SE)","sdR/SE","sdN/SE","seR","seN","itR","itN"))
dmax=0
for m in R:
    if m not in N: continue
    rt=list(R[m].keys()); nt=list(N[m].keys())
    if len(rt)!=len(nt): print(m,'term mismatch'); continue
    # order terms identically: both lists follow model order
    for a,b in zip(rt,nt):
        rb=[float(x['b']) for x in R[m][a]]; nb=[float(x['b']) for x in N[m][b]]
        rse=st.mean(float(x['se']) for x in R[m][a]); nse=st.mean(float(x['se']) for x in N[m][b])
        d=(st.mean(nb)-st.mean(rb))/rse
        itr=st.mean(float(x['iter']) for x in R[m][a]); itn=st.mean(float(x['iter']) for x in N[m][b])
        dmax=max(dmax,abs(d))
        print("%-8s %-22s %8.4f %8.4f | %7.3f | %6.3f %6.3f | %6.4f %6.4f | %5.1f %5.1f"%(m,a[:22],st.mean(rb),st.mean(nb),d,st.stdev(rb)/rse,st.stdev(nb)/rse,st.mean(float(x['se']) for x in R[m][a]),nse,itr,itn))
print("max |d| = %.3f"%dmax)
