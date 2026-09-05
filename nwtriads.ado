
capture program drop nwtriads
program nwtriads
	version 9
	syntax [anything(name=netname)] [, PLOT NAME(string)]

	_nwsyntax `netname', max(1)
	local onedirected = "`directed'"

	// The 16-type MAN census is a genuinely directed-network concept:
	// calculate_triadcensus() computes it from the network's mutual (M)
	// and asymmetric (C = net - M) dyad components, and for an
	// undirected network every tie is symmetric by construction, so C
	// is mathematically zero and every category that depends only on C
	// is trivially 0 regardless of the network's actual structure -
	// confirmed by direct computation on several undirected test
	// networks. _210 was previously found NOT to reliably return 0 for
	// undirected input, suspected at the time to be a Mata
	// [symmetric]-matrix-type edge case inside calculate_triadcensus()
	// itself - that suspicion was wrong: the actual root cause (found by
	// directly comparing calculate_triadcensus()'s own return-vector
	// order against this file's r()-extraction below) was a simple
	// swapped pair of indices right here in nwtriads.ado, reading
	// r(_201) from x_210's position and r(_210) from x_201's position -
	// now fixed. calculate_triadcensus() itself was correct the whole
	// time; only the extraction was wrong.
	if "`directed'" == "false" {
		di "{txt}Note: {bf:`netname'} is undirected - most MAN triad categories"
		di "{txt}are not meaningful for undirected data (there are no"
		di "{txt}asymmetric dyads to distinguish); only"
		di "{txt}{bf:_003}/{bf:_102}/{bf:_201}/{bf:_300} (0/1/2/3-edge triads)"
		di "{txt}reliably reflect the network's actual structure."
		di "{txt}See {help nwclustering} for undirected transitivity."
	}

	tempname triadcensus
	mata: `triadcensus' = `netobj'->calculate_triadcensus()

	mata: st_numscalar("r(_003)", `triadcensus'[1])
	mata: st_numscalar("r(_012)", `triadcensus'[2])
	mata: st_numscalar("r(_021D)", `triadcensus'[3])
	mata: st_numscalar("r(_021U)", `triadcensus'[4])
	mata: st_numscalar("r(_021C)", `triadcensus'[5])
	mata: st_numscalar("r(_030T)", `triadcensus'[6])
	mata: st_numscalar("r(_030C)", `triadcensus'[7])
	mata: st_numscalar("r(_102)", `triadcensus'[8])
	mata: st_numscalar("r(_111D)", `triadcensus'[9])
	mata: st_numscalar("r(_111U)", `triadcensus'[10])
	mata: st_numscalar("r(_120D)", `triadcensus'[11])
	mata: st_numscalar("r(_120U)", `triadcensus'[12])
	mata: st_numscalar("r(_120C)", `triadcensus'[13])
	// was st_numscalar("r(_201)", ...[14]) / st_numscalar("r(_210)",
	// ...[15]) - swapped. calculate_triadcensus()'s own return statement
	// (unw_core.do) orders its vector "..., x_120C, x_210, x_201, x_300"
	// - index 14 is x_210, index 15 is x_201 - so this file had them
	// backwards. Confirmed via 3 hand-computable undirected networks
	// (see cscripts/test_nwtriads.do): a 5-node cycle (no triangles,
	// 5 open 2-edge triads) reported _210=5/_201=0 before this fix -
	// exactly the swap, since _210 should be 0 for any undirected
	// network (no asymmetric dyads to form a 2-1-mutual/1-asym triad
	// from) while _201 (2-edge open triads) should be 5. This also
	// resolves the previously-suspected "Mata [symmetric]-matrix-type
	// edge case" (see docs/CERTIFICATION.md's now-superseded Pending
	// row) - direct probing found no such Mata quirk at all once this
	// far simpler root cause was found; calculate_triadcensus() itself
	// was correct the whole time.
	mata: st_numscalar("r(_201)", `triadcensus'[15])
	mata: st_numscalar("r(_210)", `triadcensus'[14])
	mata: st_numscalar("r(_300)", `triadcensus'[16])

	tempname r
	
	_return hold `r'
	preserve
	// nwclustering's own generate() is now required (suite-wide
	// generate()-required style decision, 2026-09-05) - only
	// r(cluster_global) is read here, inside preserve/restore, so a
	// tempvar is all that's needed.
	tempvar nwtriadsclust
	nwclustering `netname', generate(`nwtriadsclust')
	local transitivity `r(cluster_global)'
	restore
	_return restore `r'
	
	mata: st_global("r(name)", "`netname'")
	// Naming consistency (moderate-severity pass, information_census
	// group): nwname uses `r(netname)' for the identical "which network
	// is this result about" concept; nwdyads/nwtriads used `r(name)'
	// only. Added as an alias rather than renaming, so existing callers
	// of either name keep working.
	mata: st_global("r(netname)", "`netname'")
	mata: st_numscalar("r(transitivity)", `transitivity')

	
	di
	di "{txt}    Triad census: {res} `netname'{txt}"
	di 
	di "{txt}{ralign 10:003}{col 12}{c |}{ralign 10:012}{col 24}{c |}{ralign 10:021D}{col 36}{c |}{ralign 10:021U}{col 48}{c |}"
	di "{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}"
	di "{res}{ralign 10:`r(_003)'}{col 12}{c |}{ralign 10:`r(_012)'}{col 24}{c |}{ralign 10:`r(_021D)'}{col 36}{c |}{ralign 10:`r(_021U)'}{col 48}{c |}"
	di
	di "{txt}{ralign 10:021C}{col 12}{c |}{ralign 10:030T}{col 24}{c |}{ralign 10:030C}{col 36}{c |}{ralign 10:102}{col 48}{c |}"
	di "{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}"
	di "{res}{ralign 10:`r(_021C)'}{col 12}{c |}{ralign 10:`r(_030T)'}{col 24}{c |}{ralign 10:`r(_030C)'}{col 36}{c |}{ralign 10:`r(_102)'}{col 48}{c |}"
	di
	di "{txt}{ralign 10:120D}{col 12}{c |}{ralign 10:120U}{col 24}{c |}{ralign 10:120C}{col 36}{c |}{ralign 10:111D}{col 48}{c |}"
	di "{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}"
	di "{res}{ralign 10:`r(_120D)'}{col 12}{c |}{ralign 10:`r(_120U)'}{col 24}{c |}{ralign 10:`r(_120C)'}{col 36}{c |}{ralign 10:`r(_111D)'}{col 48}{c |}"
	di
	di "{txt}{ralign 10:111U}{col 12}{c |}{ralign 10:201}{col 24}{c |}{ralign 10:210}{col 36}{c |}{ralign 10:300}{col 48}{c |}"
	di "{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}"
	di "{res}{ralign 10:`r(_111U)'}{col 12}{c |}{ralign 10:`r(_201)'}{col 24}{c |}{ralign 10:`r(_210)'}{col 36}{c |}{ralign 10:`r(_300)'}{col 48}{c |}"
	di
	di "{txt}     Transitivity: {res}`=round(`r(transitivity)',0.001)'"

	// plot(): a bar chart of the 16 MAN-category counts, via this
	// package's own established preserve/rebuild-a-plotting-dataset/
	// restore convention (matching nwcug's own plot() for its null
	// distribution). Category order is fixed to the same conventional
	// MAN ordering the text table above already uses, not sorted by
	// count - achieved via a value-labeled numeric code, since
	// `graph bar's own over() sorts a plain string variable
	// alphabetically. Grayscale by design (Stata Journal figures must
	// stay legible in black and white), same discipline as nwcug's own
	// plot()/nwergm_estat's mcmcdiag/gof plots.
	if "`plot'" != "" {
		if "`name'" == "" {
			local name "triads"
		}
		preserve
		qui drop _all
		qui set obs 16
		qui gen long catcode = _n
		label define __nwtriads_catlbl 1 "003" 2 "012" 3 "021D" 4 "021U" ///
			5 "021C" 6 "030T" 7 "030C" 8 "102" 9 "111D" 10 "111U" ///
			11 "120D" 12 "120U" 13 "120C" 14 "201" 15 "210" 16 "300", replace
		label values catcode __nwtriads_catlbl
		qui gen double count = .
		qui replace count = `r(_003)' if catcode==1
		qui replace count = `r(_012)' if catcode==2
		qui replace count = `r(_021D)' if catcode==3
		qui replace count = `r(_021U)' if catcode==4
		qui replace count = `r(_021C)' if catcode==5
		qui replace count = `r(_030T)' if catcode==6
		qui replace count = `r(_030C)' if catcode==7
		qui replace count = `r(_102)' if catcode==8
		qui replace count = `r(_111D)' if catcode==9
		qui replace count = `r(_111U)' if catcode==10
		qui replace count = `r(_120D)' if catcode==11
		qui replace count = `r(_120U)' if catcode==12
		qui replace count = `r(_120C)' if catcode==13
		qui replace count = `r(_201)' if catcode==14
		qui replace count = `r(_210)' if catcode==15
		qui replace count = `r(_300)' if catcode==16
		graph bar (asis) count, over(catcode, label(angle(45))) ///
			ytitle("Count") ///
			title("Triad census: `netname'", size(medium)) ///
			bar(1, fcolor(gs12) lcolor(gs6)) ///
			legend(off) name(`name', replace)
		restore
		di as txt "(plot saved as {bf:`name'}; triad-category counts for `netname')"
	}
end
	

