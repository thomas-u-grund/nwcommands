*! nwgeodesic: one network (the full command, _nwgeodesic_single below) or a list of networks
*! (one result row per network; save(file) writes them to a data set, as nwsummarize does)
capture program drop nwgeodesic
program nwgeodesic
	version 9
	// one network and no save(): the single-network command, untouched
	local __0 `"`0'"'
	syntax [anything(name=netname)] [, SAVE(string asis) *]
	if `"`save'"' == "" {
		_nwsyntax `netname', max(100000)
		if `networks' <= 1 {
			_nwgeodesic_single `__0'
			exit
		}
	}
	else {
		_nwsyntax `netname', max(100000)
	}
	local nets `netname'
	local nn : word count `nets'
	local opts `"`options'"'
	// save(file [, replace]) as in nwsummarize
	if `"`save'"' != "" {
		local 0 `"`save'"'
		capture syntax anything(name=__nwg_file id="file name") [, REPlace]
		if _rc {
			di "{err}{p 0 0 2}option {bf:save()}: specify a file name, optionally followed by {bf:, replace}; for example {bf:save(results, replace)}{p_end}"
			exit 198
		}
		local save `__nwg_file'
	}
	if `nn' > 1 {
		// options that make a variable, a network or a graph for ONE network
		local 0 `", `opts'"'
		capture syntax [, generate(string) name(string) PLOT xvars saving(string asis) export(string asis) gname(string asis) *]
		foreach o in generate name plot xvars saving export gname {
			if `"``o''"' != "" {
				di "{err}{p 0 0 2}nwgeodesic: option {bf:`o'} makes a variable, network or graph for a single network and cannot be used with a list of networks. Call {bf:nwgeodesic} once per network for it.{p_end}"
				exit 198
			}
		}
	}
	tempname R
	matrix `R' = J(`nn', 12, .)
	matrix colnames `R' = directed valued nodes numpaths unconnected avgpath diameter radius alpha connected avgpath_connected diameter_connected
	local i 0
	local __anysym 0
	foreach onenet of local nets {
		local ++i
		_nwsyntax `onenet', max(1)
		local dirflag = ("`directed'" == "true")
		local valflag = ("`valued'" == "true")
		if `nn' > 1 {
			capture quietly _nwgeodesic_single `onenet', `opts'
			if _rc {
				_nwgeodesic_single `onenet', `opts'
				exit _rc
			}
		}
		else {
			_nwgeodesic_single `onenet', `opts'
		}
		local unc_given = (`"`opts'"' != "" & regexm(lower(`"`opts'"'), "unconnected[(]"))
		local __symm = (r(symmetrized) == "true")
		local __anysym = max(`__anysym', `__symm')
		matrix `R'[`i', 1] = `dirflag'
		matrix `R'[`i', 2] = `valflag'
		matrix `R'[`i', 3] = r(nodes)
		matrix `R'[`i', 4] = r(numpaths)
		matrix `R'[`i', 5] = r(unconnected)
		matrix `R'[`i', 9] = r(alpha)
		if r(unconnected) != 0 & !`unc_given' {
			// not defined over all pairs (the single command stores -1): missing here, the connected pairs in the last columns
			matrix `R'[`i', 10] = r(connected)
			matrix `R'[`i', 11] = r(avgpath_connected)
			matrix `R'[`i', 12] = r(diameter_connected)
		}
		else {
			matrix `R'[`i', 6] = r(avgpath)
			matrix `R'[`i', 7] = r(diameter)
			matrix `R'[`i', 8] = r(radius)
			if `unc_given' & r(unconnected) != 0 {
				matrix `R'[`i', 10] = 1 - r(unconnected) / r(numpaths)
			}
			else {
				matrix `R'[`i', 10] = 1
				matrix `R'[`i', 11] = r(avgpath)
				matrix `R'[`i', 12] = r(diameter)
			}
		}
		local nm`i' "`onenet'"
		capture _return drop _nwg_last
		_return hold _nwg_last
	}
	if `"`save'"' != "" {
		tempname memhold
		postfile `memhold' str80 name byte directed byte valued double nodes double numpaths double unconnected double avgpath double diameter double radius double alpha double connected double avgpath_connected double diameter_connected using `"`save'"', replace
		forvalues k = 1/`nn' {
			post `memhold' ("`nm`k''") (`R'[`k',1]) (`R'[`k',2]) (`R'[`k',3]) (`R'[`k',4]) (`R'[`k',5]) (`R'[`k',6]) (`R'[`k',7]) (`R'[`k',8]) (`R'[`k',9]) (`R'[`k',10]) (`R'[`k',11]) (`R'[`k',12])
		}
		postclose `memhold'
	}
	if `nn' > 1 {
		local w 12
		forvalues k = 1/`nn' {
			local w = max(`w', min(30, strlen("`nm`k''")))
		}
		local lw = `w' + 2
		di "{txt}{hline `=`lw' + 66'}"
		di "{txt}{ralign `lw':Network}{ralign 8:Nodes}{ralign 12:Avg path}{ralign 10:Diameter}{ralign 9:Radius}{ralign 11:Connected}{ralign 12:Avg conn.}"
		di "{txt}{hline `=`lw' + 66'}"
		local dirs ""
		local undirs ""
		forvalues k = 1/`nn' {
			local a = `R'[`k',6]
			local d = `R'[`k',7]
			local rd = `R'[`k',8]
			local cn = `R'[`k',10]
			local ac = `R'[`k',11]
			local sa = cond(`a' < ., string(`a', "%9.3f"), ".")
			local sd = cond(`d' < ., string(`d', "%9.3f"), ".")
			local sr = cond(`rd' < ., string(`rd', "%9.3f"), ".")
			local sc = string(`cn', "%9.3f")
			local sac = cond(`ac' < ., string(`ac', "%9.3f"), ".")
			local ss = abbrev("`nm`k''", `w')
			di "{txt}{ralign `lw':`ss'}{res}{ralign 8:`=`R'[`k',3]'}{ralign 12:`sa'}{ralign 10:`sd'}{ralign 9:`sr'}{ralign 11:`sc'}{ralign 12:`sac'}"
			if `R'[`k',1] == 1 local dirs `dirs' `nm`k''
			else local undirs `undirs' `nm`k''
		}
		di "{txt}{hline `=`lw' + 66'}"
		foreach __l in dirs undirs {
			local __w : word count ``__l''
			if `__w' > 6 {
				local __a : word 1 of ``__l''
				local __b : word 2 of ``__l''
				local __z : word `__w' of ``__l''
				local `__l' "`__a' `__b' ... `__z', `__w' networks"
			}
		}
		if "`dirs'" != "" {
			if `__anysym' di "{txt}{p 2 2 2}(directed network symmetrized, as option {bf:sym} was given: the larger of the two directions of a tie; `dirs'){p_end}"
			else di "{txt}{p 2 2 2}(directed network: distances follow the direction of the ties; `dirs'){p_end}"
		}
		if "`undirs'" != "" di "{txt}{p 2 2 2}(undirected network: `undirs'){p_end}"
		di "{txt}{p 2 2 2}(Avg path, Diameter and Radius are missing for a network in which not every pair is connected; Avg conn. is the average distance over the connected pairs; r() holds the results of the last network, {bf:`nm`nn''}){p_end}"
	}
	_return restore _nwg_last
