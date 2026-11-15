import csv,statistics as st,collections
import os,sys
# usage: python3 aggregate_rem_nwrem120.py <relevent raw rem.csv of the core bench folder> <nwrem times csv>; writes rem_nwrem120.csv
B=sys.argv[1]
R=collections.defaultdict(lambda:collections.defaultdict(list)); st_=collections.defaultdict(set); Rest={}
for r in csv.DictReader(open(B)):
    if r['impl'].startswith('relevent'):
        st_[(r['cell'],r['impl'])].add(r['status'])
        if r['status']=='ok': R[r['cell']][r['impl']].append(float(r['secs'])); Rest[(r['cell'],r['impl'])]=r['ests'].split('\t'),r['names'].split('\t'),r['ses'].split('\t')
N=collections.defaultdict(list); Nmem=collections.defaultdict(list); Nest={}; Nok=collections.Counter(); Nses={}
for r in csv.DictReader(open(sys.argv[2])):
    if r['status']=='ok': N[r['cell']].append(float(r['secs'])); Nmem[r['cell']].append(float(r['maxrss_mb'])); Nest.setdefault(r['cell'],[]).append((r['names'].split('\t'),r['ests'].split('\t'),r['ses'].split('\t')))
rows=[]
for cell in N:
    n=st.median(N[cell]); line={'cell':cell,'n':len(N[cell]),'nw':n,'mem':max(Nmem[cell])}
    for h in ('relevent_hessT','relevent_hessF'):
        v=R[cell].get(h)
        if v: line[h]=st.median(v); line['r'+h[-1]]=st.median(v)/n; line['n'+h[-1]]=len(v)
        else: line[h]=None; line['r'+h[-1]]=None; line['st'+h[-1]]=','.join(sorted(st_[(cell,h)]))
    # agreement: max |diff| in coef and in units of relevent SE (hessT)
    k=(cell,'relevent_hessT')
    if k in Rest:
        en,nm,se=Rest[k]; d=0;ds=0
        for names,ests,ses in Nest[cell]:
            m=dict(zip([x.lower().split('_')[0].split('.')[0] for x in names],map(float,ests)))
            for x,y,s in zip(nm,en,se):
                d=max(d,abs(m[x.lower().split('.')[0]]-float(y))); ds=max(ds,abs(m[x.lower().split('.')[0]]-float(y))/float(s))
        line['dcoef']=d; line['dse']=ds
    rows.append(line)
f=lambda x:'-' if x is None else ('%.3g'%x)
print('cell n nwrem relT relF ratioT ratioF maxrss_MB dcoef dcoef/SE status')
for l in rows: print(l['cell'],l['n'],f(l['nw']),f(l['relevent_hessT']),f(l['relevent_hessF']),f(l['rT']),f(l['rF']),'%.0f'%l['mem'],f(l.get('dcoef')),f(l.get('dse')),l.get('stT',''),l.get('stF',''))

# ---- tables
def g(x):
    return ('%.1f'%x) if x<10 else ('%d'%round(x))
by={l['cell']:l for l in rows}
cols=['e200','e1000','e5000_n20','e5000','e5000_n100','e20000']
sets=['S1_nodsnd_nidrec','S2_degree4','S3_degree4_inertia','S4_recency','S5_covariates']
def cellratio(l,h):
    r=l['r'+h]
    if r is not None: return g(r)
    s=l.get('st'+h,'')
    if 'timeout' in s: return '>'+g(600/l['nw'])
    return 'n.r.'
print()
for s in sets:
    print(s,'|',' | '.join(cellratio(by[s+'_'+c],'T')+' / '+cellratio(by[s+'_'+c],'F') for c in cols))
print()
for s in sets:
    print(s,'| nwrem s:',' | '.join(('%.3g'%by[s+'_'+c]['nw']) for c in cols))
w=csv.writer(open('rem_nwrem120.csv','w',newline=''))
w.writerow(['cell','nwrem_n','nwrem_median_s','relevent_hessT_median_s','relevent_hessF_median_s','ratio_hessT','ratio_hessF','relevent_status','peak_rss_mb','max_abs_coef_diff','max_diff_in_relevent_se'])
for l in rows:
    w.writerow([l['cell'],l['n'],'%.4g'%l['nw'],f(l['relevent_hessT']),f(l['relevent_hessF']),f(l['rT']),f(l['rF']),(l.get('stT','')+'/'+l.get('stF','')).strip('/'),'%.0f'%l['mem'],f(l.get('dcoef')),f(l.get('dse'))])
rT=[l['rT'] for l in rows if l['rT']]; rF=[l['rF'] for l in rows if l['rF']]
print(min(rT),max(rT),min(rF),max(rF))
