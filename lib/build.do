version 12
clear all
capture mata: mata clear

cd "/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands"
do "/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands/unw_core.do"
do "/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands/unw_ergm.do"
do "/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands/unw_saom.do"
do "/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands/unw_rem.do"
do "/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands/unw_dynam.do"

cd "/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands/lib"
mata: mata mlib create lnwcommands, dir("/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands/lib") replace
mata: mata mlib add lnwcommands *(), dir("/Users/tgrund/FILES_NEW/SOFTWARE/nwcommands/lib")
mata: mata mlib index

mata: mata describe using lnwcommands
