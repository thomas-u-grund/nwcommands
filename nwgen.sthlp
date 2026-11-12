{smcl}
{* *! version 1.0.6  23aug2014 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##generator:[NW-2.3] Generators}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwgen {hline 2}}Generate variables or networks with network functions (like egen){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:nwgen} {newvar} {cmd:=} {it:netfcn1}({it:arguments}) [{cmd:,} {it:options}]

{p 8 17 2}
{cmd:nwgen} {it:{help newnetname}} {cmd:=} {it:netfcn2}({it:arguments}) [{cmd:,} {it:options}]

{p 8 17 2}
{cmd:nwgen} {it:{help newnetname}} {cmd:=} {it:{help netexp}} [{help if}] [{cmd:,} {it:options}]
		
{pstd}
where the {it:options} are also {it:fcn} dependent. 


{title:Description}

{pstd}
These are network extensions to {help generate}. The command is very similar to {help egen}
and allows producing either variables or networks. There are basically three ways to use
this commands: 1) produce Stata variables with some function {bf:{it:netfcn1}}, 2) produce 
networks with some function {bf:{it:netfnc2}}, 3) produce networks with an expression {bf:{it:netexp}}. 
A network expression is very similar to normal expressions in Stata. 


{title:Generating variables from networks}

{pstd}
The command can be used to generate Stata variables with some function {it:netfcn1} that takes 
{help netname} as an argument. For example, this can be used to generate centrality scores for 
each node in a network. 

{pstd}
{cmd:nwgen} {newvar} {cmd:=} {it:netfcn1}({it:arguments}) [{cmd:,} {it:options}]

{pstd}
{it:netfcn1} is one of:
 
{phang2}{opth between(netname)} [, {opt nosym}]
{p_end}
{pmore2}Calculate the betweenness centrality of network nodes (see {help nwbetween}).
 
{phang2}{opth closeness(netname)} [, {opth unconnected(integer)} {opt nosym}]
{p_end}
{pmore2}Calculate the closeness centrality of network nodes (see {help nwcloseness}).

{phang2}{opth clustering(netname)}
{p_end}
{pmore2}Calculate the clustering coefficient of network nodes (see {help nwclustering}).

{phang2}{opth components(netname)} 
{p_end}
{pmore2}Return the component membership of nodes (see {help nwcomponents}).

{phang2}{opth context(netname)}{cmd:,}
{opt attribute}({help varname})
[{opt stat}({help nwcontext##statistic:statistic})
{opt mode}({help nwcontext##context:context})
{opt mat}(string)
{opt noweight}]
{p_end}
{pmore2}Generate a context variable based on attributes of a node's neighbors (see {help nwcontext}).
				 
{phang2}{opth degree(netname)}
{p_end}
{pmore2}Calculate the degree centrality of network nodes. When the network is directed, the total degree (outdegree plus indegree) is returned (see {help nwdegree}).

{phang2}{opth evcent(netname)}
{p_end}
{pmore2}Calculate the eigenvector centrality of network nodes (see {help nwevcent}).

{phang2}{opth farness(netname)} 
{p_end}
{pmore2}Calculate the farness of network nodes (see {help nwcloseness}).

{phang2}{opth indegree(netname)}
{p_end}
{pmore2}Return the indegree of network nodes. When the network is undirected, the degree is returned (see {help nwdegree}).

{phang2}{opth isolates(netname)}
{p_end}
{pmore2}Returns the isolates of a network (see {help nwdegree}). 

{phang2}{opth lgc(netname)} 
{p_end}
{pmore2}Calculate membership to largest component as variable (see {help nwcomponents}).

{phang2}{opth nearness(netname)} 
{p_end}
{pmore2}Calculate the nearness of network nodes (see {help nwcloseness}).

{phang2}{opth outdegree(netname)}
{p_end}
{pmore2}Return the outdegree of network nodes. When the network is undirected, the degree is returned (see {help nwdegree}).


{pstd}
The number of an observation {help _n} in {help newvar} corresponds to the {help nodeid}
of a node in a network.


{title:Generating variables from alter/neighbor attributes}

{pstd}
{cmd:nwgen} {it:newvar} {cmd:=} {it:stat}{cmd:(alter.}{it:srcvar}{cmd:)} generates a variable summarizing
an existing Stata variable's values among each node's network neighbors (alters) - e.g.
{cmd:nwgen exposure = mean(alter.smoking)}. {it:stat} is one of {bf:mean}, {bf:wmean}, {bf:sum},
{bf:min}, {bf:max}, {bf:sd}, {bf:count}, {bf:diversity}, or {bf:proportion} (written
{cmd:proportion(alter.}{it:srcvar}{cmd:==}{it:value}{cmd:)}). This is a thin shortcut for
{help nwaltergen}, which documents the full syntax, options, and missing-value/directed-network
conventions.


{title:Generating networks}

{pstd}
The command can also be used to generate networks. There are two ways to do this:


{p 8 17 2}
{cmd:nwgen} {it:{help newnetname}} {cmd:=} {it:netfcn2}({it:arguments}) [{cmd:,} {it:options}]

{p 8 17 2}
{cmd:nwgen} {it:{help newnetname}} {cmd:=} {it:{help netexp}} [{cmd:,} {it:options}]
	
{pstd}
{it:netfcn2} is one of:

{phang2}{opth duplicate(netname)}
{p_end}
{pmore2}Duplicate a network (see {help nwduplicate}).
 
{phang2}{opth dyadprob(netname)} , {opth density(float)} [{opt undirected} {opt xvars}]
{p_end}
{pmore2}Generate a network based on tie probabilities (see {help nwdyadprob}).

{phang2}{opth geodesic(netname)} [{cmd:,}
{opth unconnected(integer)}
{opt sym}
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

{phang2}{opth reach(netname)} [, {opt sym} {opt xvars}] 
{p_end}
{pmore2}Generate a reachability network (see {help nwreach}).

{phang2}{opt ring}({help int:nodes}) , {opth k(int)} [{opt undirected} {opt xvars}] 
{p_end}
{pmore2}Generate a ring lattice (see {help nwring}).

{phang2}{opt small}({help int:nodes}) , {opth k(int)} [{opth prob(float)} {opth shortcuts(int)} {opt undirected} {opt xvars}] 
{p_end}
{pmore2}Generate a small-world network (see {help nwsmall}).

{phang2}{opth transpose(netname)}
{p_end}
{pmore2}Transpose a network (see {help nwtranspose}).


{title:Network types}

{pstd}
The command works the same for every network type; what a function does with directed, valued, two-mode and signed
networks is in the help of that function (see {help nwnetworktypes}).{p_end}


{title:Examples}

{pstd}
Generate a per-node variable with a network function:

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwgen mydeg = degree(flomarriage)}
	{cmd:. list mydeg in 1/5}

{pstd}
Generate a new network with a network function:

	{cmd:. nwgen newnet = random(10), prob(.3)}
	{cmd:. nwsummarize newnet}

{pstd}
Generate a new network with a network expression:

	{cmd:. nwgen bus_marr = flomarriage * flobusiness}
	{cmd:. nwsummarize bus_marr, matonly}

{hline}
{pstd}{it:nwcommands version 3.20.1, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
