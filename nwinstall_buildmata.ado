*! version 1.0.0  03nov2026  nwinstall_buildmata: rebuild the Mata libraries of nwcommands, nwsaom, nwergm, nwdynam and nwrem with the Stata that is running
capture program drop nwinstall_buildmata
program define nwinstall_buildmata, rclass
	version 14
	syntax [, PKGs(string) FROM(string) RELease(string) DEST(string) KEEP]
	// Fallback and repair: a Mata library (.mlib) built by a NEWER Stata than the one running is ignored ("too new to be run by this
	// version of Stata", every function "not found", r(3499)). A library built by the Stata that runs always loads. This program
	// fetches the Mata source of each package, compiles it here and installs the libraries over the shipped ones (the old files are
	// kept as .prev). Mata classes carry their compile time: the libraries of nwsaom and nwergm are only accepted by the very core
	// library they were compiled against, so rebuilding the core always rebuilds the installed nwsaom and nwergm libraries too.
	local known "nwcommands nwsaom nwergm nwdynam nwrem"
	local usescore "nwsaom nwergm"
	if "`pkgs'" == "core" local pkgs "nwcommands"
	foreach p of local pkgs {
		if !`: list p in known' & "`p'" != "all" {
			di as err "`p': the Mata libraries that can be built are those of nwcommands, nwsaom, nwergm, nwdynam and nwrem."
			exit 198
		}
	}
	// where the libraries are now (before the build changes the ado path): replace the copy that Stata uses
	local plus "`c(sysdir_plus)'"
	foreach p of local known {
		local inst_`p' 0
		nwinstall_buildmata_tab, pkg(`p')
		local libs_`p' "`r(libs)'"
		foreach l of local libs_`p' {
			capture findfile `l'.mlib
			if !_rc {
				local inst_`p' 1
				local dir_`l' `"`=substr(r(fn), 1, strlen(r(fn)) - strlen("`l'.mlib") - 1)'"'
			}
		}
	}
	// what to build
	local todo ""
	if "`pkgs'" == "" | "`pkgs'" == "all" {
		foreach p of local known {
			if `inst_`p'' | "`p'" == "nwcommands" local todo "`todo' `p'"
		}
	}
	else {
		foreach p of local pkgs {
			local todo "`todo' `p'"
		}
	}
	// the core library changes: every installed library that was compiled against it has to be rebuilt with it
	if `: list posof "nwcommands" in todo' {
		foreach p of local usescore {
			if `inst_`p'' & !`: list p in todo' {
				di as text "Note: {bf:`p'} is installed and was compiled against the core library, so it is rebuilt as well."
				local todo "`todo' `p'"
			}
		}
	}
	local todo : list uniq todo
	local ordered ""
	foreach p of local known {
		if `: list p in todo' local ordered "`ordered' `p'"
	}
	local todo "`ordered'"

	// the build clears the data and the Mata objects (not -clear all-: that would drop this program)
	if c(N) > 0 | c(k) > 0 {
		di as err "The build clears everything in memory (data and Mata objects, including loaded networks). Save what you need, type {cmd:clear all}, and run it again."
		exit 4
	}
	local base = cond(`"`from'"' == "", "https://raw.githubusercontent.com/thomas-u-grund", `"`from'"')
	local rel = cond("`release'" == "", cond(`"`from'"' == "", "main", ""), "`release'")
	local work "`c(tmpdir)'"
	if substr("`work'", -1, 1) != "/" local work "`work'/"
	local work "`work'nwbuildmata_`=string(runiformint(100000, 999999))'"
	capture mkdir "`work'"
	di as text "Building with Stata {bf:`c(stata_version)'} (`c(os)'). This clears memory and takes a few minutes."

	clear
	mata: mata clear
	// the folders of the libraries now in use go to the build routine in global macros (paths may contain blanks)
	foreach p of local known {
		foreach l of local libs_`p' {
			global NWBM_dir_`l' `"`dir_`l''"'
		}
	}
	local pwd0 `"`c(pwd)'"'
	capture noisily nwinstall_buildmata_run, todo(`todo') work(`work') base(`base') rel(`rel') dest(`dest') plus(`plus')
	local rc = _rc
	local built "`r(built)'"
	quietly cd `"`pwd0'"'
	capture adopath - "`work'/nwcommands/lib"
	foreach p of local known {
		foreach l of local libs_`p' {
			global NWBM_dir_`l'
		}
	}
	global NW_LIBCHECK_OK
	if "`keep'" == "" capture shell rm -rf "`work'"
	else di as text _n "Build folder kept: `work'"
	if `rc' exit `rc'
	return local built "`built'"
	di as text _n "The new libraries are used from the next Stata session. Restart Stata, then check them with {cmd:nwversion}."
