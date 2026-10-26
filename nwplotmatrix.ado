capture program drop nwplotmatrix
program nwplotmatrix
	syntax [anything(name=netname)],[ * sortby(varlist) group(string) lab label(varname) ylabel(string) xlabel(string) BAckground(string) labelopt(string) legendopt(string asis) COlorpalette(string) LColor(string) legend(string asis) tievalue tievalueopt(string) ]
	unw_defs
	_nwsyntax `netname'

	// BUGFIX: a single-node network used to crash deep inside this
	// program with a generic, uninformative "invalid syntax" (r198) -
	// first from an undefined local (`cbak', only ever assigned inside
	// a now-empty `foreach' loop over color levels, itself now fixed
	// separately below) and, once past that, a second, genuinely
	// unrenderable case (a matrix plot has nothing meaningful to show
	// for a single node/no possible ties) inside Stata's own `graph
	// twoway' engine. Rather than chase that second, structural issue
	// through a complex plotting pipeline, fail fast here with a clear
	// message instead - matching the fix already applied to nwplot's
	// own analogous single-node case in an earlier unit, which DOES
	// still render (a node-layout plot can trivially place one dot,
	// unlike a matrix plot of a 1x1 adjacency matrix).
	if `nodes' <= 1 {
		di "{err}nwplotmatrix requires a network with at least 2 nodes."
		error 198
	}

	// one box (five points) per dyad: memory and drawing time grow with the
	// square of the number of nodes (about 2.6 GB and 20 s for 2,000 nodes,
	// 1 GB and 5 s for 1,000); beyond 2,500 nodes a box per dyad is also
	// finer than a screen or a page can show
	if `nodes' > 2500 {
		di "{err}nwplotmatrix draws one box for every pair of nodes: " ///
			"`nodes' nodes would need about " round(`nodes'^2 * 5 * 130 / 1024^3, 0.1) " GB."
		di "{err}Plot a part of the network (for example nwinduced) or use {bf:nwplot}."
		exit `errDenseTooLarge'
	}

	preserve
	gettoken temp ylabel : ylabel, parse(",")
	gettoken temp xlabel : xlabel, parse(",")
	if substr(`"`ylabel'"',1,1) == "," {
		local ylabel = substr(`"`ylabel'"', 2,.)
	}
	if substr(`"`xlabel'"',1,1) == "," {
		local xlabel = substr(`"`xlabel'"', 2,.)
	}
	
	local oldoptions "`options'"
	local oldlcolor "`lcolor'"
    qui if "`group'" != "" {
		local 0 "`group'"
		syntax varlist(min=1 max=1) [, lcolor(string) *]
		local groupvar "`varlist'"
		local groupopt "`options'"
		local sortby "`groupvar' `sortby'"
		if "`lcolor'" == "" {
			local lcolor `""scheme p2line""'
		}
	}
	
	if "`tievalue'" != "" {
		local freq = "freq"
	}

	_nwdatasync `netname'
	qui replace `nw_included' = . if `nw_included' == 0
	
	tempvar _sorting _group
	tempname tempmat
	gen `_sorting' = _n
	if "`sortby'" == "" {
		local sortby `_sorting'
		// two-mode network: the nodes of one mode next to each other (rows keep their order inside a mode)
		if "`is2mode'" == "true" {
			tempvar _mode
			qui gen byte `_mode' = .
			mata: st_store((1::`nodes'), "`_mode'", strtoreal(`netobj'->get_modes()'))
			local sortby `_mode'
		}
	}
	
	qui if "`group'" != "" {
		local 0 "`group'"
		syntax varlist(min=1 max=1) [, lcolor(string) *]
		local groupvar "`varlist'"
		local groupopt "`options'"
		if "`lcolor'" == "" {
			local lcolor `""scheme p2line""'
		}
		egen `_group' = group(`groupvar')
		local sortby `_group'
	}
	
	qui sort `nw_included' `sortby' `_sorting'
	mata: st_matrix("`tempmat'",(*`netobj'->get_matrix())[st_data((1,`nodes'), ("`_sorting'")), st_data((1,`nodes'), ("`_sorting'"))])
	
	local xlines ""

	qui if "`group'" != "" {
		local groupopt "`options'"
		forvalues i = 2/`nodes' {
			if (`_group'[`i'] != `_group'[`=`i'-1']) {
				local xlines "`xlines' `=`i'-0.5'"
				local ylines "`ylines' `=2 - `i' - 0.5'"
			}
		}
		local xlinecmd `"xline(`xlines', `groupopt' lcolor(`lcolor'))"'
		local ylinecmd `"yline(`ylines', `groupopt' lcolor(`lcolor'))"'
	}
	local options "`oldoptions'"
	local lcolor `"`oldlcolor'"'
	
	// two-mode network: a line between the two modes (when the nodes of one mode are next to each other)
	if "`is2mode'" == "true" {
		mata: st_local("__nwpm_md", invtokens(`netobj'->get_modes()))
		local __nwpm_xl ""
		local __nwpm_yl ""
		forvalues i = 2/`nodes' {
			local __nwpm_a = `_sorting'[`i']
			local __nwpm_b = `_sorting'[`=`i'-1']
			if word("`__nwpm_md'", `__nwpm_a') != word("`__nwpm_md'", `__nwpm_b') {
				local __nwpm_xl "`__nwpm_xl' `=`i'-0.5'"
				local __nwpm_yl "`__nwpm_yl' `=2 - `i' - 0.5'"
			}
		}
		if "`__nwpm_xl'" != "" {
			local xlinecmd `"`xlinecmd' xline(`__nwpm_xl', lcolor(black) lwidth(medium))"'
			local ylinecmd `"`ylinecmd' yline(`__nwpm_yl', lcolor(black) lwidth(medium))"'
		}
	}
	local lgd "auto"
	if `"`legend'"' != "" local lgd `"`legend'"'
	if "`lab'" != "" {
		local label `nw_nodename'
	}
	
	if "`label'" != "" {
		local l label(`label')
	}
	//nwsociomatrix_noif `netname', `xlinecmd' `ylinecmd' `lab' label(`label') `nodichotomize' background(`background') ylabel(`labelopt' `ylabel') xlabel(`labelopt' `xlabel') legendopt(`legendopt') color(`colorpalette') lcolor(`lcolor') legend(`legend') `tievalue' tievalueopt(`tievalueopt') `options'
	qui plotmatrix, `xlinecmd' `ylinecmd' `l' legend(`lgd') `freq' tievalueopt(`tievalueopt') ylabel(, angle(0) `ylabel') xlabel(, angle(90) `xlabel') aspect(1) mat(`tempmat') background(`background') color(`colorpalette') lcolor(`lcolor') `options'  
	restore
end

// The following code cas been modified....


*! Date        : 24 Apr 2014
*! Version     : 1.20
*! Author      : Adrian Mander
*! Email       : adrian.mander@mrc-bsu.cam.ac.uk
*! Description : Plot matrices/Heat maps

/*
v 1.15 24Nov2008  Bug -- had to specify a cmiss(n) option on the boxes and moved it to version 10.1 (not sure 
> if this is necessary)
v 1.16 20Oct2009  Bug - there is a problem with people using set dp comma added a check to stop the program
v 1.17  6May2011  Add - allow frequencies to be plotted on screen
v 1.18 21May2012  Add option to allow all colours to be specified using the allcolors() option.
v 1.19  8Mar2013  Add a formatcells() option to alter the printing style of the matrix values
v 1.20 24Apr2014  Bug? -- skipping allcolors if the graph is null is now removed
*/

capture program drop plotmatrix
prog def  plotmatrix
version 10.1
syntax , Mat(name) [,ifvar(varname) gap(real 0.05) originalnodes(integer 0) legend(string asis) Split(numlist) lab label(varname) tievalueopt(string) background(string) Color(string) LColor(string) Upper Lower MAXTicks(integer 8) FREQ FORMATCELLS(string) *]
local twoway_opt "`options'"
set more off

local nodes = rowsof(`mat')
local xnames = ""
if "`label'" != "" {
	forvalues i = 1/ `nodes' {
		local onelab = `label'[`i']
		local xnames `"`xnames' "`onelab'""'
	}
}
local ynames `"`xnames'"'
drop _all

