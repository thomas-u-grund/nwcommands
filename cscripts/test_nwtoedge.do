cscript

do unw_core.do

nwclear
nwset, mat((0,1,1\1,1,0\0,0,0))  name(mynet)

nwtoedge mynet
sum mynet

assert         r(sum)   == 3
assert         r(max)   == 1
assert         r(min)   == 0
assert reldif( r(sd)     , .5477225575051661 ) <  1E-8
assert reldif( r(Var)    , .3                ) <  1E-8
assert reldif( r(mean)   , .5                ) <  1E-8
assert         r(sum_w) == 6
assert         r(N)     == 6

clear
nwset, mat((0,1,1,0\1,1,0,0\0,0,0,0\0,0,0,0))  name(mynet2)

nwtoedge _all
tab mynet*

assert         r(c) == 2
assert         r(r) == 2
assert         r(N) == 6

corr mynet*
assert reldif( r(rho)  , 1                 ) <  1E-8
assert         r(N)   == 6

qui {
mat T_C = J(2,2,0)
mat T_C[1,1] =                  1
mat T_C[1,2] =                  1
mat T_C[2,1] =                  1
mat T_C[2,2] =                  1
}
matrix C_C = r(C)
assert mreldif( C_C , T_C ) < 1E-8
_assert_streq `"`: rowfullnames C_C'"' `"mynet mynet2"'
_assert_streq `"`: colfullnames C_C'"' `"mynet mynet2"'
mat drop C_C T_C



nwclear
nwset, mat((0,1,1,0\1,1,0,0\0,0,0,0\0,0,0,0))  name(mynet)
gen x = (_n > 2)
gen y = _n

nwtoedge mynet, egovars(x y) altervars(x y)

sum x_alter
assert         r(sum)   == 8
assert         r(max)   == 1
assert         r(min)   == 0
assert reldif( r(sd)     , .5163977794943222 ) <  1E-8
assert reldif( r(Var)    , .2666666666666667 ) <  1E-8
assert reldif( r(mean)   , .5                ) <  1E-8
assert         r(sum_w) == 16
assert         r(N)     == 16

sum y_ego
assert         r(sum)   == 40
assert         r(max)   == 4
assert         r(min)   == 1
assert reldif( r(sd)     , 1.154700538379251 ) <  1E-8
assert reldif( r(Var)    , 1.333333333333333 ) <  1E-8
assert reldif( r(mean)   , 2.5               ) <  1E-8
assert         r(sum_w) == 16
assert         r(N)     == 16

nwclear
nwset, mat(J(6,4,1)) name(mynet)
nwtoedge
summarize
assert         r(sum)   == 12
assert         r(max)   == 1
assert         r(min)   == 1
assert         r(sd)    == 0
assert         r(Var)   == 0
assert         r(mean)  == 1
assert         r(sum_w) == 12
assert         r(N)     == 12

nwclear
nw2set, mat(J(6,4,1)) name(mynet)
nwtoedge
assert _N == 55

nwclear
nw2set, mat(J(6,4,1)) name(mynet)
nw2toedge
assert _N == 24