end

capture program drop nwinstall_buildmata_tab
program define nwinstall_buildmata_tab, rclass
	// source files (the first one is run; it may include the others), library files and the contents of each library (as lib/build.do
	// of each package). A new Mata source file of a package has to be added here.
	syntax , PKG(string) [LIB(string)]
	if "`pkg'" == "nwcommands" return local src "unw_core.do"
	if "`pkg'" == "nwcommands" return local libs "lnwcommands"
	if "`pkg'" == "nwsaom"     return local src "unw_saom.do unw_saom_struct.do"
	if "`pkg'" == "nwsaom"     return local libs "lnwsaom1 lnwsaom2"
	if "`pkg'" == "nwergm"     return local src "unw_ergm.do"
	if "`pkg'" == "nwergm"     return local libs "lnwergm"
	if "`pkg'" == "nwdynam"    return local src "unw_dynam.do"
	if "`pkg'" == "nwdynam"    return local libs "lnwdynam"
	if "`pkg'" == "nwrem"      return local src "unw_rem.do"
	if "`pkg'" == "nwrem"      return local libs "lnwrem"
	if "`lib'" == "lnwsaom1" return local add "stat*() Saom*()"
	else if "`lib'" == "lnwsaom2" return local add "change*() _*() sn*() saom*() mm*()"
	else if "`lib'" != "" return local add "*()"
end

capture program drop nwinstall_buildmata_run
program define nwinstall_buildmata_run, rclass
	version 14
	syntax , TODO(string) WORK(string) BASE(string) PLUS(string) [REL(string) DEST(string)]
	local built ""
	foreach p of local todo {
		nwinstall_buildmata_tab, pkg(`p')
		local srcs "`r(src)'"
		local src : word 1 of `srcs'
		local libs "`r(libs)'"
		local srcurl = cond("`rel'" == "", "`base'/`p'", "`base'/`p'/`rel'")
		local bld "`work'/`p'"
		capture mkdir "`bld'"
		capture mkdir "`bld'/lib"
		di as text _n "{bf:`p'}: Mata source {bf:`srcs'}"
		di as text "  source: `srcurl'/"
		foreach f of local srcs {
			capture copy `"`srcurl'/`f'"' `"`bld'/`f'"', replace
			if _rc {
				di as err "  the file `f' cannot be copied from `srcurl' (error " _rc ")."
				di as err "  Check the internet connection, or from() and release()."
				exit 601
			}
		}
		// the classes of nwsaom and nwergm are compiled against the finished core library (the new one, if it was built here)
		mata: mata clear
		if "`p'" == "nwcommands" {
			// unw_core.do calls unw_defs, which calls _nwlibcheck: the library that is being built need not exist yet
			global NW_LIBCHECK_OK 1
		}
		quietly cd "`bld'"
		di as text "  compiling ..."
		quietly do "`src'"
		foreach l of local libs {
			nwinstall_buildmata_tab, pkg(`p') lib(`l')
			local add "`r(add)'"
			quietly mata: mata mlib create `l', dir("`bld'/lib") replace
			quietly mata: mata mlib add `l' `add', dir("`bld'/lib")
			quietly mata: mata mlib index
			if "`p'" == "nwcommands" {
				// the models that follow are compiled against this library
				mata: mata clear
				quietly adopath ++ "`bld'/lib"
				quietly mata: mata mlib index
			}
		}
		// install: over the copy that Stata uses (next to the library that net install put into PLUS), or under dest()
		foreach l of local libs {
			capture confirm file `"`bld'/lib/`l'.mlib"'
			if _rc {
				di as err "  the library `l'.mlib was not created."
				exit 601
			}
			local ltr "l"
			local tdir `"`dest'"'
			if `"`tdir'"' == "" local tdir `"${NWBM_dir_`l'}"'
			if `"`tdir'"' == "" local tdir `"`plus'`ltr'"'
			capture mkdir `"`tdir'"'
			capture confirm file `"`tdir'/`l'.mlib"'
			if !_rc {
				// the old copy is kept as .prev; the file is removed first (a loaded library must not be copied over)
				capture copy `"`tdir'/`l'.mlib"' `"`tdir'/`l'.mlib.prev"', replace
				erase `"`tdir'/`l'.mlib"'
			}
			copy `"`bld'/lib/`l'.mlib"' `"`tdir'/`l'.mlib"'
			di as text "  installed: " as result `"`tdir'/`l'.mlib"'
			local built "`built' `l'"
			return local lib_`l' `"`tdir'/`l'.mlib"'
		}
	}
	return local built "`built'"
end
