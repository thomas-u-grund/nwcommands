from analyse import *
from estcmp import res
import statistics as st
def f(x): return "%.2f"%x if x<1 else "%.1f"%x
def rng(a,b): return "%d"%a if a==b else "%d--%d"%(a,b)
names={"B1":"30 nodes, directed: edges, mutual","B2":"100 nodes, directed: + nodematch","B3":"100 nodes, undirected: edges, gwesp","B4":"500 nodes, sparse, undirected: + nodematch, gwesp","B5":"1000 nodes, directed: edges, mutual, nodematch","B6":"1000 nodes, sparse, undirected: edges, gwesp, gwnsp","Lazega":"Lazega advice, 71 nodes: seven terms","Mesa":"Faux Mesa High, 205 nodes: gwesp(.25)"}
mode=__import__('sys').argv[1]
for m in M:
    R,A,B=[out[(m,i)] for i in I]
    if mode=="article":
        print("%s & %s & %s & %s & %.2f & %s & %s \\\\"%(names[m].replace("gwesp(.25)","gwesp(.25)"),f(R[1]),f(A[1]),f(B[1]),B[1]/R[1],rng(R[4],R[5]),rng(B[4],B[5])))
    elif mode=="manual":
        print("%s & %s & %s & %s & %.1f & %s; %s\\\\"%(names[m],f(R[1]),f(A[1]),f(B[1]),R[1]/B[1],rng(R[4],R[5]),rng(B[4],B[5])))
    elif mode=="book":
        print("%s & %s & %s & %.1f \\\\"%(names[m],f(R[1]),f(B[1]),R[1]/B[1]))
    elif mode=="md":
        print("| %s | %s (%s-%s) | %s (%s-%s) | %s (%s-%s) | %.1f | %.2f | %.1f | %s / %s / %s |"%(m,f(R[1]),f(R[2]),f(R[3]),f(A[1]),f(A[2]),f(A[3]),f(B[1]),f(B[2]),f(B[3]),R[1]/B[1],B[1]/R[1],A[1]/B[1],rng(R[4],R[5]),rng(A[4],A[5]),rng(B[4],B[5])))
