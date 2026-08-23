*! version 1.0.0  28aug2008
capture program drop _gnwdegree
program define _gnwdegree
	version 11
	gettoken type 0 : 0
	gettoken h    0 : 0 
	gettoken eqs  0 : 0

	//_egennoby nwdegree() `"`by'"'
	
	//syntax [anything(name=netname)] [, *]
	//nw_syntax `netname'
	
	//nwdegree `netname', generate(`h')
	di "hhh2aå"
	qui gen `type' `h' = 5
end
exit

