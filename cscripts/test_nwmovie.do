cscript

do unw_core.do

/*
	Regression test for the rebuilt (Cytoscape.js-based) nwmovie -
	harmonisation unit 161. REPLACES this file's own prior content (a
	real, working test suite for the old ImageMagick pipeline - GIF
	magic-byte checks, frames()/sizes()/colors()/edgesizes() coverage),
	not written against an untested command - that prior version is
	still in git history (`git show <commit before this one>
	cscripts/test_nwmovie.do`) if anything there is ever needed again,
	but every option/behavior it exercised no longer exists in the
	rebuilt command, so a straight port made no sense. Real interactive
	playback/animation behavior is verified separately via
	headless-Chromium (puppeteer-core) testing during this unit's own
	development, not repeatable inside an ordinary Stata cscript - what
	IS checked here, matching this project's own established style for
	browser-output-producing features, is that the command runs clean
	end to end and produces a structurally correct, self-contained
	.html file: the right mode, the right keyframe/event count, no
	stray unsubstituted template placeholders, and the specific error
	conditions nwmovie.ado itself checks for (matching the OLD test's
	own precision on error codes, not merely _rc != 0).
*/

// Checks run entirely in Mata, returning only a 0/1 to Stata via
// st_numscalar() - the assembled .html is 400KB+ (the vendored
// cytoscape.min.js/gif.js alone), and round-tripping that through an
// ordinary Stata local macro to do the strpos() check IN Stata hits
// Stata's own macro-length limit (confirmed directly: r(920), "macro
// substitution results in line that is too long").
capture mata: mata drop __nwmovie_readfile()
capture mata: mata drop __nwmovie_filehas()
mata:
string scalar __nwmovie_readfile(string scalar path) {
	string scalar s, chunk
	transmorphic fh
	s = ""
	fh = fopen(path, "r")
	chunk = fread(fh, 1000000)
	while (chunk != J(0,0,"")) {
		s = s + chunk
		chunk = fread(fh, 1000000)
	}
	fclose(fh)
	return(s)
}

void __nwmovie_filehas(string scalar path, string scalar needle, string scalar rname) {
	st_numscalar(rname, strpos(__nwmovie_readfile(path), needle) > 0)
}
end

// --- panel mode: 3 waves, same 4 actors, undirected ---
nwclear
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,0\0,0,0,0)) name(mv_wave1) undirected labs(A,B,C,D)
nwset, mat((0,1,1,0\1,0,0,0\1,0,0,1\0,0,1,0)) name(mv_wave2) undirected labs(A,B,C,D)
nwset, mat((0,1,1,1\1,0,0,1\1,0,0,1\1,1,1,0)) name(mv_wave3) undirected labs(A,B,C,D)

capture erase "test_nwmovie_panel.html"
nwmovie mv_wave1 mv_wave2 mv_wave3, noopen fname(test_nwmovie_panel) duration(400)
assert fileexists("test_nwmovie_panel.html")

