capture program drop nwuse_new
program nwuse_new
	syntax anything [, nwclear clear *]
	local webname = subinstr(`"`anything'"', ".dta","",999)
	
	clear
	nwclear
	
	use `webname', clear
	

		confirm variable _nw_format _nw_nets _nw_netname _nw_size _nw_directed _nw_twomode
		local f = _nw_format[1]
		local nets = _nw_nets[1]
		forvalues i = 1/`nets' {
			preserve
			local n = _nw_netname[`i']
			local s = _nw_size[`i']
			local d = _nw_directed[`i']
			local t = _nw_twomode[`i']
			keep if _nw_match_`n'_nw_ego == 1
			nwfromedge _nw_ego _nw_alter `n', name("`n'")
			nwname `_nw_netname', newdirected("`d'")
			//nwname `_nw_netname', newtwomode("`t'")
			restore
		}
	
	if _rc != 0 {
		di "{err}Error in loading"
		exit
	}
	
	keep if _nwnode != ""
	drop _nw_*
	
	nw_syntax _all, max(99999)
	foreach onenet in `netname' {
		drop `onenet'
	}
	
end
