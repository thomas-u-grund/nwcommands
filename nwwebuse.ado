*! Date        : 23oct2015
*! Version     : 2.2
*! Author      : Thomas Grund, University College Dublin
*! Email	   : thomas.u.grund@gmail.com
*
* GitHub migration (2026-08-23): the default $nwwebpath rerouted from the
* now-dead nwcommands.org host to this project's own new GitHub repository
* (raw.githubusercontent.com), resolving a gap previously logged in
* docs/CERTIFICATION.md's own Pending list ("nwcommands.org's own data host
* is dead"). Points at the "master" branch (the current, tested release
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
	syntax anything [, * nwclear]

	`nwclear'
	capture drop _running

	local subcommand = word("`anything'",1)
	local path = "\$nwwebpath"
	local thispath = "`path'"

	if "`subcommand'" != "set" {
		if "`thispath'" == "" | "`thispath'" == "\" {
			global nwwebpath = "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data"
		}
	}

	if "`subcommand'" == "set" {
		local subcmd2 = word("`anything'",2)
		if  "`subcmd2'" == "" {
			global nwwebpath = "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data"
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

	local path = "\$nwwebpath"
	local thispath = "`path'"
	local webname = subinstr("`anything'", ".dta","",99)
	if substr("`webname'",1,4) == "http" {
		nwuse `webname', `options'
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
