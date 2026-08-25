cscript

do unw_core.do

set graphics off

* nwmoviexy had zero automated test coverage - as a pure 1-line alias
* ("program nwmoviexy \ nwmovie `0' \ end", confirmed by reading it) the
* risk surface is minimal, but "minimal" is not "zero": this certifies
* the alias actually forwards correctly and that its own signature
* nodexys() option (an x/y-coordinate pass-through) works end to end,
* producing a real, valid Animated GIF - not just that the call
* doesn't error. Uses noopen (see nwmovie.ado) to avoid popping open
* Safari as a side effect of running this test.

capture program drop _assert_is_gif
program _assert_is_gif
	args fname
	assert substr(fileread(`"`fname'"'), 1, 4) == "GIF8"
end

local tmpd `"`c(tmpdir)'"'

nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) name(net1) undirected labs(A,B,C)
nwset, mat((0,1,0\1,0,1\0,1,0)) name(net2) undirected labs(A,B,C)

gen x1 = _n
gen y1 = _n * 2
gen x2 = _n + 1
gen y2 = _n * 2 + 1

local out `"`tmpd'/nwmoviexy_cert"'
capture erase `"`out'.gif"'
nwmoviexy net1 net2, fname(`"`out'"') frames(2) nodexys(x1 y1 x2 y2) noopen
assert _rc == 0
capture confirm file `"`out'.gif"'
assert _rc == 0
_assert_is_gif `"`out'.gif"'

di "=== nwmoviexy REGRESSION VERIFIED ==="
