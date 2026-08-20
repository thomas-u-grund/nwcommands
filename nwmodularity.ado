/***
{smcl}
{* *! version 1.0.0  20aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwmodularity {hline 2} Score an existing node partition using Newman's modularity{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwmodularity}
[{it:{help netlist}}]
{cmd:,}
{opth group(varname)}
[{opt measure(string)}
{opt SYMmetrize}
{opth resolution(real)}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth group(varname)}}Stata variable holding each node's community/group assignment{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opt symmetrize}}Symmetrize a directed network before scoring (required for directed networks){p_end}
{synopt:{opth resolution(real)}}Resolution parameter (Reichardt-Bornholdt); default = 1{p_end}

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
	syntax [anything(name=netname)], GROUP(varname) [measure(string) SYMmetrize resolution(real 1)]
	set more off

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

		mata: st_numscalar("modularity", `netobj'->calculate_modularity(`__nw_group', `resolution'))
		mata: st_numscalar("communities", max(`__nw_group'))
		mata: mata drop `__nw_group'

		return scalar modularity = modularity
		return scalar communities = communities
		local lcomm = communities
		local lmod = modularity

		qui tab `group', matrow(comm_id) matcell(comm_size)
		mata: comm_id = st_matrix("comm_id")
		mata: comm_number = rows(comm_id)
		mata: comm_size = st_matrix("comm_size")
		mata: comm_share = comm_size :/ (sum(comm_size))
		mata: comm_sizeid = J(comm_number, 3, 0)
		mata: comm_sizeid[.,1] = comm_size
		mata: comm_sizeid[.,2] = comm_id
		mata: comm_sizeid[.,3] = comm_share
		mata: comm_sizeid = sort(comm_sizeid, -1)
		mata: st_matrix("comm_sizeid", comm_sizeid)
		mata: st_numscalar("commnum", comm_number)
		matrix colnames comm_sizeid = size compid share

		local rowlabs ""
		forvalues i = 1/`=commnum'{
			local rowlabs "`rowlabs' comm`i'"
		}
		matrix rownames comm_sizeid = `rowlabs'
		return matrix comm_sizeid = comm_sizeid
		mata: mata drop comm_number comm_share comm_id comm_size comm_sizeid

		noi di "{hline 40}"
		noi di "{txt}  Network name: {res}`netname_temp'"
		noi di "{txt}  Communities: {res}`lcomm'"
		noi di "{txt}  Modularity Q: {res}`=round(`lmod',0.001)'"
		noi di " "
		local k = `=`k' + 1'
	}
end
