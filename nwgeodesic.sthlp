{smcl}
{* *! 14jul2016: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_paths:[NW-2.6.6] Paths, flows and ego networks}

{title:Title}

{p2colset 9 22 24 2}{...}
{p2col :nwgeodesic {hline 2}}Calculate shortest paths between nodes{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:nwgeodesic} 
[{it:{help netlist}}]
[{cmd:,}
{opth unconnected(int)}
{opth alpha(real)}
{opt sym}
{opt symopt(options)}
{opth name(string)}
{opt nwreplace}
{opt noreplace}
{opth generate(newvarname)}
{opt xvars}
{opt force}
{opt bin:ary}
{opt plot}
{opt average}
{opt gname(string)}
{opt saving(filename)}
{opt export(filename[, options])}
{cmd:save(}{it:filename}[{cmd:, replace}]{cmd:)}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth unconnected(int)}}Define the length of the path between two unconnected nodes{p_end}
{synopt:{opth alpha(real)}}Cost of a step along a tie of value w: 1/w^alpha; default 1 on a valued network, 0 (every tie is one step) otherwise{p_end}
{synopt:{opt sym}}Calculate distances from symmetrized network{p_end}
{synopt:{opt symopt(options)}}Options controlling the symmetrization when {opt sym} is specified (see {help nwsym}){p_end}
{synopt:{opt name}({it:{help newnetname}})}Name of the new distance network; default = {it:_geodesic}{p_end}
{synopt:{opt nwreplace}}Overwrite existing network {it:newnetname}; the default {it:_geodesic} is overwritten without it{p_end}
{synopt:{opt noreplace}}Do not overwrite the default network {it:_geodesic} either: stop with an error if it exists{p_end}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's eccentricity; if omitted, eccentricity is not computed as a Stata variable at all (it is still available via
{bf:r(radius)}, the network-wide minimum){p_end}
{synopt:{opt xvars}}Generate Stata variables for the network{p_end}
{synopt:{opt force}}the least-cost distances of a valued network are computed natively at any size and {opt force} is not needed; on a platform without the plugin a valued network of more than 100
nodes stops with r(198) unless {opt force} (slow Mata routine) or {opt binary} (count steps) is given; also runs the command although its two n x n matrices would not fit in 12 GB (above about 27,000
nodes){p_end}
{synopt:{opt bin:ary}}Ignore the tie values of a valued network (by default they are used){p_end}
{synopt:{opt plot}}Draw a histogram of the finite geodesic distances (number of pairs at each whole distance); unconnected pairs are counted in a note, not drawn{p_end}
{synopt:{opt average}}With {opt plot}: a dashed line at the mean distance of the connected pairs{p_end}
{synopt:{opt gname(string)}}Name for the graph created by {opt plot}; default = {bf:geodesic} ({opt name()} names the distance network){p_end}
{synopt:{opt sav:ing(filename)}}Save the graph to a {cmd:.gph} file; an existing file is replaced{p_end}
{synopt:{opt exp:ort(filename[, options])}}Write the graph with {helpb graph export}; the file extension sets the format{p_end}
{synopt:{cmd:save(}{it:filename}[{cmd:, replace}]{cmd:)}}Save the results in a Stata data set, one observation per network; an existing file is replaced (with or without {cmd:replace}); see {bf:A list of networks}{p_end}


{title:Description}

{pstd}
{cmd:nwgeodesic} calculates the shortest paths (also known as geodesic distances) between all nodes {it:i} and {it:j}, the average shortest path length
and the diameter of the (un-)weighted network {help netname} according to Opsahl et al. (2010). The matrix of distances
is saved as a new network called {help newnetname} (default: {it:_geodesic}). 

{pstd}
With option {opt sym} the distances are calculated from the symmetrized network. Option {opt symopt()}
allows control over the symmetrization (see options in {help nwsym}).