/* Find matrix dimensions */
local ny = rowsof(`mat')
local nx = colsof(`mat')

/* the data of the boxes, built directly (no svmat/stack: Stata/BE holds at most
   2,048 variables, and a variable per column was a second copy of the matrix) */
_mkdata, mat(`mat') split(`split')
if "`split'" == "" local split "`r(split)'"


/*Go through the colour cutoffs to create the legend list?*/
local count 1
foreach num of numlist `split' {
  if `count' > 1 local lablist `"`lablist' "`prev'-`num'" "'
  local `count++'
  local prev `num'
}
local lablist `"`lablist' "`prev'" "' 

/*************************************************************************************** 
 * The colour list...get the levels and produce the colours 
 *  ncolleg is the number of columns in legend
 *  size is the number of colors
 *  colorlist is the list of colours
 *
 *  cb is created in the _mkdata command and it is _n per color level according to split
 *  BUT clevels will only see the observed values and groupings not used will be missed
 *
 * work out the number of specified colours and change intensities around them.. 
 * OR if you specify a colorlist
 * then you make the intensity of 1 
 ***************************************************************************************/

qui levelsof cb, local(clevels)

local colorlist ""
local ccc 1
// BUGFIX: a single-node network (nothing to tabulate) leaves `clevels'
// empty, so the `foreach' loop below - the only place that ever
// assigns `cbak' - runs zero times, leaving `cbak' entirely undefined.
// `local ncolleg = int(sqrt(`cbak')+1)' further down then expands to
// the malformed `int(sqrt()+1)' and crashes with a generic "invalid
// syntax" (r198). Defaulting `cbak' to 0 here is a no-op for every
// non-empty `clevels' case (the loop always overwrites it from its own
// final iteration) and gives a sensible ncolleg==1 for this edge case.
local cbak = 0
local size:list sizeof clevels
local no_spec_cols: list sizeof color
local new_size = int(`size'/`no_spec_cols'+0.999)
local spcol 1

/*****************************************************
 * Work out the color levels 
 * this is where the set dp is problematic
 *****************************************************/

foreach temp of local clevels {
  if `spcol'>`no_spec_cols' local spcol 1
  local cind`temp' `ccc'
  local cbak = `ccc++'-1
  local fact = int(255 -  200/`new_size'*`cbak')
  local fact2 = int( (255 -  200/`new_size'*`cbak')/2 )
  local fact3 = int( (255 -  200/`new_size'*`cbak')/3 )  
  if `spcol'==1 & `new_size'~=1 local intensity : di %4.2f (255/`new_size'*`cbak')/175+0.15
  if `spcol'==1 & `new_size'==1 local intensity : di %4.2f 1
  if `size'==1 local intensity "1"
  if "`color'"=="" local colorlist `" `colorlist' "`fact3' `fact2' `fact'" "'
  if "`color'"~="" {
    local scolor: word `spcol' of `color'
    local colorlist `" `colorlist' `scolor'*`intensity' "'
    local `spcol++'
  }
}

local ncolleg = int(sqrt(`cbak')+1)
local txt ""
local i 1

//local colorlist "scheme p5"
/*************** This next part is OK if allcolors is empty*****************/
    if "`lcolor'" == "" {
		local blc = `"scheme pline"'
	}
	else {
		local blc = `"`lcolor'"'
	}
	
	local i = 1

	foreach c of local clevels {
		qui count if  cb==`c'
		if r(N)>0 {
			if "`done`c''" == "" {
				local clab: word `c' of `lablist'
				local clegord "`clegord' `i'"
				local cleg `" `cleg' label(`i' "`clab'")"'
				local numb`c' `i'
			}
			
			capture local bcolor : word `=`i'-1' of `color'
			if "`bcolor'" == "" {
				local bc `""scheme p`=`i'-1'color""'
			}
			else {
				local bc `"`bcolor'"'
			}
	  
			if `i' == 1 {
				if "`background'" != "" {
					local bc = "`background'"
				}
				else {
					local bc `""scheme background""'
				}
			}
			
			if "`upper'"~="" local xtraif " & y<=_stack"
			if "`lower'"~="" local xtraif " & y>=_stack"
 
			local txt`c' `"area yy xx if cb==`c' & col1~=. `xtraif',  cmiss(n) bfintensity(100) blc("`blc'") blw(vvthin) bc(`bc') nodropb"'
			
			if `"`txt'"'=="" local txt `"(`txt`c'')"'
			else {
				local txt `"`txt'||(`txt`c'')"'
			}
			local gsty "`gsty' p1area"
		}
		local `i++'
   }
   

  /***** this if if allcolors is specified then we make sure missing graphs still abide by the allcolors list 
> */
  
  /* Reconstruct the order of the legend */
foreach cord of local clevels {
  local corder "`corder'`numb`cord'' "
}


// Create labels
local xlab ""
forvalues i = 1 / `nodes'{
	local onelab " "
	if `"`xnames'"' != "" {
		local onelab : word `i' of `xnames'
	}
	local onelab `"`i' "`onelab'""'
	local xlab `"`xlab'  `onelab'"'
}


