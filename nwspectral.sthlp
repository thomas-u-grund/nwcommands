{smcl}
{* *! version 1.0.0  22aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_community:[NW-2.6.3] Communities}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwspectral {hline 2}}Graph Laplacian spectral analysis{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwspectral}
[{it:{help netname}}]
{cmd:,}
{opth gen:erate(newvarname)}
[{opt bipartition}
{opt measure(string)}
{opt replace}
{opt silent}
{opt force}
{opt one:mode}
{opt plot}
{opt emb:edding}
{opt name(string)}
{opt saving(filename)}
{opt export(filename[, options])}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth gen:erate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each node's own Fiedler-vector entry{p_end}
{synopt:{opt bipartition}}Also generate a two-way spectral partition (variable {it:generate()}{bf:sign}) from the sign of the Fiedler vector{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opt replace}}Replace existing variable(s){p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt force}}Run the complete decomposition of a network with more than 6,000 nodes{p_end}
{synopt:{opt one:mode}}Two-mode network: read the bipartite graph as a one-mode graph (a two-mode network is refused without it, error 6088){p_end}
{synopt:{opt plot}}Draw the scree plot of the Laplacian eigenvalues, with the algebraic connectivity marked{p_end}
{synopt:{opt emb:edding}}With {opt plot}: a second panel with the second and third eigenvector as a scatter, the marker showing the sign of the second (the bipartition){p_end}
{synopt:{opt name(string)}}Name for the graph created by {opt plot}; default = {bf:spectral}{p_end}
{synopt:{opt sav:ing(filename)}}Save the graph to a {cmd:.gph} file; an existing file is replaced{p_end}
{synopt:{opt exp:ort(filename[, options])}}Write the graph with {helpb graph export}; the file extension sets the format{p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwspectral} computes the graph Laplacian {bf:L = D - W} (D the diagonal weighted-degree
matrix, W the adjacency/weight matrix) of a single network and its eigendecomposition - the
standard starting point for spectral graph analysis. Always computed on the undirected,
symmetrized network (no {bf:symmetrize} option needed - a directed network is symmetrized
automatically, the same convention {help nwcommunity} / {help nwkcomponents} already use, since the
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
vector") - stored per node via {opth generate(newvarname)} (required) - is a classical
continuous relaxation of graph bisection: nodes with similar Fiedler-vector values tend to be
well-connected to each other. {opt bipartition} additionally generates a discrete two-way split
from its sign (variable {it:generate()}{bf:sign}, e.g. {it:_fiedlersign} for
{cmd:generate(_fiedler)}).{p_end}
{p2colreset}{...}

{pstd}
For a network with more than one connected component, the Fiedler value is 0 and its own
eigenvector is not uniquely defined (any vector constant on each component, summing to zero
overall, is an equally valid choice) - {cmd:nwspectral} still reports whatever eigenvector the
underlying decomposition happens to return in that case, but {opt bipartition}'s resulting split
should not be interpreted as meaningful when {bf:r(algebraic_connectivity)} is (near) 0; use
{help nwcomponents} directly instead for a disconnected network's own true partition.


{title:Network types}

{pstd}
{bf:Directed:} symmetrized. {bf:Valued:} the tie values are used by default ({opt measure(valued)});
{opt measure(binary)} uses only the presence of ties. {bf:Two-mode:} not supported (error 6088; use {help nwproject}
first); {opt onemode} gives the spectrum of the bipartite graph. {bf:Signed:} with negative values the Laplacian is
not positive semi-definite and the results are not meaningful. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
The complete eigendecomposition of the dense Laplacian is needed for the Fiedler vector and for the eigenvalues that are
returned, so the work grows with the cube of the number of nodes and the memory with its square. Measured in Stata/BE,
random undirected network with 10 ties per node: 1,000 nodes 1.5 seconds, 2,000 nodes 14 seconds, 3,000 nodes 50 seconds,
5,000 nodes more than 180 seconds, 10,000 nodes more than 300 seconds (and about 3 GB). Above 2,000 nodes the command prints a note;
above 6,000 nodes it stops with r(484) unless {opt force} is given. There is no exact shortcut for the returned
spectrum: only the Fiedler vector could be had from a sparse iteration, which this command does not offer.

{pstd}
Only a single network is accepted: the Fiedler vector of each network is a full per-node eigenvector.


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwspectral flomarriage, generate(_fiedler)}
	{cmd:. nwspectral flomarriage, bipartition generate(_fiedler) replace}


{title:Drawing the spectrum}

{pstd}
{opt plot} draws the Laplacian eigenvalues in ascending order, the values of {bf:r(eigenvalues)}; the second one, the algebraic connectivity, is marked. A gap after the first eigenvalues points to few
well separated groups, and the number of eigenvalues at 0 is the number of components. {opt embedding} adds a second panel with the second and third eigenvectors, one marker per node.
{opt name()} names the graph in memory, {opt saving()} writes a {cmd:.gph} file and {opt export()} writes it with {helpb graph export}. Other options go to {helpb twoway} ({helpb graph combine} with
{opt embedding}) and come last; without {opt plot} they give an error.
{opt plot} stops with error 198 for a two-mode network and for a directed network (symmetrize it with {help nwsym} first).

{phang2}{cmd:. nwspectral flomarriage, generate(_fiedler) plot embedding export(spectrum.png, width(1100))}{p_end}

{title:Stored results}

{synoptset 27 tabbed}{...}
{p2col 5 27 31 2: Scalars}{p_end}
{synopt:{bf:r(algebraic_connectivity)}}second-smallest Laplacian eigenvalue (the Fiedler value){p_end}
{synopt:{bf:r(components)}}number of Laplacian eigenvalues within 1e-8 of 0{p_end}

{p2col 5 27 31 2: Matrices}{p_end}
{synopt:{bf:r(eigenvalues)}}all Laplacian eigenvalues, sorted ascending{p_end}


{title:References}

{pstd}
Fiedler, M. (1973). Algebraic connectivity of graphs. {it:Czechoslovak Mathematical Journal} 23(2),
298-305.

{pstd}
von Luxburg, U. (2007). A tutorial on spectral clustering. {it:Statistics and Computing} 17(4),
395-416.


{title:See also}

	{help nwevcent}, {help nwcommunity}, {help nwcomponents}, {help nwkcomponents}

{hline}
{pstd}{it:nwcommands version 3.31.0, 20 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
