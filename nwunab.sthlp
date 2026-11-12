{smcl}
{* *! version 1.0.0  9sept2014}{...}
{marker topic}
{helpb nwtopical##programming:[NW-2.9] Programming}

{p2colset 9 15 19 2}{...}
{p2col :{cmd:nwunab} {hline 2}}Unabbreviate network list{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{pstd}
Expand and unabbreviate {help netlist:network lists}

{p 8 13 2}{cmd:nwunab} {it:lmacname} {cmd::} {it:{help netlist}} [{cmd:,}
        {cmd:min(}{it:#}{cmd:)} {cmd:max(}{it:#}{cmd:)}]


{marker description}{...}
{title:Description}

{pstd}
This is the network version of {help unab}. {cmd:nwunab} expands
and unabbreviates a {help netlist:netlist} of existing networks,
placing the results in the local macro {it:lmacname}.  {cmd:nwunab} is a
low-level parsing command and works in exactly the same way as {help unab}.  One can
also use {help nwds} to unabbreviate network lists. The 
{help nwprogramming##syntax:_nwsyntax} command is a high-level parsing
command that, among other things, also unabbreviates network lists; see
{help nwprogramming##syntax:_nwsyntax}.


{marker options}{...}


{title:Options}

{phang}{cmd:min(}{it:#}{cmd:)} specifies the minimum number of networks
allowed. The default is {hi:min(1)}.

{phang}{cmd:max(}{it:#}{cmd:)} specifies the maximum number of networks
allowed. By default the limit of {help unab} applies.


{title:Network types}

{pstd}
The command works the same for every network type (see {help nwnetworktypes}).{p_end}


{marker examples}{...}
{title:Examples}

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwunab nets : glasg*}
	{cmd:. di `nets'}
	     {txt}glasgow1 glasgow2 glasgow3


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(netlist)}}the expanded list of networks{p_end}
{synopt:{bf:r(networks)}}number of networks in the list{p_end}


{title:See also}

	{help unab}, {help nwds}, {help nwprogramming##syntax:_nwsyntax}

{hline}
{pstd}{it:nwcommands version 3.21.0, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
