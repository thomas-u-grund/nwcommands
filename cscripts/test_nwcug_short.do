cscript

do unw_core.do

* nwcug stat() short form and nwclustering without generate() (3.20.1)
nwuse data/florentine, nwclear
* (the first call adds _nwinclude, as every command that syncs the node data does)
nwclustering flomarriage, generate(cc0)
drop cc0
quietly describe
local k0 = r(k)
nwclustering flomarriage
local cg = r(cluster_global)
quietly describe
assert r(k) == `k0'
nwclustering flomarriage, generate(cc)
assert reldif(r(cluster_global), `cg') < 1e-12
drop cc

nwcug flomarriage, stat(nwclustering) rname(cluster_global) reps(100) seed(7)
local p1 = r(p)
local m1 = r(mean_null)
assert reldif(r(obs), `cg') < 1e-12
nwcug flomarriage, stat(nwclustering ##net##, generate(cc) replace) rname(cluster_global) reps(100) seed(7)
assert reldif(r(p), `p1') < 1e-12
assert reldif(r(mean_null), `m1') < 1e-12

* a short form with options after a comma
nwcug flomarriage, stat(nwclustering, measure(binary)) rname(cluster_global) reps(100) seed(7)
assert reldif(r(p), `p1') < 1e-12

* silent prints nothing and returns the same
nwcug flomarriage, stat(nwdyads) rname(reciprocity) reps(20) seed(1) silent
assert r(obs) == 1