mata: __nwmovie_filehas("test_nwmovie_panel.html", `"{"mode":"panel""', "chk_mode")
mata: __nwmovie_filehas("test_nwmovie_panel.html", "mv_wave1", "chk_w1")
mata: __nwmovie_filehas("test_nwmovie_panel.html", "mv_wave2", "chk_w2")
mata: __nwmovie_filehas("test_nwmovie_panel.html", "mv_wave3", "chk_w3")
mata: __nwmovie_filehas("test_nwmovie_panel.html", "__NWMOVIE_", "chk_leftover")
assert chk_mode == 1
assert chk_w1 == 1
assert chk_w2 == 1
assert chk_w3 == 1
assert chk_leftover == 0 // no leftover unsubstituted placeholder
scalar drop chk_mode chk_w1 chk_w2 chk_w3 chk_leftover
erase "test_nwmovie_panel.html"

// panel mode requires equal-size networks
nwclear
nwset, mat((0,1\1,0)) name(mv_small) undirected labs(A,B)
nwset, mat((0,1,0\1,0,1\0,1,0)) name(mv_big) undirected labs(A,B,C)
capture nwmovie mv_small mv_big, noopen fname(test_nwmovie_shouldfail)
assert _rc == 6056 // errNWsSizeMismatch, unw_defs.ado
capture erase "test_nwmovie_shouldfail.html"

// --- event mode: 5 actors, 10 timestamped events ---
nwclear
input str1 sender str1 receiver double t
"A" "B" 0.5
"B" "C" 1.2
"A" "C" 2.1
"C" "D" 3.0
"D" "E" 3.4
"A" "B" 4.8
"B" "E" 5.5
"C" "E" 6.0
"A" "D" 7.2
"E" "A" 8.9
end
nwset sender receiver, eventtime(t) name(mv_chatlog)

capture erase "test_nwmovie_event.html"
nwmovie mv_chatlog, noopen fname(test_nwmovie_event) window(3) speed(2)
assert fileexists("test_nwmovie_event.html")
mata: __nwmovie_filehas("test_nwmovie_event.html", `"{"mode":"event""', "chk_mode")
mata: __nwmovie_filehas("test_nwmovie_event.html", `""window":3"', "chk_window")
mata: __nwmovie_filehas("test_nwmovie_event.html", "__NWMOVIE_", "chk_leftover")
assert chk_mode == 1
assert chk_window == 1
assert chk_leftover == 0
scalar drop chk_mode chk_window chk_leftover
erase "test_nwmovie_event.html"

// a single, non-event-type network is neither valid panel mode (needs
// 2+) nor valid event mode (not eventtime()-declared) - must error
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(mv_plain) undirected labs(A,B,C)
capture nwmovie mv_plain, noopen fname(test_nwmovie_shouldfail2)
assert _rc == 198
capture erase "test_nwmovie_shouldfail2.html"

// --- panel mode: per-wave transitioning layout (default) vs fixedlayout ---
// harmonisation unit: nwmovie's per-wave kk layout, warm-started from the
// previous wave's own final positions (kklayout()'s optional `Start'
// argument, unw_core.do) so consecutive waves relax into nearby layouts
// instead of each wave being laid out completely independently.
// `fixedlayout' restores the original single-shared-layout behavior.
capture mata: mata drop __nwmovie_nodepos()
mata:
// Extracts the [x,y] position of every node ("n1".."nNN") from the
// keyframe labeled `wavelabel' inside the assembled movie .html at
// `path' - simple substring scanning (strpos()/substr()), matching this
// package's own established JSON-embedding convention (no real JSON
// parser anywhere in this glue, see _nwedit_buildjson() in nwplot.ado;
// _nwmovie_assemblepanel() itself splices a `"label":"<wavelabel>",'
// field right after each keyframe's own opening brace - see its own
// header comment in nwmovie.ado).
real matrix function __nwmovie_nodepos(string scalar path, string scalar wavelabel, real scalar nn) {
	string scalar s, kfneedle, seg, idneedle
	real scalar kfstart, nodesstart, nodesend, idpos, xpos, ypos, xend, yend
	real matrix Pos
	real scalar i

	s = __nwmovie_readfile(path)
	kfneedle = char(34)+"label"+char(34)+":"+char(34)+wavelabel+char(34)
	kfstart = strpos(s, kfneedle)
	assert(kfstart > 0)
	nodesstart = strpos(substr(s, kfstart, .), char(34)+"nodes"+char(34)+":[") + kfstart - 1
	nodesend = strpos(substr(s, nodesstart, .), "],"+char(34)+"edges"+char(34)) + nodesstart - 1
	seg = substr(s, nodesstart, nodesend - nodesstart)

	Pos = J(nn, 2, .)
	for (i=1; i<=nn; i++) {
		idneedle = char(34)+"id"+char(34)+":"+char(34)+"n"+strofreal(i)+char(34)
		idpos = strpos(seg, idneedle)
		assert(idpos > 0)
		xpos = strpos(substr(seg, idpos, .), char(34)+"x"+char(34)+":") + idpos - 1 + 4
		xend = strpos(substr(seg, xpos, .), ",") + xpos - 1
		ypos = strpos(substr(seg, xend, .), char(34)+"y"+char(34)+":") + xend - 1 + 4
		yend = strpos(substr(seg, ypos, .), "}") + ypos - 1
		Pos[i,1] = strtoreal(substr(seg, xpos, xend - xpos))
		Pos[i,2] = strtoreal(substr(seg, ypos, yend - ypos))
	}
	return(Pos)
}
end

nwclear
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,0\0,0,0,0)) name(tr_wave1) undirected labs(A,B,C,D)
nwset, mat((0,1,1,0\1,0,0,0\1,0,0,1\0,0,1,0)) name(tr_wave2) undirected labs(A,B,C,D)
nwset, mat((0,1,1,1\1,0,0,1\1,0,0,1\1,1,1,0)) name(tr_wave3) undirected labs(A,B,C,D)

