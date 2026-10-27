
capture program drop nwdyads
program nwdyads
	version 9
	syntax [anything(name=netname)],
	
	// netlist and wildcards (nwdyads lazega_*) as in nwsummarize; the
	// r() results are those of the last network
	_nwsyntax `netname', max(100000)
	foreach onenet in `netname' {
		_nwdyads1 `onenet'
	}
	capture mata: mata drop __nwdyads_*
	capture confirm number 0
end

capture program drop _nwdyads1
program _nwdyads1
	version 9
	syntax anything(name=netname)
	_nwsyntax `netname', max(1)
	_nwvaluednote `netname'
	if r(shown) == 1 {
		noi di `"`r(msg)'"'
	}
	mata: __nwdyads_census = `netobj'->calculate_dyadcensus()
	mata: st_rclear()
	mata: st_numscalar("r(_001)", __nwdyads_census[3])
	mata: st_numscalar("r(_010)", __nwdyads_census[2])
	mata: st_numscalar("r(_100)", __nwdyads_census[1])
	mata: st_numscalar("r(reciprocity)", __nwdyads_census[1] / (__nwdyads_census[1] + __nwdyads_census[2]))
	mata: mata drop __nwdyads_census
	
	// Display dyad census of directed network
	if ("`directed'" == "true" ) {
		di
		di "{txt}    Dyad census: {res} `netname'{txt}"
		di 
		di "{txt}{ralign 10:Mutual}{col 12}{c |}{ralign 10:Asym}{col 24}{c |}{ralign 10:Null}"
		di "{hline 11}{c +}{hline 11}{c +}{hline 11}"
		di "{res}{ralign 10:`r(_100)'}{col 12}{c |}{ralign 10:`r(_010)'}{col 24}{c |}{ralign 10:`r(_001)'}"
		di " "
		di "{txt}    Reciprocity: {res}`=strtrim(string(round((`r(reciprocity)')*1000)/1000,"%9.0g"))'"
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
		if "`is2mode'" == "true" {
			// only the dyads between the two modes can hold a tie (the null count is over those pairs); reciprocity of an
			// undirected tie has no meaning
			di "{txt}    Reciprocity: {res}n/a {txt}(undirected two-mode network)"
			mata: st_numscalar("r(reciprocity)", .)
		}
		else {
			di "{txt}    Reciprocity: {res}`=strtrim(string(round((`r(reciprocity)')*1000)/1000,"%9.0g"))'"
		}
	}
	mata: st_global("r(name)", "`netname'")
	// Naming consistency (moderate-severity pass, information_census
	// group): nwname uses `r(netname)' for the identical "which network
	// is this result about" concept; nwdyads/nwtriads used `r(name)'
	// only. Added as an alias rather than renaming, so existing callers
	// of either name keep working.
	mata: st_global("r(netname)", "`netname'")
end
