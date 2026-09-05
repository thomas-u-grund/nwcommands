{smcl}
{* *! 5jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 19 22 2}{...}
{p2col :nwfromedge {hline 2}}Imports network data from edgelist{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwfromedge} 
{it:{help varname: fromid}}
{it:{help varname: toid}}
[{it:{help varname:tievalue}}]
[{it:{help if}}]
[{cmd:,}
{opth name(newnetname)}
{opt xvars}
{opt labs}({it:lab1 lab2 ...})
{opt undirected}
{opt directed}
{opt twomode}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth name(newnetname)}}name of the new network; default = {it:network}{p_end}
{synopt:{opt xvars}}generate Stata variables for the network{p_end}
{synopt:{opt labs}({it:lab1 lab2 ...})}overwrite node labels{p_end}
{synopt:{opt undirected}}force the network to be undirected (alias: {opt forceundirected}){p_end}
{synopt:{opt directed}}force the network to be directed (alias: {opt forcedirected}){p_end}
{synopt:{opt twomode}}declare a two-mode (bipartite) network instead - {it:fromid}/{it:toid} are the mode-1/mode-2 id variables, not a directed ego/alter pair. An exact alias for {help nw2fromedge}, forwarding {opt name()}/{opt xvars} only; cannot be combined with {opt directed}/{opt undirected}/{opt forcedirected}/{opt forceundirected}. See {help nw2fromedge} for the full two-mode-specific behavior (same-label disambiguation, mode assignment, {opt project()}){p_end}
{synopt:{opt noclear}}do not clear existing dataset{p_end}
{synopt:{opt replace}}if a network named {it:newnetname} already exists, drop it and use this name anyway (see {help nwset} for the same convention){p_end}
{synopt:{opt labprefix}({it:string})}prefix used for auto-generated node labels when {help id:fromid}/{help id:toid} are numeric and {opt labs()} is not specified; default = {bf:n} - named {opt labprefix()}, not {opt prefix()}, to avoid colliding with {help nwrecode}'s unrelated {opt prefix()} (which prefixes new {it:network} names, not node labels){p_end}
{synopt:{opt overwrite}}forwarded to {help nwload} governing whether this command's own generated Stata variables overwrite existing ones of the same name - unrelated to {opt replace} above, which is about the {it:network}, not Stata variables{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwfromedge} imports a network from a dataset in edgelist format. 

{marker edgelist}{...}
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
The following command declares such data as network data:

	{cmd:. nwfromedge fromid toid value, name(mynet)}
					
{pstd}
This automatically generates the relevant meta-information for the network and makes it available for other programs under the {help netname} {it:mynet}. In case no {bf:name()}
is specified, the command tries to come up with a suitable name for the new network. By default, it tries {it:network}, however, if a network with this name already exists, it comes
up with an alternative name {it:network_1} and so on (see {help nwvalidate}).

{pstd}
After a network has been declared, one can refer to it by its {help netname}, just as if one would refer to a {help varname}. For example, this {help nwplot:makes a network plot} of {it:mynet}.

	{cmd:. nwplot mynet}

{pstd}
Or alternatively, this calculates the {help nwbetween:betweenness centrality} of the nodes in {it:mynet}.

	{cmd:. nwbetween mynet}			
			 
{pstd}
By default, {bf:nwfromedge} recognizes if a network is directed or undirected, i.e. for each 
dyad entry (i,j) there is also a dyad entry (j,i). However, this automatic detection
can be overwritten with the options {opt undirected} and {opt directed}.

{pstd}
One can also transfrom any network that exists in memory into such an edgelist with {help nwtoedge}.



{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, via {opt directed}/{opt undirected}/{opt forcedirected}/{opt forceundirected}. Weighted: yes - a third edge-list column supplies tie values. Signed: not checked. Two-mode: yes, via {opt twomode} - an exact alias for {help nw2fromedge}, the command that actually implements two-mode edge-list import (see that command's own help file for the full behavior). A node with zero ties (an isolate) is never created from any edgelist import - use {help nwaddnodes} afterward to add any isolates the source data could not represent.

{title:Examples}

{pstd}
This loads a network dataset from the internet and transforms the network {it:glasgow1} into an edgelist.

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwtoedge glasgow1}

{pstd}
{cmd:nwtoedge} produces variables {it:_ego}/{it:_alter} (not {it:_fromid}/{it:_toid}) plus a tie-value
column named after the network itself ({it:glasgow1} here, not {it:_link}) - and, being every possible
pair rather than a compact edgelist, it needs filtering down to the real ties before being turned back
into a network:

	{cmd:. keep if glasgow1 == 1}
	{cmd:. nwfromedge _ego _alter, name(mynet)}

{pstd}
A node with zero ties never appears in an edgelist in the first place, so any isolates in the
original network are silently dropped in a round trip like this one - use {help nwaddnodes}
afterward to add them back explicitly (see this file's own {bf:Supported network types} section
above).

	
	
{title:Also see}
	
	{help nwtoedge}, {help nwuse}, {help nwsave}, {help nwwebuse}, {help nwset}, {help nwimport}, {help nw2fromedge}