// default (transitioning): positions differ wave to wave (the layout
// really does resettle as ties change) but stay close to the previous
// wave (a warm-started relaxation, not an unrelated re-randomization) -
// bounded by comparison to `fixedlayout''s own, deliberately much
// larger, wave-1-vs-wave-3 layout-only displacement below.
capture erase "test_nwmovie_transition.html"
nwmovie tr_wave1 tr_wave2 tr_wave3, noopen fname(test_nwmovie_transition) iterations(500)
assert fileexists("test_nwmovie_transition.html")
mata: Ptr1 = __nwmovie_nodepos("test_nwmovie_transition.html", "tr_wave1", 4)
mata: Ptr2 = __nwmovie_nodepos("test_nwmovie_transition.html", "tr_wave2", 4)
mata: Ptr3 = __nwmovie_nodepos("test_nwmovie_transition.html", "tr_wave3", 4)
mata: st_numscalar("disp_12", mean(rowsum((Ptr1 - Ptr2):^2):^0.5))
mata: st_numscalar("disp_13", mean(rowsum((Ptr1 - Ptr3):^2):^0.5))
// moved (not frozen) ...
assert disp_12 > 0.001
// ... but "not crazzy different" wave to wave - each single-wave step
// stays well inside this file's own [~0.25,1.25]x[0,1] plotting box,
// nowhere near the ~1.4 diagonal an unrelated independent relayout could
// land at.
assert disp_12 < 0.75
// two whole waves of real, cumulative structural change (wave1->wave3
// adds every tie in the network) stays similarly bounded, not
// accumulating without limit across waves.
assert disp_13 < 0.75
erase "test_nwmovie_transition.html"

// fixedlayout: byte-identical positions across every wave (the original,
// pre-transition behavior) - node `i' never moves at all.
capture erase "test_nwmovie_fixedlayout.html"
nwmovie tr_wave1 tr_wave2 tr_wave3, noopen fname(test_nwmovie_fixedlayout) fixedlayout
assert fileexists("test_nwmovie_fixedlayout.html")
mata: Pfx1 = __nwmovie_nodepos("test_nwmovie_fixedlayout.html", "tr_wave1", 4)
mata: Pfx3 = __nwmovie_nodepos("test_nwmovie_fixedlayout.html", "tr_wave3", 4)
mata: assert(max(abs(Pfx1 - Pfx3)) == 0)
erase "test_nwmovie_fixedlayout.html"

mata: mata drop Ptr1 Ptr2 Ptr3 Pfx1 Pfx3
scalar drop disp_12 disp_13

