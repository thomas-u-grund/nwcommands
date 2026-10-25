capture program drop _nwsyncrows
program _nwsyncrows
	// Aligns row i of the data set with node i of the network (_nwdatasync)
	// without touching the caller's r() results. Used by the commands that
	// write node-level variables by position.
	syntax [anything(name=netname)]
	tempvar included
	tempname held
	capture _return drop `held'
	_return hold `held'
	capture noisily _nwdatasync `netname', generate(`included')
	local rc = _rc
	_return restore `held'
	if `rc' != 0 {
		exit `rc'
	}
end
