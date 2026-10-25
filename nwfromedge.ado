
capture program drop nwfromedge
program nwfromedge
	syntax varlist(min=2 max=3) [if] [, overwrite REPLACE labprefix(string) noclear xvars name(string) labs(string asis) directed undirected forcedirected forceundirected twomode]

	// HARMONISATION: `twomode' makes the existing, separate `nw2fromedge'
	// command reachable directly from `nwfromedge' too - mirroring
	// exactly how `nwset's own `twomode' option is implemented (see
	// nwset.ado's own header comment at its `twomode' branch): a
	// two-mode edgelist declaration is already `nw2fromedge's own job,
	// with real, non-trivial logic (same-label disambiguation between
	// the two node sets, mode assignment by which edgelist column a
	// label actually came from) that is deliberately NOT duplicated
	// here a second time. Forwards only `name()'/`xvars', matching
	// nwset.ado's own forwarding scope exactly (not a wider, unproven
	// surface) - `directed'/`undirected'/`forcedirected'/
	// `forceundirected' make no sense for an inherently undirected
	// two-mode network and are rejected explicitly rather than silently
	// ignored. Must run before `unw_defs' below, which sets up
	// one-mode-specific state this branch never needs.
	if "`twomode'" != "" {
		if "`directed'" != "" | "`undirected'" != "" | "`forcedirected'" != "" | "`forceundirected'" != "" {
			di "{err}option {bf:twomode} declares an inherently undirected two-mode network - it cannot be combined with {bf:directed}/{bf:undirected}/{bf:forcedirected}/{bf:forceundirected}."
			error 198
		}
		nw2fromedge `varlist' `if', name(`name') `xvars'
		exit
	}

	unw_defs
	// Isolate preservation (#5): if the edgelist in memory came from
	// nwtoedge on a single source network, it carries that network's own
	// full node list as a dataset characteristic (get_nodenames_string()'s
	// ";"-delimited format) - grabbed here, before anything below touches
	// the dataset, since a characteristic is dataset-level metadata that
	// `if'/`keep'-style filtering does not disturb but a `preserve'/`use'
	// of a DIFFERENT dataset would. Applied near the end of this program,
	// once the new network actually exists.
	local __iso_srclabels : char _dta[nwtoedge_nodes]
	// NOTE: this file's own `overwrite' predates this option and controls
	// nwload's own overwrite behavior further below (`qui nwload,
	// `overwrite''), unrelated to network-name-collision - kept exactly
	// as-is. `replace' is a NEW, separate option: whether an existing
	// network under the requested name() should be replaced in place,
	// mirroring nwset.ado's own now-fixed collision guard (name()
	// colliding with an existing network used to always silently switch
	// to an auto-generated alternative name via nwvalidate below,
	// regardless of any option - confirmed directly, nothing in this
	// file ever checked for that collision at all before now).
	
	// obtain variable names
	local fromvar : word 1 of `varlist'
	local tovar : word 2 of `varlist'
	
	// check if egoid and alterid are of different type
	capture confirm numeric variable `fromvar'
	if _rc == 0 {
		capture confirm string variable `tovar'
		if _rc == 0 {
			tempvar x
			gen `x' = strofreal(`fromvar')
			local fromvar `x'
		}
	}
	else {
		capture confirm numeric variable `tovar'
		if _rc == 0 {
			tempvar x
			gen `x' = strofreal(`tovar')
			local tovar `x'
		}
	}
	
	capture replace `fromvar' = trim(`fromvar')	
	capture replace `tovar' = trim(`tovar')	
		
	qui {
	
	tempvar _value
	if (wordcount("`varlist'") == 3) {
		local value : word 3 of `varlist'
		gen double `_value' = `value'
		_extract_valuelabels `value'
		local edgelabs "`r(valuelabels)'"
	}
	else {
		gen byte `_value' = 1
	}
	
	// check for string variables
	capture confirm string variable `fromvar' `tovar'
	local fromStrings = 0
	tempfile dictionaryString
	
	// if condition
	if "`if'" != ""{ 
		keep `if'
	}
	
	// Row order of the edge list as given.  The sorts and merges below
	// scramble it, and duplicate (ego,alter) rows must resolve the same
	// way every time: the LAST row given wins (what filling an adjacency
	// matrix cell by cell does).  Rows that go through collapse (string
	// ids) are already unique, so the variable is simply gone there.
	tempvar _roworder
	gen long `_roworder' = _n

	tempfile dictionaryOriginalString
	
	// deal with strings as node identifiers
	if _rc == 0 {
		local rawtype "string"
	}
	else {
		local rawtype "numeric"
	}
	
	qui if _rc == 0 {
		local fromStrings = 1
		tempvar _nodeid _fromvarid _tovarid
		preserve
		stack `fromvar' `tovar', into(`fromvar') clear
		sort `fromvar'
		egen `_nodeid' = group(`fromvar')
		gen `tovar' = `fromvar'
		drop _stack		
		save `dictionaryString', replace
		
		sort `_nodeid'
		keep if `_nodeid' != `_nodeid'[_n-1]
		
		// Node labels travel through Mata, never through a macro: a macro
		// of 100,000 labels overflows Stata/BE's 264,408-character limit
		// (r(920)), and building it cost O(n^2).
		if "`labs'" == "" {
			capture mata: mata drop __nwlabvec
			putmata __nwlabvec = `fromvar'
		}
		restore

		merge m:n `fromvar' using `dictionaryString'
		gen `_fromvarid' = `_nodeid' 
		drop if _merge != 3
		drop _merge `_nodeid'
		merge m:n `tovar' using `dictionaryString'
		gen `_tovarid' = `_nodeid'
		drop if _merge != 3
		drop _merge

		destring `fromvar', force replace
		destring `tovar', force replace
		replace `fromvar' = `_fromvarid'
		replace `tovar' = `_tovarid'
		collapse (max) `_value', by(`fromvar' `tovar')
	}

	// `labprefix' (renamed from `prefix' during harmonisation, to avoid
	// colliding with nwrecode's unrelated network-naming `prefix()') was
	// previously overwritten unconditionally in the dictionary block below,
	// discarding whatever the caller's own option had set - a dead option
	// (node labels were always n-prefixed regardless). Now only defaults to
	// "n" when the caller left labprefix() unspecified.
	if "`labprefix'" == "" {
		local labprefix "n"
	}

	// Fast route for the dictionary of node identifiers (the stack/egen/collapse/merge/merge below cost 0.9 s of a
	// 100,000-node network): the same mapping done in Mata. Used when the dataset is cleared afterwards (the default;
	// the route below rewrites the caller's variables in place, which only matters with noclear) and every identifier
	// is an integer that a float stores exactly, so that the dictionary below (a collapse (mean) that keeps a float)
	// is exact. Anything else, or a list without a single complete row, takes the route below, unchanged.
	local __fe_fast 0
	if "`clear'" == "" {
		capture mata: mata drop __nwP
		capture confirm variable `_roworder'
		local __fe_roworder = cond(_rc == 0, "`_roworder'", "")
		mata: __nwP = nw_fromedge_prep("`fromvar'", "`tovar'", "`_value'", "`__fe_roworder'")
		mata: st_local("__fe_fast", strofreal(cols(__nwP) == 5))
		if `__fe_fast' {
			capture mata: mata drop __nwvalue
			capture mata: mata drop __nwego
			capture mata: mata drop __nwalter
			capture mata: mata drop __nwrank
			mata: __nwego = *__nwP[1]; __nwalter = *__nwP[2]; __nwvalue = *__nwP[3]; __nwrank = *__nwP[4]
			mata: st_local("maxNodes", strofreal(max((max(__nwego), max(__nwalter))), "%18.0g"))
			if "`rawtype'" == "numeric" & "`labs'" == "" {
				capture mata: mata drop __nwlabvec
				mata: __nwlabvec = "`labprefix'" :+ strofreal(*__nwP[5], "%18.0g")
			}
		}
		capture mata: mata drop __nwP
	}

	if !`__fe_fast' {

	// deal with non-consecutive integers as node identifiers
	set more off
	tempfile dictionaryConsecutive
	
	preserve
	tempvar _rawid _id _fromid _toid 
	tempname mynet
	
	// Generate a dictionary that maps the raw id's from the edgelist to consecutive id numbers.
	keep `fromvar' `tovar'
	stack `fromvar' `tovar', into(`_rawid') clear
	keep `_rawid'
	egen `_id' = group(`_rawid')
	collapse (mean) `_rawid', by(`_id')
	sort `_rawid'

	// `labprefix' (renamed from `prefix' during harmonisation, to avoid
	// colliding with nwrecode's unrelated network-naming `prefix()') was
	// previously overwritten unconditionally here, discarding whatever
	// the caller's own option had set - a dead option (node labels were
	// always n-prefixed regardless). Now only defaults to "n" when the
	// caller left labprefix() unspecified.
	if "`labprefix'" == "" {
		local labprefix "n"
	}
	if "`rawtype'" == "numeric" {
		if "`labs'" == "" {
			capture mata: mata drop __nwlabvec
			putmata __nwlabvec = `_rawid'
			mata: __nwlabvec = "`labprefix'" :+ strofreal(__nwlabvec, "%18.0g")
		}
	}
	save `dictionaryConsecutive', replace
	
	tempfile dictionaryOriginal
	if "`keeporiginal'" != "" {
		gen _nodeid = _n
		gen _nodeoriginal = `_rawid'
		keep _nodeid _nodeoriginal
		sort _nodeid
		save `dictionaryOriginal', replace
	}
	restore

	// Map raw id's with dictionary
	gen `_rawid' = `fromvar'
	sort `_rawid'
	merge m:1 `_rawid' using `dictionaryConsecutive'
	drop if _merge != 3
	drop _merge
	replace `fromvar' = `_id'
	drop `_id'
	replace `_rawid' = `tovar'
	
	sort `_rawid'
	merge m:1 `_rawid' using `dictionaryConsecutive'
	drop if _merge != 3
	drop _merge
	replace `tovar' = `_id' 
	
	// BUGFIX: if every single row's own ego/alter id was missing, `egen
	// group()' above (which does NOT assign a group to missing values
	// unless told to) leaves `_id' missing for that dictionary entry
	// too, so the merge below still matches (missing-to-missing is a
	// normal equi-join value here, not dropped by `_merge != 3') and
	// `fromvar'/`tovar' end up missing for every row rather than being
	// removed. `sum ... if fromvar != .' then succeeds with rc=0 but
	// r(N)==0/r(max) missing (confirmed directly - it does NOT itself
	// raise an error), so `maxNodes' silently became the LITERAL STRING
	// "." and was later passed as a Mata dimension argument to
	// get_nodenames_from_string()'s own J() call, crashing with a raw
	// "argument out of range" (r3300) instead of a clean message.
	sum `fromvar' if `fromvar' != .
	if r(N) == 0 {
		noisily di "{err}no valid (non-missing) node identifiers found in `fromvar'/`tovar' - nothing to build a network from."
		exit 2000
	}
	local maxNodes = r(max)
	sum `tovar' if `tovar' != .
	if (r(max) != .) {
		if ( r(max) > `maxNodes') {
			local maxNodes = r(max)
		}
	}
	
	capture mata: mata drop __nwvalue
	capture mata: mata drop __nwego
	capture mata: mata drop __nwalter
	capture mata: mata drop __nwrank

	capture confirm variable `_roworder'
	if _rc == 0 {
		putmata __nwrank = `_roworder'
	}
	else {
		mata: __nwrank = J(0, 1, .)
	}
	putmata __nwvalue = `_value'
	putmata __nwego = `fromvar'
	putmata __nwalter = `tovar'
	}

	// Captured BEFORE the defaulting below - only an explicit, caller-
	// chosen name() is held to the create/replace convention (mirrors
	// nwset.ado's own identical fix); the anonymous "network"/`value''-
	// derived default keeps auto-numbering on collision, matching this
	// command's own documented behavior for the unspecified-name case.
	local name_given = ("`name'" != "")

	// Generate valid network name and valid varlist
	if "`name'" == "" & "`value'" == ""{
		local name "network"
	}
	else if "`value'" != "" & "`name'" == ""{
		local name "`value'"
	}

	nwvalidate `name'
	if "`r(exists)'" == "true" & `name_given' {
		if "`replace'" != "" {
			// keep the caller's own requested name, dropping the
			// existing network under it first - same pattern as
			// nwset.ado's own matrix-form guard.
			nwdrop `name'
			local edgename "`name'"
		}
		else {
			// Error-code coherence pass: consolidated onto `errNWsExists'
			// (483, unw_defs.ado) - see nwsimmelian.ado's own fix for the
			// history of this convention's drift onto an undocumented `6099'.
			noi di "{err}Network `name' already exists. Specify option {bf:replace} to overwrite it."
			error `errNWsExists'
		}
	}
	else {
		local edgename = r(validname)
	}

	// SPARSE-BACKEND MIGRATION: this used to build a dense N x N
	// matrix via make_matrix() (a plain J(nodes,nodes,0) allocation,
	// filled cell-by-cell from the very same ego/alter/value triplets
	// already sitting in Mata as `__nwego'/`__nwalter'/`__nwvalue' -
	// see docs/SPARSE_BACKEND.md) and then handed that dense matrix to
	// nwset's own "mat()" ingestion path (create_by_name() + set_edge(),
	// also dense). Since nwfromedge is the most common way real data
	// becomes a network, this was the single largest remaining O(N^2)
	// allocation on the package's ordinary usage path - the dense
	// matrix was never actually needed for anything except satisfying
	// nwset's own dense-only mat() API; the triplet data was already in
	// exactly the shape set_edge_from_triplets() (proven at the
	// 100k-node/1M-edge scale, see docs/SPARSE_BACKEND.md) consumes
	// directly. Constructs the network object directly rather than
	// routing through nwset.ado at all for this step (mirroring the
	// same direct-construction pattern nw2project.ado/nwattime.ado
	// already use), since nwset's own mat() dispatch has no
	// sparse-native equivalent and adding one there is a separate,
	// larger change than this file's own construction step needs.
	// `overwrite' is not forwarded here - grep confirms nwset.ado
	// declares it in its own syntax line but never references it
	// anywhere in the program body, so it was already a no-op at this
	// exact call site before this change; unaffected uses of
	// `overwrite' elsewhere in THIS file (nwload's own output-variable
	// handling, below) are untouched.
	// nwfromedge can legitimately be the very first network-creating
	// call in a session (unlike nw2project.ado/nwattime.ado, which only
	// ever run against an already-existing source network, guaranteeing
	// `nw' already exists). nwset.ado guards this same situation for
	// itself (see its own "capture mata: `nw'" check) - mirror that
	// guard here so a fresh session doesn't hit "type mismatch:
	// transmorphic found where struct expected" from calling .add() on
	// an as-yet-uninitialized `nw'.
	capture mata: `nw'
	if (_rc != 0) {
		mata: `nw' = nws_create()
	}

	tempname __nwnodenames
	// get_nodenames_from_string() returns a column vector; create_by_name_sparse()
	// requires a string rowvector (same transpose nwset.ado applies at its own
	// call site, see its line using __nwnew rows()).
	if `"`labs'"' == "" {
		mata: `__nwnodenames' = (get_nodenames_from_vector(__nwlabvec, `maxNodes', "`cDftNodepref'"))'
		capture mata: mata drop __nwlabvec
	}
	else {
		mata: `__nwnodenames' = (get_nodenames_from_string(`"`labs'"', `maxNodes', "`cDftNodepref'"))'
	}
	mata: `nws'.add("`edgename'")
	// other(other) namespaces _nwsyntax's exported locals as
	// `otherXXX' - this program's own `syntax' line already declares
	// `directed'/`labs' as option locals, and an unprefixed _nwsyntax
	// call would silently clobber them via c_local (confirmed the hard
	// way: the auto-symmetrize block below was always seeing the
	// network's own post-construction `directed' state instead of the
	// user's directed/undirected option, because the plain call used
	// to overwrite it). Same convention nwrecode.ado already uses for
	// exactly this reason.
	_nwsyntax `edgename', other(other)
	mata: `othernetobj'->create_by_name_sparse(`__nwnodenames')
	mata: `othernetobj'->set_name("`edgename'")
	mata: nw_triplets_lastwins(__nwego, __nwalter, __nwvalue, __nwrank)
	// An undirected network from a list that gives each tie once: add the missing reverse direction first, with the
	// tie's own value. Symmetrising afterwards with "max" would compare a negative value with the 0 of the absent
	// direction and keep the 0 (every -1 of a signed network was lost).
	if "`forceundirected'" != "" | "`undirected'" != "" {
		mata: nw_fromedge_mirror(__nwego, __nwalter, __nwvalue)
	}
	mata: `othernetobj'->set_edge_from_triplets(__nwego, __nwalter, __nwvalue, 1)
	// Directed at construction unconditionally, matching nwset's own
	// former default at this exact step (its own mat()-dispatch set
	// directed unless an `undirected' local was forwarded, which this
	// call site never did) - final directedness is still decided
	// afterward by the unchanged auto-symmetrize-detection block below,
	// exactly as it always was.
	mata: `othernetobj'->set_directed(1)
	// isselfloop has no zap()-time default (a fresh NWdef leaves it at
	// Mata's missing-scalar default, not 0), so ensure_dense_built()'s
	// own "if (isselfloop == 0) _diag(e,.)" never fires unless this is
	// set explicitly - nwset.ado's own mat() path always does this via
	// its "set_selfloop("`selfloop'" == "selfloop")" call, defaulting
	// to false since nwset only sets it true when its own `selfloop'
	// option is passed. nwfromedge has no such option, so it should
	// carry the same false default nwset gave it for free before this
	// file routed through nwset at all - without this, get_density()
	// (and any other diagonal-excluding stat) silently include the
	// diagonal, since it was never previously exercised on a bare, not
	// yet ensure_dense_built()'d, network.
	mata: `othernetobj'->set_selfloop(0)

	// Isolate preservation (#5) - see the note near the top of this file.
	// A no-op whenever the edgelist did not come from nwtoedge on a
	// single source network (the local is empty), and add_missing_nodes_
	// from_string() itself skips any label the edgelist already produced
	// a real, tied node for - only genuine isolates from the source
	// network actually get added here.
	if "`__iso_srclabels'" != "" {
		mata: `othernetobj'->add_missing_nodes_from_string(`"`__iso_srclabels'"')
	}

	capture mata: mata drop __nwvalue
	capture mata: mata drop __nwego
	capture mata: mata drop __nwalter
	capture mata: mata drop __nwrank
	capture mata: mata drop `__nwnodenames'

	if "`clear'" == "" {
		qui drop _all
	}
	
	if "`forcedirected'" == "" & "`directed'" == ""{
		nwsym, check 
		if "`r(is_symmetric)'" == "true" {
			nwsym
		}
	}

	if "`forceundirected'" != "" | "`undirected'" != "" {
		nwsym
	}
	
	if "`xvars'" != "" {
		qui nwload, `overwrite'
	}
	else {
		nwload, labelonly `overwrite'
	}
	
	}
