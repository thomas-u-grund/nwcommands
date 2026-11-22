cscript

* nwwebuse schoch / nwnetworkdata: networks of David Schoch's R package networkdata, read at run time from his GitHub repository.
* Needs internet for the first use of a data set (the data are cached afterwards): the test is skipped with a message when it is missing.
* R is NOT needed: the reader works with Stata alone (global nwnd_rscript below points to a file that does not exist, so any use of R
* would stop the test). Checks sizes and types, the one-line statement of what was loaded and from where, and the overview.

do unw_core.do


* the overview without a name needs no network connection
capture noisily nwwebuse schoch
assert _rc == 0
capture noisily nwwebuse schoch, list
assert _rc == 0
global nwnd_rscript "/no/such/Rscript"
tempfile lg
local oldls = c(linesize)
set linesize 250
nwclear

* karate: 34 nodes, 78 ties, undirected, one-mode (an undirected network stores each tie in both directions: 156 rows of the tie list).
* The log must state what was loaded and the source
log using `"`lg'"', text replace name(schoch_t)
capture noisily nwwebuse schoch karate, nwclear
local rc = _rc
log close schoch_t
if inlist(`rc', 677) {
	global nwnd_rscript ""
	di "SKIP test_nwwebuse_schoch: no connection (rc `rc')"
	exit
}
assert `rc' == 0
_nwsyntax karate
assert `nodes' == 34
assert "`directed'" == "false"
assert "`is2mode'" == "false"
mata: assert(rows(`netobj'->edgelist()) == 2 * 78)
tempname fh
file open `fh' using `"`lg'"', read text
local found 0
local origin 0
local noR 0
file read `fh' line
while r(eof) == 0 {
	if strpos(`"`macval(line)'"', "Loaded from Schoch's networkdata collection: karate (34 nodes, 78 ties, undirected, one-mode, binary)") local found 1
	if strpos(`"`macval(line)'"', "(data read from cache (") | strpos(`"`macval(line)'"', "(data read downloaded now") local origin 1
	if strpos(`"`macval(line)'"', "read without R") local noR 1
	file read `fh' line
}
file close `fh'
assert `found' == 1
assert `origin' == 1
assert `noR' == 1
di "=== karate: 34 nodes, 78 ties, undirected, statement of source and origin present ==="

* a second load comes from the cache and says so
log using `"`lg'"', text replace name(schoch_t)
nwwebuse schoch karate, nwclear
log close schoch_t
file open `fh' using `"`lg'"', read text
local fromcache 0
file read `fh' line
while r(eof) == 0 {
	if strpos(`"`macval(line)'"', "from cache (") local fromcache 1
	file read `fh' line
}
file close `fh'
assert `fromcache' == 1

* southern_women: two-mode, 32 nodes (18 + 14), 89 ties
nwwebuse schoch southern_women, nwclear
_nwsyntax southern_women
assert `nodes' == 32
assert "`is2mode'" == "true"
mata: assert(rows(`netobj'->edgelist()) == 2 * 89)
di "=== southern_women: two-mode, 32 nodes, 89 ties ==="

* sampson is a list of 10 directed networks of 18 monks; element(3) loads one, called sampson_3
nwwebuse schoch sampson, nwclear element(3)
_nwsyntax sampson_3
assert `nodes' == 18
assert "`directed'" == "true"
di "=== sampson, element(3): sampson_3, 18 nodes, directed ==="

* options of nwnetworkdata are passed on, name() renames
nwwebuse karate, schoch name(kk) nwclear
_nwsyntax kk
assert `nodes' == 34

* an unknown name stops with the same error as nwnetworkdata
capture nwwebuse schoch no_such_network_xyz, nwclear
assert _rc == 111

* list and describe through nwwebuse (no R, no connection needed)
nwwebuse schoch list
assert r(n_objects) > 900
nwwebuse schoch describe karate
assert "`r(obj)'" == "karate"
nwwebuse schoch, list

global nwnd_rscript ""
set linesize `oldls'
di "PASS test_nwwebuse_schoch"