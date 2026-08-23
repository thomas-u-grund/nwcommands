capture program drop nwds
program nwds, rclass
	 syntax [anything(name=netname)] , [alpha not *]
	 
	 unw_defs
	 
	 if "" == "" {
		local netname = "_all"
	 }
	 
	 nw_syntax , max()
	 
	 if "" != "" {
		local netname : list sort netname
	 }
	 preserve
	 clear
	 foreach v in  {
		gen 2.0.0 = .
	 }
	 ds ,  
	 restore
	 return local netlist ""
end

