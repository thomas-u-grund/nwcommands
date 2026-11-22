cscript

* nwnetworkdata / nwwebuse schoch without R: the reader that is written in Stata (nwnetworkdata_rda.ado).
* Part A needs neither R nor an internet connection: small .rda files are built here (an igraph object in R's serialization format,
*   uncompressed and gzip-wrapped) and read with the reader; then corrupt, truncated, oversized and malicious variants, which must all stop
*   with a clean error (r(9002) / r(610)), never hang, never produce a network.
* Part B reads real data sets from Schoch's repository (internet needed, skipped without; R is NOT needed: global nwnd_rscript points to a
*   file that does not exist, so any use of R would stop the test): karate, a directed valued network, a two-mode network, a list of
*   networks, and the one object that needs R (the egor object), which must refuse with a clear message.

do unw_core.do

local dollar = char(36)
local tmp "`c(tmpdir)'/nwnative_`c(pid)'"
capture mkdir "`tmp'"
capture mkdir "`tmp'/src"
global nwnd_cache "`tmp'/cache"
global nwnd_rscript "/no/such/Rscript"
* the reader (its Mata code stays in memory when the file is run: the helpers below use its checksum class)
findfile nwnetworkdata_rda.ado
run "`r(fn)'"
capture nwnetworkdata_rda "`tmp'/nofile.rda" "`tmp'/out"
assert _rc == 601

* ---------------------------------------------------------------------------------------------------------------
* helpers: a writer for R's serialization format (XDR) and for gzip with one stored block
* ---------------------------------------------------------------------------------------------------------------
mata:
void tw_b(real rowvector x)
{
	external real rowvector TWB
	TWB = TWB, x
}
void tw_i(real scalar x)
{
	if (x < 0) x = x + 4294967296
	tw_b((floor(x / 16777216), mod(floor(x / 65536), 256), mod(floor(x / 256), 256), mod(x, 256)))
}
void tw_d(real scalar x)
{
	transmorphic C
	string scalar buf
	C = bufio()
	bufbyteorder(C, 1)
	buf = 8 * char(0)
	bufput(C, buf, 0, "%8z", x)
	tw_b(ascii(buf))
}
void tw_s(string scalar s)
{
	// CHARSXP, ASCII
	tw_i(9 + 64 * 4096)
	tw_i(strlen(s))
	if (strlen(s) > 0) tw_b(ascii(s))
}
void tw_sym(string scalar s)
{
	tw_i(1)
	tw_s(s)
}
void tw_strvec(string rowvector s)
{
	real scalar i
	tw_i(16)
	tw_i(cols(s))
	for (i = 1; i <= cols(s); i++) tw_s(s[i])
}
void tw_realvec(real rowvector x)
{
	real scalar i
	tw_i(14)
	tw_i(cols(x))
	for (i = 1; i <= cols(x); i++) tw_d(x[i])
}
// the rda header and the first cell of the pairlist that holds the object called nm
void tw_head(string scalar nm)
{
	tw_b((ascii("RDX3"), 10, ascii("X"), 10))
	tw_i(3); tw_i(263938); tw_i(197888)
	tw_i(5); tw_b(ascii("UTF-8"))
	tw_i(2 + 1024)
	tw_sym(nm)
}
// an igraph object: n vertices, directed, edges from -> to (0-based), vertex names, optional weights
void tw_igraph(real scalar n, real scalar dir, real rowvector from, real rowvector to, string rowvector names, real rowvector w)
{
	tw_i(19 + 512 + 256)
	tw_i(10)
	tw_realvec(n)
	tw_i(10); tw_i(1); tw_i(dir)
	tw_realvec(from)
	tw_realvec(to)
	tw_i(254); tw_i(254); tw_i(254); tw_i(254)
	// attributes: (version, graph, vertex, edge)
	tw_i(19); tw_i(4)
	tw_realvec((1, 0, 1))
	tw_i(19); tw_i(0)
	tw_i(19 + 512); tw_i(1)
	tw_strvec(names)
	tw_i(2 + 1024); tw_sym("names"); tw_strvec(("name")); tw_i(254)
	if (cols(w) > 0) {
		tw_i(19 + 512); tw_i(1)
		tw_realvec(w)
		tw_i(2 + 1024); tw_sym("names"); tw_strvec(("weight")); tw_i(254)
	}
	else { tw_i(19); tw_i(0); }
	// the environment of the graph
	tw_i(253)
	// the class
	tw_i(2 + 1024); tw_sym("class"); tw_strvec(("igraph")); tw_i(254)
	// end of the pairlist
	tw_i(254)
}
void tw_save(string scalar fn)
{
	external real rowvector TWB
	real scalar fh
	transmorphic C
	(void) _unlink(fn)
	fh = fopen(fn, "w")
	C = bufio()
	fbufput(C, fh, "%1bu", TWB)
	fclose(fh)
}
// gzip with one stored block
void tw_gzip(string scalar fn, real rowvector data, real scalar flipcrc, real scalar flipdata, real scalar cut, real scalar badisize, real scalar extra, real scalar badmagic)
{
	real rowvector d, hdr, blk, trl
	real scalar fh, crcv, n
	class nwrd_crc scalar crc
	transmorphic C
	d = data
	n = cols(d)
	crc.init()
	crcv = crc.x32(crc.upd(4294967295, d), 4294967295)
	if (flipcrc) crcv = crcv + 1
	if (flipdata) d[3] = mod(d[3] + 1, 256)
	hdr = (31, 139 - badmagic, 8, 0, 0, 0, 0, 0, 0, 255)
	blk = (1, mod(n, 256), floor(n / 256), mod(65535 - n, 256), floor((65535 - n) / 256))
	trl = (mod(crcv, 256), mod(floor(crcv / 256), 256), mod(floor(crcv / 65536), 256), floor(crcv / 16777216), mod(n + badisize, 256), mod(floor(n / 256), 256), 0, 0)
	if (extra) trl = (trl, 7)
	d = (hdr, blk, d, trl)
	if (cut > 0) d = d[|1 \ cols(d) - cut|]
	(void) _unlink(fn)
	fh = fopen(fn, "w")
	C = bufio()
	fbufput(C, fh, "%1bu", d)
	fclose(fh)
}
end

