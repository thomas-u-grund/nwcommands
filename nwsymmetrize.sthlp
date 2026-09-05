{smcl}
{* *! harmonisation phase: naming-convention alias author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 27 2}{...}
{p2col :nwsymmetrize {hline 2}}Symmetrize network (alias for {help nwsym}){p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 22 2}
{cmdab: nwsymmetrize}
[{it:{help netname}}]
[{cmd:,}
{opt mode}({it:{help nwsym##mode:mode}})
{opt check}
{opth generate(newnetname)}
{opt replace}]

{title:Description}

{pstd}
{cmd:nwsymmetrize} is an exact alias for {help nwsym} - it forwards every argument and option
unchanged and returns the identical stored results. It exists only so the verb {cmd:symmetrize}
is directly discoverable by name, matching the package's spelled-out-verb naming convention used
elsewhere (e.g. {help nwcollapse}, {help nwexpand}, {help nwrecode}). {help nwsym} itself is
unaffected and remains fully supported - see its own help file for the complete option
reference, mode() details, and worked examples.

{title:Supported network types}

{pstd}
Identical to {help nwsym} - see that command's help file.

{title:Examples}

{pstd}
This loads the Glasgow data and symmetrizes the network {it:glasgow1}, identically to
{cmd:nwsym glasgow1}.

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwsymmetrize glasgow1}

{title:Stored results}

{pstd}
See {help nwsym}.

last certified : 28 Aug 2026
