/***
{smcl}
{* *! version 1.0.6  23aug2014 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##import:[NW-2.2] Import/Export}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwimport  {hline 2}}Import network{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwimport} 
{it:{help filename}}
, 
{opt type}({it:{help nwimport##import_type:import_type}}[, {it:{help nwimport##type_sub:type_sub}}])
[{opth name(newnetname)}
{opt forcedirected}
{opt forceundirected}
{opt nwclear}
{opt nwappend}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth name(newnetname)}}name of the imported network; default = {it:filename}{p_end}
{synopt:{opt forcedirected}}force network to be directed{p_end}
{synopt:{opt forceundirected}}force network to be undirected{p_end}
{synopt:{opt nwclear}}clear all data and networks{p_end}
{synopt:{opt nwappend}}append to existing data{p_end}

{synoptset 20 tabbed}{...}
{marker import_type}{...}
{p2col:{it:import_type}}Description{p_end}
{p2line}
{p2col:{cmd: pajek}}network is given in {browse "http://gephi.github.io/users/supported-graph-formats/pajek-net-format/":Pajek NET file format}
		{p_end}
{p2col:{cmd: ucinet}}network is given in {help nwimport##ucinet:Ucinet file format}
		{p_end}
{p2col:{cmd: matrix}}network is given as an {help nwimport##matrix:adjacency matrix} (e.g. Excel, txt)
		{p_end}
{p2col:{cmd: edgelist}}network is given as an {help nwimport##edgelist:edgelist} (e.g. Excel, txt)
		{p_end}
{p2col:{cmd: compressed}}network is given as a {help nwimport##compressed:compressed edgelist} (e.g. txt, CSV)
		{p_end}
{p2col:{cmd: gml}}network is given in {browse "http://gephi.github.io/users/supported-graph-formats/gml-format/":GML file format}
	{p_end}
{p2col:{cmd: graphml}}network is given in {browse "http://gephi.github.io/users/supported-graph-formats/graphml-format/":GraphML file format}
		{p_end}
		

{synoptset 20 tabbed}{...}
{marker type_sub}{...}
{p2col:{it:type_sub}}Description{p_end}
{p2line}
{p2col:{cmd: rownames}}matrix: first row in matrix contains variable names
		{p_end}
{p2col:{cmd: colnames}}matrix: first column in matrix contains variable names
		{p_end}
{p2col:{opth delimiter(string)}}matrix: specify delimiter in matrix explicitly
		{p_end}		
{p2col:{opt keeporiginal}}edgelist, compressed: keeps original nodeid's of nodes
		{p_end}			
		
{title:Description}

{pstd}
Imports networks from popular network file formats. The command automatically recognizes whether networks are directed or undirected. However, options
{bf:forcedirected} and {bf:forceundirected} can be used to override automatic detection.

The following network formats are supported:

{pmore}{help nwimport##ucinet:- Ucinet}{p_end}
{pmore}{help nwimport##pajek:- Pajek}{p_end}
{pmore}{help nwimport##matrix:- Raw adjacency matrix}{p_end}
{pmore}{help nwimport##edgelist:- Raw edgelist}{p_end}
{pmore}{help nwimport##compressed:- Compressed edgelist}{p_end}
{pmore}{help nwimport##gml:- GML}{p_end}
{pmore}{help nwimport##graphml:- GraphML}{p_end}

{pstd}
Can also be used to import networks from the internet:

{phang}
{cmd:. nwimport "http://vlado.fmf.uni-lj.si/pub/networks/data/ucinet/prison.dat", type(ucinet)}{p_end}


{marker ucinet}{...}
{title:Import Ucinet DL format}

{pstd}
{cmd:nwimport} can import the most common Ucinet DL format types: {it:fullmatrix, upperhalf, edgelist1, nodelist1}. It also supports
multiple networks ({it:nm > 0), diagonal = absent, labels:, matrix labels:, level labels:, labels embedded, row labels embedded, col labels embedded}. Two-mode
networks are not supported. For a detailed description of the Ucinet .dl file format see {browse "http://gephi.github.io/users/supported-graph-formats/ucinet-dl-format/":here}
or the {browse "https://www.soc.umn.edu/~knoke/pages/UCINET_6_User's_Guide.doc":Ucinet manual}. Here is a {help netexample##ucinet:list of popular networks delivered with Ucinet}.  

{phang}
{bf:Example 1:}{p_end}
	dl n=4 format=fullmatrix
	data:	
	0 1 1 0	
	1 0 1 1
	1 1 0 0
	0 1 0 0 

{phang}
{bf:Example 2:}{p_end}
	dl n = 4, nm = 2
	labels:
	GroupA,GroupB,GroupC,GroupD
	matrix labels:
	Marriage,Business
	data:
	0 1 0 1
	1 0 0 0
	0 0 1 0
	1 0 0 1

	0 1 1 1
	1 0 0 0
	1 0 0 1
	1 0 1 0
	
{phang}
{bf:Example 3:}{p_end}
	dl n = 4
	format = lowerhalf
	labels:
	Sanders,Skvoretz
	S.Smith,T.Smith
	data:
	2
	1 2
	1 1 2
	0 1 0 2
	
{phang}
{bf:Example 4:}{p_end}
	DL n=5
	format = edgelist1
	labels:
	george, sally, jim, billy, jane
	data:
	1 2
	1 3
	2 3
	3 1
	4 3

{phang}
{bf:Example 5:}{p_end}
	DL n=5
	format = edgelist1
	labels embedded:
	data:
	george sally
	george jim
	sally jim
	billy george
	jane jim

	
{marker pajek}{...}
{title:Import Pajek .net format}

{pstd}
{cmd:nwimport} can import the most common Pajek .net formats: {it:*arcs, *edges, *arcslist, *edgeslist, *matrix}. It also supports
multiple networks ({it:nm > 0), diagonal = absent, labels:, matrix labels:, level labels:, labels embedded, row labels embedded, col labels embedded}. Two-mode
networks are not supported. For a detailed description of the Ucinet .dl file format see {browse "http://gephi.github.io/users/supported-graph-formats/ucinet-dl-format/":here}
or the {browse "https://www.soc.umn.edu/~knoke/pages/UCINET_6_User's_Guide.doc":Ucinet manual}. Here is a {help netexample##ucinet:list of popular networks delivered with Ucinet}.  



{marker matrix}{...}
{title:Import raw adjacency matrix}

{pstd}
This imports networks that are in raw matrix format. Data can be saved as .txt, .xls or anything else. As delimiters "tab" "," ";" and " " are allowed. Furthermore, row
and/or column names can be included as well. This import option can be used to load networks from e.g. Excel. When data has already been opened/entered to Stata,
{help nwset} declares data as network data.

{phang}
{bf:Example 1:}{p_end}
	0 1 1 0
	1 0 0 0
	0 0 0 1
	0 1 0 0

{phang}
{bf:Example 2:}{p_end}
	thomas,peter,susan,kim
	0,1,1,0
	1,0,0,0
	0,0,0,1
	0,1,0,0

{pstd}
Notice that the command recognises when variable names are given in the first row. However, variable names in the
first column are not automatically recognized. One can make this explicit with the option {bf:type(matrix, rownames colnames)}.

{pstd}
Furthermore, the raw dataset can also contain additional attributes. When there are more variables than cases, all remaining
variables are treated as attributes. 

{phang}
{bf:Example 2:}{p_end}
	thomas,peter,susan,kim, sex
	0,1,1,0, male
	1,0,0,0, male
	0,0,0,1, female
	0,1,0,0, male
	
{marker edgelist}{...}
{title:Import raw edgelist}

{pstd}
This imports networks in {help nwfromedge##edgelist:raw edgelist format}. Data can already be in Stata-dta format. Otherwise, delimiters "tab" "," ";" and " " are allowed. When two columns are given
a non-valued network is loaded, when three columns are given a valued network is loaded. In case edgelist data has already been entered/opened
in Stata, {help nwfromedge} generates a network. Node labels can be embedded in the edgelist.

{phang}
{bf:Example 1:}{p_end}
	1 2
	1 4
	2 4
	4 3

{phang}
{bf:Example 2:}{p_end}
	peter,thomas,1
	thomas,susan,4
	susan,thomas3
	geoff,john,2

{marker compressed}{...}
{title:Import compressed edgelist}

{pstd}
This imports networks in compressed edgelist format. As delimiter "," is allowed. 

{phang}
{bf:Example 1:}{p_end}
	AS,MI,NY,TX
	TX,CA
	IL,AL,SD
	AL,MI,CA,NY

{phang}
{bf:Example 2:}{p_end}
	peter,thomas,mathilde,tim
	thomas,susan
	susan
	geoff,john,michael

***/
capture program drop nwimport
program nwimport
	syntax anything, type(string) [ name(string) clear nwclear nwappend xvars forcedirected forceundirected *]
	unw_defs
	local fname `"`anything'"'
	if strpos(`"`anything'"',`"""') == 0 {
		local fname  `""`fname'""'
	}
	qui `nwclear'
	qui nwset
	if "`nwappend'" == "" & (`r(networks)' > 0 | "`r(networks)'" == "") {
		di "{err}No; data in memory would be lost. Specify either option {bf:nwclear} or {bf:nwappend}."
		error 999
	}
	
	local options_original `"`options'"'
	
	if "`name'" != "" {
		local nameoff = "false"
	}
	
	gettoken type typeoptions : type, parse(",")
	local typeoptions = subinstr("`typeoptions'",",","",.)
	
	set more off

	
	if "`name'" == "" {
		local fname_temp =  lower(subinstr(`"`fname'"', char(34), "", .))
		local fnamerev = strreverse(`"`fname_temp'"')
		local bslash = strpos(`"`fnamerev'"', "/")
		local fslash = strpos(`"`fnamerev'"', "\")
		local slash = max(`bslash', `fslash')
		local slash = cond(`slash'== 0, length(`"`fnamerev'"'), `=`slash' - 1')
		local name = substr(`"`fname_temp'"', `=length(`"`fname_temp'"') - `slash' + 1', .)
		local name = subinstr(`"`name'"',".net", "", .)
		local name = subinstr(`"`name'"',".dat", "", .)
		local name = subinstr(`"`name'"',".txt", "", .)
		local name = subinstr(`"`name'"',".csv", "", .)
		local name = subinstr(`"`name'"',".dta", "", .)
		local name = subinstr(`"`name'"',".xlsx", ".xls", .)
		local name = subinstr(`"`name'"',".xls", "", .)
		local name = subinstr(`"`name'"', char(34), "", .)
	}
	
	capture qui nwset
	local nets_before = r(networks)
		
	local 0 `type'
	syntax anything(name=import_type) [, *] 
	_opts_oneof "pajek matrix edgelist compressed gml graphml ucinet" "import_type" "`import_type'" 6556
	
	local options `"`options_original'"'

	if "`import_type'" == "matrix" {
		 capture _nwimport_matrix `fname', `options' `typeoptions'
	}
	if "`import_type'" == "compressed" {
		  capture _nwimport_compressed `fname', `options' `typeoptions'
	}
	if "`import_type'" == "edgelist" {
		 capture _nwimport_edgelist `fname', `options' `typeoptions'
	}
	if "`import_type'" == "pajek" {
		  _nwimport_pajek `fname', `options'		 
	}
	if "`import_type'" == "gml" {
		capture _nwimport_gml `fname', `options'
	}
	if "`import_type'" == "graphml" {
		capture _nwimport_graphml `fname', `options'
	}
	if "`import_type'" == "ucinet" {
		 capture _nwimpdl `fname'
		  if "`nameoff'" == "" {
			local nameoff = r(nameoff)
		  }
	}
	local i = 1
	capture qui nwset
	local nets_now = `r(networks)'
	
	if `nets_now' > `nets_before'{
		forvalues j = `=`nets_before'+1'/`nets_now' {
			nwname, id(`j')
			local d `r(directed)'	

			// check if network is undirected or not - r(is_symmetric)
			// is documented (nwsym.ado) as the string "true"/"false";
			// a numeric-scalar bug meant it was actually stored numeric
			// until fixed as part of the sparse-backend migration, so
			// this call site is updated to match what nwsym now
			// actually stores.
			qui nwsym, check
			if "`r(is_symmetric)'" == "true" & "`d'" == "true" & "`forcedirected'" == ""{
				local newdirectedcmd "newdirected(false)"
			}
			if "`r(is_symmetric)'" == "false" & "`d'" == "false" & "`forceundirected'" == ""{
				local newdirectedcmd "newdirected(true)"
			}
				
			local onename : word `i' of `name'
			if "`onename'" != ""  & "`nameoff'" != "true"{
				local newnamecmd "newname(`onename')"
			}
			nwname, id(`j') `newnamecmd' `newdirectedcmd'
			if "`forceundirected'" != "" {
				nwsym `r(netname)'
			}
			if "`forcedirected'" != "" {
				nwname, id(`j') newdirected(true)
			}
			local i = `i' + 1
			qui if "`xvars'" != ""{
				nwload `r(netname)'
			}
		}
		di "{hline 30}"
		di  "{txt}{it:Importing successful}"
	}
	else {
		di 
		noi di `"{err}{it:Loading networks from file {bf:`fname'} failed}"'
		error 6750
	}
end
	
	
	

	
	
///////////////////////////
///////////////////////////

capture program drop _nwimport_pajek
program _nwimport_pajek
	version 9
	syntax [anything][, name(string) clear nwclear]

		`clear'
		`nwclear'
		set more off
		preserve
		drop _all
		
		tempfile dict
		unw_defs
		
		file open importfile using `anything', read
		file read importfile line
		local labs ""
		qui while `"`line'"' != "" {
			// get first word
			local f_cmd : word 1 of `line'
			local f_cmd = lower("`f_cmd'")
			if lower("`f_cmd'") == "*vertices" {
				local size = word(`"`line'"',2)
				local mode = "vertices"
				set obs `size'
				gen _fromid = _n
				gen _toid = _n
				gen _value = 0
				file read importfile line
				local f_star = strpos(`"`line'"', "*")
				
				// parse node labels
				if `f_star' != 1 {
					tempname dict_handler
					local num_attributes : word count `line'
					local attributes "" 
					forvalues k = 3/`num_attributes'{
						local nextattrib : word `k' of `line'
						capture confirm number `nextattrib'
						if _rc == 0 {
							local attributes "`attributes' int __x`=`k'-2'" 
						}
						else {
							local attributes "`attributes' str30 __x`=`k'-2'" 
						}
					}
					
					postfile `dict_handler' str30  `nw_nodename' `attributes' using `dict'
					while (`f_star' != 1) {
						//local tempid : word 1 of `line'
						local templab : word 2 of `line'
						local labs "`labs'`templab',"
						local attributes_post ""
						forvalues l = 3/`num_attributes' {

							local tempx : word `l' of `line'
							capture confirm number `tempx'
							if _rc == 0 {
								local attributes_post `"`attributes_post' (`tempx')"'
							}
							else {
								local attributes_post `"`attributes_post' ("`tempx'")"'
							}
						}
						
						local templab = cond("`templab'" == "", "`tempid'", "`templab'")
						local templab = subinstr("`templab'", " ","_",.)
						
						//post `dict_handler' (`tempid') ("`templab'") `attributes_post'

						post `dict_handler' ("`templab'") `attributes_post'

						file read importfile line
						local f_star = cond(`"`line'"'=="", 1, strpos(`"`line'"', "*"))	
					}
					postclose `dict_handler'
				}
				local f_cmd : word 1 of `line'
				if "`f_cmd'" == "" {
					local mode ""
				}
			}
			if lower("`f_cmd'") == "*edgeslist" {
				local mode = "edgeslist"
				local directed = "false"
				local nwfromedgeopt = "undirected"
				file read importfile line
				local f_cmd : word 1 of `line'
				local f_cmd = lower("`f_cmd'")
			}
			if lower("`f_cmd'") == "*arcslist" {
				local mode = "arcslist"
				local directed = "true"
				local nwfromedgeopt = "directed"
				file read importfile line
				local f_cmd : word 1 of `line'
				local f_cmd = lower("`f_cmd'")
			}

			if lower("`f_cmd'") == "*arcs" {
				local mode = "arcs"
				local directed = "true"
				local nwfromedgeopt = "directed"
				file read importfile line
				local f_cmd : word 1 of `line'
				local f_cmd = lower("`f_cmd'")
			}
			if lower("`f_cmd'") == "*edges" {
				local mode = "edges"
				local directed = "false"
				if "`nwfromedgeopt'" != "directed" {
					local nwfromedgeopt = "undirected"
				}
				file read importfile line
				local f_cmd : word 1 of `line'
				local f_cmd = lower("`f_cmd'")
			}
			if lower("`f_cmd'") == "*matrix" {
				local mode = "matrix"	
			}
			
			// read edges from edgelist
			if ("`mode'" == "arcs" | "`mode'" == "edges"){
				local ego = word("`line'", 1)
				local alter = word("`line'", 2)
				local newN = _N + 1
				if "`ego'" != "" & "`alter'" != "" {
					set obs `newN'
					replace _fromid = `ego' in `newN'
					replace _toid = `alter' in `newN'
					if (wordcount("`line'") - 2) > 0 {
						local value = word("`line'", 3)
					}
					else {
						local value = 1
					}
					replace _value = `value' in `newN'
				
					if "`mode'" == "edges"{
						local newN = _N + 1
						set obs `newN'
						replace _fromid = `alter' in `newN'
						replace _toid = `ego' in `newN'
						replace _value = `value' in `newN'
					}
				}
			}
			
			// read edges from compressed edgelist
			if ("`mode'" == "arcslist" | "`mode'" == "edgeslist"){
				local ego = word("`line'", 1)
				local next = 2
				local alter = word("`line'", `next')
				while "`alter'" != "" {
					local newN = _N + 1
					set obs `newN'
					replace _fromid = `ego' in `newN'
					replace _toid = `alter' in `newN'
					replace _value = 1 in `newN'
					if "`mode'" == "edgeslist" {
						local newN = _N + 1
						set obs `newN'
						replace _fromid = `alter' in `newN'
						replace _toid = `ego' in `newN'
						replace _value = 1 in `newN'
					}
					local next = `next' + 1
					local alter = word("`line'", `next') 
				}
			}
			// read edges from matrix
			if ("`mode'" == "matrix") {
				local id_ego : word `id_num' of `id'
				local id_num = `id_num' + 1
				local next = 1
				local value = word("`line'", `next') 
				while "`value'" != "" {
					local id_alter : word `next' of `id' 
					local next = `next' + 1
					if (`value' != 0 | (`id_alter' == `id_ego')){
						local newN = _N + 1
						set obs `newN'
						replace _fromid = `id_ego' in `newN'
						replace _toid = `id_alter' in `newN'
						replace _value = `value' in `newN'
					}
					local value = word("`line'", `next') 
				}	
			}
			
			file read importfile line
		}
		file close importfile

		capture replace _fromid = trim(_fromid)
		capture replace _toid = trim(_toid)
		qui nwfromedge _fromid _toid _value, name(`name') labs(`labs') `nwfromedgeopt'
	
		unw_defs
		nwload, labelonly
		qui merge m:n `nw_nodename' using `dict', nogenerate
end


capture program drop _nwimport_ucinet
program _nwimport_ucinet
	version 9
	syntax [anything][, name(string) clear nwclear]

		`clear'
		`nwclear'
		set more off
		preserve
		drop _all
		gen _fromid = ""
		gen _toid = ""
		gen _value = .
		local labs ""
	
		file open importfile using `anything', read

		local mode ""
		file read importfile line
		local l = 0
		
		// read line
		local matrix_loaded = 0
		while `"`line'"' != "" & `matrix_loaded' == 0{
			local line = subinstr(`"`line'"', "="," = ",.)
			local first : word 1 of `line'
			
			if "`mode'" == "label" {
				
				local labs "`line'"
				local labs = subinstr("`line'",","," ",.)
				//local labs `""`labs'""'
				local mode = ""
			}
			if "`mode'" == "data" & "`data_format'" == "" {
				local data_format = "fullmatrix"
			}
			if "`mode'" == "data" & "`data_format'" == "edgelist1" {
				local second : word 2 of `line'
				local value : word 3 of `line'
				if "`value'" == "" {
					local value = 1
				}
				_insert_edge, from(`first') to(`second') value(`value')
			}
			if ("`mode'" == "data" &  strpos("fullmatrix edgelist1", "`data_format'") == 0) {
				noi di "{err}format {bf:`data_format'} not supported"
				error 6705
			}
			
			if "`mode'" == "data" & "`data_format'" == "fullmatrix" {
				local matrix_loaded = 1
				insheet using `anything', delimiter(" ")  clear
				drop if _n < `l'
				foreach v of varlist _all {
					destring `v', replace
				}
				if "`labs'" == "" {
					forvalues i = 1/`nodes' {
						local labs "`labs' `i'"
					}
				}
				local k 1 
				foreach var of varlist _all {
					rename `var' net`k'
					local k = `k' + 1
				}
				nwset  _all, name(`name') labs(`labs')
			}
			
			local dl_add = 0
			if (lower("`first'") == "dl") {
				local first : word 2 of `line'
				local dl_add = 1
			}	
			if (lower("`first'") == "n") {
				local num = 3 + `dl_add'
				local nodes : word `num' of `line'
				forvalues i = 1/`nodes' {
					_insert_edge, from("`i'") to("`i'") value(0) 
				}
			}	
			if lower("`first'") == "format" {
				local data_format : word 3 of `line'
				di "Format:`format'"
			}
			
			if lower("`line'") == "labels embedded:"{
				local mode = "label"
				drop if _n <= `nodes'
			}
			if lower("`line'") == "labels:"{
				local mode = "label"
				local uselabs = "true"
			}
			if lower("`line'") == "data:"{
				local mode = "data"
			}
			local l = `l' + 1
			
			// read next line
			file read importfile line
		}
		capture file close importfile
		
		if "`uselabs'" == "" {
			local labs ""
		}
		
		if `matrix_loaded' == 0  {
			capture replace _fromid = trim(_fromid)
			capture replace _toid = trim(_toid)
			qui nwfromedge _fromid _toid _value, name(`name') labs(`labs') `nwfromedgeopt'
		}
		restore
end


capture program drop _insert_edge
program _insert_edge
	syntax, from(string) to(string) value(string)
	
	if ("`from'" != "-1" & "`to'" != "-1"){
		local n = _N
		local newN = `n' + 1
		set obs `newN'
		replace _fromid = "`from'" in `newN'
		replace _toid = "`to'"  in `newN'
		replace _value = `value' in `newN'
	}
