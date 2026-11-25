*! _nwreservedname: a network cannot be called like one of Stata's reserved words or like the node variables; other commands
*! then read the name as something else (a network called _all stops every command that works on all networks).
capture program drop _nwreservedname
program _nwreservedname
	args name
	if inlist(`"`name'"', "_all", "_n", "_N", "_pi", "_cons", "_rc", "_b", "_coef", "_se") | ///
		inlist(`"`name'"', "_pred", "_skip", "if", "in", "using", "with", "_nwnode", "_nwinclude") | ///
		inlist(`"`name'"', "byte", "int", "long", "float", "double", "strL") | regexm(`"`name'"', "^str[0-9]+$") {
		di `"{err}{p 0 0 2}{bf:`name'} is a reserved word and cannot be the name of a network.{p_end}"'
		exit 198
	}
end
