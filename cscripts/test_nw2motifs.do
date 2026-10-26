cscript

do unw_core.do

* nw2motifs (kernel 50 of the nwgraph plugin, generation 11) against bmotif 2.0.2 (Simmons et al. 2019): the motif counts of
* bmotif::mcount and the node position counts of bmotif::node_positions on 38 networks (fixture cscripts/native380_fixture,
* made by tools/verify_native380.R):
*   1 the toy network (6 x 4), 2 Southern women (davis), 3 Swedish directors (5,092 x 455, motifs up to five nodes),
*   4 a subsample of the directors, 5..34 random bipartite networks (sizes 3..24, densities 0.06..0.7, isolates, one empty and one complete network), 35..38 larger ones (up to 60 nodes in a mode)
* Network-level and node-level counts must be equal to the R values, the normalisations equal to 1e-12.  All networks carry the
* six-node motifs except the full directors.  Without a plugin of generation 11 the command must stop with a clear message
* (that check is the whole test then).  Prints "test_nw2motifs: all passed" on success.

local fx "cscripts/native380_fixture"

mata: st_local("gen", strofreal(nwg_comb_version()))
if `gen' < 11 {
	di as txt "test_nw2motifs: plugin generation `gen' < 11: the command must refuse with a message"
	nwclear
	mata: toy = (1,1,0 \ 0,1,1)
	nw2set, mat(toy) name(tt)
	capture noisily nw2motifs tt
	assert _rc == 198
	di as txt "test_nw2motifs: refused with r(198), main test SKIPPED"
	exit
}

capture program drop _chk
program _chk
	args ok msg
	if `ok' == 0 {
		di as err "FAIL: `msg'"
		exit 9
	}
end

mata:
// biadjacency matrix of the cells (i, j) of one network
real matrix n380_B(real matrix cells, real scalar n1, real scalar n2)
{
	real matrix B
	real scalar k
	B = J(n1, n2, 0)
	for (k = 1; k <= rows(cells); k++) B[cells[k, 1], cells[k, 2]] = 1
	return(B)
}
// the position counts of the nodes of the network held in the variables np1..npP, reordered rows (mode 1) then columns (mode 2)
real matrix n380_pos(string scalar stub, real scalar P, real colvector md)
{
	real matrix X
	string rowvector vn
	real scalar j
	vn = J(1, P, "")
	for (j = 1; j <= P; j++) vn[j] = stub + strofreal(j)
	X = st_data((1::rows(md)), vn)
	return(X[selectindex(md :== 1) \ selectindex(md :== 2), .])
}
// largest absolute difference, missing values must coincide (R NA or NaN = missing); 1e9 for a mismatch of missingness
real scalar n380_diff(real matrix A, real matrix B)
{
	real matrix miss
	if (rows(A) != rows(B) | cols(A) != cols(B)) return(1e10)
	if (any((A :>= .) :!= (B :>= .))) return(1e9)
	miss = (A :>= .)
	return(max(abs(editmissing(A, 0) - editmissing(B, 0))))
}
end