local ylab ""
forvalues i = 1 / `nodes'{
	local onelab " "
	local j = 1 - `i'
	if `"`ynames'"' != "" {
		local onelab : word `i' of `ynames'
	}
	local onelab `"`j' "`onelab'""'
	local ylab `"`ylab'  `onelab'"'
}

if "`lab'" == "" & "`label'" == "" {
	local scaleOff = "yscale(off) xscale(off)"
}




/********************************************************
 * The Freq option
 *  Want to display the values of the cells as the text 
 *  within each box
 *  ALSO the user can alter these formats
 ********************************************************/
if "`freq'"~="" {
  gen newy = -1*y+1
  if "`formatcells'"~="" format col1 `formatcells'
  local txt "`txt'||(scatter newy _stack, mlab(col1) mlabcolor(black) mlabposition(0) ms(i) `tievalueopt')"
} 

gen temp = mod(_n,5)
replace xx = xx - `gap' if temp == 1 | temp == 4
replace xx = xx + `gap' if temp == 2 | temp == 3

replace yy = yy + `gap' if (temp == 1 | temp == 2) 
replace yy = yy - `gap' if (temp == 3 | temp == 4) 

if `"`legend'"' == "auto" {
	local legend `"order(`clegord') `cleg' rows(1) position(6) size(small)"'
}
twoway `txt', `scaleOff' legend(`legend') xlabel(`xlab', nogrid) ylabel(`ylab', nogrid) xtitle("") ytitle("") graphregion( c(white) lp(blank)) `twoway_opt' 
end

/************************************************ 
 *
 * Make the dataset that will create the boxes 
 *
 *************************************************/

capture program drop _mkdata
prog def _mkdata, rclass
syntax , Mat(name) [Split(numlist)]

/*
Create percentiles if split is not specified.  The cells of the matrix are
stacked column by column into col1 (with the column number in _stack and the
row number in y); every cell then becomes the five corners of its box, in the
order the boxes are drawn (see nw_pm_boxes() in unw_core.do).
*/

local ny = rowsof(`mat')
local nx = colsof(`mat')
qui set obs `=`ny'*`nx''
mata: nw_pm_cells("`mat'")

qui su col1
local min: di %5.3f (`r(min)'-0.001)
local max: di %5.3f (`r(max)'+0.001)
if "`split'"=="" {
  //di as text "Percentiles are used to create legend"
  qui _pctile col1, p( 1 5(10)95 99)
  local i 1
  local split "`min' "
  while r(r`i')~=. {
    local entry:di %5.3f `r(r`i++')'
    local split "`split'`entry' "
  }
  local split "`split' `max'"
}
return local split = "`split'"  

local diff 0.5
mata: nw_pm_boxes(strtoreal(tokens(st_local("split"))), `diff')
end
