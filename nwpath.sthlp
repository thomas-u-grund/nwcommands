{smcl}
{* *! version 2.0.1  29may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##analysis_paths:[NW-2.6.5] Paths, Reachability & Ego Networks}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwpath {hline 2}}Calculate paths between nodes{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwpath} 
[{it:{help netname}}],
[{opth ego(nodename)}
{opth alter(nodename)} | 
{opth egoid(nodeid)}
{opth alterid(nodeid)}]
{opth generate(newnetnamestub)}
{opt sym}
{opt nwreplace}]


{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opth ego(nodename)}}Name of start node{p_end}
{synopt:{opth alter(nodename)}}Name of destination node{p_end}
{synopt:{opth egoid(nodeid)}}Nodeid of start node{p_end}
{synopt:{opth alterid(nodeid)}}Nodeid of destination node{p_end}
{synopt:{opth generate(newnetnamestub)}}Save paths as networks beginning with {it:newnetnamestub}{p_end}
{synopt:{opt sym}}Symmetrize network for calculation{p_end}
{synopt:{opt nwreplace}}Overwrite networks with {it:newnetnamestub}{p_end}
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


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes ({opt sym} to symmetrize first). Weighted: not applicable - any nonzero
tie is treated as traversable regardless of its value; there is currently no shortest-{it:weighted}
-path variant (see {help nwgeodesic} for weighted distances). Signed: not checked. Two-mode: not
checked.


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
	

{title:Stores results}

	Scalars:
	  {bf:r(paths)}		 number of shortest paths found (0 if {it:ego} and {it:alter} are not connected)
	  {bf:r(path_length)}	 length of the shortest path (-1 if not connected)
	  {bf:r(path_shortest)}	 same as {bf:r(path_length)}; this command currently only ever finds
	                    shortest paths, there is no {bf:length()} option to select a longer one
	  {bf:r(ego)}		 nodeid of ego
	  {bf:r(alter)}		 nodeid of alter

	Matrices:
	  {bf:r(paths_matrix)}	one row per path found, node ids along the path; only set when
	                    {bf:r(paths)} > 0


{title:Also see}

   {help nwgeodesic}

last certified : 24 Aug 2026