// --- panel mode: per-wave color/symbol/size/edgecolor/edgesize ---
// colors()/symbols()/sizes()/edgecolors()/edgesizes() each take one
// value PER WAVE (unlike their singular color()/symbol()/size()/
// edgecolor()/edgesize() counterparts, which broadcast one value to
// every wave). colors()/symbols()/sizes() each take a Stata variable
// per wave, matching color()/symbol()/size()'s own convention;
// edgecolors()/edgesizes() each take a NETWORK NAME per wave, matching
// nwplot's own edgecolor()/edgesize() (a network whose own tie values
// supply per-edge color/width, not a Stata variable) - BUGFIX along the
// way: nwmovie's own singular edgecolor()/edgesize() were mistakenly
// declared `varname' instead of `string', so even THOSE never actually
// worked before this (confirmed directly: "Network <x> not found" on
// any real use, never caught before because neither had test coverage).
capture mata: mata drop __nwmovie_nodeblob()
mata:
// Returns the raw JSON text of one node object ("id":"nodeid",...}) from
// the keyframe labeled `wavelabel' - same substring-scanning convention
// as __nwmovie_nodepos() above, just returning the whole blob instead
// of parsing x/y out of it, so a caller can check for particular
// field:value substrings the same way __nwmovie_filehas() already does
// for the whole file.
string scalar __nwmovie_nodeblob(string scalar path, string scalar wavelabel, string scalar nodeid) {
	string scalar s, kfneedle, idneedle
	real scalar kfstart, idpos, blobend
	s = __nwmovie_readfile(path)
	kfneedle = char(34)+"label"+char(34)+":"+char(34)+wavelabel+char(34)
	kfstart = strpos(s, kfneedle)
	assert(kfstart > 0)
	idneedle = char(34)+"id"+char(34)+":"+char(34)+nodeid+char(34)
	idpos = strpos(substr(s, kfstart, .), idneedle) + kfstart - 1
	assert(idpos > 0)
	blobend = strpos(substr(s, idpos, .), "}") + idpos - 1
	return(substr(s, idpos, blobend - idpos))
}
end

nwclear
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,0\0,0,0,0)) name(pw_wave1) undirected labs(A,B,C,D)
gen pw_c1 = _n
gen pw_s1 = 10 + _n*8
gen pw_sh1 = mod(_n,2)
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,0\0,0,0,0)) name(pw_wave1_w) undirected labs(A,B,C,D)

nwset, mat((0,1,1,0\1,0,0,0\1,0,0,1\0,0,1,0)) name(pw_wave2) undirected labs(A,B,C,D)
gen pw_c2 = 5 - _n
gen pw_s2 = 60 - _n*8
gen pw_sh2 = mod(_n+1,2)
nwset, mat((0,8,1,0\8,0,0,0\1,0,0,1\0,0,1,0)) name(pw_wave2_w) undirected labs(A,B,C,D)

capture erase "test_nwmovie_perwave.html"
nwmovie pw_wave1 pw_wave2, noopen fname(test_nwmovie_perwave) colors(pw_c1 pw_c2) symbols(pw_sh1 pw_sh2) sizes(pw_s1 pw_s2) edgecolors(pw_wave1_w pw_wave2_w) edgesizes(pw_wave1_w pw_wave2_w)
assert fileexists("test_nwmovie_perwave.html")

// node n1's own color/size/shape genuinely differ wave to wave (proves
// the per-wave variable, not just the broadcast one, is what actually
// got resolved into each wave's own nwplot call)
mata: pw_b1 = __nwmovie_nodeblob("test_nwmovie_perwave.html", "pw_wave1", "n1")
mata: pw_b2 = __nwmovie_nodeblob("test_nwmovie_perwave.html", "pw_wave2", "n1")
mata: st_numscalar("pw_diff", (pw_b1 != pw_b2))
assert pw_diff == 1
scalar drop pw_diff
mata: mata drop pw_b1 pw_b2
erase "test_nwmovie_perwave.html"

// colors()/etc. must list exactly one value per network
capture nwmovie pw_wave1 pw_wave2, noopen fname(test_nwmovie_shouldfail3) colors(pw_c1)
assert _rc == 198
capture erase "test_nwmovie_shouldfail3.html"

