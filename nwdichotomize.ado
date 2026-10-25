
capture program drop nwdichotomize
program nwdichotomize
	syntax anything(name=netname), THRESHOLD(real) [generate(string) prefix(string)]

	local genopt ""
	if "`generate'" != "" {
		local genopt "generate(`generate')"
	}
	local prefopt ""
	if "`prefix'" != "" {
		local prefopt "prefix(`prefix')"
	}

	nwrecode `netname' (`=strofreal(`threshold')'/max=1) (min/max=0), `genopt' `prefopt'

	// The result has two values only: it is a binary network, whatever the source was
	_nwsyntax `netname', max(9999) other(src)
	local __nwd_targets ""
	local __nwd_i 1
	foreach __nwd_n in `srcnetname' {
		if "`prefix'" != "" {
			local __nwd_targets "`__nwd_targets' `prefix'`__nwd_n'"
		}
		else if "`generate'" != "" & "`: word `__nwd_i' of `generate''" != "" {
			local __nwd_targets "`__nwd_targets' `: word `__nwd_i' of `generate''"
		}
		else {
			local __nwd_targets "`__nwd_targets' `__nwd_n'"
		}
		local ++__nwd_i
	}
	foreach __nwd_t in `__nwd_targets' {
		capture _nwsyntax `__nwd_t', max(1)
		if _rc == 0 {
			mata: `netobj'->set_valued(0)
		}
	}
end
