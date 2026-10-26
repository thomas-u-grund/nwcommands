capture program drop nw2degree
program nw2degree
	version 12
	// Alias of nwdegree on a two-mode network (the two-mode form is nwdegree's default there); same options as always.
	syntax [anything(name=netname)][, GENerate(string) replace silent alpha(string) BINary RAW]
	set more off

	_nwsyntax `netname', max(9999)
	local __netlist "`netname'"
	foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'
		if "`is2mode'" != "true" {
			noi di "{err}nw2degree requires a two-mode network; `netname_temp' is one-mode. See {help nwdegree} instead."
			error 198
		}
	}
	local netname "`__netlist'"
	local __fwd ""
	if "`generate'" != "" local __fwd "generate(`generate')"
	if "`alpha'" != "" local __fwd "`__fwd' alpha(`alpha')"
	nwdegree `netname', `__fwd' `replace' `silent' `binary' `raw'
	capture confirm number 1
end
