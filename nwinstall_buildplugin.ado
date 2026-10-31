*! version 1.0.0  31oct2026  nwinstall_buildplugin: compile the native plugins of nwcommands, nwsaom, nwergm and nwdynam on this computer
capture program drop nwinstall_buildplugin
program define nwinstall_buildplugin, rclass
	version 14
	syntax [, PKGs(string) FROM(string) RELease(string) DEST(string) KEEP]
	// package -> repository folder, plugin, the files of the build (relative to the repository), the C file that is compiled
	local known "nwcommands nwsaom nwergm nwdynam"
	if "`pkgs'" == "" | "`pkgs'" == "all" local pkgs "`known'"
	if "`pkgs'" == "core" local pkgs "nwcommands"
	foreach p of local pkgs {
		if !`: list p in known' {
			di as err "`p': the plugins that can be built are those of nwcommands, nwsaom, nwergm and nwdynam."
			exit 198
		}
	}
	local plug_nwcommands "nwgraph"
	local plug_nwsaom     "saom_sim"
	local plug_nwergm     "ergm_mcmc"
	local plug_nwdynam    "dynam_sim"
	local files_nwcommands "nwgraph.c nwtypes.h nwcomb.h nwcomb2.h nwfast.h nwfast2.h nwburtw.h nwbrokerage.h nwbmotif_dict.h nwnative370.h nwnative380.h nwnative390.h"
	local files_nwsaom     "saom_sim.c saom_ml.c saom_bayes.c saom_struct.c"
	local files_nwergm     "ergm_mcmc.c ergm_mcmc_e6.h ergm_struct.h"
	local files_nwdynam    "dynam_sim.c"

	// this computer
	local os "`c(os)'"
	if "`os'" == "MacOSX" {
		local platform "macos"
		local target "macos"
		local needs "make clang lipo codesign"
	}
	else if "`os'" == "Unix" {
		local platform "unix"
		local target "unix"
		local needs "make gcc"
	}
	else {
		di as err "nwinstall, buildplugin builds the plugins on macOS and Linux."
		di as err "On Windows use the Visual Studio command line (x64 Native Tools prompt) in the folder native/ of the package; the exact"
		di as err "command is in the file *_native_readme.txt, which {cmd:net get} <package> copies (see {help nwinstall})."
		exit 198
	}
	local base = cond(`"`from'"' == "", "https://raw.githubusercontent.com/thomas-u-grund", `"`from'"')
	local rel = cond("`release'" == "", cond(`"`from'"' == "", "main", ""), "`release'")

	// the tools
	local work "`c(tmpdir)'"
	if substr("`work'", -1, 1) != "/" local work "`work'/"
	local work "`work'nwbuild_`=string(runiformint(100000, 999999))'"
	capture mkdir "`work'"
	foreach t of local needs {
		capture erase "`work'/tool.txt"
		quietly shell command -v `t' > "`work'/tool.txt" 2>&1
		capture confirm file "`work'/tool.txt"
		local ok 0
		if !_rc {
			tempname fh
			file open `fh' using "`work'/tool.txt", read text
			file read `fh' line
			file close `fh'
			if `"`line'"' != "" local ok 1
		}
		if !`ok' {
			di as err "The tool {bf:`t'} was not found."
			if "`os'" == "MacOSX" di as err "On macOS install the command line tools of Xcode: type  xcode-select --install  in the Terminal."
			else di as err "Install a C compiler and make (for example the package build-essential on Debian and Ubuntu)."
			capture shell rm -rf "`work'"
			exit 601
		}
	}

	foreach p of local pkgs {
		local plug "`plug_`p''"
		local out "`plug'_`platform'.plugin"
		local src = cond("`rel'" == "", "`base'/`p'", "`base'/`p'/`rel'")
		local bld "`work'/`p'"
		capture mkdir "`bld'"
		capture mkdir "`bld'/native"
		capture mkdir "`bld'/native/spi"
		di as text _n "{bf:`p'}: plugin {bf:`plug'} for `platform'"
		di as text "  source: `src'/native/"
		// the source files (the layout of the repository is rebuilt, because net get copies all files into one folder)
		local fetch "`files_`p'' Makefile spi/stplugin.c spi/stplugin.h"
		foreach f of local fetch {
			capture copy `"`src'/native/`f'"' `"`bld'/native/`f'"', replace
			if _rc {
				di as err "  the file native/`f' cannot be copied from `src' (error " _rc ")."
				di as err "  Check the internet connection, or from() and release()."
				capture shell rm -rf "`work'"
				exit 601
			}
		}
		// compile with the Makefile of the package
		capture erase "`bld'/ok.txt"
		quietly shell cd "`bld'/native" && make `target' > "`bld'/build.log" 2>&1 && echo ok > "`bld'/ok.txt"
		capture confirm file "`bld'/ok.txt"
		capture confirm file "`bld'/lib/plugins/`platform'/`out'"
		if _rc {
			di as err "  The compiler stopped. The end of the log:"
			capture noisily type "`bld'/build.log"
			if "`keep'" == "" capture shell rm -rf "`work'"
			else di as err "  Build folder kept: `work'"
			exit 9
		}
		quietly shell cd "`bld'/native" && (cc --version 2>/dev/null || gcc --version) | head -1 > "`bld'/cc.txt"
		local ccv ""
		capture {
			tempname fh2
			file open `fh2' using "`bld'/cc.txt", read text
			file read `fh2' ccv
			file close `fh2'
		}
		// install: next to the plugin that net install put into PLUS, or under dest()
		local plus "`c(sysdir_plus)'"
		local ltr = substr("`out'", 1, 1)
		local target_dir = cond(`"`dest'"' == "", "`plus'`ltr'", `"`dest'"')
		capture mkdir `"`target_dir'"'
		capture confirm file `"`target_dir'/`out'"'
		if !_rc {
			// an old copy is kept as .prev; the file is removed first (a rebuilt plugin must not be copied over a loaded one)
			capture copy `"`target_dir'/`out'"' `"`target_dir'/`out'.prev"', replace
			erase `"`target_dir'/`out'"'
		}
		copy `"`bld'/lib/plugins/`platform'/`out'"' `"`target_dir'/`out'"'
		di as text "  compiler: " as result `"`ccv'"'
		di as text "  installed: " as result `"`target_dir'/`out'"'
		return local plugin_`p' `"`target_dir'/`out'"'
		capture findfile `out'
		if !_rc & `"`r(fn)'"' != `"`target_dir'/`out'"' {
			di as text "  note: Stata finds another copy of `out' first: " `"`r(fn)'"'
			di as text "        remove it, or give dest() the folder in which it is."
		}
	}
	if "`keep'" == "" capture shell rm -rf "`work'"
	else di as text _n "Build folder kept: `work'"
	di as text _n "The new plugin is used from the next Stata session. Restart Stata, then check it with {cmd:nwversion}."
end
