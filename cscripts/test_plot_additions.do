cscript
nwclear
do unw_core.do

* 3.20.0: nwplot basemap(), the Save do-file button of the interactive page (the nwplot call embedded in
* the page), and the group names of nwplotmatrix, group().

set graphics off
// run from the repository: the example data of this checkout (usmap is new in this release)
capture confirm file "data/usmap.dta"
if !_rc global nwwebpath "`c(pwd)'/data"

// 1 if the file holds the text in the global macro tpa_needle (read in Mata: the page holds backquotes)
capture mata: mata drop _tpa_has()
mata:
real scalar _tpa_has(string scalar f, string scalar needle)
{
	real scalar fh
	string scalar s, c
	fh = fopen(f, "r")
	s = ""
	while ((c = fread(fh, 1000000)) != J(0, 0, "")) s = s + c
	fclose(fh)
	return(strpos(s, needle) > 0)
}
end
capture program drop _tpa_check
program _tpa_check
	args f want
	mata: st_local("has", strofreal(_tpa_has(st_local("f"), st_global("tpa_needle"))))
	assert `has' == `want'
end

// 1. basemap(): the US state outlines under the airports
nwwebuse usair, nwclear
nwplot usair, nodexy(Lon Lat) basemap(usmap) arcstyle(straight) name(bm1, replace)
// line options after the comma, the file given with its extension
nwplot usair, nodexy(Lon Lat) basemap("$nwwebpath/usmap.dta", lcolor(gs13) lwidth(thin)) name(bm2, replace)
// part of the map with if (a condition on the map file), with the if of nwplot and line options
nwplot usair if Lat < 50 & Lon > -125, nodexy(Lon Lat) basemap(usmap if !inlist(state, "AK", "HI"), lcolor(gs13)) name(bm3, replace)
// a condition that the map file cannot evaluate is refused
capture nwplot usair, nodexy(Lon Lat) basemap(usmap if nosuchvar == 1)
assert _rc == 198
// without nodexy() it is refused
capture nwplot usair, basemap(usmap)
assert _rc == 198
// a file without _X and _Y is refused
preserve
clear
set obs 3
gen a = _n
tempfile nomap
save `nomap'
restore
capture nwplot usair, nodexy(Lon Lat) basemap("`nomap'")
assert _rc != 0
// a file that does not exist
capture nwplot usair, nodexy(Lon Lat) basemap("./no/such/map.dta")
assert _rc == 601
// the data in memory are unchanged (the plot works on a copy)
assert _N == 50
capture confirm variable __nwp_bmx
assert _rc != 0
// the map file itself: 50 states and DC, longitudes west of -66, no wrap-around at 180 degrees
preserve
use "$nwwebpath/usmap.dta", clear
qui levelsof state
assert r(r) == 51
qui summarize _X
assert r(max) < -66 & r(min) > -190
restore

// 2. the interactive page carries the nwplot call for its Save do-file button
nwwebuse lazega, nwclear
tempfile page
local page "`page'.html"
nwplot lazega_adv if office != "Providence", color(office) symbol(practice) generate(x y) interactive noopen fname("`page'") title("Advice")
global tpa_needle "saveDoBtn"
_tpa_check "`page'" 1
global tpa_needle `"const STATA_CMD = {"netname": "lazega_adv", "ifin": "if office != \"Providence\"", "options": "color(office) symbol(practice) title(\"Advice\")"};"'
_tpa_check "`page'" 1
// the placeholder is always replaced
global tpa_needle "__NWEDIT_STATACMD__"
_tpa_check "`page'" 0
// the current network, no options
nwplot, interactive noopen fname("`page'")
global tpa_needle `"const STATA_CMD = {"netname": "lazega_adv", "ifin": "", "options": ""};"'
_tpa_check "`page'" 1

// 3. nwplotmatrix, group(): names of the groups beside the blocks
nwplotmatrix lazega_adv, group(office) name(pm1, replace)
nwplotmatrix lazega_adv, group(office) nogrouplabels name(pm2, replace)
nwplotmatrix lazega_adv, group(office, lcolor(red) lwidth(thin)) lab name(pm3, replace)
// value labels of a numeric group variable
nwwebuse florentine, nwclear
gen rich = wealth > 50
label define richl 0 "poor" 1 "rich"
label values rich richl
nwplotmatrix flomarriage, group(rich) name(pm4, replace)
graph describe pm4
tempfile svg
graph export "`svg'.svg", name(pm4) as(svg) replace
global tpa_needle ">poor<"
_tpa_check "`svg'.svg" 1
global tpa_needle ">rich<"
_tpa_check "`svg'.svg" 1
nwplotmatrix flomarriage, group(rich) nogrouplabels name(pm5, replace)
graph export "`svg'.svg", name(pm5) as(svg) replace
global tpa_needle ">poor<"
_tpa_check "`svg'.svg" 0

di "test_plot_additions: all checks passed"
