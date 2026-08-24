/***
{smcl}
{* *! 5jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 19 22 2}{...}
{p2col :nwfromedge {hline 2}}Imports network data from edgelist{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwfromedge} 
{it:{help varname: fromid}}
{it:{help varname: toid}}
[{it:{help varname:tievalue}}]
[{it:{help if}}]
[{cmd:,}
{opth name(newnetname)}
{opt xvars}
{opt labs}({it:lab1 lab2 ...})
{opt undirected}
{opt directed}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth name(newnetname)}}name of the new network; default = {it:network}{p_end}
{synopt:{opt xvars}}generate Stata variables for the network{p_end}
{synopt:{opt labs}({it:lab1 lab2 ...})}overwrite node labels{p_end}
{synopt:{opt undirected}}force the network to be undirected{p_end}
{synopt:{opt directed}}force the network to be directed{p_end}
{synopt:{opt noclear}}do not clear existing dataset{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwfromedge} imports a network from a dataset in edgelist format. 

{marker edgelist}{...}
{pstd}
An edgelist or arclist is a set of two (or three in the case of a valued network) variables representing
relations. Nodes are identified by entries in the cells.  For example, the data

                 {c TLC}{hline 14}{c -}{c TRC}
                 {c |} {res} fromid  toid {txt}{c |}
                 {c LT}{hline 14}{c -}{c RT}
              1. {c |} {res} 1       2    {txt}{c |}
              2. {c |} {res} 2       3    {txt}{c |}
              3. {c |} {res} 4       2    {txt}{c |}
                 {c BLC}{hline 14}{c -}{c BRC}

{pstd}
stores information about three {it:ties} (1=>2), (2=>3) and (4=>2) among four unique network nodes. The
variables defining the edges can also be {help string} variables. 

                 {c TLC}{hline 25}{c -}{c TRC}
                 {c |} {res} fromid    toid     value{txt}{c |}
                 {c LT}{hline 25}{c -}{c RT}
              1. {c |} {res} Peter     Thomas   1    {txt}{c |}
              2. {c |} {res} Tim       Peter    3    {txt}{c |}
              3. {c |} {res} Mathilde  Thomas   2    {txt}{c |}
                 {c BLC}{hline 25}{c -}{c BRC}

{pstd}
Here, there are also three relationships: (Peter => Thomas), (Tim => Peter) and (Mathilde => Thomas).

{pstd}
The following command declares such data as network data:

	{cmd:. nwfromedge fromid toid value, name(mynet)}
					
{pstd}
This automatically generates the relevant meta-information for the network and makes it available for other programs under the {help netname} {it:mynet}. In case no {bf:name()}
is specified, the command tries to come up with a suitable name for the new network. By default, it tries {it:network}, however, if a network with this name already exists, it comes
up with an alternative name {it:network_1} and so on (see {help nwvalidate}).

{pstd}
After a network has been declared, one can refer to it by its {help netname}, just as if one would refer to a {help varname}. For example, this {help nwplot:makes a network plot} of {it:mynet}.

	{cmd:. nwplot mynet}

{pstd}
Or alternatively, this calculates the {help nwbetween:betweenness centrality} of the nodes in {it:mynet}.

	{cmd:. nwbetween mynet}			
			 
{pstd}
By default, {bf:nwfromedge} recognizes if a network is directed or undirected, i.e. for each 
dyad entry (i,j) there is also a dyad entry (j,i). However, this automatic detection
can be overwritten with the options {opt undirected} and {opt directed}.

{pstd}
One can also transfrom any network that exists in memory into such an edgelist with {help nwtoedge}.


{title:Examples}

{pstd}
This loads a network dataset from the internet and transforms the network {it:glasgow1} into an edgelist.

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwtoedge glasgow1}

{pstd}
Afterwards, it can be loaded as a network object again:

	{cmd:. nwfromedge _fromid _toid _link, name(mynet)}

	
	
{title:Also see}
	
	{help nwtoedge}, {help nwuse}, {help nwsave}, {help nwwebuse}, {help nwset}, {help nwimport}, {help nw2fromedge}

***/

capture program drop nwfromedge
program nwfromedge
	syntax varlist(min=2 max=3) [if] [, overwrite REPLACE prefix(string) noclear xvars name(string) labs(string asis) directed undirected forcedirected forceundirected ]
	unw_defs
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
		gen `_value' = `value'
		_extract_valuelabels `value'
		local edgelabs "`r(valuelabels)'"
	}
	else {
		gen `_value' = 1
	}
	
	// check for string variables
	capture confirm string variable `fromvar' `tovar'
	local fromStrings = 0
	tempfile dictionaryString
	
	// if condition
	if "`if'" != ""{ 
		keep `if'
	}
	
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
		list _all
		
		sort `_nodeid'
		keep if `_nodeid' != `_nodeid'[_n-1]
		list _all
		
		if "`labs'" == "" {
			forvalues k = 1/ `=_N'{
				local labs "`labs' `=`fromvar'[`k']',"
			}
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

	local prefix "n"
	if "`rawtype'" == "numeric" {
		if "`labs'" == "" {
			forvalues k = 1/ `=_N'{
				local labs "`labs' `prefix'`=`_rawid'[`k']',"
			}
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
	
	sum `fromvar' if `fromvar' != .
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

	putmata __nwvalue = `_value'
	putmata __nwego = `fromvar'
	putmata __nwalter = `tovar'

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
			di "{err}Network `name' already exists. Specify option {bf:replace} to overwrite it."
			error 6099
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
	mata: `__nwnodenames' = (get_nodenames_from_string(`"`labs'"', `maxNodes', "`cDftNodepref'"))'
	mata: `nws'.add("`edgename'")
	// other(other) namespaces nw_syntax's exported locals as
	// `otherXXX' - this program's own `syntax' line already declares
	// `directed'/`labs' as option locals, and an unprefixed nw_syntax
	// call would silently clobber them via c_local (confirmed the hard
	// way: the auto-symmetrize block below was always seeing the
	// network's own post-construction `directed' state instead of the
	// user's directed/undirected option, because the plain call used
	// to overwrite it). Same convention nwrecode.ado already uses for
	// exactly this reason.
	nw_syntax `edgename', other(other)
	mata: `othernetobj'->create_by_name_sparse(`__nwnodenames')
	mata: `othernetobj'->set_name("`edgename'")
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

	capture mata: mata drop __nwvalue
	capture mata: mata drop __nwego
	capture mata: mata drop __nwalter
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
