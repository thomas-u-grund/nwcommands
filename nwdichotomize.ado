
capture program drop nwdichotomize
program nwdichotomize
	syntax anything(name=netname), THRESHOLD(real) [generate(string) prefix(string)]

	// the names the results will get are fixed first: a name in use is replaced by a free one (with a warning), and
	// only the networks that receive a result are made binary afterwards
	_nwsyntax `netname', max(9999) other(src)
	local __nwd_targets ""
	local __nwd_gen ""
	local __nwd_i 1
	foreach __nwd_n in `srcnetname' {
		local __nwd_req ""
		if "`prefix'" != "" local __nwd_req "`prefix'`__nwd_n'"
		else local __nwd_req : word `__nwd_i' of `generate'
		local __nwd_new "`__nwd_n'"
		if "`__nwd_req'" != "" {
			qui nwvalidate `__nwd_req'
			local __nwd_new "`r(validname)'"
		}
		if "`prefix'" == "" & "`__nwd_req'" != "" local __nwd_gen "`__nwd_gen' `__nwd_new'"
		local __nwd_targets "`__nwd_targets' `__nwd_new'"
		local ++__nwd_i
	}
	local genopt ""
	if "`__nwd_gen'" != "" {
		local genopt "generate(`__nwd_gen')"
	}
	local prefopt ""
	if "`prefix'" != "" {
		local prefopt "prefix(`prefix')"
	}

	nwrecode `netname' (`=strofreal(`threshold')'/max=1) (min/max=0), `genopt' `prefopt'
	if "`prefix'" == "" {
		local __nwd_i 1
		foreach __nwd_w in `generate' {
			local __nwd_new : word `__nwd_i' of `__nwd_gen'
			if "`__nwd_new'" != "" & "`__nwd_new'" != "`__nwd_w'" {
				di "{txt}{p 0 0 2}Warning! Switched to netname {res}`__nwd_new'{txt} because {res}`__nwd_w'{txt} already in use.{p_end}"
			}
			local ++__nwd_i
		}
	}

	// The result has two values only: it is a binary network, whatever the source was
	foreach __nwd_t in `__nwd_targets' {
		capture _nwsyntax `__nwd_t', max(1)
		if _rc == 0 {
			mata: `netobj'->set_valued(0)
		}
	}
end
