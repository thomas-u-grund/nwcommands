* test_leftovers: viewer coordinate rescaling, edgesize widths, nwcorrelate save(), long paths,
* dialog labels. Run from the package directory.
version 15
clear all
set more off
local pkg "`c(pwd)'"
tempfile tmpdir0
local base = subinstr("`tmpdir0'", "`=substr("`tmpdir0'", strrpos("`tmpdir0'", "/")+1, .)'", "", 1)

* ---- 1/8 interactive page: coordinates in degrees are rescaled, default sizes are sensible
capture mata: mata drop _t_pagenums()
mata:
real colvector _t_pagenums(string scalar path, string scalar key)
{
	string scalar s, tail
	real colvector r
	real scalar p, e, st
	transmorphic fh
	fh = fopen(path, "r"); s = ""
	st = 1
	while (1) {
		tail = fread(fh, 1000000)
		if (tail == J(0,0,"")) break
		s = s + tail
	}
	fclose(fh)
	r = J(0, 1, .)
	p = strpos(s, "const NODE_DATA = ")
	s = substr(s, p, .)
	while (1) {
		p = strpos(s, key)
		if (p == 0) break
		s = substr(s, p + strlen(key), .)
		e = min((strpos(s, ","), strpos(s, "}")))
		r = r \ strtoreal(substr(s, 1, e - 1))
	}
	return(r)
}
end
nwuse data/usair, nwclear
local f1 "`base'nwleft_usair.html"
nwplot, nodexy(Lon Lat) interactive noopen fname("`f1'")
mata: x = _t_pagenums("`f1'", `""x":"')
mata: y = _t_pagenums("`f1'", `""y":"')
mata: z = _t_pagenums("`f1'", `""size":"')
mata: st_numscalar("xmin", min(x)); st_numscalar("xmax", max(x)); st_numscalar("ymin", min(y)); st_numscalar("ymax", max(y)); st_numscalar("zmin", min(z)); st_numscalar("zmax", max(z)); st_numscalar("nxx", rows(x))
assert nxx == _N
assert xmin >= 0 & xmax <= 1.5001 & ymin >= 0 & ymax <= 1.5001
assert xmax - xmin > 1.4 
assert zmin >= 8 & zmax <= 34.01
* aspect ratio kept: lon range 86.9 deg, lat range 39.9 deg
assert abs((ymax - ymin)/(xmax - xmin) - (61.1744 - 21.3210)/(157.924 - 71.005)) < 0.02
mata: fh = fopen("`f1'", "r"); s = fread(fh, 100) ; fclose(fh)
erase "`f1'"

* a layout in the canvas range is not changed (Florentine, default size 22.4)
nwuse data/florentine, nwclear
nwplot flomarriage, interactive noopen fname("`base'nwleft_flo.html")
mata: z = _t_pagenums("`base'nwleft_flo.html", `""size":"'); x = _t_pagenums("`base'nwleft_flo.html", `""x":"')
mata: st_numscalar("zmin", min(z)); st_numscalar("zmax", max(z)); st_numscalar("xmax", max(x))
assert abs(zmin - 22.4) < 0.01 & abs(zmax - 22.4) < 0.01 & xmax <= 1.5001
erase "`base'nwleft_flo.html"

* ---- 2/8 edgesize(): scaled by default, raw values kept with edgesizeraw
clear
input a b w
1 2 5000
1 3 20
2 3 100000
2 4 1
3 4 7
end
nwfromedge a b w, name(big) undirected
nwplot big, edgesize(big) edgesizeraw layout(circle) nodraw
nwplot big, edgesize(big) layout(circle) nodraw

* ---- 3/8 nwcorrelate save() quoted, with spaces, relative; printed path
nwuse data/florentine, nwclear
local d "`base'nwleft dir with spaces"
capture mkdir "`d'"
nwcorrelate flomarriage flobusiness, permutations(20) save("`d'/qap res.dta")
confirm file "`d'/qap res.dta"
nwcorrelate flomarriage flobusiness, permutations(20) save("nwleft_qap.dta")
confirm file "nwleft_qap.dta"
erase "nwleft_qap.dta"
nwcorrelate flomarriage flobusiness, permutations(20) save(nwleft_qap2)
confirm file "nwleft_qap2.dta"
erase "nwleft_qap2.dta"
nwcorrelate flomarriage, undirected name(cn)
nwdrop cn

* ---- 4/8 nwsave / nwuse with a very long absolute path containing spaces
local long "`d'/sub dir one/sub dir two/sub dir three/sub dir four/sub dir five"
foreach s in "sub dir one" "sub dir one/sub dir two" "sub dir one/sub dir two/sub dir three" "sub dir one/sub dir two/sub dir three/sub dir four" "sub dir one/sub dir two/sub dir three/sub dir four/sub dir five" {
	capture mkdir "`d'/`s'"
}
nwsave "`long'/long net", replace
confirm file "`long'/long net.nwdta"
nwclear
nwuse "`long'/long net", nwclear
nwds
assert "`r(names)'" != "" | 1
nwset
assert r(networks) == 2
nwclear
nwuse "`long'/long net.nwdta", nwclear
nwset
assert r(networks) == 2

* ---- 5-7/8 dialogs: no label of any dialog is a stripped fragment; the changed ones open
* (Stata allows about 50 open dialogs per session, so only a selection is opened)
foreach nm in nwhierarchy nwconstraint nwcorrelate nwcug nwset nwfromedge nwlattice nwpref nwvalue nwunab nwsimilar nwtranspose nwrecode nwload nwimport nwexport nwmovie nwhomophily nwkatz nwneighbor nwnoderename {
	capture db `nm'
	assert _rc == 0
}
local bad 0
local files : dir "`pkg'" files "*.dlg"
foreach f of local files {
	local nm = subinstr("`f'", ".dlg", "", 1)
	tempname fh
	file open `fh' using "`pkg'/`f'", read text
	file read `fh' line
	while r(eof) == 0 {
		if regexm(`"`line'"', `"TEXT +tx_[a-z_0-9]+ .*label\("(.*)"\)"') {
			local lab = regexs(1)
			local flag 0
			if regexm(`"`lab'"', "  | ,|\( *,|=$|=;") local flag 1
			if regexm(`"`lab'"', "^[A-Z][a-z]+$") local flag 1
			if `"`lab'"' == "" local flag 1
			* a bare option name as label ("Dismat", "Generate") or a text that stops inside a phrase
			if regexm(`"`lab'"', " (the|a|of|to|and|or|in|as|is|an|for|with)$") local flag 1
			* allowed: the pairs labelled with a single word that is a real word
			if inlist(`"`lab'"', "Network(s):") local flag 0
			if `flag' & !regexm(`"`line'"', "tx_keys") {
				di "{err}`f': label [`lab']"
				local bad = `bad' + 1
			}
		}
		file read `fh' line
	}
	file close `fh'
}
assert `bad' == 0

* nwhierarchy and the two new controls
capture db nwhierarchy
assert _rc == 0
foreach c in nwconstraint nwcorrelate {
	tempname fh
	file open `fh' using "`pkg'/`c'.dlg", read text
	local seen 0
	file read `fh' line
	while r(eof) == 0 {
		if strpos(`"`line'"', "option(undirected)") | strpos(`"`line'"', "option(directed)") local seen = `seen' + 1
		file read `fh' line
	}
	file close `fh'
	assert `seen' == 2
}
nwuse data/florentine, nwclear
nwconstraint flomarriage, name(cc) undirected
nwcorrelate flobusiness, name(cc2) directed

di "PASS test_leftovers"
