
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
end
