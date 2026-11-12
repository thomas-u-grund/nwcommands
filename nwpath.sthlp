{smcl}
{* *! version 2.0.1  29may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_paths:[NW-2.6.6] Paths, flows and ego networks}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwpath {hline 2}}Paths between nodes{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwpath} 
[{it:{help netname}}],
{c -(}{opth ego(nodename)} | {opth egoid(nodeid)}{c )-}
{c -(}{opth alter(nodename)} | {opth alterid(nodeid)}{c )-}
[{opth generate(newnetnamestub)}
{opt sym}
{opt nwreplace}
{opt nopaths}
{opt bin:ary}
{opth alpha(real)}]


{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opth ego(nodename)}}Name of start node{p_end}
{synopt:{opth alter(nodename)}}Name of destination node{p_end}
{synopt:{opth egoid(nodeid)}}Nodeid of start node{p_end}
{synopt:{opth alterid(nodeid)}}Nodeid of destination node{p_end}
{synopt:{opth generate(newnetnamestub)}}Save paths as networks beginning with {it:newnetnamestub}{p_end}
{synopt:{opt sym}}Symmetrize network for calculation; cannot be combined with {opt generate()}{p_end}
{synopt:{opt nwreplace}}Overwrite networks with {it:newnetnamestub}{p_end}
{synopt:{opt nopaths}}Do not print the list of paths; the results in {cmd:r()} are still returned{p_end}
{synopt:{opt bin:ary}}Ignore the tie values of a valued network (by default they are used){p_end}
{synopt:{opth alpha(real)}}Cost of a step along a tie of value w: 1/w^alpha (default 1 on a valued network; accepted on any network){p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd: nwpath} calculates the shortest paths between node {it:ego} and node {it:alter}, i.e. ways how the nodes
are connected with each other.

{pstd}
With option {opth generate(newnetname)} the command produces one new network for each valid path that is found.
For example, if three paths are found between nodes {it:ego} and {it:alter}, the networks {it:newnetnamestub_1, newnetnamestub_2, newnetnamestub_3}
are produced.


{title:Options}

{p2col 5 30 30 30:{opth ego(nodename)}}Must be specified and indicates the startpoint of a path.

{p2col 5 30 30 30:{opth alter(nodename)}}Must be specified and indicates the endpoint of a path.

{p2col 5 30 30 30:{opt sym}}Calculates everything on the symmetrized network.{p_end}

{p2col 5 30 30 30:{opth generate(newnetnamestub)}}Save the paths as networks. This can be used to display 
paths using nwplot, see example.{p_end}


{title:Remarks}

{pstd}
It can be a good idea to save the paths between two nodes by specifying {opth generate(newnetname)} for plotting.
For example, 

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwpath flobusiness, ego(medici) alter(peruzzi) generate(medici_peruzzi)}

{pstd}
There is exactly one shortest path between {it:medici} and {it:peruzzi}, so a single network,
{it:medici_peruzzi_1}, is generated ({opt generate()} is a stub - one network per shortest path found,
numbered {it:_1}, {it:_2}, ... - so a pair of nodes with multiple shortest paths would instead
produce {it:medici_peruzzi_1}, {it:medici_peruzzi_2}, and so on).
One can now use this new network to represent the edgecolor when plotting the original network.

	{cmd:. nwplot flobusiness, edgecolor(medici_peruzzi_1) scheme(s2network)}


{title:Network types}

{pstd}
{bf:Directed:} used as directed; {opt sym} symmetrizes the network first. {bf:Valued:} tie values are used by default:
the path of least cost, a tie of value w costing 1/w^alpha ({opt alpha(1)} by default, {opt alpha(-1)}: values are
lengths; {cmd:r(path_cost)}, {cmd:r(path_length)} = steps); {opt binary} finds the fewest steps. {bf:Two-mode:} same as
for the bipartite graph read as a one-mode network. {bf:Signed:} not checked. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
The paths are enumerated from the stored ties and {opt generate()} writes each path as a network of its ties; neither builds a matrix.
20,000 nodes 0.25 seconds in Stata/BE for two nodes at 4 steps. The number of walks examined grows with the
degree to the power of the path length.


{title:Examples}


     {cmd:. nwwebuse florentine}
     {cmd:. nwpath flobusiness, ego(medici) alter(peruzzi)}
     {res}
     {hline 40}
     {txt}  Network: {res}flobusiness
     {hline 40}
     {txt}    Ego                  : {res}medici
     {txt}    Alter                : {res}peruzzi
     {txt}    Shortest path length : {res}3
     {hline 40}

     {txt}  Path 1:  {res}medici{txt} => {res}barbadori{txt} => {res}castellani{txt} => {res}peruzzi
     {txt}  Path 2:  {res}medici{txt} => {res}ridolfi{txt} => {res}strozzi{txt} => {res}peruzzi{txt}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(paths)}}number of shortest paths found (0 if {it:ego} and {it:alter} are not connected){p_end}
{synopt:{bf:r(path_length)}}length of the shortest path (-1 if not connected){p_end}
{synopt:{bf:r(path_shortest)}}same as {bf:r(path_length)}; this command currently only ever finds
shortest paths, there is no {bf:length()} option to select a longer one{p_end}
{synopt:{bf:r(path_cost)}}cost of the path on a valued network (sum of 1/value^alpha){p_end}
{synopt:{bf:r(ego)}}nodeid of ego{p_end}
{synopt:{bf:r(alter)}}nodeid of alter{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{bf:r(paths_matrix)}}one row per path found, node ids along the path; only set when {bf:r(paths)} > 0{p_end}


{title:Also see}

   {help nwgeodesic}

{hline}
{pstd}{it:nwcommands version 3.20.1, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
