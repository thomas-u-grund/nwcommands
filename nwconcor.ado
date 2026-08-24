/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwconcor {hline 2}}CONCOR structural-equivalence blockmodel{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwconcor}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opth splits(int)}
{opt measure(string)}
{opth maxiter(int)}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores block membership; default = {it:_concor}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opth splits(int)}}Number of recursive bisections; final number of blocks is up to 2^{it:splits}; default = 1{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opth maxiter(int)}}Maximum number of correlation iterations per split before giving up on convergence; default = 25{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwconcor} partitions the nodes of a network into structurally equivalent blocks using CONCOR
(CONvergence of iterated CORrelations - Breiger, Boorman and Arabie 1975). Each node's tie profile
(its outgoing ties stacked on its incoming ties, excluding the tie to itself) is correlated against
every other node's profile; this correlation matrix is then repeatedly re-correlated with itself.
For well-separated block structure this process converges to a matrix of exactly +1/-1 entries, from
which nodes are split into two groups based on the sign of their correlation with a reference node.
Unlike methods that require an undirected network (e.g. {help nwcommunity}), CONCOR is defined
directly for directed data, since a node's profile already keeps its outgoing and incoming ties
separate.

{pstd}
With {opt splits(1)} (the default) {cmd:nwconcor} performs a single bisection, producing 2 blocks.
With {opt splits(k)}, each resulting block from the previous level is independently re-split using
only the ties among its own members, producing up to 2^{it:k} blocks in total - this is the
classical recursive CONCOR procedure, not merely applying a single bisection {it:k} times to the
whole network. A block that cannot be split further (all of its members end up on the same side of
its own bisection, or all of its members only tie to nodes {it:outside} the block, leaving no
internal structure to split on) simply stays as one block rather than being forced apart -
{cmd:nwconcor} may therefore return fewer than 2^{it:splits} blocks; {bf:r(blocks)} always reports
the actual number found.

{pstd}
By default, {cmd:nwconcor} generates a new variable {it:_concor} which stores, for each node, the id
of the block it was assigned to.

{pstd}
A node with no ties at all (in any direction) has no tie profile to compare against anyone else's,
so {cmd:nwconcor} requires every node to have at least one tie; remove isolates first (see
{help nwdropnodes}) if your network has any.

{title:Stored results}

	Scalars
	  {bf:r(blocks)}		number of blocks actually found (up to 2^{it:splits})

	Matrices
	  {bf:r(block_sizeid)}		distribution over blocks

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. * pucci is an isolate in this network - CONCOR requires every node to have a tie}
	{cmd:. nwdropnodes flomarriage, nodes(pucci) generate(flomarriage2)}
	{cmd:. nwconcor flomarriage2}

	{cmd:. nwconcor flomarriage2, splits(2) replace}


{title:References}

{pstd}
Breiger, R.L., Boorman, S.A., Arabie, P. (1975). An algorithm for clustering relational data with
applications to social network analysis and comparison with multidimensional scaling. {it:Journal of
Mathematical Psychology} 12(3), 328-383.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - CONCOR is defined directly for directed data (a node's profile stacks
its outgoing and incoming ties separately), unlike {help nwcommunity}, which requires
{bf:symmetrize} for a directed network. Weighted: {opt measure(valued)} uses tie weights directly in
the profile; {opt measure(binary)} uses presence/absence only; default follows the network's own
weighted-ness, matching {help nwcommunity}'s convention. Signed: not checked - a negative tie
weight participates in the profile and correlation arithmetic like any other value, but no dedicated
signed-network semantics exist. Two-mode: not checked - operates on the network's own square
adjacency matrix. Isolates (nodes with no tie in any direction) are rejected explicitly with a clear
error, not silently mishandled - see Description.

{title:See also}

	{help nwsimilar}, {help nwdissimilar}, {help nwhierarchy}, {help nwcommunity}

***/