* moderate-severity pass, import_export group: upper/full/ignore2mode/
* numeric had no regression coverage at all before this. numeric's own
* "only one network" constraint was previously print-only (no `error'
* call, see nwtoedge.ado's own fix comment) - this is the regression
* guard for that fix specifically.
nwclear
nwset, mat((0,1,1\1,0,0\0,0,0)) name(undirnet)
nwtoedge undirnet, upper
assert _rc == 0
nwclear
nwset, mat((0,1,1\1,0,0\0,0,0)) name(undirnet)
nwtoedge undirnet, full
assert _rc == 0

nwclear
nw2set, mat(J(6,4,1)) name(mynet)
nwtoedge, ignore2mode
assert _rc == 0

nwclear
nwset, mat((0,1\0,0)) name(a)
nwset, mat((0,1\0,0)) name(b)
capture nwtoedge _all, numeric
assert _rc == 198


* --- comparevars()/comparemode(): ego/alter comparison columns
* (harmonisation unit 63, the Stage 5 "ego/alter comparison variables"
* roadmap item), built by internally expanding each variable via the
* already-certified nwexpand and appending the result to the same
* network list nwtoedge already merges - so no new comparison logic was
* written, only new plumbing. x = (1,1,2,3) for nodes 1-4. comparemode
* same (undirected, the default): 6 dyads (basenet is undirected, no
* directed network in the list), same_x = 1 only for the (1,2) dyad
* (x1==x2==1), 0 for every other of the 6 pairs (1 vs 2, 1 vs 3, 2 vs
* 3 all differ) - hand-computable exactly.
nwclear
nwset, mat((0,1,1,0\1,0,0,0\0,0,0,0\0,0,0,0)) undirected name(basenet)
gen x = 1 in 1
replace x = 1 in 2
replace x = 2 in 3
replace x = 3 in 4

nwtoedge basenet, comparevars(x) comparemode(same)
assert _rc == 0
capture confirm variable same_x
assert _rc == 0
* count includes the diagonal (self-dyads, always missing - selfloop
* is off by default); sum's own r(N) excludes missing values, giving
* exactly the 6 genuine off-diagonal dyads.
qui sum same_x
assert r(N) == 6
assert r(sum) == 1

* comparemode(dist) is directional (x[ego]-x[alter]), which forces
* full() automatically (a directed network entering the list) - all 12
* ordered pairs appear, and the sign correctly flips with direction:
* dist_x(1,3) = x1-x3 = 1-2 = -1; dist_x(3,1) = x3-x1 = 2-1 = 1.
nwclear
nwset, mat((0,1,1,0\1,0,0,0\0,0,0,0\0,0,0,0)) undirected name(basenet2) labs(A,B,C,D)
gen x = 1 in 1
replace x = 1 in 2
replace x = 2 in 3
replace x = 3 in 4

nwtoedge basenet2, comparevars(x) comparemode(dist)
assert _rc == 0
qui sum dist_x
assert r(N) == 12
qui sum dist_x if _ego == "A" & _alter == "C"
assert r(mean) == -1
qui sum dist_x if _ego == "C" & _alter == "A"
assert r(mean) == 1

* comparevars() combines with egovars()/altervars() - both kinds of
* columns coexist, comparevars() does not replace the raw values.
nwclear
nwset, mat((0,1,1,0\1,0,0,0\0,0,0,0\0,0,0,0)) undirected name(basenet3)
gen x = 1 in 1
replace x = 1 in 2
replace x = 2 in 3
replace x = 3 in 4

nwtoedge basenet3, egovars(x) altervars(x) comparevars(x) comparemode(same)
assert _rc == 0
foreach v in x_ego x_alter same_x {
	capture confirm variable `v'
	assert _rc == 0
}

* --- regression: egovars()/altervars() after nwdropnodes ..., generate()
* used to leak phantom rows for the dropped nodes. nwdropnodes leaves
* unrelated Stata rows untouched by design unless attributes() is also
* given (see nwdropnodes.ado's own header note and its test file's
* "shared dataset" comment) - so the dataset can legitimately hold more
* rows than the shrunk network has nodes. fromfile/tofile used to be
* built from every one of those rows regardless, and the leftover
* dropped-node rows, never matching any real _ego/_alter value, got
* appended as new all-missing-except-attributes rows by the plain
* merge m:n below (Stata's default unmatched-"using" behavior) - one
* phantom row per dropped node per egovars()/altervars() call. Fixed by
* filtering fromfile/tofile on `_nwinclude' (nw_datasync's own node-
* membership flag, already computed earlier in this same command) before
* the merge. 5-node undirected network, drop 2 nodes (B, D): the
* resulting 3-node undirected network's edgelist (upper triangle plus
* diagonal, the default for an undirected network without `full') must
* be exactly 3*4/2 = 6 rows, none of them referencing B or D, none of
* them missing.
nwclear
nwset, mat((0,1,0,0,1\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\1,0,0,1,0)) name(dropnet) undirected labs(A,B,C,D,E)
gen myx = _n * 10
nwdropnodes dropnet, nodes(B D) generate(dropnet_small)
nwtoedge dropnet_small, egovars(myx) altervars(myx)
assert _N == 6
count if missing(_ego) | missing(_alter)
assert r(N) == 0
count if inlist(_ego, "B", "D") | inlist(_alter, "B", "D")
assert r(N) == 0
di "=== nwtoedge/nwdropnodes phantom-row REGRESSION VERIFIED ==="


