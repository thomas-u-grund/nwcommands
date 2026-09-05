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
{synopt:{opt nodenames}({it:n1, n2, ...})}Node identifiers separated by comma{p_end}
{synopt:{opt mode(numlist)}}Two-mode (bipartite) networks only: the mode (1 or 2) each new node belongs to. Either a SINGLE value (applied to every new node) or one value per node listed in {opt nodenames()}, in the same order. Required when {help netname} is two-mode and omitted only for a one-mode network, where it would be meaningless{p_end}
{synopt:{opt generate}({it:{help newnetname}})}Save as new network{p_end}
{synopt:{opt xvars}}Generate Stata variables for the network{p_end}


{title:Description}

{pstd}
Add isolate nodes to an existing networks. By default, {help netname} is replaced, unless {bf:generate()} is specified.

{pstd}
An isolate node added this way has no ties to any existing node - this is the ONLY way to
represent an isolate in a network that was built from an edgelist ({help nwset}, {help nwfromedge},
{help nw2fromedge}): an edgelist can only ever record nodes that appear in at least one tie, so a
node with zero ties is never created from edgelist input alone, silently, with no error or note -
see {help nwset##twomode:nwset}'s and {help nwfromedge}'s own "Supported network types" sections.
Call {cmd:nwaddnodes} afterward to add any isolates the source data itself could not represent.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes - a purely structural operation, existing
ties and their values are untouched. Two-mode: yes - {opt mode()} is REQUIRED on a two-mode
network (no default is silently assumed) to say which of the two node sets each new isolate
belongs to; omitting it on a two-mode network is an error, not a silent mode-1 default.


{title:Examples}

{pstd}
This example adds three new nodes (isolates) to a random network with 5 nodes.

	{cmd:. nwclear}
	{cmd:. nwrandom 5, prob(.1)}
	{cmd:. nwaddnodes, nodenames(Thomas Grund, Peter, Mathilde Turcotte)}

{pstd}
This example adds two isolate nodes to a two-mode network - one to each mode (a mode-1 "person"
with no memberships, and a mode-2 "institution" with no members):

	{cmd:. nw2fromedge person institution, name(mynet)}
	{cmd:. nwaddnodes mynet, nodenames(New Person, New Institution) mode(1 2)}

last certified : 29 Aug 2026
