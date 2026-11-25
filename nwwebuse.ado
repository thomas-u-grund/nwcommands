*! Date        : 23oct2015
*! Version     : 2.2
*! Author      : Thomas Grund, RWTH Aachen University
*! Email	   : thomas.u.grund@gmail.com
*
* GitHub migration (2026-08-23): the default $nwwebpath rerouted from the
* now-dead nwcommands.org host to this project's own new GitHub repository
* (raw.githubusercontent.com), resolving a gap previously logged in
* docs/CERTIFICATION.md's own Pending list ("nwcommands.org's own data host
* is dead"). Points at the "main" branch (the current, tested release
* branch users are told to install from) - a user can still override via
* `nwwebuse set <path>` at any time, and `$nwwebpath` remains the single,
* centralized place this would need to change again (e.g. to a
* versioned/tagged path for a future stable release) rather than a
* hardcoded literal scattered across files.
*
* webnwuse/nwwebuse consolidation (2026-08-23): this command used to be a
* one-line wrapper around webnwuse.ado, which held the real implementation -
* backwards from every other command pair in this package (the shorter,
* more consistently-named form should be the real one). webnwuse.ado/
* webnwuse.sthlp are gone; this file now holds the actual implementation
* directly, and every doc-header example/cross-reference across the
* package was updated from `webnwuse` to `nwwebuse` in the same pass.

capture program drop nwwebuse
program nwwebuse
	// The former `old' option dispatched to a command literally named
	// `nwuse_old' - never a real Stata idiom the way `save'/`saveold' is
	// (contrast nwsave.ado's own `old' option) - which was archived to
	// old/ado/ as a confirmed dead-on-arrival duplicate during an earlier
	// harmonisation cleanup, so `old' has raised a hard "command not
	// found" on every use since. Its underlying legacy metadata format
	// (bare _format/_nets/... Stata variables) predates even the plain-
	// .dta fallback nwuse.ado already handles natively today (see that
	// file's own _nw_format/_nw_nets/... convention), and no such
	// old-format dataset remains hosted at $nwwebpath - removed outright
	// rather than reviving a triply-obsolete path with no current use
	// case.
	syntax anything [, * nwclear NETWORKdata SCHoch]
	_nwlibcheck

	// The networkdata collection (R package by David Schoch, github.com/schochastics/networkdata): "nwwebuse networkdata karate" or
	// "nwwebuse karate, networkdata". The data are not part of nwcommands; the command nwnetworkdata downloads them from the
	// author's repository (options such as name() and element() are passed on). The keyword schoch of 3.35 is an alias.
	local nwwu_kw = word(`"`anything'"', 1)
	if inlist("`nwwu_kw'", "networkdata", "schoch") {
		local anything = trim(substr(trim(`"`anything'"'), strlen("`nwwu_kw'") + 1, .))
		local networkdata networkdata
	}
	if "`schoch'" != "" local networkdata networkdata
	if "`networkdata'" != "" {
		capture which nwnetworkdata
		if _rc {
			di as err "{p 0 0 2}the command {bf:nwnetworkdata} was not found; it is part of nwcommands (reinstall the core, see {help nwinstall}){p_end}"
			exit 111
		}
		// no name (or ", list"): what the collection offers and how to see all of it
		if `"`anything'"' == "" {
			di as txt "{p 0 0 2}The networkdata collection (R package by David Schoch, 990 R objects = 2,274 networks), loaded with {bf:nwwebuse networkdata} {it:name}; the data are not part of nwcommands and are downloaded from the author's repository when you ask for a network (no R is needed).{p_end}"
			di as txt "{p 2 2 2}{bf:nwwebuse networkdata list}{space 12}all data sets ({bf:nwnetworkdata list} has filters: directed, undirected, twomode, weighted, ...){p_end}"
			di as txt "{p 2 2 2}{bf:nwwebuse networkdata describe} {it:name}{space 1}type, size, attributes; source and citation{p_end}"
			di as txt "{p 2 2 2}{bf:nwwebuse networkdata karate}{space 6}Zachary's karate club (34 nodes){p_end}"
			di as txt "{p 2 2 2}{bf:nwwebuse networkdata southern_women}{space 1}two-mode: 18 women, 14 events{p_end}"
			di as txt "{p 2 2 2}{bf:nwwebuse networkdata sampson}{space 4}10 directed networks of monks ({bf:element(3)} for one){p_end}"
			di as txt "{p 0 0 2}Help: {help nwnetworkdata}; cite Schoch (2022), doi:10.5281/zenodo.7189928, and the original source of the data set.{p_end}"
			exit
		}
		if "`nwclear'" != "" local options `options' nwclear
		if trim(`"`options'"') != "" nwnetworkdata `anything', `options'
		else nwnetworkdata `anything'
		exit
	}

	// nwclear is carried out by nwuse, which does so only when the file could be loaded
	local __nwwu_clear "`nwclear'"

	// Default source (since 3.18.1): the copy of data/ that the website deploy serves at nwcommands.org/examples
	// (short addresses in output such as "Contains data from ..."); GitHub main is the fallback.
	local default "https://nwcommands.org/examples"
	local github "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/data"
	local subcommand = word("`anything'",1)
	local path = "\$nwwebpath"
	local thispath = "`path'"

	if "`subcommand'" != "set" {
		if "`thispath'" == "" | "`thispath'" == "\" {
			global nwwebpath = "`default'"
		}
	}

	if "`subcommand'" == "set" {
		local subcmd2 = word("`anything'",2)
		if  "`subcmd2'" == "" {
			global nwwebpath = "`default'"
		}
		else {
			global nwwebpath = word("`anything'",2)
		}
		exit
	}
	if "`subcommand'" == "query" {
		di `"{txt}(prefix now "{bf:$nwwebpath}")"'
		exit
	}

	if "`__nwwu_clear'" != "" local options `options' nwclear
	local path = "\$nwwebpath"
	local thispath = "`path'"
	local webname = subinstr("`anything'", ".dta","",99)
	if substr("`webname'",1,4) == "http" {
		nwuse `webname', `options'
	}
	else if "`thispath'" == "`default'" {
		// the website can be unreachable (no connection to it, a deploy in progress): check with a 29-byte file
		// and load the same data set from GitHub if the check fails
		tempfile probe
		capture copy "`default'/pajek_example.net" "`probe'"
		if _rc {
			di as txt "{p 0 0 2}(nwcommands.org could not be reached; loading the data set from GitHub, which stays the source for this session){p_end}"
			// switch the source for the session, so that files merged with "$nwwebpath/..." come from the same place
			global nwwebpath "`github'"
			nwuse `github'/`webname', `options'
		}
		else nwuse `thispath'/`webname', `options'
	}
	else {
		nwuse `thispath'/`webname', `options'
	}
	// Several of this package's own example datasets are plain .dta
	// files, not a saved nwsave() network (see nwuse.ado's own comment)
	// - nwuse already detects that case and leaves the plain dataset
	// loaded as-is, with no network for `nwload' to act on. Wrapped in
	// `capture' so that case exits cleanly instead of surfacing
	// `nwload''s own "no current network" error as if this command had
	// failed.
	capture qui nwload, labelonly
end
