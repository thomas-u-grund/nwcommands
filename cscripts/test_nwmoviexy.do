cscript

do unw_core.do

set graphics off

/*
	nwmoviexy is now a pure 1-line alias for nwmovie ("program nwmoviexy \
	nwmovie `0' \ end", confirmed by reading it) - nwmovie itself was
	rebuilt on a Cytoscape.js-based rendering pipeline (harmonisation
	unit 161), which dropped the old ImageMagick-era nodexys()/frames()
	options nwmoviexy's own prior test exercised (neither exists in
	nwmovie.ado's current syntax line at all - confirmed directly,
	"option frames() not allowed"/"option nodexys() not allowed" on any
	call). Fixed positions across waves are now produced automatically
	via nwmovie's own fixedlayout option instead of caller-supplied
	coordinates. REPLACES this file's own prior content (a real,
	working test for the old GIF-magic-byte-checking pipeline - still in
	git history if ever needed again), matching test_nwmovie.do's own
	post-rebuild verification style: confirm the alias forwards
	correctly and produces a real, structurally correct, self-contained
	HTML output, not a GIF.
*/

capture mata: mata drop __nwmoviexy_readfile()
capture mata: mata drop __nwmoviexy_filehas()
mata:
string scalar __nwmoviexy_readfile(string scalar path) {
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

void __nwmoviexy_filehas(string scalar path, string scalar needle, string scalar rname) {
	st_numscalar(rname, strpos(__nwmoviexy_readfile(path), needle) > 0)
}
end

nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) name(mvxy_net1) undirected labs(A,B,C)
nwset, mat((0,1,0\1,0,1\0,1,0)) name(mvxy_net2) undirected labs(A,B,C)

capture erase "test_nwmoviexy_cert.html"
nwmoviexy mvxy_net1 mvxy_net2, noopen fname(test_nwmoviexy_cert) duration(400) fixedlayout
assert _rc == 0
assert fileexists("test_nwmoviexy_cert.html")

mata: __nwmoviexy_filehas("test_nwmoviexy_cert.html", `"{"mode":"panel""', "chk_mode")
mata: __nwmoviexy_filehas("test_nwmoviexy_cert.html", "mvxy_net1", "chk_n1")
mata: __nwmoviexy_filehas("test_nwmoviexy_cert.html", "mvxy_net2", "chk_n2")
mata: __nwmoviexy_filehas("test_nwmoviexy_cert.html", "__NWMOVIE_", "chk_leftover")
assert chk_mode == 1
assert chk_n1 == 1
assert chk_n2 == 1
assert chk_leftover == 0 // no leftover unsubstituted placeholder
scalar drop chk_mode chk_n1 chk_n2 chk_leftover
erase "test_nwmoviexy_cert.html"

// confirm the now-dropped options are correctly rejected (matching
// nwmovie.ado's own current syntax exactly, not silently ignored) -
// the alias forwards `0' verbatim, so nwmovie's own errors surface
capture noisily nwmoviexy mvxy_net1 mvxy_net2, noopen fname(test_nwmoviexy_shouldfail) frames(2)
assert _rc == 198
capture erase "test_nwmoviexy_shouldfail.html"
capture noisily nwmoviexy mvxy_net1 mvxy_net2, noopen fname(test_nwmoviexy_shouldfail) nodexys(x y)
assert _rc == 198
capture erase "test_nwmoviexy_shouldfail.html"

di "=== nwmoviexy REGRESSION VERIFIED (post-Cytoscape.js rebuild) ==="
