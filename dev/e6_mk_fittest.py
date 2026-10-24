# builds the "fits vs R" block of cscripts/test_nwergm_constr.do from e6_fit_ref.txt
import collections
specs={'U_fixedas':'fixedas(present=UP, absent=UA)','U_blockdiag':'blockdiag(g)','U_blocks':'blocks(g, levels2=-c(1,2,3))','U_bd4':'bd(maxout=4)',
 'U_edges':'edges','U_degrees':'degrees','D_blockdiag':'blockdiag(gd)','D_odegrees':'odegrees','D_bd':'bd(maxout=4,maxin=4)','D_idegrees':'idegrees'}
mple=collections.OrderedDict(); mcmle=collections.OrderedDict()
for l in open('e6_fit_ref.txt'):
    f=l.strip().split('|')
    if f[0]=='MPLE': mple.setdefault(f[1],[]).append((f[2].replace('.','_'),f[3],f[4]))
    else: mcmle.setdefault(f[1],{}).setdefault(f[2],[]).append((float(f[4]),float(f[5])))
o=[]
o.append('* ---- fits under constraints vs R ergm 4.12.0 (dev/e6_fit_ref.R): MPLE coefficients and standard errors; MCMLE coefficients ----')
o.append('local nfitfail 0')
for lab,rows in mple.items():
    t=lab[0]
    terms = 'edges nodematch(g) triangle' if t=='U' else 'edges mutual nodematch(gd)'
    net = 'U' if t=='U' else 'D'
    o.append('qui nwergm %s, %s constraints(%s) method(mple)'%(net,terms,specs[lab]))
    for (nm,co,se) in rows:
        nm2 = nm.replace('nodematch_g','nodematch_g' if t=='U' else 'nodematch_gd')
        if co=='NA':
            o.append('e6fitchk omitted "%s"'%nm2)
        else:
            o.append('e6fitchk mple "%s" %s %s'%(nm2,co,se))
o.append('if "`e6fitfail\'" != "" local nfitfail 1')
for lab,d in mcmle.items():
    t=lab[0]; net='U' if t=='U' else 'D'
    terms='edges triangle' if t=='U' else 'edges mutual'
    # per-coefficient: mean over seeds, sd across seeds, mean reported se
    for nm,vals in d.items():
        pass
    o.append('qui nwergm %s, %s constraints(%s) method(mcmle) mcmcsamplesize(4000) mcmcburnin(20000) mcmcinterval(1000) mcmleiterations(30) seed(7)'%(net,terms,specs[lab]))
    for nm,vals in d.items():
        import statistics as st
        m=st.mean(v[0] for v in vals); sd=st.pstdev(v[0] for v in vals); se=st.mean(v[1] for v in vals)
        o.append('e6fitchk mcmle "%s" %.6f %.6f %.6f'%(nm.replace('.','_'),m,sd,se))
o.append('if "`e6fitfail\'" != "" local nfitfail 1')
o.append('if `nfitfail\' == 0 di "PASS fitted coefficients under constraints agree with R ergm"\nelse exit 9')
open('e6_fittest_block.do','w').write("\n".join(o)+"\n")
