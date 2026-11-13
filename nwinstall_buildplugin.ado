*! version 1.1.0  09nov2026  nwinstall_buildplugin: compile the native plugins of nwcommands, nwsaom, nwergm and nwdynam on this computer
*! 1.1.0: builds on Windows too, with Microsoft's free C compiler (Build Tools for Visual Studio), found with vswhere
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
			di as err "{p 0 0 2}`p': the plugins that can be built are those of nwcommands, nwsaom, nwergm and nwdynam.{p_end}"
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
	// console Stata on macOS reports c(os) = "Unix"; c(machine_type) still starts with "Mac" (3.20.1)
	if "`os'" == "Unix" & substr(c(machine_type), 1, 3) == "Mac" local os "MacOSX"
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
	else if "`os'" == "Windows" {
		local platform "windows"
		local needs ""
		nwinstall_buildplugin_msvc
		local vcvars `"`r(vcvars)'"'
	}
	else {
		di as err "{p 0 0 2}nwinstall, buildplugin builds the plugins on macOS, Linux and Windows; this computer is `os'.{p_end}"
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
			if "`os'" == "MacOSX" di as err "{p 0 0 2}On macOS install the command line tools of Xcode: type{space 2}xcode-select --install{space 2}in the Terminal.{p_end}"
			else di as err "{p 0 0 2}Install a C compiler and make (for example the package build-essential on Debian and Ubuntu).{p_end}"
			nwinstall_buildplugin_rmdir "`work'"
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
				di as err "{p 2 2 2}the file native/`f' cannot be copied from `src' (error " _rc ").{p_end}"
				di as err "  Check the internet connection, or from() and release()."
				nwinstall_buildplugin_rmdir "`work'"
				exit 601
			}
		}
		capture mkdir "`bld'/lib"
		capture mkdir "`bld'/lib/plugins"
		capture mkdir "`bld'/lib/plugins/`platform'"
		if "`platform'" == "windows" {
			// Visual Studio's compiler, with the command of the package's automatic build (plus /O2 and /nologo)
			local b = char(92)
			local bw = subinstr("`bld'", "/", "`b'", .)
			tempname bh
			file open `bh' using "`bld'/build.bat", write text replace
			file write `bh' "@echo off" _n
			file write `bh' `"call "`vcvars'" > nul"' _n
			file write `bh' `"cd /d "`bw'`b'native""' _n
			file write `bh' `"cl 2> "`bw'`b'cc.txt""' _n
			file write `bh' `"cl /nologo /LD /O2 /DSYSTEM=STWIN32 /I spi `plug'.c spi`b'stplugin.c /Fe:..`b'lib`b'plugins`b'windows`b'`out' > "`bw'`b'build.log" 2>&1"' _n
			file close `bh'
			quietly shell "`bw'`b'build.bat"
		}
		else {
			// compile with the Makefile of the package
			quietly shell cd "`bld'/native" && make `target' > "`bld'/build.log" 2>&1
		}
		capture confirm file "`bld'/lib/plugins/`platform'/`out'"
		if _rc {
			di as err "  The compiler stopped. The end of the log:"
			capture noisily type "`bld'/build.log"
			if "`keep'" == "" nwinstall_buildplugin_rmdir "`work'"
			else di as err "  Build folder kept: `work'"
			exit 9
		}
		if "`platform'" != "windows" quietly shell cd "`bld'/native" && (cc --version 2>/dev/null || gcc --version) | head -1 > "`bld'/cc.txt"
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
			capture erase `"`target_dir'/`out'.prev"'
			if "`platform'" == "windows" {
				// Windows cannot erase a plugin that this Stata has loaded, but it can rename it
				local tw = subinstr(`"`target_dir'/`out'"', "/", char(92), .)
				quietly shell move /y "`tw'" "`tw'.prev" > nul
			}
			else {
				capture copy `"`target_dir'/`out'"' `"`target_dir'/`out'.prev"', replace
				erase `"`target_dir'/`out'"'
			}
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
	if "`keep'" == "" nwinstall_buildplugin_rmdir "`work'"
	else di as text _n "Build folder kept: `work'"
	di as text _n "{p 0 0 2}The new plugin is used from the next Stata session. Restart Stata, then check it with {cmd:nwversion}.{p_end}"
end

// Windows: find Microsoft's C compiler (Build Tools for Visual Studio, or Visual Studio with C++) with vswhere, which every
// installation has; r(vcvars) is the script that sets up the compiler. Without it, say what to install and stop.
capture program drop nwinstall_buildplugin_msvc
program define nwinstall_buildplugin_msvc, rclass
	local vswhere ""
	foreach d in "C:/Program Files (x86)" "C:/Program Files" {
		capture confirm file "`d'/Microsoft Visual Studio/Installer/vswhere.exe"
		if !_rc & "`vswhere'" == "" local vswhere "`d'/Microsoft Visual Studio/Installer/vswhere.exe"
	}
	local vcvars ""
	if "`vswhere'" != "" {
		// through a batch file: cmd mangles a command line with more than one quoted path
		tempfile vs
		local vw = subinstr("`vswhere'", "/", char(92), .)
		local bat "`c(tmpdir)'/nwvswhere_`=subinstr("`c(current_time)'", ":", "", .)'.bat"
		tempname bh
		file open `bh' using "`bat'", write text replace
		file write `bh' "@echo off" _n
		file write `bh' `""`vw'" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath > "`vs'""' _n
		file close `bh'
		quietly shell "`=subinstr("`bat'", "/", char(92), .)'"
		capture erase "`bat'"
		tempname fh
		capture file open `fh' using "`vs'", read text
		if !_rc {
			file read `fh' line
			file close `fh'
			local line = strtrim(`"`line'"')
			if `"`line'"' != "" {
				capture confirm file `"`line'/VC/Auxiliary/Build/vcvars64.bat"'
				if !_rc local vcvars = subinstr(`"`line'/VC/Auxiliary/Build/vcvars64.bat"', "/", char(92), .)
			}
		}
	}
	if `"`vcvars'"' == "" {
		di as err "{p 0 0 2}Building the plugin on Windows needs Microsoft's free C compiler, which was not found on this computer.{p_end}"
		di as err "Install it once (it is free, and needs no Visual Studio licence):"
		di as err `"  1. Download Build Tools for Visual Studio and run the installer:"'
		di as err `"     {browse "https://visualstudio.microsoft.com/visual-cpp-build-tools/":https://visualstudio.microsoft.com/visual-cpp-build-tools/}"'
		di as err `"{p 2 5 2}2. Tick {bf:Desktop development with C++} and click Install (a download of a few gigabytes).{p_end}"'
		di as err `"{p 2 5 2}3. Then type the same {cmd:nwinstall, buildplugin()} command again; Stata does not need to be restarted.{p_end}"'
		di as err "{p 0 0 2}If Visual Studio itself is installed, add the workload Desktop development with C++ to it in the Visual Studio Installer.{p_end}"
		exit 601
	}
	di as text "C compiler: Microsoft C/C++ (" as result `"`vcvars'"' as text ")"
	return local vcvars `"`vcvars'"'
end

// remove the build folder (rm -rf; rmdir /s /q on Windows)
capture program drop nwinstall_buildplugin_rmdir
program define nwinstall_buildplugin_rmdir
	args dir
	if "`c(os)'" == "Windows" quietly shell rmdir /s /q "`=subinstr("`dir'", "/", char(92), .)'"
	else quietly shell rm -rf "`dir'"
end
