cscript

do unw_core.do

set graphics off

* Real regression test for a genuine bug found while writing the
* visualization tutorial: `local last "`geps'.eps"' already held the
* full "name.eps" filename, but the shell command that builds the GIF
* appended ANOTHER ".eps" onto it ("-delay `lastdelay' `last'.eps"),
* so ImageMagick was always asked to read a "name.eps.eps" file that
* never existed - `animate' failed on every real invocation with more
* than one graph. Skips cleanly (rather than failing) on a machine
* without ImageMagick installed, since that is a real, documented,
* external prerequisite for this command, not something nwcommands
* itself controls.
capture shell which convert
local hasimagemagick = (_rc == 0)

if `hasimagemagick' {
	local tmpd `"`c(tmpdir)'"'
	local gifout `"`tmpd'/nwcommands_test_animate.gif"'
	capture erase `"`gifout'"'

	nwclear
	nwrandom 8, prob(.3)
	graph drop _all
	nwplot, generate(x y)
	nwplot, nodexy(x y) name(g1)
	nwrandom 8, prob(.3)
	nwplot, nodexy(x y) name(g2)

	local olddir `"`c(pwd)'"'
	cd `"`tmpd'"'
	animate nwcommands_test_animate, graphs(g1 g2) delay(50) keepeps
	cd `"`olddir'"'

	capture confirm file `"`gifout'"'
	assert _rc == 0

	* a real, non-empty GIF - not the empty/error output the
	* double-extension bug used to leave behind
	local gifcontent = fileread(`"`gifout'"')
	assert strlen(`"`gifcontent'"') > 0
	assert substr(`"`gifcontent'"', 1, 3) == "GIF"

	capture erase `"`gifout'"'
	capture erase `"`tmpd'/g1.eps"'
	capture erase `"`tmpd'/g2.eps"'
}
else {
	di as text "ImageMagick not found - skipping animate real-output check"
}

graph drop _all
exit, clear
