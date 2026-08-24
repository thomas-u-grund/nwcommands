{smcl}
{* *! 12jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwtoedge {hline 2}}Convert two-mode network to edgelist{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nw2toedge} 
[{it:{help netlist}}]
[{cmd:,}
{opth egovars(varlist)}
{opth altervars(varlist)}
{opth ego(newvarname)}
{opth alter(newvarname)}]
		
{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth egovars(varlist)}}Keep attributes of sending nodes{p_end}
{synopt:{opth altervars(varlist)}}Keep attributes of receiving nodes {p_end}
{synopt:{opth ego(newvarname)}}Sender of ties; default = {it:_ego}{p_end}
{synopt:{opth alter(newvarname)}}Receiver of ties; default = {it:_alter}{p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwtoedge} makes an edgelist from a two-mode network or a list of networks. 

{pstd}
An edgelist of a single network {help netname} produced by {cmd:nwtoedge} is a set of three variables representing
the relations in the network. The first variable ({it:_ego}) gives the {help nodeid}
of the sending node {it:i} of a relationship; the second variable ({it:_alter}) gives the {help nodeid} of the 
receiving node {it:j}. Lastly, the variable {it:netname} saves information about the 
dyad pair ({it:i},{it:j}) in the network {it:netname}. 

{pstd}
When a network is undirected only one entry for the dyad pair ({it:i},{it:j})
is generated, unless option {opt full} is specified. 

{pstd}
When the command is used with a {help netlist}, it generates one new variable for each network {it:netname} in the list. If only one
of the networks in {help netlist} is directed, the option {opt full} is enforced.

{pstd}
One can also include node attributes (saved as normal Stata variables) in the edgelist. Option {opt egovars()} 
generates new variables that match the attributes of the sender of a tie (ego); option {opt altervars()} 
generates new variables that match the attributes of the receiver of a tie (alter).

{pstd}
For two-mode networks (see {help nw2set:introduction to two-mode networks}) the command automatically
generates the two variables {it:_nwmode_ego} and {it:_nwmode_alter}. They indicate in the edgelist format
the mode to which a node belongs.
  

{title:Supported network types}

{pstd}
Two-mode: **T1**, native - this command's entire purpose is converting a two-mode network to an edge list. Binary: yes. Directed: not applicable. Weighted: yes, tie values are carried into the edge list. Signed: not checked.

{title:See also}
	
	{help nw2fromedge}, {help nwtoedge}, {help nwsave}

last certified : 24 Aug 2026
