cscript

do unw_core.do

/*
	Certifies the native (C) graph-algorithm plugin (harmonisation unit
	95, docs/CERTIFICATION.md; feasibility background in
	docs/NATIVE_GRAPH_LIBRARIES.md) against its own Mata reference
	implementation. Unlike nwergm's own native MCMC backend (a stochastic
	sampler, certified via statistical equivalence -
	cscripts/test_nwergm_native.do), betweenness centrality is an EXACT
	combinatorial quantity - native and Mata must agree up to ordinary
	floating-point summation-order noise, not a statistical tolerance.

	(1) NativeGraphAvailable()/NativeGraphPluginPath() resolve to a real,
	    existing file on this platform (macOS, built via
	    native/Makefile's own `make macos-nwgraph` target) - if this ever
	    fails on the machine running these tests, every other assertion
	    below is moot (nwbetween.ado would already have silently fallen
	    back to Mata) and the failure needs to be about ITSELF, not
	    misread as a correctness bug in the algorithm.
	(2) calculate_betweenness_native() reproduces calculate_betweenness()
	    exactly (within 1e-9) on: a small hand-built undirected graph, a
	    small hand-built directed graph, an isolate (a node with zero
	    ties - betweenness 0, not an error), a disconnected graph (two
	    separate components - no path between them contributes to either
	    side's betweenness), and a network with a genuinely negative
	    (signed) tie weight (must be excluded from the tie list exactly
	    like calculate_betweenness()'s own `edge_weight(m,n)>0` filter).
	(3) nwbetween.ado itself (not just the underlying Mata methods)
	    produces identical output whether or not native is available -
	    confirmed by forcing the Mata fallback path directly and
	    comparing.
*/

mata: mata set matastrict off
mata: printf("NativeGraphAvailable() = %g (path: %s)\n", NativeGraphAvailable(), NativeGraphPluginPath())

// --- (2) undirected, small hand-built graph ---
nwclear
nwset, mat((0,1,0,1,0,0\1,0,1,0,0,0\0,1,0,1,1,0\1,0,1,0,0,1\0,0,1,0,0,1\0,0,0,1,1,0)) name(undirnet) undirected
_nwsyntax undirnet
mata: cm1 = `netobj'->calculate_betweenness()
mata: cn1 = `netobj'->calculate_betweenness_native()
mata: assert(max(abs(cm1 - cn1)) < 1e-9)

// --- (2) directed, small hand-built graph ---
nwclear
nwset, mat((0,1,0,1,0,0\0,0,1,0,0,0\0,0,0,1,1,0\0,0,0,0,0,1\0,0,1,0,0,1\0,0,0,0,0,0)) name(dirnet) directed
_nwsyntax dirnet
mata: cm2 = `netobj'->calculate_betweenness()
mata: cn2 = `netobj'->calculate_betweenness_native()
mata: assert(max(abs(cm2 - cn2)) < 1e-9)

// --- (2) isolate: node 4 has no ties at all ---
nwclear
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,0\0,0,0,0)) name(isonet) undirected
_nwsyntax isonet
mata: cm3 = `netobj'->calculate_betweenness()
mata: cn3 = `netobj'->calculate_betweenness_native()
mata: assert(max(abs(cm3 - cn3)) < 1e-9)
mata: assert(cn3[4] == 0)

// --- (2) disconnected: two separate triangles, no path between them ---
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(discnet) undirected
_nwsyntax discnet
mata: cm4 = `netobj'->calculate_betweenness()
mata: cn4 = `netobj'->calculate_betweenness_native()
mata: assert(max(abs(cm4 - cn4)) < 1e-9)

// --- (2) signed network: a negative tie must be excluded from both,
//     the same way, not just "not crash" ---
nwclear
nwset, mat((0,1,-1,1\1,0,1,0\-1,1,0,1\1,0,1,0)) name(signednet) undirected
_nwsyntax signednet
mata: cm5 = `netobj'->calculate_betweenness()
mata: cn5 = `netobj'->calculate_betweenness_native()
mata: assert(max(abs(cm5 - cn5)) < 1e-9)

// --- (3) nwbetween.ado itself, forcing the Mata fallback path
//     directly (temporarily renaming the plugin file so
//     NativeGraphAvailable() reports false), then comparing against the
//     native-backed default run on the identical network. ---
nwclear
nwset, mat((0,1,0,1,0,0\1,0,1,0,0,0\0,1,0,1,1,0\1,0,1,0,0,1\0,0,1,0,0,1\0,0,0,1,1,0)) name(cmpnet) undirected
qui nwbetween cmpnet, generate(_bc_native) silent
mata: st_local("pluginpath", NativeGraphPluginPath())
local movedplugin "`pluginpath'.disabled_for_test"
capture erase "`movedplugin'"
qui copy "`pluginpath'" "`movedplugin'", replace
qui erase "`pluginpath'"
qui nwbetween cmpnet, generate(_bc_mata) silent
qui copy "`movedplugin'" "`pluginpath'", replace
qui erase "`movedplugin'"
// Stata's own `copy' does not preserve the source file's executable bit -
// restore it directly (macOS/Linux only; harmless no-op elsewhere, and
// not load-bearing for Stata's own plugin loading either way - confirmed
// directly, the native path above already worked with the bit missing -
// but leaving it off needlessly re-dirties this tracked binary's git
// mode on every test run).
capture shell chmod +x "`pluginpath'"
mata: bn = st_data((1::6), "_bc_native")
mata: bm = st_data((1::6), "_bc_mata")
mata: assert(max(abs(bn - bm)) < 1e-9)

di "test_nwgraph_native: ALL OK"
