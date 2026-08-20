/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwkcore {hline 2} k-core decomposition}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwkcore}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt silent}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's coreness; default = {it:_kcore}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwkcore} computes the k-core decomposition (Seidman 1983) of a network or a list of networks. A
node's {it:coreness} is the largest {it:k} such that the node belongs to a {it:k-core}: a maximal
subgraph in which every node has degree at least {it:k} within that subgraph. Nodes with high
coreness sit in the network's densely interconnected "core"; nodes with low coreness (e.g. degree-1
pendants) sit on the periphery. Coreness is a common building block for identifying cohesive
subgroups and for network visualization (e.g. sizing/coloring nodes by coreness, or restricting a
plot to the k-core for some threshold {it:k}).

{pstd}
All calculations are performed on the undirected version of the network: for directed networks, a
node's neighbor set is the union of its out- and in-neighbors, matching how {help nwcomponents}
treats directed networks for the same kind of undirected-sense structural question.

{pstd}
By default, {cmd:nwkcore} generates a new variable {it:_kcore} which stores each node's coreness.

{title:Stored results}

	Scalars
	  {bf:r(maxcore)}		maximum coreness found (the network's degeneracy)

	Matrices
	  {bf:r(core_sizeid)}		distribution over coreness levels


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwkcore flomarriage}
	{cmd:. tab _kcore}


{title:References}

{pstd}
Seidman, S.B. (1983). Network structure and minimum degree. {it:Social Networks} 5(3), 269-287.

{pstd}
Batagelj, V., Zaversnik, M. (2003). An O(m) Algorithm for Cores Decomposition of Networks.
arXiv:cs/0310049.

{title:See also}

	{help nwcomponents}, {help nwcommunity}, {help nwdegree}

***/

capture program drop nwkcore
program nwkcore, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace silent]
	set more off

	nw_syntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		nw_syntax `netname_temp'

		local netgenerate "`generate'"
		if "`netgenerate'" == "" {
			local netgenerate = "_kcore"
		}

		capture confirm variable `netgenerate'
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'} already exists; specify {bf:replace}"
			err 99
		}

		capture drop `netgenerate'`k'
		gen `netgenerate'`k' = .
		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		nw_syntax `netname_temp'

		tempname __nw_core
		mata: `__nw_core' = `netobj'->calculate_kcore()
		mata: st_store((1::`nodes'),"`netgenerate'`k'", `__nw_core')
		mata: st_numscalar("maxcore", max(`__nw_core'))
		mata: mata drop `__nw_core'

		qui tab `netgenerate'`k', matrow(core_id) matcell(core_size)

		mata: core_id = st_matrix("core_id")
		mata: core_number = rows(core_id)
		mata: core_size = st_matrix("core_size")
		mata: core_share = core_size :/ (sum(core_size))
		mata: core_sizeid = J(core_number, 3, 0)
		mata: core_sizeid[.,1] = core_size
		mata: core_sizeid[.,2] = core_id
		mata: core_sizeid[.,3] = core_share
		mata: core_sizeid = sort(core_sizeid, -1)
		mata: st_matrix("core_sizeid", core_sizeid)
		mata: st_numscalar("corelevels", core_number)

		matrix colnames core_sizeid = size coreid share

		return scalar maxcore = maxcore
		local lmax = maxcore
		local lcorelevels = corelevels

		local rowlabs ""
		forvalues i = 1/`lcorelevels'{
			local rowlabs "`rowlabs' core`i'"
		}
		matrix rownames core_sizeid = `rowlabs'
		return matrix core_sizeid = core_sizeid
		mata: mata drop core_number core_share core_id core_size core_sizeid

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Max coreness (degeneracy): {res}`lmax'"
			noi tab `netgenerate'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
