*! version 3.1.1  24oct2026
// _nwtabplot: built-in bar plot of a one- or two-way table, so that the
// plot option of nwtab2, nwtab3 and nwmixing needs no user-written package.
// It draws what the user-written -tabplot- (Nick Cox, SSC) draws for the
// same arguments: one bar per cell of the table (row variable on the y
// axis, column variable on the x axis), bar length proportional to the
// cell frequency, the weight total, or a percent / fraction / per mille.
// Written for nwcommands; it does not call or copy -tabplot-.
//
// Supported: varlist (1 or 2 variables) [if] [in] [fweight aweight iweight],
// percent[(varlist)] fraction[(varlist)] permille[(varlist)] missing
// yasis xasis yreverse xreverse horizontal height() barwidth()
// showval[(...)] maximum() minimum() plot() addplot(), and any further
// twoway option, which is passed on. Not supported (clear error):
// by(), separate(), frame(), recast(), bar#(), barall().
program define _nwtabplot, sortpreserve
	version 14
	syntax varlist(min=1 max=2) [if] [in] [fweight aweight iweight/]  ///
		[, PERCent(varlist) PERCent2 FRaction(varlist) FRaction2       ///
		PERMille(varlist) PERMille2 MISSing yasis xasis HORizontal     ///
		Height(real 0.8) YREVerse XREVerse SHOWval SHOWval2(str asis)  ///
		BARWidth(real 0.5) MAXimum(numlist max=1) MINimum(numlist max=1) ///
		PLOT(str asis) ADDPLOT(str asis)                               ///
		BY(string) SEParate(string) SEPerate(string) frame(string)     ///
		RECAST(string) barall(string) bar1(string) bar2(string)        ///
		bar3(string) bar4(string) * ]

	foreach o in by separate seperate frame recast barall bar1 bar2 bar3 bar4 {
		if `"``o''"' != "" {
			di as err "option {bf:`o'()} is not available in the built-in table plot of nwcommands"
			exit 198
		}
	}
	if "`missing'" != "" local novarlist "novarlist"
	marksample touse, strok `novarlist'
	quietly count if `touse'
	if r(N) == 0 error 2000

	local nopts = ("`percent'" != "") + ("`percent2'" != "") ///
		+ ("`fraction'" != "") + ("`fraction2'" != "") ///
		+ ("`permille'" != "") + ("`permille2'" != "")
	if `nopts' > 1 {
		di as err "percent, fraction and per mille options may not be combined"
		exit 198
	}
	if "`xasis'" != "" & "`xreverse'" != "" {
		di as err "must choose between xasis and xreverse options"
		exit 198
	}
	if "`yasis'" != "" & "`yreverse'" != "" {
		di as err "must choose between yasis and yreverse options"
		exit 198
	}
	if "`maximum'" != "" & "`minimum'" != "" {
		if `minimum' > `maximum' {
			di as err "maximum() and minimum() are inconsistent"
			exit 498
		}
	}

	local pvars `percent' `fraction' `permille'
	local isfrac = ("`fraction'`fraction2'" != "")
	local ispm = ("`permille'`permille2'" != "")
	local ispc = ("`percent'`percent2'" != "")
	local isprop = (`isfrac' | `ispm' | `ispc')
	local scale = cond(`isfrac', 1, 100)

	// what is shown (subtitle)
	if "`percent2'" != "" local what "percent"
	else if "`fraction2'" != "" local what "fraction"
	else if "`permille2'" != "" local what "per mille"
	else if "`percent'" != "" local what "percent given `percent'"
	else if "`fraction'" != "" local what "fraction given `fraction'"
	else if "`permille'" != "" local what "per mille given `permille'"
	else if "`exp'" != "" {
		capture unab wexp : `exp'
		if _rc local what "`exp'"
		else local what "`wexp'"
	}
	else local what "frequency"

	tempvar w toshow show tag
	quietly {
		// observation weights
		if "`weight'" == "" gen double `w' = `touse'
		else gen double `w' = `touse' * (`exp')
		if "`weight'" == "aweight" & !`isprop' {
			count if `touse'
			local N = r(N)
			summarize `w', meanonly
			replace `w' = `w' * `N' / r(sum)
		}
		if `isprop' {
			// share of each observation within its group, times the scale
			tempvar tot
			if "`pvars'" == "" {
				summarize `w' if `touse', meanonly
				gen double `toshow' = `scale' * `w' / r(sum) if `touse'
			}
			else {
				bysort `touse' `pvars': gen double `tot' = sum(`w')
				by `touse' `pvars': replace `tot' = `tot'[_N]
				gen double `toshow' = `scale' * `w' / `tot' if `touse'
			}
		}
		else gen double `toshow' = `w'
		if `ispm' replace `toshow' = 10 * `toshow'

		// cell totals, carried to every observation of the cell
		sort `varlist'
		by `varlist': replace `toshow' = sum(`toshow')
		by `varlist': replace `toshow' = `toshow'[_N]

		// y (row) and x (column) coordinates
		local nvars : word count `varlist'
		if `nvars' == 1 {
			if "`horizontal'" == "" {
				tempvar row
				gen byte `row' = 1
				local col "`varlist'"
				local ytitle ""
				local xtitle : variable label `col'
				if `"`xtitle'"' == "" local xtitle "`col'"
				local one yla(none) ysc(r(1 .))
			}
			else {
				local row "`varlist'"
				tempvar col
				gen byte `col' = 1
				local xtitle ""
				local ytitle : variable label `row'
				if `"`ytitle'"' == "" local ytitle "`row'"
				local one xla(none) xsc(r(1 .))
			}
		}
		else {
			gettoken row col : varlist
			local col = trim("`col'")
			local ytitle : variable label `row'
			if `"`ytitle'"' == "" local ytitle "`row'"
			local xtitle : variable label `col'
			if `"`xtitle'"' == "" local xtitle "`col'"
		}

		if "`yasis'" == "" {
			// the first row variable value is at the top unless yreverse
			local yrev = cond("`yreverse'" == "", "reverse", "")
			tempvar y
			_nwtabplot_axis `row' if `touse', gen(`y') `missing' `yrev'
			local row "`y'"
			local noyti "noticks"
		}
		capture levels `row', local(ylevels)
		if "`xasis'" == "" {
			local xrev = cond("`xreverse'" != "", "reverse", "")
			tempvar x
			_nwtabplot_axis `col' if `touse', gen(`x') `missing' `xrev'
			local col "`x'"
			local noxti "noticks"
		}
		capture levels `col', local(xlevels)

		gen double `show' = `toshow'
		if "`maximum'" != "" replace `show' = min(`maximum', `show')
		if "`minimum'" != "" replace `show' = 0 if `show' < `minimum'
		summarize `show', meanonly
		if -r(min) > r(max) {
			local biggest = r(min)
			local text "minimum"
		}
		else {
			local biggest = r(max)
			local text "maximum"
		}
		if `biggest' == 0 {
			di as err "all bars zero height?"
			exit 498
		}
		if "`horizontal'" != "" {
			replace `show' = `col' + `height' * `show' / abs(`biggest')
		}
		else {
			replace `show' = `row' + `height' * `show' / abs(`biggest')
		}
		bysort `touse' `varlist': gen byte `tag' = `touse' * (_n == 1)
	}

	// value labels printed on the bars
	local showcall ""
	quietly if "`showval'`showval2'" != "" {
		local gopts `options'
		local 0 `showval2'
		capture syntax varname [, format(str) offset(numlist max=1) zoffset(numlist max=1) * ]
		if _rc == 0 {
			local showvar `varlist'
			local varspec 1
		}
		else {
			gettoken comma 0 : 0, parse(",")
			if "`comma'" == "," local 0 `showval2'
			else local 0 , `showval2'
			syntax [, format(str) offset(numlist max=1) zoffset(numlist max=1) * ]
			local varspec 0
			local showvar "`toshow'"
		}
		if "`offset'`zoffset'" == "" local offset 0.1
		else if "`offset'" != "" & "`zoffset'" != "" {
			di as err "choose between offset() and zoffset()"
			exit 198
		}
		local sopts `options'
		local options `gopts'
		tempvar row2 col2
		gen double `col2' = `col'
		if "`zoffset'" != "" gen double `row2' = `row' - (`zoffset')
		else if "`horizontal'" == "" gen double `row2' = min(`show', `row') - (`offset')
		else {
			gen double `row2' = `row' - (`offset')
			replace `col2' = min(`show', `col')
		}
		if "`format'" == "" {
			if `varspec' local format : format `showvar'
			else if `ispc' local format %2.1f
			else if `isfrac' local format %4.3f
			else if `ispm' local format %3.0f
		}
		if "`format'" != "" {
			capture confirm numeric variable `showvar'
			if _rc format `showvar' `format'
			else {
				tempvar svs
				gen str20 `svs' = string(`showvar', "`format'")
				local showvar `svs'
			}
		}
		if "`horizontal'" != "" {
			summarize `col', meanonly
			local min = r(min) - 0.1
			local where mlabpos(11) xsc(r(`min' .))
		}
		else {
			summarize `row', meanonly
			local min = r(min) - 0.02
			local pos = cond(`nvars' == 1, 12, 0)
			local where mlabpos(`pos') ysc(r(`min' .))
		}
		local showcall scatter `row2' `col2' if `tag', ms(none) mla(`showvar') mlabcolor(black) `where' `sopts'
	}
	else {
		local format ""
		if `ispc' local format %2.1f
		else if `isfrac' local format %4.3f
		else if `ispm' local format %3.0f
		local biggest = trim("`: di `format' `biggest''")
		local note `"note("`text': `biggest'")"'
	}
	local notwithby "subtitle(`what', place(w) size(medsmall)) legend(off) `note'"
	local bw "barwidth(`barwidth')"

	if "`horizontal'" != "" {
		local barcall || rbar `show' `col' `row' if `tag', horizontal xti("`xtitle'") ///
			xla(`xlevels', val grid angle(-.001) labgap(2) `noxti') `one' `notwithby' ///
			yti("`ytitle'") `bw' pstyle(p1bar)
		twoway scatter `row' `col' if `tag', ms(none) yla(`ylevels', `noyti' nogrid ang(h) val) ///
			|| `showcall' `barcall' `options' || `plot' || `addplot'
	}
	else {
		local barcall || rbar `show' `row' `col' if `tag', xla(`xlevels', `noxti' val) ///
			xti("`xtitle'") `one' `notwithby' yti("`ytitle'") `bw' pstyle(p1bar)
		twoway scatter `row' `col' if `tag', ms(none) yla(`ylevels', `noyti' ang(h) val) ///
			|| `showcall' `barcall' `options' || `plot' || `addplot'
	}
end

// map the values of a variable to 1, 2, ... in sorted order (reversed on
// request) and attach the original values or value labels as labels
program define _nwtabplot_axis
	version 14
	syntax varname [if] [in], Generate(name) [Missing REVerse]
	marksample touse, strok novarlist
	if "`missing'" == "" markout `touse' `varlist', strok
	quietly {
		tempvar first ord
		gen long `ord' = _n
		bysort `touse' `varlist' (`ord'): gen byte `first' = (_n == 1) if `touse'
		gen long `generate' = sum(`first') if `touse'
		sort `ord'
		replace `generate' = . if !`touse'
		summarize `generate', meanonly
		local K = r(max)
		if "`reverse'" != "" {
			replace `generate' = `K' - `generate' + 1
		}
	}
	local lblname `generate'
	local vl : value label `varlist'
	forvalues i = 1/`K' {
		quietly summarize `ord' if `generate' == `i', meanonly
		local at = r(min)
		if "`vl'" != "" local t : label (`varlist') `=`varlist'[`at']'
		else local t = `varlist'[`at']
		label define `lblname' `i' `"`t'"', modify
	}
	label values `generate' `lblname'
end
