cscript

do unw_core.do

* Zero test coverage existed for this command before this unit. Also
* certifies a performance fix: nwissymmetric.ado used to materialize
* the full dense n-by-n adjacency matrix via nwtomata just to run
* issymmetric() on it - O(n^2) regardless of how sparse the actual
* network is (confirmed as one of the nwtomata-dependent commands
* excluded from the n=10,000 benchmark tier entirely,
* docs/PERFORMANCE_BENCHMARKS.md). Replaced with
* check_issymmetric() (unw_core.do), which checks the same condition
* directly against the sparse edge list, O(m) in tie count.

nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) directed name(sym1) nooutput
nwissymmetric sym1
assert r(issymmetric) == 1

nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) directed name(asym1) nooutput
nwissymmetric asym1
assert r(issymmetric) == 0

* valued: same tie value in both directions - symmetric.
nwclear
nwset, mat((0,3,3\3,0,3\3,3,0)) directed name(sym2) nooutput
nwissymmetric sym2
assert r(issymmetric) == 1

* valued: same tie PATTERN but a different weight in one direction -
* correctly asymmetric (the fix must compare weights, not just
* presence/absence).
nwclear
nwset, mat((0,3,3\2,0,3\3,3,0)) directed name(asym2) nooutput
nwissymmetric asym2
assert r(issymmetric) == 0

* an undirected network is symmetric by construction.
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) undirected name(undirnet) nooutput
nwissymmetric undirnet
assert r(issymmetric) == 1

* empty network (no ties at all) is trivially symmetric.
nwclear
nwset, mat((0,0,0\0,0,0\0,0,0)) directed name(emptynet) nooutput
nwissymmetric emptynet
assert r(issymmetric) == 1

* asymmetric purely via a one-sided tie (one direction has a tie, the
* reverse direction has none at all).
nwclear
nwset, mat((0,1,0\0,0,0\0,0,0)) directed name(onesided) nooutput
nwissymmetric onesided
assert r(issymmetric) == 0

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwissymmetric nonexistent
assert _rc == 482

nwclear
capture noisily nwissymmetric
assert _rc == 482