end

capture mata: mata drop nw_fromedge_mirror()
capture mata: mata drop nw_fromedge_prep()
mata:
// The node dictionary of nwfromedge done in Mata: the identifiers are mapped to 1, 2, ... in ascending order of their
// value. Returns (ego, alter, value, rank, sorted distinct identifiers) as pointers to column vectors, or an empty
// pointer vector when the route does not apply (then the Stata route runs): a missing identifier, a non-integer
// identifier or one beyond what a float stores exactly (the Stata route keeps the dictionary in a float).
pointer(real colvector) rowvector nw_fromedge_prep(string scalar fromvar, string scalar tovar, string scalar valuevar, string scalar rankvar)
{
	real colvector e, a, x, gid, present, rank, u, ge, ga
	real scalar lo, hi, n

	e = st_data(., fromvar)
	a = st_data(., tovar)
	n = rows(e)
	// a row with a missing identifier goes through the Stata route, which has its own (and not always consistent)
	// way of treating it
	if (hasmissing(e) | hasmissing(a)) return(J(1, 0, NULL))
	x = e \ a
	if (rows(x) == 0) return(J(1, 0, NULL))
	if (any(x :!= trunc(x)) | max(abs(x)) > 16777216) return(J(1, 0, NULL))
	lo = min(x)
	hi = max(x)
	// the identifiers are small integers: a table indexed by the value gives the rank of every value without a
	// sort (a wide, sparse range is left to the Stata route)
	if (hi - lo + 1 > 8 * rows(x) + 2000000) return(J(1, 0, NULL))
	present = J(hi - lo + 1, 1, 0)
	present[x :- lo :+ 1, 1] = J(rows(x), 1, 1)
	u = select((lo::hi), present)
	gid = runningsum(present)
	present = J(0, 1, 0)
	ge = gid[e :- lo :+ 1, 1]
	ga = gid[a :- lo :+ 1, 1]
	if (rankvar != "") rank = st_data(., rankvar)
	else rank = J(0, 1, .)
	return((&ge, &ga, &(st_data(., valuevar)), &rank, &u))
}