capture program drop nwconcor
program nwconcor, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace SPLITs(int 1) measure(string) maxiter(int 25) silent]
	set more off

	if `splits' < 1 {
		di "{err}splits() must be a positive integer."
		error 198
	}
	if `maxiter' < 1 {
		di "{err}maxiter() must be a positive integer."
		error 198
	}

	nw_syntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		nw_syntax `netname_temp'

		local netmeasure "`measure'"
		if "`netmeasure'" == "" {
			if "`valued'" == "true" {
				local netmeasure "valued"
			}
			else {
				local netmeasure "binary"
			}
		}
		_opts_oneof "binary valued" "measure" "`netmeasure'" 6556

		local netgenerate "`generate'"
		if "`netgenerate'" == "" {
			local netgenerate = "_concor"
		}

		// Checks the exact suffixed name this iteration is about to
		// create, not the bare stem - Stata's own variable-name
		// abbreviation would otherwise let `confirm variable _concor'
		// match an already-existing `_concor1' on a later netlist
		// iteration (there being no other variable starting "_concor"
		// to make it ambiguous), falsely blocking that iteration even
		// though its own target name is still free.
		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`k'} already exists; specify {bf:replace}"
			err 99
		}

		local val = ("`netmeasure'" == "valued")

		// BUGFIX: `gen netgenerate = .' used to run here, BEFORE the
		// calculate_concor() call below that can fail (e.g. the isolates
		// check inside it) - so a failure left a stale, all-missing
		// output variable behind, which then falsely tripped the
		// "already exists; specify replace" collision guard above on any
		// retry, masking the real, original error entirely (exactly what
		// the alpha audit's own repro hit: the doc's own second example
		// line reported a misleading "already exists" error instead of
		// the real isolates problem the first line had already failed
		// on). `capture drop' (clearing out only a genuinely stale
		// variable from an unrelated earlier call) is still safe to run
		// here unconditionally - it does not itself create anything -
		// but the actual `gen' is deferred until after calculate_concor()
		// has succeeded, so a failed call never leaves anything behind to
		// block a retry. (`capture drop' is deliberately kept in its
		// original position, before the calculate_concor() call below,
		// rather than after it: _rc is not reset by ordinary successful
		// commands in Stata, only by another capture or a genuine error -
		// so moving it after would leave the harmless "variable not
		// found" 111 from this drop as the last thing to touch _rc even
		// on a fully successful call, corrupting _rc for any caller.)
		capture drop `netgenerate'`k'

		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		nw_syntax `netname_temp'

		tempname __nw_concor
		capture noisily mata: `__nw_concor' = `netobj'->calculate_concor(`splits', `val', `maxiter')
		if _rc != 0 {
			exit _rc
		}
		gen `netgenerate'`k' = .
		mata: st_store((1::`nodes'),"`netgenerate'`k'", `__nw_concor')
		mata: mata drop `__nw_concor'

		qui tab `netgenerate'`k', matrow(block_id) matcell(block_size)

		mata: block_id = st_matrix("block_id")
		mata: block_number = rows(block_id)
		mata: block_size = st_matrix("block_size")
		mata: block_share = block_size :/ (sum(block_size))
		mata: block_sizeid = J(block_number, 3, 0)
		mata: block_sizeid[.,1] = block_size
		mata: block_sizeid[.,2] = block_id
		mata: block_sizeid[.,3] = block_share
		mata: block_sizeid = sort(block_sizeid, -1)
		mata: st_numscalar("blocks", block_number)
		mata: st_matrix("block_sizeid", block_sizeid)

		matrix colnames block_sizeid = size blockid share

		return scalar blocks = blocks
		local lblocks = blocks

		local rowlabs ""
		forvalues i = 1/`=blocks'{
			local rowlabs "`rowlabs' block`i'"
		}
		matrix rownames block_sizeid = `rowlabs'
		return matrix block_sizeid = block_sizeid
		mata: mata drop block_number block_share block_id block_size block_sizeid

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Splits: {res}`splits'{txt}   Blocks found: {res}`lblocks'"
			noi tab `netgenerate'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
