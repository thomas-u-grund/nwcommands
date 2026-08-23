capture program drop nwds
program nwds, rclass
	 syntax [anything(name=netname)] , [alpha not *]
	 
	 unw_defs
	 
	 if "`netname'" == "" {
		local netname = "_all"
	 }
	 
	 nw_syntax `netname', max(`nw_max')
	 
	 if "`alpha'" != "" {
		local netname : list sort netname
	 }
	 preserve
	 clear
	 foreach v in `netname' {
		gen `v' = .
	 }
	 ds `netname', `alpha' `options'
	 restore
	 return local netlist "`netname'"
end

