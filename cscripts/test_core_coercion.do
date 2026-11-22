do unw_core.do

* Coercion sweep (3.35, unreleased): no command treats a network as another type than it is unless the user asks by an
* option, and every coercion is stated in the output. One section per command (A1, A2, ...). Run from the repository
* root. References: igraph 2.3.2 (values hard-coded below, 1e-9) and, for undirected binary networks, the numbers of
* the branch before this sweep (3.34.0 plus the directed betweenness / closeness / evcent change).

local tol 1e-9
global tcc_out "`c(tmpdir)'/tcc_golden_new.txt"
set linesize 255

capture program drop _tcc_log
program _tcc_log
	* run a command with the log on; every needle must be in its output (needles separated by |), none of the nonneedles
	args needles cmd
	tempfile lg
	qui log using `"`lg'"', text replace name(tcclog)
	capture noisily `cmd'
	local rc = _rc
	qui log close tcclog
	mata: st_local("__L", stritrim(invtokens(cat(st_local("lg"))')))
	local __rest `"`needles'"'
	while `"`__rest'"' != "" {
		gettoken one __rest : __rest, parse("|")
		if `"`one'"' == "|" continue
		if !strpos(`"`__L'"', `"`one'"') {
			di as err `"FAIL: the output of {`cmd'} does not contain "`one'""'
			exit 9
		}
	}
	exit `rc'
end

capture program drop _tcc_near
program _tcc_near
	args x ref tol label
	if abs(`x' - `ref') > `tol' | missing(`x') {
		di as err "FAIL: `label' (`x' against `ref')"
		exit 9
	}
end

nwuse data/lazega, nwclear
nwuse data/glasgow, nwappend
nwuse data/gahuku, nwappend
nwuse data/davis, nwappend
qui nwload lazega_adv
qui gen xa = mod(_n*7, 5) + 1

* ---------------------------------------------------------------- A1. nwassortativity
nwassortativity lazega_adv
_tcc_near `r(assortativity)' -0.0301746072337015 `tol' "A1 directed degree assortativity = igraph directed"
assert `"`r(directed)'"' == "true"
_tcc_log "directed network: out-degree of the sender against in-degree of the receiver" "nwassortativity lazega_adv"
nwassortativity lazega_adv, sym
_tcc_near `r(assortativity)' -0.0801247207887384 `tol' "A1 sym = igraph on the collapsed network"
_tcc_log "directed network symmetrized" "nwassortativity lazega_adv, sym"
nwassortativity lazega_adv, attribute(xa)
_tcc_near `r(assortativity)' -0.00986686920981053 `tol' "A1 directed attribute"
_tcc_log "the attribute of the sender against that of the receiver" "nwassortativity lazega_adv, attribute(xa)"
nwassortativity glasgow1
_tcc_near `r(assortativity)' 0.150880794508067 `tol' "A1 glasgow1 directed"
_tcc_log "undirected network" "nwassortativity gahuku"

* ---------------------------------------------------------------- A2. nwcomponents
* igraph::components(mode = "strong") on lazega_fr (3 components, largest 69) and glasgow1 (14, largest 14); weak: 1 and 8
foreach n in lazega_fr glasgow1 {
	local ns = cond("`n'" == "lazega_fr", 3, 14)
	local nw = cond("`n'" == "lazega_fr", 1, 8)
	nwcomponents `n', generate(cs_`n')
	assert r(components) == `ns'
	assert `"`r(connected)'"' == "strong"
	* same partition as igraph: every igraph component maps to one of ours and the other way round
	qui gen long ig_`n' = .
	mata: st_store((1, rows(IG = strtoreal(cat("cscripts/directed_fixture/`n'_strong_igraph.txt")))), "ig_`n'", IG)
	qui egen byte nn_`n' = group(cs_`n' ig_`n')
	qui summ nn_`n'
	assert r(max) == `ns'
	nwcomponents `n', generate(cw_`n') weak
	assert r(components) == `nw'
	assert `"`r(connected)'"' == "weak"
}
_tcc_log "directed network: strongly connected components" "nwcomponents lazega_fr, generate(cs2)"
_tcc_log "directed network: weakly connected components" "nwcomponents lazega_fr, generate(cs3) weak"
_tcc_log "undirected network" "nwcomponents gahuku, generate(cs4)"
* a network that is not strongly connected but is weakly connected: path 1>2>3, cycle-free
nwset, mat((0,1,0\0,0,1\0,0,0)) name(pth) directed
nwcomponents pth, generate(pc)
assert r(components) == 3
nwcomponents pth, generate(pw) weak
assert r(components) == 1
* undirected: unchanged (the weak components are the components)
nwcomponents gahuku, generate(cg)
assert `"`r(connected)'"' == "undirected"
* missing ties are reported
nwset, mat((0,1,.\1,0,0\.,0,0)) name(mis) undirected
_tcc_log "1 missing ties treated as 0" "nwcomponents mis, generate(mc)"
nwset, mat((0,1,.\0,0,1\1,0,0)) name(mis2) directed
_tcc_log "1 missing ties treated as 0" "nwcomponents mis2, generate(mc2)"

