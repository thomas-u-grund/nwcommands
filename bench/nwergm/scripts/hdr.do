* SCR: the scratch folder holding the installed trees (set the environment variable SCR before starting Stata)
global SCR : env SCR
clear all
set more off
capture program drop nwinstall
sysdir set PLUS "$SCR/ergmspeed/plus"
sysdir set PERSONAL "$SCR/ergmspeed/plus/pers"
adopath ++ "$SCR/r391"
adopath ++ "$SCR/r391/lib"
adopath ++ "$SCR/r391/lib/plugins/macos"
adopath ++ "$NWERGM"
adopath ++ "$NWERGM/lib"
adopath ++ "$NWERGM/lib/plugins/macos"
