{smcl}
{* *! version 1.0.6  23aug2014 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwexport  {hline 2}}Export network as Pajek, Ucinet, GML or edge list file{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwexport} 
[{it:{help netname}}],
{opt type}({it:{help nwexport##exp_type:exp_type}})
[, {opth fname(filename)}
{opt replace}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth fname(filename)}}filename of the exported network: default = {it:netname}{p_end}
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



{title:Two-mode networks}

{pstd}
Two-mode: yes - Pajek gets the bipartite form (first line {cmd:*Vertices n n1}, the first mode first); UCINET a rectangular matrix with row and column labels; the edge list five columns (ego, alter, value, mode of the ego, mode of the alter); GML the node attribute {cmd:nwmode}. {help nwimport} reads each of the four back as a two-mode network. The level labels of the two modes (for example {it:women} and {it:events}) are kept in three of the formats: Pajek has no place for names of modes, so they are written as a comment line (starting with %) before {cmd:*Vertices}, which Pajek ignores; in GML they are the graph attributes {cmd:nwmodelabel1} and {cmd:nwmodelabel2}; in the edge list the columns of the modes hold the labels instead of 1 and 2 (1 and 2 when the network has no labels of its own). UCINET DL has no place for them: a file read back gets the labels {it:rows} and {it:columns}.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: not checked. Two-mode: yes - Pajek gets the bipartite form (first line {cmd:*Vertices n n1}, the first mode first); UCINET a rectangular matrix with row and column labels; the edge list five columns (ego, alter, value, mode of the ego, mode of the alter); GML the node attribute {cmd:nwmode}. {help nwimport} reads each of the four back as a two-mode network. The level labels of the two modes (for example {it:women} and {it:events}) are kept in three of the formats: Pajek has no place for names of modes, so they are written as a comment line (starting with %) before {cmd:*Vertices}, which Pajek ignores; in GML they are the graph attributes {cmd:nwmodelabel1} and {cmd:nwmodelabel2}; in the edge list the columns of the modes hold the labels instead of 1 and 2 (1 and 2 when the network has no labels of its own). UCINET DL has no place for them: a file read back gets the labels {it:rows} and {it:columns}.

{title:Examples}

{pstd}
This example loads the {help netexample:Florentine marriage data} and exports to both .DL and .NET format. 

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwexport flomarriage, type(ucinet)}
	{cmd:. nwexport flobusiness, type(pajek)}

{title:Limits}

{pstd}
Every format is written from the ties only and in blocks. Measured in Stata/BE, random directed network with 10 ties per
node: 1,000 / 5,000 / 20,000 nodes in 0.1 / 0.3 / 1.4 seconds (edge list, Pajek, UCINET; before: 4.7 seconds at 1,000
nodes, 90 seconds and 11 GB at 5,000 nodes, out of memory at 20,000). Within a Pajek, UCINET or GML file the ties are
ordered by the label of the alter, then of the ego.

 {title:See also}
 
	{help nwimport}, {help nwuse}, {help nwsave}
	
last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.9.2, 26 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
