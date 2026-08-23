/***
{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nw_topical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwbetween  {hline 2}}Calculate betweenness centrality{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwbetween}
[{it:{help netlist}}]
[{cmd:,}
{opt generate}({it:{help newvarlist}})
{opt replace}
{opt nosym}
{opt standardize}
{opt silent}
{opt weighted}
{opt alpha(real)}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt generate}({it:{help newvarlist}})}variable name for betweenness centrality; default = {it:_between}{p_end}
{synopt:{opt replace}}allow overwriting an existing variable of the same name{p_end}
{synopt:{opt nosym}}do not symmetrize network before calculation of shortest paths{p_end}
{synopt:{opt standardize}}standardize centrality scores{p_end}
{synopt:{opt silent}}suppress the summary table of the generated variable{p_end}
{synopt:{opt weighted}}calculate on weighted (Dijkstra) shortest paths instead of dichotomizing{p_end}
{synopt:{opt alpha(real)}}weight-to-distance exponent used with {opt weighted}; default = 1{p_end}


{title:Description}

{pstd}
Calculates the betweenness centrality for each node {it:i} in a {help netname:network} or {help netlist:network list} and
saves the result as a Stata variable. By default the command uses the dichotomized network (any tie
with weight > 0 counts as an edge, tie strength ignored); pass {opt weighted} to compute genuinely
weighted betweenness on Dijkstra shortest paths instead, using {opt alpha()} to control the
weight-to-distance conversion (same convention as {help nwgeodesic}'s own {opt alpha()}: edge cost is
{it:weight^alpha} - {opt alpha(1)}, the default, uses raw tie weight directly as distance/cost;
{opt alpha(0)} reduces to the unweighted case).

{pstd}
The betweenness centrality for node {it:i} is equal to the number of shortest paths from all vertices to all 
others that pass through node {it:i}. A node with high betweenness centrality has a large influence on the 
transfer of items through the network, under the assumption that item transfer follows the shortest paths. 

{pstd}
When there is more than one shortest path from node {it:k} to node {it:l}, the betweenness scores of all nodes {it:i}
on these paths increases proportionally.  

{pstd}
Formally, betweenness centrality of node {it:i} on graph {it:g} is defined as:

{pmore}
{it:Between_i(g) = sum ( sigma_st(i) / sigma_st )}

{pstd}
where, {it:sigma_st} is the total number of shortest paths from node {it:s} to node {it:t} and {sigma_st(i)} is the number of those 
paths that pass through node {i}.

{pstd}
For the standardized betweenness centrality:

{pmore}
Directed network: {it:Between_i_std(g) = Between_i(g) / ((N-1)*(N-2))}

{pmore}
Undirected network: {it:Between_i_std(g) = Between_i(g) / ((N-1)*(N-2)/2)}

{pstd}
The Stata variable {it:varname} is overwritten (pass {opt replace} to allow this deliberately, or
{opt generate()} to use a different name instead). When betweenness centrality is calculated
for more than one network at the same time (e.g. {bf:nwbetween glasgow1 glasgow2}), the command
generates one variable per network, named {it:varname_netname} (e.g. {it:_between_glasgow1},
{it:_between_glasgow2}).


{title:Examples}

	{cmd:. webnwuse gang, nwclear}
	{cmd:. nwbetween gang}
	{cmd:. sum _between}


{title:Performance}

{pstd}
The default (unweighted) mode of {cmd:nwbetween} transparently uses a compiled native (C)
implementation of the same algorithm when one is available for the current platform (currently:
macOS), falling back to an identical, fully-supported Mata implementation everywhere else -
there is nothing to configure and no difference in the result, only in how fast it is computed.
See {browse "docs/NATIVE_GRAPH_LIBRARIES.md"} in the package's own repository for the evidence
behind this (a native run at 10,000 nodes was measured faster than the Mata implementation at
just 1,000). {opt weighted} still always uses the Mata implementation.


{title:Supported network types}

{pstd}
Binary: yes, native. Directed: yes for the standardization normalizer (see the formulas above), but
by default the network is symmetrized before computing betweenness at all - pass {opt nosym} to
compute genuinely directed betweenness on the network as given; without {opt nosym} the reported
scores reflect the symmetrized structure, not the original directed one (this applies identically
whether or not {opt weighted} is used - symmetrization, via {help nwsym}'s default {cmd:max} mode,
correctly combines rather than discards tie weights). Weighted: {bf:W2} - the default remains
{bf:W3} (explicit binary-only: any tie with weight strictly greater than zero is dichotomized to an
edge, tie strength otherwise ignored), but {opt weighted} now computes genuine Dijkstra-based
betweenness using tie strength directly as distance/cost via {opt alpha()} - never silently
implied, always an explicit opt-in. Signed: ties with weight less than or equal to zero, including
negative ties, are treated as no tie at all in both the default and {opt weighted} cases - a
negative (e.g. antagonistic) tie is not distinguished from an absent one, and {opt weighted}'s
{it:weight^alpha} cost is undefined for a negative base in general, so signed networks are not
natively supported by either mode. Two-mode: not checked.


{title:See also}

	{help nwpath}, {help nwgeodesic}, {help nwcloseness}, {help nwkatz}, {help nwdegree}, {help nwcloseness}, {help nwevcent}

***/

