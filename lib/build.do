* Builds lib/lnwcommands.mlib (core Mata library) from unw_core.do.
* Run from the repository root:  do lib/build.do
* (the model packages nwergm, nwsaom, nwdynam, nwrem build their own libraries.)
version 12
* BUILD GUARD: Mata libraries must be built with the OLDEST supported Stata (currently Stata 17), never with a newer one: a library
* compiled by a newer Stata is silently ignored by older Stata versions ("compiled by Stata 18.0, is too new to be run by this version
* of Stata and so was ignored"), and every function is then "not found" (r(3499)). Set NW_ALLOW_NEWER_STATA=1 only for experiments
* whose library is never released.
local nw_minbuild 17
local nw_allow : env NW_ALLOW_NEWER_STATA
if c(stata_version) > `nw_minbuild' & "`nw_allow'" != "1" {
    di as error "this library must be built with Stata `nw_minbuild' (the oldest supported version), but this is Stata " c(stata_version) ". A library built by a newer Stata cannot be used by older Stata versions."
    di as error "Run the build with Stata `nw_minbuild' (see RELEASING.md, 'Build the Mata libraries with the oldest supported Stata'); NW_ALLOW_NEWER_STATA=1 overrides this for experiments."
    exit 198
}
local root "`c(pwd)'"
capture confirm file "`root'/unw_core.do"
if _rc {
    display as error "run lib/build.do from the repository root (the folder containing unw_core.do)"
    exit 601
}
clear all
capture mata: mata clear
* unw_core.do calls unw_defs, which calls _nwlibcheck: the library that is being built need not exist yet
global NW_LIBCHECK_OK 1

cd "`root'"
do "`root'/unw_core.do"

cd "`root'/lib"
mata: mata mlib create lnwcommands, dir("`root'/lib") replace
mata: mata mlib add lnwcommands *(), dir("`root'/lib")
mata: mata mlib index

mata: mata describe using lnwcommands
global NW_LIBCHECK_OK
cd "`root'"
