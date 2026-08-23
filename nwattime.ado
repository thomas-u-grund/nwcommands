/***
{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwattime {hline 2}}Static graph view of a temporal network at a given time{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwattime}
[{it:{help netname}}]
{cmd:,}
{opt at(#)}
[{opth name(newnetname)}
{opt xvars}
{opt replace}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt at(#)}}The timepoint to slice at{p_end}
{synopt:{opth name(newnetname)}}Name of the new static network; default = {it:atview}{p_end}
{synopt:{opt xvars}}Generate Stata variables for the new network{p_end}
{synopt:{opt replace}}Replace an existing network of the same name{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwattime} takes a temporal network (declared via {help nwset}'s {bf:time()}, {bf:interval()}, or
{bf:eventtime()} options) and produces an ordinary, static one-mode network containing only the ties
active at the requested timepoint - the "temporal network -> select edges active at t -> static graph
view -> ordinary nw algorithm" model: the resulting network is a completely normal network, usable with
any existing {bf:nw*} command exactly as if it had never been temporal at all. This is deliberate
groundwork, not a full temporal-network modelling system - see {help nwset##temporal:nwset}'s own
temporal section for what is and is not supported yet.

{pstd}
The slicing rule depends on the source network's own temporal semantics:

{p 8 12 2}{bf:snapshot}{p_end}
{p 12 12 2}a tie is active at {it:t} when its own recorded time equals {it:t} exactly{p_end}
{p 8 12 2}{bf:interval}{p_end}
{p 12 12 2}a tie is active at {it:t} when {it:start} <= {it:t} < {it:end} - the documented convention.
A tie with a missing {it:end} (an ongoing tie with no recorded end date) is treated as open-ended
and stays active for every {it:t} from its {it:start} onward. A missing {it:start} is not specially
handled and excludes the tie{p_end}
{p 8 12 2}{bf:event}{p_end}
{p 12 12 2}an exact-timestamp match: every event recorded at precisely {it:t} becomes a binary tie in
the static view. This is the one place an event network is allowed to become a persistent graph in
this package, and only because {it:t} was explicitly requested - no windowing or aggregation across a
range of timestamps is done (not yet supported){p_end}

{pstd}
For example, a network declared with {cmd:nwset ego alter, time(wave)} can be sliced to the ties that
existed in wave 2:

	{cmd:. nwattime mynet, at(2) name(wave2)}

{title:Stored results}

	Scalars
	  {bf:r(ties)}		number of ties in the static view
	  {bf:r(at)}		the timepoint sliced at


{title:Supported network types}

{pstd}
Binary: yes. Directed: preserved from the source network. Weighted: preserved from the source network's
own tie values (the slice selects which ties are active, it does not change their values). Signed: not
checked. Two-mode: not yet supported as a source (see {help nwset}'s own note that {bf:time()}/
{bf:interval()}/{bf:eventtime()} cannot currently be combined with {bf:twomode}/{bf:bipartite} - tracked
in docs/ROADMAP.md as a composability item for a later pass).


{title:See also}

	{help nwset}, {help nwsummarize}

***/

capture program drop nwattime
program nwattime, rclass
	version 12
	syntax [anything(name=netname)], AT(real) [name(string) xvars replace]

	nw_syntax `netname'

	if "`istemporal'" != "true" {
		di "{err}Network {bf:`netname'} is not temporal; nwattime requires a network declared via {help nwset}'s {bf:time()}, {bf:interval()}, or {bf:eventtime()} options."
		error 198
	}

	if "`name'" == "" {
		local name "atview"
	}
	nw_validate `name'
	if "`r(exists)'" == "true" {
		if "`replace'" == "" {
			di "{txt}Warning! Switched to netname {res}`r(validname)'{txt} because {res}`name'{txt} already in use."
			local name = r(validname)
		}
		else {
			capture nwdrop `name'
		}
	}

	// captured from the SOURCE network's own netobj/name before both
	// are reassigned to the newly-created static-view network below -
	// mirrors nw2project.ado's own established pattern for exactly the
	// same reason (the second nw_syntax call below overwrites `netname'
	// itself, not just `netobj' - confirmed via a direct probe: without
	// this capture, the display and provenance note both silently
	// showed the NEW network's own name instead of the source's).
	local srcnetname "`netname'"
	local srctemporaltype "`temporaltype'"
	tempname __srcnames __edges
	mata: `__srcnames' = `netobj'->get_nodenames()
	mata: st_local("srcdirected", strofreal(`netobj'->is_directed_boolean()))
	mata: st_local("srcvalued", strofreal(`netobj'->is_valued_boolean()))

	if "`temporaltype'" == "snapshot" {
		mata: `__edges' = nwattime_slice_snapshot(`netobj', `at')
	}
	else if "`temporaltype'" == "interval" {
		mata: `__edges' = nwattime_slice_interval(`netobj', `at')
	}
	else {
		mata: `__edges' = nwattime_slice_event(`netobj', `at')
	}

	mata: st_numscalar("ties", rows(`__edges'))

	mata: nw.nws.add("`name'")
	nw_syntax `name'
	mata: `netobj'->create_by_name_sparse(`__srcnames')
	// BUGFIX (see docs/CERTIFICATION.md unit 42): create_by_name_sparse()
	// wipes `name' via its own internal zap() call - nwset.ado's own
	// create_by_name() caller already re-sets it immediately afterward
	// for exactly this reason, mirrored here.
	mata: `netobj'->set_name("`name'")
	mata: `netobj'->set_directed(`srcdirected')
	mata: `netobj'->set_edge_from_triplets(`__edges'[.,1], `__edges'[.,2], `__edges'[.,3], `srcdirected')
	mata: `netobj'->set_valued(`srcvalued')
	mata: `netobj'->set_provenance("static graph view of `srcnetname' at t=`at' (`srctemporaltype')")

	mata: mata drop `__srcnames' `__edges'

	return scalar ties = ties
	return scalar at = `at'

	di "{hline 40}"
	di "{txt}  Static graph view: {res}`name'"
	di "{txt}  Source network: {res}`srcnetname'{txt} ({res}`srctemporaltype'{txt})"
	di "{txt}  At: {res}`at'"
	di "{txt}  Ties: {res}`=ties'"

	if "`xvars'" != "" {
		nwload `name'
	}
end
