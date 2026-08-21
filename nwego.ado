/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwego {hline 2} Ego-network size and density{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwego}
[{it:{help netlist}}]
[{cmd:,}
{opth sizevar(newvarname)}
{opth densvar(newvarname)}
{opt replace}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth sizevar(newvarname)}}Name of the Stata variable that stores ego-network size; default = {it:_egosize}{p_end}
{synopt:{opth densvar(newvarname)}}Name of the Stata variable that stores ego-network density; default = {it:_egodensity}{p_end}
{synopt:{opt replace}}Replace existing variables{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwego} calculates, for every node, the size and density of its ego network. A node's alters are
every other node it has any tie with - for a directed network, the union of its incoming and
outgoing ties (the standard "who is in ego's network at all" question; this is distinct from
{help nwaltergen}'s own alter-aggregation convention, which deliberately keeps incoming and outgoing
ties separate for a different purpose).

{pstd}
{bf:Ego-network size} is simply the number of alters (equivalent to {help nwdegree} for an
undirected network; for a directed network it is the count of {it:distinct} nodes tied in either
direction, not the sum of in- and out-degree, which could double-count a reciprocated tie).

{pstd}
{bf:Ego-network density} is the proportion of possible ties actually present {it:among the alters
themselves} - ego itself is excluded, the standard convention for reporting how interconnected an
ego's contacts are with each other, independent of their (by definition, complete) ties to ego. For
a directed network, ordered alter-alter pairs are counted (an alter set of size {it:k} has
{it:k(k-1)} possible ties); for an undirected network, unordered pairs are counted ({it:k(k-1)/2}
possible ties). An ego with fewer than 2 alters has no pair to assess - density is reported missing
for it, not spuriously 0 or 1.

{pstd}
By default, {cmd:nwego} generates {it:_egosize} and {it:_egodensity}.

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwego flomarriage}


{title:References}

{pstd}
Burt, R.S. (1992). {it:Structural Holes: The Social Structure of Competition}. Harvard University
Press. (ego-network density as used in structural holes analysis - see also {help nwconstraint},
{help nwburt})


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - alters are the union of in- and out-neighbors; alter-alter density
counts ordered pairs. Weighted: not used - only presence/absence of a tie determines ego-network
membership and alter-alter density; tie strength does not affect these measures. Signed: not
checked. Two-mode: not checked - operates on the network's own square adjacency matrix.

{title:See also}

	{help nwdegree}, {help nwaltergen}, {help nwconstraint}, {help nwburt}

***/

capture program drop nwego
program nwego, rclass
	version 12
	syntax [anything(name=netname)][, sizevar(string) densvar(string) replace silent]
	set more off

	nw_syntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		nw_syntax `netname_temp'

		local netsizevar "`sizevar'"
		if "`netsizevar'" == "" {
			local netsizevar = "_egosize"
		}
		local netdensvar "`densvar'"
		if "`netdensvar'" == "" {
			local netdensvar = "_egodensity"
		}

		capture confirm variable `netsizevar'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netsizevar'`k'} already exists; specify {bf:replace}"
			err 99
		}
		capture confirm variable `netdensvar'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netdensvar'`k'} already exists; specify {bf:replace}"
			err 99
		}

		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		nw_syntax `netname_temp'

		tempname __nw_ego
		mata: `__nw_ego' = `netobj'->calculate_egostats()
		capture drop `netsizevar'`k'
		gen `netsizevar'`k' = .
		capture drop `netdensvar'`k'
		gen `netdensvar'`k' = .
		mata: st_store((1::`nodes'), "`netsizevar'`k'", `__nw_ego'[.,1])
		mata: st_store((1::`nodes'), "`netdensvar'`k'", `__nw_ego'[.,2])
		mata: mata drop `__nw_ego'

		// see nwbrokerage.ado's own header comment: the "already
		// exists" probes above leave _rc stale even after a fully
		// successful run - reset explicitly and silently.
		capture confirm variable `netsizevar'`k', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi sum `netsizevar'`k' `netdensvar'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
