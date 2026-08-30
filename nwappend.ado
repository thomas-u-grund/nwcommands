
capture program drop nwappend
program nwappend
	syntax [anything] using/ [, force]
    nwuse `using', nwappend `force'
end


