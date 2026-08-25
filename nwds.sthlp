{smcl}
{* *! version 1.0.0  24aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_utility:[NW-2.7] Utility Commands}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwds {hline 2}}List loaded networks, in the style of Stata's own {help ds}{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwds}
[{it:{help netlist}}]
[{cmd:,}
{opt alpha}
{opt not}
{it:ds_options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt alpha}}List network names in alphabetical order (the default is creation order){p_end}
{synopt:{opt not}}Invert the selection - list every {it:other} loaded network instead of the ones
named in {it:netlist}{p_end}
{synopt:{it:ds_options}}Any other option is forwarded to Stata's own {help ds} (e.g. {opt varwidth},
which controls the display's own column width){p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwds} lists the networks currently loaded in memory, reusing Stata's own {help ds} command for
the display (network names are shown the way {cmd:ds} shows variable names). With no {it:netlist}, every
loaded network is listed. {bf:r(netlist)} always returns the exact list of network names shown.

{title:Supported network types}

{pstd}
Not applicable - a pure network-listing utility (in the style of Stata's own {help ds}); does not read or depend on any network's own content, directed/valued/two-mode status, or tie values.

{title:Stored results}

	Macros
	  {bf:r(netlist)}		the exact list of network names shown

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwds}
	{cmd:. nwds, alpha}

{title:See also}

	{help ds}, {help nwcurrent}, {help nwclear}

last certified : 24 Aug 2026