// For an undirected network: every tie (i,j) whose reverse (j,i) is not in the list gets the reverse added with the same
// value, so that the later symmetrisation compares two listed values (when both directions are listed with different
// values the larger one is kept, as always) and never a listed value against the "no tie" 0.
void nw_fromedge_mirror(real colvector e, real colvector a, real colvector v)
{
	real colvector off, k1, k2, x, tag, ord, xs, ts, first, pidx, ps, cnt, cntorig, miss, ne, na, nv
	real matrix info
	real scalar n, m

	off = selectindex(e :!= a)
	m = rows(off)
	if (m == 0) return
	n = max((max(e), max(a)))
	k1 = e :* (n + 1) :+ a
	k2 = a[off] :* (n + 1) :+ e[off]
	x = k1 \ k2
	tag = J(rows(k1), 1, 1) \ J(m, 1, 0)
	ord = order(x, 1)
	xs = x[ord]
	ts = tag[ord]
	first = J(rows(xs), 1, 1)
	if (rows(xs) > 1) first[|2 \ rows(xs)|] = (xs[|2 \ rows(xs)|] :!= xs[|1 \ rows(xs)-1|])
	pidx = runningsum(first)
	info = panelsetup(xs, 1)
	ps = panelsum(ts, info)
	cnt = ps[pidx]
	cntorig = J(rows(x), 1, 0)
	cntorig[ord] = cnt
	miss = selectindex(cntorig[|rows(k1)+1 \ rows(x)|] :== 0)
	if (rows(miss) == 0) return
	miss = off[miss]
	ne = a[miss]
	na = e[miss]
	nv = v[miss]
	e = e \ ne
	a = a \ na
	v = v \ nv
}
end
