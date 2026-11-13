
capture program drop nwfromedge
program nwfromedge
	syntax varlist(min=2 max=3) [if] [, overwrite REPLACE labprefix(string) noclear xvars name(string) labs(string asis) directed undirected forcedirected forceundirected twomode valued unvalued keeporiginal selfloop]

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
	if `"`name'"' != "" mata: nw_assert_netname(st_local("name"))
	if "`twomode'" != "" {
		if "`directed'" != "" | "`undirected'" != "" | "`forcedirected'" != "" | "`forceundirected'" != "" {
			di "{err}{p 0 0 2}option {bf:twomode} declares an inherently undirected two-mode network - it cannot be combined with {bf:directed}/{bf:undirected}/{bf:forcedirected}/{bf:forceundirected}.{p_end}"
			error 198
		}
		nw2fromedge `varlist' `if', name(`name') `xvars' `replace'
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
	// labs() may list the labels separated by blanks (lab1 lab2 ...) or by
	// commas; with commas a label may contain blanks
	if `"`labs'"' != "" & strpos(`"`labs'"', ",") == 0 {
		local __nwfe_l ""
		foreach __nwfe_w of local labs {
			local __nwfe_l `"`__nwfe_l',`__nwfe_w'"'
		}
		local labs = substr(`"`__nwfe_l'"', 2, .)
	}
	if "`keeporiginal'" != "" & "`clear'" != "" {
		capture confirm new variable _nodeoriginal
		if _rc {
			di "{err}variable {bf:_nodeoriginal} already defined; option {bf:keeporiginal} creates it"
			exit 110
		}
	}
	tempname __nwfe_orig
	// a name() already in use is refused before the data are changed (the string-id route below stacks and drops
	// the data first; the user's edge list must survive the error)
	if "`name'" != "" & "`replace'" == "" {
		qui nwvalidate `name'
		if "`r(exists)'" == "true" {
			noi di "{err}{p 0 0 2}Network `name' already exists. Specify option {bf:replace} to overwrite it.{p_end}"
			error `errNWsExists'
		}
	}
	// noclear: the edge list is worked on in place below (ids replaced,
	// rows dropped); keep the user's data and bring them back afterwards
	if "`clear'" != "" {
		tempfile __nwfe_userdata
		qui save `"`__nwfe_userdata'"'
	}
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
			qui gen `x' = cond(missing(`fromvar'), "", strofreal(`fromvar', "%18.0g"))
			local fromvar `x'
		}
	}
	else {
		capture confirm numeric variable `tovar'
		if _rc == 0 {
			tempvar x
			qui gen `x' = cond(missing(`tovar'), "", strofreal(`tovar', "%18.0g"))
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
		keep if `_nodeid' != `_nodeid'[_n-1] & !missing(`_nodeid')
		
		// Node labels travel through Mata, never through a macro: a macro
		// of 100,000 labels overflows Stata/BE's 264,408-character limit
		// (r(920)), and building it cost O(n^2).
		if "`labs'" == "" {
			capture mata: mata drop __nwlabvec
			putmata __nwlabvec = `fromvar'
		}
		if "`keeporiginal'" != "" {
			putmata `__nwfe_orig' = `fromvar', replace
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
		// a pair listed more than once: the last row counts, as with numeric ids
		bysort `fromvar' `tovar' (`_roworder'): keep if _n == _N
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
			if "`rawtype'" == "numeric" & "`keeporiginal'" != "" {
				mata: `__nwfe_orig' = *__nwP[5]
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
	// A missing identifier is not a node. A row with one identifier missing ("Fion" and "", or 5 and .) declares
	// the other one as a node without a tie from that row (the way to keep isolates in an edge list): the node is
	// in the dictionary through its stacked value, and the row itself is dropped by the merges below (no match).
	// Up to 3.18.0 the missing value had its own dictionary entry, the row became a tie with a missing end, and
	// the stored tie count was one too high (r(3200) in nwtomata for numeric identifiers).
	drop if missing(`_id')
	local __fe_nnodes = _N
	// every identifier missing: nothing to build (a clean error instead of a Mata error further down)
	if `__fe_nnodes' == 0 {
		noisily di "{err}{p 0 0 2}no valid (non-missing) node identifiers found in `fromvar'/`tovar' - nothing to build a network from.{p_end}"
		exit 2000
	}
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
		if "`keeporiginal'" != "" {
			putmata `__nwfe_orig' = `_rawid', replace
		}
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
	
	// The number of nodes is the size of the dictionary, not the largest id in a tie: a node from an isolate
	// row (see above) may have no tie at all.
	local maxNodes = `__fe_nnodes'
	
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
			noi di "{err}{p 0 0 2}Network `name' already exists. Specify option {bf:replace} to overwrite it.{p_end}"
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
		mata: `__nwnodenames' = nwfromedge_padlabs(`__nwnodenames', sum(tokens(`"`labs'"', ",") :!= ","), "`cDftNodepref'")
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
	// selfloop: the flag must be set before the ties are stored, or the diagonal is dropped
	if "`selfloop'" != "" mata: `othernetobj'->set_selfloop(1)
	mata: `othernetobj'->set_edge_from_triplets(__nwego, __nwalter, __nwvalue, 1)
	// The valued flag is set here, when the network is created: a value variable (third variable) makes
	// the network valued, even if every value is 1; without one it is binary.  valued / unvalued override.
	local __nwfe_val = (wordcount("`varlist'") == 3 | "`valued'" != "") & "`unvalued'" == ""
	mata: `othernetobj'->set_valued(`__nwfe_val')
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
	mata: `othernetobj'->set_selfloop("`selfloop'" != "")

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
	else {
		qui use `"`__nwfe_userdata'"', clear
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

	// keeporiginal: the original id of each node, on the node's row
	if "`keeporiginal'" != "" {
		mata: nw_fromedge_orig("`nw_nodename'", `othernetobj'->get_nodenames(), `__nwfe_orig')
		mata: mata drop `__nwfe_orig'
	}
	
	}
end

capture mata: mata drop nw_fromedge_mirror()
capture mata: mata drop nw_fromedge_orig()
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
void nw_fromedge_orig(string scalar labvar, string rowvector nm, transmorphic colvector orig)
{
	transmorphic A
	string colvector lab
	real colvector pos
	real scalar i, vi, w

	A = asarray_create()
	for (i = 1; i <= min((cols(nm), rows(orig))); i++) asarray(A, nm[i], i)
	lab = st_sdata(., labvar)
	pos = J(rows(lab), 1, 0)
	for (i = 1; i <= rows(lab); i++) {
		if (lab[i] != "") {
			if (asarray_contains(A, lab[i])) pos[i] = asarray(A, lab[i])
		}
	}
	if (isstring(orig)) {
		w = max((1, max(strlen(orig))))
		vi = st_addvar(w > 2045 ? "strL" : "str" + strofreal(w), "_nodeoriginal")
		for (i = 1; i <= rows(lab); i++) if (pos[i]) st_sstore(i, vi, orig[pos[i]])
	}
	else {
		vi = st_addvar("double", "_nodeoriginal")
		for (i = 1; i <= rows(lab); i++) if (pos[i]) st_store(i, vi, orig[pos[i]])
	}
}

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

capture mata: mata drop nwfromedge_padlabs()
mata:
// fewer labels than nodes: the nodes without a label get default names
// (def + position) that are not already used; a name that is used is
// replaced by the next unused def + number above the number of nodes
string rowvector nwfromedge_padlabs(string rowvector l, real scalar k, string scalar def)
{
	transmorphic A
	real scalar i, j, z

	z = cols(l)
	if (k >= z | k < 1) return(l)
	A = asarray_create()
	for (i = 1; i <= k; i++) asarray(A, l[i], 1)
	j = z
	for (i = k + 1; i <= z; i++) {
		if (asarray_contains(A, l[i])) {
			do {
				j++
			} while (asarray_contains(A, def + strofreal(j)))
			l[i] = def + strofreal(j)
		}
		asarray(A, l[i], 1)
	}
	return(l)
}
end
