{smcl}
{* *! version 1.0.0  20aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_community:[NW-2.6.3] Community Detection}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwmodularity {hline 2}}Score an existing node partition using Newman's modularity{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwmodularity}
[{it:{help netlist}}]
{cmd:,}
{opth group(varname)}
[{opt measure(string)}
{opt SYMmetrize}
{opth resolution(real)}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth group(varname)}}Stata variable holding each node's community/group assignment{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opt symmetrize}}Symmetrize a directed network before scoring (required for directed networks){p_end}
{synopt:{opth resolution(real)}}Resolution parameter (Reichardt-Bornholdt); default = 1{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwmodularity} computes Newman's modularity {it:Q} of the network(s) in {help netlist} against an
{ul:existing} node partition given in {bf:group()} — for example a partition obtained from
{help nwcomponents}, a block model, or any hand-coded grouping variable. Unlike {help nwcommunity},
{cmd:nwmodularity} does not search for a partition; it only scores the one given. All calculations are
performed on the undirected network; directed networks require {bf:symmetrize}.

{pstd}
Modularity compares the fraction of ties that fall within the given groups to the fraction expected
under a random network with the same degree sequence. Values near 0 indicate the grouping is no better
than chance; higher (positive) values indicate a grouping that captures real community structure.
Scoring a single, all-nodes-in-one-group partition always gives {it:Q} = 0, for any network.


{title:Supported network types}

{pstd}
Binary: yes. Directed: requires {opt symmetrize} - modularity as computed here is not defined for a directed network. Weighted: yes, via {opt measure(binary|valued)}; default = {it:valued} for a valued network, {it:binary} otherwise. Signed: not checked. Two-mode: not checked.

{title:Stored results}

	Scalars
	  {bf:r(communities)}		number of distinct groups in {bf:group()}
	  {bf:r(modularity)}		modularity Q of the given partition

	Matrices
	  {bf:r(comm_sizeid)}		distribution over groups


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcomponents flomarriage, generate(comp)}
	{cmd:. nwmodularity flomarriage, group(comp)}


{title:References}

{pstd}
Newman, M.E.J. (2006). Modularity and community structure in networks. {it:PNAS} 103(23), 8577-8582.


{title:See also}

	{help nwcommunity}, {help nwcomponents}

