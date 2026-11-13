{smcl}
{* *! version 1.0.0  20aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_community:[NW-2.6.3] Communities}

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
{opt sym:metrize}
{opth resolution(real)}
{opt silent}
{opt one:mode}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth group(varname)}}Stata variable holding each node's community/group assignment, numeric or string{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opt sym:metrize}}Symmetrize a directed network before scoring (required for directed networks){p_end}
{synopt:{opth resolution(real)}}Resolution parameter (Reichardt-Bornholdt); must be > 0; default = 1{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt one:mode}}Two-mode network: the modularity of Newman for the bipartite graph read as a one-mode graph, instead of the bipartite modularity of Barber (the default for a two-mode
network){p_end}

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


{title:Network types}

{pstd}
{bf:Directed:} needs {opt symmetrize} (or a symmetrized network). {bf:Valued:} {opt measure(valued)} by default on a
valued network, {opt measure(binary)} ignores the values. {bf:Two-mode:} yes - Barber's bipartite modularity;
{opt onemode} gives Newman's modularity of the bipartite graph. {bf:Signed:} not checked. See
{help nwnetworktypes}.{p_end}


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcomponents flomarriage, generate(comp)}
	{cmd:. nwmodularity flomarriage, group(comp)}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(communities)}}number of distinct groups in {bf:group()}{p_end}
{synopt:{bf:r(modularity)}}modularity Q of the given partition{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(modularity_type)}}{bf:barber} (bipartite modularity of a two-mode network) or {bf:newman}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{bf:r(comm_sizeid)}}distribution over groups: one row per group, columns {bf:size}, {bf:compid} (group value) and {bf:share}, sorted by size{p_end}


{title:References}

{pstd}
Newman, M.E.J. (2006). Modularity and community structure in networks. {it:PNAS} 103(23), 8577-8582.


{title:See also}

	{help nwcommunity}, {help nwcomponents}

{hline}
{pstd}{it:nwcommands version 3.24.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
