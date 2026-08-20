/***
{smcl}
{* *! version 1.0.0  20aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcommunity {hline 2} Detect communities via the Louvain method{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwcommunity}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt measure(string)}
{opt SYMmetrize}
{opth resolution(real)}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores community membership; default = {it:_community}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opt symmetrize}}Symmetrize a directed network before detecting communities (required for directed networks){p_end}
{synopt:{opth resolution(real)}}Resolution parameter (Reichardt-Bornholdt); default = 1{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwcommunity} detects communities in the network(s) in {help netlist} using the Louvain method (Blondel et al 2008),
a greedy algorithm that repeatedly moves nodes between communities and aggregates communities into a coarser
network, in order to maximize Newman's modularity {it:Q}. All calculations are performed on the undirected
network; directed networks require {bf:symmetrize}.

{pstd}
By default, {cmd:nwcommunity} generates a new variable {it:_community} which stores, for each node, the
id of the community it was assigned to.

{title:Stored results}

	Scalars
	  {bf:r(communities)}		number of communities
	  {bf:r(modularity)}		modularity Q of the detected partition

	Matrices
	  {bf:r(comm_sizeid)}		distribution over communities


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcommunity flomarriage}


{title:References}

{pstd}
Blondel, V.D., Guillaume, J.-L., Lambiotte, R., Lefebvre, E. (2008). Fast unfolding of communities in
large networks. {it:Journal of Statistical Mechanics: Theory and Experiment}, 2008(10), P10008.

{pstd}
Newman, M.E.J. (2006). Modularity and community structure in networks. {it:PNAS} 103(23), 8577-8582.


{title:See also}

	{help nwmodularity}, {help nwcomponents}, {help nwclustering}

***/

capture program drop nwcommunity
program nwcommunity, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace measure(string) SYMmetrize resolution(real 1) silent]
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
			noi di "{err}Community detection not defined for directed networks. Either specify {bf:symmetrize} or symmetrize the network first (see {help nwsym})."
			error 198
		}

		local netgenerate "`generate'"
		if "`netgenerate'" == "" {
			local netgenerate = "_community"
		}

		capture confirm variable `netgenerate'
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'} already exists; specify {bf:replace}"
			err 99
		}

		local val = ("`netmeasure'" == "valued")

		capture drop `netgenerate'`k'
		gen `netgenerate'`k' = .
		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		nw_syntax `netname_temp'

		tempname __nw_comm
		mata: `__nw_comm' = `netobj'->detect_communities_louvain(`val', `resolution')
		mata: st_store((1::`nodes'),"`netgenerate'`k'", `__nw_comm')
		mata: st_numscalar("modularity", `netobj'->calculate_modularity(`__nw_comm', `resolution'))
		mata: mata drop `__nw_comm'

		qui tab `netgenerate'`k', matrow(comm_id) matcell(comm_size)

		mata: comm_id = st_matrix("comm_id")
		mata: comm_number = rows(comm_id)
		mata: comm_size = st_matrix("comm_size")
		mata: comm_share = comm_size :/ (sum(comm_size))
		mata: comm_sizeid = J(comm_number, 3, 0)
		mata: comm_sizeid[.,1] = comm_size
		mata: comm_sizeid[.,2] = comm_id
		mata: comm_sizeid[.,3] = comm_share
		mata: comm_sizeid = sort(comm_sizeid, -1)
		mata: st_numscalar("communities", comm_number)
		mata: st_matrix("comm_sizeid", comm_sizeid)

		matrix colnames comm_sizeid = size compid share

		return scalar modularity = modularity
		return scalar communities = communities
		local lcomm = communities
		local lmod = modularity

		local rowlabs ""
		forvalues i = 1/`=communities'{
			local rowlabs "`rowlabs' comm`i'"
		}
		matrix rownames comm_sizeid = `rowlabs'
		return matrix comm_sizeid = comm_sizeid
		mata: mata drop comm_number comm_share comm_id comm_size comm_sizeid

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Communities: {res}`lcomm'"
			noi di "{txt}  Modularity Q: {res}`=round(`lmod',0.001)'"
			noi tab `netgenerate'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
