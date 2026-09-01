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
{it:{help nwmovie:nwmovie_options}}]

{marker description}{...}
{title:Description}

{pstd}
{cmd:nwmoviexy} is a thin alias for {help nwmovie}: it forwards its entire argument string to
{cmd:nwmovie} unchanged and behaves identically to it in every way. Historically {cmd:nwmoviexy} was
a separate, coordinate-specific implementation (accepting an explicit {cmd:nodexys(varlist)} option
to place nodes at fixed x/y coordinates supplied by the caller). {help nwmovie:nwmovie} itself was
rebuilt on a Cytoscape.js-based rendering pipeline (see that command's own help file) and no longer
has an equivalent option - fixed node positions across waves are now produced automatically via its
own {opt fixedlayout} option (one shared layout computed once and reused every frame) instead of
requiring the caller to supply coordinates. {cmd:nwmoviexy} is kept only as a thin, backward-compatible
alias so existing scripts that call it by name continue to work; it accepts exactly {help nwmovie:nwmovie}'s
own current option set, nothing more.

{pstd}
New code should call {help nwmovie:nwmovie} directly - see its own help file for the complete option
reference and worked examples.

{title:Examples}

{pstd}
Animate two waves of a network (accepts exactly the same arguments as {help nwmovie}):

	{cmd:. nwclear}
	{cmd:. nwrandom 6, prob(.3) name(wave1)}
	{cmd:. nwrandom 6, prob(.3) name(wave2)}
	{cmd:. nwmoviexy wave1 wave2, duration(400)}

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: not checked. Two-mode: not checked - a direct alias for {help nwmovie}; see that command's own identical classification.

{title:See also}

	{help nwmovie}, {help nwplot}

