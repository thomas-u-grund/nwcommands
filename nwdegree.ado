
capture program drop nwdegree
program nwdegree
	version 9
	syntax [anything(name=netname)],[ replace standardize silent isolates alpha(string) BINary TIES(string) GENerate(string) in(string) outputoff out(string) ONEmode RAW *]
	set more off

	// This command's own doc has always described netlist (multi-network)
	// behavior ("In case degree centrality is calculated for z networks
	// at the same time... the command generates the variables
	// _outdegree_z and _indegree_z for each network"), but the code
	// never actually implemented it: "_nwsyntax ..., max(1)" capped the
	// argument to exactly one network, and what looked like the start of
	// a loop ("if networks > 1 { local k = 1 ... }") never actually
	// wrapped anything - the rest of the body ran once unconditionally
	// and referenced an undefined netname_temp local throughout. This
	// is exactly the "netname vs netlist" example NWCOMMANDS_COMMAND_
	// STYLE.md itself cites as the model case for genuine netlist
	// support (independent per-network degree calculation has obvious,
	// useful semantics), so this was finished rather than just
	// documented as unsupported. Single-network calls (still the common
	// case) are unaffected: default output variable names have no
	// suffix, exactly as before.
	_nwsyntax `netname', max(9999)
	// The "networks" local gets clobbered by the inner _nwsyntax call
	// below (which re-parses one network at a time and resets it to 1
	// each iteration) - capture the true total here, before the loop
	// starts, matching the convention already used elsewhere in this
	// package (e.g.
	// nwcomponents/nwcommunity check the "networks" local before
	// entering their own loops, not inside them).
	local totalnetworks = `networks'

	// Tie values: on a valued network the default is the strength (sum of the tie values,
	// alpha(1); igraph::strength, tnet::degree_w), as R does for a weighted graph.  alpha(0) or
	// binary gives the number of ties.  An unvalued network has no values: alpha() is then
	// irrelevant and the result is the number of ties, as before.
	if "`alpha'" != "" {
		capture confirm number `alpha'
		if _rc {
			noi di "{err}Option {bf:alpha()} must be a number."
			error 198
		}
		if "`binary'" != "" & real("`alpha'") != 0 {
			noi di "{err}Options {bf:binary} and {bf:alpha()} cannot be combined."
			error 198
		}
	}

	// Two-mode networks: the degree of a two-mode network (the number of ties divided by the size of the other mode, tnet::degree_tm)
	// is used by default; onemode forces the one-mode computation on the bipartite graph.  nw2degree is an alias of this form.
	if "`onemode'" == "" {
		local __all2 1
		local __netlist "`netname'"
		foreach netname_temp in `netname' {
			_nwsyntax `netname_temp'
			if "`is2mode'" != "true" local __all2 0
		}
		local netname "`__netlist'"
		if `__all2' {
			local ignored_opts ""
			if "`isolates'" != "" local ignored_opts "`ignored_opts' isolates"
			if "`standardize'" != "" local ignored_opts "`ignored_opts' standardize"
			if "`in'" != "" local ignored_opts "`ignored_opts' in()"
			if "`out'" != "" local ignored_opts "`ignored_opts' out()"
			if "`outputoff'" != "" local ignored_opts "`ignored_opts' outputoff"
			if "`ignored_opts'" != "" {
				noi di "{txt}note: two-mode degree is used; the following option(s) have no two-mode form and were ignored:{bf:`ignored_opts'} ({bf:onemode} gives the one-mode computation)"
			}
			local __fwd ""
			if "`alpha'" != "" local __fwd "alpha(`alpha')"
			if "`binary'" != "" local __fwd "`__fwd' binary"
			if "`raw'" != "" local __fwd "`__fwd' raw"
			_nwdegree_two `netname', generate(`generate') `replace' `silent' `__fwd'
			capture confirm number 1
			exit
		}
	}
	else if "`raw'" != "" {
		noi di "{err}Option {bf:raw} is the two-mode degree and cannot be combined with {bf:onemode}."
		error 198
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'

		// Plain degree has no meaningful definition on a two-mode
		// network's own square-matrix sense (every node's "neighbors"
		// are structurally confined to the opposite mode already, and
		// the natural normalisation differs by mode) - nwdegree used
		// to just silently compute it anyway, on whatever the raw
		// bipartite adjacency happened to contain, producing a
		// plausible-looking but meaningless number with no warning at
		// all (confirmed empirically before this fix - a real,
		// previously-undiscovered instance of exactly the "Category A"
		// silent-wrong-result gap this initiative's own audit was
		// looking for). Redirects to nw2degree instead, the same
		// already-established, already-tested pattern nwclustering.ado
		// uses for its own identical situation - not a warning about
		// anything wrong with the data, so styled as an ordinary
		// {txt} note rather than {err} (nwclustering's own version of
		// this message uses {err}, arguably inconsistent with "don't
		// call normal expected behaviour a warning"; not changed here
		// to avoid an unrelated, out-of-scope edit to that file).
		// nw2degree's own option set (generate()/replace/silent/
		// alpha()) is smaller than nwdegree's one-mode-specific one
		// (isolates/standardize/in()/out()/outputoff have no bipartite
		// equivalent) - forwarding only what applies and naming
		// explicitly, not silently, whatever was requested but
		// doesn't carry over. `alpha()' USED to be listed here as
		// having no bipartite equivalent - it does now (nw2degree
		// gained a weighted Opsahl-style two-mode degree variant,
		// self-flagged as a real gap in docs/NETWORK_TYPE_MATRIX.md
		// and closed 2026-09-02), so it is forwarded like any other
		// shared option instead.
		if "`is2mode'" == "true" & "`onemode'" == "" {
			// a list that mixes two-mode and one-mode networks: each network gets its own form
			local ignored_opts ""
			if "`isolates'" != "" local ignored_opts "`ignored_opts' isolates"
			if "`standardize'" != "" local ignored_opts "`ignored_opts' standardize"
			if "`in'" != "" local ignored_opts "`ignored_opts' in()"
			if "`out'" != "" local ignored_opts "`ignored_opts' out()"
			if "`outputoff'" != "" local ignored_opts "`ignored_opts' outputoff"
			if "`ignored_opts'" != "" {
				noi di "{txt}note: `netname_temp' is a two-mode network: its two-mode degree is used; the following option(s) have no two-mode form and were ignored:{bf:`ignored_opts'}"
			}
			local __fwd ""
			if "`alpha'" != "" local __fwd "alpha(`alpha')"
			if "`binary'" != "" local __fwd "`__fwd' binary"
			if "`raw'" != "" local __fwd "`__fwd' raw"
			noi _nwdegree_two `netname_temp', generate(`generate') `replace' `silent' `__fwd'
			continue
		}

		tempvar included
		_nwdatasync `netname_temp', generate(`included')
		local nodes_temp `nodes'

		tempname outdegree
		tempname indegree

		local __alpha 0
		if "`alpha'" != "" {
			local __alpha = real("`alpha'")
		}
		else if "`valued'" == "true" & "`binary'" == "" {
			local __alpha 1
		}
		// strengths are not whole numbers: stored in double precision (a network without values keeps float)
		local __gt ""
		if "`valued'" == "true" local __gt "double"
		mata: `outdegree' = `netobj'->get_outdegree(`__alpha')
		mata: `indegree' = `netobj'->get_indegree(`__alpha')

		// BUGFIX (real, severe, silently-wrong-output bug - confirmed
		// empirically before fixing, not assumed): the default (no
		// explicit generate()) directed-network word order below used
		// to be "_indegree _outdegree" (indegree word 1, outdegree word
		// 2), but the extraction further down has always read word 1
		// into the `_outdegree' local and word 2 into `_indegree' - the
		// documented convention (see this file's own doc header: "the
		// next example saves the out- and indegree centrality in the
		// variables myout and myin", i.e. out=word1, in=word2). That
		// mismatch meant every default `nwdegree' call on a directed
		// network silently stored OUTdegree values into the variable
		// literally named "_indegree", and INdegree values into the one
		// named "_outdegree" - confirmed directly on a 4-node star
		// network (A -> B,C,D): node A (true outdegree 3, indegree 0)
		// came back with _indegree==3, _outdegree==0. The centralization
		// r()-results were unaffected (computed straight from the
		// underlying Mata vectors, never routed through these Stata
		// variable names at all) - only the generated dataset variables
		// were wrong. Same swap existed for the valued
		// _instrength/_outstrength pair. Fixed by reordering both to
		// out-then-in, matching the extraction and the documented
		// convention, instead of changing the extraction to match the
		// (undocumented, inconsistent) construction order.
		//
		// Separately fixed: "isolates" without an explicit generate()
		// used to completely REPLACE netgenerate with the single word
		// "_isolates", discarding the degree-name assignment entirely -
		// on a directed network this left `_indegree' empty and
		// `_outdegree' aliased to "_isolates", so "capture generate
		// `_indegree' = ." silently no-ops (empty target name) and
		// the very next "mata: st_store(..., "`_indegree'", ...)" (not
		// wrapped in capture) crashed hard passing st_store() an empty
		// variable-name string - this is the crash already flagged in
		// docs/CERTIFICATION.md's Pending table. Fixed by APPENDING
		// "_isolates" to the normal degree-name list instead of
		// replacing it, so isolates can always be computed FROM
		// properly-named degree variables exactly as the later isolates
		// block already assumes.
		local netgenerate "`generate'"
		// BUGFIX: an explicit generate() on a DIRECTED network needs at
		// least 2 names (outdegree, indegree); a caller supplying just 1
		// (e.g. generate(mydeg), a plausible attempt to just rename the
		// degree variable the way it would work on an undirected
		// network) got no error here. `word 2 of netgenerate' then
		// evaluated to empty, "capture generate <empty> = ." silently
		// no-op'd, and the very next, uncaptured "mata: st_store(...,
		// "`_indegree'", ...)" crashed hard passing st_store() an empty
		// variable-name string (r(3500)) - the same failure class as the
		// isolates-word-count bugs fixed above, from a different
		// trigger. Matches nwcloseness.ado's own established pattern:
		// validate the word count up front and error clearly instead of
		// silently mis-assigning or crashing downstream.
		// generate() is required (suite-wide generate()-required style
		// decision, 2026-09-05): nwdegree's whole purpose is producing
		// this variable, so - matching Stata's own egen/predict
		// convention - there is no default name to silently fall back
		// to; a hidden default is exactly how an existing variable gets
		// unexpectedly clobbered. No isolates-only exception: the
		// isolates-append logic just below assumes netgenerate already
		// holds the real degree name(s) to append an _isolates slot
		// onto, so generate() must be given even for an isolates-only
		// call (a real name is still required, even if the caller never
		// reads it afterward).
		if ("`netgenerate'" == "") {
			noi di "{err}option {bf:generate()} required."
			error 198
		}
		if ("`netgenerate'" != "" & "`directed'" == "true") {
			local __nwdeg_gencount : word count `netgenerate'
			if (`__nwdeg_gencount' < 2) {
				noi di "{err}Option {bf:generate()} needs at least 2 names (outdegree, indegree) for a directed network; got `__nwdeg_gencount'."
				error 198
			}
		}
		// Give isolates its own word slot whenever the (default or
		// user-supplied) netgenerate doesn't already have enough words
		// for one - 2 slots for directed (out, in) + isolate = 3;
		// 1 slot for undirected (degree) + isolate = 2. Covers not just
		// the empty-generate() case above but also a caller who
		// supplies generate() with fewer names than the full set (e.g.
		// this file's own doc/test: "generate(myisolate) isolates" on
		// an undirected network - 1 word given, needs 2) - previously
		// that single given name got aliased to BOTH the ordinary
		// degree slot and the isolate slot (whichever word-position
		// rule was in play), so the real degree values written first
		// were silently overwritten by the isolates 0/1 indicator right
		// after, and the degree computation was lost entirely. Adding a
		// distinct name here instead means the caller's own word(s)
		// keep meaning whatever they already meant (degree names, read
		// left to right) and isolate always gets a genuine, separate
		// variable - never silently a degree variable in disguise.
		if "`isolates'" != "" {
			local ngwords : word count `netgenerate'
			if ("`directed'" == "true") {
				if `ngwords' < 3 {
					local netgenerate "`netgenerate' _isolates"
				}
			}
			else {
				if `ngwords' < 2 {
					local netgenerate "`netgenerate' _isolates"
				}
			}
		}
		// Multi-network output naming, per NWCOMMANDS_COMMAND_STYLE.md's
		// established convention (basevar_<netname> suffix): only
		// applied when more than one network is actually being
		// processed, so a single-network call's output names are
		// unchanged from before this fix.
		if `totalnetworks' > 1 {
			local suffixed ""
			foreach onevar of local netgenerate {
				local suffixed "`suffixed' `onevar'_`netname_temp'"
			}
			local netgenerate "`suffixed'"
		}

		local _degree : word 1 of `netgenerate'
		local _indegree : word 2 of `netgenerate'
		local _outdegree : word 1 of `netgenerate'
		// BUGFIX: `_isolate' always read word 1 (the degree/outdegree
		// name itself), regardless of how many degree-name words
		// actually precede the isolate name - correct only by accident
		// for the narrow "isolates with no other output requested"
		// case. Broken for the doc's own worked example
		// ("generate(myout myin mysiolate) isolates" - a directed
		// network - documented as saving out/in-degree in myout/myin,
		// so the isolate name "mysiolate" is word 3, not word 1): with
		// the old code, `_isolate' would have resolved to "myout" (the
		// OUTdegree name), so "capture generate `_isolate' = ." would
		// silently no-op (myout already exists as a real degree
		// variable) and the isolates block's own "replace `_isolate' =
		// ..." would then silently OVERWRITE the user's real outdegree
		// centrality values in "myout" with a 0/1 isolate indicator,
		// while "mysiolate" itself was never created at all - a genuine
		// silent-data-corruption bug, not just the directed-network
		// crash already flagged in docs/CERTIFICATION.md's Pending
		// table. Fixed by taking the isolate name from the word
		// position immediately after however many degree-name words
		// actually precede it (2 for directed - out then in - 1 for
		// undirected), matching how netgenerate is now actually built
		// above.
		if ("`directed'" == "true") {
			local _isolate : word 3 of `netgenerate'
		}
		else {
			local _isolate : word 2 of `netgenerate'
		}

		// BUGFIX: this whole per-network body runs inside the outer
		// "qui foreach netname_temp in `netname' { ... }" loop above, so
		// a plain "di" here was silently swallowed by that enclosing
		// qui - the user got nothing but a bare, unexplained r(99), with
		// no indication of which variable already existed or why (the
		// exact complaint this was found while diagnosing: nwplot's own
		// internal degree/isolates computation, elsewhere, left stale
		// _outdegree/_indegree/_isolates variables behind after a
		// compound "capture drop A B C D" silently failed in its
		// entirety - see nwplot.ado's own fix - and the next call to
		// generate those same names hit this guard with no visible
		// explanation at all). "noi" makes this diagnostic actually
		// reach the user, matching how every other user-facing message
		// in this same command body is already marked.
		//
		// Also fixed a separate, adjacent typo found in the same line:
		// this loop referenced `_isolates' (plural) which is never
		// defined anywhere - `_isolate' (singular, set two lines above)
		// is the real local - so the isolates target variable's own
		// existence was never actually checked here at all, silently
		// falling through to a bare "capture generate" later instead of
		// this guard's own clear error message.
		// ties(): the number of ties as well, next to the strength (names: degree, or outdegree and indegree)
		local __cntout ""
		local __cntin ""
		if "`ties'" != "" {
			local __tcount : word count `ties'
			if "`directed'" == "true" & `__tcount' != 2 {
				noi di "{err}Option {bf:ties()} needs 2 names (outdegree, indegree) for a directed network; got `__tcount'."
				error 198
			}
			if "`directed'" != "true" & `__tcount' != 1 {
				noi di "{err}Option {bf:ties()} needs 1 name for an undirected network; got `__tcount'."
				error 198
			}
			local __cntout : word 1 of `ties'
			local __cntin : word 2 of `ties'
			if `totalnetworks' > 1 {
				local __cntout "`__cntout'_`netname_temp'"
				if "`__cntin'" != "" local __cntin "`__cntin'_`netname_temp'"
			}
			foreach c in `__cntout' `__cntin' {
				capture confirm variable `c', exact
				if _rc == 0 & "`replace'" == "" {
					noi di "{err}Variable {bf:`c'} already exists; use {bf:replace} or {bf:ties()}"
					err 99
				}
				capture drop `c'
			}
		}
		else if "`isolates'" != "" & `__alpha' != 0 {
			// the isolates are the nodes without a tie, whatever the tie values add up to
			tempvar __cntout __cntin
		}
		foreach c in `_degree' `_indegree' `_outdegree' `_isolate' {
			capture confirm variable `c', exact
			if _rc == 0 & "`replace'" == "" {
				noi di "{err}Variable {bf:`c'} already exists; use {bf:replace} or {bf:generate()}"
				err 99
			}
			capture drop `c'
		}

		if ("`directed'" == "false"){
			capture generate `__gt' `_degree' = .
			mata: st_store((1,`nodes_temp'), "`_degree'", `outdegree')
		}
		else {
			capture generate `__gt' `_outdegree' = .
			capture generate `__gt' `_indegree' = .
			mata: st_store((1,`nodes_temp'), "`_outdegree'", `outdegree')
			mata: st_store((1,`nodes_temp'), "`_indegree'", `indegree')
		}

		if "`__cntout'" != "" {
			qui generate double `__cntout' = .
			mata: st_store((1,`nodes_temp'), "`__cntout'", `netobj'->get_outdegree(0))
			if "`directed'" == "true" {
				qui generate double `__cntin' = .
				mata: st_store((1,`nodes_temp'), "`__cntin'", `netobj'->get_indegree(0))
			}
		}

		if "`standardize'" != "" {
			// Divide each stored variable once: for an undirected network
			// `_degree' and `_outdegree' are the same variable (word 1 of
			// generate()), and for a directed network `_degree' is the
			// outdegree variable, so dividing all three divided it twice.
			if "`directed'" == "true" {
				replace `_outdegree' = `_outdegree' / (`nodes_temp' - 1)
				replace `_indegree' = `_indegree' / (`nodes_temp' - 1)
			}
			else {
				replace `_degree' = `_degree' / (`nodes_temp' - 1)
			}
		}

		if "`isolates'" != "" {
			capture generate `_isolate' = .
			sum `_isolate'
			if "`directed'" == "true" {
				if "`__cntout'" != "" {
					replace `_isolate' = (`__cntout' == 0) * (`__cntin'==0) if `included' == 1
				}
				else {
					replace `_isolate' = (`_outdegree' == 0) * (`_indegree'==0) if `included' == 1
				}
			}
			else {
				if "`__cntout'" != "" {
					replace `_isolate' = (`__cntout' == 0)  if `included' == 1
				}
				else {
					replace `_isolate' = (`_degree' == 0)  if `included' == 1
				}
			}
		}

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{hline 40}"
			if "`valued'" == "true" {
				if `__alpha' == 0 {
					noi di "{txt}  (valued network, tie values not used: degree is the number of ties)"
				}
				else if `__alpha' == 1 {
					noi di "{txt}  (valued network: degree is the strength, the sum of the tie values; {bf:binary} gives the number of ties)"
				}
				else {
					noi di "{txt}  (valued network: degree is k (s/k)^alpha, alpha = `__alpha', k = number of ties, s = sum of tie values)"
				}
			}
			if "`isolates'" == "" {
				noi di "{txt}    Degree distribution"
				if "`directed'" == "true"{
					noi tab `_indegree' if `included' == 1, `in'
					noi tab `_outdegree' if `included' == 1, `out'
				}
				else {
					noi tab `_degree' if `included' == 1, `options'
				}
			}
			else {
				noi di "{txt}    Isolates"
				noi tab `_isolate' if `included' == 1, `in'
			}
		}

		if "`silent'" == "" & "`valued'" == "true" {
			mata: st_local("__mt", strofreal(mean(`netobj'->get_outdegree(0)), "%9.4g"))
			mata: st_local("__ms", strofreal(mean(`netobj'->get_outdegree(1)), "%9.4g"))
			noi di "{txt}  Mean number of ties (out): {res}`__mt'{txt}   mean strength (out): {res}`__ms'"
		}
		mata: st_rclear()
		mata: st_numscalar("r(alpha)", `__alpha')
		if "`valued'" == "true" {
			mata: st_numscalar("r(mean_ties)", mean(`netobj'->get_outdegree(0)))
			mata: st_numscalar("r(mean_strength)", mean(`netobj'->get_outdegree(1)))
		}

		if "`isolates'" == "" {
			if ("`directed'" == "false") {
				mata: st_numscalar("r(dg_central)", sum(J(`nodes_temp',1,max(`outdegree')) :- `outdegree') / ((`nodes_temp' - 2) * (`nodes_temp' - 1)))
				if "`silent'" == "" {
					noi di
					// BUGFIX: was `noi di "..." + `=round(...)'' - string-
					// concatenating a quoted display literal with a bare
					// numeric expression via `+' is not valid `di' syntax
					// once that expression evaluates to missing (a
					// genuine division-by-zero for any N<=2 network,
					// where centralization is undefined) - crashed with
					// r(198) on the ordinary default display path for
					// any 1- or 2-node undirected network. Split into the
					// standard two-item `di "text" value' form used
					// throughout the rest of this package, which
					// displays missing as "." without erroring.
					noi di "{txt}   Degree centralization: {res}`=strtrim(string(round((`r(dg_central)')*1000)/1000,"%9.0g"))'"
				}
			}
			else {
				mata: st_numscalar("r(indg_central)", sum(J(`nodes_temp',1,max(`indegree')) :- `indegree') / ((`nodes_temp' - 1) * (`nodes_temp' - 1)))
				mata: st_numscalar("r(outdg_central)", sum(J(`nodes_temp',1,max(`outdegree')) :- `outdegree') / ((`nodes_temp' - 1) * (`nodes_temp' - 1)))
				if "`silent'" == "" {
					noi di
					// BUGFIX: same fix as the undirected branch above -
					// a 1-node directed network divides by zero here too.
					noi di "{txt}   Indegree centralization: {res}`=strtrim(string(round((`r(indg_central)')*1000)/1000,"%9.0g"))'"
					noi di "{txt}   Outdegree centralization: {res}`=strtrim(string(round((`r(outdg_central)')*1000)/1000,"%9.0g"))'"
				}
			}
		}
		capture drop `included'
		mata: mata drop `outdegree' `indegree'
	}

end


capture program drop _nwdegree_two
program _nwdegree_two, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace silent alpha(string) BINary RAW]
	set more off

	_nwsyntax `netname', max(9999)
	if "`alpha'" != "" {
		capture confirm number `alpha'
		if _rc {
			di "{err}Option {bf:alpha()} must be a number."
			error 198
		}
		if "`binary'" != "" & real("`alpha'") != 0 {
			di "{err}Options {bf:binary} and {bf:alpha()} cannot be combined."
			error 198
		}
	}

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'

		if "`is2mode'" != "true" {
			noi di "{err}nwdegree: onemode is required to use the one-mode form of `netname_temp'."
			error 198
		}

		if "`generate'" == "" {
			noi di "{err}option {bf:generate()} required."
			error 198
		}
		local netgenerate "`generate'"

		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`k'} already exists; specify {bf:replace}"
			err 99
		}

		// BUGFIX: a bare "capture drop X" is subject to Stata's default
		// variable-name abbreviation (set varabbrev on) - if X does NOT
		// exist yet but a DIFFERENT, longer variable happens to have X
		// as a literal prefix (e.g. calling nwdegree on a netlist mixing
		// a two-mode network with a one-mode one: this redirect's own
		// unsuffixed base name is always a prefix of nwdegree's own
		// suffixed one-mode output, "basevar_netname"), this silently
		// dropped that unrelated, already-computed variable instead of
		// safely no-op'ing - confirmed directly while writing the Paths
		// & Ego Networks / centrality tutorials' own test coverage.
		// Guarding the drop behind the same exact-match confirm already
		// used for the "already exists" check above eliminates the
		// ambiguity entirely: skip the drop when the exact name doesn't
		// exist (nothing to safely drop), and once it's confirmed to
		// exist, Stata always resolves an exact literal match over an
		// abbreviation candidate, so the drop can no longer go astray.
		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 {
			drop `netgenerate'`k'
		}
		gen `=cond("`valued'" == "true", "double", "")' `netgenerate'`k' = .
		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		// align row i of the data set with node i of this network before the
		// positional st_store() below (a data set that was sorted or reordered, or
		// synced to another network such as a two-mode projection, would otherwise
		// receive the values on the wrong rows)
		_nwsyncrows `netname_temp'
		mata: st_rclear()
		_nwsyntax `netname_temp'
		// tie values: the strength on a valued network (as nwdegree), the number of ties with binary or alpha(0)
		local __alpha 0
		if "`alpha'" != "" {
			local __alpha = real("`alpha'")
		}
		else if "`valued'" == "true" & "`binary'" == "" {
			local __alpha 1
		}
		if "`raw'" != "" {
			// the degree itself (tnet::degree_tm, igraph::degree), without the division by the size of the other mode
			mata: st_store((1::`nodes'), "`netgenerate'`k'", `netobj'->calculate_2mode_degree(`__alpha') :* ((strtoreal(`netobj'->get_modes()) :== 1)' :* `netobj'->get_nodes_mode2() :+ (strtoreal(`netobj'->get_modes()) :== 2)' :* `netobj'->get_nodes_mode1()))
		}
		else {
			mata: st_store((1::`nodes'), "`netgenerate'`k'", `netobj'->calculate_2mode_degree(`__alpha'))
		}

		// see nwbrokerage.ado's own header comment for why this is
		// needed: quietly/mata:-only commands above do not refresh _rc
		// on their own, so the "already exists" probe's own stale rc
		// would otherwise leak out as this command's own exit code.
		capture confirm variable `netgenerate'`k', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			if "`raw'" != "" noi di "{txt}  (raw degree: not divided by the size of the other mode)"
			if "`valued'" == "true" {
				if `__alpha' == 0 noi di "{txt}  (valued network, tie values not used: degree is the number of ties)"
				else if `__alpha' == 1 noi di "{txt}  (valued network: degree is the strength, the sum of the tie values; {bf:binary} gives the number of ties)"
				else noi di "{txt}  (valued network: degree is k (s/k)^alpha, alpha = `__alpha')"
			}
			noi sum `netgenerate'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
