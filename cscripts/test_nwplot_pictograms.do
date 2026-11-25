cscript

do unw_core.do

* nwplot, interactive: the page offers the pictograms; node-size legend labels carry no long
* binary fractions (9.870000000000001).

capture program drop _nwopenviewer
program _nwopenviewer
end

nwclear
nwset, mat((0,1.07,0,0\1.07,0,5,0\0,5,0,9.87\0,0,9.87,0)) name(w1) undirected labs(A,B,C,D)
gen wealth = cond(_n==1, 1.05, cond(_n==2, 9.87, 5)) in 1/4
gen str6 sex = cond(mod(_n,2), "female", "male") in 1/4

tempfile page svg
nwplot w1, color(sex) symbol(sex) size(wealth) interactive noopen fname(`page'_pict)
local html `"`r(fname)'"'

mata:
string scalar __slurp(string scalar path) {
	real scalar fh
	string scalar s, c
	fh = fopen(path, "r"); s = ""
	while ((c = fread(fh, 1000000)) != J(0,0,"")) s = s + c
	fclose(fh)
	return(s)
}
t = __slurp(st_local("html"))
assert(strpos(t, "const ICONS = {") > 0)
assert(strpos(t, "const ICON_GROUPS = {") > 0)
assert(strpos(t, "function plainShape") > 0 | strpos(t, "const plainShape") > 0)
assert(strpos(t, "wealth = 1.05" + char(34)) > 0)
assert(strpos(t, "wealth = 9.87" + char(34)) > 0)
assert(strpos(t, "9.870000000000001") == 0)
end

* static graph: node-size legend labels
local svgfile `"`c(tmpdir)'/nwpict_legend.svg"'
nwplot w1, size(wealth) export(`"`svgfile'"') replace
mata:
t = __slurp(st_local("svgfile"))
assert(strpos(t, "wealth = 9.87<") > 0)
assert(strpos(t, "wealth = 1.05<") > 0)
assert(strpos(t, "9.870000") == 0)
end
capture erase `"`svgfile'"'

di "PASS test_nwplot_pictograms"
