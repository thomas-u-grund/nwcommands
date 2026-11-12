{smcl}
{* *! 21dec2017 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwpreserve {hline 2}}Preserve and restore network data{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

    Preserve network data

{p 8 17 2}{cmd:nwpreserve}


    Restore network data

{p 8 16 2}{cmd:nwrestore}


{marker description}{...}
{title:Description}

{pstd}
{cmd:nwpreserve} preserves network data by temporarily saving the current network dataset (including all normal Stata variables) in the working directory.
Calling {cmd:nwpreserve} again before {cmd:nwrestore}
exits with an error ("Already preserved"), as Stata's own {help preserve} does.

{pstd}
{cmd:nwrestore} restores network data previously preserved (including all Stata variables).


{title:Network types}

{pstd}
The command works the same for every network type (see {help nwnetworktypes}).{p_end}


{title:Examples}

{pstd}
Preserve a network, drop it, then restore it:

	{cmd:. nwclear}
	{cmd:. nwrandom 5, prob(.4) name(mynet)}
	{cmd:. nwpreserve}
	{cmd:. nwdrop mynet}
	{cmd:. nwset}
	{cmd:. nwrestore}
	{cmd:. nwset}


{title:Also see}
   
   {help restore}, {help preserve}

{hline}
{pstd}{it:nwcommands version 3.20.1, 12 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
