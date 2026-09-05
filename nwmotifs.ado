capture program drop nwmotifs
program nwmotifs, rclass
	version 9
	syntax [anything(name=netname)] [, silent PLOT NAME(string)]

	_nwsyntax `netname', max(1)

	if "`directed'" == "true" {
		di "{txt}Note: {bf:`netname'} is directed - the 4-node motif census below"
		di "{txt}treats every tie as undirected (a directed 4-node census has 218"
		di "{txt}distinct isomorphism classes and is not attempted here); see"
		di "{txt}{help nwtriads} for a genuinely directed 3-node census."
	}

	tempname mc
	mata: `mc' = `netobj'->calculate_motif4()

	// BUGFIX: a plain `mata: st_numscalar("r(x)", ...)' poke does NOT
	// survive past this program's own exit when the program is declared
	// `rclass' - Stata's rclass wrapper discards any "r(x)" scalar that
	// was not published via the formal `return' command, confirmed via
	// an isolated repro (a two-line rclass program that pokes r(foo)
	// directly leaves `return list' empty; the identical program
	// without `, rclass' keeps it). nwtriads.ado uses the same raw-poke
	// pattern and happens to work only because it was never declared
	// `rclass' in the first place - not a safe pattern to copy for a
	// genuinely rclass command. Fixed by reading each count back into a
	// local first, then publishing via `return scalar', matching every
	// other command built this session (nwfactions/nwmaxflow/
	// nwmatching/nwpagerank/nwrandomwalk/nwlambda).
	mata: st_local("__nwmotifs_path", strofreal(`mc'[1]))
	mata: st_local("__nwmotifs_star", strofreal(`mc'[2]))
	mata: st_local("__nwmotifs_cycle", strofreal(`mc'[3]))
	mata: st_local("__nwmotifs_paw", strofreal(`mc'[4]))
	mata: st_local("__nwmotifs_diamond", strofreal(`mc'[5]))
	mata: st_local("__nwmotifs_k4", strofreal(`mc'[6]))
	mata: st_local("__nwmotifs_disc", strofreal(`mc'[7]))

	return scalar path = `__nwmotifs_path'
	return scalar star = `__nwmotifs_star'
	return scalar cycle = `__nwmotifs_cycle'
	return scalar paw = `__nwmotifs_paw'
	return scalar diamond = `__nwmotifs_diamond'
	return scalar k4 = `__nwmotifs_k4'
	return scalar disconnected = `__nwmotifs_disc'
	return local netname "`netname'"

	// Display from the locals computed above, not from r(): r(x) reads
	// as missing from inside the same program body that just called
	// "return scalar x = ..." (r() is only published to the CALLER once
	// this program exits) - the same gotcha documented in nwcug.ado's
	// own header comment, found there via an identical bug in
	// nw2project.ado earlier this session.
	if "`silent'" == "" {
		di
		di "{txt}    4-node motif census: {res}`netname'{txt}"
		di
		di "{txt}{ralign 10:path}{col 12}{c |}{ralign 10:star}{col 24}{c |}{ralign 10:cycle}{col 36}{c |}{ralign 10:paw}{col 48}{c |}"
		di "{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}"
		di "{res}{ralign 10:`__nwmotifs_path'}{col 12}{c |}{ralign 10:`__nwmotifs_star'}{col 24}{c |}{ralign 10:`__nwmotifs_cycle'}{col 36}{c |}{ralign 10:`__nwmotifs_paw'}{col 48}{c |}"
		di
		di "{txt}{ralign 10:diamond}{col 12}{c |}{ralign 10:k4}{col 24}{c |}{ralign 10:disconn.}{col 36}{c |}"
		di "{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}"
		di "{res}{ralign 10:`__nwmotifs_diamond'}{col 12}{c |}{ralign 10:`__nwmotifs_k4'}{col 24}{c |}{ralign 10:`__nwmotifs_disc'}{col 36}{c |}"
	}

	// plot(): a bar chart of the 7 motif-category counts, via this
	// package's own established preserve/rebuild-a-plotting-dataset/
	// restore convention (matching nwcug's own plot() for its null
	// distribution, and the identical addition just made to
	// nwtriads.ado). Reads from the SAME locals the display block above
	// uses, not from r() - r(x) reads as missing from inside this same
	// program body, since it was published via the formal `return'
	// command (see the BUGFIX comment above).
	if "`plot'" != "" {
		if "`name'" == "" {
			local name "motifs"
		}
		preserve
		qui drop _all
		qui set obs 7
		qui gen long catcode = _n
		label define __nwmotifs_catlbl 1 "path" 2 "star" 3 "cycle" ///
			4 "paw" 5 "diamond" 6 "k4" 7 "disconnected", replace
		label values catcode __nwmotifs_catlbl
		qui gen double count = .
		qui replace count = `__nwmotifs_path' if catcode==1
		qui replace count = `__nwmotifs_star' if catcode==2
		qui replace count = `__nwmotifs_cycle' if catcode==3
		qui replace count = `__nwmotifs_paw' if catcode==4
		qui replace count = `__nwmotifs_diamond' if catcode==5
		qui replace count = `__nwmotifs_k4' if catcode==6
		qui replace count = `__nwmotifs_disc' if catcode==7
		graph bar (asis) count, over(catcode, label(angle(45))) ///
			ytitle("Count") ///
			title("4-node motif census: `netname'", size(medium)) ///
			bar(1, fcolor(gs12) lcolor(gs6)) ///
			legend(off) name(`name', replace)
		restore
		di as txt "(plot saved as {bf:`name'}; motif-category counts for `netname')"
	}
end
