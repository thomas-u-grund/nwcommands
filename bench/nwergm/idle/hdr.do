* SCR: the scratch folder holding the installed trees (set the environment variable SCR before starting Stata)
global SCR : env SCR
clear all
set more off
capture program drop nwinstall
sysdir set PLUS "$SCR/idle/plus"
sysdir set PERSONAL "$SCR/idle/plus/pers"
adopath ++ "$SCR/r3100"
adopath ++ "$SCR/r3100/lib"
adopath ++ "$SCR/r3100/lib/plugins/macos"
adopath ++ "$NWERGM"
adopath ++ "$NWERGM/lib"
adopath ++ "$NWERGM/lib/plugins/macos"
