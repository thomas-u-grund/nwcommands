/***
{smcl}
{* *! version 1.0.6  23aug2014 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwexport  {hline 2}}Export network as Pajek or Ucinet file{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwexport} 
[{it:{help netname}}],
{opt type}({it:{help nwexport##exp_type:exp_type}})
[, {opth fname(filename)}
{opt replace}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth fname(filename)}}filename of the exported network: default = {it:netname}{p_end}
{synopt:{opt replace}}overwrite exported file{p_end}


{synoptset 20 tabbed}{...}
{marker exp_type}{...}
{p2col:{it:exp_type}}Description{p_end}
{p2line}
{p2col:{cmd: pajek}}network is saved in {browse "http://gephi.github.io/users/supported-graph-formats/pajek-net-format/":Pajek .NET file format}
		{p_end}
{p2col:{cmd: ucinet}}network is saved in {help nwimport##ucinet:Ucinet .DL file format}
		{p_end}
		
		
{title:Description}

{pstd}
Exports a network to either 1) Pajek .NET or 2) Ucinet .DL file format. Only exports one network and no node level
attributes. By default, the
new network file is saved in the working directory. When no {opt fname} is specified, the program calls the new file {it:netname.dl} (Ucinet) or
{it:netname.net} (Pajek).


{title:Examples}

{pstd}
This example loads the {help netexample:Florentine marriage data} and exports to both .DL and .NET format. 

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwexport flomarriage, type(ucinet)}
	{cmd:. nwexport flobusiness, type(pajek)}

 {title:See also}
 
	{help nwimport}, {help nwuse}, {help nwsave}
	
***/

capture program drop nwexport
program nwexport
	version 9
	syntax [anything(name=netname)], type(string) [FName(string asis) replace]	
	
	nw_syntax `netname', max(1)
	_opts_oneof "pajek ucinet" "type" "`type'" 6810
	
	if `"`fname'"' == "" {
		local fname = "`netname'"
	}
	
	di `"{txt}Exporting network: {it:`netname'}"'
	local ending ""
	if "`type'" == "pajek" {
		 qui _nwexport_pajek `netname', fname(`fname') `replace'
		 local ending ".net"
	}	
	if "`type'" == "ucinet" {
		 qui _nwexport_ucinet `netname', fname(`fname') `replace'
		 local ending ".dl"
	}
	di `"{txt}Saved as file: {it:`fname'`ending'}"'
end


capture program drop _nwexport_pajek
program _nwexport_pajek
	syntax [anything(name=netname)], fname(string) [replace]
	
	unw_defs
	nw_syntax `netname'
	nw_datasync `netname'
	
	tempvar _running
	tempfile f
	
	preserve
	keep if _n <= `nodes'
	gen `_running' = _n
	keep `nw_nodename' `_running'
	save `f', replace
	tempname expfile

	file open `expfile' using "`fname'.net", write `replace'
	file write `expfile' "*Vertices `nodes'" _newline
	forvalues i = 1/`nodes' {
		file write `expfile' (`i')
		file write `expfile' ("   ")
		file write `expfile' (char(34))
		file write `expfile' (`nw_nodename'[`i'])
		file write `expfile' (char(34)) _newline	
	}
	
	if ("`directed'" == "true"){
		file write `expfile' "*Arcs"
	}
	else {
		file write `expfile' "*Edges"
	}
	
	qui nwtoedge `netname'
	qui keep if `netname' != 0
	gen `nw_nodename' = `nw_ego'
	merge m:1 `nw_nodename' using `f'
	drop if _merge != 3
	drop _merge 
	drop `nw_ego'
	rename `_running' `nw_ego'
	drop `nw_nodename'
	
	gen `nw_nodename' = `nw_alter'
	merge m:1 `nw_nodename' using `f'
	drop if _merge != 3
	drop _merge `nw_alter'
	rename `_running' `nw_alter'
	drop `nw_nodename'
	local ties = _N
	drop if `netname' == .
	forvalues i = 1/`=_N' {
		if `netname'[`i'] != 0 {
			local value = `netname'[`i']
			local k = `nw_ego'[`i']
			local l = `nw_alter'[`i']
			file write `expfile' _newline
			file write `expfile' (`k')
			file write `expfile' " "
			file write `expfile' (`l')
			file write `expfile' " `value'" 	
		}
	
	}
	file write `expfile' "" _newline
	file close `expfile'	
	restore
end


capture program drop _nwexport_ucinet
program _nwexport_ucinet
	syntax [anything(name=netname)], fname(string) [replace]
	
	unw_defs
	nw_syntax `netname'
	nw_datasync `netname'
	
	tempvar _running
	tempfile f
	
	preserve
	keep if _n <= `nodes'
	gen `_running' = _n
	keep `nw_nodename' `_running'
	save `f', replace
	tempname expfile
	
	nwname `netname'
	file open `expfile' using "`fname'.dl", write `replace'
	file write `expfile' "dl n=`nodes'" _newline
	file write `expfile' "format = edgelist1" _newline
	file write `expfile' "labels:" _newline
	file write `expfile' "`r(labs)'" _newline
	file write `expfile' "data:"

	qui nwtoedge `netname'
	qui keep if `netname' != 0
	gen `nw_nodename' = `nw_ego'
	merge m:1 `nw_nodename' using `f'
	drop if _merge != 3
	drop _merge 
	drop `nw_ego'
	rename `_running' `nw_ego'
	drop `nw_nodename'
	
	gen `nw_nodename' = `nw_alter'
	merge m:1 `nw_nodename' using `f'
	drop if _merge != 3
	drop _merge `nw_alter'
	rename `_running' `nw_alter'
	drop `nw_nodename'
	local ties = _N
	drop if `netname' == .
	forvalues i = 1/`=_N' {
		if `netname'[`i'] != 0 {
			local value = `netname'[`i']
			local k = `nw_ego'[`i']
			local l = `nw_alter'[`i']
			file write `expfile' _newline
			file write `expfile' (`k')
			file write `expfile' " "
			file write `expfile' (`l')
			file write `expfile' " `value'" 	
			if "`directed'" == "false" {
				file write `expfile' _newline
				file write `expfile' (`l')
				file write `expfile' " "
				file write `expfile' (`k')
				file write `expfile' " `value'" 
			}
		}
	}
	file write `expfile' "" _newline
	file close `expfile'	
	restore
end

