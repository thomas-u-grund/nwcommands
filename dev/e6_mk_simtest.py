# builds the "simulation vs R" block of cscripts/test_nwergm_constr.do from e6_basis.txt and e6_sim_ref.txt
import re,sys
basis={l.split()[0]:l.split()[1] for l in open('e6_basis.txt')}
def mat(tag,n):
    s=basis[tag]; rows=[s[i*n:(i+1)*n] for i in range(n)]
    return " \\ ".join(",".join(r) for r in rows)
specs={('U','edges'):'edges',('U','degrees'):'degrees',('U','degreedist'):'degreedist',('U','bd4'):'bd(maxout=4)',
 ('U','blockdiag'):'blockdiag(g)',('U','blocksedges'):'blocks(g, levels2=-c(1,2,3)) + edges',('U','fixedas'):'fixedas(present=UP, absent=UA)',
 ('U','fixedasbd'):'fixedas(present=UP, absent=UA) + bd(maxout=5)',
 ('D','edges'):'edges',('D','odegrees'):'odegrees',('D','idegrees'):'idegrees',
 ('D','idegreedist'):'idegreedist',('D','degreedist'):'degreedist',('D','bd44'):'bd(maxout=5,maxin=5)',('D','blockdiag'):'blockdiag(g)'}
ref={}
for l in open('e6_sim_ref.txt'):
    t,lab,st,m,se=l.strip().split('|'); ref.setdefault((t,lab),[]).append((st,float(m),float(se)))
o=[]
o.append('* ---- simulation under constraints vs R ergm 4.12.0 simulate() (dev/e6_sim_ref.R): means of the model statistics ----')
o.append('nwclear')
o.append('clear\nset obs 12\ngen g = ceil(_n/4)\ngen gd = cond(_n<=5, 1, 2)')
o.append('nwset, mat((%s)) undirected name(U)'%mat('U',12))
o.append('nwset, mat((%s)) undirected name(UP)'%mat('UP',12))
o.append('nwset, mat((%s)) undirected name(UA)'%mat('UA',12))
o.append('nwset, mat((%s)) directed name(D)'%mat('D',10))
o.append('local nsimfail 0')
for (t,lab),rows in ref.items():
    spec=specs[(t,lab)]
    if t=='D': spec=spec.replace('blockdiag(g)','blockdiag(gd)')
    vals=";".join("%.6f,%.6f"%(m,se) for st,m,se in rows)
    o.append('e6simcase %s "%s" "%s/%s" "%s"'%(t,spec,t,lab,vals))
    o.append('if scalar(e6_simz) > 5 {\n\tdi as err "FAIL sim vs R"\n\tlocal nsimfail 1\n}')
o.append('if `nsimfail\' == 0 di "PASS simulated statistics under constraints agree with R ergm"\nelse exit 9')
open('e6_simtest_block.do','w').write("\n".join(o)+"\n")
print(len(ref),"cases")
