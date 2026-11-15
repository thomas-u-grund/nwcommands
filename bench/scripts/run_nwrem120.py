"""nwrem 1.2.0 in the design of bench/scripts/plan_rem.py (warm-up fit, own process per fit, seed = rep). nwrem only."""
import os, subprocess, time, csv, sys, resource
# env: SCR (scratch folder with cc17 core and the nwrem tree), BENCH (core bench/ folder with scripts/ and data/rem/), WORK (output folder)
SCR=os.environ["SCR"]
BENCH=os.environ["BENCH"]
NWC=os.environ["NWCORE"]; TREE=os.environ["NWTREE"]; W=os.environ["WORK"]
PLUS=W+"/plus_empty"; os.makedirs(PLUS,exist_ok=True)
STATA="/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE"
SIZES=["e200","e1000","e5000_n20","e5000","e5000_n100","e20000"]
SETS=["S1_nodsnd_nidrec","S2_degree4","S3_degree4_inertia","S4_recency","S5_covariates"]
only=sys.argv[1].split(",") if len(sys.argv)>1 else SIZES
raw=W+"/rem_nwrem120.csv"
new=not os.path.exists(raw)
fh=open(raw,"a",newline=""); w=csv.writer(fh)
if new: w.writerow("cell,rep,status,load1,wall,maxrss_mb,secs,ll,names,ests,ses,info,start".split(","))
def one(size,st,rep):
    out=W+"/out.tsv"
    if os.path.exists(out): os.remove(out)
    env=dict(os.environ,SIZE=size,SET=st,SEED=str(rep),OUT=out,BENCH=BENCH,BENCH_PLUS=PLUS,NWC=NWC,
        BENCH_ADOPATH=":".join([NWC,NWC+"/lib",TREE,TREE+"/lib"]))
    l1=os.getloadavg()[0]; t0=time.time()
    p=subprocess.Popen(["perl","-e","alarm 600; exec @ARGV",STATA,"-e","do",BENCH+"/scripts/rem_nw.do"],env=env,cwd=W,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True)
    _,ru=os.wait4(p.pid,0)[1:]  # rusage of the child tree
    wall=time.time()-t0
    d={}
    if os.path.exists(out):
        for line in open(out):
            k,_,v=line.rstrip("\n").partition("\t"); d[k]=v
    return d,l1,wall,ru.ru_maxrss/1048576  # bytes on macOS
for size in only:
  for st in SETS:
    cell=st+"_"+size; rep=1; reps=7
    while rep<=reps:
        d,l1,wall,mem=one(size,st,rep)
        status="ok" if d.get("secs") else ("timeout" if wall>=598 else "error")
        w.writerow([cell,rep,status,l1,"%.2f"%wall,"%.0f"%mem,d.get("secs",""),d.get("ll",""),d.get("names",""),d.get("ests",""),d.get("ses",""),d.get("version",""),time.strftime("%Y-%m-%d %H:%M:%S")]); fh.flush()
        print(cell,rep,status,d.get("secs"),"mem",round(mem),"load",l1,flush=True)
        if status!="ok": break
        if rep==1:
            t=float(d["secs"]); reps=1 if t>400 else 3 if t>200 else 5 if t>60 else 7
        rep+=1
