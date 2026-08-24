/***
{smcl}
{* *! version 1.0.0  22aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_community:[NW-2.6.3] Community Detection}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwspectral {hline 2}}Graph Laplacian spectral analysis{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwspectral}
[{it:{help netname}}]
[{cmd:,}
{opth generate(newvarname)}
{opt bipartition}
{opt measure(string)}
{opt replace}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's own Fiedler-vector entry; default = {it:_fiedler}{p_end}
{synopt:{opt bipartition}}Also generate a two-way spectral partition ({it:_fiedlersign}, or {it:generate()}{bf:sign}) from the sign of the Fiedler vector{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opt replace}}Replace existing variable(s){p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwspectral} computes the graph Laplacian {bf:L = D - W} (D the diagonal weighted-degree
matrix, W the adjacency/weight matrix) of a single network and its eigendecomposition - the
standard starting point for spectral graph analysis. Always computed on the undirected,
symmetrized network (no {bf:symmetrize} option needed - a directed network is symmetrized
automatically, the same convention {help nwcommunity}/{help nwkcomponents} already use, since the
classical Laplacian spectrum results below assume a symmetric matrix).

{pstd}
Three classical results are reported directly:

{p2colset 9 34 36 2}{...}
{p2col:{bf:Connected components}}The MULTIPLICITY of eigenvalue 0 in the Laplacian spectrum
exactly equals the number of connected components - {bf:r(components)} counts eigenvalues within
{bf:1e-8} of 0, cross-checkable directly against {help nwcomponents}.{p_end}
{p2col:{bf:Algebraic connectivity}}The second-smallest eigenvalue (the "Fiedler value",
{bf:r(algebraic_connectivity)}) - 0 for a disconnected network (matching the component-count
result above), and otherwise a genuine measure of how well-connected the network is overall: larger
values indicate a more robustly connected structure, harder to disconnect by removing few
edges.{p_end}
{p2col:{bf:Spectral bipartition}}The eigenvector belonging to the Fiedler value (the "Fiedler
vector") - stored per node via {opth generate(newvarname)} (default {it:_fiedler}) - is a classical
continuous relaxation of graph bisection: nodes with similar Fiedler-vector values tend to be
well-connected to each other. {opt bipartition} additionally generates a discrete two-way split
from its sign ({it:_fiedlersign}, or {it:generate()}{bf:sign} when {opt generate()} is
given).{p_end}
{p2colreset}{...}

{pstd}
For a network with more than one connected component, the Fiedler value is 0 and its own
eigenvector is not uniquely defined (any vector constant on each component, summing to zero
overall, is an equally valid choice) - {cmd:nwspectral} still reports whatever eigenvector the
underlying decomposition happens to return in that case, but {opt bipartition}'s resulting split
should not be interpreted as meaningful when {bf:r(algebraic_connectivity)} is (near) 0; use
{help nwcomponents} directly instead for a disconnected network's own true partition.

{title:Stored results}

	Scalars
	  {bf:r(algebraic_connectivity)}	second-smallest Laplacian eigenvalue (the Fiedler value)
	  {bf:r(components)}			number of Laplacian eigenvalues within 1e-8 of 0

	Matrices
	  {bf:r(eigenvalues)}			all Laplacian eigenvalues, sorted ascending

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwspectral flomarriage}
	{cmd:. nwspectral flomarriage, bipartition}

{title:References}

{pstd}
Fiedler, M. (1973). Algebraic connectivity of graphs. {it:Czechoslovak Mathematical Journal} 23(2),
298-305.

{pstd}
von Luxburg, U. (2007). A tutorial on spectral clustering. {it:Statistics and Computing} 17(4),
395-416.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (the classical Laplacian spectrum results
this command reports assume a symmetric matrix, the same reasoning {help nwcommunity}/
{help nwkcomponents} already apply). Weighted: yes, via {opt measure(valued)} (default for a
valued network) - the Laplacian is built from tie weights directly rather than dichotomized
presence/absence. Signed: not checked - a Laplacian built from mixed-sign weights is not
guaranteed positive semi-definite, so results are not meaningful for a signed network. Two-mode:
not checked - operates on the network's own square adjacency matrix. Only a single network is
accepted (unlike most other commands in this package, which accept a full {help netlist}) - each
network's own Fiedler vector is a full per-node eigenvector, not a simple per-network scalar or
per-node aggregate that stacks cleanly across multiple networks the way {help nwcomponents}'s
component id does.

{title:See also}

	{help nwevcent}, {help nwcommunity}, {help nwcomponents}, {help nwkcomponents}

***/

capture program drop nwspectral
program nwspectral, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) bipartition measure(string) replace silent]
	set more off

	nw_syntax `netname', max(1)

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
	local val = ("`netmeasure'" == "valued")

	local netgenerate "`generate'"
	if "`netgenerate'" == "" {
		local netgenerate = "_fiedler"
	}
	local signvar = "`netgenerate'" + "sign"

	capture confirm variable `netgenerate', exact
	if _rc == 0 & "`replace'" == "" {
		noi di "{err}Variable {bf:`netgenerate'} already exists; specify {bf:replace}"
		err 99
	}
	if "`bipartition'" != "" {
		capture confirm variable `signvar', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`signvar'} already exists; specify {bf:replace}"
			err 99
		}
	}

	mata: st_rclear()
	qui if _N < `nodes' {
		set obs `nodes'
	}
	nw_syntax `netname', max(1)

	tempname __nw_L __nw_EC __nw_EV __nw_ord __nw_fiedler
	mata: `__nw_L' = `netobj'->calculate_laplacian(`val')
	mata: symeigensystem(`__nw_L', `__nw_EC' = ., `__nw_EV' = .)
	mata: `__nw_ord' = order(`__nw_EV'', 1)
	mata: `__nw_EV' = (`__nw_EV''[`__nw_ord'])'
	mata: `__nw_EC' = `__nw_EC'[.,`__nw_ord']
	mata: st_matrix("nw_spectral_eigenvalues", `__nw_EV')
	mata: st_numscalar("nw_spectral_components", sum(abs(`__nw_EV') :< 1E-8))
	mata: st_numscalar("nw_spectral_algconn", `__nw_EV'[1,2])
	mata: `__nw_fiedler' = `__nw_EC'[.,2]

	capture drop `netgenerate'
	qui gen `netgenerate' = .
	mata: st_store((1::`nodes'), "`netgenerate'", `__nw_fiedler')
	if "`bipartition'" != "" {
		capture drop `signvar'
		qui gen `signvar' = .
		mata: st_store((1::`nodes'), "`signvar'", sign(`__nw_fiedler'))
	}
	mata: mata drop `__nw_L' `__nw_EC' `__nw_EV' `__nw_ord' `__nw_fiedler'

	return scalar algebraic_connectivity = nw_spectral_algconn
	return scalar components = nw_spectral_components
	return matrix eigenvalues = nw_spectral_eigenvalues
	local lalgconn = nw_spectral_algconn
	local lcomponents = nw_spectral_components

	// see nwbrokerage.ado's own header comment: the "already exists"
	// probes above leave _rc stale even after a fully successful run -
	// reset explicitly and silently.
	capture confirm variable `netgenerate', exact

	if "`silent'" == "" {
		noi di "{hline 40}"
		noi di "{txt}  Network name: {res}`netname'"
		noi di "{txt}  Connected components: {res}`lcomponents'"
		noi di "{txt}  Algebraic connectivity: {res}`=round(`lalgconn',0.0001)'"
		noi sum `netgenerate'
		noi di " "
	}
end
