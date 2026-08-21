{smcl}
{* *! version 1.0.6  23aug2014 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwgen {hline 2} Network extensions to generate}
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
{pmore2}Generate a network of paths between nodes (see {help nwpath}).

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
last certified : 21 Aug 2026
