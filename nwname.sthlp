{smcl}
{* *! version 2.0  13may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##information:[NW-2.4] Information}
{marker top2}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwname {hline 2}}Obtain and change meta-information of a network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwname} 
[{it:{help netname}}]
[,{opth id(int)}
{opth newname(newnetname)}
{opth newtitle(string)}
{opt newdirected(boolean)}
{opt new2mode(boolean)}
{opt newvalued(boolean)}
{opt newselfloop(boolean)}
{opth newlabsfromvar(varname)}
]

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth id(int)}}network ID{p_end}
{synopt:{opt newname}({help newnetname})}new name of the network{p_end}
{synopt:{opth newtitle(string)}}new title of the network{p_end}
{synopt:{opt newdirected}(boolean)}force change: directed = {it:true}, not directed = {it:false}{p_end}
{synopt:{opt newd2mode}(boolean)}force change: twomode = {it:true}, not twomode = {it:false}{p_end}
{synopt:{opt newvalued}(boolean)}force change: valued = {it:true}, unvalued = {it:false}{p_end}
{synopt:{opt newselfloop}(boolean)}force change: selfloops = {it:true}, no selfloops = {it:false}{p_end}
{synopt:{opth newlabsfromvar(varname)}}new node labels (saved in Stata variable){p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwname} obtains and changes the meta-information of a network.



{title:Supported network types}

{pstd}
Not applicable in the usual sense - this command reports and *sets* a network's own directed/valued/two-mode/self-loop status and other metadata directly; it is the mechanism by which those properties are themselves declared, not something whose behavior varies by them.

{title:Examples}

{pstd}
This loads the Florentine data and returns various information about the {it:flobusiness} network.
	
	{cmd:. nwwebuse florentine}
	{cmd:. nwname flobusiness}
	{cmd:. return list}

{pstd}
This changes the name of the network {it:flobusiness} into {it:flob}. This could also be achieved with {help nwrename}.
	
	{cmd:. nwname flobusiness, newname(flob)}
	{cmd:. return list}  
	  
 {title:See also}
 
	{help nwsummarize}, {help nwset}, {help nwload}
last certified : 24 Aug 2026
