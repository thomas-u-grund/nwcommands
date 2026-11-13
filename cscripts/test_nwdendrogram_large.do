cscript

do unw_core.do

* nwdendrogram (3.20.1): a tree of 70 nodes has 69 rings; drawing one plot per group and ring made
* the graph command longer than Stata/BE allows, and the error was swallowed (nothing drawn, rc 0).
* With the default single color each kind of element is now one plot.
nwclear
set seed 1
nwrandom 70, density(.15) name(big)
nwhierarchy big, linkage(wardslinkage)
graph drop _all
nwdendrogram _clus_1
assert _rc == 0
graph describe Graph
nwdendrogram _clus_1, lab
assert _rc == 0

* colorpalette() was passed on nested (colorpalette(colorpalette(...))) and failed silently
nwclear
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) undirected name(small)
nwhierarchy small
nwdendrogram _clus_1, colorpalette(red blue)
assert _rc == 0

* an error while drawing is reported, not swallowed
capture nwdendrogram _clus_1, notanoption
assert _rc != 0
di "test_nwdendrogram_large: all passed"
