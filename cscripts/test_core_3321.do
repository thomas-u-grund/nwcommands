* core 3.32.1: nwtabulate attribute() on undirected networks, nwbackbone fixedrow signed lower end of the support,
* nwdiffuse curve with one period and rate when nobody has adopted before, nwcloseness note on valued networks
clear all
set more off
nwclear

mata:
// within and between ties of an undirected network from its adjacency matrix and a group variable (brute force)
void nwtest_we(real matrix A, string scalar gvar)
{
	real colvector g
	real scalar i, j, W, B
	g = st_data(., gvar)
	W = 0
	B = 0
	for (i = 1; i < rows(A); i++) for (j = i + 1; j <= rows(A); j++) if (A[i,j] != 0) {
		if (g[i] == g[j]) W++
		else B++
	}
	st_numscalar("__W", W)
	st_numscalar("__B", B)
}
end

* ---- (1) nwtabulate, attribute(), undirected: the star of the report ----
matrix M = (0,1,1\1,0,0\1,0,0)
nwset, mat(M) name(star) undirected
nwload star
gen byte a = (_nwnode == "n2")
nwtabulate star, attribute(a) permutations(1)
assert r(N) == 2
assert r(EI_index) == 0
matrix T = r(table)
assert T[1,1] == 1 & T[1,2] == 1
* a directed network is unchanged: every directed tie is one row
matrix D = (0,1,0\0,0,1\1,0,0)
nwset, mat(D) name(dcyc) directed
nwload dcyc
capture drop a
gen byte a = (_nwnode == "n1")
nwtabulate dcyc, attribute(a) permutations(1)
assert r(N) == 3
matrix T = r(table)
assert T[1,1] == 1 & T[1,2] == 1 & T[2,1] == 1

* random undirected networks against a brute-force count from the adjacency matrix
foreach s in 1 2 3 4 5 6 {
	set seed `s'
	local n = 10 + `s'
	nwclear
	nwrandom `n', prob(.3) name(u) undirected
	nwload u
	capture drop g
	gen byte g = mod(_n * `s', 3)
	nwtabulate u, attribute(g) permutations(1)
	local nt = r(N)
	local ei = r(EI_index)
	nwtomata u, mat(Au)
	mata: nwtest_we(Au, "g")
	assert `nt' == scalar(__W) + scalar(__B)
	assert abs(`ei' - (scalar(__B) - scalar(__W)) / (scalar(__B) + scalar(__W))) < 1e-6
}

* the Senate of the book chapter (skipped when the data are not found)
nwclear
clear
capture nwuse data/senate114
local __sen = _rc
if `__sen' == 0 {
	generate byte republican = (party == "R")
	nwrecode senate114 (-1 = 0) (1 = 1), generate(spos)
	nwrecode senate114 (1 = 0) (-1 = 1), generate(sneg)
	foreach v in spos sneg {
		nwtabulate `v', attribute(republican) permutations(1)
		local nt = r(N)
		local ei = r(EI_index)
		nwtomata `v', mat(Ap)
		mata: nwtest_we(Ap, "republican")
		assert `nt' == scalar(__W) + scalar(__B)
		assert abs(`ei' - (scalar(__B) - scalar(__W)) / (scalar(__B) + scalar(__W))) < 1e-6
		di "Senate114 `v': ties " `nt' ", E-I " `ei'
	}
}
if `__sen' != 0 di "(senate114 not available: Senate check skipped)"

* ---- (2) nwbackbone fixedrow signed: the minimum overlap has upper p-value 1 ----
nwclear
nwuse data/davis
nwbackbone davis, method(fixedrow) signed
assert r(ties) == 6
assert r(ties_in) == 139
* with a correction
nwbackbone davis, method(fixedrow) signed mtc(BH) replace
local bh = r(ties)
* unsigned: unchanged
nwbackbone davis, method(fixedrow) replace

* ---- (4) nwdiffuse curve ----
nwclear
set seed 3
nwrandom 8, prob(.3) name(g)
nwload g
capture drop toa
gen toa = 1
nwdiffuse curve g, toa(toa)
matrix C = r(curve)
assert rowsof(C) == 1 & C[1,2] == 8 & C[1,5] == 8 & C[1,4] == 0
nwdiffuse curve g, toa(toa) graph
* t0 earlier than the first adoption: the growth is not defined (missing), no 1e15
replace toa = cond(_n <= 3, 3, cond(_n <= 5, 4, .))
nwdiffuse curve g, toa(toa) t0(1) t1(5)
matrix C = r(curve)
assert C[1,4] == 0 & C[2,4] == 0 & C[3,4] == . & C[4,4] == (5 - 3) / 3 & C[5,4] == 0
assert C[3,5] == 3 & C[4,5] == 2
* the unchanged case: first adoption in the first period
nwdiffuse curve g, toa(toa) t0(3) t1(5)
matrix C = r(curve)
assert C[1,4] == 0 & C[2,4] == (5 - 3) / 3
di "test_core_3321 done"
