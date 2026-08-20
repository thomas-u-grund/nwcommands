{smcl}
{* *! 14jul2016: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 10 10 2}{...}
{p2col:nwgeodesic {hline 2} Calculate shortest paths between nodes}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:nwgeodesic} 
[{it:{help netname}}]
[{cmd:,}
{opth unconnected(int)}
{opt nosym}
{opt sympopt(options)}
{opth name(string)}
{opt nwreplace}
{opth generate(newvarname)}
{opt xvars}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth unconnected(int)}}Define the length of the path between two unconnected nodes{p_end}
{synopt:{opth alpha(real)}}Deal with valued networks{p_end}
{synopt:{opt sym}}Calculate distances from symmetrized network{p_end}
{synopt:{opt name}({it:{help newnetname}})}Name of the new distance network; default = {it:_geodesic}{p_end}
{synopt:{opt nwreplace}}Overwrite existing network {it:newnetname}{p_end}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores each node's eccentricity; default = {it:_eccentricity}{p_end}
{synopt:{opt xvars}}Do not generate Stata variables{p_end}


{title:Description}

{pstd}
{cmd:nwgeodesic} calculates the shortest paths (also known as geodesic distances) between all nodes {it:i} and {it:j}, the average shortest path length
and the diameter of the (un-)weighted network {help netname} according to Opsahl et al. (2010). The matrix of distances
is saved as a new network called {help newnetname} (default: {it:geodesic}). 

{pstd}
With option {opt sym} the distances are calculated from the symmetrized network. Option {opt symopt()}
allows control over the symmetrization (see options in {help nwsym}).

{pstd}
{cmd:nwgeodesic} also generates a new variable (default: {it:_eccentricity}) that stores each node's
{it:eccentricity} - the length of the longest shortest path from that node to any other node - and
returns the network's {it:radius} (the smallest eccentricity across all nodes) as {bf:r(radius)}.
Like the diameter, both are undefined (missing for a node's eccentricity; {bf:r(radius) = -1}) when
the network has unconnected pairs and {bf:unconnected()} was not specified. An existing {it:generate()}
variable is overwritten when {bf:nwreplace} is specified (there is no separate {bf:replace} option for
just the variable).

{pstd}
By default, the distance between two unconnected nodes {it:i} and {it:j}, i.e. there is no path that connects node {it:i} with node {it:j}, is set to missing. Non-existent paths are excluded from 
the calculation of the average shortest path length (unless option {bf:unconnected()} is specified). 

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


{title:References}

{pstd}
Brandes, U. (2001). A faster algorithm for betweenness centrality. {it:Journal of Mathematical Sociology} 25, 163–177.

{pstd}
Opsahl, T., Agneessens, F. and Skvoretz, J. (2010). Node centrality in weighted networks: Generalizing degree and shortest paths. {it:Social Networks} 32 (3), 245-251.

{pstd}
Newman, M. E.J. (2001). Scientific collaboration networks. II. Shortest paths, weighted
networks, and centrality. {it:Physical Review E} 64, 016132.


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

    {com}. nwgeodesic flomarriage, unconnected(max)

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
additional line here, and, unless {bf:xvars} is specified, generates a per-node {it:_eccentricity}
variable; not reproduced above since it depends on live data.)

	
{title:Stored results}	

	Scalars
	  {bf:r(nodes)}		number of nodes
	  {bf:r(numpaths)}	number of shortest paths
	  {bf:r(diameter)}	network diameter
	  {bf:r(radius)}	network radius (minimum node eccentricity)
	  {bf:r(avgpath)}	average shortest path length
		  
	Macros
	  {bf:r(symmetrized)}	calculated on symmetrized network
	  {bf:r(netname)}	name of the original network
	  {bf:r(netname)}	name of the new distance network	  
		  
		  
{title:See also}

	{help nwcloseness}, {help nwreach}, {help nwpath}, {help nwcomponents}

last certified : 21 Aug 2026
