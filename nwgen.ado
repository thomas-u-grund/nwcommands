capture program drop nwgen
program nwgen
	local arg ="`0'"
	if regexm(`"`arg'"', "=[ ]*(mean|wmean|sum|min|max|sd|count|diversity|proportion)\(alter\.") {
		nwaltergen `arg'
		exit
	}
	nwgenerate `arg'
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
