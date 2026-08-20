version 12
clear all
capture mata: mata clear

cd "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016"
do "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/unw_core.do"

cd "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/lib"
mata: mata mlib create lnwcommands, dir("/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/lib") replace
mata: mata mlib add lnwcommands *(), dir("/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/lib")
mata: mata mlib index

mata: mata describe using lnwcommands
