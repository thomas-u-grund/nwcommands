
capture program drop nwdegree
program nwdegree
	version 9
	syntax [anything(name=netname)],[ replace standardize silent isolates alpha(real 0.0) GENerate(string) in(string) outputoff out(string) *]
	set more off

	// This command's own doc has always described netlist (multi-network)
	// behavior ("In case degree centrality is calculated for z networks
	// at the same time... the command generates the variables
	// _outdegree_z and _indegree_z for each network"), but the code
	// never actually implemented it: "nw_syntax ..., max(1)" capped the
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
	nw_syntax `netname', max(9999)
	// The "networks" local gets clobbered by the inner nw_syntax call
	// below (which re-parses one network at a time and resets it to 1
	// each iteration) - capture the true total here, before the loop
	// starts, matching the convention already used elsewhere in this
	// package (e.g.
	// nwcomponents/nwcommunity check the "networks" local before
	// entering their own loops, not inside them).
	local totalnetworks = `networks'

	qui foreach netname_temp in `netname' {
		nw_syntax `netname_temp'

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
		// nw2degree's own option set (generate()/replace/silent) is
		// smaller than nwdegree's one-mode-specific one
		// (alpha()/isolates/standardize/in()/out()/outputoff, none of
		// which have a bipartite equivalent) - forwarding only what
		// applies and naming explicitly, not silently, whatever was
		// requested but doesn't carry over.
		if "`is2mode'" == "true" {
			local ignored_opts ""
			if "`alpha'" != "0" local ignored_opts "`ignored_opts' alpha()"
			if "`isolates'" != "" local ignored_opts "`ignored_opts' isolates"
			if "`standardize'" != "" local ignored_opts "`ignored_opts' standardize"
			if "`in'" != "" local ignored_opts "`ignored_opts' in()"
			if "`out'" != "" local ignored_opts "`ignored_opts' out()"
			if "`outputoff'" != "" local ignored_opts "`ignored_opts' outputoff"
			noi di "{txt}note: `netname_temp' is a two-mode network - using {bf:nw2degree} instead."
			if "`ignored_opts'" != "" {
				noi di "{txt}      the following option(s) have no bipartite equivalent and were ignored:{bf:`ignored_opts'}"
			}
			noi nw2degree `netname_temp', generate(`generate') `replace' `silent'
			continue
		}

		tempvar included
		nw_datasync `netname_temp', generate(`included')
		local nodes_temp `nodes'

		tempname outdegree
		tempname indegree

		mata: `outdegree' = `netobj'->get_outdegree(`alpha')
		mata: `indegree' = `netobj'->get_indegree(`alpha')

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
		if ("`netgenerate'" != "" & "`directed'" == "true") {
			local __nwdeg_gencount : word count `netgenerate'
			if (`__nwdeg_gencount' < 2) {
				noi di "{err}Option {bf:generate()} needs at least 2 names (outdegree, indegree) for a directed network; got `__nwdeg_gencount'."
				error 198
			}
		}
		if ("`netgenerate'" == "") {
			if ("`directed'" == "true") {
				if "`valued'" == "true" {
					local netgenerate "_outstrength _instrength"
				}
				else {
					local netgenerate "_outdegree _indegree"
				}
			}
			else {
				if "`valued'" == "true" {
					local netgenerate "_strength"
				}
				else {
					local netgenerate "_degree"
				}
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
		foreach c in `_degree' `_indegree' `_outdegree' `_isolate' {
			capture confirm variable `c', exact
			if _rc == 0 & "`replace'" == "" {
				noi di "{err}Variable {bf:`c'} already exists; use {bf:replace} or {bf:generate()}"
				err 99
			}
			capture drop `c'
		}

		if ("`directed'" == "false"){
			capture generate `_degree' = .
			mata: st_store((1,`nodes_temp'), "`_degree'", `outdegree')
		}
		else {
			capture generate `_outdegree' = .
			capture generate `_indegree' = .
			mata: st_store((1,`nodes_temp'), "`_outdegree'", `outdegree')
			mata: st_store((1,`nodes_temp'), "`_indegree'", `indegree')
		}

		if "`standardize'" != "" {
			capture replace `_degree' = `_degree' / (`nodes_temp' - 1)
			capture replace `_outdegree' = `_outdegree' / (`nodes_temp' - 1)
			capture replace `_indegree' = `_indegree' / (`nodes_temp' - 1)
		}

		if "`isolates'" != "" {
			capture generate `_isolate' = .
			sum `_isolate'
			if "`directed'" == "true" {
				replace `_isolate' = (`_outdegree' == 0) * (`_indegree'==0) if `included' == 1
			}
			else {
				replace `_isolate' = (`_degree' == 0)  if `included' == 1
			}
		}

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{hline 40}"
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

		mata: st_rclear()

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
					noi di "{txt}   Degree centralization:: {res}" `=round(`r(dg_central)',0.001)'
				}
			}
			else {
				mata: st_numscalar("r(indg_central)", sum(J(`nodes_temp',1,max(`indegree')) :- `indegree') / ((`nodes_temp' - 1) * (`nodes_temp' - 1)))
				mata: st_numscalar("r(outdg_central)", sum(J(`nodes_temp',1,max(`outdegree')) :- `outdegree') / ((`nodes_temp' - 1) * (`nodes_temp' - 1)))
				if "`silent'" == "" {
					noi di
					// BUGFIX: same fix as the undirected branch above -
					// a 1-node directed network divides by zero here too.
					noi di "{txt}   Indegree centralization:: {res}" `=round(`r(indg_central)',0.001)'
					noi di "{txt}   Outdegree centralization:: {res}" `=round(`r(outdg_central)',0.001)'
				}
			}
		}
		capture drop `included'
		mata: mata drop `outdegree' `indegree'
	}

end

