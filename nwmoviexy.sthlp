{smcl}
{* *! version 1.0.0  24aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##visualization:[NW-2.8] Visualization}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwmoviexy {hline 2}}Animate a sequence of networks (alias for nwmovie){p_end}
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
{cmd:nwmovie} unchanged and behaves identically to it in every way; it accepts exactly {help nwmovie:nwmovie}'s
option set, nothing more. Fixed node positions across waves are produced by {cmd:nwmovie}'s
{opt fixedlayout} option (one shared layout computed once and reused every frame).

{pstd}
New code should call {help nwmovie:nwmovie} directly - see its own help file for the complete option
reference and worked examples.


{title:Network types}

{pstd}
{bf:Directed:} yes. {bf:Valued:} the layouts use the tie values and the values set the line widths; {opt binary}
switches that off (see {help nwplot##valuedlayout:nwplot}). {bf:Two-mode:} yes - a symbol and a colour per mode.
{bf:Signed:} negative ties are dashed in a second colour ({opt nosign} is passed on). See {help nwnetworktypes}.{p_end}


{title:Examples}

{pstd}
Animate two waves of a network (accepts exactly the same arguments as {help nwmovie}):

	{cmd:. nwclear}
	{cmd:. nwrandom 6, prob(.3) name(wave1)}
	{cmd:. nwrandom 6, prob(.3) name(wave2)}
	{cmd:. nwmoviexy wave1 wave2, duration(400)}


{title:See also}

	{help nwmovie}, {help nwplot}

{hline}
{pstd}{it:nwcommands version 3.23.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
