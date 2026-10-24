clear all
set more off
adopath ++ "."
quietly do unw_core.do
quietly do unw_ergm.do
do cscripts/test_nwergm_structural.do