* ---- the fixture
tempfile nets cells freq pos posn
preserve
qui import delimited using "`fx'/nets.csv", clear
qui save `nets'
qui import delimited using "`fx'/cells.csv", clear
qui save `cells'
qui import delimited using "`fx'/freq.csv", clear asdouble
qui save `freq'
qui import delimited using "`fx'/pos.csv", clear asdouble
qui save `pos'
qui import delimited using "`fx'/posnorm.csv", clear asdouble
qui save `posn'
restore

local types none sum sizeclass sizeclass_plus1 sizeclass_NAzero position levelsize levelsize_plus1 levelsize_NAzero motif motif_plus1 motif_NAzero
local normnets 1 2 5 9 12
local nnet 38
local maxdiff 0
local maxnorm 0

* ---- 1. network-level and node-level counts, all networks
forvalues b = 1/`nnet' {
	preserve
	qui use `nets', clear
	qui keep if net == `b'
	local n1 = n1[1]
	local n2 = n2[1]
	local six = six[1]
	local lab = label[1]
	qui use `freq', clear
	qui keep if net == `b'
	sort motif
	mata: n380_F = st_data(., ("frequency", "normalise_sum", "normalise_sizeclass", "normalise_levelsize", "normalise_nodesets"))
	local nm = _N
	qui use `pos', clear
	qui keep if net == `b'
	sort node
	local P = cond(`six', 148, 46)
	mata: n380_X = st_data(., "np1" + "-np`P'")
	qui use `cells', clear
	qui keep if net == `b'
	mata: n380_C = st_data(., ("i", "j"))
	restore

	nwclear
	if `b' == 2 {
		nwuse data/davis, nwclear
		local net davis
	}
	else if `b' == 3 {
		nwuse data/ftdirectors_se, nwclear
		local net ftdirectors_se
	}
	else {
		if `b' == 4 {
			* the subsample is not stored as cells of a data set: it is in the cells file like the others
		}
		mata: n380_M = n380_B(n380_C, `n1', `n2')
		mata: n380_M = n380_M'   /* nw2set takes the columns of the matrix as mode 1 */
		nw2set, mat(n380_M) name(bnet)
		local net bnet
	}
	_nwsyntax `net', max(1)
	mata: n380_md = strtoreal(`netobj'->get_modes())'
	mata: st_local("nn1", strofreal(sum(strtoreal(`netobj'->get_modes()) :== 1)))
	_chk `=`nn1' == `n1'' "network `b' (`lab'): `nn1' rows instead of `n1'"
	timer clear 1
	timer on 1
	qui nw2motifs `net', `=cond(`six', "sixnode", "")' generate(np) replace normalise
	timer off 1
	qui timer list 1
	local secs = r(t1)
	matrix MT = r(motifs)
	_chk `=rowsof(MT) == `nm'' "network `b': `=rowsof(MT)' motifs instead of `nm'"
	mata: n380_G = st_matrix("MT")[., 3..7]
	mata: st_numscalar("__d", n380_diff(n380_G[., 1], n380_F[., 1]))
	_chk `=scalar(__d) == 0' "network `b' (`lab'): motif frequencies differ from bmotif::mcount by `=scalar(__d)'"
	mata: st_numscalar("__d", n380_diff(n380_G[., 2..5], n380_F[., 2..5]))
	_chk `=scalar(__d) < 1e-12' "network `b' (`lab'): normalised frequencies differ from bmotif::mcount by `=scalar(__d)'"
	if scalar(__d) > `maxnorm' local maxnorm = scalar(__d)
	mata: st_numscalar("__d", n380_diff(n380_pos("np", `P', n380_md), n380_X))
	_chk `=scalar(__d) == 0' "network `b' (`lab'): node position counts differ from bmotif::node_positions by `=scalar(__d)'"
	if scalar(__d) > `maxdiff' local maxdiff = scalar(__d)
	* the frequencies are the column sums of the positions of a motif / nodes of the motif
	di as txt "  net `b' (`lab', `n1' x `n2', `=cond(`six', "six-node", "five-node")'): equal to bmotif, `=string(`secs', "%6.2f")' s"
}
di as txt "1. motif frequencies and node positions of 38 networks equal bmotif::mcount and bmotif::node_positions (largest difference `maxdiff', normalised `maxnorm')"

* ---- 2. the twelve normalisations of node_positions
local cnt 0
foreach b of local normnets {
	preserve
	qui use `nets', clear
	qui keep if net == `b'
	local n1 = n1[1]
	local n2 = n2[1]
	local six = six[1]
	local P = cond(`six', 148, 46)
	qui use `cells', clear
	qui keep if net == `b'
	mata: n380_C = st_data(., ("i", "j"))
	restore
	nwclear
	if `b' == 2 {
		nwuse data/davis, nwclear
		local net davis
	}
	else {
		mata: n380_M = n380_B(n380_C, `n1', `n2')
		mata: n380_M = n380_M'   /* nw2set takes the columns of the matrix as mode 1 */
		nw2set, mat(n380_M) name(bnet)
		local net bnet
	}
	_nwsyntax `net', max(1)
	mata: n380_md = strtoreal(`netobj'->get_modes())'
	foreach ty of local types {
		preserve
		qui use `posn', clear
		qui keep if net == `b' & type == "`ty'"
		sort node
		mata: n380_X = st_data(., "np1" + "-np`P'")
		restore
		qui nw2motifs `net', `=cond(`six', "sixnode", "")' generate(nq) replace posnorm(`ty')
		mata: st_numscalar("__d", n380_diff(n380_pos("nq", `P', n380_md), n380_X))
		_chk `=scalar(__d) < 1e-12' "net `b', posnorm(`ty'): differs from bmotif::node_positions(normalisation) by `=scalar(__d)'"
		local ++cnt
	}
}
di as txt "2. `cnt' normalised node position tables equal bmotif::node_positions(normalisation = ...)"

* ---- 3. options, results and refusals
nwclear
mata: toy = (1,1,0,0 \ 1,1,1,0 \ 0,1,1,0 \ 0,0,1,1 \ 0,0,0,1 \ 1,0,0,1)'
nw2set, mat(toy) name(tm)
qui nw2motifs tm
_chk `=r(sixnode) == 0 & r(n_mode1) == 6 & r(n_mode2) == 4' "stored scalars"
_chk `=rowsof(r(motifs)) == 17 & colsof(r(motifs)) == 3' "17 x 3 motif table without normalise"
local cn : colnames r(motifs)
_chk `=("`cn'" == "motif nodes frequency")' "column names"
nw2motifs tm, sixnode generate(np) replace matrix(PM) silent
_chk `=rowsof(PM) == 10 & colsof(PM) == 148' "matrix(): 10 x 148"
_chk `=PM[1, 1] == np1[1]' "matrix and variables agree"
capture noisily nw2motifs tm, generate(np)
_chk `=_rc == 110' "an existing variable needs replace (r(110))"
capture noisily nw2motifs tm, posnorm(sum)
_chk `=_rc == 198' "posnorm() without generate() or matrix() is refused"
capture noisily nw2motifs tm, generate(zz) posnorm(nonsense)
_chk `=_rc == 198' "unknown posnorm() is refused"
qui nw2motifs tm, generate(sx) posnorm(sum)
qui egen double __rs = rowtotal(sx1-sx46)
qui count if abs(__rs - 1) > 1e-12 & !missing(__rs) & __rs != 0
_chk `=r(N) == 0' "posnorm(sum): rows add up to 1"
* a one-mode network is refused
nwclear
mata: A = (0,1,1 \ 1,0,1 \ 1,1,0)
nwset, mat(A) name(one) undirected
capture noisily nw2motifs one
_chk `=_rc == 198' "a one-mode network is refused (198)"
di as txt "3. options, stored results, refusals"

* ---- 4. valued network: ties above zero count, tie values are ignored
nwclear
mata: toy = (1,1,0,0 \ 1,1,1,0 \ 0,1,1,0 \ 0,0,1,1 \ 0,0,0,1 \ 1,0,0,1)'
nw2set, mat(toy) name(tb)
qui nw2motifs tb, sixnode generate(bb) replace
mata: V = (1,1,0,0 \ 1,1,1,0 \ 0,1,1,0 \ 0,0,1,1 \ 0,0,0,1 \ 1,0,0,1)' :* (3.5, 1, 2, 7, 0.25, 9)
nw2set, mat(V) name(tv) valued
nw2motifs tv, sixnode generate(vv) replace
_chk `=r(sixnode) == 1' "valued network runs"
forvalues j = 1/148 {
	qui count if bb`j' != vv`j'
	_chk `=r(N) == 0' "valued network gives the binary counts (position `j')"
}
di as txt "4. valued network: counts of the binary network (ties above zero)"

* ---- 5. the dialog opens; a matrix larger than Stata allows is refused with the way out
capture db nw2motifs
_chk `=(_rc == 0)' "dialog nw2motifs opens (capture db, rc `=_rc')"
nwclear
nwuse data/ftdirectors_se, nwclear
if c(max_matdim) < 5547 {
	capture noisily nw2motifs ftdirectors_se, matrix(BIG) silent
	_chk `=(_rc == 908)' "a 5,547-row matrix is refused (r(908)), generate() is the way"
}
di as txt "5. dialog, matrix limit"

di as txt "test_nw2motifs: all passed"
