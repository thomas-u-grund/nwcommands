cscript

do unw_core.do

nwclear


// Check weighted clustering coefficient accoridng to Opsahl & Panzarasa (2009, p. 157)

set obs 6
gen ego = ""
gen alter = ""
gen value = .

replace ego = "A" in 1/2
replace alter = "B" in 1
replace alter = "C" in 2
replace value = 4 in 1
replace value = 2 in 2
replace ego = "C" in 3
replace alter = "B" in 3/5
replace value = 4 in 3
replace ego = "D" in 4
replace value = 1 in 4
replace ego = "E" in 5/6
replace value = 2 in 5
replace alter = "F" in 6
replace value = 1 in 6

nwfromedge _all, undirected



nwclustering, measure(binary)

assert `"`r(measure)'"' == `"binary"'

assert reldif( r(cluster_avg)     , .5416666679084301 ) <  1E-8
assert reldif( r(cluster_global)  , .3333333333333333 ) <  1E-8

nwclustering, measure(geometric)

assert `"`r(measure)'"' == `"geometric"'

assert reldif( r(cluster_avg)     , .5663523003458977 ) <  1E-8
assert reldif( r(cluster_global)  , .4361302099462925 ) <  1E-8

nwclustering, measure(minimum)

assert `"`r(measure)'"' == `"minimum"'

assert reldif( r(cluster_avg)     , .5909090936183929 ) <  1E-8
assert reldif( r(cluster_global)  , .5                ) <  1E-8

nwclustering, measure(maximum)
assert `"`r(measure)'"' == `"maximum"'

assert reldif( r(cluster_avg)     , .5454545468091965 ) <  1E-8
assert reldif( r(cluster_global)  , .375              ) <  1E-8






* --- regression guard: a plain nwclustering call (no symmetrize) used
* to leave a stale nonzero _rc behind on every single call, despite
* completing and printing its own results correctly. Root cause: the
* command's own end-of-program cleanup ("capture nwdrop `symnet'")
* unconditionally tried to drop a tempname that is only ever actually
* created when `symmetrize' is given - on any other call it legitimately
* failed ("network not found"), and nothing afterward reset `_rc'
* before the command returned (the same bug class fixed repeatedly
* elsewhere in this package's own history). Checked directly against
* the STATA session's own `_rc', not just that the command "worked" -
* a stale nonzero `_rc' with no accompanying error message is exactly
* the kind of silent problem a plain "did it crash" check would miss.
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) undirected labs(A,B,C,D)
nwclustering, generate(myclust)
assert _rc == 0

* the symmetrize-requiring path (where the tempname genuinely IS
* created and genuinely needs dropping) must still work correctly too.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) directed labs(A,B,C)
nwclustering, symmetrize generate(myclust2)
assert _rc == 0
assert myclust2[1] == 1
