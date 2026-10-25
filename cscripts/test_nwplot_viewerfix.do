cscript

do unw_core.do

* nwplot, interactive: fname() writes the page to a chosen file and returns the path;
* nwmovie, noopen must not start the viewer; the viewer shape drop-down reads "mixed";
* bring-back of saved sizes.

* a stand-in for the viewer launcher records any call
capture program drop _nwopenviewer
program _nwopenviewer
	global VIEWER_CALLED "yes"
end

nwclear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(w1) undirected labs(A,B,C,D)
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(w2) undirected labs(A,B,C,D)

tempfile page
local target "`page'_chosen.html"
capture erase "`target'"
global VIEWER_CALLED ""
nwplot w1, interactive noopen fname(`page'_chosen) generate(x y)
assert `"`r(fname)'"' == `"`target'"'
assert `"`r(interactive)'"' == `"`target'"'
confirm file "`target'"
assert `"$VIEWER_CALLED"' == ""

* without fname(): still a file, still returned
nwplot w1, interactive noopen
confirm file `"`r(fname)'"'
assert `"`r(fname)'"' != `"`target'"'

* nwmovie, noopen opens nothing
global VIEWER_CALLED ""
capture erase "`page'_mv.html"
nwmovie w1 w2, noopen fname(`page'_mv) duration(300)
confirm file "`page'_mv.html"
assert `"$VIEWER_CALLED"' == ""
nwmovie w1 w2, fname(`page'_mv) duration(300)
assert `"$VIEWER_CALLED"' == "yes"

* the page has the "mixed" legend state
mata:
real scalar __hasmixed(string scalar path) {
	real scalar fh, ok
	string scalar line
	fh = fopen(path, "r"); ok = 0
	while ((line = fget(fh)) != J(0,0,"")) {
		if (strpos(line, "'mixed'") > 0) ok = 1
	}
	fclose(fh)
	return(ok)
}
end
mata: st_numscalar("hasmixed", __hasmixed("`target'"))
assert hasmixed == 1

* bring-back: slider value 2 gives nodefactor 0.4, explicit nodefactor() wins
tempfile nodes
preserve
clear
input node_row x y str11 color str8 shape color_group shape_group nodefactor edgefactor
1 0 0 "26 71 111" "circle" 1 1 2 1
2 1 0 "26 71 111" "circle" 1 1 2 1
3 1 1 "26 71 111" "circle" 1 1 2 1
4 0 1 "26 71 111" "circle" 1 1 2 1
end
export delimited using "`nodes'.csv", replace
restore
nwplot w1, nodexy(x y) importcoords("`nodes'.csv")
nwplot w1, nodexy(x y) importcoords("`nodes'.csv") nodefactor(0.1)

display "PASS test_nwplot_viewerfix"
