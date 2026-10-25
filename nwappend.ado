
capture program drop nwappend
program nwappend
	syntax [anything] using/ [, force]
	_nwlibcheck
    nwuse `using', nwappend `force'
end