capture program drop nwbetween
program nwbetween
	syntax [anything(name=netname)], [replace GENerate(string) nosym standardize silent weighted alpha(real 1)]

	// This command's own doc has always described netlist (multi-network)
	// behavior ("In case, betweenness centrality is calculated for z
	// networks at the same time... the command generates the variables
	// varname_z, one for each network"), but the code never actually
	// implemented it: nw_syntax was called with no max() override (so
	// it defaulted to exactly one network), and "local k = 1" /
	// "local generate_all """ were vestigial scaffolding from an
	// abandoned attempt, referenced nowhere else in the body. Finished
	// rather than just documented as unsupported, matching the same
	// fix already made to nwdegree (NWCOMMANDS_COMMAND_STYLE.md's own
	// canonical netlist example). Single-network calls are unaffected:
	// default output variable names have no suffix, exactly as before.
	//
	// Separately, the pre-existing "already exists" guard was dead
	// code: "capture drop `generate'*" unconditionally deleted any
	// matching variable *before* the confirm check ran, so the check
	// could never fire, and there was no actual "replace" option in
	// syntax despite the error text telling users to pass one - the
	// command always silently overwrote existing variables regardless.
	// Fixed by adding a real replace option and making the guard gate
	// the drop, matching the working convention used elsewhere in this
	// package (e.g. nwdegree, nwkatz).
	nw_syntax `netname', max(9999)
	local totalnetworks = `networks'

	if "`generate'" == "" {
		local generate "_between"
	}

	qui foreach netname_temp in `netname' {
		nw_syntax `netname_temp'
		local oldnetname `netname_temp'

		local netgenerate "`generate'"
		if `totalnetworks' > 1 {
			local netgenerate "`netgenerate'_`netname_temp'"
		}

		capture confirm variable `netgenerate', exact
		if _rc == 0 & "`replace'" == "" {
			di "{err}Variable {bf:`netgenerate'} already exists; use {bf:replace} or {bf:generate()}"
			err 99
		}
		capture drop `netgenerate'
		generate `netgenerate' = .

		if "`nosym'" == "" {
			nwsym `netname_temp', generate(`netname_temp'_symmetrized)
			nw_syntax
		}

		if "`weighted'" != "" {
			// weighted (Dijkstra-based) betweenness has no native
			// backend yet - a documented follow-on, see
			// docs/NATIVE_GRAPH_LIBRARIES.md.
			mata: st_store((1::`nodes'),"`netgenerate'", `netobj'->calculate_betweenness_weighted(`alpha'))
		}
		else {
			// NativeGraphAvailable() (unw_core.do) transparently falls
			// back to the Mata implementation on any platform without a
			// compiled nwgraph.plugin/nwgraph_unix.plugin (currently:
			// everywhere except macOS) - see docs/NATIVE_GRAPH_LIBRARIES.md
			// and native/nwgraph.c's own header for the full account.
			mata: st_store((1::`nodes'),"`netgenerate'", NativeGraphAvailable() ? `netobj'->calculate_betweenness_native() : `netobj'->calculate_betweenness())
		}

		if "`standardize'" != "" {
			if "`directed'" == "true" {
				qui replace `netgenerate'  = `netgenerate'  / ((`nodes' - 1) * (`nodes' - 2))
			}
			else {
				qui replace `netgenerate'   = `netgenerate' / ((`nodes' - 1) * (`nodes' - 2) / 2)
			}
		}

		if "`nosym'" == "" {
			nwdrop `oldnetname'_symmetrized
			nwcurrent `oldnetname'
		}

		mata: st_rclear()

		noi di "{hline 40}"
		noi di "{txt}  Network name: {res}`netname_temp'"
		noi di "{hline 40}"
		noi di "{txt}    Betweenness centrality"
		if "`standardize'" != "" {
			noi di "{txt}    (standardized)"
		}
		if "`silent'" == "" {
			noi sum `netgenerate'
		}
		mata: st_numscalar("r(bw_central)", sum(J(`nodes',1,max(st_data((1::`nodes'), "`netgenerate'"))) :- st_data((1::`nodes'), "`netgenerate'")) / ((`nodes' - 2) * (`nodes' - 1) * (`nodes' - 1)))
	}
end

