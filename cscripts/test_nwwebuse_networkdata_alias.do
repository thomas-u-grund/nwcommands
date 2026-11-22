cscript

* nwwebuse networkdata <name>, nwwebuse <name>, networkdata and the old keyword schoch (3.35) give identical networks.
* Needs internet for the first use of a data set (cached afterwards): skipped with a message when it is missing.

do unw_core.do

global nwnd_rscript "/no/such/Rscript"

* the overview and the list work with both keywords and without a connection
foreach kw in networkdata schoch {
	capture noisily nwwebuse `kw'
	assert _rc == 0
	capture noisily nwwebuse `kw', list
	assert _rc == 0
}

nwclear
capture noisily nwwebuse networkdata karate, nwclear name(k_a)
if inlist(_rc, 677) {
	global nwnd_rscript ""
	di "SKIP test_nwwebuse_networkdata_alias: no connection (rc `=_rc')"
	exit
}
assert _rc == 0
nwwebuse schoch karate, nwclear name(k_b)
nwwebuse karate, schoch name(k_c) nwclear
nwwebuse karate, networkdata name(k_d) nwclear
nwset
assert r(networks) == 1

* the four forms give the same network: compare the tie matrices of separate loads
local i 0
foreach cmd in "nwwebuse networkdata karate" "nwwebuse schoch karate" "nwwebuse karate, schoch" "nwwebuse karate, networkdata" {
	local ++i
	nwclear
	if strpos(`"`cmd'"', ",") `cmd' name(kk) nwclear
	else `cmd', name(kk) nwclear
	nwtomata kk, mat(Mk`i')
	nwsummarize kk
	assert r(nodes) == 34
	assert r(edges) == 78
}
mata: assert(all(Mk1 :== Mk2)); assert(all(Mk1 :== Mk3)); assert(all(Mk1 :== Mk4))

* a list of networks and a two-mode data set
foreach kw in networkdata schoch {
	nwclear
	nwwebuse `kw' sampson, nwclear
	nwset
	local n_`kw' = r(networks)
	nwclear
	nwwebuse `kw' southern_women, nwclear
	nwsummarize
	local m_`kw' = r(nodes)
}
assert `n_networkdata' == `n_schoch' & `n_networkdata' == 10
assert `m_networkdata' == `m_schoch'

* an unknown name stops with the same error for both keywords
capture nwwebuse networkdata no_such_network_xyz, nwclear
local r1 = _rc
capture nwwebuse schoch no_such_network_xyz, nwclear
assert `r1' != 0 & `r1' == _rc

global nwnd_rscript ""
di "PASS test_nwwebuse_networkdata_alias"
