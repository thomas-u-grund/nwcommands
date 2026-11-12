*! _nwcensusplot: draws the dyad or triad census as small pictures with counts
*! used by the plot option of nwdyads and nwtriads
capture program drop _nwcensusplot
program _nwcensusplot
	version 16
	syntax , KIND(string) DIRected(string) COUNTS(numlist) NETname(string) [NAME(string)]

	if "`name'" == "" local name "`kind's"

	// categories in display order; the node positions in each cell are
	// A (bottom left), B (top), C (bottom right); a tie is written as
	// from-to, a mutual tie with "=" (A=B); the definitions follow the
	// MAN labelling of Holland and Leinhardt (B is the middle node)
	if "`kind'" == "dyad" {
		if "`directed'" == "true" {
			local cats "Mutual Asym Null"
			local e1 "A=C"
			local e2 "A-C"
			local e3 ""
		}
		else {
			local cats "Tie Null"
			local e1 "A=C"
			local e2 ""
		}
		local ncol : word count `cats'
		local nrow 1
	}
	else {
		if "`directed'" == "true" {
			local cats "003 012 102 021D 021U 021C 111D 111U 030T 030C 201 120D 120U 120C 210 300"
			local e1  ""
			local e2  "A-B"
			local e3  "A=B"
			local e4  "B-A B-C"
			local e5  "A-B C-B"
			local e6  "A-B B-C"
			local e7  "A=B C-B"
			local e8  "A=B B-C"
			local e9  "A-B C-B A-C"
			local e10 "B-A C-B A-C"
			local e11 "A=B B=C"
			local e12 "B-A B-C A=C"
			local e13 "A-B C-B A=C"
			local e14 "A-B B-C A=C"
			local e15 "A-B B=C A=C"
			local e16 "A=B B=C A=C"
			local ncol 4
			local nrow 4
		}
		else {
			local cats "003 102 201 300"
			local e1 ""
			local e2 "A=B"
			local e3 "A=B B=C"
			local e4 "A=B B=C A=C"
			local ncol 4
			local nrow 1
		}
	}
	local ncat : word count `cats'
	if `: word count `counts'' != `ncat' {
		di as err "_nwcensusplot: `ncat' counts expected"
		exit 198
	}

	preserve
	quietly {
		drop _all
		// up to 3 nodes, 3 ties and 1 label row per category
		set obs `=`ncat' * 7'
		gen double nx = .
		gen double ny = .
		gen double x1 = .
		gen double y1 = .
		gen double x2 = .
		gen double y2 = .
		gen byte mutual = .
		gen double lx = .
		gen double ly = .
		gen double cy = .
		gen str20 lcat = ""
		gen str20 lcnt = ""

		local obs 0
		forvalues k = 1/`ncat' {
			local col = mod(`k' - 1, `ncol')
			local row = `nrow' - 1 - floor((`k' - 1) / `ncol')
			// node positions
			if "`kind'" == "dyad" {
				local Ax = `col' + 0.22
				local Ay = `row' + 0.7
				local Cx = `col' + 0.78
				local Cy = `row' + 0.7
				local nodes "A C"
			}
			else {
				local Ax = `col' + 0.2
				local Ay = `row' + 0.44
				local Bx = `col' + 0.5
				local By = `row' + 0.86
				local Cx = `col' + 0.8
				local Cy = `row' + 0.44
				local nodes "A B C"
			}
			foreach v of local nodes {
				local ++obs
				replace nx = ``v'x' in `obs'
				replace ny = ``v'y' in `obs'
			}
			foreach t of local e`k' {
				local mut = strpos("`t'", "=") > 0
				local f = substr("`t'", 1, 1)
				local g = substr("`t'", 3, 1)
				// shorten the line so that it stops at the node markers
				local dx = ``g'x' - ``f'x'
				local dy = ``g'y' - ``f'y'
				local len = sqrt((`dx')^2 + (`dy')^2)
				local s = 0.09 / `len'
				local ++obs
				replace x1 = ``f'x' + `s' * `dx' in `obs'
				replace y1 = ``f'y' + `s' * `dy' in `obs'
				replace x2 = ``g'x' - `s' * `dx' in `obs'
				replace y2 = ``g'y' - `s' * `dy' in `obs'
				replace mutual = `mut' in `obs'
			}
			local ++obs
			local c : word `k' of `counts'
			replace lx = `col' + 0.5 in `obs'
			replace ly = `row' + cond("`kind'" == "dyad", 0.36, 0.25) in `obs'
			replace cy = `row' + cond("`kind'" == "dyad", 0.12, 0.11) in `obs'
			replace lcat = "`: word `k' of `cats''" in `obs'
			replace lcnt = strtrim(string(`c', "%15.0fc")) in `obs'
		}
	}

	local asp = `nrow' / `ncol'
	if `nrow' == 1 local tsz "large"
	else local tsz "medsmall"
	if `nrow' == 1 local msz "large"
	else local msz "medlarge"
	if "`kind'" == "dyad" local ttl "Dyad census"
	else local ttl "Triad census"
	if "`directed'" == "true" {
		local tiecmd (pcarrow y1 x1 y2 x2 if mutual == 0, lcolor(gs3) mcolor(gs3) lwidth(medthin) msize(medsmall) barbsize(medsmall)) ///
			(pcbarrow y1 x1 y2 x2 if mutual == 1, lcolor(gs3) mcolor(gs3) lwidth(medthin) msize(medsmall) barbsize(medsmall))
	}
	else {
		local tiecmd (pcspike y1 x1 y2 x2 if mutual == 1, lcolor(gs3) lwidth(medthin))
	}
	twoway `tiecmd' ///
		(scatter ny nx, msymbol(O) msize(`msz') mfcolor(gs10) mlcolor(gs3)) ///
		(scatter ly lx, msymbol(none) mlabel(lcat) mlabpos(0) mlabsize(`tsz') mlabcolor(black)) ///
		(scatter cy lx, msymbol(none) mlabel(lcnt) mlabpos(0) mlabsize(`tsz') mlabcolor(gs5)), ///
		xscale(range(0 `ncol') off) yscale(range(-0.05 `nrow') off) ///
		xlabel(none) ylabel(none) aspectratio(`asp') legend(off) ///
		plotregion(margin(small)) graphregion(color(white)) ///
		title("`ttl': `netname'", size(medium)) ///
		xsize(`=cond(`nrow' == 1, 6, 5)') ysize(`=cond(`nrow' == 1, 2.4, 5.5)') ///
		name(`name', replace)
	restore
	di as txt "(plot saved as {bf:`name'}; `kind' census of `netname')"
end
