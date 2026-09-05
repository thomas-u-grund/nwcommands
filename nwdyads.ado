
capture program drop nwdyads
program nwdyads
	version 9
	syntax [anything(name=netname)],
	
	_nwsyntax `netname', max(1)
	mata: census = `netobj'->calculate_dyadcensus()
	mata: st_rclear()
	mata: st_numscalar("r(_001)", census[3])
	mata: st_numscalar("r(_010)", census[2])
	mata: st_numscalar("r(_100)", census[1])
	mata: st_numscalar("r(reciprocity)", census[1] / (census[1] + census[2]))
	mata: mata drop census
	
	// Display dyad census of directed network
	if ("`directed'" == "true" ) {
		di
		di "{txt}    Dyad census: {res} `netname'{txt}"
		di 
		di "{txt}{ralign 10:Mutual}{col 12}{c |}{ralign 10:Asym}{col 24}{c |}{ralign 10:Null}"
		di "{hline 11}{c +}{hline 11}{c +}{hline 11}"
		di "{res}{ralign 10:`r(_100)'}{col 12}{c |}{ralign 10:`r(_010)'}{col 24}{c |}{ralign 10:`r(_001)'}"
		di " "
		di "{txt}    Reciprocity: {res}`=round(`r(reciprocity)',0.001)'"
	}
	
	// Display dyad census for undirected network
	if ("`directed'" == "false" ) {
		di
		di "{txt}    Dyad census: {res} `netname'{txt}"
		di 
		di "{txt}{ralign 10:Mutual}{col 12}{c |}{ralign 10:Null}"
		di "{hline 11}{c +}{hline 11}"
		di "{res}{ralign 10:`r(_100)'}{col 12}{c |}{ralign 10:`r(_001)'}"
		di " "
		di "{txt}    Reciprocity: {res}`=round(`r(reciprocity)',0.001)'"
	}
	mata: st_global("r(name)", "`netname'")
	// Naming consistency (moderate-severity pass, information_census
	// group): nwname uses `r(netname)' for the identical "which network
	// is this result about" concept; nwdyads/nwtriads used `r(name)'
	// only. Added as an alias rather than renaming, so existing callers
	// of either name keep working.
	mata: st_global("r(netname)", "`netname'")
end
