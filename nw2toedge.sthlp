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
{synopt:{opt compress}}Drop rows with no tie in any listed network, keeping only actual ties{p_end}
{synopt:{opt full}}List both {it:(i,j)} and {it:(j,i)} for an undirected network's dyads, rather than only one entry per dyad; forced automatically whenever any network in a {help netlist} is directed{p_end}
{synopt:{opt upper}}List only one entry per undirected dyad (the default; see {opt full} above) - has no effect and is suppressed with a warning on a directed network{p_end}
{synopt:{opt ignore2mode}}Treat the two-mode network like a one-mode one - suppress the auto-generated {it:_nwmode_ego}/{it:_nwmode_alter} mode-indicator variables{p_end}
{synopt:{opt isolates0}}reserved; not currently implemented{p_end}

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
the mode to which a node belongs. Unlike {help nwtoedge} on a two-mode network, {cmd:nw2toedge} also
filters the edgelist down to cross-mode pairs only (dropping any same-mode/self entry the underlying
dense representation may otherwise still enumerate) - this is the one behavioral difference between the
two commands; see {help nwtoedge}'s own help file if you specifically need the unfiltered enumeration.

{title:Examples}

{pstd}
Build a small two-mode network (3 people x 2 events) and convert it to an edgelist:

	{cmd:. nwclear}
	{cmd:. mata: net = (1,0 \ 1,1 \ 0,1)}
	{cmd:. nw2set, mat(net) name(attendance)}
	{cmd:. nw2toedge attendance}
	{cmd:. list}

{title:Supported network types}

{pstd}
Two-mode: **T1**, native - this command's entire purpose is converting a two-mode network to an edge list. Binary: yes. Directed: not applicable. Weighted: yes, tie values are carried into the edge list. Signed: not checked.

{title:See also}

	{help nw2fromedge}, {help nwtoedge}, {help nwsave}

last certified : 28 Aug 2026
