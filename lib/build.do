* Builds lib/lnwcommands.mlib (core Mata library) from unw_core.do.
* Run from the repository root:  do lib/build.do
* (the model packages nwergm, nwsaom, nwdynam, nwrem build their own libraries.)
version 12
local root "`c(pwd)'"
capture confirm file "`root'/unw_core.do"
if _rc {
    display as error "run lib/build.do from the repository root (the folder containing unw_core.do)"
    exit 601
}
clear all
capture mata: mata clear

cd "`root'"
do "`root'/unw_core.do"

cd "`root'/lib"
mata: mata mlib create lnwcommands, dir("`root'/lib") replace
mata: mata mlib add lnwcommands *(), dir("`root'/lib")
mata: mata mlib index

mata: mata describe using lnwcommands
cd "`root'"
