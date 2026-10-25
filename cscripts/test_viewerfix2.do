do unw_core.do

* viewerfix2: page orientation (y up), saved-coordinate round trip, edgeimport on
* directed and undirected networks, continuous edgecolor(), edgesize() widths in the page.

capture program drop _nwedit_openviewer_stub
capture program drop _nwopenviewer
program _nwopenviewer
end

* read a number list out of the embedded JSON: all values of "key":<number>
capture program drop _vf2_json
program _vf2_json
	args file key
	mata: _vf2_vals = _vf2_extract(_vf2_slurp(`"`file'"'), "`key'")
end
mata:
string scalar _vf2_slurp(string scalar path)
{
	real scalar fh
	string scalar s, chunk
	fh = fopen(path, "r"); s = ""
	while ((chunk = fread(fh, 1000000)) != J(0,0,"")) s = s + chunk
	fclose(fh)
	return(s)
}
// values of "key":number inside the data block only (after "const NODE_DATA = ")
real colvector _vf2_extract(string scalar s, string scalar key)
{
	real colvector v
	real scalar p, q, e
	string scalar pat, num
	s = substr(s, strpos(s, "const NODE_DATA = "), .)
	pat = char(34) + key + char(34) + ":"
	v = J(0, 1, .)
	p = strpos(s, pat)
	while (p > 0) {
		s = substr(s, p + strlen(pat), .)
		e = 1
		while (e <= strlen(s) & strpos("0123456789.-e+", substr(s, e, 1)) > 0) e++
		num = substr(s, 1, e - 1)
		v = v \ strtoreal(num)
		p = strpos(s, pat)
	}
	return(v)
}
end

* ---------- 1. orientation: page data and Stata plot share y ----------
nwclear
nwwebuse florentine
nwplot flomarriage, interactive noopen fname(vf2_flo) generate(fx fy) layout(circle)
local f "`r(fname)'"
* the page template flips y and the saved CSV flips it back
qui findfile nwedit_template.html
mata: st_local("flipin", strofreal(strpos(_vf2_slurp(st_global("r(fn)")), "y: -n.y * 1000") > 0))
mata: st_local("flipout", strofreal(strpos(_vf2_slurp(st_global("r(fn)")), "(-p.y / 1000)") > 0))
assert `flipin' == 1 & `flipout' == 1

* ---------- 2. saved coordinates round trip ----------
preserve
nwplot flomarriage, layout(circle) generate(rx ry) nodexy(fx fy)
restore
* simulate the viewer: it saves x,y in Stata orientation
preserve
keep fx fy
keep in 1/16
gen node_row = _n
rename (fx fy) (x y)
gen color = "26 71 111"
gen shape = "circle"
gen color_group = 1
gen shape_group = 1
gen nodefactor = 1
gen edgefactor = 1
export delimited node_row x y color shape color_group shape_group nodefactor edgefactor using "vf2_nodes.csv", replace
restore
nwplot flomarriage, nodexy(fx fy) importcoords("vf2_nodes.csv") generate(bx by)
qui corr fx bx
assert abs(r(rho) - 1) < 1e-6
qui corr fy by
assert abs(r(rho) - 1) < 1e-6

* ---------- 3. edgeimport, undirected (20 ties) and directed ----------
preserve
clear
set obs 20
gen edge_row = _n
gen color = "255 0 0"
gen style = "solid"
gen edgecolor_group = 1
export delimited using "vf2_edges20.csv", replace
set obs 40
replace edge_row = _n
replace color = "255 0 0"
replace style = "solid"
replace edgecolor_group = 1
export delimited using "vf2_edges40.csv", replace
restore
nwplot flomarriage, interactive noopen fname(vf2_u1) edgeimport("vf2_edges20.csv")
nwplot flomarriage, interactive noopen fname(vf2_u2) edgeimport("vf2_edges40.csv")
nwwebuse lazega, nwclear
nwplot lazega_adv, interactive noopen fname(vf2_d0)
_vf2_json "vf2_d0.html" "edgecolor_group"
mata: st_numscalar("nd", rows(_vf2_vals))
preserve
clear
set obs `=nd'
gen edge_row = _n
gen color = "0 0 255"
gen style = "solid"
gen edgecolor_group = 1
export delimited using "vf2_edgesd.csv", replace
restore
nwplot lazega_adv, interactive noopen fname(vf2_d1) edgeimport("vf2_edgesd.csv")
capture nwplot lazega_adv, interactive noopen fname(vf2_d2) edgeimport("vf2_edges20.csv")
assert _rc == 6056

* ---------- 4. edgesize() maps to widths in the page ----------
nwwebuse chesapeake, nwclear
nwgenerate clog = ln(chesapeake + 1)
nwplot chesapeake, arcstyle(straight) edgesize(clog) layout(mds) interactive noopen fname(vf2_es)
_vf2_json "vf2_es.html" "width"
mata: st_numscalar("wmin", min(_vf2_vals)); st_numscalar("wmax", max(_vf2_vals))
assert wmin >= 1 - 1e-6 & wmax <= 8 + 1e-6 & wmax - wmin > 3
nwplot chesapeake, arcstyle(straight) interactive noopen fname(vf2_es0)
_vf2_json "vf2_es0.html" "width"
mata: st_numscalar("wmin", min(_vf2_vals)); st_numscalar("wmax", max(_vf2_vals))
assert wmin == 3 & wmax == 3

* ---------- 5. continuous edgecolor() ----------
nwplot chesapeake, arcstyle(straight) edgecolor(clog) layout(mds) interactive noopen fname(vf2_ec)
_vf2_json "vf2_ec.html" "edgecolor_group"
mata: st_numscalar("ng", rows(uniqrows(_vf2_vals)))
assert ng >= 3 & ng <= 5
nwplot chesapeake, arcstyle(straight) edgecolor(clog) layout(mds)
* integer-valued edgecolor() stays categorical
nwgenerate cint = chesapeake > 5
nwplot chesapeake, arcstyle(straight) edgecolor(cint) layout(mds) interactive noopen fname(vf2_ec2)
_vf2_json "vf2_ec2.html" "edgecolor_group"
mata: st_numscalar("ng", rows(uniqrows(_vf2_vals)))
assert ng == 2

foreach f in vf2_flo vf2_u1 vf2_u2 vf2_d0 vf2_d1 vf2_es vf2_es0 vf2_ec vf2_ec2 {
	capture erase "`f'.html"
}
capture erase vf2_nodes.csv
capture erase vf2_edges20.csv
capture erase vf2_edges40.csv
capture erase vf2_edgesd.csv
display "PASS test_viewerfix2"
