
capture program drop nwconcor
program nwconcor, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace SPLITs(int 1) measure(string) maxiter(int 25) silent]
	set more off

	if `splits' < 1 {
		di "{err}splits() must be a positive integer."
		error 198
	}
	if `maxiter' < 1 {
		di "{err}maxiter() must be a positive integer."
		error 198
	}

	_nwsyntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'

		local netmeasure "`measure'"
		if "`netmeasure'" == "" {
			if "`valued'" == "true" {
				local netmeasure "valued"
			}
			else {
				local netmeasure "binary"
			}
		}
		_opts_oneof "binary valued" "measure" "`netmeasure'" 6556

		if "`generate'" == "" {
			di "{err}option {bf:generate()} required."
			error 198
		}
		local netgenerate "`generate'"

		// Checks the exact suffixed name this iteration is about to
		// create, not the bare stem - Stata's own variable-name
		// abbreviation would otherwise let `confirm variable _concor'
		// match an already-existing `_concor1' on a later netlist
		// iteration (there being no other variable starting "_concor"
		// to make it ambiguous), falsely blocking that iteration even
		// though its own target name is still free.
		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`k'} already exists; specify {bf:replace}"
			err 99
		}

		local val = ("`netmeasure'" == "valued")

		// BUGFIX: `gen netgenerate = .' used to run here, BEFORE the
		// calculate_concor() call below that can fail (e.g. the isolates
		// check inside it) - so a failure left a stale, all-missing
		// output variable behind, which then falsely tripped the
		// "already exists; specify replace" collision guard above on any
		// retry, masking the real, original error entirely (exactly what
		// the alpha audit's own repro hit: the doc's own second example
		// line reported a misleading "already exists" error instead of
		// the real isolates problem the first line had already failed
		// on). `capture drop' (clearing out only a genuinely stale
		// variable from an unrelated earlier call) is still safe to run
		// here unconditionally - it does not itself create anything -
		// but the actual `gen' is deferred until after calculate_concor()
		// has succeeded, so a failed call never leaves anything behind to
		// block a retry. (`capture drop' is deliberately kept in its
		// original position, before the calculate_concor() call below,
		// rather than after it: _rc is not reset by ordinary successful
		// commands in Stata, only by another capture or a genuine error -
		// so moving it after would leave the harmless "variable not
		// found" 111 from this drop as the last thing to touch _rc even
		// on a fully successful call, corrupting _rc for any caller.)
		capture drop `netgenerate'`k'

		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		_nwsyntax `netname_temp'

		tempname __nw_concor
		capture noisily mata: `__nw_concor' = `netobj'->calculate_concor(`splits', `val', `maxiter')
		if _rc != 0 {
			exit _rc
		}
		gen `netgenerate'`k' = .
		mata: st_store((1::`nodes'),"`netgenerate'`k'", `__nw_concor')
		mata: mata drop `__nw_concor'

		qui tab `netgenerate'`k', matrow(block_id) matcell(block_size)

		mata: block_id = st_matrix("block_id")
		mata: block_number = rows(block_id)
		mata: block_size = st_matrix("block_size")
		mata: block_share = block_size :/ (sum(block_size))
		mata: block_sizeid = J(block_number, 3, 0)
		mata: block_sizeid[.,1] = block_size
		mata: block_sizeid[.,2] = block_id
		mata: block_sizeid[.,3] = block_share
		mata: block_sizeid = sort(block_sizeid, -1)
		mata: st_numscalar("blocks", block_number)
		mata: st_matrix("block_sizeid", block_sizeid)

		matrix colnames block_sizeid = size blockid share

		return scalar blocks = blocks
		local lblocks = blocks

		local rowlabs ""
		forvalues i = 1/`=blocks'{
			local rowlabs "`rowlabs' block`i'"
		}
		matrix rownames block_sizeid = `rowlabs'
		return matrix block_sizeid = block_sizeid
		mata: mata drop block_number block_share block_id block_size block_sizeid

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Splits: {res}`splits'{txt}   Blocks found: {res}`lblocks'"
			noi tab `netgenerate'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
