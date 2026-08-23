{smcl}
{* *! version 1.0.6  23aug2014 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##analysis_other:[NW-2.6.7] Other Analysis Utilities}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwgen {hline 2}}Network extensions to generate{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:nwgen} {it:{help newnetname}} {cmd:=} {it:netfcn}({it:arguments}) [{cmd:,} {it:options}]

{p 8 17 2}
{cmd:nwgen} {it:{help newnetname}} {cmd:=} {it:{help netexp}} [{help if}] [{cmd:,} {it:options}]
		


{title:Description}

{pstd}
The command generates a network. It can be used either with a) some function {bf:{it:netfnc}} or b) with a network expression {bf:{it:netexp}}. 


{pstd}
{it:netfcn} is one of:

{phang2}{opth duplicate(netname)} [, {opt xvars}]
{p_end}
{pmore2}Duplicate a network (see {help nwduplicate}).
 
{phang2}{opth dyadprob(netname)} , {opth density(float)} [{opt undirected} {opt xvars}]
{p_end}
{pmore2}Generate a network based on tie probabilities (see {help nwdyadprob}).

{phang2}{opth geodesic(netname)} [{cmd:,}
{opth unconnected(integer)}
{opt nosym}
{opt xvars}]
{p_end}
{pmore2}Generate a network of shortest paths between nodes (see {help nwgeodesic}).

{phang2}{opth homophily(varname)}, {opth homophily(float)} {opth density(float)} [...]
{p_end}
{pmore2}Generate a homophily network (see {help nwhomophily}).

{phang2}{opt lattice}({it:{help int:rows cols}}) [, {opt undirected} {opt xwrap} {opt ywrap} {opt xvars}] 
{p_end}
{pmore2}Generate a lattice network (see {help nwlattice}).

{phang2}{opth large(netname)}
{p_end}
{pmore2}Extract the largest component as a network.

{phang2}{opth path(netname)}, {opth ego(nodeid)} {opth alter(nodeid)} [{opth length(int)} {opt sym} {opt xvars}]
{p_end}
{pmore2}Not currently implemented as a shortcut - {help nwpath} can produce zero, one, or several
output networks (one per shortest path found), which does not fit this command's own "exactly one
network per call" form. Use {help nwpath} directly - its own {opt generate()} option names one
network per path found.

{phang2}{opth permute(netname)} [, {opt xvars}] 
{p_end}
{pmore2}Random permutation of a network (see {help nwpermute}).

{phang2}{opt pref}({help int:nodes}) [, {opth m0(int)} {opth m(int)} {opth prob(float)} {opt undirected} {opt xvars}] 
{p_end}
{pmore2}Generate a preferential attachment a network (see {help nwpref}).

{phang2}{opt random}({help int:nodes}) [, {opth prob(float)} {opth density(float)} {opt undirected} {opt xvars}] 
{p_end}
{pmore2}Generate a random network (see {help nwrandom}).

{phang2}{opth reach(netname)} [, {opt nosym} {opt xvars}] 
{p_end}
{pmore2}Generate a reachability network (see {help nwreach}).

{phang2}{opt ring}({help int:nodes}) , {opth k(int)} [{opt undirected} {opt xvars}] 
{p_end}
{pmore2}Generate a ring lattice (see {help nwring}).

{phang2}{opt small}({help int:nodes}) , {opth k(int)} [{opth prob(float)} {opth shortcuts(int)} {opt undirected} {opt xvars}] 
{p_end}
{pmore2}Generate a small-world network (see {help nwsmall}).

{phang2}{opth transpose(netname)} [, {opt xvars}]
{p_end}
{pmore2}Transpose a network (see {help nwtranspose}).

{pstd}
The shortcuts above all generate a new {it:network}. A second family generates a per-node
{it:variable} instead - {cmd:nwgen} {it:newvarname} {cmd:=} {it:netfcn}({it:netname}) - each a thin
dispatch to an already-existing, dedicated command's own {opt generate()} option:

{phang2}{opth degree(netname)}, {opth outdegree(netname)}, {opth indegree(netname)}
{p_end}
{pmore2}Degree centrality (see {help nwdegree}). {bf:degree()} on a directed network is total degree
(out+in summed).

{phang2}{opth isolates(netname)}
{p_end}
{pmore2}Isolate indicator (see {help nwdegree}, {opt isolates}).

{phang2}{opth components(netname)}, {opth lgc(netname)}
{p_end}
{pmore2}Component membership, or a largest-component indicator (see {help nwcomponents}).

{phang2}{opth clustering(netname)}
{p_end}
{pmore2}Clustering coefficient (see {help nwclustering}).

{phang2}{opth closeness(netname)}, {opth farness(netname)}, {opth nearness(netname)}
{p_end}
{pmore2}Closeness centrality and its two components (see {help nwcloseness}).

{phang2}{opth between(netname)}
{p_end}
{pmore2}Betweenness centrality (see {help nwbetween}).

{phang2}{opth evcent(netname)}
{p_end}
{pmore2}Eigenvector centrality (see {help nwevcent}).

{phang2}{opth context(netname)}, {opth attribute(varname)}
{p_end}
{pmore2}Contextual (neighbor-attribute) statistic (see {help nwcontext}) - {opt attribute()} is
required and has no default.

{pstd}
Three further keywords are recognized but not implemented as a variable shortcut, since they do not
naturally reduce to one value per node: {bf:addnodes(} (mutates a network's own node set - see
{help nwaddnodes}), {bf:subset(} (produces a new network, not a variable - see {help nwsubset}), and
{bf:collapse(} (see {help nwcollapse}). Each raises a clear, immediate error rather than silently
doing nothing.
last certified : 21 Aug 2026
