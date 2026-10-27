* SCR: the scratch folder holding the installed trees (set the environment variable SCR before starting Stata)
global SCR : env SCR
* Local header of the check scripts: released trees, scratch PLUS. Set global NWERGM before calling to use another nwergm tree (default: v1.3.0).
clear all
set more off
capture program drop nwinstall
local scr "$SCR"
if "$NWERGM" == "" global NWERGM "`scr'/ergm130"
if "$PLUSDIR" == "" global PLUSDIR "`scr'/paperw130"
capture mkdir "$PLUSDIR"
capture mkdir "$PLUSDIR/plus"
capture mkdir "$PLUSDIR/pers"
sysdir set PLUS "$PLUSDIR/plus"
sysdir set PERSONAL "$PLUSDIR/pers"
adopath ++ "`scr'/r3100"
adopath ++ "`scr'/r3100/lib"
adopath ++ "`scr'/r3100/lib/plugins/macos"
adopath ++ "$NWERGM"
adopath ++ "$NWERGM/lib"
adopath ++ "$NWERGM/lib/plugins/macos"