end	


capture program drop _nwimport_matrix
program _nwimport_matrix
	syntax anything, [name(string) delimiter(string) directed rownames colnames ] 
	if "`name'" == "" {
		local name "network"
	}
	
	if "`rownames'" != "" {
		local firstrow = "firstrow"
		local varnames = "names"
	}

	local excelfile = strpos(`"`anything'"', ".xls")
	local excelfile = (`excelfile' != 0)
	
	local success = 0
	local excel = 0
	local pot_delimiters = `""tab" ";" "," " ""'
	local pot_delimiters_length : word count `pot_delimiters'
	local i = 1
	
	// Excel file detected
	if (`excelfile' != 0){
		local excel = 1
		import excel `anything',  `firstrow' clear
	}
	else {	
		while (`excel' == 0 & "`delimiter'" == "" & `success' == 0 & `i' <= `pot_delimiters_length'){
			local use_delimiter : word `i' of `pot_delimiters'
			local i = `i' + 1
		
			if "`use_delimiter'" == "tab" {
				local insheet_opt = ", tab clear"
			}
			else {
				local insheet_opt = `", delimiter("`use_delimiter'") clear"'
			}
	
			insheet using `anything' `insheet_opt' `varnames'
			if `c(k)' == 1 {
				split v1, parse(" ")
				drop v1
				foreach v of varlist _all {
					if `v'[1] == "" {
						drop `v'
					}
				}
				destring _all, replace
			}
			
			if (`c(k)' == 1){
				local success = 0
			}
			else {
				local success = 1
			}
		}
		if "`delimiter'" != "" {
			local insheet_opt = ", clear"
			insheet using `anything' `insheet_opt' `varnames' delimiter("`delimiter'")
			if `c(k)' == 1 {
				split v1, parse(" ")
				drop v1
				foreach v of varlist _all {
					if `v'[1] == "" {
						drop `v'
					}
				}
				destring _all, replace
			}
			
			if (`c(k)' == 1){
				local success = 0
			}
			else {
				local success = 1
			}
		}
	}
	
	// Check for rownames and colnames
	ds
	local firstvar : word 1 of `r(varlist)'
	local secondvar : word 2 of `r(varlist)'
	
	if "`rownames'" == "" { 
		local check1 = `secondvar'[1]
		capture confirm number `check1'
		if _rc != 0 {
			local rownames "rownames"
		}
	}
	
	if "`colnames'" == "" {
		local check2 = `firstvar'[2]
		capture confirm number `check2'
		if _rc != 0 {
			local colnames "colnames"
		}
	}
	
	unab varlist : _all 
	
	if "`colnames'" == "colnames" {
		local labscmd " labsfromvar(`firstvar')"
		local varlist : list varlist - firstvar
	}	
	if "`rownames'" == "rownames" {
		local newvarlist ""
		local coladd = 0
		if "`colnames'" != "" {
			local coladd = 1
		}
		local k_start = 1 + `coladd'
		local k_end = `=_N' + `coladd'
		
		local k = 1
		foreach var of varlist _all {
			if `k' >= `k_start' & `k' <= `k_end' {
				local newvarlist "`newvarlist' `var'"
			}
			local k = `k' + 1
		}
		local varlist "`newvarlist'"
	}
	
	destring `varlist', force replace
	nwset `varlist', name("`name'") `labscmd'
	drop `firstvar'
end

capture program drop _nwimport_gml
program _nwimport_gml
	version 9
	syntax [anything][, name(string) clear nwclear]

		`clear'
		`nwclear'
		set more off
		preserve
		drop _all
		gen _fromid = ""
		gen _toid = ""
		gen _value = .
		local labs ""
		
		file open importfile using `anything', read

		local mode ""
		file read importfile line
		// read line
		while `"`line'"' != "" {
			tokenize `"`line'"'
			local i = 1
			// read all elements
			while "``i''" != "" {
				if "``i''" == "id" & "`mode'" == "node" {
					local mode_sub = "node_id"
					local node = "``=`i'+1''"
					_insert_edge, from(`node') to(`node') value(0)
				}
				if "``i''" == "label" & "`mode'" == "node" {
					local mode_sub = "node_label"
					local nextlab `"``=`i'+1''"'
					local labs `"`labs' "`nextlab'""'
				}
				if "``i''" == "source" & "`mode'" == "edge" {
					local mode_sub = "edge_source"
					local source = "``=`i'+1''"
					_insert_edge, from(`source') to(`target') value(1)
				}
				if "``i''" == "target" & "`mode'" == "edge" {
					local mode_sub = "edge_target"
					local target = "``=`i'+1''"
					_insert_edge, from(`source') to(`target') value(1)
				}
				if "``i''" == "node" {
					local mode = "node"
				}
				if "``i''" == "edge" {
					local mode = "edge"
					local target = -1
					local source = -1
				}
				local i = `i' + 1
			}
			// read next line
			file read importfile line
		}	
		capture file close importfile
		capture replace _fromid = trim(_fromid)
		capture replace _toid = trim(_toid)
		nwfromedge _fromid _toid _value, name(`name') labs(`labs') `nwfromedgeopt'
		restore
end


capture program drop _nwimport_gefx
program _nwimport_gefx
	version 9
	syntax [anything][, name(string) clear nwclear]

		`clear'
		`nwclear'
		set more off
		preserve
		drop _all
		gen _fromid = ""
		gen _toid = ""
		gen _value = .
		local labs ""
		
		file open importfile using `anything', read

		local mode ""
		file read importfile line
		// read line
		while `"`line'"' != "" {
			local line = subinstr(`"`line'"', "="," = ",.)
			tokenize `"`line'"'
			local i = 1
			// read all elements
			while "``i''" != "" {
				if "``i''" == "id" & "`mode'" == "node" {
					local mode_sub = "node_id"
					local node = "``=`i'+2''"
					_insert_edge, from(`node') to(`node') value(0)
				}
				if "``i''" == "label" & "`mode'" == "node" {
					local mode_sub = "node_label"
					local nextlab ``=`i'+2''
					local labs "`labs' `nextlab'"
				}
				if "``i''" == "source" & "`mode'" == "edge" {
					local mode_sub = "edge_source"
					local source = ``=`i'+2''
					_insert_edge, from(`source') to(`target') value(1)
				}
				if "``i''" == "target" & "`mode'" == "edge" {
					local mode_sub = "edge_target"
					local target = ``=`i'+2''
					_insert_edge, from(`source') to(`target') value(1)
				}
				if "``i''" == "<node" {
					local mode = "node"
				}
				if "``i''" == "<edge" {
					local mode = "edge"
					local target = -1
					local source = -1
				}
				local i = `i' + 1
			}
			// read next line
			file read importfile line
		}
		capture file close importfile
		capture encode _fromid, gen(_fromidnum)
		if _rc != 0 {
			gen _fromidnum = _fromid
		}
		capture encode _toid, gen(_toidnum)
		if _rc != 0 {
			gen _toidnum = _toid
		}	
		capture replace _fromidnum = trim(_fromidnum)
		capture replace _toidnum = trim(_toidnum)
		nwfromedge _fromidnum _toidnum _value, name(`name') labs(`labs') `nwfromedgeopt'
		restore
end


capture program drop _nwimport_edgelist
program _nwimport_edgelist
	syntax anything, [keeporiginal name(string) delimiter(string) directed undirected xvars] 
	if "`name'" == "" {
		local name "network"
	}

	if (strpos(lower(`anything'), ".dta") != 0) | (strpos(lower(`anything'), ".DTA") != 0)  {
		//preserve
		use `anything', clear
		ds
		local ego : word 1 of `r(varlist)'
		local alter : word 2 of `r(varlist)'
		local value : word 3 of `r(varlist)'
		replace `alter' = `ego' if `alter' == .
		drop if `ego' == .
		nwfromedge `ego' `alter' `value', `keeporiginal' `undirected' `direcetd' `xvars' name(`name')
		//restore
	}
	else {
	
	//preserve
	clear
	
	local success = 0
	local excel = 0
	local pot_delimiters = `""tab" ";" "," " ""'
	local pot_delimiters_length : word count `pot_delimiters'
	local i = 1

	// Excel file detected
	if (strpos(`"`anything'"', ".xls") != 0 ){
		local excel = 1
		import excel `anything', clear
		if c(k) == 1 | _rc != 0 {
			local success = 0
		}
		else {
			local success = 1
		}
	}
 
	local i = 1
	while (`excel' == 0 & "`delimiter'" == "" & `success' == 0 & `i' <= `pot_delimiters_length'){
		local use_delimiter : word `i' of `pot_delimiters'
		local i = `i' + 1
		
		if "`use_delimiter'" == "tab" {
			local insheet_opt = ", tab clear"
		}
		else {
			local insheet_opt = `", delimiter("`use_delimiter'") clear"'
		}
		
		capture insheet using `anything' `insheet_opt'
		
		// Check for failure
		if c(k) == 1 | _rc != 0{
			local success = 0
			clear
		}
		else {
			local success = 1
		}
	}
	
	if `excel' != 0 {
	// Try other delimiters
    if ("`delimiter'" != ""){
		insheet using `"`anything'"', delimiter("`delimiter'") clear
		
		di `"insheet using `"`anything'"', delimiter("`delimiter'") clear"'
		// Check for failure
		if c(k) == 1 | _rc != 0 {
			local success = 0
		}
		else {
			local success = 1
		}
	}
	}
	
	if `success' == 0 {
		noi di "{err}{it:edgelist} could not be loaded"
		restore
		error 6704
	}

	if `c(k)' > 3 | `c(k)' < 2 {
		noi di "{err}Something went wrong; data has more than three columns."
		restore
		error 6704
	}
	nwfromedge _all, name(`name') `keeporiginal' `directed' `undirected' `xvars'
	//restore
	}
end


capture program drop _nwimport_compressed
program _nwimport_compressed
	syntax anything, [name(string) delimiter(string) directed undirected xvars keeporiginal] 
	if "`name'" == "" {
		local name "network"
	}
	if "`delimiter'" == "" {
		local delimiter = "comma"
	}
	
	//preserve
	clear
	
	local anyting "compressed_example.txt"
	import delimited `anything', delimiter(`delimiter') varnames(noname) clear
	rename v1 ego
	capture replace v2 = ego if v2 == ""
	capture replace v2 = ego if v2 == .
	
	reshape long v, i(ego) j(j)
	keep if v != "" | j == 2
	rename v alter
	replace ego = trim(ego)
	replace alter = trim(alter)
	nwfromedge ego alter, `directed' `undirected' `xvars' name(`name') `keeporiginal'

	//restore
	
	if "`xvars'" != "" {
		nwload
	}
end



capture program drop _nwimpdl_nodelist1
program _nwimpdl_nodelist1
	syntax, filehandler(string) nodes(int) [undirected directed rankedlist edgelist netlabs(string) labs(string) labelsembedded collabsembedded rowlabsembedded]

	preserve
	clear
	
	set obs `nodes'
	gen _fromid = ""
	gen _toid = ""
	gen _value = .
	
	if "`labelsembedded'" != "" {
		foreach onenode in `labs' {
			local onenode = lower("`onenode'")
			_insert_edge, from("`onenode'") to("`onenode'") value(0)
		}
	}
	else {
		forvalues i = 1/`nodes' {
			_insert_edge, from("`i'") to("`i'") value(0)
		}
	}
	
	local r = 0
	file read `filehandler' line
	
	if "`collabsembedded'" != "" {
		local labs "`line'"
		file read `filehandler' line
	}	
	if "`rowlabsembedded'" != "" {
		local r = 1
	}	
	
	local lc : word count `labs'
	local labscomplete = cond(`lc' == `nodes', "true", "")

	while r(eof)==0 {	
		if "`rowlabsembedded'" != "" & "`labscomplete'" == "" {
			local onelab : word 1 of `line'
			labs "`labs' `onelab'"
		}
		local wc : word count `line'
		local sender : word `=1 + `r'' of `line'
		local sender = lower("`sender'")
		if "`edgelist'" != "" {
			local wc = `=2+`r''
		}
		
		forvalues i = `=2+`r''/ `wc' {
			local receiver : word `i' of `line'
			local receiver = lower("`receiver'")
			if "`rankedlist'" == "" {
				local value 1
			}
			else{
				local value = `i' - `=2+`r'' + 1
			}
			if "`edgelist'" != "" {
				local value1 :  word `=`i'+1' of `line'
				capture confirm number `value1'
				if _rc == 0 {
					local value `value1'
				}
			}
			capture _insert_edge, from("`sender'") to("`receiver'") value(`value')
		}
		file read `filehandler' line
	}
	file close `filehandler'
	capture drop if _fromid == .
	capture drop if _fromid == ""
	
	nwfromedge _all, name(`netlabs') labs(`labs') `directed' `undirected' `xvars'
	restore
end



capture program drop _nwimpdl_fullmatrix
program _nwimpdl_fullmatrix
	syntax, filehandler(string) nodes(int) nets(int) [directed netlabs(string) labs(string)  diagonal(string) rowlabsembedded collabsembedded]

	mata: onenet = J(`nodes', `nodes', 0)
	
	file read `filehandler' line	
	local lc = 1
	local x = 1
	local y = 0
	local twc = 0
	local netcounter 1
	
	if "`collabsembedded'" != "" {
		local labs "`line'"
		file read `filehandler' line
	}	
		
	while r(eof)==0 {
		
		local wc : word count `line'
		
		local nc = `nodes'
		if "`diagonal'" == "absent" {
			local nc = `nc' - 1
		}
		if "`rowlabsembedded'" != "" {
			local nc = `nc' + 1
		}
		
		forvalues i = 1/ `wc' {
			local ncc = `nc' * `nodes'
			local oneword : word `i' of `line'
			local twc = `twc' + 1
			
			if mod(`twc', `nc') == 1  & "`rowlabsembedded'" != "" {
				local newlabs "`newlabs' ``oneword'" 
			}	
			else {
				local y = `y' + 1 
				if `y' > `nodes' {
					local y = 1
					local x = `x' + 1
				}
				if "`oneword'" != "0" {
					mata: onenet[`x', `y'] = `oneword'
				}
				// one network complete
				if `y' == `nodes' & `x' == `nodes' {
					local onename : word `netcounter' of `netlabs'
					mata: st_numscalar("r(issymmetric)", issymmetric(onenet))
					local symmetric = `r(issymmetric)'
					nwset, name(`onename') labs(`labs') mat(onenet) 
					if "`symmetric'" == "1" & "`directed'" == "" {
						nwsym `onename'
					}
					
					mata: onenet = J(`nodes', `nodes', 0)
					local x = 1
					local y = 0
					local netcounter = `netcounter' + 1
				}
			}
		}	
		file read `filehandler' line
	}
	file close `filehandler'
end


capture program drop _nwimpdl_lowerhalf
program _nwimpdl_lowerhalf
	syntax, filehandler(string) nodes(int) nets(int) [ directed netlabs(string) labs(string)  diagonal(string) rowlabsembedded collabsembedded]

	mata: onenet = J(`nodes', `nodes', 0)
	
	file read `filehandler' line	
	local lc = 1
	local twc = 0
	local netcounter 1
	local y = 1
	local x = 0
	local ab = 0
	
	if "`collabsembedded'" != "" {
		local labs "`line'"
		file read `filehandler' line
	}	
	
	if "`diagonal'" == "absent" {
		local ab = 1
		local y = 2
	}
		
	while r(eof)==0 {		
		local wc : word count `line'
		forvalues i = 1/ `wc' {
			local twc = `twc' + 1
	
			if `x' >= `y'-`ab' {
				local x = 1
				local y = `y' + 1
			}
			else {
				local x = `x' + 1
			}
			

			local oneword : word `i' of `line'
			
			di "x:`x'  y:`y'  v:`oneword'"
						
			mata: onenet[`x',`y'] = `oneword'
			mata: onenet[`y',`x'] = `oneword'
		
			if (`y' == `nodes' & `x' == `nodes' - `ab') {
				local onename : word `netcounter' of `netlabs'
				nwset, name(`onename') labs(`labs') mat(onenet) 
				mata: onenet = J(`nodes', `nodes', 0)
				local x = 0
				local y = 0 + `ab'
				local netcounter = `netcounter' + 1
			}
		}	
		file read `filehandler' line
	}
	file close `filehandler'
end

capture program drop _nwimpdl
program _nwimpdl 
	syntax anything, [ netlistonly ]

	local nodes = ""
	local nets = "1"
	local cols = ""
	local rows = ""
	local format = "fullmatrix"
	local diagonal = ""
	local labels_on = 0
	local labs ""
	local netlabels_on = 0
	local netlabs ""
	local data_on = 0
	local rowlab_embedded ""
	local collab_embedded ""
	local labels_embedded ""
	
	local diagonal = ""
	tempname importfile
	
	// parse header of .dl file
	file open `importfile' using `anything', read
	
	file read `importfile' line
	local firstword : word 1 of `line'
	local firstword = trim(lower("`firstword'"))

	// check for .dl format
	if "`firstword'" != "dl" {
		noi di "{err}No valid {bf:.dl} file"
		error 6099
	}
	
	set more off
	// parse header until data part
	while  ("`firstword'" != "data:") {
		local line : subinstr local line "=" " ", all
		local line : subinstr local line "," " ", all
		local line : subinstr local line ";" " ", all
		
		// parse word by word
		local lc : word count `line'
		forvalues i = 1/ `lc' {
			local oneword : word `i' of `line'
			
			local keywords = "level matrix n nm nr nc format data: labels: diagonal"
			local oneword_low = lower("`oneword'")
			local key : list oneword_low  & keywords
			
			if `labels_on' == 1 & `netlabels_on' == 0 & "`key'" == "" {
				local labs "`labs' `oneword'"
			}
			else {
				local labels_on = 0
			}
			if `netlabels_on' == 1 & "`key'" == "" {
				local netlabs "`netlabs' `oneword'"
			}
			else {
				//local netlabels_on = 0
			}
			
			if (lower("`oneword'") == "n"){
				local nodes : word `=`i' + 1' of `line'
			}
		
			if (lower("`oneword'") == "nm") {
				local nets : word `=`i' + 1' of `line'
			}
			if (lower("`oneword'") == "nr") {
				local rows : word `=`i' + 1' of `line'
			}
			if (lower("`oneword'") == "nc") {
				local cols : word `=`i' + 1' of `line'
			}
			if (lower("`oneword'") == "format") {
				local format : word `=`i' + 1' of `line'
				local format = lower("`format'")
			}
			if (lower("`oneword'") == "diagonal") {
				local diagonal : word `=`i' + 1' of `line'
				local diagonal = lower("`diagonal'")
			}	
			
			if (lower("`oneword'") == "labels:") {
				if `netlabels_on' == 0 {
					local labels_on = 1
				}	
			}
			if (lower("`oneword'") == "labels"){
				local secondword : word `=`i' + 1' of `line'
				if (lower("`secondword'") == "embedded"){
					local labels_embedded "labelsembedded"
				}
			}
			
			if (lower("`oneword'") == "matrix" | lower("`oneword'") == "level") {
				local secondword : word `=`i' + 1' of `line'
				if (lower("`secondword'") == "labels:"){
					local labels_on = 0
					local netlabels_on = 1	
					local nameoff = "true"
				}
			}
			if (lower("`oneword'") == "row" | lower("`oneword'") == "col") {
				local secondword : word `=`i' + 1' of `line'
				if (lower("`secondword'") == "labels"){
					local thirdword : word `=`i' + 2' of `line'
					if (lower("`thirdword'") == "embedded"){
						if (lower("`oneword'") == "row")  {
							local rowlab_embedded = "rowlabsembedded"
						}
						if (lower("`oneword'") == "col")  {
							local collab_embedded = "collabsembedded"
						}
					}
				}
			}
		}
		file read `importfile' line
		local firstword : word 1 of `line'
		local firstword = lower("`firstword'")
	}

	if "`rows'" != "`cols'" {
		noi di "{err}Two-mode networks are not supported"
		error 6088
	}
	
	local labscount : word count `labs'
	if `labscount' > `nodes' {
		local newlabs ""
		forvalues i = 1/`nodes' {
			local onelab : word `i' of `labs'
			local newlabs "`newlabs' `onelab'"
		}
		local labs `newlabs'
	}
	
	local format = lower("`format'")
	
	if "`netlistonly'" == "" {
		if lower("`format'") == "fullmatrix" {
			di "full"
			capture _nwimpdl_fullmatrix, filehandler(`importfile') labs(`labs') netlabs(`netlabs') nodes(`nodes') nets(`nets') diagonal(`diagonal') `rowlab_embedded' `collab_embedded'
		}
		if lower("`format'") == "nodelist1" {
			qui  capture _nwimpdl_nodelist1, filehandler(`importfile') labs(`labs') netlabs(`netlabs') nodes(`nodes') `labels_embedded' `rowlab_embedded' `collab_embedded'
		}
		if lower("`format'") == "rankedlist1" {
			qui capture  _nwimpdl_nodelist1, rankedlist filehandler(`importfile') labs(`labs') netlabs(`netlabs') nodes(`nodes') `labels_embedded' `rowlab_embedded' `collab_embedded'
		}
		if lower("`format'") == "edgelist1" {
			qui capture _nwimpdl_nodelist1, edgelist filehandler(`importfile') labs(`labs') netlabs(`netlabs') nodes(`nodes') `labels_embedded' `rowlab_embedded' `collab_embedded'
		}
		if lower("`format'") == "lowerhalf" {
			if "`rowlabsembedded'" != "" {
				noi di "{err}Ucinet {bf:row labels embedded} not supported together with format {bf:lowerhalf}"
			}
			else {
				capture _nwimpdl_lowerhalf, filehandler(`importfile') labs(`labs') netlabs(`netlabs') nodes(`nodes') nets(`nets') diagonal(`diagonal') `rowlab_embedded' `collab_embedded'
			}
		}
	}
	mata: st_global("r(netlabs)", "`netlabs'")
	
	capture file close `importfile'
	local sformat "fullmatrix nodelist1 edgelist1 lowerhalf"
	local f : list format & sformat
			
	if "`f'" == "" {
		noi di "{err}Ucinet format = {bf:`format'} not supported."
	}	
	mata: st_global("r(nameoff)","`nameoff'")
end

	
	






	
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
