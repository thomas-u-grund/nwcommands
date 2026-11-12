{smcl}
{* *!  15jul2016 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwaddnodes {hline 2}}Add nodes to network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwaddnodes}
[{it:{help netname}}],
{cmd:nodenames}({it:n1, n2, ...})
[{opt mode(numlist)}
{opt generate}({it:{help newnetname}})
{opt xvars}]

{synoptline}
{p2colreset}{...}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt nodenames}({it:n1, n2, ...})}Node identifiers separated by commas or spaces; a node identifier cannot contain a space{p_end}
{synopt:{opt mode(numlist)}}Two-mode (bipartite) networks only: the mode (1 or 2) each new node belongs to. Either a SINGLE value (applied to every new node) or one value per node listed in
{opt nodenames()}, in the same order. Required when {help netname} is two-mode and omitted only for a one-mode network, where it would be meaningless{p_end}
{synopt:{opt generate}({it:{help newnetname}})}Save as new network{p_end}
{synopt:{opt xvars}}Generate Stata variables for the network{p_end}


{title:Description}

{pstd}
Add isolate nodes to an existing networks. By default, {help netname} is replaced, unless {bf:generate()} is specified.

{pstd}
An isolate node added this way has no ties to any existing node. A network built from an edgelist
({help nwset}, {help nwfromedge}, {help nw2fromedge}) only has the nodes that appear in the edgelist
(an isolate needs a row of its own with the other identifier missing, see {help nwfromedge}).
Call {cmd:nwaddnodes} afterward to add any isolates the source data itself did not hold.


{title:Network types}

{pstd}
{bf:Directed:} yes. {bf:Valued:} yes, existing ties and their values are untouched. {bf:Two-mode:} yes - {opt mode()} is
required and says to which mode each new node belongs. {bf:Signed:} yes, as valued. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
The added nodes have no ties, so a network held as stored ties only gets longer row pointers: 20,000 nodes 0.1 seconds.


{title:Examples}

{pstd}
This example adds three new nodes (isolates) to a random network with 5 nodes.

	{cmd:. nwclear}
	{cmd:. nwrandom 5, prob(.1)}
	{cmd:. nwaddnodes, nodenames(Thomas, Peter, Mathilde)}

{pstd}
This example adds two isolate nodes to a two-mode network - one to each mode (a mode-1 "person"
with no memberships, and a mode-2 "institution" with no members):

	{cmd:. nw2fromedge person institution, name(mynet)}
	{cmd:. nwaddnodes mynet, nodenames(NewPerson, NewInstitution) mode(1 2)}

{hline}
{pstd}{it:nwcommands version 3.20.1, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
