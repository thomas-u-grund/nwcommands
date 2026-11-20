* _nw_gfinish: unit test of the verbs version, check, title, blk and save.
* Run from the repository root.
cscript
capture program drop nwinstall
set graphics off
run _nw_gfinish.ado
run cscripts/nw_pngwidth.do
local tmp "`c(tmpdir)'/nw_gfinish_test"
capture mkdir "`tmp'"

* ---- version
_nw_gfinish version
assert r(api) == 1
di as text "  PASS: version"

* ---- check: defaults, replace stripping
_nw_gfinish check, plot(plot) default(gof)
assert "`r(name)'" == "gof"
assert `"`r(nameopt)'"' == "name(gof, replace)"
assert r(draw) == 1
assert r(hastitle) == 0
_nw_gfinish check, plot(plot) name(mine, replace) saving(`"`tmp'/a.gph"', replace) export(`"`tmp'/a.png"', width(500)) gopts(`"scheme(s2color) title("x")"') default(gof)
assert "`r(name)'" == "mine"
assert `"`r(nameopt)'"' == "name(mine, replace)"
assert `"`r(saving)'"' == `"`tmp'/a.gph"'
assert `"`r(export)'"' == `"`"`tmp'/a.png"', width(500)"'
assert `"`r(gopts)'"' == `"scheme(s2color) title("x")"'
assert r(hastitle) == 1
_nw_gfinish check, plot(plot) saving("`tmp'/a b.gph")
assert `"`r(saving)'"' == `"`tmp'/a b.gph"'
_nw_gfinish check, default(gof)
assert r(draw) == 0
_nw_gfinish check, always default(gof) name(zz)
assert r(draw) == 1 & "`r(name)'" == "zz"
di as text "  PASS: check normalisation"

* ---- check: 198 messages
foreach o in `"name(x)"' `"saving(a.gph)"' `"export(a.png)"' `"gopts(xlabel(none))"' {
	capture _nw_gfinish check, `o' default(gof)
	assert _rc == 198
}
capture _nw_gfinish check, name(x) default(gof) cmd(estat gof)
assert _rc == 198
quietly {
	capture noisily _nw_gfinish check, name(x) default(gof) cmd(estat gof)
}
* the text itself, taken from a log
local lg `"`tmp'/msg.log"'
capture log close _msg
log using `"`lg'"', replace text name(_msg)
capture noisily _nw_gfinish check, saving(a.gph) default(gof)
capture noisily _nw_gfinish check, name(x) default(gof) cmd(estat gof)
log close _msg
tempname fh
file open `fh' using `"`lg'"', read text
local found1 0
local found2 0
file read `fh' line
while r(eof) == 0 {
	if strpos(`"`line'"', "name(), saving(), export() and graph options need plot.") & !strpos(`"`line'"', "estat gof") local found1 1
	if strpos(`"`line'"', "estat gof: name(), saving(), export() and graph options need plot.") local found2 1
	file read `fh' line
}
file close `fh'
assert `found1' == 1
assert `found2' == 1
capture _nw_gfinish check, plot(plot) name(x, keep)
assert _rc == 198
capture _nw_gfinish check, plot(plot) name("a b")
assert _rc == 198
capture _nw_gfinish check, plot(plot) saving(a.gph, append)
assert _rc == 198
* always: no need for plot
_nw_gfinish check, always name(x) saving(a.gph) default(gof)
di as text "  PASS: check 198 messages"

* ---- check: directory and SVG
capture _nw_gfinish check, plot(plot) saving(`"`tmp'/nodir/a.gph"')
assert _rc == 603
capture _nw_gfinish check, plot(plot) export(`"`tmp'/nodir/a.png"')
assert _rc == 603
_nw_gfinish check, plot(plot) saving(`"`tmp'/a.gph"')
capture _nw_gfinish check, plot(plot) export(`"`tmp'/a.svg"') svver(15)
assert _rc == 198
_nw_gfinish check, plot(plot) export(`"`tmp'/a.svg"') svver(16)
_nw_gfinish check, plot(plot) export(`"`tmp'/a.png"') svver(15)
di as text "  PASS: check directory and SVG"

