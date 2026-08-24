{smcl}
{* *! version 1.0.0  24aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##visualization:[NW-2.8] Visualization}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwmoviexy {hline 2}}Animate a sequence of networks (alias for {bf:nwmovie}){p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab: nwmoviexy}
{it:{help netlist}}
[{cmd:,}
{it:{help nwmovie##movie_options:movie_options}}
{it:{help nwmovie##switch_options:switch_options}}
{it:{help nwmovie##time_options:time_options}}
{it:{help nwplot:nwplot_options}}
{it:{help twoway_options}}]

{marker description}{...}
{title:Description}

{pstd}
{cmd:nwmoviexy} is an alias for {help nwmovie} - the two commands accept the exact same syntax and options
and behave identically, including the {opt nodexys(varlist)} option for placing nodes at fixed x/y
coordinates across every time point (rather than letting the layout algorithm reposition them each
frame). Historically {cmd:nwmoviexy} was a separate, coordinate-specific implementation; once
{help nwmovie:nwmovie} itself gained {opt nodexys()}, the two became functionally identical, and
{cmd:nwmoviexy} is now kept only as a thin, backward-compatible alias so existing scripts that call it
by name continue to work.

{pstd}
New code should call {help nwmovie:nwmovie} directly - see its own help file for the complete option
reference, requirements (ImageMagick), and worked examples.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: not checked. Two-mode: not checked - a direct alias for {help nwmovie}; see that command's own identical classification.

{title:See also}

	{help nwmovie}, {help nwplot}

