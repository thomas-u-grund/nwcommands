{smcl}
{* *! 12jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nw2toedge {hline 2}}Convert a two-mode network to an edge list{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nw2toedge}
[{it:{help netlist}}]
[{cmd:,}
{opth egovars(varlist)}
{opth altervars(varlist)}
{opth ego(newvarname)}
{opth alter(newvarname)}
{opt compress}
{opt full}
{opt upper}
{opt ignore2mode}
{opt isolates0}
{opt allpairs}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth egovars(varlist)}}Keep attributes of sending nodes{p_end}
{synopt:{opth altervars(varlist)}}Keep attributes of receiving nodes {p_end}
{synopt:{opth ego(newvarname)}}Sender of ties; default = {it:_ego}{p_end}
{synopt:{opth alter(newvarname)}}Receiver of ties; default = {it:_alter}{p_end}
{synopt:{opt compress}}Drop rows with no tie in any listed network, keeping only actual ties{p_end}
{synopt:{opt full}}List both {it:(i,j)} and {it:(j,i)} for an undirected network's dyads, rather than only one entry per dyad; forced automatically whenever any network in a {help netlist} is
directed{p_end}
{synopt:{opt upper}}List only one entry per undirected dyad (the default; see {opt full} above) - has no effect and is suppressed with a warning on a directed network{p_end}
{synopt:{opt ignore2mode}}Treat the two-mode network like a one-mode one - suppress the auto-generated {it:_nwmode_ego}/{it:_nwmode_alter} mode-indicator variables{p_end}
{synopt:{opt isolates0}}reserved; not currently implemented{p_end}
{synopt:{opt allpairs}}Also write the pairs of nodes of different modes without a tie (by default the ties only, as with {opt compress}){p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nw2toedge} makes an edgelist from a two-mode network or a list of networks.

{pstd}
An edgelist of a single network {help netname} produced by {cmd:nw2toedge} is a set of three variables representing
the relations in the network. The first variable ({it:_ego}) gives the {help nodeid:node label}
of the sending node {it:i} of a relationship; the second variable ({it:_alter}) gives the {help nodeid:node label} of the
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
the mode to which a node belongs. By default only the ties are listed (as with {opt compress}). With
{opt allpairs}, {cmd:nw2toedge} lists every pair of nodes of different modes, while {help nwtoedge} with
{opt allpairs} also lists the pairs of nodes of the same mode.


{title:Network types}

{pstd}
{bf:Directed:} not applicable. {bf:Valued:} the tie values are carried into the edge list. {bf:Two-mode:} yes - one
row per tie between the two modes, with the mode of both nodes; {opt allpairs} also writes the pairs without a tie.
{bf:Signed:} negative values are written like any other value. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
Only the dyads between the two modes are listed, so the size grows with the product of the two mode sizes. Measured in
Stata/BE for N mode-1 and N/2 mode-2 nodes with 10 ties per mode-1 node: 1,000 nodes 0.7 seconds,
5,000 nodes 24 seconds with {opt allpairs}; by default (ties only) 1,000 / 5,000 nodes in 0.7 / 1.0 seconds.


{title:Examples}

{pstd}
Build a small two-mode network (3 people x 2 events) and convert it to an edgelist:

	{cmd:. nwclear}
	{cmd:. mata: net = (1,0 \ 1,1 \ 0,1)}
	{cmd:. nw2set, mat(net) name(attendance)}
	{cmd:. nw2toedge attendance}
	{cmd:. list}


{title:See also}

	{help nw2fromedge}, {help nwtoedge}, {help nwsave}

{hline}
{pstd}{it:nwcommands version 3.24.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