* the three-node graph a - b - c (undirected), called karate: a file with 3 nodes proves that the network came from this file
local f "`tmp'/src/karate.rda"
mata: TWB = J(1, 0, 0)
mata: tw_head("karate"); tw_igraph(3, 0, (0, 1), (1, 2), ("a", "b", "c"), J(1, 0, .))
mata: tw_save("`f'")
nwnetworkdata karate, nwclear from("`tmp'/src")
_nwsyntax karate
assert `nodes' == 3
assert "`directed'" == "false"
mata: assert(rows(`netobj'->edgelist()) == 4)
mata: assert(all(`netobj'->get_nodenames() :== ("a", "b", "c")))
di "=== synthetic uncompressed .rda: 3 nodes, 2 ties, read without R ==="

* a directed valued network (weights 1.5 and 2) called rhesus
mata: TWB = J(1, 0, 0)
mata: tw_head("rhesus"); tw_igraph(3, 1, (0, 2), (1, 0), ("x", "y", "z"), (1.5, 2))
mata: tw_save("`tmp'/src/rhesus.rda")
nwnetworkdata rhesus, nwclear from("`tmp'/src")
_nwsyntax rhesus
assert `nodes' == 3
assert "`directed'" == "true"
assert "`valued'" == "true"
mata: assert(sort(`netobj'->edgelist(), (1, 2)) == (1, 2, 1.5 \ 3, 1, 2))
di "=== synthetic directed valued network ==="

* the same data, gzip-wrapped (one stored block): must give the same network; then every kind of damage
mata: TWB = J(1, 0, 0)
mata: tw_head("karate"); tw_igraph(3, 0, (0, 1), (1, 2), ("a", "b", "c"), J(1, 0, .))
mata: tw_good = TWB
mata: tw_gzip("`tmp'/src/karate.rda", tw_good, 0, 0, 0, 0, 0, 0)
nwnetworkdata karate, nwclear from("`tmp'/src") refresh
_nwsyntax karate
assert `nodes' == 3
di "=== synthetic gzip file: same network ==="

local k 0
foreach v in "1 0 0 0 0 0" "0 1 0 0 0 0" "0 0 20 0 0 0" "0 0 0 5 0 0" "0 0 0 0 1 0" "0 0 0 0 0 1" "0 0 1 0 0 0" "0 0 3 0 0 0" {
	tokenize `v'
	mata: tw_gzip("`tmp'/src/karate.rda", tw_good, `1', `2', `3', `4', `5', `6')
	capture nwnetworkdata karate, nwclear from("`tmp'/src") refresh
	assert _rc == 610
	capture nwnetworkdata_rda "`tmp'/src/karate.rda" "`tmp'/out"
	assert _rc == 9002
	assert `"$NWND_MSG"' != ""
	local ++k
	di "damaged gzip variant `v': refused with: $NWND_MSG"
}
* the decompressed size is capped (option of the reader), the compressed size too
mata: tw_gzip("`tmp'/src/karate.rda", tw_good, 0, 0, 0, 0, 0, 0)
capture nwnetworkdata_rda "`tmp'/src/karate.rda" "`tmp'/out", maxout(100)
assert _rc == 9002
di "size cap: $NWND_MSG"
capture nwnetworkdata_rda "`tmp'/src/karate.rda" "`tmp'/out", maxin(100)
assert _rc == 9002
nwnetworkdata_rda "`tmp'/src/karate.rda" "`tmp'/out"
confirm file "`tmp'/out/karate_index.csv"

mata:
void tw_rand(real scalar i)
{
	real scalar fh
	real rowvector d
	d = (31, 139, 8, 0, 0, 0, 0, 0, 0, 255, floor(256 :* runiform(1, 10 + i * 7)), 0, 0, 0, 0, 0, 0, 0, 0)
	(void) _unlink("`tmp'/src/karate.rda")
	fh = fopen("`tmp'/src/karate.rda", "w")
	fbufput(bufio(), fh, "%1bu", d)
	fclose(fh)
}
end
* garbage after a gzip header (random bytes): an error, in finite time
set seed 20261122
forvalues i = 1/40 {
	mata: tw_rand(`i')
	capture nwnetworkdata_rda "`tmp'/src/karate.rda" "`tmp'/out"
	assert inlist(_rc, 9001, 9002)
}
di "=== 40 random bodies after a gzip header: all refused ==="

* ---- the R serialization: damaged, oversized, nested, unknown ----
* (uncompressed files; every case must stop with r(9002), the closure with r(9001))
local cases "trunc hugevec hugestr deep badref badtype closure badhead empty short"
foreach c of local cases {
	mata: TWB = J(1, 0, 0)
	if "`c'" == "trunc" {
		mata: tw_head("karate"); tw_igraph(3, 0, (0, 1), (1, 2), ("a", "b", "c"), J(1, 0, .)); TWB = TWB[|1 \ 150|]
	}
	if "`c'" == "hugevec" {
		mata: tw_head("karate"); tw_i(19); tw_i(2147483647)
	}
	if "`c'" == "hugestr" {
		mata: tw_head("karate"); tw_i(16); tw_i(2147483647)
	}
	if "`c'" == "deep" {
		mata: tw_head("karate"); for (i = 1; i <= 5000; i++) { tw_i(19); tw_i(1); }; tw_i(254)
	}
	if "`c'" == "badref" {
		mata: tw_head("karate"); tw_i(255 + 99 * 256)
	}
	if "`c'" == "badtype" {
		mata: tw_head("karate"); tw_i(99)
	}
	if "`c'" == "closure" {
		mata: tw_head("karate"); tw_i(3); tw_i(254)
	}
	if "`c'" == "badhead" {
		mata: tw_b((ascii("RDX9"), 10, ascii("X"), 10, J(1, 40, 0)))
	}
	if "`c'" == "empty" {
		mata: TWB = J(1, 0, 0)
	}
	if "`c'" == "short" {
		mata: tw_b((ascii("RDX3"), 10))
	}
	mata: tw_save("`tmp'/src/karate.rda")
	capture nwnetworkdata_rda "`tmp'/src/karate.rda" "`tmp'/out"
	local rc = _rc
	if "`c'" == "closure" assert `rc' == 9001
	else assert `rc' == 9002
	di "damaged R data `c': r(`rc') `=substr(`"$NWND_MSG"', 1, 90)'"
	capture nwnetworkdata karate, nwclear from("`tmp'/src") refresh
	if "`c'" == "closure" assert _rc == 601
	else assert _rc == 610
}
* a graph whose edge points to a vertex that does not exist, and an edge list of different length
mata: TWB = J(1, 0, 0)
mata: tw_head("karate"); tw_igraph(3, 0, (0, 1), (1, 7), ("a", "b", "c"), J(1, 0, .)); tw_save("`tmp'/src/karate.rda")
capture nwnetworkdata_rda "`tmp'/src/karate.rda" "`tmp'/out"
assert _rc == 9002
mata: TWB = J(1, 0, 0)
mata: tw_head("karate"); tw_igraph(3, 0, (0, 1, 2), (1, 2), ("a", "b", "c"), J(1, 0, .)); tw_save("`tmp'/src/karate.rda")
capture nwnetworkdata_rda "`tmp'/src/karate.rda" "`tmp'/out"
assert _rc == 9002
* a vertex attribute of the wrong length is not handled (r(9001): R would be needed)
mata: TWB = J(1, 0, 0)
mata: tw_head("karate"); tw_igraph(3, 0, (0, 1), (1, 2), ("a", "b"), J(1, 0, .)); tw_save("`tmp'/src/karate.rda")
capture nwnetworkdata_rda "`tmp'/src/karate.rda" "`tmp'/out"
assert _rc == 9001
di "=== damaged and malicious R data: all refused with a clear message, no network created ==="

* nothing damaged was loaded: the last good network is still the one in memory, and no half-converted data set stays in the cache
capture confirm file "`tmp'/cache/conv/karate_index.csv"
assert _rc != 0

* ---------------------------------------------------------------------------------------------------------------
* Part B: real data sets (internet)
* ---------------------------------------------------------------------------------------------------------------
global nwnd_cache "`tmp'/cache2"
capture nwnetworkdata karate, nwclear
local rc = _rc
if inlist(`rc', 677) {
	di "SKIP part B of test_nwnetworkdata_native: no connection to GitHub (rc `rc')"
}
else {
	assert `rc' == 0
	_nwsyntax karate
	assert `nodes' == 34
	assert "`directed'" == "false"
	assert "`is2mode'" == "false"
	mata: assert(rows(`netobj'->edgelist()) == 2 * 78)
	di "=== karate: 34 nodes, 78 ties, read without R ==="
	* a directed, valued network
	nwnetworkdata rhesus, nwclear
	_nwsyntax rhesus
	assert `nodes' == 16
	assert "`directed'" == "true"
	assert "`valued'" == "true"
	* a two-mode network
	nwnetworkdata southern_women, nwclear
	_nwsyntax southern_women
	assert `nodes' == 32
	assert "`is2mode'" == "true"
	mata: assert(rows(`netobj'->edgelist()) == 2 * 89)
	* a list of networks; element(3) is one directed network of 18 monks
	nwnetworkdata sampson, nwclear element(3)
	_nwsyntax sampson_3
	assert `nodes' == 18
	assert "`directed'" == "true"
	* the whole list
	nwnetworkdata sampson, nwclear
	assert r(n_loaded) == 10
	* a data set that is compressed with bzip2 (the reader decodes it as well)
	nwnetworkdata flo_marriage, nwclear
	_nwsyntax flo_marriage
	assert `nodes' == 16
	* the egor object: the reader says that it needs R, a clear error (601 because R was made unavailable above)
	capture nwnetworkdata tables gss_egor, table(ego) clear
	assert _rc == 601
	* withr: the conversion with R, which is not available here
	capture nwnetworkdata karate, nwclear withr
	assert _rc == 601
	* the cache is used afterwards, without a connection and without R
	nwnetworkdata karate, nwclear
	di "=== list, two-mode, valued, bzip2, egor refusal: as expected ==="
}

* clean up
nwnetworkdata cache clear
global nwnd_cache ""
global nwnd_rscript ""
di "PASS test_nwnetworkdata_native"
