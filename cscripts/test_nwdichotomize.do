cscript

do unw_core.do

* nwdichotomize is a thin wrapper around nwrecode (harmonisation phase:
* new command, cheap to build since nwrecode already does the real
* work). threshold(#): value >= # -> 1, else -> 0.

nwclear
nwset, mat((0,50,150,0\50,0,300,0\150,300,0,4\0,0,4,0)) name(net1) undirected labs(A,B,C,D)
nwdichotomize net1, threshold(100)
nwtomata net1, mat(M)
mata: assert(M[1,2] == 0)   // 50 < 100
mata: assert(M[1,3] == 1)   // 150 >= 100
mata: assert(M[2,3] == 1)   // 300 >= 100
mata: assert(M[3,4] == 0)   // 4 < 100

* exact-threshold boundary is inclusive (>= means the threshold value
* itself becomes 1)
nwclear
nwset, mat((0,100\100,0)) name(boundary)
nwdichotomize boundary, threshold(100)
nwtomata boundary, mat(M2)
mata: assert(M2[1,2] == 1)

* generate(): leaves the original valued network untouched, saves the
* binary version under a new name
nwclear
nwset, mat((0,50,150,0\50,0,300,0\150,300,0,4\0,0,4,0)) name(net2) undirected labs(A,B,C,D)
nwdichotomize net2, threshold(100) generate(net2_bin)
nwtomata net2, mat(Morig)
mata: assert(Morig[1,3] == 150)
nwtomata net2_bin, mat(Mbin)
mata: assert(Mbin[1,3] == 1)
mata: assert(Mbin[1,2] == 0)

di "=== nwdichotomize VERIFIED ==="
