cscript

do unw_core.do

set graphics off

* nwmovie had zero automated test coverage, already flagged as an open
* item in docs/CERTIFICATION.md's own Pending table following the
* _nwsyntax_other fix that made it work end to end for the first time -
* still unaddressed until now. Requires ImageMagick (confirmed present
* in this environment: /opt/homebrew/bin/convert). Uses noopen
* throughout (a new option, added alongside this file - see
* nwmovie.ado's own header comment) so this test never pops open
* Safari as an uncontrollable side effect of simply calling the
* command, which is exactly what running this file unattended would
* otherwise do on every single call.

capture program drop _assert_is_gif
program _assert_is_gif
	args fname
	assert substr(fileread(`"`fname'"'), 1, 4) == "GIF8"
end

local tmpd `"`c(tmpdir)'"'

nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) name(net1) undirected labs(A,B,C)
nwset, mat((0,1,0\1,0,1\0,1,0)) name(net2) undirected labs(A,B,C)
nwset, mat((0,0,1\0,0,1\1,1,0)) name(net3) undirected labs(A,B,C)

* --- basic two-network movie: a real, valid Animated GIF is produced.
local out1 `"`tmpd'/nwmovie_cert1"'
capture erase `"`out1'.gif"'
nwmovie net1 net2, fname(`"`out1'"') frames(2) noopen
assert _rc == 0
capture confirm file `"`out1'.gif"'
assert _rc == 0
_assert_is_gif `"`out1'.gif"'

* --- three networks, with per-time-point sizes()/colors() and node
* labels - exercises the time_options family together.
gen attrval = _n
gen colorval = mod(_n, 2)
local out2 `"`tmpd'/nwmovie_cert2"'
nwmovie net1 net2 net3, fname(`"`out2'"') frames(2) sizes(attrval attrval attrval) colors(colorval colorval colorval) lab noopen
assert _rc == 0
capture confirm file `"`out2'.gif"'
assert _rc == 0
_assert_is_gif `"`out2'.gif"'

* --- time-invariant singular forms (size()/color()/title(), not the
* plural sizes()/colors()/titles()) apply the same value to every time
* point - exercised together since they all funnel through the
* identical "replicate across `networks'" preprocessing block.
local out3 `"`tmpd'/nwmovie_cert3"'
nwmovie net1 net2 net3, fname(`"`out3'"') frames(2) size(attrval) color(colorval) title("fixed title") noopen
assert _rc == 0
capture confirm file `"`out3'.gif"'
assert _rc == 0
_assert_is_gif `"`out3'.gif"'

* moderate-severity pass, visualization group: edgesizes()'s per-frame
* interpolation was dead code (nwmovie.ado's own guard tested the
* wrong, permanently-empty local `edgesize' instead of `edgesizes') -
* edges only ever snapped to the correct width at the start/end frame
* of each transition, not the frames in between. This call exercises
* that exact code path (edgesizes() with more than 1 frame, so the
* per-frame interpolation branch actually runs); a real regression
* would need frame-by-frame pixel inspection to catch precisely, which
* is out of scope here, but this at minimum confirms the previously
* dead-and-never-exercised branch (nwgenerate _frame_edgesize ...) now
* actually runs without erroring, which it could not do at all before
* this fix (the condition guarding it was always false).
local out4 `"`tmpd'/nwmovie_cert4"'
nwmovie net1 net2, fname(`"`out4'"') frames(3) edgesizes(net1 net2) noopen
assert _rc == 0
capture confirm file `"`out4'.gif"'
assert _rc == 0
_assert_is_gif `"`out4'.gif"'

* --- mismatched network sizes are rejected cleanly, not silently
* plotted wrong.
nwclear
nwset, mat((0,1\1,0)) name(small1) undirected labs(A,B)
nwset, mat((0,1,1\1,0,0\1,0,0)) name(big1) undirected labs(A,B,C)
capture noisily nwmovie small1 big1, noopen
assert _rc == 6056

* --- moderate-severity pass regression: a single network (violating
* netlist's own documented/enforced minimum of 2) used to crash with a
* raw Mata "subscript invalid" error (r3301) instead of a clear
* message.
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) name(onlyone) undirected labs(A,B,C)
capture noisily nwmovie onlyone, noopen
assert _rc == 198

di "=== nwmovie REGRESSION VERIFIED ==="
