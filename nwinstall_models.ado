*! version 1.0.0  24oct2026  nwinstall_models: install, update or remove the model packages nwsaom, nwergm, nwdynam, nwrem
capture program drop nwinstall_models
program define nwinstall_models
	version 14
	syntax [, PKGs(string) RELease(string) FROM(string) REMOVE]
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
