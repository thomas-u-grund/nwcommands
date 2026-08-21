/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcoreperiphery {hline 2} Discrete core-periphery detection{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwcoreperiphery}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt measure(string)}
{opth maxiter(int)}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores core membership; default = {it:_core}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opth maxiter(int)}}Maximum number of local-search sweeps before giving up on convergence; default = 100{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwcoreperiphery} partitions the nodes of a network into a "core" and a "periphery" using the
discrete core-periphery model (Borgatti and Everett 1999). The core-periphery model assumes ties are
expected between any pair of nodes where at least one is a core member (core-core and core-periphery
ties are both structurally expected), while periphery-periphery ties are not expected at all.
{cmd:nwcoreperiphery} searches for the 0/1 assignment (0 = periphery, 1 = core) whose implied pattern
correlates as highly as possible with the network actually observed, starting from a degree-based
seed and then repeatedly trying to flip each node's status in turn, keeping any flip that improves
the correlation, until a full sweep produces no further improvement. This is a greedy local search,
not an exhaustive search over all 2^n possible partitions, so it can settle on a good but not
necessarily globally optimal partition - the same character of algorithm {help nwcommunity} already
uses for modularity maximization.

{pstd}
By default, {cmd:nwcoreperiphery} generates a new variable {it:_core} which stores, for each node, 1
if it was assigned to the core and 0 if it was assigned to the periphery.

{pstd}
Always operates on the undirected version of the network (the classical model does not distinguish
incoming from outgoing ties); a directed network is symmetrized automatically, matching
{help nwcommunity}'s own convention - no separate {bf:symmetrize} option is needed or offered.

{title:Stored results}

	Scalars
	  {bf:r(fitness)}		correlation between the observed network and the ideal pattern implied by the found partition (-1 to 1; 1 = a perfect discrete core-periphery structure)
	  {bf:r(core)}		number of nodes assigned to the core

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcoreperiphery flomarriage}


{title:References}

{pstd}
Borgatti, S.P., Everett, M.G. (1999). Models of core/periphery structures. {it:Social Networks}
21(4), 375-395.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (no explicit {bf:symmetrize} option, unlike
{help nwcommunity} - the model itself does not distinguish direction). Weighted:
{opt measure(valued)} uses tie weights directly when computing the fitness correlation;
{opt measure(binary)} uses presence/absence only; default follows the network's own weighted-ness,
matching {help nwcommunity}'s convention. Signed: not checked. Two-mode: not checked - operates on
the network's own square adjacency matrix. A network with no ties at all is rejected explicitly
(there is no structure to fit a core-periphery pattern to); a node with no ties of its own (an
isolate) is handled without error and is simply assigned to the periphery.

{title:See also}

	{help nwconcor}, {help nwcommunity}, {help nwconstraint}

***/

capture program drop nwcoreperiphery
program nwcoreperiphery, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace measure(string) maxiter(int 100) silent]
	set more off

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
			local netgenerate = "_core"
		}

		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`k'} already exists; specify {bf:replace}"
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

		tempname __nw_cp
		capture noisily mata: `__nw_cp' = `netobj'->calculate_coreperiphery(`val', `maxiter')
		if _rc != 0 {
			exit _rc
		}
		mata: st_store((1::`nodes'),"`netgenerate'`k'", `__nw_cp'[1::`nodes',1])
		mata: st_numscalar("cp_fitness", `__nw_cp'[`nodes'+1,1])
		mata: st_numscalar("cp_coresize", sum(`__nw_cp'[1::`nodes',1]))
		mata: mata drop `__nw_cp'

		return scalar fitness = cp_fitness
		return scalar core = cp_coresize
		local lfit = cp_fitness
		local lcore = cp_coresize

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Core size: {res}`lcore'{txt}   Fitness: {res}`=round(`lfit',0.001)'"
			noi tab `netgenerate'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
