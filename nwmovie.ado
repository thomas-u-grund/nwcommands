*! nwmovie v2 - Cytoscape.js-based interactive/animated network movie
*! player, replacing the ImageMagick/graph-export pipeline entirely (see
*! docs/CERTIFICATION.md's own harmonisation-unit entry for the full
*! rationale and the real, measured tradeoffs against the old command).
*!
*! Two input modes, auto-detected from `netname':
*!   - PANEL mode: 2+ already-built networks of the same size, in
*!     sequence (nwmovie net1 net2 net3 ...) - the old command's own
*!     input convention, unchanged.
*!   - EVENT mode: exactly ONE network built via nwset's own eventtime()
*!     option (an event-type temporal network - the SAME input nwrem
*!     already consumes, see {help nwrem}) - NEW. Node positions stay
*!     fixed (one layout, computed once over the union of every
*!     sender/receiver pair that ever occurs); the movie replays real
*!     event time as a scrubbable timeline of ties appearing and, if
*!     window() is given, decaying.
*!
*! Both modes reuse nwplot's own color/shape/position resolution
*! pipeline (nwplot.ado's new movieexport() option, added alongside this
*! command) rather than re-deriving concrete hex colors from scratch -
*! one call to `nwplot <network>, interactive noopen movieexport(path)`
*! per panel network (or once, on a temp cumulative network, in event
*! mode), reading the resulting JSON back directly. The Cytoscape.js
*! player itself (play/pause/scrub/speed, keyframe diffing with real
*! .animate() transitions, GIF export via vendored gif.js) lives in
*! nwmovie_template.html, opened via the same chromeless native viewer
*! nwplot's own interactive option uses (nw_openviewer.ado).

capture program drop nwmovie
program nwmovie
	// edgecolor()/edgesize() are {help netname}s (a network whose own tie
	// values supply per-edge color/width - see {help nwplot}'s identical
	// edgecolor(string)/edgesize(string)), NOT Stata variables like
	// color()/symbol()/size() - BUGFIX: this line previously declared
	// them `varname', which made even the pre-existing singular
	// edgecolor()/edgesize() options fail outright ("Network <x> not
	// found") on any real use - confirmed directly, never caught before
	// because neither had test coverage.
	syntax anything(name=netname), [layout(string) duration(integer 800) easing(string) window(string) speed(real 1) fname(string) noopen color(varname) symbol(varname) size(varname) edgecolor(string) edgesize(string) label(varname) colors(varlist) symbols(varlist) sizes(varlist) edgecolors(string) edgesizes(string) titles(string asis) colorpalette(string) edgecolorpalette(string) symbolpalette(string) scheme(string) iterations(integer 500) fixedlayout]
	unw_defs

	mata: st_local("_nwmv_pkgdir", NativeGraphInstallDir())
	local _nwmv_template = "`_nwmv_pkgdir'/nwmovie_template.html"
	local _nwmv_cytoscape = "`_nwmv_pkgdir'/lib/vendor/cytoscape.min.js"
	local _nwmv_gifjs = "`_nwmv_pkgdir'/lib/vendor/gif.js"
	local _nwmv_gifworker = "`_nwmv_pkgdir'/lib/vendor/gif.worker.js"
	foreach _nwmv_f in _nwmv_template _nwmv_cytoscape _nwmv_gifjs _nwmv_gifworker {
		capture confirm file "``_nwmv_f''"
		if _rc {
			di as error "required file not found: ``_nwmv_f''; reinstall the package."
			error 601
		}
	}

	// ------------------------------------------------------------------
	// Mode detection: exactly one network name AND it is event-type
	// temporal => event mode; otherwise (2+ names) => panel mode, same
	// same-size requirement the old ImageMagick-era command already
	// enforced (errNWsSizeMismatch, unw_defs.ado).
	// ------------------------------------------------------------------
	local nwords : word count `netname'
	local mode ""
	if `nwords' == 1 {
		capture nw_syntax `netname', max(1)
		if _rc == 0 {
			if "`istemporal'" == "true" & "`temporaltype'" == "event" local mode "event"
		}
	}
	if "`mode'" == "" {
		capture nw_syntax `netname', max(999) min(2)
		if _rc != 0 {
			di as error "nwmovie requires either ONE event-type temporal network (built via {help nwset}'s {bf:eventtime()} option) or AT LEAST 2 panel networks of the same size, in sequence."
			error 198
		}
		local mode "panel"
		local sizecheck = 0
		foreach _nwmv_onenet in `netname' {
			nw_syntax `_nwmv_onenet', other(other)
			if `sizecheck' == 0 {
				local sizecheck = `othernodes'
			}
			else if `sizecheck' != `othernodes' {
				di as error "nwmovie's panel networks must all have the same number of nodes; `_nwmv_onenet' has `othernodes', expected `sizecheck'."
				error `errNWsSizeMismatch'
			}
		}
	}

	if "`fname'" == "" {
		local fname "movie"
	}
	if "`easing'" == "" {
		local easing "ease-in-out-cubic"
	}

	local _nwmv_colorpalette ""
	if "`colorpalette'" != "" local _nwmv_colorpalette "colorpalette(`colorpalette')"
	local _nwmv_edgecolorpalette ""
	if "`edgecolorpalette'" != "" local _nwmv_edgecolorpalette "edgecolorpalette(`edgecolorpalette')"
	local _nwmv_symbolpalette ""
	if "`symbolpalette'" != "" local _nwmv_symbolpalette "symbolpalette(`symbolpalette')"
	local _nwmv_scheme ""
	if "`scheme'" != "" local _nwmv_scheme "scheme(`scheme')"
	local _nwmv_color ""
	if "`color'" != "" local _nwmv_color "color(`color')"
	local _nwmv_symbol ""
	if "`symbol'" != "" local _nwmv_symbol "symbol(`symbol')"
	local _nwmv_size ""
	if "`size'" != "" local _nwmv_size "size(`size')"
	local _nwmv_edgecolor ""
	if "`edgecolor'" != "" local _nwmv_edgecolor "edgecolor(`edgecolor')"
	local _nwmv_edgesize ""
	if "`edgesize'" != "" local _nwmv_edgesize "edgesize(`edgesize')"
	local _nwmv_label ""
	if "`label'" != "" local _nwmv_label "label(`label')"
	local _nwmv_layout ""
	if "`layout'" != "" local _nwmv_layout "layout(`layout')"

	// Per-wave styling: colors()/symbols()/sizes()/edgecolors()/
	// edgesizes() each take one variable PER NETWORK (in the same order
	// as `netname'), unlike their singular color()/symbol()/etc.
	// counterparts above which broadcast ONE variable to every wave -
	// panel mode only (event mode has a single, static node layout, not
	// a sequence of waves to vary styling across). color/size are
	// genuinely tweened wave-to-wave by nwmovie_template.html's own
	// Cytoscape.js .animate() (numeric/color style properties are
	// natively interpolable there); shape stays a hard switch at the
	// start of each transition - not a simplification but a real
	// constraint documented in that file's own animateToFrame(): asking
	// Cytoscape to interpolate `shape' was the actual trigger for a
	// renderer crash chased through nwmovie's original development.
	local _nwmv_perwave_opts colors symbols sizes edgecolors edgesizes
	local _nwmv_perwave_singular color symbol size edgecolor edgesize
	local _nwmv_j = 0
	foreach _nwmv_po of local _nwmv_perwave_opts {
		local _nwmv_j = `_nwmv_j' + 1
		local _nwmv_so : word `_nwmv_j' of `_nwmv_perwave_singular'
		local _nwmv_list_`_nwmv_po' ""
		if "``_nwmv_po''" != "" {
			if "``_nwmv_so''" != "" {
				di as error "specify only one of {bf:`_nwmv_so'()} or {bf:`_nwmv_po'()}."
				error 198
			}
			if "`mode'" != "panel" {
				di as error "{bf:`_nwmv_po'()} (one variable per wave) is panel-mode only; use {bf:`_nwmv_so'()} in event mode."
				error 198
			}
			local _nwmv_pocount : word count ``_nwmv_po''
			if `_nwmv_pocount' != `nwords' {
				di as error "{bf:`_nwmv_po'()} must list exactly `nwords' variable(s), one per network, in the same order as `netname'."
				error 198
			}
			local _nwmv_list_`_nwmv_po' "``_nwmv_po''"
		}
	}

	// titles() overrides the movie's own displayed wave title (see the
	// panel-mode block below, right before _nwmovie_assemblepanel(), for
	// how the DEFAULT title is resolved when titles() is not given) -
	// count-validated there too, once `_nwmv_k' exists; only the
	// panel-mode-only check happens this early, matching the other
	// per-wave options' own validation order above.
	if `"`titles'"' != "" & "`mode'" != "panel" {
		di as error "{bf:titles()} (one title per wave) is panel-mode only."
		error 198
	}

	tempname _nwmv_json
	tempfile _nwmv_jsonstub
	local _nwmv_jsondir = "`c(tmpdir)'"

	if "`mode'" == "panel" {
		local _nwmv_first : word 1 of `netname'
		nw_syntax `_nwmv_first', other(other)
		local _nwmv_directed = ("`otherdirected'" == "true")
		local _nwmv_k : word count `netname'

		// The movie's own displayed wave title (toolbar text + the
		// draggable/resizable on-canvas overlay in nwmovie_template.html,
		// baked into GIF exports too) - built ENTIRELY in Mata rather than
		// round-tripped through a Stata macro, since a title may contain
		// spaces and Mata's own tokens() (used both for titles()'s own
		// double-quoted list and to hand this off to
		// _nwmovie_assemblepanel() below) already parses that compound-
		// quoted convention correctly with no extra Stata-side quote
		// handling to get wrong.
		if `"`titles'"' != "" {
			mata: _nwmv_labelvec = tokens(`"`titles'"')
			mata: st_local("_nwmv_titlecount", strofreal(cols(_nwmv_labelvec)))
			if `_nwmv_titlecount' != `_nwmv_k' {
				di as error "titles() must list exactly `_nwmv_k' double-quoted title(s), one per network, in the same order as `netname'."
				error 198
			}
		}
		else {
			// default: each wave's own get_label() - set via {help
			// nwname}'s newtitle(), a network's real display title,
			// distinct from its bare Stata object name - if one was ever
			// given; falls back to the bare network name (this command's
			// only behavior before titles() existed) when a wave was
			// never given a title of its own.
			mata: _nwmv_labelvec = J(1, `_nwmv_k', "")
			local _nwmv_li = 0
			foreach _nwmv_onenet3 of local netname {
				local _nwmv_li = `_nwmv_li' + 1
				nw_syntax `_nwmv_onenet3', other(other3)
				mata: _nwmv_labelvec[1,`_nwmv_li'] = (strlen(`other3netobj'->get_label()) > 0 ? `other3netobj'->get_label() : "`_nwmv_onenet3'")
			}
		}

		// Per-wave TRANSITIONING layout is now the default: each wave
		// gets its own layout, computed with layout(kk)'s own optional
		// warm start (see kklayout()'s own header comment in
		// nwplot.ado) fed forward from the PREVIOUS wave's own final
		// positions, so consecutive waves relax into nearby layouts -
		// a real, visible transition - rather than reusing one single,
		// static layout for the whole movie (the original, and only,
		// behavior before this). `fixedlayout' restores that original
		// one-fixed-layout-for-every-wave behavior. A per-wave
		// transition is a `layout(kk)'-specific idea - kk's own stress-
		// majorization iteration is what actually has a "warm start"
		// concept to relax from; mds/mdsclassical/circle/grid/etc. have
		// no equivalent, so an explicit non-kk `layout()' here falls
		// back to `fixedlayout''s own single-shared-layout behavior
		// instead of silently ignoring the request.
		local _nwmv_transition = ("`fixedlayout'" == "" & ("`layout'" == "" | "`layout'" == "kk"))

		if !`_nwmv_transition' {
			// One fixed layout, computed on the FIRST network only,
			// reused for every keyframe via nodexy() - node identity
			// stays visually trackable across the whole movie, at the
			// cost of never showing the layout itself moving/settling
			// differently wave to wave. Node order must therefore match
			// across panel networks (the same convention panel-data
			// network analysis already assumes elsewhere in this
			// package, e.g. nwsaom's own wave1()/wave2()).
			tempvar _nwmv_x _nwmv_y
			qui nwplot `_nwmv_first', ignorelgc `_nwmv_layout' iterations(`iterations') generate(`_nwmv_x' `_nwmv_y') noopen
			capture graph close _nwplot_interactive
			graph drop _all
		}
		else {
			// Chain of per-wave kk layouts. Wave 1's own layout is
			// still computed through the normal `nwplot ..., generate()'
			// path (not a direct kklayout() call) since it is the SAME
			// computation either way (layout(kk) is the package
			// default) and this keeps wave 1's own resolution logic in
			// one place. Waves 2+ below call kklayout() directly -
			// safe to do because kklayout() (and distance()/
			// circlelayout()) now live in unw_core.do, compiled into
			// lib/lnwcommands.mlib, this package's own reliable
			// mechanism for Mata code shared across .ado files (a
			// function defined inline inside an ordinary .ado file's
			// own mata: block, like nwplot.ado's old copy, is NOT
			// reliably callable from a different .ado file's Mata
			// code - confirmed directly - which is why these moved.
			tempvar _nwmv_x1 _nwmv_y1
			qui nwplot `_nwmv_first', ignorelgc iterations(`iterations') generate(`_nwmv_x1' `_nwmv_y1') noopen
			capture graph close _nwplot_interactive
			graph drop _all
			mata: _nwmv_prevpos = (st_data(., "`_nwmv_x1'"), st_data(., "`_nwmv_y1'"))
		}

		local _nwmv_i = 0
		local _nwmv_keyframes ""
		foreach _nwmv_net in `netname' {
			local _nwmv_i = `_nwmv_i' + 1

			// wave-specific styling overrides: fall back to the
			// broadcast singular option (already resolved above) when
			// the caller didn't give the corresponding plural one.
			local _nwmv_wave_color "`_nwmv_color'"
			if `"`_nwmv_list_colors'"' != "" {
				local _nwmv_thisvar : word `_nwmv_i' of `_nwmv_list_colors'
				local _nwmv_wave_color "color(`_nwmv_thisvar')"
			}
			local _nwmv_wave_symbol "`_nwmv_symbol'"
			if `"`_nwmv_list_symbols'"' != "" {
				local _nwmv_thisvar : word `_nwmv_i' of `_nwmv_list_symbols'
				local _nwmv_wave_symbol "symbol(`_nwmv_thisvar')"
			}
			local _nwmv_wave_size "`_nwmv_size'"
			if `"`_nwmv_list_sizes'"' != "" {
				local _nwmv_thisvar : word `_nwmv_i' of `_nwmv_list_sizes'
				local _nwmv_wave_size "size(`_nwmv_thisvar')"
			}
			local _nwmv_wave_edgecolor "`_nwmv_edgecolor'"
			if `"`_nwmv_list_edgecolors'"' != "" {
				local _nwmv_thisvar : word `_nwmv_i' of `_nwmv_list_edgecolors'
				local _nwmv_wave_edgecolor "edgecolor(`_nwmv_thisvar')"
			}
			local _nwmv_wave_edgesize "`_nwmv_edgesize'"
			if `"`_nwmv_list_edgesizes'"' != "" {
				local _nwmv_thisvar : word `_nwmv_i' of `_nwmv_list_edgesizes'
				local _nwmv_wave_edgesize "edgesize(`_nwmv_thisvar')"
			}

			if `_nwmv_transition' & `_nwmv_i' == 1 {
				local _nwmv_x "`_nwmv_x1'"
				local _nwmv_y "`_nwmv_y1'"
			}
			else if `_nwmv_transition' {
				tempvar _nwmv_x _nwmv_y
				tempname _nwmv_wavemat
				// nwtomata's own mat() option creates a bare MATA variable
				// under this literal name (confirmed directly in
				// cscripts/test_nwtomata.do - consumers reference it as
				// `mat' itself, e.g. `mata: assert(M[2,1]==1)', never via
				// st_matrix()); it is NOT pushed into Stata's own matrix
				// store, so st_matrix() on it reads back an empty 0x0
				// matrix instead - referencing it directly here instead.
				nwtomata `_nwmv_net', mat(`_nwmv_wavemat')
				mata: _nwmv_waveM = `_nwmv_wavemat'
				mata: _nwmv_waveM = (_nwmv_waveM :+ _nwmv_waveM') :/ (_nwmv_waveM :+ _nwmv_waveM')
				mata: _editmissing(_nwmv_waveM, 0)
				// kklayout() lives in unw_core.do (compiled into
				// lib/lnwcommands.mlib), so it is directly callable here
				// with no Stata-matrix round trip needed.
				mata: _nwmv_prevpos = kklayout(_nwmv_waveM, `iterations', _nwmv_prevpos)
				qui gen `_nwmv_x' = .
				qui gen `_nwmv_y' = .
				mata: st_store((1::rows(_nwmv_prevpos)), ("`_nwmv_x'","`_nwmv_y'"), _nwmv_prevpos)
				mata: mata drop _nwmv_waveM
			}

			local _nwmv_out "`_nwmv_jsondir'nwmovie_kf`_nwmv_i'_`=subinstr(subinstr("`c(current_time)'", ":", "", .), " ", "", .)'_`=strofreal(int(runiform()*1000000))'.json"
			// fopen(path,"w") errors (602) if the path already exists,
			// unlike a plain overwrite - matching nwplot.ado's own
			// defensive `capture erase` before its identical interactive-
			// html fopen(,"w") call, needed here too since a bare
			// runiform() draw is not guaranteed unique across two Stata
			// batch invocations started within the same clock second (the
			// actual collision observed while building this: two
			// sequential smoke-test runs landed on the identical seed).
			capture erase "`_nwmv_out'"
			noi di "{txt}Resolving network {bf:`_nwmv_net'} (`_nwmv_i'/`_nwmv_k')..."
			qui nwplot `_nwmv_net', ignorelgc interactive noopen movieexport("`_nwmv_out'") nodexy(`_nwmv_x' `_nwmv_y') `_nwmv_wave_color' `_nwmv_wave_symbol' `_nwmv_wave_size' `_nwmv_wave_edgecolor' `_nwmv_wave_edgesize' `_nwmv_label' `_nwmv_colorpalette' `_nwmv_edgecolorpalette' `_nwmv_symbolpalette' `_nwmv_scheme'
			capture confirm file "`_nwmv_out'"
			if _rc {
				di as error "nwmovie: failed to resolve network `_nwmv_net' via nwplot."
				error 601
			}
			local _nwmv_keyframes "`_nwmv_keyframes' `_nwmv_out'"
		}
		capture mata: mata drop _nwmv_prevpos

		mata: _nwmovie_assemblepanel("`_nwmv_keyframes'", _nwmv_labelvec, `duration', "`easing'", `_nwmv_directed', "`_nwmv_template'", "`_nwmv_cytoscape'", "`_nwmv_gifjs'", "`_nwmv_gifworker'", "`fname'.html")
		mata: mata drop _nwmv_labelvec
	}
	else {
		// Event mode: nodes are static; the temp "cumulative" network
		// (union of every sender/receiver pair that ever occurs) exists
		// ONLY to get nwplot's own layout/color/shape resolution for a
		// stable initial view - built via mat()/labs() in the EXACT
		// get_nodenames() order so its own node indices line up 1:1
		// with the eventlist's own sender/receiver indices, with no
		// remapping needed.
		mata: st_local("_nwmv_nodes", strofreal(`netobj'->get_nodes()))
		tempname _nwmv_evlist
		// get_eventlist() makes no ordering guarantee of its own (same
		// finding nwrem's own RemState::init() already documents, in
		// unw_rem.do) - sort ascending by event time here, since the
		// browser-side timeline player (nwmovie_template.html's seekTo())
		// assumes chronological order, exactly like RemState does.
		mata: `_nwmv_evlist' = *(`netobj'->get_eventlist())
		mata: `_nwmv_evlist' = `_nwmv_evlist'[order(`_nwmv_evlist'[.,3], 1), .]
		mata: st_numscalar("_nwmv_nev", rows(`_nwmv_evlist'))
		local _nwmv_nev = _nwmv_nev
		scalar drop _nwmv_nev
		if `_nwmv_nev' < 1 {
			di as error "nwmovie: `netname' has no events."
			error 2001
		}

		// `i' here is a plain Mata script variable, not a Stata local -
		// no backtick-quoting (unlike every other `_nwmv_*' reference in
		// this program, which ARE Stata locals): a `_nwmv_i'' backtick
		// reference here would be substituted by STATA's macro processor
		// (to an empty string, since no such local exists in this
		// branch) before Mata ever saw it, turning the loop bounds into
		// garbage - confirmed directly, this exact mistake produced a
		// bare "expression invalid" r(3000) with no further detail.
		tempname _nwmv_cumM
		mata: `_nwmv_cumM' = J(`_nwmv_nodes', `_nwmv_nodes', 0)
		mata: for (i=1; i<=rows(`_nwmv_evlist'); i++) `_nwmv_cumM'[`_nwmv_evlist'[i,1], `_nwmv_evlist'[i,2]] = 1
		// get_nodenames() already returns a row vector (confirmed
		// directly - the surrounding assumption elsewhere in this
		// package is not always consistent about this), so no
		// transpose here.
		mata: st_local("_nwmv_labs", invtokens(`netobj'->get_nodenames()))

		// NOT nwclear before this nwset - nwclear destroys every named
		// network in memory (unw_defs's own `nw' Mata object, package-
		// wide, not dataset-scoped - confirmed directly in nwclear.ado),
		// which would take the caller's own original event network down
		// with it (this program is still holding a live pointer into it,
		// `netobj', from the mode-detection nw_syntax call above). A
		// brand-new nwset ..., name() call needs no clearing first -
		// multiple named networks already coexist fine without it
		// elsewhere in this package (e.g. dev/saom_rsiena_benchmark.do's
		// own back-to-back nwset ..., name(wave1)/name(wave2) calls).
		preserve
		mata: st_matrix("_nwmv_cumM_st", `_nwmv_cumM')
		nwset, mat(_nwmv_cumM_st) directed name(_nwmv_cumnet) labs(`_nwmv_labs')
		matrix drop _nwmv_cumM_st

		local _nwmv_out "`_nwmv_jsondir'nwmovie_evnodes_`=subinstr(subinstr("`c(current_time)'", ":", "", .), " ", "", .)'_`=strofreal(int(runiform()*1000000))'.json"
		capture erase "`_nwmv_out'"
		qui nwplot _nwmv_cumnet, ignorelgc `_nwmv_layout' iterations(`iterations') interactive noopen movieexport("`_nwmv_out'") `_nwmv_color' `_nwmv_symbol' `_nwmv_size' `_nwmv_colorpalette' `_nwmv_symbolpalette' `_nwmv_scheme' `_nwmv_label'
		capture nwdrop _nwmv_cumnet
		restore
		capture confirm file "`_nwmv_out'"
		if _rc {
			di as error "nwmovie: failed to resolve `netname''s node layout via nwplot."
			error 601
		}

		local _nwmv_windowval "."
		if "`window'" != "" {
			capture confirm number `window'
			if _rc {
				di as error "window() must be a number, in the same units as {help nwset}'s {bf:eventtime()} variable."
				error 198
			}
			local _nwmv_windowval "`window'"
		}

		mata: _nwmovie_assembleevent("`_nwmv_out'", `_nwmv_evlist', `speed', `_nwmv_windowval', "`_nwmv_template'", "`_nwmv_cytoscape'", "`_nwmv_gifjs'", "`_nwmv_gifworker'", "`fname'.html")
		mata: mata drop `_nwmv_evlist' `_nwmv_cumM'
	}

	di "{txt}Wrote {bf:`fname'.html}"
	if "`noopen'" == "" {
		nw_openviewer "`c(pwd)'/`fname'.html"
	}
end

// -----------------------------------------------------------------------
// Mata assembly: splices each per-network resolved-JSON blob
// (_nwedit_buildjson()'s own output, via nwplot's movieexport()) into one
// combined MOVIE_DATA object for nwmovie_template.html, using pure string
// concatenation - no JSON parser needed on the Mata side at all, since
// the only consumer of these files is the browser's own JS engine
// (`const MOVIE_DATA = __NWMOVIE_DATA__;` is a JS literal assignment, not
// JSON.parse()) and every producer/consumer pair here is code in this
// same package. Each per-network blob keeps its own "nodes"/"edges"
// arrays verbatim (already exactly the shape nwmovie_template.html
// expects for one keyframe) - only a "label" field is prepended.
// -----------------------------------------------------------------------
capture mata: mata drop _nwmovie_slurpfile()
capture mata: mata drop _nwmovie_writehtml()
capture mata: mata drop _nwmovie_assemblepanel()
capture mata: mata drop _nwmovie_assembleevent()
mata:
// A private copy of nwplot.ado's own _nwedit_slurpfile(), not a call to
// it directly - confirmed empirically (not assumed) that a Mata
// function defined in one .ado file's own mata: block is NOT reliably
// callable from a different .ado file's Mata code when both are loaded
// the NORMAL way (auto-loaded by Stata's own command dispatch): a
// standalone probe showed nwplot.ado's _nwedit_slurpfile() genuinely
// missing from Mata's function table immediately after a successful,
// error-free `nwplot ..., movieexport()' call from a fresh session (it
// IS visible when nwplot.ado is instead loaded via an explicit `run'/
// `do', which is why this gap never surfaced during this feature's own
// earlier scratch testing - those scripts all used `run'). Duplicating
// this one small, stable utility is simpler and more robust than
// depending on cross-.ado Mata linkage that does not actually hold
// under real, ordinary command usage.
string scalar _nwmovie_slurpfile(string scalar path)
{
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

void _nwmovie_writehtml(string scalar data, string scalar tplpath,
		string scalar cytopath, string scalar gifjspath, string scalar gifworkerpath,
		string scalar outpath)
{
	string scalar tpl, vjs, gifjs, gifworkersrc, gifworkerb64
	transmorphic fh

	tpl = _nwmovie_slurpfile(tplpath)
	vjs = _nwmovie_slurpfile(cytopath)
	gifjs = _nwmovie_slurpfile(gifjspath)
	gifworkersrc = _nwmovie_slurpfile(gifworkerpath)
	gifworkerb64 = base64encode(gifworkersrc)

	tpl = subinstr(tpl, "__NWMOVIE_CYTOSCAPE__", vjs)
	tpl = subinstr(tpl, "__NWMOVIE_GIFJS__", gifjs)
	tpl = subinstr(tpl, "__NWMOVIE_GIFWORKER__", "atob(" + char(34) + gifworkerb64 + char(34) + ")")
	tpl = subinstr(tpl, "__NWMOVIE_DATA__", data)

	// fopen(,"w") errors (602) if outpath already exists, unlike a plain
	// overwrite - unlike the randomly-named intermediate JSON files
	// above, `outpath' here is the user's own fixed fname().html, which
	// is EXPECTED to already exist on a re-run (that is the whole point
	// of re-running nwmovie with the same fname()).
	if (fileexists(outpath)) unlink(outpath)
	fh = fopen(outpath, "w")
	fwrite(fh, tpl)
	fclose(fh)
}

void _nwmovie_assemblepanel(string scalar jsonfiles, string rowvector labels,
		real scalar duration, string scalar easing, real scalar isdirected,
		string scalar tplpath, string scalar cytopath, string scalar gifjspath,
		string scalar gifworkerpath, string scalar outpath)
{
	string rowvector files
	string scalar q, data, blob, one
	real scalar i

	q = char(34)
	files = tokens(jsonfiles)
	data = "{"+q+"mode"+q+":"+q+"panel"+q+","+
		q+"directed"+q+":"+(isdirected==1 ? "true" : "false")+","+
		q+"duration"+q+":"+strofreal(duration)+","+
		q+"easing"+q+":"+q+easing+q+","+q+"keyframes"+q+":["
	for (i=1; i<=cols(files); i++) {
		blob = _nwmovie_slurpfile(files[i])
		// blob is "{...}" (a full JSON object) - splice a label field in
		// right after the opening brace.
		one = "{"+q+"label"+q+":"+q+labels[i]+q+"," + substr(blob, 2, strlen(blob)-1)
		data = data + one
		if (i < cols(files)) data = data + ","
	}
	data = data + "]}"

	_nwmovie_writehtml(data, tplpath, cytopath, gifjspath, gifworkerpath, outpath)
}

void _nwmovie_assembleevent(string scalar nodejsonfile, real matrix evlist,
		real scalar speed, real scalar window,
		string scalar tplpath, string scalar cytopath, string scalar gifjspath,
		string scalar gifworkerpath, string scalar outpath)
{
	string scalar q, data, blob, windowstr
	real scalar i

	q = char(34)
	// The resolved-cumulative-network blob is embedded WHOLE (as its own
	// "_nodesource" field, read by nwmovie_template.html as
	// MOVIE_DATA._nodesource.nodes) rather than string-surgered apart in
	// Mata to pull out just its "nodes" array - a first attempt at that
	// surgery (locating "nodes":[ / ],"edges" by strpos()+substr()) was
	// genuinely broken (off-by-one at both ends, confirmed directly:
	// produced a doubled leading "[[" and a missing closing "]"), and
	// splicing the whole object is exactly the same, already-proven
	// pattern _nwmovie_assemblepanel() already uses for each keyframe -
	// no parser needed on the Mata side either way.
	blob = _nwmovie_slurpfile(nodejsonfile)

	windowstr = (window == . ? "null" : strofreal(window))

	data = "{"+q+"mode"+q+":"+q+"event"+q+","+
		q+"directed"+q+":true,"+
		q+"speed"+q+":"+strofreal(speed)+","+
		q+"window"+q+":"+windowstr+","+
		q+"tmin"+q+":"+strofreal(min(evlist[.,3]))+","+
		q+"tmax"+q+":"+strofreal(max(evlist[.,3]))+","+
		q+"_nodesource"+q+":"+blob+","+
		q+"events"+q+":["
	for (i=1; i<=rows(evlist); i++) {
		data = data + "{"+q+"sender"+q+":"+q+"n"+strofreal(evlist[i,1])+q+","+
			q+"receiver"+q+":"+q+"n"+strofreal(evlist[i,2])+q+","+
			q+"t"+q+":"+strofreal(evlist[i,3])+"}"
		if (i < rows(evlist)) data = data + ","
	}
	data = data + "]}"

	_nwmovie_writehtml(data, tplpath, cytopath, gifjspath, gifworkerpath, outpath)
}
end
