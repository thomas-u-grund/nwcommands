{smcl}
{* *! version 3.17.6  09nov2026}{...}

{phang}
{help nwcommands:NW-5 programming} {hline 2} Network programming

{title:Contents}

{col 14}Section{col 31}Description
{col 14}{hline 46}
{help nwprogramming##first:{col 14}{bf:[NW-5.1]}{col 31}{bf:A first network command}}
{help nwprogramming##generator:{col 14}{bf:[NW-5.2]}{col 31}{bf:A command that creates a network}}
{help nwprogramming##internaldesign:{col 14}{bf:[NW-5.3]}{col 31}{bf:How networks are stored}}
{help nwprogramming##syntax:{col 14}{bf:[NW-5.4]}{col 31}{bf:Entering a network: _nwsyntax}}
{help nwprogramming##access:{col 14}{bf:[NW-5.5]}{col 31}{bf:Reading the ties}}
{help nwprogramming##conventions:{col 14}{bf:[NW-5.6]}{col 31}{bf:Conventions}}
{help nwprogramming##pitfalls:{col 14}{bf:[NW-5.7]}{col 31}{bf:Pitfalls}}


{marker first}{...}
{title:A first network command}

{pstd}
The program below computes the indegree of every node of a network and stores it in a new variable. It reads the
ties through the network object, so it works on networks of any size without building the adjacency matrix.

	{com}capture program drop myindegree
	program myindegree
		syntax [anything(name=netname)], GENerate(name)
		_nwsyntax `netname'
		_nwdatasync `netname'
		confirm new variable `generate'
		quietly generate double `generate' = .
		mata: st_store((1::`nodes'), "`generate'", `netobj'->get_indegree(0))
	end{txt}

{pstd}
{cmd:_nwsyntax} finds the network (the current network when none is named), unabbreviates its name and leaves
local macros behind: {cmd:`netobj'} refers to the network object and {cmd:`nodes'} is its number of nodes
({help nwprogramming##syntax:[NW-5.4]}). {cmd:_nwdatasync} makes observation {it:i} of the dataset belong to
node {it:i}, so that the result can be stored row by row. {cmd:get_indegree(0)} returns one value per node: the
number of incoming ties (all ties of an undirected network).

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. myindegree flomarriage, generate(indeg)}
	{cmd:. list _nwnode indeg in 1/5}


{marker generator}{...}
{title:A command that creates a network}

{pstd}
For a small network it is often simplest to work on the adjacency matrix. {help nwtomata} copies it into a Mata
matrix, and {help nwset} with option {opt mat()} makes a new network of a Mata matrix. This program creates the
complement of a binary network: a tie wherever the original network has none.

	{com}capture program drop mycomplement
	program mycomplement
		syntax [anything(name=netname)], name(name)
		_nwsyntax `netname'
		tempname net
		nwtomata `netname', mat(`net')
		mata: `net' = (`net' :== 0)
		mata: _diag(`net', 0)
		local undirected = cond("`directed'" == "false", "undirected", "")
		nwset, mat(`net') name(`name') labs(`labs') `undirected'
		mata: mata drop `net'
	end{txt}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. mycomplement flomarriage, name(nomarriage)}
	{cmd:. nwsummarize nomarriage}

{pstd}
{cmd:`labs'} and {cmd:`directed'}, also left by {cmd:_nwsyntax}, give the new network the same nodes and the same
direction as the original. A command
that creates a network names it with {opt name()}; {opt generate()} is for new variables.

{pstd}
The adjacency matrix has {it:n} x {it:n} cells, so this is for networks of up to a few thousand nodes; above 20,000
nodes it is refused (error 484). For larger networks, read the ties as in {help nwprogramming##access:[NW-5.5]}
and create the network from an edge list with {help nwfromedge} or {cmd:nwset, edgelist}.


{marker internaldesign}{...}
{title:How networks are stored}

{pstd}
Networks are kept in Mata, next to the Stata dataset, in one object of class {bf:NWs}. It holds the list of
networks in memory (class {bf:NWsdef}): their names, a pointer to each network and the current network. Each
network is an object of class {bf:NWdef}. The classes are compiled into the Mata library {bf:lnwcommands.mlib};
their source is {bf:unw_core.do} in the repository.

{pstd}
An {bf:NWdef} object holds

{p2colset 8 30 32 2}{...}
{p2col:{it:name, nodes}}the network name and the node names{p_end}
{p2col:{it:type}}whether the network is directed, valued, two-mode (with the mode of every node), has self-loops,
or is temporal (snapshots, intervals or events){p_end}
{p2col:{it:sparse index}}the ties as compressed rows: for every node its out-neighbors and tie values, and for a
directed network also its in-neighbors{p_end}
{p2col:{it:adjacency matrix}}the {it:n} x {it:n} matrix of tie values{p_end}
{p2colreset}{...}

{pstd}
The sparse index and the adjacency matrix hold the same ties, and each is built from the other when it is first
needed. A network created from an edge list ({help nwfromedge}, {cmd:nwset, edgelist}, the generators above 2,000
nodes) starts with the sparse index only; its adjacency matrix is built only for a command that needs it, and is
refused above 20,000 nodes. Most commands work on the sparse index, which needs memory in proportion to the number
of ties; see {help nwintro##limits:[NW-1.8]} for which commands need the matrix.

{pstd}
Node {it:i} of a network is observation {it:i} of the dataset. Node attributes are ordinary variables, and results for
nodes are stored in ordinary variables. A network does not need variables to exist; {help nwload} creates them on
request.

{pstd}
The heavy computations (shortest paths, betweenness, cliques, communities, motifs and others) run in a compiled
plugin, {bf:nwgraph}, which is installed for macOS, Windows and Linux. Where it is missing, most commands fall back
to Mata code, which gives the same results more slowly.

{pstd}
Always change networks through the commands or the methods of {bf:NWdef}, never by changing the objects directly:
the sparse index and the matrix must stay consistent.


{marker syntax}{...}
{title:Entering a network: _nwsyntax}

{pstd}
{cmd:_nwsyntax} {it:netlist} [{cmd:,} {opt max(#)} {opt min(#)}] checks that the networks exist and unabbreviates
them (by default exactly one network). It leaves these local macros, for the last network of the list:

{p2colset 8 24 26 2}{...}
{p2col:{cmd:netname}}the full network name (all names, when {opt max()} allows several){p_end}
{p2col:{cmd:netobj}}the network object, to be used in Mata as {cmd:`netobj'->}{it:method}{cmd:()}{p_end}
{p2col:{cmd:nodes}}the number of nodes{p_end}
{p2col:{cmd:directed}}{cmd:true} or {cmd:false}; likewise {cmd:valued}, {cmd:selfloops}, {cmd:is2mode} and {cmd:istemporal}{p_end}
{p2col:{cmd:labs}}the node names, ready for {cmd:nwset, labs()}{p_end}
{p2col:{cmd:networks}}the number of networks in the list{p_end}
{p2colreset}{...}

{pstd}
Without a network name it uses the current network. Network lists can be abbreviated like variable lists
({cmd:flo*}, {cmd:net1-net3}, {cmd:_all}); see {help netlist} and {help nwunab}.


{marker access}{...}
{title:Reading the ties}

{pstd}
Methods of {bf:NWdef} that read the sparse index (node numbers run from 1 to {cmd:`nodes'}):

{p2colset 8 30 32 2}{...}
{p2col:{cmd:neighbors(}{it:i}{cmd:)}}column vector of the out-neighbors of node {it:i} (all neighbors in an undirected network){p_end}
{p2col:{cmd:neighbors_in(}{it:i}{cmd:)}}column vector of the in-neighbors of node {it:i}{p_end}
{p2col:{cmd:degree(}{it:i}{cmd:)}, {cmd:degree_in(}{it:i}{cmd:)}}number of out- and in-neighbors{p_end}
{p2col:{cmd:get_outdegree(0)}, {cmd:get_indegree(0)}}the same for all nodes at once, as an {it:n} x 1 vector{p_end}
{p2col:{cmd:has_edge(}{it:i}{cmd:,}{it:j}{cmd:)}}1 if there is a tie from {it:i} to {it:j}{p_end}
{p2col:{cmd:edge_weight(}{it:i}{cmd:,}{it:j}{cmd:)}}the value of that tie (0 if none){p_end}
{p2col:{cmd:edgelist()}}all ties as an {it:m} x 3 matrix of sender, receiver and value{p_end}
{p2col:{cmd:get_nodes()}, {cmd:get_nodenames()}}number and names of the nodes{p_end}
{p2colreset}{...}

{pstd}
{cmd:get_matrix()} returns a pointer to the adjacency matrix, building it if needed. In a directed network,
decide whether a measure needs out-neighbors, in-neighbors or both: a question about a node's surroundings (is it in a
dense core? do two neighborhoods overlap?) usually uses both directions, a question about exposure (what do my
contacts do?) the out-neighbors.


{marker conventions}{...}
{title:Conventions}

{phang}
{bf:Options.} {opt generate()} names new variables, {opt name()} a new network; {opt replace} allows overwriting.
Commands that change a network in place say so.

{phang}
{bf:Results.} Node-level results go into variables, one observation per node, after {cmd:_nwdatasync}. Scalars and
matrices are returned in {cmd:r()} with {cmd:return scalar} and {cmd:return matrix} in an {cmd:rclass} program.

{phang}
{bf:Errors.} The return codes of nwcommands are listed in {help nwerrorcodes}; use them, so that users meet the same
code for the same problem.

{phang}
{bf:Tests.} The commands of the package have test files in {bf:cscripts/} of the repository, which check the results
against values computed by hand or by another program. Run a new command's test against the compiled library, not only
against the Mata source.


{marker pitfalls}{...}
{title:Pitfalls}

{phang}
1. {bf:Missing diagonal.} Without self-loops, the diagonal of the adjacency matrix is missing ({cmd:.}), so a matrix
product such as {cmd:net*net} is missing everywhere. Set the diagonal to 0 first: {cmd:_diag(net, 0)}.

{phang}
2. {bf:No broadcasting.} Mata's elementwise operators do not combine a column and a row vector into a matrix:
{cmd:x :+ x'} is a conformability error. Write {cmd:(x*J(1,n,1)) :+ (J(n,1,1)*x')}.

{phang}
3. {bf:Rows of the dataset.} Storing a node result with {cmd:st_store()} fails if the dataset has fewer
observations than the network has nodes, or puts values on the wrong nodes if they are in another order. Call
{cmd:_nwdatasync} first.

{phang}
4. {bf:r() inside the program.} A value set with {cmd:return scalar} is in {cmd:r()} only after the program has ended;
inside the program, use the local or scalar it came from.

{phang}
5. {bf:One-line Mata.} {cmd:mata: if (...) ...} and {cmd:mata: for (...) ...} on one line of an ado-file do not work;
put loops and conditions in a Mata function.


{title:See also}

{pstd}
{help _nwsyntax}, {help nwtomata}, {help nwset}, {help nwfromedge}, {help nwunab}, {help nwerrorcodes}, {help nwinternals}

{hline}
{pstd}{it:nwcommands version 3.20.1, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
