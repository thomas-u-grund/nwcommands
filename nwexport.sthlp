{smcl}
{* *! version 1.0.6  23aug2014 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwexport  {hline 2}}Export a network as a Pajek, UCINET, GML or edge list file{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwexport} 
[{it:{help netname}}],
{opt type}({it:{help nwexport##exp_type:exp_type}})
[{opth fn:ame(filename)}
{opt replace}
{opt agg:regate}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt type}({it:{help nwexport##exp_type:exp_type}})}{bf:Required.} file format: {cmd:pajek}, {cmd:ucinet}, {cmd:gml} or {cmd:edgelist}{p_end}
{synopt:{opth fn:ame(filename)}}filename of the exported network without the file ending: default = {it:netname}{p_end}
{synopt:{opt replace}}overwrite exported file{p_end}
{synopt:{opt agg:regate}}temporal network: export the ties aggregated over all times (see {help nwexport##temporal:Temporal networks}){p_end}


{synoptset 20 tabbed}{...}
{marker exp_type}{...}
{p2col:{it:exp_type}}Description{p_end}
{p2line}
{p2col:{cmd: pajek}}network is saved in {browse "https://docs.gephi.org/desktop/User_Manual/Import/Pajek_NET_Format/":Pajek .NET file format}
		{p_end}
{p2col:{cmd: ucinet}}network is saved in {help nwimport##ucinet:Ucinet .DL file format}
		{p_end}
{p2col:{cmd: gml}}network is saved in GML format (file ending .gml)
		{p_end}
{p2col:{cmd: edgelist}}network is saved as a plain-text edge list (file ending .txt)
		{p_end}


{title:Description}

{pstd}
Exports a network to 1) Pajek .NET, 2) Ucinet .DL, 3) GML or 4) plain-text edge list file format. Only exports one network and no node level
attributes. By default, the
new network file is saved in the working directory. When no {opt fname} is specified, the program calls the new file {it:netname.dl} (Ucinet),
{it:netname.net} (Pajek), {it:netname.gml} (GML) or {it:netname.txt} (edge list).


{title:Network types}

{pstd}
{bf:Directed:} yes. {bf:Valued:} the tie values of a valued network are written; a binary (unvalued) network is written without tie values (ego and alter only, in GML without {cmd:value}), so that
{help nwimport} reads it back as binary (a two-mode network keeps its form). In UCINET DL a label that contains a blank or a comma is written in double quotes. {bf:Two-mode:} yes - Pajek bipartite form, UCINET rectangular
matrix, edge list with the modes of both nodes, GML attribute {cmd:nwmode}; level labels are kept except in UCINET DL.
{bf:Signed:} not checked. {bf:Temporal:} see below. See {help nwnetworktypes}.{p_end}

{marker temporal}{...}
{title:Temporal networks}

{pstd}
A network declared with {cmd:time()}, {cmd:interval()} or {cmd:eventtime()} in {help nwset} has times that only the edge list can hold.
{cmd:type(edgelist)} writes one row per event (per observation of a tie of a snapshot network, per interval of an interval network) with the
times in the last column(s), tab-delimited and without a header: {it:ego alter} [{it:value}] {it:time} for event and snapshot networks, {it:ego alter} [{it:value}]
{it:start end} for interval networks. The value column is there for a valued network. {help nwimport} reads such a file back with
the type option {cmd:eventtime}, {cmd:time} or {cmd:interval}, and every event, time and value comes back exactly. The file does not say whether a network is directed;
state {cmd:directed} or {cmd:undirected} when importing it.{p_end}

{pstd}
The formats {cmd:pajek}, {cmd:ucinet} and {cmd:gml}, and the edge list of a two-mode network, cannot hold times: for a temporal network the command stops with
error 198 and writes nothing. Specify {opt aggregate} to write the ties of the network aggregated over all times (a tie that is present at any time), as a network that is not temporal;
with {cmd:type(edgelist)}, {opt aggregate} writes the aggregated tie list instead of the times. {help nwsave} keeps the temporal network as it is.{p_end}


{title:Limits}

{pstd}
Every format is written from the ties only and in blocks. Measured in Stata/BE, random directed network with 10 ties per
node: 1,000 / 5,000 / 20,000 nodes in 0.1 / 0.3 / 1.4 seconds (edge list, Pajek, UCINET). Within a Pajek, UCINET or GML file the ties are
ordered by the label of the alter, then of the ego.

 {title:See also}
 
	{help nwimport}, {help nwuse}, {help nwsave}


{title:Examples}

{pstd}
This example loads the {help netexample:Florentine marriage data} and exports to both .DL and .NET format. 

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwexport flomarriage, type(ucinet)}
	{cmd:. nwexport flobusiness, type(pajek)}

{hline}
{pstd}{it:nwcommands version 3.25.0, 14 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
