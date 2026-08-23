{smcl}
{* *! 6jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 17 23 2}{...}
{p2col :nwset {hline 2}}Declare data to be network data{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{pstd}Declare data to be network data

{p 8 15 2}
{cmd:nwset} {it:{help varlist}} [, {it:options} ]

{p 8 15 2}
{cmd:nwset}
,
{opt mat}({it:matamatrix})
[ {it:options} ]

{pstd}Declare a two-mode network from an edgelist of two id variables (see {help nwset##twomode:below})

{p 8 15 2}
{cmd:nwset} {it:{help varname:mode1id}} {it:{help varname:mode2id}} [{it:{help varname:tievalue}}] {cmd:,} {opt twomode} [ {it:options} ]

{pstd}Declare a two-mode network from a Mata matrix or a wide affiliation-matrix {help varlist} (see {help nwset##twomode:below})

{p 8 15 2}
{cmd:nwset} [{it:{help varlist}}] {cmd:,} {opt bipartite} [{opt mat}({it:matamatrix})] [ {it:options} ]

{pstd}Declare a temporal network from an edgelist (see {help nwset##temporal:below})

{p 8 15 2}
{cmd:nwset} {it:{help varname:fromid}} {it:{help varname:toid}} [{it:{help varname:tievalue}}] {cmd:,} {opt time(varname)} [ {it:options} ]

{p 8 15 2}
{cmd:nwset} {it:{help varname:fromid}} {it:{help varname:toid}} [{it:{help varname:tievalue}}] {cmd:,} {opt interval(startvar endvar)} [ {it:options} ]

{p 8 15 2}
{cmd:nwset} {it:{help varname:fromid}} {it:{help varname:toid}} {cmd:,} {opt eventtime(varname)} [ {it:options} ]


{pstd}Display currently existing networks

{p 8 15 2}
{cmd:nwset}


{pstd}Display more details about existing networks

{p 8 15 2}
{cmd:nwset, detail}


{pstd}Clear all networks (but keep Stata variables)

{p 8 15 2}
{cmd:nwset, clear}


{pstd}Clear all networks and Stata variables

{p 8 15 2}
{cmd:nwset, nwclear}


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}

{synopt:{opt edgelist}}Declare data in edgelist format{p_end}
{synopt:{opt bipartite}}Declare a two-mode network from a Mata matrix or a wide affiliation-matrix {help varlist} (see {help nwset##twomode:Declare a two-mode network} below){p_end}
{synopt:{opt twomode}}Declare a two-mode network from an edgelist of two (or three, for a valued network) id variables (see {help nwset##twomode:Declare a two-mode network} below){p_end}
{synopt:{opt directed}}Force network to be directed{p_end}
{synopt:{opt undirected}}Force network to be undirected{p_end}
{synopt:{opt name}({it:{help newnetname}})}Name of the new network; default = {it:network}{p_end}
{synopt:{opt labs}({it:lab1, lab2,...})}Node labels{p_end}
{synopt:{opth labsfromvar(varname)}}Use information in varname as node labels{p_end}
{synopt:{opt xvars}}Generate Stata variables for the network{p_end}
{synopt:{opt keeporiginal}}Generate variable {it:_nodeoriginal} with original node id's (when setting from an edgelist){p_end}
{synopt:{opth time(varname)}}Declare a snapshot temporal network - each row's own time value (see {help nwset##temporal:Declare a temporal network} below){p_end}
{synopt:{opt interval(startvar endvar)}}Declare an interval temporal network - each row active for start<=t<end (see {help nwset##temporal:Declare a temporal network} below){p_end}
{synopt:{opth eventtime(varname)}}Declare an event temporal network - each row a timestamped event, not a persistent tie (see {help nwset##temporal:Declare a temporal network} below){p_end}


{title:Description}

{pstd}
This command declares data to be network data (it is very similar to {help xtset} or {help stset}). When networks are 
{help nwimport:imported} or {help nwuse:used} or loaded from the {help webnwuse:internet} or created from
an {help nwfromedge:edgelist} or created by any other {help nw_topical##generator:network generator}, {bf:nwset} is automatically
invoked. But one can also explicitly declare data to be network data. 

{pstd}
Networks ultimately exist as objects in Mata. Once a network is declared one can interact with it from Stata by referring
to its {help netname}. In practice, this works just as if one would refer to a {help varname} in other commands. The
command sets a new network by assigning it an adjacency matrix. It can also be used to assign various meta-information
to the network.

{pstd}
An adjacency matrix is a simple representation of a network. The adjaceny matrix {it:M} of a one-mode network
has the dimensions {it:nodes} x {it:nodes}. The matrix cell {it:M_ij} = 0 when there is no tie between nodes {it:i}
and {it:j}. In binary networks, {it:M_ij} = 1 when there is a network relationship between nodes {it:i} and {it:j}.
However, networks can also be valued, i.e. {it:M_ij} > 1; in undirected networks {it:M_ij = M_ji}.

{pstd}
The command automatically recognizes if the network is unvalued (only has values 0, 1 or missing) or valued.

{pstd}
There are three ways to explicitly declare data to be network data:

{pstd}
{bf:{ul:1. Declare adjacency matrix from variables}}

{pstd}
Declare the variables in {help varlist} to represent the adjacency matrix of the network. In this case a
{help varlist} (var_1, var_2,..., var_z) needs to be given. Each variable is assumed to stand for one column in the adjacency matrix. 

{pmore}
{it:M_ij = var_i[j]}

{pstd}
When there are more observations {it:n} than variables {it:z}, only the the first {it:z} observations of each variable are considered. When
there are more variables than observations, then only the first {it:n} variables are considered as network data.

{pstd}
In this dummy example, we create 5 new variables v1-v5 and set a network from these variables. It creates an empty network (there 
are no ties).

	{cmd:. nwclear}
	{cmd:. forvalues i = 1/5} {
	{cmd:     gen v = 0}
	{cmd:  }}
	{cmd:. nwset v*}

{pstd}
After that we can display the networks that have been set (see also {help nwsummarize} or {help nwds})

	{cmd:. nwset, detail}
	{hline 50}
	{txt} 1) Current Network
	{hline 50}
	{txt}   Network name: {res}network
	{txt}   Directed: {res}true
	{txt}   Nodes: {res}5
	{txt}   Network id: {res}1
	{txt}   Variables: {res}v1 v2 v3 v4 v5
	{txt}   Labels: {res}v1 v2 v3 v4 v5{txt}

{pstd}
There is exactly one network. When neither {bf:name()}, {bf:vars()}, or {bf:labs()} are specified, the command comes up with 
a suggestion to fill this meta-information.	


{pstd}
{bf:{ul:2. Declare edgelist from variables}}

{pstd}
In this case, the command interprets the variables {help varlist} as egdelist (see {help nwfromedge}). 

{pstd}
An edgelist or arclist is a set of two (or three in the case of a valued network) variables representing
relations. Nodes are identified by entries in the cells.  For example, the data

                 {c TLC}{hline 14}{c -}{c TRC}
                 {c |} {res} fromid  toid {txt}{c |}
                 {c LT}{hline 14}{c -}{c RT}
              1. {c |} {res} 1       2    {txt}{c |}
              2. {c |} {res} 2       3    {txt}{c |}
              3. {c |} {res} 4       2    {txt}{c |}
                 {c BLC}{hline 14}{c -}{c BRC}

{pstd}
stores information about three {it:ties} (1=>2), (2=>3) and (4=>2) among four unique network nodes. The
variables defining the edges can also be {help string} variables. 

                 {c TLC}{hline 25}{c -}{c TRC}
                 {c |} {res} fromid    toid     value{txt}{c |}
                 {c LT}{hline 25}{c -}{c RT}
              1. {c |} {res} Peter     Thomas   1    {txt}{c |}
              2. {c |} {res} Tim       Peter    3    {txt}{c |}
              3. {c |} {res} Mathilde  Thomas   2    {txt}{c |}
                 {c BLC}{hline 25}{c -}{c BRC}

{pstd}
Here, there are also three relationships: (Peter => Thomas), (Tim => Peter) and (Mathilde => Thomas).

{pstd}
The following command declares such data as network data and gives the new network the name {it:mynet}:

	{cmd:. nwset fromid toid value, name(mynet) edgelist}


{pstd}
{bf:{ul:3. Declare adjacency matrix from Mata matrix}}

{pstd}
Set a network from a {it:nodes x nodes} Mata matrix that holds the adjacency matrix of the new network. The option
{bf:mat()} is specified with the name of an existing Mata matrix.

{pstd}
For example, this generates a Mata matrix:

	{cmd:. nwclear}
	{cmd:. mata: net = (0,1,0,0\1,0,0,1\1,1,0,0\1,1,1,0)}
	{cmd:. nwset, mat(net) name(network)}

{pstd}
This also generates a network called {it:network}. When no {bf:name()} for a network is specified, the command makes a valid suggestion (see {help nwvalidate}).
	
{pstd}
Now a network called {it:network} exists and we can interact with it. For example, we can get a summary of the network:
	
	{com}. nwsummarize network, mat
	{res}{hline 50}
	{txt}   Network name: {res} network
	{txt}   Network id: {res} 1
	{txt}   Directed: {res}true
	{txt}   Nodes: {res}4
	{txt}   Arcs: {res}8
	{txt}   Minimum value: {res} 0
	{txt}   Maximum value: {res} 1
	{txt}   Density: {res} .6666666666666666
             {txt}1   2   3   4
          {c TLC}{hline 17}{c TRC}
	1 {c |}  {res}0   1   0   0{txt}  {c |}
	2 {c |}  {res}1   0   0   1{txt}  {c |}
	3 {c |}  {res}1   1   0   0{txt}  {c |}
	4 {c |}  {res}1   1   1   0{txt}  {c |}
          {c BLC}{hline 17}{c BRC}


{marker twomode}{...}
{pstd}
{bf:{ul:4. Declare a two-mode network}}

{pstd}
A two-mode (bipartite) network has two distinct sets of nodes ("modes"), with ties running only
{it:between} the two sets, never within either one - e.g. people and the organisations they belong
to. Two-mode status is stored directly on the network object itself (queryable via
{help nwsummarize} or {help nwname}'s own {bf:r(mode2)}/{bf:r(nodes1)}/{bf:r(nodes2)} results), the
same as directed/valued/selfloop status - there are two ways to declare one, matching the two input
shapes {bf:nwset} already supports for one-mode networks:

{pstd}
{bf:twomode} - from an edgelist of two (or three, for a valued network) id variables, one row per
tie, directly analogous to {bf:edgelist} above. This is generally the more natural form when the
data already looks like a list of affiliations:

	{cmd:. nwclear}
	{cmd:. use "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop/data/institutions.dta", clear}
	{cmd:. nwset person institution, twomode name(mynet)}

{pstd}
This also automatically sets each mode's own human-readable description from the variable names
used ({it:person}/{it:institution} here - see {bf:r(mode1desc)}/{bf:r(mode2desc)} in
{help nwname}/{help nwsummarize}), and (if {bf:xvars} is given) generates a {it:_mode} variable
holding each node's own mode ("1" for persons, "2" for institutions - see {help nw2fromedge} for the
full option set this delegates to internally, including {bf:name()}/{bf:xvars}/{bf:keeporiginal}).
{bf:twomode} cannot be combined with {bf:bipartite} - they declare two different input shapes (an
edgelist of ties vs. a wide affiliation matrix, below) that cannot be told apart from a bare
{help varlist} alone, so combining them is rejected as an explicit error rather than guessed at.

{pstd}
{bf:bipartite} - from a Mata matrix, or from a {help varlist} interpreted as a {it:wide} affiliation
matrix (each named variable is one mode-1 node, each observation is one mode-2 node) - the two-mode
analogue of the plain adjacency-matrix forms in sections 1 and 3 above:

	{cmd:. nwclear}
	{cmd:. mata: net = (1,1,0\1,0,1\0,1,1)}
	{cmd:. nwset, mat(net) bipartite name(mynet)}

{pstd}
Here {bf:net} is a 3 (mode 1) x 3 (mode 2) matrix - {bf:bipartite} tells {bf:nwset} the matrix's own
columns are mode-1 nodes and its rows are mode-2 nodes, rather than treating it as an ordinary square
one-mode adjacency matrix.

{pstd}
Ordinary {bf:nw*} commands inspect a network's own two-mode status and behave accordingly rather
than requiring a separate command family for bipartite data - see each command's own help file for
whether it has a native bipartite definition, works on the raw bipartite structure directly, requires
an explicit projection (see {help nw2project} - {bf:nwset} and the rest of the package never project
automatically), or does not support two-mode data at all.


{marker temporal}{...}
{bf:{ul:5. Declare a temporal network}}

{pstd}
Time belongs to edges/ties, not to a separate network copy per timepoint. An edgelist can carry a
temporal dimension via exactly one of three options - {bf:time()}, {bf:interval()}, or
{bf:eventtime()} - matching three distinct semantics that are never conflated:

{p 8 12 2}{bf:time({it:timevar})}{p_end}
{p 12 12 2}{bf:snapshot} semantics: each row's own {it:timevar} value is the single instant that tie
was recorded (e.g. a wave number). Ties from different waves live in the same network object, each
carrying its own recorded time{p_end}
{p 8 12 2}{bf:interval({it:startvar endvar})}{p_end}
{p 12 12 2}{bf:interval} semantics: each row is active for {it:startvar} <= {it:t} < {it:endvar} - a
missing {it:endvar} means the tie is still ongoing (open-ended){p_end}
{p 8 12 2}{bf:eventtime({it:eventtimevar})}{p_end}
{p 12 12 2}{bf:event} semantics: each row is a timestamped relational {it:event}, not a persistent
tie - e.g. a message sent at a particular instant. Event data is never silently treated as an
ordinary graph{p_end}

{pstd}
For example, this declares a snapshot network from three waves of ties:

	{cmd:. nwset ego alter, time(wave) name(mynet)}

{pstd}
A temporal network is otherwise a completely ordinary {bf:nwset}-declared network - {help nwsummarize}
shows its temporal metadata, and {help nwattime} produces an ordinary static network containing only
the ties active at a given timepoint, usable with any {bf:nw*} command exactly like any other network.

{pstd}
{bf:time()}/{bf:interval()}/{bf:eventtime()} cannot currently be combined with {bf:twomode}/
{bf:bipartite} in the same call - a genuine composability gap (a two-mode temporal network) tracked in
docs/ROADMAP.md, not yet supported. This is deliberate groundwork only, per the package's own stated
scope: no full temporal-network modelling subsystem (dynamic centrality, relational-event models,
temporal ERGMs) is implemented or attempted here.


{title:Remarks}

{pstd}
The command {bf:nwset} or {bf:nwset, detail} without a {help varlist} or {bf:mat()} option, give a list of all
networks that do currently exist in memory. A similar overview is provided by {help nwds} (which is very similar to {help ds}).

{pstd}
Although not really needed, networks can be represented with Stata variables (see {help nwload}). For this purpose, each network
holds some meta-information about which Stata variables should be created when a network is loaded in such a way. This meta-information
can be set wit option {bf:vars()}. When specified, it needs to have as many entries as there are nodes in the network. When not specified, 
the program automatically makes a suggestion for variable names. 

{pstd}
By default, network generators (including {cmd:nwset} itself) only produce a network object - they do NOT load a network as Stata
variables (see {help nwload}). Many network generators allow the option {bf:xvars}, which ADDITIONALLY loads the new network as Stata
variables right away (equivalent to following the generator with a separate {help nwload} call). Leaving {bf:xvars} unspecified keeps
Stata's own variable budget free when one deals with many or large networks - all commands that require a {help netname} still work
even when no Stata variables for that network exist at all, or after {bf: drop _all}. This also means that one can still deal with
larger networks even when using {bf:Small Stata}.

{pstd}
Each node in a network also has a node label. This is a unique name for each node. This meta-information can be set with
option {bf:labs()}. As before, there need to be as many entries as there are nodes in the network. When not specified, the program
automatically labels nodes according the variables that have been set.
	
{pstd}
Whenever a network is set with {bf:nwset}, it is also made the {help nwcurrent:current network}. The current network is always 
the network that has been most recently loaded or generated. Many nwcommands allow that a {help netname} or a {help netlist} is
optional. In case no network is given, all nwcommands generally refer to the current network.

{pstd}
Programmers can use {bf:nwset} to write their own import routines  (see also {help nwimport}) for different network
file formats that are not natively supported by the {bf:nwcommands}.All you need to do is transform your data either in
an adjacency list or an edgelist represented by Stata variables. 

{title:See also}

	{help nodeid}, {help nwname}, {help nwds}, {help nwload}, {help nwvalidate}, {help nwsummarize}, {help nw2fromedge}, {help nw2project}, {help nwattime}
last certified : 21 Aug 2026