* ---------------------------------------------------------------- A3. nwclustering
* directed clustering: a path a -> i -> b closed by a -> b (hand-computed in R from the matrix); the output says so
nwclustering lazega_adv, generate(cl1)
_tcc_near `r(cluster_global)' 0.329310892346777 `tol' "A3 lazega_adv global"
_tcc_near `r(cluster_avg)' 0.361068395667964 1e-7 "A3 lazega_adv average"
_tcc_log "directed network: a path a -> i -> b is closed by the tie a -> b" "nwclustering lazega_adv, generate(cl2) replace"
_tcc_log "directed network symmetrized" "nwclustering lazega_adv, generate(cl2) replace symmetrize"
nwclustering lazega_adv, generate(cl2) replace symmetrize
_tcc_near `r(cluster_global)' 0.422925152749491 `tol' "A3 symmetrize = igraph transitivity of the collapsed network"
_tcc_log "undirected network" "nwclustering gahuku, generate(cl3) replace"
_tcc_log "valued network: tie values ignored" "nwclustering gahuku, generate(cl3) replace measure(binary)"
nwset, mat((0,1,.\1,0,1\.,1,0)) name(mis3) undirected
_tcc_log "1 missing ties treated as 0" "nwclustering mis3, generate(cl4) replace"
clear
qui nwload davis
_tcc_log "two-mode network: Opsahl's two-mode clustering of the nodes of mode 2" "nwclustering davis, generate(cl5) replace level(2)"
_tcc_log "two-mode network read as the one-mode network of the bipartite graph" "nwclustering davis, generate(cl5) replace onemode"

* ---------------------------------------------------------------- A4. nwrandomwalk
* directed walk: hitting times from the linear system solved in R on the row-normalised matrix (lazega_adv, target n13)
nwload lazega_adv
nwrandomwalk lazega_adv, target(n13) generate(rw1) silent
_tcc_near `=rw1[1]' 33.7515788480639 `tol' "A4 directed hitting time of node 1"
_tcc_near `=rw1[10]' 35.4957674947171 `tol' "A4 directed hitting time of node 10"
assert rw1[5] == 0 | rw1[13] == 0
nwrandomwalk lazega_adv, target(n13) generate(rw2) sym silent
_tcc_near `=rw2[1]' 38.7312516061468 `tol' "A4 sym = walk on the symmetrized network (results of 3.34.0)"
_tcc_log "directed network: the walk follows the direction of the ties" "nwrandomwalk lazega_adv, target(n13) generate(rw3)"
_tcc_log "directed network symmetrized" "nwrandomwalk lazega_adv, target(n13) generate(rw3) replace sym"
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri) undirected labs(A,B,C)
_tcc_log "undirected network" "nwrandomwalk tri, target(A) generate(rw4) replace"
* a node from which the target is not reached with certainty has a missing hitting time: 1 -> 2 -> 3, 1 -> 4 (4 is a dead end)
nwset, mat((0,1,0,1\0,0,1,0\0,0,0,0\0,0,0,0)) name(dead) directed labs(a,b,c,d)
nwrandomwalk dead, target(c) generate(rw5) silent
assert missing(rw5[1]) & rw5[2] == 1 & rw5[3] == 0 & missing(rw5[4])

* ---------------------------------------------------------------- A5. cohesion family: undirected-only measures
* a directed network with unreciprocated ties is refused (198) unless sym asks for the symmetrized network
nwset, mat((0,1,1\1,0,1\0,1,0)) name(dnet) directed labs(A,B,C)
nwset, mat((0,1,1\1,0,1\1,1,0)) name(dsym) directed labs(A,B,C)
nwset, mat((0,1,1\1,0,1\1,1,0)) name(unet) undirected labs(A,B,C)
foreach c in nwcohesion nwclique nwkplex nwnclique nwnclan nwkcomponents {
	local g generate(gg_`c') replace
	capture noisily `c' dnet, `g'
	assert _rc == 198
	capture confirm variable gg_`c'1
	_tcc_log "directed network symmetrized" "`c' dnet, `g' sym"
	_tcc_log "directed network with every tie reciprocated" "`c' dsym, `g'"
	* the same numbers as on the undirected network
	qui `c' unet, generate(uu) replace
	local nu = cond(`"`r(cliques)'"' != "", `"`r(cliques)'"', "x")
	qui `c' dsym, generate(du) replace
	local nd = cond(`"`r(cliques)'"' != "", `"`r(cliques)'"', "x")
	assert "`nu'" == "`nd'"
}
capture noisily nwlambda dnet, name(lam1) replace
assert _rc == 198
_tcc_log "directed network symmetrized" "nwlambda dnet, name(lam1) replace sym"
_tcc_log "directed network with every tie reciprocated" "nwlambda dsym, name(lam2) replace"
* a valued network says that the values are ignored
_tcc_log "tie values are ignored" "nwclique gahuku, generate(gq) replace"
_tcc_log "tie values are ignored" "nwlambda gahuku, name(lam3) replace"

di "PASS: test_core_coercion"
