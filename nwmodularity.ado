/***
{smcl}
{* *! version 1.0.0  20aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_community:[NW-2.6.3] Community Detection}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwmodularity {hline 2}}Score an existing node partition using Newman's modularity{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwmodularity}
[{it:{help netlist}}]
{cmd:,}
{opth group(varname)}
[{opt measure(string)}
{opt SYMmetrize}
{opth resolution(real)}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth group(varname)}}Stata variable holding each node's community/group assignment{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opt symmetrize}}Symmetrize a directed network before scoring (required for directed networks){p_end}
{synopt:{opth resolution(real)}}Resolution parameter (Reichardt-Bornholdt); must be > 0; default = 1{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwmodularity} computes Newman's modularity {it:Q} of the network(s) in {help netlist} against an
{ul:existing} node partition given in {bf:group()} — for example a partition obtained from
{help nwcomponents}, a block model, or any hand-coded grouping variable. Unlike {help nwcommunity},
{cmd:nwmodularity} does not search for a partition; it only scores the one given. All calculations are
performed on the undirected network; directed networks require {bf:symmetrize}.

{pstd}
Modularity compares the fraction of ties that fall within the given groups to the fraction expected
under a random network with the same degree sequence. Values near 0 indicate the grouping is no better
than chance; higher (positive) values indicate a grouping that captures real community structure.
Scoring a single, all-nodes-in-one-group partition always gives {it:Q} = 0, for any network.


{title:Supported network types}

{pstd}
Binary: yes. Directed: requires {opt symmetrize} - modularity as computed here is not defined for a directed network. Weighted: yes, via {opt measure(binary|valued)}; default = {it:valued} for a valued network, {it:binary} otherwise. Signed: not checked. Two-mode: not checked.

{title:Stored results}

	Scalars
	  {bf:r(communities)}		number of distinct groups in {bf:group()}
	  {bf:r(modularity)}		modularity Q of the given partition

	Matrices
	  {bf:r(comm_sizeid)}		distribution over groups


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcomponents flomarriage, generate(comp)}
	{cmd:. nwmodularity flomarriage, group(comp)}


{title:References}

{pstd}
Newman, M.E.J. (2006). Modularity and community structure in networks. {it:PNAS} 103(23), 8577-8582.


{title:See also}

	{help nwcommunity}, {help nwcomponents}

***/

capture program drop nwmodularity
program nwmodularity, rclass
	version 12
	syntax [anything(name=netname)], GROUP(varname) [measure(string) SYMmetrize resolution(real 1) silent]
	set more off

	// resolution() had no input validation - same fix as nwcommunity's
	// own identical option in this same group; see its own comment for
	// the full reasoning.
	if `resolution' <= 0 {
		di "{err}Option {bf:resolution()} must be > 0."
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

		if "`directed'" == "true" & "`symmetrize'" == "" {
			noi di "{err}Modularity not defined for directed networks. Either specify {bf:symmetrize} or symmetrize the network first (see {help nwsym})."
			error 198
		}

		capture assert `group' < .
		if _rc != 0 {
			noi di "{err}Variable {bf:`group'} contains missing values; every node must be assigned to a group."
			error 198
		}

		local val = ("`netmeasure'" == "valued")

		tempname __nw_group
		mata: `__nw_group' = nw_community_denserelabel(st_data((1::`nodes'), "`group'"))

		// BUGFIX: `val' (already computed above from measure()) used to
		// never be forwarded, so calculate_modularity() always scored on
		// the network's raw valued weights regardless of what measure()
		// requested - measure(binary) was a complete no-op.
		mata: st_numscalar("modularity", `netobj'->calculate_modularity(`__nw_group', `val', `resolution'))
		mata: st_numscalar("communities", max(`__nw_group'))
		mata: mata drop `__nw_group'

		return scalar modularity = modularity
		return scalar communities = communities
		local lcomm = communities
		local lmod = modularity

		// same fix as nwcommunity.ado's own identical bug: `tab ...,
		// matrow() matcell()' crashes ("too many values", r134) once
		// there are enough distinct groups, and the later `matrix
		// rownames = `rowlabs'' has the same class of failure one
		// level down (a long enough command-line token list blows
		// Stata's own matsize-driven limit, r915) - both replaced with
		// Mata-native equivalents with no such ceiling. See
		// nwcommunity.ado's own identical fix for the full detail.
		mata: __nwm_vals = st_data((1::`nodes'), "`group'")
		mata: __nwm_sorted = sort(__nwm_vals, 1)
		mata: __nwm_info = panelsetup(__nwm_sorted, 1)
		mata: comm_number = rows(__nwm_info)
		mata: comm_id = __nwm_sorted[__nwm_info[.,1]]
		mata: comm_size = __nwm_info[.,2] :- __nwm_info[.,1] :+ 1
		mata: comm_share = comm_size :/ (sum(comm_size))
		mata: comm_sizeid = J(comm_number, 3, 0)
		mata: comm_sizeid[.,1] = comm_size
		mata: comm_sizeid[.,2] = comm_id
		mata: comm_sizeid[.,3] = comm_share
		mata: comm_sizeid = sort(comm_sizeid, -1)
		mata: st_matrix("comm_sizeid", comm_sizeid)
		mata: st_numscalar("commnum", comm_number)
		matrix colnames comm_sizeid = size compid share

		mata: __nwm_stripe = J(comm_number, 2, "")
		mata: for (__nwm_i=1; __nwm_i<=comm_number; __nwm_i++) __nwm_stripe[__nwm_i,2] = "comm" + strofreal(__nwm_i)
		mata: st_matrixrowstripe("comm_sizeid", __nwm_stripe)
		return matrix comm_sizeid = comm_sizeid
		mata: mata drop comm_number comm_share comm_id comm_size comm_sizeid __nwm_vals __nwm_sorted __nwm_info __nwm_stripe __nwm_i

		// Consistency (moderate-severity pass, community_spectral group):
		// nwmodularity had no `silent' option at all, unlike its closest
		// sibling nwcommunity (same detect/score-and-print-a-summary
		// family) and nwspectral, both of which already support it.
		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Communities: {res}`lcomm'"
			noi di "{txt}  Modularity Q: {res}`=round(`lmod',0.001)'"
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
