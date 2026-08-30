{smcl}
{* *! harmonisation phase: naming-convention alias author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 27 2}{...}
{p2col :nwproject {hline 2}}One-mode projection of a two-mode network (alias for {help nw2project}){p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwproject}
[{it:{help netname}}]
{cmd:,}
{opt project(1|2)}
[{opth name(newnetname)}
{opt stat(string)}
{opt xvars}
{opt replace}]

{title:Description}

{pstd}
{cmd:nwproject} is an exact alias for {help nw2project} - it forwards every argument and option
unchanged and returns the identical stored results. It exists purely for discoverability: unlike
{help nw2set}/{help nw2fromedge}/{help nw2toedge}/{help nw2degree}/{help nw2clustering} (whose
{cmd:nw2} prefix genuinely disambiguates a one-mode command from a same-purpose two-mode-specific
sibling), a one-mode {cmd:nwproject} could never exist - projecting only makes sense starting from
a two-mode source - so there is no ambiguity for the {cmd:nw2} prefix to resolve here, only an
unnecessary naming inconsistency with the rest of the "transformation grammar" family
({help nwcollapse}, {help nwexpand}, {help nwfromedge}, {help nwtoedge}), none of which carry a
{cmd:nw2} prefix. {help nw2project} itself is unaffected and remains fully supported - see its own
help file for the complete option reference, the {opt stat()} formulas, and worked examples.

{title:Examples}

{pstd}
Build a small two-mode network (3 people x 2 events) and project it onto mode 1 (people):

	{cmd:. nwclear}
	{cmd:. mata: net = (1,0 \ 1,1 \ 0,1)}
	{cmd:. nw2set, mat(net) name(attendance)}
	{cmd:. nwproject attendance, project(1) name(people_net)}
	{cmd:. nwsummarize people_net, matonly}

{title:Supported network types}

{pstd}
Identical to {help nw2project} - see that command's help file.

{title:Stored results}

{pstd}
See {help nw2project}.

last certified : 28 Aug 2026
