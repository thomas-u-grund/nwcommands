{smcl}
{* *! version 1.0.6  23aug2014 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwexport  {hline 2}}Export network as Pajek or Ucinet file{p_end}
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
		
		
{title:Description}

{pstd}
Exports a network to either 1) Pajek .NET or 2) Ucinet .DL file format. Only exports one network and no node level
attributes. By default, the
new network file is saved in the working directory. When no {opt fname} is specified, the program calls the new file {it:netname.dl} (Ucinet) or
{it:netname.net} (Pajek).



{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: not checked. Two-mode: not checked - exports the network to Pajek/UCINET format largely as stored; consult the target format's own documentation for what it can represent.

{title:Examples}

{pstd}
This example loads the {help netexample:Florentine marriage data} and exports to both .DL and .NET format. 

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwexport flomarriage, type(ucinet)}
	{cmd:. nwexport flobusiness, type(pajek)}

 {title:See also}
 
	{help nwimport}, {help nwuse}, {help nwsave}
	
last certified : 24 Aug 2026
