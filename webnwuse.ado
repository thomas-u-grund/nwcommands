*! Date        : 23oct2015
*! Version     : 2.1
*! Author      : Thomas Grund, University College Dublin
*! Email	   : thomas.u.grund@gmail.com
*
* GitHub migration (2026-08-23): the default $nwwebpath rerouted from the
* now-dead nwcommands.org host to this project's own new GitHub repository
* (raw.githubusercontent.com), resolving a gap previously logged in
* docs/CERTIFICATION.md's own Pending list ("nwcommands.org's own data host
* is dead"). Points at the `develop` branch specifically (the actually
* current, complete branch - `master` was found to be a stale, diverged
* legacy line during this same migration, NOT simply an older point on the
* same history) - a user can still override via `webnwuse set <path>` at
* any time, and `$nwwebpath` remains the single, centralized place this
* would need to change again (e.g. to a versioned/tagged path for a future
* stable release) rather than a hardcoded literal scattered across files.

capture program drop webnwuse
program webnwuse
	syntax anything [, * nwclear old]
	
	`nwclear'
	capture drop _running 
	
	local subcommand = word("`anything'",1)
	local path = "\$nwwebpath"
	local thispath = "`path'"
	
	if "`subcommand'" != "set" {
		if "`thispath'" == "" | "`thispath'" == "\" {
			global nwwebpath = "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop/data"
		}
	}
	
	if "`subcommand'" == "set" {
		local subcmd2 = word("`anything'",2)
		if  "`subcmd2'" == "" {
			global nwwebpath = "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop/data"
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
	if "`old'" != "" {
		local old "_old"
	}
	local webname = subinstr("`anything'", ".dta","",99)
	if substr("`webname'",1,4) == "http" {
		nwuse`old' `webname', `options'
	}
	else {
		nwuse`old' `thispath'/`webname', `options'
	}
	qui nwload, labelonly
end
