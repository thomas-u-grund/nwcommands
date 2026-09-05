{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nwtopical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 16 22 2}{...}
{p2col :nwkatz {hline 2}}Calculate a Katz-inspired distance-decay centrality{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwkatz} 
[{it:{help netname}}]
[{cmd:,}
{opt alpha(real)}
{opt walks}
{opt generate}({it:{help varname}})
{opt replace}
{it:{help nwgeodesic:geodesic_options}}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt alpha(real)}}penalization factor for calculation of weights; default = 1 (distance-decay mode) or {bf:0.9/rho} (walk-counting mode, {opt walks}){p_end}
{synopt:{opt walks}}switch to the literature's own genuine walk-counting Katz/Bonacich centrality, {it:(I - alpha*A)^-1 * 1}, instead of this command's own default distance-decay formula (see Description){p_end}
{synopt:{opt generate}({it:{help varname}})}variable name for Katz centrality scores; default =
{it:_katz}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{it:{help nwgeodesic:geodesic_options}}}options for calculating distances (forwarded to
the internal {help nwgeodesic} call); not used when {opt walks} is specified{p_end}


{title:Description}

{pstd}
Calculates a distance-decay centrality measure, inspired by Katz's (1953) attenuation idea, for
each node {it:i} in a network and saves the result as a variable. It is an extension of degree
centrality (see {help nwdegree}): degree centrality counts each node's direct neighbors; this
measure counts all other reachable nodes, but penalizes ones that are further away.

{pstd}
Formally, this command computes:

{pmore}
{it:nwkatz(i) = sum(alpha ^ dist(i,j)), over all j reachable from i}

{pmore}
where {it:dist(i,j)} is the {help nwgeodesic:geodesic (shortest-path) distance} between nodes
{it:i} and {it:j}, and unreachable pairs contribute 0.

{pstd}
{bf:The DEFAULT formula (without {opt walks}) is not the same as the Katz centrality defined in
the literature.} Katz's (1953) original measure counts the total number of {it:walks} of every
length between two nodes, attenuated by {it:alpha} raised to the walk length, and is computed as
{it:(I - alpha*A)^-1 * 1} (a matrix-inverse, eigenvector-family measure closely related to
Bonacich power centrality) - not as a sum over {it:shortest-path distances} the way this command's
own default formula does. The two measures are related in spirit (both attenuate a node's reach by
distance/length) but are mathematically different and will generally give different node rankings,
especially on networks with many alternate paths between the same pair of nodes, since true Katz
centrality credits every walk, not just the shortest one. The default formula's own results are
unchanged from prior versions (preserving backwards compatibility for anyone already relying on
this specific distance-decay measure) - this note exists so the choice of default formula, and its
relationship to the cited reference, is explicit rather than implied by the command name and
citation alone.

{pstd}
{opt walks} switches to the genuine, literature-standard walk-counting Katz/Bonacich formula
instead: {it:x = (I - alpha*A)^-1 * 1}, solved via a linear solve (not an explicit matrix
inverse). {opt alpha()} must then satisfy {it:|alpha| * rho < 1} (rho = the network's own spectral
radius) or the implied infinite walk sum diverges - {cmd:nwkatz} checks this and errors with the
valid range if violated. Default {opt alpha()} in this mode is {bf:0.9/rho}, a conventional
"safely inside the convergent range" choice. Directed networks get separate in/out-walk variants,
the same convention the default distance-decay formula already uses.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - generates separate {it:_in}/{it:_out} variables automatically when the
network is directed (the network is otherwise symmetrized for the underlying distance calculation
unless {help nwgeodesic:geodesic_options} specifies {opt nosym}). Weighted: distances come from
{help nwgeodesic}, which supports valued networks via its own {opt alpha()}/weighting options,
forwarded through this command's {it:geodesic_options}; weight meaning follows whatever
{help nwgeodesic} uses (tie strength inverted into a path cost via the Opsahl et al. formulation -
see {help nwgeodesic} for detail), not tie strength directly. Signed: not checked; negative tie
values are not validated or rejected. Two-mode: not checked.


{title:References}

{pstd}
Katz, L. (1953). A New Status Index Derived from Sociometric Index. {it:Psychometrika}, 39-43.


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwkatz flomarriage}
	{cmd:. sum _katz}


{title:See also}

	{help nwcloseness}, {help nwbetween}, {help nwdegree}, {help nwcloseness}, {help nwevcent}

last certified : 24 Aug 2026
