cscript

do unw_core.do

set graphics off

* nwdendrogram had zero automated regression coverage. Uses nwhierarchy
* to produce a genuine Stata cluster object (nwhierarchy itself is
* already certified in test_nwhierarchy.do) rather than re-deriving
* clustermat's own internals here.

nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwhierarchy net1
assert _rc == 0

* --- default (no cluster name): auto-picks the first cluster found.
nwdendrogram
assert _rc == 0

* --- explicit cluster name.
nwdendrogram _clus_1
assert _rc == 0

* --- label(varname): an existing Stata variable used as node labels.
nwdendrogram _clus_1, label(_nwnode)
assert _rc == 0

* moderate-severity pass, visualization group: unlike its siblings
* nwplot/nwplotmatrix, nwdendrogram had no bare `lab' flag to reuse the
* network's own stored node-name labels (`_nwnode') - forcing the
* caller to pass the variable manually even though that is exactly
* what `lab' pulls in for the other two plotting commands in this
* group. `lab', like the sibling commands' own convention, takes
* precedence over an explicit label() when both are given.
nwdendrogram _clus_1, lab
assert _rc == 0

* moderate-severity pass, visualization group: the intended validation
* that a user-supplied cluster name actually exists was dead code
* (commented out), so a nonexistent name produced a confusing generic
* Stata error ("variable ..._hgt not found", r111) instead of the
* clear, purpose-written message the code was written to give. Fixing
* the dead code itself surfaced a second, independent bug in the very
* code being restored: `: list clus & r(names)' crashed outright
* ("invalid syntax") since the `: list A & B' extended macro function
* requires bare local macro names, not an r()-result reference -
* r(names) must be copied into a local first. The final reported code
* (r111) is coincidentally unchanged from the pre-fix behavior, but the
* displayed message is now the clear, purpose-written one, not a
* confusing internal variable-not-found error.
capture noisily nwdendrogram bogus_cluster_xyz_that_does_not_exist
assert _rc == 111

di "=== nwdendrogram REGRESSION VERIFIED ==="

* --- failure path (BUGFIX: this used to print "No cluster analysis
* found" and then fall through - a bare `exit' with no return code -
* returning _rc==0 as if nothing were wrong, confirmed directly before
* this fix): a bare nwdendrogram call with no cluster analysis at all
* in the session (no cluster name given, and `cluster query' finds
* none).
clear
cluster drop _all
capture noisily nwdendrogram
assert _rc != 0
