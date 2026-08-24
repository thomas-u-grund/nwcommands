/***
{smcl}
{* *! version 2.1  13may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 14 22 2}{...}
{p2col :nwuse  {hline 2}}Load Stata network dataset{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwuse} 
{it:{help filename}}
[{cmd:,}
{cmd:clear}]

{p 8 17 2}
{cmdab: nwwebuse} 
{it:{help netexample}}
[{cmd:,}
{cmd:nwclear}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt nwclear}}clear memory before loading dataset{p_end}
{synopt:{opt nwappend}}append to existing data{p_end}

        
{title:Description}

{pstd}
{bf:nwuse} loads a Stata network dataset previously saved with {help nwsave}. This includes all networks and Stata variables. If {it:{help filename}}
is specified without an extension, {bf:.nwdta} is assumed. If your {it:filename} contains embedded spaces, remember to enclose
it in double quotes.

     
{title:Examples}
        
{pstd}
This example creates 5 new random networks and {help nwsave:saves} them as {it:mynets}.A new dataset called {it:mynets.nwdta} is created in the working directory with the networks and all Stata variables.

        {cmd:. nwclear}
        {cmd:. nwrandom 20, ntimes(5) prob(.2)}
        {cmd:. nwsave mynets}
		{cmd:. nwclear}

{pstd}
One can bring the data back with:
	
        {cmd:. nwuse mynets}
		
{pstd}
This load the Florentine dataset from the internet and appends it to the existing data.

        {cmd:. nwwebuse florentine, nwappend}       
        
{title:See also}

        {help nwwebuse}, {help nwsave}, {help use}, {help nwappend}
***/
capture program drop nwuse
program nwuse
	syntax anything [, nwclear nwappend force *]
	local basename = subinstr(`"`anything'"', ".nwdta","",999)
	local basename = subinstr(`"`basename'"', ".dta","",999)

	tempfile existing
	capture save `existing'
	local have_existing = (_rc == 0)

	`nwclear'
	qui nwset
	if "`nwappend'" == "" & (`r(networks)' > 0 | "`r(networks)'" == "") {
		di "{err}No; data in memory would be lost. Specify either option {bf:nwclear} or {bf:nwappend}."
		error 999
	}

	qui if "`nwappend'" != "" {
		capture qui nwcurrent
		local current "`r(current)'"
	}

	// BUGFIX: this used to unconditionally force a ".nwdta" suffix onto
	// every target (local or web), so any of this package's own example
	// datasets that are plain .dta files rather than a genuine nwsave()
	// restoration file (gang2/hpotter/institutions/klas12b/stockholm/
	// usstates/example1 - see netexample.sthlp, which already advertises
	// `nwwebuse usstates`/`nwwebuse klas12b`/etc. as the intended way to
	// load them) could never be loaded via nwuse/nwwebuse at all - it
	// always tried to fetch a nonexistent "<name>.nwdta" and
	// crashed, well before ever reaching the confirm-variable check
	// below that would have been the natural place to detect a plain
	// dataset. Only florentine/gang/glasgow actually ship a .nwdta
	// counterpart (confirmed against the data host's own listing).
	// Fixed to try .nwdta first (the common, documented case: a network
	// saved with nwsave), falling back to plain .dta - and, if loaded
	// that way, skipping the network-restoration logic entirely rather
	// than crashing on the missing _nw_* metadata columns.
	capture use `"`basename'.nwdta"'
	if _rc != 0 {
		capture use `"`basename'.dta"'
		if _rc != 0 {
			if `have_existing' {
				use `existing'
			}
			di "{err}could not load {bf:`basename'} as either a saved network ({bf:.nwdta}) or a plain dataset ({bf:.dta})"
			error 601
		}
		di "{txt}(plain Stata dataset loaded - not a saved {help nwsave:network} file; build a network from it directly, e.g. with {help nwfromedge} or {help nwgenerate})"
		exit
	}

	confirm variable _nw_format _nw_nets _nw_netname _nw_size _nw_directed _nw_twomode _nw_selfloop _nw_title
	// _nw_modes/_nw_mode1desc/_nw_mode2desc are a newer addition (mode
	// membership was never actually saved before, despite the bare
	// is-two-mode flag surviving correctly - see nwsave.ado's own
	// comment for the full explanation) - not required here, unlike
	// the columns above, so that a .nwdta file saved before this fix
	// existed still loads cleanly; it just has no mode data to
	// restore (exactly the same "do not silently reinterpret old
	// data" principle new2mode() below already follows for is2mode).
	capture confirm variable _nw_modes
	local has_modes = (_rc == 0)
	capture confirm variable _nw_mode1desc
	local has_mode1desc = (_rc == 0)
	capture confirm variable _nw_mode2desc
	local has_mode2desc = (_rc == 0)
	capture confirm variable _nw_provenance
	local has_provenance = (_rc == 0)
	local f = _nw_format[1]
	local nets = _nw_nets[1]
	// check if network names already exist
	qui forvalues i = 1/`nets' {
		nwvalidate `=_nw_netname[`i']'
		di `"if "`r(exists)'" == "true" & "`force'" == "" "'
		if "`r(exists)'" == "true" & "`force'" == "" {
			noi di "{err}network {it:`r(tryname)'} already exists; use option {bf:force}"
			if `have_existing' {
				use `existing'
			}
			error 999
		}
	}
	
	qui forvalues i = 1/`nets' {
		preserve
		local n = _nw_netname[`i']
		local s = _nw_size[`i']
		local d = _nw_directed[`i']
		local t = _nw_twomode[`i']
		local sl = _nw_selfloop[`i']
		local tl = _nw_title[`i']
		local v = _nw_valued[`i']
		local md ""
		local m1d ""
		local m2d ""
		local prov ""
		if `has_modes' local md = _nw_modes[`i']
		if `has_mode1desc' local m1d = _nw_mode1desc[`i']
		if `has_mode2desc' local m2d = _nw_mode2desc[`i']
		if `has_provenance' local prov = _nw_provenance[`i']
		keep if _nw_match_`n'_nw_ego == 1
		// BUGFIX: this used to pass `n' (the raw, saved network name)
		// straight through as an explicit name() to nwfromedge - fine
		// as long as `n' is guaranteed not to collide, which used to be
		// true whenever execution reaches here (a hard collision on any
		// network name aborts this whole command earlier, at the
		// "already exists; use option force" check above, unless
		// `force' was given). Once nwfromedge.ado's own name()
		// collision guard was tightened (harmonisation unit 116: an
		// explicit name() collision now errors unless replace is also
		// given, rather than silently auto-incrementing) that stopped
		// being true for the one case this command's own `force' option
		// exists to support: `nwappend ..., force' deliberately allows
		// loading a network whose name already exists in memory,
		// auto-renumbering it (see cscripts/test_nwappend.do's own
		// "mynet1_1" case) rather than either erroring or replacing the
		// existing one - nwfromedge's new guard doesn't know that's
		// wanted and errors (6099) instead. Resolved here instead of by
		// passing replace (which would destroy the existing network
		// under that name, not what `force' means for nwappend):
		// nwvalidate's own r(validname) already implements exactly the
		// "same name if free, else auto-incremented" logic wanted -
		// resolving it BEFORE calling nwfromedge means nwfromedge is
		// only ever asked to create under a name confirmed not to
		// collide, so its own guard is never triggered. `ncreate' (not
		// `n') is used for every reference to the newly created network
		// for the remainder of this loop iteration, below.
		nwvalidate `n'
		local ncreate = r(validname)
		nwfromedge _nw_ego _nw_alter `n', name("`ncreate'")
		// BUGFIX: `_nw_netname' is a LOCAL-macro reference to a local
		// literally named "_nw_netname", which is never defined
		// anywhere in this loop - `_nw_netname' is the STATA VARIABLE
		// holding each row's network name, and `n' (set above from
		// _nw_netname[`i']) is the already-correct local for it. The
		// undefined-local reference silently expands to "" (Stata does
		// not error on an undefined local), so nwname/nwsym below were
		// being called *bare* - operating on whatever network happened
		// to be "current" at that instant rather than explicitly this
		// iteration's network. Found via a direct probe (set trace on)
		// while tracking down why a projected network's new provenance
		// metadata wasn't surviving a save/reload round-trip - the same
		// bug silently affected every other newXXX() field passed here
		// (new2mode/newselfloop/newtitle/newvalued/newmodes/
		// newmode1desc/newmode2desc) too, though it happened to go
		// unnoticed for those because "current" usually already matched
		// the intended network by the time this specific line ran.
		// BUGFIX: was "newvalued("``v'")" - a stray extra backtick left
		// the literal text "`false"/"`true" (backtick included) being
		// passed to newvalued() instead of the plain string, which
		// nwname.ado's own option processing didn't recognize -
		// confirmed directly via `set trace on`, the actual root cause
		// of this command's own long-documented "error in loading"
		// crash on every dataset that reaches this line (i.e. every
		// genuine .nwdta restoration - previously undiagnosed beyond
		// "some macro-quoting mismatch").
		nwname `ncreate', new2mode("`t'") newselfloop("`sl'") newtitle("`tl'") newvalued("`v'") newmodes(`"`md'"') newmode1desc(`"`m1d'"') newmode2desc(`"`m2d'"') newprovenance(`"`prov'"')
		if "`d'"  == "false" {
			nwsym `ncreate'
		}
		restore
	}
	
	if _rc != 0 {
		di "{err}error in loading"
		error 999
	}
	
	qui keep if _nwnode != ""
	qui capture drop _nw_*
	
	nw_syntax _all, max(99999)
	qui foreach onenet in `netname' {
		capture drop `onenet'
	}
	
	qui if "`nwappend'" != "" {
		capture merge 1:1 _nwnode using `existing', nogenerate
		capture order _nwnode _nwinclude
		nwcurrent `current'
	}
end
