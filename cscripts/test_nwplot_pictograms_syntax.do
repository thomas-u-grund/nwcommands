* nwplot, interactive pictograms(): names per group in legend order, errors, and the list of names equals the page's
clear all
do unw_core.do

capture program drop _nwopenviewer
program _nwopenviewer
end

mata:
string scalar __slurp(string scalar path) {
	real scalar fh
	string scalar s, c
	fh = fopen(path, "r"); s = ""
	while ((c = fread(fh, 1000000)) != J(0,0,"")) s = s + c
	fclose(fh)
	return(s)
}
/* the pictogram written for each node, in node order, separated by | */
string scalar __pictos(string scalar path) {
	string scalar t, out, key
	real scalar p
	t = __slurp(path)
	key = char(34) + "pictogram" + char(34) + ":" + char(34)
	out = ""
	while ((p = strpos(t, key)) > 0) {
		t = substr(t, p + strlen(key), .)
		out = out + substr(t, 1, strpos(t, char(34)) - 1) + "|"
	}
	return(out)
}
end
capture program drop _pic
program _pic
	args file want
	mata: st_local("got", __pictos(st_local("file")))
	if "`got'" != "`want'" {
		di as err "pictograms are `got', expected `want'"
		exit 9
	}
end

nwclear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(net) undirected labs(A,B,C,D)
gen sex = cond(mod(_n, 2), 1, 2) in 1/4
label define sx 1 "female" 2 "male"
label values sex sx
gen str1 team = word("x y z z", _n) in 1/4
tempfile page
local o "interactive noopen"

* one per group, in the order of the legend (1 female, 2 male)
nwplot net, color(sex) symbol(sex) `o' pictograms(woman man) fname(`page'_a)
_pic "`r(fname)'" "woman|man|woman|man|"
* one name for all nodes, without color() or symbol()
nwplot net, `o' picto(star) fname(`page'_b)
_pic "`r(fname)'" "star|star|star|star|"
* groups of color() when there is no symbol(); commas and capitals are accepted, a full stop keeps a shape
nwplot net, color(team) `o' pictograms(House, ., CAR) fname(`page'_c)
_pic "`r(fname)'" "house||car|car|"
* groups of symbol() when these differ from the colors
nwplot net, color(sex) symbol(team) `o' pictograms(bank church shop) fname(`page'_d)
_pic "`r(fname)'" "bank|church|shop|shop|"
* without the option no node has a pictogram, and the page applies those of the option when it is opened
nwplot net, color(sex) `o' fname(`page'_e)
_pic "`r(fname)'" "||||"
local html "`r(fname)'"
mata: assert(strpos(__slurp(st_local("html")), "n.shape = ICON_PREFIX + n.pictogram") > 0)

* errors: nothing is written
foreach bad in "pictograms(unicorn)" "pictograms(man woman star)" {
	capture noisily nwplot net, color(sex) `o' `bad' fname(`page'_x)
	assert _rc == 198
	capture confirm file "`page'_x.html"
	assert _rc != 0
}
capture noisily nwplot net, pictograms(star)
assert _rc == 198

* Save do-file writes a command for a Stata graph: the page option is not in it
nwplot net, color(sex) `o' pictograms(man woman) fname(`page'_f)
local html "`r(fname)'"
mata:
t = __slurp(st_local("html"))
t = substr(t, strpos(t, "const STATA_CMD = "), .)
t = substr(t, 1, strpos(t, char(10)))
assert(strpos(t, "color(sex)") > 0 & strpos(t, "picto") == 0)
end

* the names the option accepts are the pictograms of the page
findfile nwedit_template.html
local tpl "`r(fn)'"
mata:
t = __slurp(st_local("tpl"))
t = substr(t, strpos(t, "const ICONS = {"), .)
t = substr(t, 1, strpos(t, "const ICON_GROUPS"))
L = ustrsplit(t, char(10))
names = J(1, 0, "")
for (i = 1; i <= cols(L); i++) if (regexm(L[i], "^  ([a-z]+): +'M")) names = names, regexs(1)
st_local("pagenames", invtokens(names))
end
assert `: word count `pagenames'' > 30
* every pictogram of the page is accepted by the command
local k 0
foreach w of local pagenames {
	local ++k
	qui nwplot net, `o' pictograms(`w') fname(`page'_g`k')
}
findfile nwplot.ado
mata: s = __slurp(st_global("r(fn)")); s = substr(s, strpos(s, "local known " + char(34)) + 13, .)
mata: st_local("adonames", substr(s, 1, strpos(s, char(34)) - 1))
local d1 : list pagenames - adonames
local d2 : list adonames - pagenames
assert "`d1'`d2'" == ""

display "PASS test_nwplot_pictograms_syntax"
