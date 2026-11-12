{smcl}
{* *! version 2.0  23aug2014 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##programming:[NW-2.9] Programming}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwvalidate {hline 2}}Validate a network name{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwvalidate} 
{it:{help netname}}

{p2colreset}{...}
	
{title:Description}

{pstd}
Checks if a network {it:{help netname}} already exists. In case it does, 
the command makes a suggestion for an alternative name. Normally, 
the command returns {it:netname_1}. If that also exists, the commands returns {it:netname_2}.



{title:Network types}

{pstd}
The command works the same for every network type (see {help nwnetworktypes}).{p_end}

{title:Examples}

	{cmd:. nwclear}
	{cmd:. nwwebuse florentine}
	{cmd:. nwvalidate flobusiness}
	{cmd:. return list}

	
{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{bf:r(exists)}}"true" when network name already exists, "false" otherwise{p_end}
{synopt:{bf:r(tryname)}}network name that is validated{p_end}
{synopt:{bf:r(validname)}}valid name in case the tryname already exists (otherwise the tryname){p_end}

{hline}
{pstd}{it:nwcommands version 3.21.0, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
