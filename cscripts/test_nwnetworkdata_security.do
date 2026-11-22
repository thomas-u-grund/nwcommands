cscript

* nwnetworkdata / nwwebuse schoch: input checks. No internet and no R needed: every call below must stop with a clean error
* BEFORE anything is downloaded or any program is started. The canary file would be created if a shell command were built
* from a name or a path.

do unw_core.do

local canary "`c(tmpdir)'/nw_pwned_canary"
capture erase "`canary'"
tempname fh

* ---- names: shell metacharacters, quotes, path parts, empty ----
foreach bad in "karate; touch `canary'" "karate && touch `canary'" "karate|touch `canary'" "../karate" "karate/../x" "ka rate" {
	capture nwnetworkdata load `"`bad'"', nwclear
	assert inlist(_rc, 198, 111)
	capture nwwebuse schoch `"`bad'"', nwclear
	assert inlist(_rc, 198, 111)
	capture nwnetworkdata describe `"`bad'"'
	assert inlist(_rc, 198, 111)
	capture nwnetworkdata edges `"`bad'"', clear
	assert inlist(_rc, 198, 111)
	capture nwnetworkdata nodes `"`bad'"', clear
	assert inlist(_rc, 198, 111)
	capture nwnetworkdata tables `"`bad'"', table(ego) clear
	assert inlist(_rc, 198, 111, 459)
}
* a name with a $ or back quote (not expanded by Stata when it is written in a macro)
local dollar = char(36)
capture nwnetworkdata load "karate`dollar'(touch `canary')", nwclear
assert inlist(_rc, 198, 111)
local bq = char(96)
capture nwnetworkdata load `"karate`bq'touch `canary'`bq'"', nwclear
assert inlist(_rc, 198, 111, 132)
capture nwnetworkdata list "x; touch `canary'"
assert _rc == 198
capture nwnetworkdata
assert _rc == 198
* a name that is well formed but not in the catalogue: unknown, nothing is downloaded
capture nwnetworkdata load no_such_network_xyz, nwclear
assert _rc == 111
capture nwnetworkdata tables karate, table(ego) clear
assert _rc == 459
capture nwnetworkdata tables gss_egor, table(foo) clear
assert _rc == 198

* ---- from(): only the official repository or an existing local folder ----
foreach bad in "https://evil.example.com/data" "http://raw.githubusercontent.com/schochastics/networkdata/main/data" ///
	"https://raw.githubusercontent.com/schochastics/networkdata/../../evil/x" "ftp://example.com/x" "file:///etc" ///
	"https://raw.githubusercontent.com/schochastics/networkdata/main/data; touch `canary'" {
	capture nwnetworkdata load karate, from(`"`bad'"') nwclear
	assert _rc == 198
	capture nwnetworkdata source set `"`bad'"'
	assert _rc == 198
}
capture nwnetworkdata load karate, from("/no/such/folder/for/schoch") nwclear
assert _rc == 601
capture nwnetworkdata load karate, from("`c(tmpdir)'/x`dollar'(touch `canary')") nwclear
assert _rc == 198
capture nwnetworkdata load karate, from(`"`c(tmpdir)'/x"; touch `canary'"') nwclear
assert _rc == 198
global nwnd_source "https://evil.example.com/data"
capture nwnetworkdata load karate, nwclear
assert _rc == 198
global nwnd_source ""
capture nwnetworkdata source default
assert _rc == 0
nwnetworkdata source

* ---- cache, R script and R location from the globals ----
global nwnd_cache "`c(tmpdir)'/nwnd`dollar'(touch `canary')"
capture nwnetworkdata load karate, nwclear
assert _rc == 198
global nwnd_cache ""
* an (empty) local file karate.rda gets the conversion as far as the R location: a missing Rscript is r(601), not a shell error
local fake "`c(tmpdir)'/nwnd_fake_rda"
capture mkdir "`fake'"
file open `fh' using "`fake'/karate.rda", write text replace
file write `fh' "not an rda file" _n
file close `fh'
global nwnd_cache "`c(tmpdir)'/nwnd_fake_cache"
global nwnd_rscript "/no/such/Rscript"
capture nwnetworkdata load karate, nwclear from("`fake'")
assert _rc == 601
global nwnd_rscript ""
* R is found, but the file is not a valid .rda: r(601) with the message of R, nothing else happens
capture nwnetworkdata load karate, nwclear from("`fake'")
assert inlist(_rc, 601)
global nwnd_cache ""
capture erase "`fake'/karate.rda"
capture rmdir "`fake'"

* ---- element(): a numlist of positive integers ----
capture nwnetworkdata load sampson, element(3; touch `canary') nwclear
assert inlist(_rc, 121, 198)
capture nwnetworkdata load sampson, element(abc) nwclear
assert inlist(_rc, 121, 198)
capture nwnetworkdata load sampson, element(-1) nwclear
assert inlist(_rc, 121, 125, 198)
* name() and valueattr() are Stata names
capture nwnetworkdata load karate, name("a; touch `canary'") nwclear
assert _rc != 0

* ---- nothing was executed ----
capture confirm file "`canary'"
assert _rc != 0
* the catalogue of names still lists, without R and without internet
nwnetworkdata list karate
assert r(n_objects) == 2
nwwebuse schoch
nwwebuse schoch describe karate
di "PASS test_nwnetworkdata_security"