{pstd}
{cmd:nwgeodesic}'s primary output is the distance network itself ({opt name()}); the network's
{it:radius} (the smallest node eccentricity across the whole network) is always returned as
{bf:r(radius)}, regardless of {opt generate()}. If {opt generate()} is also given,
{cmd:nwgeodesic} additionally stores each node's own {it:eccentricity} - the length of the
longest shortest path from that node to any other node - as a Stata variable under that name;
omit {opt generate()} to skip this per-node variable entirely (unlike most other nwcommands
{opt generate()} options, there is no default name - eccentricity is a secondary, opt-in output
here, not this command's main purpose). Like the diameter, {bf:r(radius)} is undefined ({bf:r(radius) = -1}) when the network has
unconnected pairs and {bf:unconnected()} was not specified; a node's eccentricity is then the longest
distance to the nodes it can reach. An existing {opt generate()}
variable is overwritten when {bf:nwreplace} is specified (there is no separate {bf:replace} option for
just the variable).

{pstd}
By default, the distance between two unconnected nodes {it:i} and {it:j}, i.e. there is no path that connects node {it:i} with node {it:j}, is set to missing. The average shortest path length, the
diameter and the radius over all pairs are then not defined;
the output says so and gives instead the share of pairs that are connected and the average and longest
distance over the connected pairs (unless option {bf:unconnected()} is specified). 

{pstd}
The option {bf:unconnected(max)} sets the distance of non-connected nodes to the maximum distance 
observed in the network plus 1.

{pstd}
Following Opsahl et al. (2010) the shortest path between node {it:i} and node {it:j}
for a given {it:alpha} is defined as:

{pmore}
{it:d_w_alpha(i,j) = min (1 / w_ih^alpha + ... + 1 / w_hj^alpha )}

{pstd}
where {it:w_ih} is the weight (value) of the tie between node {it:i} and node {it:h}. When {bf:{it:alpha} = 1}
this formula reduces to: 

{pmore}
{it:d_w_alpha(i,j) = min (1 / w_ih + ... + 1 / w_hj)}

{pstd}
which is essentially what Newman (2001) and Brandes (2001) suggested. This simply equates the distance between two
nodes with the inverse of the weight of the tie that connects them. Such a solution for dealing with 
valued networks, however, does not explicitly account for the number of steps that need to be taken to connect to nodes.
In contrast, Opsahl et al. (2010) allows giving different weight to longer and shorter paths. When {bf:{it:alpha} = 0}
the formula above ignores tie weights.


{title:A list of networks}

{pstd}
{cmd:nwgeodesic} takes one network or a list of networks ({it:netlist}; wildcards such as {bf:draw_*} work as in {help nwsummarize}). With a list, every network is analysed with the same options and a table with one row per network is printed
(nodes, average path length, diameter, radius, share of connected pairs and the average distance over the connected pairs); one line says how the networks were read (directed networks: distances follow the direction of the ties, or the
symmetrized network with {opt sym}; undirected networks). {bf:r()} holds the results of the last network of the list, exactly as a call for that network alone. The options that make a variable, a network or a graph for one network
({opt generate()}, {opt name()}, {opt xvars}, {opt plot} with {opt gname()}, {opt saving()} and {opt export()}) are error 198 with a list; call the command once per network for them. The distance network {it:_geodesic} afterwards holds
the distances of the last network.

{pstd}
{opt save()} writes a Stata data set with one observation per network (also for one network), in the order of the list, with the variables {bf:name} (network name), {bf:directed} and {bf:valued} (0 or 1), {bf:nodes}, {bf:numpaths},
{bf:unconnected} (the number of unconnected pairs), {bf:avgpath}, {bf:diameter}, {bf:radius}, {bf:alpha}, {bf:connected} (the share of pairs that are connected), {bf:avgpath_connected} and {bf:diameter_connected} (over the connected
pairs). {bf:avgpath}, {bf:diameter} and {bf:radius} are missing for a network in which not every pair is connected (the single call stores -1 in {bf:r()}); {bf:avgpath_connected} and {bf:diameter_connected} are missing when
{opt unconnected()} replaced the distances of the unconnected pairs. All numeric variables are stored as {cmd:double}.

{phang2}{cmd:. nwrandom 30, prob(.12) undirected name(draw) ntimes(20)}{p_end}
{phang2}{cmd:. nwgeodesic draw_*, save(draws)}{p_end}
{phang2}{cmd:. use draws, clear}{p_end}

{title:Network types}

{pstd}
{bf:Directed:} used as directed; {opt sym} symmetrizes the network first. {bf:Valued:} tie values are used by default: a
step along a tie of value w costs 1/w^alpha ({opt alpha(1)} by default, {opt alpha(-1)} reads the values as lengths);
{opt binary} (or {opt alpha(0)}) counts steps. {bf:Two-mode:} same as for the bipartite graph read as a one-mode
network. {bf:Signed:} not checked. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
The breadth-first searches run in the plugin, 128 sources per call (the ties are read once per call). Measured in Stata/BE, random directed network with 10 ties per node: 10,000 nodes 2.7 seconds,
20,000 nodes 10 seconds and
6.4 GB; the result is a dense {it:n}-by-{it:n} network. For the sums of the distances alone use {help nwcloseness} or {help nwkatz}, which do
not build the matrix.

{pstd}
The distances of all pairs of nodes are an {it:n}-by-{it:n} matrix; two matrices are held at once. Above about 27,000 nodes (12 GB) the command stops at once with r(484), names {help nwcloseness},
{help nwkatz}, {help nwcomponents} and {help nwpath} as the alternatives for sums of distances, connectedness and single pairs, and {opt force} runs it anyway.

{pstd}
Weighted distances are computed at any size by the native plugin; on a platform without it a valued network of more than
100 nodes stops with an error unless {opt force} (slow Mata routine) or {opt binary} is given.


{title:Example}
	
    {com}. nwwebuse florentine, nwclear
    {com}. nwgeodesic flomarriage

    {res}{hline 40}
    {txt}  Network name: {res}flomarriage
    {txt}  Network of shortest paths: {res}_geodesic
    {hline 40}
    {txt}    Nodes: {res}16
    {txt}    Symmetrized : {res}(already undirected)
        {hline 36}
    {txt}    Paths: {res}120
    {txt}    Unconnected paths: {res} 15
    {txt}    Average shortest path length: {res} (not defined)
    {txt}    Diameter: {res} (not defined)
    {txt}    Radius: {res} (not defined){txt}

{pstd}
In this first example, the average shortest path length is not defined because there
are 15 non-existent paths. There is one isolate node who cannot connect to any of the
other 15 nodes. The next example, makes use of the option {bf:unconnected()} to assign
these non-existent paths a certain length. Here, the option {bf:unconnected(max)} assigns
them the length 6.

    {com}. nwgeodesic flomarriage, unconnected(max) nwreplace

    {res}{hline 40}
    {txt}  Network name: {res}flomarriage
    {txt}  Network of shortest paths: {res}_geodesic
    {hline 40}
    {txt}    Nodes: {res}16
    {txt}    Symmetrized : {res}(already undirected)
        {hline 36}
    {txt}    Paths: {res}120
    {txt}    Unconnected paths: {res} 15
    {txt}    Unconnected paths replaced with: {res} 6
    {txt}    Average shortest path length: {res} 2.925
    {txt}    Diameter: {res} 6{txt}

{pstd}
({cmd:nwgeodesic} also reports the network {it:radius} - the minimum node eccentricity - as an
additional line here, and, if {opt generate()} is specified, stores each node's own
{it:eccentricity} under that name; not reproduced above since it depends on live data.)


{title:Drawing the distances}

{pstd}
{opt plot} draws, for the pairs of distinct nodes, how many are at distance 1, 2, 3, ... steps (the whole numbers are on the x axis). In an undirected network each pair counts once, in a directed
network each ordered pair. Pairs without a path are not distances: their number is in a note under the graph, and {opt unconnected()} does not enter the histogram.
{opt average} adds the mean distance of the connected pairs, the same number as {bf:r(avgpath)} (or {bf:r(avgpath_connected)} when pairs are unconnected). The network of distances and the displayed table are the same as without {opt plot}.
{opt gname()} names the graph in memory ({opt name()} is the distance network), {opt saving()} writes a {cmd:.gph} file and {opt export()} writes it with {helpb graph export}. Other options go to
{helpb twoway} and come last; without {opt plot} they give an error.
{opt plot} stops with error 198 for a two-mode network and for a valued network whose distances are sums of 1/value^alpha, not step counts ({opt binary} or {opt alpha(0)} count steps).

{phang2}{cmd:. nwgeodesic flomarriage, plot average export(distances.png, width(1000))}{p_end}

{title:Stored results}

{synoptset 23 tabbed}{...}
{p2col 5 23 27 2: Scalars}{p_end}
{synopt:{bf:r(nodes)}}number of nodes{p_end}
{synopt:{bf:r(numpaths)}}number of shortest paths{p_end}
{synopt:{bf:r(diameter)}}network diameter{p_end}
{synopt:{bf:r(radius)}}network radius (minimum node eccentricity){p_end}
{synopt:{bf:r(avgpath)}}average shortest path length (-1 if some pairs are unconnected){p_end}
{synopt:{bf:r(unconnected)}}number of unconnected pairs{p_end}
{synopt:{bf:r(alpha)}}value of {it:alpha} used (1 on an unvalued network){p_end}
{synopt:{bf:r(connected)}}share of pairs connected (only if some are not){p_end}
{synopt:{bf:r(avgpath_connected)}}average distance over connected pairs (only if some are not){p_end}
{synopt:{bf:r(diameter_connected)}}longest distance over connected pairs (only if some are not){p_end}
		  
{p2col 5 23 27 2: Macros}{p_end}
{synopt:{bf:r(symmetrized)}}calculated on symmetrized network{p_end}
{synopt:{bf:r(netname)}}name of the original network{p_end}
{synopt:{bf:r(geodesic)}}name of the new distance network{p_end}


{title:References}

{pstd}
Brandes, U. (2001). A faster algorithm for betweenness centrality. {it:Journal of Mathematical Sociology} 25, 163–177.

{pstd}
Opsahl, T., Agneessens, F. and Skvoretz, J. (2010). Node centrality in weighted networks: Generalizing degree and shortest paths. {it:Social Networks} 32 (3), 245-251.

{pstd}
Newman, M. E.J. (2001). Scientific collaboration networks. II. Shortest paths, weighted
networks, and centrality. {it:Physical Review E} 64, 016132.


{title:See also}

	{help nwcloseness}, {help nwreach}, {help nwpath}, {help nwcomponents}

{hline}
{pstd}{it:nwcommands version 3.35.1, 22 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
