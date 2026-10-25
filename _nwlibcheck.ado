*! version 3.5.1  25oct2026 _nwlibcheck - clear message when the nwcommands Mata library is missing or cannot be used by this Stata
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwcommands (GPL-3, see the file LICENSE).
* A Mata library (.mlib) compiled by a NEWER Stata than the one running is silently ignored ("... is too new to be run by this version
* of Stata and so was ignored"), and then every Mata function is "not found" (r(3499)). The same happens when the library is not
* installed or not indexed. This program is called by unw_defs (and so by nearly every command) and by the commands that do not call
* it; it costs one global macro test after the first successful call of a session, and one -mata which- before that.
capture program drop _nwlibcheck
program define _nwlibcheck
	version 12
	if "$NW_LIBCHECK_OK" == "1" exit
	* the function looked for; NW_LIBCHECK_TEST lets the test script (cscripts/test_nwlibcheck.do) simulate a missing library
	local fn "nws_create"
	if "$NW_LIBCHECK_TEST" != "" local fn "$NW_LIBCHECK_TEST"
	capture mata: mata which `fn'()
	if _rc {
		capture mata: mata mlib index
		capture mata: mata which `fn'()
	}
	if _rc == 0 {
		* the library is usable; is it the CURRENT one? An old lnwcommands.mlib (for example from an earlier net install in the PLUS
		* folder) can shadow it: it has nws_create() but lacks functions added later (sentinel: a function of this release)
		local sentinel "get_nodenames_from_vector"
		if "$NW_LIBCHECK_SENTINEL" != "" local sentinel "$NW_LIBCHECK_SENTINEL"
		capture mata: mata which `sentinel'()
		if _rc == 0 {
			global NW_LIBCHECK_OK 1
			exit
		}
		di as error "An OLD copy of the nwcommands Mata library (lnwcommands.mlib) is being used: it lacks functions of this version of nwcommands."
		di as error `"Reinstall: net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/") replace"'
		di as error "and then: nwinstall, all"
		di as error "Remove the old copy first (it is probably in your PLUS folder): ado uninstall nwcommands"
		exit 3499
	}
	di as error "The nwcommands Mata library is missing or was built by a newer Stata (your Stata: `c(stata_version)')."
	di as error `"Reinstall: net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/") replace"'
	di as error "and then: nwinstall, all"
	di as error "If you have an old copy in your PLUS folder, remove it first: ado uninstall nwcommands"
	exit 3499
end
