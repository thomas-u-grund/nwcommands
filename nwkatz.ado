/***
{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 16 22 2}{...}
{p2col :nwkatz {hline 2} Calculate a Katz-inspired distance-decay centrality}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwkatz} 
[{it:{help netname}}]
[{cmd:,}
{opt alpha(real)}
{opt generate}({it:{help varname}})
{opt replace}
{it:{help nwgeodesic:geodesic_options}}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt alpha(real)}}penalization factor for calculation of weights; default = 1{p_end}
{synopt:{opt generate}({it:{help varname}})}variable name for Katz centrality scores; default =
{it:_katz}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{it:{help nwgeodesic:geodesic_options}}}options for calculating distances (forwarded to
the internal {help nwgeodesic} call){p_end}


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
{bf:This is not the same formula as the Katz centrality defined in the literature.} Katz's (1953)
original measure counts the total number of {it:walks} of every length between two nodes,
attenuated by {it:alpha} raised to the walk length, and is computed as {it:(I - alpha*A)^-1 * 1}
(a matrix-inverse, eigenvector-family measure closely related to Bonacich power centrality) - not
as a sum over {it:shortest-path distances} the way this command does. The two measures are related
in spirit (both attenuate a node's reach by distance/length) but are mathematically different and
will generally give different node rankings, especially on networks with many alternate paths
between the same pair of nodes, since true Katz centrality credits every walk, not just the
shortest one. This command's existing formula and stored results are unchanged from prior versions
(preserving backwards compatibility for anyone already relying on this specific distance-decay
measure) - this note exists so the choice of formula, and its relationship to the cited reference,
is explicit rather than implied by the command name and citation alone. A genuine walk-counting
Katz centrality implementation remains a documented gap (see {browse "docs/ROADMAP.md":the project
roadmap}).


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
Katz, L. (1953). A New Status Index Derived from Sociometric Index. Psychometrika, 39-43.


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwkatz flomarriage}
	{cmd:. sum _katz}


{title:See also}

	{help nwcloseness}, {help nwbetween}, {help nwdegree}, {help nwcloseness}, {help nwevcent}

***/
capture program drop nwkatz
program nwkatz
	version 9
	syntax [anything(name=netname)] , [ alpha(real 1)  GENerate(string) replace *]

	nw_syntax `netname', max(1)
	local origdirected "`directed'"
	nw_datasync `netname'

	local original `netname'
	if "`generate'" == "" {
		local generate = "_katz"
	}

	// `replace' was previously absorbed by the trailing `*' catch-all
	// (which populates `options', never a local literally named
	// `replace') rather than being declared as a real option, so this
	// guard could never actually see it - `replace' silently never
	// worked. Also: the guard printed an error but never called
	// error/exit, so execution continued regardless and could silently
	// clobber (or crash later inside getmata on) an existing variable.
	// Both fixed here.
	if "`directed'" == "false" {
		capture confirm variable `generate'
		if _rc == 0 & "`replace'" == "" {
			di "{err}Variable {bf:`generate'} already exists; use {bf:replace}"
			error 110
		}
		local generate_all `generate'
	}
	else {
		local generate_all ""
		foreach c in `generate'_in `generate'_out {
			capture confirm variable `c'
			if _rc == 0 & "`replace'" == "" {
				di "{err}Variable {bf:`c'} already exists; use {bf:replace}"
				error 110
			}
			local generate_all `generate_all' `c'
		}
	}

	tempname geo
	// `options' forwards whatever geodesic_options the caller supplied
	// (as documented in the syntax block above) - previously declared
	// via the trailing `*' but never actually passed through, so e.g.
	// alpha()/unconnected() on the underlying nwgeodesic call were
	// silently ignored regardless of what the user specified.
	// nwreplace here (nwgeodesic's own option, unrelated to nwkatz's own
	// replace guard above) is required even though `geo' is a fresh
	// tempname: Stata's tempname counter is scoped per top-level command
	// invocation, not session-globally unique, so calling nwkatz twice
	// in a row can allocate the identical underlying name (confirmed via
	// direct trace) - nwgeodesic's own "name already exists" guard would
	// otherwise intermittently fire on this purely-internal scratch
	// network, depending on what tempname counter state happens to be
	// active. This scratch network is dropped again a few lines below
	// regardless, so always allowing nwgeodesic to overwrite it here is
	// safe.
	qui nwgeodesic `netname', name(`geo') nwreplace `options'
	nw_syntax `geo'
	// nwreplace's own expression parser (nw_expnetexp.ado) treats its
	// input as plain Stata-style arithmetic text and translates it into
	// Mata syntax via naive string substitution (e.g. every "*" becomes
	// " :* ", every "^" becomes " :^ "). It was never designed to accept
	// raw Mata object/pointer syntax such as (*netobj->get_matrix()) -
	// passing that here (as this line previously did) mangles the "*"
	// dereference and "->" method-call operators into nonsense along
	// with the alpha exponentiation, producing a genuine "invalid
	// expression" Mata error on every call. Confirmed via direct trace
	// before fixing - this was broken end to end, not merely for
	// non-integer alpha; there was no prior test coverage to catch it.
	// Fixed by doing the alpha^distance transform directly in Mata and
	// writing it back via the network's own set_edge() method (which
	// correctly invalidates the sparse index), instead of routing a
	// pointer-dereference expression through nwreplace's string-based
	// translator at all.
	tempname __nw_katz
	mata: `__nw_katz' = `alpha' :^ (*`netobj'->get_matrix())
	mata: _editmissing(`__nw_katz', 0)
	mata: `netobj'->set_edge(`__nw_katz')
	mata: mata drop `__nw_katz'

	// getmata's parenthetical-expression form does not accept a raw
	// pointer-dereference expression either (confirmed via an isolated
	// repro before fixing: "invalid vector or matrix name") - assign to
	// a plain Mata variable first, matching the one form getmata is
	// documented and confirmed to actually accept. Also drop any
	// existing target variable(s) first: the guard above only errors
	// when the variable exists AND replace was not given - when replace
	// *was* given, getmata would otherwise still fail on the
	// still-present variable, since getmata has no overwrite option of
	// its own.
	if "`origdirected'" == "true" {
		capture drop `generate'_out
		capture drop `generate'_in
		tempname __nw_out __nw_in
		// This package's own row=source/column=target adjacency
		// convention (confirmed against get_outdegree()/get_indegree()
		// in unw_core.do) means "out" reach is a ROW sum (how far node i
		// can reach others) and "in" reach is a COLUMN sum (how
		// reachable node i is from others) - the previous version had
		// these swapped, verified by hand on a small A->B, A->C example
		// (A's true out-reach summed to 1.0, but the swapped code
		// returned 0 for it).
		mata: `__nw_out' = rowsum(*`netobj'->get_matrix())
		mata: `__nw_in' = colsum(*`netobj'->get_matrix())'
		getmata `generate'_out = `__nw_out'
		getmata `generate'_in = `__nw_in'
		mata: mata drop `__nw_out' `__nw_in'
	}
	else {
		capture drop `generate'
		tempname __nw_all
		mata: `__nw_all' = rowsum(*`netobj'->get_matrix())
		getmata `generate' = `__nw_all'
		mata: mata drop `__nw_all'
	}

	capture nwdrop `geo'

	mata: st_rclear()
	di "{hline 40}"
	di "{txt}  Katz centrality"
	di "{txt}  Network name: {res}`original'"
	if "`sym'" == "" {
		di "{txt}	Network has been symmetrized for calculation.{txt}"
	}
	di "{hline 40}"
	di "{txt}	Alpha: {res}`alpha'"

	sum `generate_all'
end
