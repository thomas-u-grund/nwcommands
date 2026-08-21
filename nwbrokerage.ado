/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwbrokerage {hline 2} Gould-Fernandez brokerage roles{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwbrokerage}
[{it:{help netlist}}]
{cmd:,}
{opth group(varname)}
[{opth generate(newvarname)}
{opt replace}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth group(varname)}}Existing Stata variable holding each node's group membership (required){p_end}
{synopt:{opth generate(newvarname)}}Stem for the 5 new Stata variables that store role counts; default = {it:_broker}{p_end}
{synopt:{opt replace}}Replace existing variables{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwbrokerage} counts, for every node {it:b}, how often it plays each of the five brokerage
roles defined by Gould and Fernandez (1989). For every directed two-path {it:a -> b -> c} (with
{it:a} != {it:c}) through {it:b}, the role is determined by comparing the group membership of
{it:a}, {it:b} and {it:c} (from {opt group()}):

	{col 4}{bf:coordinator}{col 20}{it:a}, {it:b} and {it:c} all in the same group
	{col 4}{bf:gatekeeper}{col 20}{it:a} in a different group from {it:b}; {it:c} in the same group as {it:b}
	{col 4}{bf:representative}{col 20}{it:a} in the same group as {it:b}; {it:c} in a different group
	{col 4}{bf:consultant}{col 20}{it:a} and {it:c} in the same group, different from {it:b}'s
	{col 4}{bf:liaison}{col 20}{it:a}, {it:b} and {it:c} all in different groups

{pstd}
Five new Stata variables are generated, one per role, each holding node {it:b}'s count of that
role (e.g. the default {opt generate(_broker)} produces {it:_broker_coordinator},
{it:_broker_gatekeeper}, {it:_broker_representative}, {it:_broker_consultant} and
{it:_broker_liaison}).

{pstd}
For a directed network, {it:a} ranges over {it:b}'s incoming ties and {it:c} over its outgoing
ties - brokerage is fundamentally about {it:a} reaching {it:c} {it:through} {it:b}. For an
undirected network, incoming and outgoing ties are identical, so {it:a} and {it:c} both range over
{it:b}'s (undirected) neighbors - the same five-role classification still applies, just without the
directional distinction a directed network provides.

{title:Stored results}

	Scalars
	  {bf:r(pairs)}		total number of a-b-c two-paths counted, summed across all nodes and all five roles

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. gen faction = mod(_n, 2)}
	{cmd:. nwbrokerage flomarriage, group(faction)}


{title:References}

{pstd}
Gould, R.V., Fernandez, R.M. (1989). Structures of mediation: A formal approach to brokerage in
transaction networks. {it:Sociological Methodology} 19, 89-126.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, and directionality is used directly (see Description) - this is the
network type the model was originally defined for. Undirected networks are supported too, with the
directional distinction collapsing away as described above. Weighted: not used - only the
presence/absence of a tie determines whether a two-path exists; tie strength does not affect role
counts. Signed: not checked. Two-mode: not checked - operates on the network's own square adjacency
matrix. {opt group()} must be an existing Stata variable already aligned with the network's nodes
(the same convention {help nwmodularity}'s own {opt group()} option uses) - {cmd:nwbrokerage} does
not detect groups itself; pair it with {help nwconcor}, {help nwcoreperiphery}, {help nwcommunity},
or a substantive attribute for the grouping.

{title:See also}

	{help nwconcor}, {help nwcoreperiphery}, {help nwcommunity}, {help nwmodularity}

***/

capture program drop nwbrokerage
program nwbrokerage, rclass
	version 12
	syntax [anything(name=netname)], GROUP(varname) [GENerate(string) replace silent]

	nw_syntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	local roles coordinator gatekeeper representative consultant liaison

	qui foreach netname_temp in `netname' {
		nw_syntax `netname_temp'

		local netgenerate "`generate'"
		if "`netgenerate'" == "" {
			local netgenerate = "_broker"
		}

		foreach role of local roles {
			capture confirm variable `netgenerate'_`role'`k', exact
			if _rc == 0 & "`replace'" == "" {
				noi di "{err}Variable {bf:`netgenerate'_`role'`k'} already exists; specify {bf:replace}"
				err 99
			}
		}

		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		nw_syntax `netname_temp'

		tempname __nw_grp __nw_brk
		mata: `__nw_grp' = st_data((1::`nodes'), "`group'")
		capture noisily mata: `__nw_brk' = `netobj'->calculate_brokerage(`__nw_grp')
		if _rc != 0 {
			exit _rc
		}

		local ri = 1
		foreach role of local roles {
			capture drop `netgenerate'_`role'`k'
			gen `netgenerate'_`role'`k' = .
			mata: st_store((1::`nodes'), "`netgenerate'_`role'`k'", `__nw_brk'[.,`ri'])
			local ri = `ri' + 1
		}
		mata: st_numscalar("brk_pairs", sum(`__nw_brk'))
		mata: mata drop `__nw_grp' `__nw_brk'

		// _rc is left stale (still 111, "variable not found") from the
		// earlier already-exists probes above, both the deliberately-
		// failing capture confirm checks and the capture drop calls on
		// not-yet-created variables - quietly-prefixed and inherently
		// silent commands (confirm, mata:, local) do NOT refresh _rc
		// even when they succeed, only a *captured* command deterministically
		// does (confirmed by direct testing: bare "confirm variable X"
		// and "qui sum X" both leave a prior nonzero _rc untouched, but
		// "capture confirm variable X" always sets _rc to exactly that
		// command's own result) - reset explicitly and silently here so
		// a caller checking _rc right after this command sees this
		// command's own actual outcome, not a leftover probe result.
		capture confirm variable `netgenerate'_liaison`k', exact

		return scalar pairs = brk_pairs
		local lpairs = brk_pairs

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Two-paths classified: {res}`lpairs'"
			noi di "{txt}{col 2}{ralign 16:Role}{col 20}{c |}{col 25}Total"
			noi di "{txt}{hline 19}{c +}{hline 15}"
			local ri = 1
			foreach role of local roles {
				qui sum `netgenerate'_`role'`k'
				noi di "{txt}{col 2}{ralign 16:`role'}{col 20}{c |}{col 25}{res}`=r(sum)'"
				local ri = `ri' + 1
			}
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
