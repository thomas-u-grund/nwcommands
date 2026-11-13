
capture program drop nwcug
program nwcug, rclass
	version 12
	syntax [anything(name=netname)], STAT(string) RNAME(string) [reps(integer 1000) seed(integer -1) tail(string) condition(string) silent plot name(string) trades(integer -1)]

	// BUGFIX: reps() was never validated - reps(0) silently "succeeded"
	// with a meaningless result (mean_null/sd_null missing, but p(two-
	// sided) reported as a concrete-looking 1, not obviously an error to
	// a user skimming the output), and any negative reps() crashed with
	// a raw Mata "argument out of range" the instant nwcug_nullvals =
	// J(reps,1,.) tried to allocate a negative-length vector. Confirmed
	// directly via an adversarial-input probe. A meaningful null
	// distribution needs at least 2 draws (1 alone gives sd_null
	// undefined too), so that is the floor enforced here.
	if `reps' < 2 {
		di "{err}{p 0 0 2}reps() must be at least 2 (a null distribution needs more than one draw); got `reps'.{p_end}"
		error 198
	}

	local tail = lower("`tail'")
	if "`tail'" == "" {
		local tail "both"
	}
	_opts_oneof "both upper lower" "tail" "`tail'" 6556

	local condition = lower("`condition'")
	if "`condition'" == "" {
		local condition "density"
	}
	_opts_oneof "density census mode1degree mode2degree degrees" "condition" "`condition'" 6556

	if `seed' != -1 {
		set seed `seed'
	}

	// short form (3.20.1): a stat() without the ##net## placeholder is a command that takes the
	// network as its first argument, so the placeholder goes right after the command name
	// (stat(nwclustering) is stat(nwclustering ##net##)); ##net## is still needed for a command
	// or program that takes the network elsewhere
	if strpos(`"`stat'"', "##net##") == 0 {
		gettoken __cmd __rest : stat, parse(" ,")
		local stat `"`__cmd' ##net##`__rest'"'
	}

	// Consistency (moderate-severity pass, stat_models group): a
	// misspelled/nonexistent network name used to crash with a raw,
	// low-level Mata error ("subscript invalid", r3301) from inside
	// `_nwsyntax' itself, instead of this package's usual clean
	// "{err}...{txt}" message.
	unw_defs
	capture _nwsyntax `netname'
	if _rc != 0 {
		di "{err}Network {bf:`netname'} not found."
		error `errNWsNotFound'
	}
	// a two-mode network has its own null models (below); a one-mode network meets the two-mode conditions as an error
	local __two = ("`is2mode'" == "true")
	if `__two' {
		if "`condition'" == "census" {
			di "{err}{p 0 0 2}condition(census) counts the dyads of a one-mode directed network; for a two-mode network use condition(density), condition(mode1degree), condition(mode2degree) or condition(degrees).{p_end}"
			error 198
		}
		mata: st_local("__ok", strofreal(nwg_comb_version() >= 12))
		if "`__ok'" != "1" {
			di "{err}{p 0 0 2}nwcug for a two-mode network draws with the native plugin of nwcommands 3.10.0 or later (plugin generation 12); the plugin found for this platform is older or missing.{p_end}"
			di "{err}{p 0 0 2}Update it: {stata nwinstall, all}{space 2}(or reinstall the package with {bf:net install nwcommands, replace}).{p_end}"
			error 198
		}
		if `trades' == 0 | `trades' < -1 {
			di "{err}trades() must be at least 1."
			error 198
		}
	}
	else {
		if inlist("`condition'", "mode1degree", "mode2degree") {
			di "{err}{p 0 0 2}condition(`condition') is for two-mode networks; use condition(density), condition(degrees) or condition(census) for a one-mode network.{p_end}"
			error 198
		}
		_nw2guard `netname', cmd(nwcug)
		if "`condition'" == "degrees" {
			// one-mode: every node keeps its degree (directed: out- and in-degree); the draws are a chain of tie swaps
			// (native kernel 55, igraph::rewire(g, keeping_degseq()))
			mata: st_local("__ok", strofreal(nwg_comb_version() >= 13))
			if "`__ok'" != "1" {
				di "{err}{p 0 0 2}nwcug, condition(degrees) for a one-mode network draws with the native plugin of nwcommands 3.17.0 or later; the plugin found for this platform is older or missing.{p_end}"
				di "{err}Update it: {stata nwinstall, all}"
				error 198
			}
			if `trades' == 0 | `trades' < -1 {
				di "{err}trades() must be at least 1."
				error 198
			}
		}
	}
	local origname "`netname'"

	if "`condition'" == "census" & "`directed'" != "true" & !`__two' {
		di "{err}{p 0 0 2}condition(census) requires a directed network - mutual/asymmetric/null dyad types only exist for directed ties; use condition(density) (the default) for an undirected network.{p_end}"
		error 198
	}

	tempname __nw_dens
	mata: st_numscalar("obsdensity", `netobj'->get_density())
	local obsdensity = obsdensity

	// BUGFIX: a 1-node network has 0 possible dyads, so its own density
	// is undefined (missing) - previously passed straight through to
	// nwrandom's own density() option, which never terminates when
	// asked to hit a missing target density (confirmed directly: hangs
	// indefinitely at 100% CPU, no error, no timeout). Only relevant to
	// the default condition(density) path - condition(census) doesn't
	// use obsdensity at all.
	if "`condition'" != "census" & `nodes' < 2 {
		di "{err}{p 0 0 2}nwcug needs at least 2 nodes for a condition(density) draw (network `origname' has `nodes').{p_end}"
		error 198
	}

	if "`condition'" == "census" {
		qui nwdyads `origname'
		local obsmutual = r(_100)
		local obsasym = r(_010)
	}

	// BUGFIX: stat() is documented as "any nw* command plus whatever
	// options it needs", and many such commands legitimately resize or
	// otherwise modify the ACTIVE dataset as part of their own ordinary
	// generate()-style behavior (e.g. nwcomponents ..., replace syncs
	// the current dataset to the network's own node count) - entirely
	// correct when that command is called directly by a user, but not
	// when nwcug is silently running it, up to `reps'+1 times, against
	// whatever dataset the CALLER happened to have active. Neither the
	// observed-value evaluation just below nor the reps loop further
	// down was ever protected, so a caller's own dataset (row count,
	// variables) could be silently resized/altered by nwcug and never
	// restored - confirmed directly: a 3-observation dataset with a
	// hand-added variable came back as a 5-observation dataset (the
	// network's own node count) after an ordinary nwcug call, no plot
	// involved. `obsval' below and `nwcug_nullvals' (Mata, unaffected
	// by dataset state) both survive `restore' safely, since restore
	// only reverts the dataset itself, never Stata locals or Mata
	// state - so wrapping the whole evaluation region is safe.
	preserve
	local obscmd = subinstr("`stat'", "##net##", "`origname'", .)
	qui `obscmd'
	// r(anything-undefined) silently evaluates to missing rather than
	// erroring (confirmed via an isolated repro) - an empty-string check
	// alone does not catch a bad rname(), so check for missing too.
	local obsval = r(`rname')
	if "`obsval'" == "" | "`obsval'" == "." {
		di "{err}stat() did not return a real r(`rname') for network `origname'"
		error 111
	}

	local drawopt "undirected"
	if "`directed'" == "true" {
		local drawopt ""
	}

	// BUGFIX: each draw below used to get nwrandom's own generic
	// auto-generated node names ("n1", "n2", ...) rather than
	// `origname''s own real ones ("g1", "g2", ... for `gang', say).
	// _nwdatasync() matches dataset rows to network nodes BY NAME (its
	// own documented contract - see _nwdatasync.ado's own header), so a
	// differently-named draw never matched any existing row and instead
	// got `nodes' entirely NEW rows appended to the dataset, with every
	// pre-existing node-attribute variable (e.g. a `nodematch()'-style
	// covariate) missing on all of them - silently, not as an error.
	// Confirmed directly: any stat() template depending on a node
	// attribute (nwmixing's own E-I index, tested directly) returned
	// r(rname) missing on every single draw, which `mean()'/`variance()'
	// then silently propagated to the WHOLE null distribution (both
	// reported as missing) while the tail-probability comparisons
	// (`nwcug_nullvals :>= obsval'/`:<= obsval') still "worked" - Mata
	// treats missing as larger than any real number, so every missing
	// draw silently counted as "greater than observed" and never as
	// "less than", producing a confident-looking but meaningless p-value
	// rather than an error. Fixed by giving every draw `origname''s own
	// real node names via `labs()' - nwrandom already supports this
	// option, so _nwdatasync's existing name-matching then reuses
	// `origname''s own existing rows (attributes and all) for each draw
	// instead of appending new, attribute-less ones. Harmless for a
	// stat() that does not depend on names/attributes at all (density,
	// a raw statistic count, ...): only the labels controlling row reuse
	// change, never the drawn graph's own structure.
	// the names go to nwrandom as a Mata variable: a long Stata option string gets blanks inserted (GOTCHA.md)
	tempname origlabs
	mata: `origlabs' = `netobj'->get_nodenames()

	mata: __nwcug_nullvals = J(`reps', 1, .)
	local base "_nwcug_draw"
	local drawcmd = subinstr("`stat'", "##net##", "`base'", .)
	if `__two' {
		// two-mode: one copy of the network is redrawn in place (native kernel 53): the same nodes, names and attributes
		local __model = cond("`condition'" == "density", 1, cond("`condition'" == "mode1degree", 2, cond("`condition'" == "mode2degree", 3, 4)))
		capture nwdrop `base'
		qui nwduplicate `origname', name(`base')
		qui _nwsyntax `base'
		local __dobj "`netobj'"
		qui _nwsyntax `origname'
		tempname __T __K __M
		mata: `__T' = J(0, 3, .)
		mata: `__K' = J(0, 3, .)
		mata: `__M' = J(0, 1, .)
		mata: nw2_cugstart(`netobj', `__T', `__K', `__M')
		mata: st_numscalar("__nwcug_nsmall", min((sum(`__M' :== 1), sum(`__M' :== 2))))
		local __thin = `trades'
		if `trades' < 0 local __thin = max(1, 5 * scalar(__nwcug_nsmall))
		local __burn = 6 * `__thin'
		forvalues i = 1/`reps' {
			local __nt = cond(`i' == 1, `__burn', `__thin')
			mata: st_local("__okd", strofreal(nw2_cugdraw(`__dobj', `__T', `__K', `__M', `__model', `__nt')))
			if "`__okd'" != "1" {
				di "{err}the native draw of the two-mode null model failed (out of memory?)."
				error 198
			}
			qui `drawcmd'
			local v = r(`rname')
			mata: __nwcug_nullvals[`i'] = `v'
		}
		mata: mata drop `__T' `__K' `__M'
	}
	else if "`condition'" == "degrees" {
		// one-mode, degrees kept: one copy of the network is rewired in place, draw after draw (a chain of tie swaps)
		capture nwdrop `base'
		qui nwduplicate `origname', name(`base')
		qui _nwsyntax `base'
		local __dobj "`netobj'"
		qui _nwsyntax `origname'
		tempname __T __K
		mata: `__T' = J(0, 3, .)
		mata: `__K' = J(0, 3, .)
		mata: nw1_cugstart(`netobj', `__T', `__K')
		mata: st_numscalar("__nwcug_nties", rows(`__T'))
		local __thin = `trades'
		if `trades' < 0 local __thin = max(1, 10 * scalar(__nwcug_nties))
		forvalues i = 1/`reps' {
			mata: st_local("__okd", strofreal(nw1_cugdraw(`__dobj', `__T', `__K', `__thin')))
			if "`__okd'" != "1" {
				di "{err}the native draw of the degree-preserving null model failed (out of memory?)."
				error 198
			}
			qui `drawcmd'
			local v = r(`rname')
			mata: __nwcug_nullvals[`i'] = `v'
		}
		mata: mata drop `__T' `__K'
	}
	else {
	forvalues i = 1/`reps' {
		capture nwdrop `base'
		if "`condition'" == "census" {
			qui nwrandom `nodes', census(`obsmutual' `obsasym') name(`base') nodenamesmata(`origlabs')
		}
		else {
			qui nwrandom `nodes', density(`obsdensity') name(`base') `drawopt' nodenamesmata(`origlabs')
		}
		qui `drawcmd'
		local v = r(`rname')
		mata: __nwcug_nullvals[`i'] = `v'
	}
	}
	capture nwdrop `base'
	restore

	// Defense in depth alongside the `labs()' fix above: if stat() still
	// returns a missing r(`rname') on some draw for a reason unrelated
	// to node-name/attribute matching (a caller's own stat() genuinely
	// failing sometimes, say), catch it here rather than let it silently
	// corrupt mean_null/sd_null (Mata's mean()/variance() propagate a
	// single missing to the WHOLE result) and skew the tail-probability
	// comparisons (missing sorts as larger than any real number, so an
	// uncaught missing draw would silently count as "greater than
	// observed" and never "less than").
	mata: st_numscalar("nmiss", missing(__nwcug_nullvals))
	if nmiss > 0 {
		di "{err}{p 0 0 2}stat() returned a missing r(`rname') on `=nmiss' of `reps' draws - results below are unreliable; check that stat()'s own statistic is defined for every network `condition'-conditioned random draws can produce.{p_end}"
	}

	mata: st_numscalar("meannull", mean(__nwcug_nullvals))
	mata: st_numscalar("sdnull", sqrt(variance(__nwcug_nullvals)))
	// plus-one (Monte Carlo) correction: the observed value counts as one more draw of the null, so a tail p-value is never 0
	mata: st_numscalar("pgreater", (1 + sum(__nwcug_nullvals :>= `obsval')) / (rows(__nwcug_nullvals) + 1))
	mata: st_numscalar("pless", (1 + sum(__nwcug_nullvals :<= `obsval')) / (rows(__nwcug_nullvals) + 1))

	// plot(): a histogram of the `reps' null draws with a dashed
	// reference line at the observed statistic - the same comparison
	// R's sna::plot.cug.test() draws, via this package's own established
	// preserve/rebuild-a-plotting-dataset/restore convention (matching
	// nwergm_estat's mcmcdiag/gof plot helpers) rather than a Statnet-
	// style S3 plot method, since nwcug has no such object to attach one
	// to. Grayscale by design (Stata Journal figures must stay legible
	// in black and white), same discipline as nwergm_estat's own plots.
	if "`plot'" != "" {
		if "`name'" == "" {
			local name "cug"
		}
		preserve
		qui drop _all
		mata: st_addobs(`reps')
		mata: st_store(., st_addvar("double", "nwcug_null"), __nwcug_nullvals)
		// The reference line is drawn as its own foreground plot layer
		// (a two-point vertical segment on a hidden, fixed-0/1 second
		// y-axis) rather than via xline() - xline()/yline() are
		// rendered as part of the axis background, so a solid
		// fcolor()-filled histogram bar draws OVER it wherever the
		// two overlap, leaving the dashed line visibly broken. A
		// same-scale twoway plot listed after the histogram always
		// draws on top; the hidden axis(2), fixed to range(0 1),
		// makes the segment span the full panel height regardless of
		// the histogram's own (data-dependent) density scale.
		twoway (histogram nwcug_null, fcolor(gs14) lcolor(gs8)) ///
			(scatteri 0 `obsval' 1 `obsval', recast(line) ///
				lcolor(black) lwidth(thick) lpattern(dash) yaxis(2)), ///
			yscale(off axis(2) range(0 1)) ///
			title("CUG test: `rname'", size(medium)) ///
			xtitle("`rname' (`reps' condition(`condition') draws)") ytitle("Density") ///
			legend(off) name(`name', replace)
		restore
		di as txt "{p 0 0 2}(plot saved as {bf:`name'}; histogram of the `reps' null draws under condition(`condition'), dashed line marks the observed value){p_end}"
	}

	mata: mata drop __nwcug_nullvals

	local ptwo = min(2*min(pgreater,pless), 1)

	return scalar obs = `obsval'
	return scalar reps = `reps'
	return scalar mean_null = meannull
	return scalar sd_null = sdnull
	return scalar p_greater = pgreater
	return scalar p_less = pless
	return scalar p = `ptwo'

	// Display from the locals/scalars computed above, not from r(), which
	// is only published to the caller once this program exits - a real
	// bug found (and fixed the same way) in nw2project.ado earlier this
	// session: r(x) reads as missing from inside the same program body
	// that just called "return scalar x = ...".
	if "`condition'" == "census" & sdnull == 0 {
		di "{txt}{p 0 0 2}Note: the null standard deviation is 0 under condition(census); this statistic is fixed by the dyad census, so the test is uninformative.{p_end}"
	}
	if "`silent'" == "" {
		// Stata-style display (3.20.1): a header with the network, the statistic, the number of
		// draws and the condition, then one row for the statistic
		local __w = max(12, udstrlen("`rname'"))
		local __np = cond("`tail'" == "both", 3, 1)
		local __tw = 10 * (3 + `__np') + 1
		di
		di as txt "Conditional uniform graph test" _col(50) "Number of draws" _col(66) "=" as res %11.0fc `reps'
		di as txt "Network: " as res "`origname'" _col(50) as txt "Condition" _col(66) "=" as res %11s "`condition'"
		di as txt "{p 0 11 2}Statistic: {res}r(`rname'){txt} after {res}`obscmd'{p_end}"
		di
		di as txt "{hline `=`__w'+1'}{c TT}{hline `__tw'}"
		local __h "{space `__w'} {c |}  Observed Null mean   Null sd"
		if "`tail'" != "lower" local __h "`__h'  P >= obs"
		if "`tail'" != "upper" local __h "`__h'  P <= obs"
		if "`tail'" == "both"  local __h "`__h' Two-sided"
		di as txt "`__h'"
		di as txt "{hline `=`__w'+1'}{c +}{hline `__tw'}"
		di as txt %`__w's "`rname'" " {c |}" as res " " %9.0g `obsval' " " %9.0g meannull " " %9.0g sdnull _c
		if "`tail'" != "lower" di as res " " %9.4f pgreater _c
		if "`tail'" != "upper" di as res " " %9.4f pless _c
		if "`tail'" == "both"  di as res " " %9.4f `ptwo' _c
		di
		di as txt "{hline `=`__w'+1'}{c BT}{hline `__tw'}"
	}
	capture mata: mata drop `origlabs'
	capture mata: mata drop __nwcug_*
	capture confirm number 0
end

capture mata: mata drop nw2_cugstart()
capture mata: mata drop nw2_cugdraw()
capture mata: mata drop nw1_cugstart()
capture mata: mata drop nw1_cugdraw()
mata:
// the cross-mode ties (mode 1, mode 2, value) of a two-mode network, the other ties, and the mode of every node
void nw2_cugstart(pointer(class nw_def scalar) scalar p, real matrix T, real matrix K, real colvector md)
{
	real matrix el
	real colvector cross

	md = strtoreal(p->get_modes())'
	el = p->edgelist()
	if (rows(el) == 0) {
		T = J(0, 3, .)
		K = J(0, 3, .)
		return
	}
	cross = ((md[el[., 1]] :== 1) :& (md[el[., 2]] :== 2)) :| ((md[el[., 1]] :== 2) :& (md[el[., 2]] :== 1))
	cross = cross :& (el[., 3] :< .) :& (el[., 3] :!= 0)
	T = select(el, cross :& (md[el[., 1]] :== 1))
	K = select(el, !cross)
}

// One draw of the null model (kernel 53 of the nwgraph plugin) written into the network p; T is the list of ties of the
// previous draw (the chain of the curveball trades).  Returns 1 on success.
real scalar nw2_cugdraw(pointer(class nw_def scalar) scalar p, real matrix T, real matrix K, real colvector md, real scalar model, real scalar ntrades)
{
	real matrix R, el
	real rowvector aux
	real scalar st, wasvalued

	if (rows(T) == 0) return(1)
	R = nwg_comb(53, rows(md), T, md, (model, floor(uniform(1, 1) * 2147483646) + 1, ntrades), aux, st)
	if (st != 0 | rows(R) != rows(T) | cols(R) != 3) return(0)
	T = R
	el = K \ R \ (R[., 2], R[., 1], R[., 3])
	wasvalued = p->isvalued
	p->set_edge_from_triplets(el[., 1], el[., 2], el[., 3], p->isdirect)
	p->isvalued = wasvalued
	return(1)
}
// the ties of a one-mode network that are swapped (no loop, a value that is neither 0 nor missing; undirected: once,
// i < j) and the others, which stay
void nw1_cugstart(pointer(class nw_def scalar) scalar p, real matrix T, real matrix K)
{
	real matrix el
	real colvector ok

	el = p->edgelist()
	if (rows(el) == 0) {
		T = J(0, 3, .)
		K = J(0, 3, .)
		return
	}
	ok = (el[., 3] :< .) :& (el[., 3] :!= 0) :& (el[., 1] :!= el[., 2])
	T = select(el, ok :& (p->isdirect :| (el[., 1] :< el[., 2])))
	K = select(el, !ok)
}

// One draw of the degree-preserving null model of a one-mode network (kernel 55 of the nwgraph plugin): nswap tie swaps
// on the ties T of the previous draw, written into the network p.  Returns 1 on success.
real scalar nw1_cugdraw(pointer(class nw_def scalar) scalar p, real matrix T, real matrix K, real scalar nswap)
{
	real matrix R, el
	real rowvector aux
	real scalar st, wasvalued

	if (rows(T) < 2) return(1)
	R = nwg_comb(55, p->get_nodes(), T, J(0, 1, .), (p->isdirect, floor(uniform(1, 1) * 2147483646) + 1, nswap, 0, p->get_nodes()), aux, st)
	if (st != 0 | rows(R) != rows(T) | cols(R) != 3) return(0)
	T = R
	if (p->isdirect) el = K \ R
	else el = K \ R \ (R[., 2], R[., 1], R[., 3])
	wasvalued = p->isvalued
	p->set_edge_from_triplets(el[., 1], el[., 2], el[., 3], p->isdirect)
	p->isvalued = wasvalued
	return(1)
}
end
