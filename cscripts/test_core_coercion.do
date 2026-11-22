do unw_core.do

* Coercion sweep (3.35, unreleased): no command treats a network as another type than it is unless the user asks by an
* option, and every coercion is stated in the output. One section per command (A1, A2, ...). Run from the repository
* root. References: igraph 2.3.2 (values hard-coded below, 1e-9) and, for undirected binary networks, the numbers of
* the branch before this sweep (3.34.0 plus the directed betweenness / closeness / evcent change).

local tol 1e-9
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

di "PASS: test_core_coercion"