end

capture program drop _nwgeodesic_single
program _nwgeodesic_single
	version 9
	syntax [anything(name=netname)], [ nwreplace force noreplace name(string) alpha(real 0) BINary xvars unconnected(string) sym symopt(string) generate(string) ///
		PLOT AVErage GNAME(string asis) SAVing(string asis) EXPort(string asis) *]

	// plot: histogram of the geodesic distances (the graph name is gname(): name() is the distance network)
	_nw_gfinish check, plot(`plot') name(`gname') saving(`saving') export(`export') gopts(`"`options'"') default(geodesic) cmd(nwgeodesic)
	local __gname `"`r(name)'"'
	local __gsv `"`r(saving)'"'
	local __gex `"`r(export)'"'
	if "`average'" != "" & "`plot'" == "" {
		di as err "{p 0 0 2}nwgeodesic: option {bf:average} needs {bf:plot}.{p_end}"
		exit 198
	}

	capture
	unw_defs
	_nwsyntax `netname'
	local origname "`netname'"
	
	// the default output network is overwritten without nwreplace;
	// a name given with name() is protected
	local name_given = ("`name'" != "")
	if "`name'" == "" {
		local name "`nwgen_geodesic'"
	}
	
	tempname symnet
	local symmetrized "false"

	_nwsyntax `netname', max(1)
	_nwdenseguard, command(nwgeodesic) nodes(`nodes') copies(2) alternative(The distances between all pairs of nodes form an n x n matrix. Use nwcloseness or nwkatz for sums over the distances, nwcomponents for connectedness, nwpath for one pair, or a part of the network (nwsubset).) `force'

	local __alpha_given = (strpos(lower(`"`0'"'), "alpha(") > 0)
	if "`binary'" != "" & `__alpha_given' & `alpha' != 0 {
		di "{err}Options {bf:binary} and {bf:alpha()} cannot be combined."
		exit 198
	}

	if "`plot'" != "" {
		if "`is2mode'" == "true" {
			di as err "{p 0 0 2}nwgeodesic: {bf:plot} is not available for the two-mode network {bf:`netname'}: the histogram counts the distances between nodes of one mode. Use a one-mode network (for example from {help nw2project}).{p_end}"
			exit 198
		}
		if "`valued'" == "true" & "`binary'" == "" & (!`__alpha_given' | `alpha' != 0) {
			di as err "{p 0 0 2}nwgeodesic: {bf:plot} draws whole numbers of steps; the distances of the valued network {bf:`netname'} are sums of 1/value^alpha. Use {bf:binary} (or {bf:alpha(0)}) to count steps.{p_end}"
			exit 198
		}
	}

	local eccvar "`generate'"
	// nwgeodesic is dual-purpose: its PRIMARY output is the distance
	// network (name(), already required to be non-empty via its own
	// default-name convention above - a separate, already-decided,
	// legitimate style for network-producing commands, see
	// styleguides/NWCOMMANDS_COMMAND_STYLE.md's "Output creation"
	// section). Per-node eccentricity is a secondary, optional bonus
	// output layered on top - unlike a single-purpose command (nwdegree,
	// nwbetween, ...), where omitting generate() would mean the call
	// accomplishes nothing and so generate() is REQUIRED there, forcing
	// every nwgeodesic caller to also name an eccentricity variable it
	// doesn't want would make THIS command worse, not safer. So:
	// generate() omitted here simply means "skip eccentricity entirely"
	// (no variable, no error) - this is also what let nwreach.ado's own
	// internal call (which only ever wanted the reachability network)
	// drop its former `eccoff' workaround option entirely; omitting
	// generate() already does the right thing on its own now.
	if "`eccvar'" != "" {
		capture confirm variable `eccvar', exact
		if _rc == 0 & "`nwreplace'" == "" {
			di "{err}Variable {bf:`eccvar'} already exists; specify {bf:nwreplace}"
			exit 110
		}
	}

	if "`sym'" != "" {
		di "{txt}Geodesics calculated on the symmetrized network."
		// `noreplace' dropped from this call: nwsym.ado's harmonisation
		// pass removed that option (see its own header comment) in favor
		// of a plain `replace', which cannot be combined with generate()
		// - so it would now error here. It was already redundant with
		// generate() (already given on this same call) determining the
		// in-place-vs-copy outcome on its own.
		nwsym `netname', generate(`symnet') `symopt'
		_nwsyntax `symnet', max(1)
		local symmetrized "true"
	}
	_nwtargetcheck `name', source(`origname') given(0)
	capture _nwsyntax `name', other(_check)
	local name_exists = (_rc == 0)
	// noreplace: also the default network _geodesic is not overwritten
	if `name_exists' & "`nwreplace'" == "" & (`name_given' | "`replace'" == "noreplace") {
		di "{pstd} {err}Network {bf:`name'} already exists; use {bf:nwreplace} or specify another {it:newnetname} with {bf:name()}{p_end}"
		exit 483
	}
	// BUGFIX: was an unconditional `capture nwdrop `name'' - in the
	// ordinary case (no pre-existing network under this name), this
	// drop failed every time and left a stale, leaked `_rc' - the same
	// trailing-capture class fixed just below and in nwshared.ado this
	// same pass. `name_exists' above already knows whether there is
	// anything to drop.
	if `name_exists' {
		capture nwdrop `name'
	}
	tempname __nw_gd
	nwduplicate `netname', name(`name')
	_nwsyntax `name'
	
	// Tie values: on a valued network a step along a tie of value w costs 1/w^alpha, alpha = 1 by default
	// (Opsahl et al. 2010; alpha(-1) is igraph's "weights are lengths").  binary or alpha(0): every tie is one step.
	if "`valued'" == "true" & "`binary'" == "" & !`__alpha_given' {
		local alpha = 1
	}
	if ("`valued'" == "false" & `alpha' != 1 ){
		// say so only when alpha() was typed (the default 0 is not a request)
		if strpos(lower(`"`0'"'), "alpha(") > 0 {
			di "{txt}Network is unvalued; {bf:alpha = `alpha'} is ignored."
		}
		local alpha = 1
	}
	
	if (`alpha' == 0) {
		mata: `netobj'->set_edge(`netobj'->calculate_distances(`alpha', "brute"))
	}
	else if "`valued'" == "true" {
		// a valued network: least-cost paths of cost 1/w^alpha, whatever the size.  The native Dijkstra kernel (plugin
		// generation 10 or later) computes them at any size; without it the Mata search is too slow above 100 nodes,
		// and the command stops instead of silently counting steps (use binary for that, or force to wait for Mata).
		local __ok 0
		mata: `__nw_gd' = nw2_fastdist(`netobj', `alpha')
		mata: st_local("__ok", strofreal(rows(`__nw_gd') == `nodes'))
		if `__ok' {
			mata: `netobj'->set_edge(`__nw_gd')
		}
		else if `nodes' > 100 & "`force'" == "" {
			mata: mata drop `__nw_gd'
			capture nwdrop `name'
			if "`symmetrized'" == "true" capture nwdrop `symnet'
			di "{err}{p 0 0 2}Distances on a valued network of more than 100 nodes need the native plugin of the current version, which this platform does not have.{p_end}"
			di "{err}{p 0 0 2}Use option {bf:force} to compute them with the slow Mata routine, or option {bf:binary} to count steps.{p_end}"
			exit 198
		}
		else {
			mata: `netobj'->set_edge(`netobj'->calculate_distances(`alpha', "dijkstra"))
		}
		capture mata: mata drop `__nw_gd'
	}
	else {
		// An unvalued network: every tie costs 1 whatever alpha, so the distances are hop counts, and the brute-force
		// routine (native breadth-first search when the plugin is there) gives them exactly.  Dijkstra in Mata gave
		// the same numbers, but 37 s at 600 nodes with force (3.8.0).
		if (`nodes' > 100 & "`force'" == ""){
			di "{txt}Calculated on unvalued network because network size exceeds 100."
			di "Use option {bf:force} to calculate distance on valued network nevertheless." 
		}
		mata: `netobj'->set_edge(`netobj'->calculate_distances(`alpha', "brute"))
	}
	
	// Get number of unconnected links
	mata: st_numscalar("r(unconnected)", missing(*`netobj'->get_matrix()) - missing(diagonal(*`netobj'->get_matrix())))
	
	// the histogram of the distances (before unconnected() replaces the missing ones): connected pairs of distinct nodes,
	// each pair once in an undirected network, each ordered pair in a directed one
	if "`plot'" != "" {
		tempname __ghist
		mata: __nwgeodesic_D = *`netobj'->get_matrix()
		mata: __nwgeodesic_s = (`=cond("`directed'" == "true", 1, 0)' ? J(rows(__nwgeodesic_D), rows(__nwgeodesic_D), 1) - I(rows(__nwgeodesic_D)) : uppertriangle(J(rows(__nwgeodesic_D), rows(__nwgeodesic_D), 1), 0))
		mata: __nwgeodesic_v = select(vec(__nwgeodesic_D), vec(__nwgeodesic_s) :== 1)
		mata: st_local("__gunc", strofreal(sum(__nwgeodesic_v :>= .)))
		mata: __nwgeodesic_v = select(__nwgeodesic_v, __nwgeodesic_v :< .)
		mata: st_local("__gmax", strofreal(rows(__nwgeodesic_v) > 0 ? max(__nwgeodesic_v) : 0))
		mata: st_local("__gmean", strofreal(rows(__nwgeodesic_v) > 0 ? mean(__nwgeodesic_v) : .))
		if `__gmax' > 0 {
			mata: __nwgeodesic_c = J(`__gmax', 1, 0); for (__nwgeodesic_i = 1; __nwgeodesic_i <= `__gmax'; __nwgeodesic_i++) __nwgeodesic_c[__nwgeodesic_i] = sum(__nwgeodesic_v :== __nwgeodesic_i)
			mata: st_matrix("`__ghist'", __nwgeodesic_c)
		}
	}

	// Deal with non-existing paths
	if "`unconnected'" != "" {
		mata: __nwgeodesic_d = diagonal(*`netobj'->get_matrix())
		if "`unconnected'" == "max" {
			mata: st_local("unconnected", strofreal(max(*`netobj'->get_matrix())+1))
			mata: _editvalue((*`netobj'->get_matrix()),., `unconnected')
		}
		capture confirm number `unconnected'
		if _rc == 0 {
			mata: _editvalue((*`netobj'->get_matrix()),.,`unconnected')
		}
		mata: _diag((*`netobj'->get_matrix()), __nwgeodesic_d)
		mata: mata drop __nwgeodesic_d
	}

	// distances above 1 make the result a valued network
	mata: `netobj'->set_valued(`netobj'->check_valued())

	mata: st_numscalar("r(nodes)", `nodes')
	mata: st_numscalar("r(numpaths)", `nodes' * (`nodes' - 1))

	// Get number of paths in distance network
	if "`directed'" == "false" {
		mata: st_numscalar("r(numpaths)", (`r(numpaths)' / 2))
	}
	
	// Get average shortest path length
	tempname s
	mata: __nwgeodesic_sum = sum(*`netobj'->get_matrix())

	mata: st_numscalar("r(avgpath)", (__nwgeodesic_sum / (`r(numpaths)')))
	if ("`directed'" == "false"){
		mata: st_numscalar("r(avgpath)", (__nwgeodesic_sum / (`r(numpaths)' * 2)))
		mata: st_numscalar("r(unconnected)",(`r(unconnected)' / 2))
	}		
	mata: mata drop __nwgeodesic_sum
	
	// Get rest
	mata: st_global("r(netname)","`origname'")
	mata: st_global("r(geodesic)","`name'")
	mata: st_global("r(symmetrized)", "`symmetrized'")
	mata: st_numscalar("r(diameter)", max(*`netobj'->get_matrix()))
	mata: st_numscalar("r(alpha)", `alpha')

	// Per-node eccentricity (max distance from a node to any other node) and
	// network radius (min eccentricity). Missing propagates through max()
	// exactly like it already does for r(diameter) above: a node that
	// cannot reach every other node has undefined (missing) eccentricity
	// unless unconnected() was specified.
	tempname __nw_ecc
	mata: `__nw_ecc' = rowmax(*`netobj'->get_matrix())
	mata: st_numscalar("r(radius)", min(`__nw_ecc'))
	if "`eccvar'" != "" {
		capture confirm variable `eccvar', exact
		if _rc == 0 drop `eccvar'
		qui gen double `eccvar' = .
		// align row i of the data set with node i of the network before the positional
		// read/write below (see nwcommunity.ado)
		_nwsyncrows `name'
		mata: st_store((1::`nodes'), "`eccvar'", `__nw_ecc')
	}
	mata: mata drop `__nw_ecc'

	// Adjust for unconnected networks: the averages over all pairs are
	// not defined; report them over the connected pairs instead
	if `r(unconnected)' != 0 & "`unconnected'" == "" {
		tempname __nw_D
		mata: `__nw_D' = *`netobj'->get_matrix()
		mata: _diag(`__nw_D', .)
		mata: st_numscalar("r(avgpath_connected)", sum(`__nw_D') / sum(`__nw_D' :< .))
		mata: st_numscalar("r(diameter_connected)", max(`__nw_D'))
		mata: st_numscalar("r(connected)", sum(`__nw_D' :< .) / (rows(`__nw_D') * (rows(`__nw_D') - 1)))
		mata: mata drop `__nw_D'

		mata: st_numscalar("r(avgpath)", -1)
		mata: st_numscalar("r(diameter)",-1)
		mata: st_numscalar("r(radius)",-1)
	}

	di "{hline 40}"
	di "{txt}  Network name: {res}`r(netname)'"
	di "{txt}  Network of shortest paths: {res}`r(geodesic)'"
	di "{hline 40}"
	di "{txt}    Nodes: {res}`r(nodes)'"
	
	if "`directed'" == "true" {
		di "{txt}    Symmetrized : {res}`r(symmetrized)'"
	}
	else {
		di "{txt}    Symmetrized : {res}(already undirected)"
	}
	if "`valued'" == "true" {
		di "{txt}    ALpha : {res}`=strtrim(string(round((`r(alpha)')*1000)/1000,"%9.0g"))'"
	}
	di "    {hline 36}"
	di "{txt}    Paths: {res}`r(numpaths)'"
	di "{txt}    Unconnected paths: {res} `r(unconnected)'"
	
	if "`unconnected'" != "" {
		di "{txt}    Unconnected paths replaced with: {res} `unconnected'"
	}
	
	if `r(unconnected)' == 0 | "`unconnected'" != "" {
		di "{txt}    Average shortest path length: {res} `=strtrim(string(round((`r(avgpath)')*1000)/1000,"%9.0g"))'"
		di "{txt}    Diameter: {res} `=strtrim(string(round((`r(diameter)')*1000)/1000,"%9.0g"))'"
		di "{txt}    Radius: {res} `=strtrim(string(round((`r(radius)')*1000)/1000,"%9.0g"))'"
	}
	else {
		di "{txt}    Average shortest path length: {res} (not defined)"
		di "{txt}    Diameter: {res} (not defined)"
		di "{txt}    Radius: {res} (not defined)"
		di "{txt}    Share of pairs connected: {res} `=strtrim(string(round((`r(connected)')*1000)/1000,"%9.0g"))'"
		di "{txt}    Average over connected pairs: {res} `=strtrim(string(round((`r(avgpath_connected)')*1000)/1000,"%9.0g"))'"
		di "{txt}    Longest over connected pairs: {res} `=strtrim(string(round((`r(diameter_connected)')*1000)/1000,"%9.0g"))'"
	}

	capture _return drop _geo
	_return hold _geo
	// BUGFIX: was an unconditional `capture nwdrop `symnet'' - `symnet'
	// is only ever actually created as a real network when `sym' was
	// given (see above); otherwise this drop failed every time (nothing
	// to drop), and whenever `xvars' was ALSO not given (nothing else
	// afterward to touch `_rc'), the swallowed `capture' failure became
	// this command's own final, leaked `_rc' on an otherwise entirely
	// successful call - the same trailing-capture leak class fixed in
	// nwshared.ado this same pass. Only drop it when it was genuinely
	// created.
	if "`symmetrized'" != "" {
		capture nwdrop `symnet'
	}


	if "`plot'" != "" {
		_nwgeodesic_plot `__ghist', netname(`origname') directed(`directed') max(`__gmax') mean(`__gmean') unc(`__gunc') ///
			name(`__gname') `average' saving(`"`__gsv'"') export(`"`__gex'"') gopts(`"`options'"')
	}
	if "`xvars'" != "" {
		nwload `name'
	}
	// The two conditional-capture fixes above close the two known
	// stale-`_rc'-leak sources, but `capture _return drop _geo' further
	// above (an expected no-op the very first time this runs in a
	// session, since nothing was previously held under "_geo") is a
	// third, harder-to-guard one - and `_return hold'/`_return restore'
	// (both unconditional, including the one on the very next line) do
	// NOT refresh `_rc' themselves (same "quietly-prefixed/inherently
	// silent commands don't touch _rc" class documented in
	// nwbrokerage.ado's own header comment). Resetting explicitly here,
	// on a variable guaranteed to exist by this point, forces a clean,
	// deterministic `_rc==0' regardless of any upstream harmless
	// capture-swallowed failure - the same idiom nwaltergen.ado/
	// nwbrokerage.ado already use for the identical situation.
	capture confirm variable `nw_nodename', exact
	_return restore _geo
	capture mata: mata drop __nwgeodesic_*
	capture confirm number 0
end

// the histogram of the finite geodesic distances: bars of the number of pairs at each whole distance
capture program drop _nwgeodesic_plot
program _nwgeodesic_plot
	version 15
	syntax [anything(name=hist)], NETname(string) DIRected(string) MAX(integer) MEAN(string) UNC(integer) NAME(string) ///
		[AVErage SAVing(string asis) EXPort(string asis) GOPTS(string asis)]
	if strpos(`"`gopts'"', char(96) + char(34)) == 1 gettoken gopts : gopts
	if `max' < 1 {
		di as txt "{p 0 0 2}(nothing to plot: no pair of nodes of {bf:`netname'} is connected){p_end}"
		exit
	}
	local what = cond("`directed'" == "true", "ordered pairs", "pairs")
	preserve
	quietly {
		drop _all
		svmat double `hist', names(__cnt)
		rename __cnt1 __n
		generate double __d = _n
		generate double __cnt = __n
	}
	local notes ""
	if "`average'" != "" local notes `"`"Mean distance of the connected `what': `=strtrim(string(`mean', "%9.2f"))'"'"'
	if `unc' > 0 local notes `"`notes' `"`=strtrim(string(`unc', "%15.0fc"))' unconnected `what' (not shown)"'"'
	local note ""
	if `"`notes'"' != "" local note `"note(`notes', size(small) color(black))"'
	local xl "xlabel(1(1)`max', format(%9.0f))"
	if `max' > 20 local xl "xlabel(#10, format(%9.0f))"
	// the mean is a dashed line drawn ON TOP of the bars (pci after the bars), not an xline behind them
	local xline ""
	if "`average'" != "" {
		quietly summarize __n, meanonly
		local xline `"(pci 0 `mean' `=r(max)' `mean', lpattern(dash) lcolor(black) lwidth(medthin))"'
	}
	_nw_gfinish blk "Geodesic distance (number of steps)", kind(xtitle) gopts(`"`gopts'"')
	local xtit `"`r(t)'"'
	_nw_gfinish blk "Number of `what'", kind(ytitle) gopts(`"`gopts'"')
	local ytit `"`r(t)'"'
	_nw_gfinish title "Geodesic distances: `netname'", gopts(`"`gopts'"')
	local ttl `"`r(t)'"'
	quietly twoway (bar __n __d, barwidth(0.9) fcolor(gs10) lcolor(gs4)) `xline', `xl' legend(off) ///
		ylabel(, angle(0) format(%9.0fc)) `xtit' `ytit' `ttl' `note' graphregion(color(white)) ///
		name(`name', replace) `gopts'
	restore
	_nw_gfinish save, name(`name') saving(`"`saving'"') export(`"`export'"')
end

/*
capture mata mata drop getgeodesic()


mata:
void getgeodesic(pointer (class nw_def scalar) scalar nw)
{
	if (min(*nw->get_distance()) >= 0 ) { 
		st_numscalar("r(L)", sum(nw->get_distance())/(rows(*nw->get_distance())*rows(*nw->get_distance()) - rows(*nw->get_distance()))) 
	}
	else {
		st_numscalar("r(L)", -1) 
	}
}
end*/

capture mata: mata drop nw2_fastdist()
mata:
// Native Dijkstra distances (kernel 49 of the nwgraph plugin) as an n x n matrix, 0 on the diagonal, missing = unreachable;
// a 0 x 0 matrix when the kernel is not available.
real matrix nw2_fastdist(pointer(class nw_def scalar) scalar p, real scalar alpha)
{
	real rowvector aux
	real scalar st, n, a, b
	real matrix el, r, D

	if (st_global("NW_NOFASTKERNELS") != "") return(J(0, 0, .))
	if (nwg_comb_version() < 10) return(J(0, 0, .))
	n = p->get_nodes()
	if (n < 1) return(J(0, 0, .))
	el = p->edgelist()
	D = J(n, n, .)
	for (a = 1; a <= n; a = a + 400) {
		b = min((400, n - a + 1))
		r = nwg_comb(49, n, el, J(0, 1, .), (alpha, a, b), aux, st)
		if (st != 0 | rows(r) != n | cols(r) != b) return(J(0, 0, .))
		D[(a..(a + b - 1)), .] = r'
	}
	return(D)
}
end
