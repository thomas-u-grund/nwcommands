
capture program drop nwdichotomize
program nwdichotomize
	syntax anything(name=netname), THRESHOLD(real) [generate(string) prefix(string)]

	local __nwd_dups : list dups generate
	if "`__nwd_dups'" != "" {
		di "{err}{p 0 0 2}{bf:generate()} names a network twice ({bf:`: word 1 of `__nwd_dups''}); every result needs its own name.{p_end}"
		exit 198
	}
	_nwsyntax `netname', max(9999) other(src)
	qui nwset
	local __nwd_before `r(nets)'

	local genopt ""
	if "`generate'" != "" {
		local genopt "generate(`generate')"
	}
	local prefopt ""
	if "`prefix'" != "" {
		local prefopt "prefix(`prefix')"
	}

	nwrecode `netname' (`=strofreal(`threshold')'/max=1) (min/max=0), `genopt' `prefopt'

	// The result has two values only: it is a binary network, whatever the source was. The results are the networks
	// that are new (nwrecode may have chosen another name than the one asked for) and, without prefix(), the sources
	// for which generate() gave no name (they were recoded in place)
	qui nwset
	local __nwd_after `r(nets)'
	local __nwd_targets : list __nwd_after - __nwd_before
	if "`prefix'" == "" {
		local __nwd_ngen : word count `generate'
		local __nwd_i 1
		foreach __nwd_n in `srcnetname' {
			if `__nwd_i' > `__nwd_ngen' local __nwd_targets "`__nwd_targets' `__nwd_n'"
			local ++__nwd_i
		}
	}
	foreach __nwd_t in `__nwd_targets' {
		capture _nwsyntax `__nwd_t', max(1)
		if _rc == 0 {
			mata: `netobj'->set_valued(0)
		}
	}
end