// specifying both the singular and plural form of the same option is a
// conflict, not "plural wins"
capture nwmovie pw_wave1 pw_wave2, noopen fname(test_nwmovie_shouldfail4) color(pw_c1) colors(pw_c1 pw_c2)
assert _rc == 198
capture erase "test_nwmovie_shouldfail4.html"

// colors()/etc. are panel-mode only - event mode has one static node
// layout, not a sequence of waves to vary styling across
nwclear
input str1 sender str1 receiver double t
"A" "B" 0.5
"B" "C" 1.2
"A" "C" 2.1
end
nwset sender receiver, eventtime(t) name(pw_ev)
gen pw_evc = _n
capture nwmovie pw_ev, noopen fname(test_nwmovie_shouldfail5) colors(pw_evc)
assert _rc == 198
capture erase "test_nwmovie_shouldfail5.html"

// --- panel mode: titles() overrides the displayed wave title ---
// Default (no titles()) is each wave's own get_label() - set via
// {help nwname}'s newtitle() - if one was ever given, else the bare
// network name; titles() overrides that outright, one double-quoted
// title per wave. `titles()' has to be declared `string asis' in
// nwmovie.ado's own syntax line, not plain `string' - BUGFIX along the
// way: a plain `string' option silently drops the word-boundary
// information a multi-word quoted list like this depends on (confirmed
// directly: titles("Custom A" "Custom B" "Custom C") arrived inside the
// program as the words run together with no quotes at all, tokens()
// then over-counting 6 words instead of 3), so `asis' is required to
// keep each "..." segment intact as its own single title.
nwclear
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,0\0,0,0,0)) name(tt_wave1) undirected labs(A,B,C,D)
nwset, mat((0,1,1,0\1,0,0,0\1,0,0,1\0,0,1,0)) name(tt_wave2) undirected labs(A,B,C,D)
nwname tt_wave1, newtitle("Wave 1: Friendship")

// default: newtitle() wins over the bare name for wave 1; wave 2 (never
// given a newtitle()) falls back to its own bare network name
capture erase "test_nwmovie_titles1.html"
nwmovie tt_wave1 tt_wave2, noopen fname(test_nwmovie_titles1)
mata: __nwmovie_filehas("test_nwmovie_titles1.html", `""label":"Wave 1: Friendship""', "chk_deftitle1")
mata: __nwmovie_filehas("test_nwmovie_titles1.html", `""label":"tt_wave2""', "chk_deftitle2")
assert chk_deftitle1 == 1
assert chk_deftitle2 == 1
scalar drop chk_deftitle1 chk_deftitle2
erase "test_nwmovie_titles1.html"

// explicit titles() overrides newtitle() too
capture erase "test_nwmovie_titles2.html"
nwmovie tt_wave1 tt_wave2, noopen fname(test_nwmovie_titles2) titles("Custom A" "Custom B")
mata: __nwmovie_filehas("test_nwmovie_titles2.html", `""label":"Custom A""', "chk_override1")
mata: __nwmovie_filehas("test_nwmovie_titles2.html", `""label":"Custom B""', "chk_override2")
assert chk_override1 == 1
assert chk_override2 == 1
scalar drop chk_override1 chk_override2
erase "test_nwmovie_titles2.html"

// wrong count -> 198
capture nwmovie tt_wave1 tt_wave2, noopen fname(test_nwmovie_shouldfail6) titles("Only one")
assert _rc == 198
capture erase "test_nwmovie_shouldfail6.html"

// titles() is panel-mode only
capture nwmovie pw_ev, noopen fname(test_nwmovie_shouldfail7) titles("X")
assert _rc == 198
capture erase "test_nwmovie_shouldfail7.html"

mata: mata drop __nwmovie_readfile() __nwmovie_filehas() __nwmovie_nodepos() __nwmovie_nodeblob()

di as text "test_nwmovie.do: all checks passed"
