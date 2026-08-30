capture program drop nwds
program nwds, rclass
	 syntax [anything(name=netname)] , [alpha not *]
	 
	 unw_defs
	 
	 if "`netname'" == "" {
		local netname = "_all"
	 }
	 
	 nw_syntax `netname', max(`nw_max')

	 // BUGFIX: the original code checked `not' - but that local is
	 // ALWAYS empty, a variant of this pass's own established
	 // "no-prefix trap": Stata's syntax parser sees the option name
	 // "not" itself as "no"+"t" and silently creates a toggle local
	 // named after the STEM ("t"), not "not" - confirmed directly
	 // (typing "not" sets `t' to "not"; typing "t" alone, or omitting
	 // the option entirely, leaves `t' empty). So `not' is never
	 // populated at all, regardless of what the caller types - fixed by
	 // checking `t' instead. Once correctly detected, inverts `netname'
	 // against the full set of currently loaded networks (the same
	 // "qui nwset" + "r(nets)" + list-subtraction idiom nwsmall.ado
	 // already uses for an analogous before/after set difference),
	 // before the (unrelated) alpha-sort step below.
	 if "`t'" != "" {
		qui nwset
		local __nwds_allnets `r(nets)'
		local netname : list __nwds_allnets - netname
	 }

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

