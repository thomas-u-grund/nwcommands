{smcl}
{* *! version 1.0.0  13nov2026}{...}
{marker topic}
{helpb nwtopical##utilities:[NW-2.7] Utilities}

{title:Title}

{p2colset 9 17 19 2}{...}
{p2col :nwapi {hline 2}}Mata functions to read networks{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 16 2}{cmd:nwapi_version()}{p_end}
{p 8 16 2}{cmd:nwapi_count()}{p_end}
{p 8 16 2}{cmd:nwapi_names()}{p_end}
{p 8 16 2}{cmd:nwapi_exists(}[{it:name}]{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_current()}{p_end}

{p 8 16 2}{cmd:nwapi_nodes(}[{it:name}]{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_ties(}[{it:name}]{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_directed(}[{it:name}]{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_valued(}[{it:name}]{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_twomode(}[{it:name}]{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_selfloops(}[{it:name}]{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_temporal(}[{it:name}]{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_nodelabels(}[{it:name}]{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_modes(}[{it:name}]{cmd:)}{p_end}

{p 8 16 2}{cmd:nwapi_matrix(}[{it:name}]{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_edgelist(}[{it:name}]{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_outdegree(}[{it:name}]{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_indegree(}[{it:name}]{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_neighbors(}{it:name}{cmd:,} {it:node}{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_inneighbors(}{it:name}{cmd:,} {it:node}{cmd:)}{p_end}
{p 8 16 2}{cmd:nwapi_nodeid(}{it:name}{cmd:,} {it:label}{cmd:)}{p_end}

{title:Description}

{pstd}
The functions give Mata programs, including those that you write for your own research, a small and stable way to read
the networks that nwcommands holds in memory: how many networks there are, how large they are and of which kind, and
their ties, as a matrix, as an edge list, as degrees or as the neighbors of a node. They need no knowledge of how nwcommands stores
networks, never return anything that is linked to the stored network (every result is a copy), and never change a
network, the list of networks or the current network. To create a network from a Mata matrix, use {help nwset}
with option {opt mat()}; to give a result back, store it in a Stata variable with {cmd:st_store()} or in a matrix with
{cmd:st_matrix()}.

{pstd}
{it:name} is a string scalar, the exact name of a network; {cmd:""} (or no argument) is the current network. {it:node}
is a node number (a whole number, real) or a node label (string). {it:label} is a string scalar. The square brackets
in the syntax diagram mean that {it:name} can be left out.

{pstd}
For writing whole commands see {help nwprogramming}. {help nwtomata} is the command-line way to copy a network into a
Mata matrix.

{title:Stability}

{pstd}
The functions listed here are the programming interface of nwcommands for Mata. Within one major version of
nwcommands (3.x) their names, arguments, the type and the orientation of their results (rows and columns), and
their return codes do not change. New functions can be added in a minor version. A function that is to be removed
is announced as deprecated in the help file and in the release notes at least one minor version ahead; it still works until the next major
version. An incompatible change, which comes only with a new major version, raises {cmd:nwapi_version()}.

{pstd}
Nothing else in the Mata library of nwcommands is part of this interface: the classes that hold the networks and all
other functions can change in any release without notice. Do not use them in code that has to keep working.

{pstd}
{cmd:nwapi_version()} returns the generation of the interface as a whole number ({cmd:1} for nwcommands 3.x); test it in a
program that needs the functions: {cmd:assert(nwapi_version() >= 1)}. The functions of this help file exist from
nwcommands 3.24 on; an older installation does not know them (Mata stops with r(3499), "function not found").
{help nwversion} shows the version of the package.

{title:Conventions}

{phang}
{bf:Network names.} A name must match a network exactly (upper and lower case, no abbreviation, no wildcards). Unlike the
commands, the functions do not accept abbreviated names or lists of networks. {cmd:""} or no argument is the
current network ({cmd:nwapi_current()}); {cmd:nwapi_neighbors()}, {cmd:nwapi_inneighbors()} and {cmd:nwapi_nodeid()}
need the name as their first argument and take {cmd:""} for the current network.

{phang}
{bf:Nodes.} Nodes are numbered 1 to {cmd:nwapi_nodes()} in the order of the node list; node {it:i} is observation {it:i} of
the data after {cmd:_nwdatasync}. A function that takes a node accepts the number or the label. If two nodes have
the same label, the label stands for the first of them.

{phang}
{bf:Two-mode networks.} A two-mode network is one list of nodes, first the nodes of the first mode, then those of the
second; {cmd:nwapi_modes()} gives the mode of each node. Its matrix has the size of both modes together, and
dyads inside a mode, where no tie can exist, are 0.

{phang}
{bf:Copies.} Every result is a copy: changing it does not change the network.

{phang}
{bf:Orientation.} Vectors with one value per node or per network are column vectors; a matrix has the senders in its rows and
the receivers in its columns.

{title:The functions}

{pstd}
{it:The collection}
{p_end}
{p2colset 8 44 46 2}{...}
{p2col:{cmd:nwapi_version()}}real scalar: the generation of the interface, 1 in nwcommands 3.x{p_end}
{p2col:{cmd:nwapi_count()}}real scalar: the number of networks in memory (0 if none){p_end}
{p2col:{cmd:nwapi_names()}}string colvector: the names of the networks, in the order in which they were created ({cmd:0 x 1} if none){p_end}
{p2col:{cmd:nwapi_exists(}{it:name}{cmd:)}}real scalar: 1 if a network of this name exists, else 0; {cmd:nwapi_exists()} or {cmd:nwapi_exists("")}: 1 if there is any network{p_end}
{p2col:{cmd:nwapi_current()}}string scalar: the name of the current network (error 482 if there is no network){p_end}

{p2colreset}{...}
{pstd}
{it:Properties of a network}
{p_end}
{p2colset 8 44 46 2}{...}
{p2col:{cmd:nwapi_nodes()}}real scalar: the number of nodes{p_end}
{p2col:{cmd:nwapi_ties()}}real scalar: the number of ties; the arcs of a directed network, the edges of an undirected network (a tie between two nodes counts once, and a self-loop counts once){p_end}
{p2col:{cmd:nwapi_directed()}}real scalar: 1 if the network is directed{p_end}
{p2col:{cmd:nwapi_valued()}}real scalar: 1 if the ties have values{p_end}
{p2col:{cmd:nwapi_twomode()}}real scalar: 1 if the network is two-mode{p_end}
{p2col:{cmd:nwapi_selfloops()}}real scalar: 1 if ties from a node to itself are allowed{p_end}
{p2col:{cmd:nwapi_temporal()}}real scalar: 1 if the network was declared temporal (snapshots, intervals or events); the times themselves are not read by this interface{p_end}
{p2col:{cmd:nwapi_nodelabels()}}string colvector: the node labels, one row per node{p_end}
{p2col:{cmd:nwapi_modes()}}real colvector: the mode (1 or 2) of every node; all 1 in a one-mode network{p_end}

{p2colreset}{...}
{pstd}
{it:Ties}
{p_end}
{p2colset 8 44 46 2}{...}
{p2col:{cmd:nwapi_matrix()}}real matrix, {it:n} x {it:n}: the adjacency matrix, see below{p_end}
{p2col:{cmd:nwapi_edgelist()}}real matrix, {it:m} x 3: sender, receiver and value of every tie, see below{p_end}
{p2col:{cmd:nwapi_outdegree()}}real colvector, {it:n} x 1: the number of ties each node sends (a self-loop counts once){p_end}
{p2col:{cmd:nwapi_indegree()}}real colvector, {it:n} x 1: the number of ties each node receives; in an undirected network the same as the outdegree{p_end}
{p2col:{cmd:nwapi_neighbors(}{it:name}{cmd:,} {it:node}{cmd:)}}real colvector: the numbers of the nodes that {it:node} sends ties to, in ascending order ({cmd:0 x 1} if none); in an undirected network all neighbors{p_end}
{p2col:{cmd:nwapi_inneighbors(}{it:name}{cmd:,} {it:node}{cmd:)}}real colvector: the numbers of the nodes that send ties to {it:node}, in ascending order; in an undirected network the same as {cmd:nwapi_neighbors()}{p_end}
{p2col:{cmd:nwapi_nodeid(}{it:name}{cmd:,} {it:label}{cmd:)}}real scalar: the number of the node with this label (error 485 if there is none){p_end}
{p2colreset}{...}

{pstd}
In a network with values, the degrees count the ties, not the values; sum the third column of {cmd:nwapi_edgelist()} or
the rows of {cmd:nwapi_matrix()} for the sum of the values. A tie with the value 0 is not a tie.

{pstd}
{bf:The matrix.} {cmd:nwapi_matrix()} holds the value of the tie from row node to column node (1 in a network without values) and
0 where there is no tie. For an undirected network it is symmetric. It contains no missing values, so
that {cmd:A*A} and {cmd:rowsum(A)} work. {help nwtomata} returns the same matrix but with
missing values on the diagonal of a network without self-loops (and between the nodes of one mode of a two-mode
network); the functions here put 0 in those cells. A network of more than 20,000 nodes is not turned into a matrix:
the function stops with error 484, because the matrix would need more than 3 GB of memory; use the edge list, the
neighbors or the degrees, which need memory in proportion to the number of ties only.

{pstd}
{bf:The edge list.} {cmd:nwapi_edgelist()} has one row for each tie, ordered by sender and then by receiver. In an
undirected network a tie is listed once, with the smaller node number first (so the rows are the
upper triangle of the matrix); in a directed network every arc is listed. A network without ties gives a matrix of 0 rows and 3
columns. It is the right way to read large networks.

{title:Errors}

{pstd}
The functions check their arguments and stop with the return codes of {help nwerrorcodes} and a message that says what is wrong:

{p2colset 8 16 18 2}{...}
{p2col:{bf:482}}no network of this name (or no network at all, for {cmd:""}){p_end}
{p2col:{bf:485}}no node with this label, or a node number below 1 or above the number of nodes{p_end}
{p2col:{bf:198}}{it:node} is not a single whole number or a single label (a missing value, a fraction, a vector, a number that is not real){p_end}
{p2col:{bf:484}}{cmd:nwapi_matrix()} of a network with more than 20,000 nodes{p_end}
{p2colreset}{...}

{pstd}
Use {cmd:capture} to catch them: {cmd:capture mata: nwapi_nodes("friends")} followed by {cmd:if _rc == 482 ...}. Mata itself stops
with r(3200) or r(3250) if an argument has the wrong size or type (a vector for {it:name}, a number for {it:label}).

{title:Examples}

{pstd}Use the functions in a Mata block, here the Florentine marriage network{p_end}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. mata:}
	{cmd:: nwapi_names()'}
	{cmd:: nwapi_nodes("flomarriage"), nwapi_ties("flomarriage")}
	{cmd:: nwapi_directed("flomarriage")}
	{cmd:: end}

{pstd}Neighbors and degree of a family by label{p_end}

	{cmd:. mata:}
	{cmd:: nb = nwapi_neighbors("flomarriage", "medici")}
	{cmd:: lab = nwapi_nodelabels("flomarriage")}
	{cmd:: lab[nb]'}
	{cmd:: deg = nwapi_outdegree("flomarriage")}
	{cmd:: deg[nwapi_nodeid("flomarriage", "medici")]}
	{cmd:: end}

{pstd}The density of a network, and the number of triangles from the matrix{p_end}

	{cmd:. mata:}
	{cmd:: n = nwapi_nodes("flomarriage")}
	{cmd:: nwapi_ties("flomarriage") / (n*(n-1)/2)}
	{cmd:: A = nwapi_matrix("flomarriage")}
	{cmd:: trace(A*A*A) / 6}
	{cmd:: end}

{pstd}Catch an error{p_end}

	{cmd:. capture mata: nwapi_nodes("nonetwork")}
	{cmd:. display _rc}

{title:See also}

{pstd}
{help nwprogramming}, {help nwtomata}, {help nwset}, {help nwerrorcodes}, {help nwversion}

{hline}
{pstd}{it:nwcommands version 3.25.0, 14 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
