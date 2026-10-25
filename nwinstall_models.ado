*! version 1.1.0  25oct2026  nwinstall_models: install, update or remove the model packages nwsaom, nwergm, nwdynam, nwrem
capture program drop nwinstall_models
program define nwinstall_models
	version 14
	syntax [, PKGs(string) RELease(string) FROM(string) REMOVE STOP PREflight COREver(string)]
	local known "nwsaom nwergm nwdynam nwrem"
	if "`pkgs'" == "" local pkgs "`known'"
	foreach p of local pkgs {
		if !`: list p in known' {
			di as err "`p' is not a model package of nwcommands (nwsaom nwergm nwdynam nwrem)."
			exit 198
		}
	}
	// from(): a folder or URL that holds one subfolder per package (default: the GitHub repositories); with from() and no
	// release() the package folder itself is used (local clones, offline installs)
	local rel = cond("`release'" == "", cond(`"`from'"' == "", "main", ""), "`release'")
	local base = cond(`"`from'"' == "", "https://raw.githubusercontent.com/thomas-u-grund", `"`from'"')
	local failed ""
	// preflight (used by nwinstall, everything before anything is installed): is each package reachable, and does it need a newer core?
	if "`preflight'" != "" {
		foreach p of local pkgs {
			local src = cond("`rel'" == "", "`base'/`p'/", "`base'/`p'/`rel'/")
			tempfile pk
			capture copy `"`src'`p'.pkg"' `"`pk'"', replace
			if _rc {
				di as err "nwinstall, everything: the model package `p' cannot be reached at `src' (error " _rc ")."
				di as err "Nothing has been installed. Check the internet connection or from()/release(), or install the core alone with: nwinstall, all"
				exit 601
			}
			nwinstall_reqcore, file(`"`pk'"')
			if "`r(req)'" != "" & "`corever'" != "" {
				local req "`r(req)'"
				nwinstall_vnum `req'
				local rq = r(n)
				nwinstall_vnum `corever'
				if `rq' > r(n) {
					di as err "nwinstall, everything: the model package `p' needs nwcommands (core) version `req' or later, but the core to be installed is version `corever'."
					di as err "Nothing has been installed. Install a newer core, or choose an older release() of the model packages."
					exit 498
				}
			}
		}
		exit
	}
	foreach p of local pkgs {
		if "`remove'" != "" {
			capture ado uninstall `p'
			di as text "`p': " cond(_rc == 0, "removed", "was not installed")
			continue
		}
		local src = cond("`rel'" == "", "`base'/`p'/", "`base'/`p'/`rel'/")
		di as text _n "Installing {bf:`p'}" cond("`rel'" == "", "", " (`rel')") " from `src' ..."
		capture net install `p', from("`src'") replace
		if _rc {
			di as err "  could not install `p' (error " _rc "). The repository may be private or the release may not exist."
			local failed "`failed' `p'"
			if "`stop'" != "" {
				di as err "nwinstall, everything stopped at the model package `p'; the core and the packages before it are installed."
				exit 601
			}
		}
		else {
			capture noisily which `p'
		}
	}
	// Stata indexes the Mata libraries once, early in a session; index again so the libraries just installed are found
	// (the model entry points repeat this check themselves). Harmless if it fails.
	if "`remove'" == "" {
		capture mata: mata mlib index
	}
	if "`remove'" == "" & "`failed'" == "" {
		di as text _n "Model packages installed. Each has a version command, e.g. {stata nwsaom version}."
		di as text "They are free software (GPL-3) and are installed separately from the nwcommands core;"
		di as text "updating nwcommands never overwrites them."
	}
	if "`failed'" != "" exit 601
end


capture program drop nwinstall_reqcore
program nwinstall_reqcore, rclass
	// the core version a model .pkg requires: line "d Requires nwcommands (core), version X.Y.Z or later"
	syntax , file(string)
	tempname fh
	local req ""
	file open `fh' using `"`file'"', read text
	file read `fh' line
	while r(eof) == 0 {
		if strpos(`"`line'"', "Requires nwcommands (core), version ") {
			local t = substr(`"`line'"', strpos(`"`line'"', "version ") + 8, .)
			local req : word 1 of `t'
		}
		file read `fh' line
	}
	file close `fh'
	return local req "`req'"
end

capture program drop nwinstall_vnum
program nwinstall_vnum, rclass
	// X.Y.Z -> a comparable number
	args v
	local v = subinstr("`v'", ".", " ", .)
	local a : word 1 of `v'
	local b : word 2 of `v'
	local c : word 3 of `v'
	foreach x in a b c {
		if "``x''" == "" local `x' 0
	}
	return scalar n = `a' * 1000000 + `b' * 1000 + `c'
end
