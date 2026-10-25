*! Date        : 24aug2014
*! Version     : 1.0
*! Author      : Thomas Grund, Linkoping University
*! Email	   : thomas.u.grund@gmail.com

capture program drop nwvalidvars
program nwvalidvars
	syntax anything(name=nodes), stub(string)
	
	mata: st_rclear()

	// one name per node goes into a Stata macro: a list that is longer than a macro can hold (c(macrolen)) stopped
	// with r(920) "macro substitution results in line that is too long" after minutes of work (about 20,000 nodes
	// in Stata/BE)
	if `nodes' * (length("`stub'") + length("`nodes'") + 2) > c(macrolen) {
		di "{err}The `nodes' variable names do not fit into a Stata macro (at most `c(macrolen)' characters)."
		di "{err}A network of this size cannot be held in one variable per node: work with the stored ties (nwtoedge, nwtomatafast) or a part of the network (nwsubset)."
		exit 900
	}
	
	// Generate temporary varlist and check for each variable if it already exists.
	local varlist = "" 	
	local invalid = 0
	forvalues i=1/`nodes' {
		local varlist "`varlist' `stub'`i'"
		capture confirm variable `stub'`i'
		if !_rc {
			local invalid = `invalid' + 1
		}
	}
	mata: st_global("r(valid)", "true")
	mata: st_global("r(stub)", "`stub'")
	
	// Find valid Stata variable names to store network.
	if `invalid' > 0 { 
		mata: st_global("r(valid)", "false")
		local stub_add = 0
		while `invalid' > 0 {
			local varlist = ""
			local stub_add = `stub_add' + 1
			local invalid = 0
			forvalues i=1/`nodes' {
				local varlist "`varlist' `stub'`stub_add'_`i'"
				capture confirm variable `stub'`stub_add'_`i'
				if !_rc {
					local invalid = `invalid' + 1
				}
			}
		}
	}
	global validvars "`varlist'"
	mata: st_global("r(validvars)", "`varlist'")
end
	
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
