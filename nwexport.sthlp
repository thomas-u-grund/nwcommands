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
{opt replace}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt type}({it:{help nwexport##exp_type:exp_type}})}{bf:Required.} file format: {cmd:pajek}, {cmd:ucinet}, {cmd:gml} or {cmd:edgelist}{p_end}
{synopt:{opth fn:ame(filename)}}filename of the exported network without the file ending: default = {it:netname}{p_end}
{synopt:{opt replace}}overwrite exported file{p_end}


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
{bf:Directed:} yes. {bf:Valued:} tie values are written. {bf:Two-mode:} yes - Pajek bipartite form, UCINET rectangular
matrix, edge list with the modes of both nodes, GML attribute {cmd:nwmode}; level labels are kept except in UCINET DL.
{bf:Signed:} not checked. See {help nwnetworktypes}.{p_end}


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
{pstd}{it:nwcommands version 3.20.1, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