* ---- title
_nw_gfinish title "Goodness of fit"
assert `"`r(t)'"' == `"title("Goodness of fit", size(medium) color(black))"'
_nw_gfinish title "Goodness of fit", size(small)
assert `"`r(t)'"' == `"title("Goodness of fit", size(small) color(black))"'
_nw_gfinish title "Goodness of fit", gopts(`"scheme(s2color) title("mine", color(red))"')
assert `"`r(t)'"' == ""
_nw_gfinish title "Goodness of fit", gopts(`"title("")"')
assert `"`r(t)'"' == ""
_nw_gfinish title "Goodness of fit", gopts(`"subtitle("s") xtitle("x")"')
assert `"`r(t)'"' == `"title("Goodness of fit", size(medium) color(black))"'
_nw_gfinish title "Sub", subtitle gopts(`"title("t")"')
assert `"`r(t)'"' == `"subtitle("Sub", color(black))"'
_nw_gfinish title "Sub", subtitle gopts(`"subtitle("t")"')
assert `"`r(t)'"' == ""
_nw_gfinish title "", size(small)
assert `"`r(t)'"' == ""
_nw_gfinish title "Time", xtitle
assert `"`r(t)'"' == `"xtitle("Time", color(black))"'
_nw_gfinish blk "Count", kind(ytitle) size(small)
assert `"`r(t)'"' == `"ytitle("Count", size(small) color(black))"'
_nw_gfinish blk "Count", kind(ytitle) gopts(`"ytitle("mine")"')
assert `"`r(t)'"' == ""
* a drawn graph: the default title is black, a user title keeps its own colour
sysuse auto, clear
_nw_gfinish title "Black default"
twoway scatter mpg weight, `r(t)' name(gf_a, replace)
_nw_gfinish title "Black default", gopts(`"title("Red", color(red))"')
twoway scatter mpg weight, `r(t)' title("Red", color(red)) name(gf_b, replace)
_nw_gfinish title "Black default", gopts(`"title("")"')
twoway scatter mpg weight, `r(t)' title("") name(gf_c, replace)
_nw_gfinish title "Plain", size(small) noblack
assert `"`r(t)'"' == `"title("Plain", size(small))"'
_nw_gfinish title "Plain", noblack
assert `"`r(t)'"' == `"title("Plain")"'
_nw_gfinish title "Plain", noblack gopts(`"title("mine")"')
assert `"`r(t)'"' == ""
_nw_gfinish check, name(x) nameok default(gof)
assert "`r(name)'" == "x" & r(draw) == 0
capture _nw_gfinish check, name(x) nameok saving(a.gph) default(gof)
assert _rc == 198
di as text "  PASS: title and blk"

* ---- save: one graph, replace, .gph extension added
foreach f in one.gph one.png many_gf_a.gph many_gf_b.gph many_gf_a.png many_gf_b.png yes_gf_a.gph yes_gf_a.png {
	capture erase `"`tmp'/`f'"'
}
_nw_gfinish save, name(gf_a) saving(`"`tmp'/one"') export(`"`tmp'/one.png"', width(400))
confirm file `"`tmp'/one.gph"'
confirm file `"`tmp'/one.png"'
assert strpos(`"`r(saved)'"', "one.gph") > 0
assert strpos(`"`r(exported)'"', "one.png") > 0
* again: replaced without asking, also with ", replace"
_nw_gfinish save, name(gf_a) saving(`"`tmp'/one.gph"', replace) export(`"`tmp'/one.png"')
* several graphs: the graph name goes before the extension
_nw_gfinish save, graphs(gf_a gf_b) saving(`"`tmp'/many.gph"') export(`"`tmp'/many.png"')
foreach g in gf_a gf_b {
	confirm file `"`tmp'/many_`g'.gph"'
	confirm file `"`tmp'/many_`g'.png"'
}
* always: the suffix also for one graph
_nw_gfinish save, graphs(gf_a) always saving(`"`tmp'/yes.gph"') export(`"`tmp'/yes.png"')
confirm file `"`tmp'/yes_gf_a.gph"'
confirm file `"`tmp'/yes_gf_a.png"'
* nothing to do without saving and export
_nw_gfinish save, name(gf_a)
assert `"`r(saved)'`r(exported)'"' == ""
* directory missing: message instead of a raw error
capture _nw_gfinish save, name(gf_a) saving(`"`tmp'/nodir/x.gph"')
assert _rc == 603
capture _nw_gfinish save
assert _rc == 198
capture _nw_gfinish nosuchverb
assert _rc == 198
di as text "  PASS: save"

* ---- save: the export options reach graph export in every calling style (width in pixels of the PNG)
* style A: literal export("f.png", width(N)); style B: the string from check wrapped in a further compound quote
* (local ex `"`r(export)'"'; export(`"`ex'"')), as the plot commands do
twoway scatter mpg weight, name(gf_w, replace)
local n 0
foreach nm in "w one" "w,comma" "w_plain" {
	local ++n
	local w = 300 + 100 * `n'
	foreach style in A B C D {
		capture erase `"`tmp'/`nm'.png"'
		if "`style'" == "A" _nw_gfinish save, name(gf_w) export(`"`tmp'/`nm'.png"', width(`w'))
		if "`style'" == "B" {
			_nw_gfinish check, plot(plot) export(`"`tmp'/`nm'.png"', width(`w'))
			local ex `"`r(export)'"'
			_nw_gfinish save, name(gf_w) export(`"`ex'"')
		}
		if "`style'" == "C" {
			* the check output wrapped twice, drawn with always (suffix _gf_w)
			_nw_gfinish check, plot(plot) export(`"`tmp'/`nm'.png"', width(`w'))
			local ex `"`r(export)'"'
			local ex2 `"`ex'"'
			_nw_gfinish save, name(gf_w) always export(`"`ex2'"')
			nw_assertwidth `"`tmp'/`nm'_gf_w.png"' `w'
			capture erase `"`tmp'/`nm'_gf_w.png"'
			continue
		}
		if "`style'" == "D" {
			* the raw string, one compound-quote layer more than the literal
			local inner `""`tmp'/`nm'.png", width(`w')"'
			_nw_gfinish save, name(gf_w) export(`"`inner'"')
		}
		nw_assertwidth `"`tmp'/`nm'.png"' `w'
	}
	capture erase `"`tmp'/`nm'.png"'
}
* style C (always, so the file carries the graph name): width too
_nw_gfinish check, always export(`"`tmp'/cc.png"', width(650))
local ex `"`r(export)'"'
_nw_gfinish save, name(gf_w) always export(`"`ex'"')
nw_assertwidth `"`tmp'/cc_gf_w.png"' 650
erase `"`tmp'/cc_gf_w.png"'
* several graphs: suffixed files, each with the width. With graphics off (headless batch runs) Stata cannot export a graph that is
* not the newest one drawn (r(693) "could not find Graph window"), also without width(); _nw_gfinish save therefore runs
* graph display on each graph before graph export. This block fails without that call.
twoway scatter mpg weight, name(gf_w, replace)
twoway scatter mpg weight, name(gf_w2, replace)
_nw_gfinish check, plot(plot) export(`"`tmp'/mm.png"', width(450))
local ex `"`r(export)'"'
_nw_gfinish save, graphs(gf_w gf_w2) export(`"`ex'"')
foreach g in gf_w gf_w2 {
	nw_assertwidth `"`tmp'/mm_`g'.png"' 450
	erase `"`tmp'/mm_`g'.png"'
}
* the older graph alone (gf_w was drawn before gf_w2), no width, and saving() of the older graph
_nw_gfinish save, name(gf_w) saving(`"`tmp'/old"') export(`"`tmp'/old.png"')
confirm file `"`tmp'/old.png"'
confirm file `"`tmp'/old.gph"'
erase `"`tmp'/old.png"'
erase `"`tmp'/old.gph"'
* saving() together with a wrapped export
local inner `""`tmp'/sv.png", width(333)"'
_nw_gfinish save, name(gf_w) saving(`"`tmp'/sv"') export(`"`inner'"')
nw_assertwidth `"`tmp'/sv.png"' 333
confirm file `"`tmp'/sv.gph"'
erase `"`tmp'/sv.png"'
erase `"`tmp'/sv.gph"'
* the string parsing itself: backslash (Windows) paths, spaces, forward slashes, commas inside the quotes
foreach f in `"C:\Users\x\My Folder\a.png"' `"D:/dir with space/a,b.png"' `"rel/a.png"' {
	local one `""`f'", width(900)"'
	local want `"`one'"'
	_nw_gfinish_unquote `"`one'"'
	assert `"`r(s)'"' == `"`want'"'
	_nw_gfinish_unquote `"`"`one'"'"'
	assert `"`r(s)'"' == `"`want'"'
	_nw_gfinish_unquote `"`"`"`one'"'"'"'
	assert `"`r(s)'"' == `"`want'"'
}
_nw_gfinish_unquote `"plain.png"'
assert `"`r(s)'"' == "plain.png"
_nw_gfinish_unquote ""
assert `"`r(s)'"' == ""
* the file name of a wrapped Windows path as the helper sees it
local inner `""`tmp'/x.png", width(900)"'
_nw_gfinish check, plot(plot) export(`"`inner'"') svver(16)
assert `"`r(export)'"' == `"`inner'"'
di as text "  PASS: export options in every calling style (pixel widths)"
di as text "ALL TESTS PASSED"
