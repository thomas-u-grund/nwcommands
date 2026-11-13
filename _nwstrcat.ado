*! _nwstrcat: run a command with string variables temporarily encoded (3.20.1)
* Syntax:  _nwstrcat varlist : command
*
* Categorical options (a group, a "same" match) only need to know which nodes
* share a value. When a variable in varlist is a string, it is renamed to a
* temporary name and replaced by an encoded numeric variable with the original
* name, label and position (levels in alphabetical order); the command then
* runs, and afterwards the string variable is put back. Numeric variables in
* varlist are left alone. r() and e() results of the command are kept (an
* rclass caller adds them with -return add-). The command's return code is
* passed on.
*
* Use it only for options where the values serve as categories; options that
* use values as numbers must keep refusing strings.
capture program drop _nwstrcat
program _nwstrcat
	version 12
	_on_colon_parse `0'
	local vars `"`s(before)'"'
	local cmd `"`s(after)'"'
	local vars : list uniq vars

	local sv
	foreach v of local vars {
		capture confirm string variable `v', exact
		if !_rc local sv `sv' `v'
	}
	if "`sv'" == "" {
		`cmd'
		exit
	}

	local tmps
	local labs
	foreach v of local sv {
		tempvar t
		tempname l
		local vl : variable label `v'
		rename `v' `t'
		quietly encode `t', generate(`v') label(`l')
		label variable `v' `"`vl'"'
		order `v', after(`t')
		local tmps `tmps' `t'
		local labs `labs' `l'
	}

	capture noisily `cmd'
	local rc = _rc

	nobreak {
		local i = 0
		foreach v of local sv {
			local ++i
			local t : word `i' of `tmps'
			local l : word `i' of `labs'
			capture confirm variable `t', exact
			if !_rc {
				capture drop `v'
				rename `t' `v'
			}
			capture label drop `l'
		}
	}
	exit `rc'
end
