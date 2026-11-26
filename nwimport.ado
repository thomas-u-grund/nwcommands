capture program drop nwimport
program nwimport, rclass
	syntax anything, type(string) [ name(string) clear nwclear nwappend xvars forcedirected forceundirected *]
	unw_defs
	local fname `"`anything'"'
	if strpos(`"`anything'"',`"""') == 0 {
		local fname  `""`fname'""'
	}
	// `clear' was previously accepted by syntax but never referenced here -
	// a dead no-op that neither behaved like Stata's own `clear' nor
	// satisfied the "data would be lost" guard immediately below the way
	// `nwclear' does. Treated as a synonym for `nwclear', matching how
	// several other import-family Stata commands accept `clear' as a
	// general-purpose alias.
	if "`clear'" != "" {
		local nwclear "nwclear"
	}
	qui nwset
	if "`nwappend'" == "" & "`nwclear'" == "" & ("`r(networks)'" == "" | real("`r(networks)'") > 0) {
		di "{err}No; data in memory would be lost. Specify either option {bf:nwclear} or {bf:nwappend}."
		exit 999
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
		// the name of the file is what follows the last separator of either kind (a Windows path can hold both)
		local fname_temp = subinstr(`"`fname_temp'"', char(92), "/", .)
		local fnamerev = strreverse(`"`fname_temp'"')
		local slash = strpos(`"`fnamerev'"', "/")
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
		// any other extension goes too, and what is left is made a valid name (my-net.gml: my_net)
		local name = regexr(`"`name'"', "\.(gml|dl|paj|graphml|tsv)$", "")
		local name = strtoname(`"`name'"')
		if inlist("`name'", "_all", "_n", "_N", "if", "in", "using", "byte", "int", "long") local name "net_`name'"
	}
	
	local 0 `type'
	syntax anything(name=import_type) [, *] 
	// BUGFIX: "graphml" was accepted here and documented in nwimport.sthlp
	// as a supported type(), but _nwimport_graphml (called below) was
	// never actually implemented anywhere in this file - every graphml
	// import failed with a generic, uninformative "loading networks...
	// failed" (the real cause, "command _nwimport_graphml is
	// unrecognized", was silently swallowed by the outer capture).
	// Removed from the allowed-type list and from the .sthlp until a
	// real implementation exists, rather than continuing to advertise a
	// type that cannot work.
	_opts_oneof "pajek matrix edgelist compressed gml ucinet" "import_type" "`import_type'" 6556
	
	local options `"`options_original'"'

	// Nothing of the user's is touched before the import has succeeded. The file is loaded in a work frame of its
	// own, so the data in memory stay as they are. With nwclear the networks are not dropped yet: they are set
	// aside under another name and brought back when the import fails.
	if "`nwclear'" != "" {
		capture mata: mata drop __nwibak
		capture mata: mata rename `nw' __nwibak
	}
	local __nwi_cur ""
	capture qui nwset
	local nets_before = cond("`r(networks)'" == "", 0, real("`r(networks)'"))
	if `nets_before' > 0 {
		mata: st_local("__nwi_cur", `nws'.get_current_name())
	}
	local __nwi_home "`c(frame)'"
	// data in memory (with or without unsaved changes) are only replaced with clear or nwclear
	local __nwi_keepdata = ("`nwclear'" == "" & (c(k) > 0 | _N > 0))
	tempname __nwi_work
	frame create `__nwi_work'
	frame change `__nwi_work'
	global NWIMPORT_relabel ""
	global NWIMPORT_error ""
	local __nwi_declared ""

	local __nwi_rc 0
	if "`import_type'" == "matrix" {
		capture noisily quietly _nwimport_matrix `fname', `options' `typeoptions'
		local __nwi_rc = _rc
	}
	if "`import_type'" == "compressed" {
		capture noisily quietly _nwimport_compressed `fname', `options' `typeoptions'
		local __nwi_rc = _rc
	}
	if "`import_type'" == "edgelist" {
		// forceundirected on a list: build the network undirected from the start (the missing direction of each tie gets
		// its value); symmetrising a directed network afterwards would keep 0 instead of a negative value
		if "`forceundirected'" != "" & strpos(" `options' `typeoptions' ", "undirected") == 0 & strpos(" `options' `typeoptions' ", "directed") == 0 {
			local typeoptions "`typeoptions' undirected"
		}
		capture noisily quietly _nwimport_edgelist `fname', `options' `typeoptions'
		local __nwi_rc = _rc
	}
	if "`import_type'" == "pajek" {
		capture noisily _nwimport_pajek `fname', `options'
		local __nwi_rc = _rc
	}
	if "`import_type'" == "gml" {
		capture noisily quietly _nwimport_gml `fname', `options'
		local __nwi_rc = _rc
	}
	if "`import_type'" == "ucinet" {
		capture noisily quietly _nwimpdl `fname'
		local __nwi_rc = _rc
		if `__nwi_rc' == 0 & "`nameoff'" == "" {
			local nameoff = r(nameoff)
		}
	}
	// close the files of the importers, also after an error (an open handle would stop every later import)
	capture file close importfile
	capture file close nwimpdl_fh
	capture file close nwimpdl_rfh
	capture postclose nwimpdl_post
	
	// the option directed of a list or matrix, given in type() or on its own, is a declaration too: such a network
	// stays directed also when every tie is reciprocated
	if inlist("`import_type'", "edgelist", "compressed", "matrix") {
		local __nwi_words `" `options' `typeoptions' "'
		if strpos(`"`__nwi_words'"', " directed ") > 0 local __nwi_declared "directed"
	}
	
	local nets_now `nets_before'
	capture qui nwset
	if _rc == 0 & "`r(networks)'" != "" local nets_now = `r(networks)'
	local __nwi_new ""
	local __nwi_prc 0
	if `__nwi_rc' == 0 & `nets_now' > `nets_before' {
		capture noisily {
			local i = 1
			forvalues j = `=`nets_before'+1'/`nets_now' {
				nwname, id(`j')
				local d `r(directed)'	
				// a temporal network keeps the direction it was declared with
				local __nwi_temp "`r(temporal)'"
				local newdirectedcmd ""
				local newnamecmd ""
		
				// check if network is undirected or not - r(is_symmetric)
				// is documented (nwsym.ado) as the string "true"/"false";
				// a numeric-scalar bug meant it was actually stored numeric
				// until fixed as part of the sparse-backend migration, so
				// this call site is updated to match what nwsym now
				// actually stores.
				qui nwsym, check
				// a file that declares its ties directed (Pajek *Arcs, GML directed 1) stays directed
				if "`r(is_symmetric)'" == "true" & "`d'" == "true" & "`forcedirected'" == "" & "`__nwi_temp'" != "true" & "`__nwi_declared'" != "directed" {
					local newdirectedcmd "newdirected(false)"
				}
				if "`r(is_symmetric)'" == "false" & "`d'" == "false" & "`forceundirected'" == "" & "`__nwi_temp'" != "true"{
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
				qui nwname, id(`j')
				local __nwi_new "`__nwi_new' `r(netname)'"
				local i = `i' + 1
			}
		}
		local __nwi_prc = _rc
	}
	
	frame change `__nwi_home'
	local __nwi_relabel "$NWIMPORT_relabel"
	local __nwi_error `"$NWIMPORT_error"'
	macro drop NWIMPORT_relabel NWIMPORT_error
	capture mata: mata drop __nwimport_*
	
	if `__nwi_rc' != 0 | `__nwi_prc' != 0 | `nets_now' <= `nets_before' {
		// failed: the data were not touched; remove what was created and bring the networks back
		capture frame drop `__nwi_work'
		if "`nwclear'" != "" | `nets_before' == 0 {
			capture mata: mata drop `nw'
			if "`nwclear'" != "" capture mata: mata rename __nwibak `nw'
		}
		else {
			qui nwset
			local __nwi_all "`r(nets)'"
			local __nwi_drop ""
			local __nwi_k = 0
			foreach __nwi_n of local __nwi_all {
				local __nwi_k = `__nwi_k' + 1
				if `__nwi_k' > `nets_before' local __nwi_drop "`__nwi_drop' `__nwi_n'"
			}
			if "`__nwi_drop'" != "" qui nwdrop `__nwi_drop'
			mata: `nws'.make_current_from_name("`__nwi_cur'")
		}
		mata: st_rclear()
		if `__nwi_rc' == 1 | `__nwi_prc' == 1 {
			exit 1
		}
		// the Pajek reader and the refusal of a tie inside a mode (459) keep their own return codes
		if `__nwi_rc' != 0 & ("`import_type'" == "pajek" | `__nwi_rc' == 459) {
			exit `__nwi_rc'
		}
		di 
		if `"`__nwi_error'"' != "" noi di `"{err}{p 0 0 2}`__nwi_error'{p_end}"'
		noi di `"{err}{it:Loading networks from file {bf:`fname'} failed}"'
		exit 480
	}
	
	capture mata: mata drop __nwibak
	// the data that the importer leaves (node names, matrix columns, node attributes) go into memory when there was
	// nothing to lose or the user asked for it with clear or nwclear
	frame `__nwi_work': local __nwi_wk = c(k)
	if !`__nwi_keepdata' {
		if `__nwi_wk' > 0 {
			qui frame copy `__nwi_work' `__nwi_home', replace
		}
		else if "`nwclear'" != "" {
			clear
		}
	}
	else {
		frame `__nwi_work' {
			capture unab __nwi_extra : _all
			local __nwi_extra : list __nwi_extra - nw_nodename
			local __nwi_extra : list __nwi_extra - nw_included
			capture confirm variable _nodeoriginal
			local __nwi_orig = (_rc == 0)
			local __nwi_nattr : char _dta[nwimport_attributes]
		}
		if "`__nwi_nattr'" != "" | `__nwi_orig' {
			di "{txt}{p 0 0 2}(note: the data in memory are kept, so the node variables of the file (`=trim("`__nwi_nattr' `=cond(`__nwi_orig', "_nodeoriginal", "")'")') are not loaded; to get them, import into an empty data set or specify {bf:nwclear}){p_end}"
		}
	}
	frame drop `__nwi_work'
	// columns of an adjacency matrix imported into an empty data set hold the ties under the node names: they count
	// as variables made by nwload, so that nwload and nwsync may refresh them
	if "`xvars'" == "" & !`__nwi_keepdata' & "`import_type'" == "matrix" {
		foreach __nwi_n of local __nwi_new {
			_nwsyntax `__nwi_n', max(1) other(__nwim)
			mata: st_local("__nwi_nv", invtokens(`__nwimnetobj'->get_nodesvar()))
			foreach __nwi_v of local __nwi_nv {
				capture confirm variable `__nwi_v', exact
				if _rc == 0 char `__nwi_v'[nwload] "`__nwi_n'"
			}
		}
	}
	if "`xvars'" != "" {
		foreach __nwi_n of local __nwi_new {
			// without data of the user to keep, variables of these names are the import's own
			if `__nwi_keepdata' qui nwload `__nwi_n', keepuser
			else qui nwload `__nwi_n', overwrite
		}
	}
	if "`__nwi_relabel'" != "" {
		di "{txt}{p 0 0 2}(note: node names cannot hold commas or double quotes; commas were replaced by blanks and double quotes by apostrophes, with a suffix _2, _3, ... where two names became equal){p_end}"
	}
	di "{hline 30}"
	di  "{txt}{it:Importing successful}"
	mata: st_rclear()
	capture confirm number 0
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
		// the network is valued when the file gives tie values (a third field on an edge line, a matrix with values)
		local __haswt 0
		// the direction the file declares: lines in an *Arcs or an *Edges section
		local __arcsec 0
		local __edgesec 0
		local __narcs 0
		local __nedges 0
		local __relab 0
		local __mrow 0
		local size ""
		preserve
		drop _all
		
		tempfile dict
		unw_defs
		
		tempfile __nwi_masked
		_nwimport_apos `anything' `"`__nwi_masked'"'
		// the reader below takes an empty line as the end of the file: blank and comment lines are removed first
		tempfile __nwi_noblank
		mata: nwimp_pajeklines(st_local("__nwi_file"), st_local("__nwi_noblank"))
		local __nwi_file `"`__nwi_noblank'"'
		capture file close importfile
		file open importfile using `"`__nwi_file'"', read
		file read importfile line
		local labs ""
		qui while `"`line'"' != "" {
			// get first word
			local f_cmd : word 1 of `line'
			local f_cmd = lower("`f_cmd'")
			// the level labels of a two-mode network (comment line written by nwexport)
			if "`f_cmd'" == "%" & word(`"`line'"', 2) == "nwcommands" & word(`"`line'"', 3) == "level" & word(`"`line'"', 4) == "labels" {
				local __lv1 = subinstr(word(`"`line'"', 5), char(34), "", .)
				local __lv2 = subinstr(word(`"`line'"', 6), char(34), "", .)
			}
			if lower("`f_cmd'") == "*vertices" {
				local size = word(`"`line'"',2)
				// "*Vertices n n1" (Pajek's bipartite form): the first n1 vertices are the nodes of the first mode
				local n1 ""
				capture confirm integer number `=word(`"`line'"',3)'
				if _rc == 0 local n1 = word(`"`line'"',3)
				local mode = "vertices"
				set obs `size'
				gen _fromid = _n
				gen _toid = _n
				gen _value = 0
				file read importfile line
				local f_star = strpos(`"`line'"', "*")
				
				// parse node labels
				if `f_star' != 1 {
					local dict_handler "nwimpdl_post"
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
						// the labels are handed on as a comma separated list: no comma or double quote inside a label
						local templab = subinstr(`"`templab'"', "__nwapos__", "'", .)
						if strpos(`"`templab'"', ",") | strpos(`"`templab'"', char(34)) {
							local templab = subinstr(`"`templab'"', char(34), "'", .)
							local templab = strtrim(stritrim(subinstr(`"`templab'"', ",", " ", .)))
							if `"`templab'"' == "" local templab "_"
							local __relab 1
						}
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
				local __arcsec 1
				local mode = "arcs"
				local directed = "true"
				local nwfromedgeopt = "directed"
				file read importfile line
				local f_cmd : word 1 of `line'
				local f_cmd = lower("`f_cmd'")
			}
			if lower("`f_cmd'") == "*edges" {
				local __edgesec 1
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
				if "`size'" == "" | "`n1'" != "" {
					noi di "{err}{p 0 0 2}*Matrix is read for a square matrix after a *Vertices line only (not for a two-mode network){p_end}"
					exit 6705
				}
				local mode = "matrix"
				local __mrow 0
				file read importfile line
				local f_cmd : word 1 of `line'
				local f_cmd = lower("`f_cmd'")
			}
			
			// read edges from edgelist
			if ("`mode'" == "arcs" | "`mode'" == "edges"){
				local ego = word("`line'", 1)
				local alter = word("`line'", 2)
				local newN = _N + 1
				if "`ego'" != "" & "`alter'" != "" {
					if "`mode'" == "arcs" local __narcs 1
					else local __nedges 1
					set obs `newN'
					replace _fromid = `ego' in `newN'
					replace _toid = `alter' in `newN'
					if (wordcount("`line'") - 2) > 0 {
						local value = word("`line'", 3)
						local __haswt 1
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
				if "`alter'" != "" {
					if "`mode'" == "arcslist" local __narcs 1
					else local __nedges 1
				}
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
			// read edges from matrix: one row of the adjacency matrix per line
			if ("`mode'" == "matrix") & word(`"`line'"', 1) != "" & substr(strtrim(`"`line'"'), 1, 1) != "*" {
				local ++__mrow
				if `__mrow' > `size' | wordcount(`"`line'"') != `size' {
					noi di "{err}{p 0 0 2}*Matrix needs `size' lines with `size' numbers each (the number of vertices){p_end}"
					exit 6705
				}
				forvalues next = 1/`size' {
					local value = word(`"`line'"', `next')
					capture confirm number `value'
					if _rc {
						noi di "{err}*Matrix: `value' is not a number"
						exit 6705
					}
					if `value' != 0 {
						local newN = _N + 1
						set obs `newN'
						replace _fromid = `__mrow' in `newN'
						replace _toid = `next' in `newN'
						replace _value = `value' in `newN'
						if `value' != 1 local __haswt 1
					}
				}
			}
			
			file read importfile line
			if substr(strtrim(`"`line'"'), 1, 1) == "*" & "`mode'" == "matrix" local mode ""
		}
		file close importfile
		if "`mode'" == "matrix" & `__mrow' != `size' {
			noi di "{err}{p 0 0 2}*Matrix needs `size' lines with `size' numbers each (the number of vertices); found `__mrow'{p_end}"
			exit 6705
		}

		// arcs make the network directed (an empty *Arcs section before *Edges does not)
		if `__narcs' | (`__arcsec' & !`__edgesec' & !`__nedges') {
			local nwfromedgeopt "directed"
			c_local __nwi_declared "directed"
		}
		else if `__nedges' | `__edgesec' {
			local nwfromedgeopt "undirected"
		}
		if `__relab' {
			mata: st_local("labs", nwimp_uniquelist(st_local("labs")))
			global NWIMPORT_relabel "1"
		}

		capture replace _fromid = trim(_fromid)
		capture replace _toid = trim(_toid)
		_nwimport_loops _fromid _toid _value
		qui nwfromedge _fromid _toid _value, name(`name') labs(`labs') `nwfromedgeopt' `=cond(`__haswt', "valued", "unvalued")' `__nwi_loop'
	
		unw_defs
		nwload, labelonly
		// the vertex dictionary exists only when the file has vertex lines ("*Vertices 3" followed directly by
		// "*Arcs" is valid Pajek; the nodes are then numbered, labels n1, n2, ... as from nwfromedge)
		capture confirm file `"`dict'"'
		if _rc == 0 {
			qui merge m:n `nw_nodename' using `dict', nogenerate
		}
		if "`n1'" != "" {
			_nwimport_apply2mode `name', n(`size') n1(`n1') labs(`labs') desc1(`"`__lv1'"') desc2(`"`__lv2'"')
		}
end


capture program drop _nwimport_apply2mode
program _nwimport_apply2mode
	// declare the network a two-mode network after the import: the mode of every node comes either from the
	// comma separated list modes() (parallel to labs()) or from n/n1 (the first n1 of n vertices form the first
	// mode); a tie between two nodes of the same mode makes the file invalid
	syntax [anything(name=netname)] [, LABS(string) MODES(string) N(integer 0) N1(integer 0) DESC1(string) DESC2(string)]
	unw_defs
	_nwsyntax `netname', max(1)
	tempname lab md
	if `"`labs'"' != "" {
		mata: `lab' = tokens(`"`labs'"', ","); `lab' = select(`lab', `lab' :!= ",")
	}
	else {
		// a Pajek file without vertex lines: the nodes are n1, n2, ... (nwfromedge's labels for numeric ids)
		mata: `lab' = "n" :+ strofreal(1::`n')'
	}
	if "`modes'" != "" {
		mata: `md' = tokens("`modes'", ","); `md' = select(`md', `md' :!= ",")
	}
	else {
		mata: `md' = (J(1, `n1', "1"), J(1, `n' - `n1', "2"))
	}
	mata: st_local("__ok", strofreal(cols(`lab') == cols(`md')))
	if !`__ok' {
		mata: mata drop `lab' `md'
		di "{txt}{p 0 0 2}(note: the file does not give a mode for every node; {bf:`netname'} is not declared two-mode){p_end}"
		exit
	}
	mata: `netobj'->set_2mode(1)
	qui mata: `netobj'->set_modes_from_labeled_string(invtokens(`lab' :+ "=" :+ `md', ","))
	mata: mata drop `lab' `md'
	mata: st_local("__bad", strofreal(`netobj'->count_samemode_ties()))
	if `__bad' > 0 {
		mata: `netobj'->set_2mode(0)
		di "{err}{p 0 0 2}The file declares a two-mode network, but `__bad' ties join two nodes of the same mode.{p_end}"
		exit 459
	}
	mata: `netobj'->clean_matrix_2mode()
	// ties of value 1 only: a binary network (the writers add the value 1 to every tie)
	mata: `netobj'->set_valued(`netobj'->check_valued())
	// the level labels, if the file holds them
	if `"`desc1'"' == "" | `"`desc2'"' == "" {
		local desc1 "mode 1"
		local desc2 "mode 2"
	}
	mata: `netobj'->set_description_mode1(`"`desc1'"')
	mata: `netobj'->set_description_mode2(`"`desc2'"')
end


capture program drop _nwimport_apos
program _nwimport_apos
	// A double quote followed by an apostrophe ("'t Hart") ends a Stata compound quote, so such a line cannot be
	// handled in macros. c_local __nwi_file: the file itself or, when it holds this pair, the copy masked (a
	// temporary file of the caller) in which that apostrophe is written as __nwapos__.
	args fn masked
	c_local __nwi_file `"`fn'"'
	mata: st_local("found", strofreal(nwimp_maskapos(st_local("fn"), st_local("masked"))))
	if "`found'" == "1" c_local __nwi_file `"`masked'"'
end


capture program drop _nwimport_loops
program _nwimport_loops
	// c_local __nwi_loop: "selfloop" when the list built from a file has ties of a node with itself. The rows of
	// value 0 that only declare such a node are removed (a later one would overwrite the tie).
	args from to value
	c_local __nwi_loop ""
	qui count if `from' == `to' & `value' != 0 & `value' < .
	if r(N) == 0 exit
	tempvar order has
	qui gen long `order' = _n
	qui gen byte `has' = (`from' == `to' & `value' != 0 & `value' < .)
	qui bysort `from' `to' (`has' `order'): replace `has' = `has'[_N]
	qui drop if `from' == `to' & `value' == 0 & `has'
	sort `order'
	c_local __nwi_loop "selfloop"
end


capture program drop _nwimpdl_rect
program _nwimpdl_rect
	// UCINET DL with a rectangular matrix (nr rows, nc columns, format fullmatrix): rows form the first mode,
	// columns the second; row and column labels as in nwexport (row labels: / col labels: / data:)
	syntax anything(name=fn), ROWS(integer) COLS(integer)
	unw_defs
	preserve
	drop _all
	// The ties are listed with numbered stand-ins for the nodes (the rows first): node names with blanks or
	// semicolons would not pass through an edge list and its list of isolates. They get their names afterwards.
	qui {
		gen str12 _fromid = ""
		gen str12 _toid = ""
		gen double _value = .
	}
	tempname names
	mata: `names' = nwimp_dlrect(`fn', `rows', `cols')
	if _N == 0 {
		di "{err}The matrix has no ties."
		restore
		error 2000
	}
	local alln ""
	local allm ""
	forvalues i = 1/`=`rows' + `cols'' {
		local w = "z" + string(1000000 + `i', "%7.0f")
		local alln "`alln'`w';"
		local allm "`allm'`w'=`=1 + (`i' > `rows')',"
		if length("`allm'") > 60000 {
			di "{err}a two-mode network in a UCINET file can have at most about 5,000 nodes"
			restore
			error 920
		}
	}
	local alln = substr("`alln'", 1, length("`alln'") - 1)
	local allm = substr("`allm'", 1, length("`allm'") - 1)
	char _dta[nwtoedge_nodes] `"`alln'"'
	char _dta[nwtoedge_modes] `"`allm'"'
	char _dta[nwtoedge_mode1desc] "rows"
	char _dta[nwtoedge_mode2desc] "columns"
	qui sum _value
	if r(min) == 1 & r(max) == 1 {
		nw2fromedge _fromid _toid
	}
	else {
		nw2fromedge _fromid _toid _value
	}
	_nwsyntax
	mata: nwimp_dlrename(`netobj', `names')
	mata: mata drop `names'
	restore
end


capture program drop _nwimport_ucinet
program _nwimport_ucinet
	version 9
	syntax [anything][, name(string) clear nwclear]
	unw_defs

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
				exit `errFormatUnsupported'
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
			qui count if _value < . & _value != 0 & _value != 1
			qui nwfromedge _fromid _toid _value, name(`name') labs(`labs') `nwfromedgeopt' `=cond(r(N) > 0, "valued", "unvalued")'
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
	
	// every cell is read as text; which row and column hold node names is decided afterwards (nwimp_matrix())
	local excelfile = (strpos(lower(`"`anything'"'), ".xls") != 0)
	local decimalcomma 0
	
	// Excel file detected
	if `excelfile' {
		import excel `anything', allstring clear
	}
	else if `"`delimiter'"' == "" {
		local success 0
		foreach use_delimiter in tab semicolon comma blank {
			if `success' == 0 {
				_nwimport_text `anything', delimiter(`use_delimiter')
				if c(k) > 1 {
					local success 1
					if inlist("`use_delimiter'", "tab", "semicolon") local decimalcomma 1
				}
			}
		}
	}
	else {
		_nwimport_text `anything', delimiter(`"`delimiter'"')
		if inlist(`"`delimiter'"', "tab", ";") local decimalcomma 1
	}
	if _N == 0 | c(k) == 0 {
		global NWIMPORT_error "no matrix found in the file"
		exit 6705
	}
	
	// result: variables of the matrix (__nwimp_vars), their node names in __nwimport_names (empty: none given),
	// the node attributes (__nwimp_attr)
	mata: nwimp_matrix(`decimalcomma', "`rownames'" != "", "`colnames'" != "")
	if `"`__nwimp_error'"' != "" {
		global NWIMPORT_error `"adjacency matrix: `__nwimp_error'"'
		exit 6705
	}
	if "`__nwimp_attr'" != "" {
		capture destring `__nwimp_attr', replace
		char _dta[nwimport_attributes] "`__nwimp_attr'"
	}
	qui compress
	local labscmd ""
	if "`__nwimp_labvar'" != "" {
		local labscmd "labsfromvar(`__nwimp_labvar')"
	}
	nwset `__nwimp_vars', name("`name'") `labscmd'
	if "`__nwimp_labvar'" != "" {
		capture drop `__nwimp_labvar'
	}
end


capture program drop _nwimport_text
program _nwimport_text
	// a delimited text file, every cell as a string
	syntax anything, delimiter(string asis)
	local d `delimiter'
	if `"`d'"' == "tab" local dopt `"delimiters("\t")"'
	else if `"`d'"' == "semicolon" local dopt `"delimiters(";")"'
	else if `"`d'"' == "comma" local dopt `"delimiters(",")"'
	else if `"`d'"' == "blank" | `"`d'"' == " " local dopt `"delimiters(" ", collapse)"'
	else local dopt `"delimiters(`"`d'"')"'
	import delimited using `anything', `dopt' varnames(nonames) stringcols(_all) clear
end


capture program drop _nwimport_header
program _nwimport_header
	// A first line of an edge list that is clearly a header is removed. It is one when the first two cells are one of
	// the pairs below (any case) and neither word occurs again in these two columns, or when the third column holds
	// a word in the first line and numbers (or nothing) in all other lines.
	if _N == 0 | c(k) < 2 exit
	unab v : _all
	local v1 : word 1 of `v'
	local v2 : word 2 of `v'
	local v3 : word 3 of `v'
	local header 0
	capture confirm string variable `v1' `v2'
	if _rc == 0 {
		local a = lower(strtrim(`v1'[1]))
		local b = lower(strtrim(`v2'[1]))
		if inlist(`"`a'|`b'"', "from|to", "source|target", "ego|alter", "sender|receiver", "sender|recipient") | ///
		   inlist(`"`a'|`b'"', "node1|node2", "id1|id2", "src|dst", "tail|head") {
			qui count if _n > 1 & (inlist(lower(strtrim(`v1')), "`a'", "`b'") | inlist(lower(strtrim(`v2')), "`a'", "`b'"))
			if r(N) == 0 local header 1
		}
	}
	if !`header' & "`v3'" != "" & _N > 1 {
		capture confirm string variable `v3'
		if _rc == 0 {
			local c = strtrim(`v3'[1])
			if !inlist(`"`c'"', "", ".") & real(`"`c'"') == . {
				qui count if _n > 1 & real(`v3') == . & !inlist(strtrim(`v3'), "", ".")
				if r(N) == 0 local header 1
			}
		}
	}
	if `header' {
		qui drop in 1
		capture destring _all, replace
	}
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
		local nwmodes ""
		local __haswt 0
		
		tempfile __nwi_masked
		_nwimport_apos `anything' `"`__nwi_masked'"'
		capture file close importfile
		file open importfile using `"`__nwi_file'"', read

		local mode ""
		local __relab 0
		local gmlvalue 1
		local nwfromedgeopt ""
		file read importfile line
		// REAL BUG FOUND AND FIXED (docs/ROADMAP.md's own tracked "GML/
		// GraphML import fixture confidence" gap): this used to loop
		// `while `"`line'"' != ""' - treating ANY blank line, anywhere
		// in the file, as end-of-file, not just a genuine EOF. Real GML
		// files commonly have blank lines for readability (confirmed
		// directly against a real, externally-sourced fixture -
		// networkx's own GML test data - which has one inside its first
		// `edge [...]' block; this parser silently stopped there,
		// reading only a fragment of the first edge and none of the
		// rest of the file, with no error). A programmatically-generated
		// exporter (this package's own included) never happens to emit
		// a blank line, which is exactly why this was invisible to
		// every round-trip (export-then-reimport) test that existed
		// before this pass. Fixed using `file read''s own documented
		// `r(eof)' indicator instead of inferring EOF from line content.
		while r(eof) == 0 {
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
					local nextlab = subinstr(`"`nextlab'"', "__nwapos__", "'", .)
					if strpos(`"`nextlab'"', ",") | strpos(`"`nextlab'"', char(34)) {
						local nextlab = subinstr(`"`nextlab'"', char(34), "'", .)
						local nextlab = strtrim(stritrim(subinstr(`"`nextlab'"', ",", " ", .)))
						if `"`nextlab'"' == "" local nextlab "_"
						local __relab 1
					}
					// get_nodenames_from_string() (unw_core.do) tokenizes
					// `labs' on COMMA, not whitespace, so multi-word GML
					// labels (e.g. "Node 1") survive intact without needing
					// quoting - matching the comma-delimited, unquoted
					// convention already used by every other importer that
					// builds `labs' (e.g. the pajek path just above). The
					// previous space-separated, double-quoted-per-label
					// form produced a `labs' value like ` "Node 1" "Node 2"'
					// which broke nwfromedge's own `if "`labs'" == ""'
					// emptiness check (a real, distinct "type mismatch"
					// bug, not just cosmetic) as soon as it was actually
					// exercised against a real (non-self-generated) GML
					// fixture with labels.
					local labs `"`labs'`nextlab',"'
				}
				// the level labels of a two-mode network: graph attributes written by nwexport
				if "``i''" == "nwmodelabel1" & "`mode'" == "" {
					local __lv1 `"``=`i'+1''"'
				}
				if "``i''" == "nwmodelabel2" & "`mode'" == "" {
					local __lv2 `"``=`i'+1''"'
				}
				if "``i''" == "nwmode" & "`mode'" == "node" {
					local nwmodes "`nwmodes'``=`i'+1'',"
				}
				if "``i''" == "source" & "`mode'" == "edge" {
					local mode_sub = "edge_source"
					local source = "``=`i'+1''"
					_insert_edge, from(`source') to(`target') value(`gmlvalue')
				}
				if "``i''" == "target" & "`mode'" == "edge" {
					local mode_sub = "edge_target"
					local target = "``=`i'+1''"
					_insert_edge, from(`source') to(`target') value(`gmlvalue')
				}
				// tie value (written by nwexport as value, by other software as weight)
				if inlist("``i''", "value", "weight") & "`mode'" == "edge" {
					local gmlvalue = real("``=`i'+1''")
					if `gmlvalue' >= . local gmlvalue 1
					local __haswt 1
					if "`source'" != "-1" & "`target'" != "-1" {
						qui replace _value = `gmlvalue' in `=_N'
					}
				}
				// graph [ directed 0|1 ]: before the first node or edge block
				if "``i''" == "directed" & "`mode'" == "" {
					if "``=`i'+1''" == "0" local nwfromedgeopt "undirected"
					if "``=`i'+1''" == "1" local nwfromedgeopt "forcedirected"
				}
				if "``i''" == "node" {
					local mode = "node"
				}
				if "``i''" == "edge" {
					local mode = "edge"
					local target = -1
					local source = -1
					local gmlvalue 1
				}
				local i = `i' + 1
			}
			// read next line
			file read importfile line
		}	
		capture file close importfile
		capture replace _fromid = trim(_fromid)
		capture replace _toid = trim(_toid)
		// the ids are the numbers of the node blocks: sorted as text "10" comes before "2" and the labels (in the
		// order of the node blocks) landed on the wrong nodes from 10 nodes on
		capture destring _fromid _toid, replace
		if "`nwfromedgeopt'" == "forcedirected" c_local __nwi_declared "directed"
		if `__relab' {
			mata: st_local("labs", nwimp_uniquelist(st_local("labs")))
			global NWIMPORT_relabel "1"
		}
		_nwimport_loops _fromid _toid _value
		nwfromedge _fromid _toid _value, name(`name') labs(`labs') `nwfromedgeopt' `=cond(`__haswt', "valued", "unvalued")' `__nwi_loop'
		if "`nwmodes'" != "" {
			// the attribute nwmode (written by nwexport for a two-mode network) gives the mode of every node
			_nwimport_apply2mode `name', labs(`labs') modes(`nwmodes') desc1(`"`__lv1'"') desc2(`"`__lv2'"')
		}
		restore
end


// Unreachable: "gefx" is not in the _opts_oneof "import_type" allow-list
// above (line ~352, "pajek matrix edgelist compressed gml ucinet"), was
// never documented in this file's own {title:Syntax}, and has no test
// coverage - so it can never be dispatched to and has never been verified
// to actually work. Left in place (documented here) rather than either
// wired up untested or deleted outright, matching the graphml precedent
// just above (removed from the allow-list once found broken, not silently
// left reachable) without assuming this one is equally broken - it has
// simply never been exercised.
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
		nwfromedge _fromidnum _toidnum _value, name(`name') labs(`labs') `nwfromedgeopt' unvalued
		restore
end


capture program drop _nwimport_edgelist
program _nwimport_edgelist
	syntax anything, [keeporiginal name(string) delimiter(string) directed undirected xvars eventtime time interval noheader] 
	if "`name'" == "" {
		local name "network"
	}
	// a list with times (written by nwexport, type(edgelist), for a temporal network): ego alter [value] time, or
	// ego alter [value] start end; eventtime, time or interval says what the time column(s) are
	local __nwi_ntm = ("`eventtime'" != "") + ("`time'" != "") + ("`interval'" != "")
	if `__nwi_ntm' > 1 {
		di "{err}options {bf:eventtime}, {bf:time} and {bf:interval} are mutually exclusive"
		exit 198
	}

	if (strpos(lower(`anything'), ".dta") != 0) | (strpos(lower(`anything'), ".DTA") != 0)  {
		//preserve
		use `anything', clear
		ds
		local ego : word 1 of `r(varlist)'
		local alter : word 2 of `r(varlist)'
		local value : word 3 of `r(varlist)'
		// ties of a node with itself in the data set; without them, a missing alter is written as a row of the
		// node with itself, which declares the node
		_nwimport_selfties `ego' `alter' `value'
		if "`__nwi_loop'" == "" {
			replace `alter' = `ego' if `alter' == .
		}
		drop if `ego' == .
		nwfromedge `ego' `alter' `value', `keeporiginal' `undirected' `directed' `xvars' name(`name') `__nwi_loop'
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
	if (strpos(lower(`"`anything'"'), ".xls") != 0 ){
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
		if "`header'" == "noheader" local insheet_opt `"`insheet_opt' nonames"'
		
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
	
	// a file with a single line is read as variable names without data: read it again as data
	if `excel' == 0 & "`delimiter'" == "" & `success' == 1 & _N == 0 {
		capture insheet using `anything' `insheet_opt' nonames
	}
	
	// an explicit delimiter() (text files)
	if `excel' == 0 & "`delimiter'" != "" {
		local __nwi_nn = cond("`header'" == "noheader", "nonames", "")
		if "`delimiter'" == "tab" capture insheet using `anything', tab clear `__nwi_nn'
		else capture insheet using `anything', delimiter("`delimiter'") clear `__nwi_nn'
		if _rc != 0 | c(k) == 1 {
			local success = 0
		}
		else {
			local success = 1
		}
	}
	
	if `success' == 0 {
		global NWIMPORT_error "{it:edgelist} could not be loaded"
		error 6705
	}

	// a header line that was read as a tie (insheet and import excel keep it when all columns are text)
	if "`header'" == "" {
		capture unab __nwi_first : _all
		local __nwi_first : word 1 of `__nwi_first'
		if `excel' | "`__nwi_first'" == "v1" _nwimport_header
	}
	// node names: no commas or double quotes
	capture unab __nwi_v : _all
	local __nwi_e1 : word 1 of `__nwi_v'
	local __nwi_e2 : word 2 of `__nwi_v'
	if "`__nwi_e2'" != "" mata: nwimp_cleanvars("`__nwi_e1' `__nwi_e2'")

	if `__nwi_ntm' == 1 {
		local __nwi_core = 3 + ("`interval'" != "")
		if `c(k)' != `__nwi_core' & `c(k)' != `__nwi_core' + 1 {
			global NWIMPORT_error "a list with times needs `__nwi_core' columns (ego, alter, time) or `=`__nwi_core'+1' with a value before the times (interval: two time columns); the file has `c(k)'."
			exit 6705
		}
		ds
		local __nwi_v `r(varlist)'
		local ego : word 1 of `__nwi_v'
		local alter : word 2 of `__nwi_v'
		local __nwi_p 3
		local value ""
		if `c(k)' == `__nwi_core' + 1 {
			local value : word 3 of `__nwi_v'
			local __nwi_p 4
		}
		local __nwi_t1 : word `__nwi_p' of `__nwi_v'
		local __nwi_t2 : word `=`__nwi_p'+1' of `__nwi_v'
		foreach __nwi_x in `__nwi_t1' `__nwi_t2' `value' {
			capture confirm numeric variable `__nwi_x'
			if _rc {
				global NWIMPORT_error "column {bf:`__nwi_x'} must be numeric (times and values)."
				exit 6705
			}
		}
		if "`eventtime'" != "" local __nwi_opt "eventtime(`__nwi_t1')"
		if "`time'" != "" local __nwi_opt "time(`__nwi_t1')"
		if "`interval'" != "" local __nwi_opt "interval(`__nwi_t1' `__nwi_t2')"
		nwset `ego' `alter' `value', `__nwi_opt' name(`name') `directed' `undirected' `xvars' dropvars
		exit
	}
	if `c(k)' == 5 {
		// a two-mode list written by nwexport: ego (first mode), alter (second mode), value, mode_ego, mode_alter
		ds
		local ego : word 1 of `r(varlist)'
		local alter : word 2 of `r(varlist)'
		local value : word 3 of `r(varlist)'
		local m1 : word 4 of `r(varlist)'
		local m2 : word 5 of `r(varlist)'
		qui keep if `m1' != `m2'
		qui replace `value' = 1 if `value' >= .
		// the columns mode_ego and mode_alter hold 1 and 2, or the level labels of the two modes
		local __lv1 "mode 1"
		local __lv2 "mode 2"
		capture confirm string variable `m1'
		local __s1 = (_rc == 0)
		capture confirm string variable `m2'
		local __s2 = (_rc == 0)
		if _N > 0 {
			local __a = `m1'[1]
			local __b = `m2'[1]
			if `__s1' == 0 local __a = string(`__a')
			if `__s2' == 0 local __b = string(`__b')
			if !(`"`__a'"' == "1" & `"`__b'"' == "2") & `"`__a'"' != `"`__b'"' {
				local __lv1 `"`__a'"'
				local __lv2 `"`__b'"'
			}
		}
		char _dta[nwtoedge_mode1desc] `"`__lv1'"'
		char _dta[nwtoedge_mode2desc] `"`__lv2'"'
		qui sum `value'
		if r(min) == 1 & r(max) == 1 {
			nw2fromedge `ego' `alter', name(`name') `xvars'
		}
		else {
			nw2fromedge `ego' `alter' `value', name(`name') `xvars'
		}
		exit
	}
	if `c(k)' > 3 | `c(k)' < 2 {
		global NWIMPORT_error "Something went wrong; data has more than three columns."
		error 6705
	}
	unab __nwi_v : _all
	_nwimport_selfties `__nwi_v'
	nwfromedge _all, name(`name') `keeporiginal' `directed' `undirected' `xvars' `__nwi_loop'
	//restore
	}
end


capture program drop _nwimport_selfties
program _nwimport_selfties
	// c_local __nwi_loop: "selfloop" when the list has a tie of a node with itself (a value other than 0)
	args ego alter value
	c_local __nwi_loop ""
	tempvar a b
	foreach s in a b {
		local x = cond("`s'" == "a", "`ego'", "`alter'")
		capture confirm string variable `x'
		if _rc == 0 qui gen strL ``s'' = strtrim(`x')
		else qui gen strL ``s'' = cond(missing(`x'), "", strofreal(`x', "%18.0g"))
	}
	local cond ""
	if "`value'" != "" {
		capture confirm numeric variable `value'
		if _rc == 0 local cond "& `value' != 0 & `value' < ."
	}
	qui count if `a' == `b' & `a' != "" `cond'
	if r(N) > 0 c_local __nwi_loop "selfloop"
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
	mata: nwimp_cleanvars("ego alter")
	nwfromedge ego alter, `directed' `undirected' `xvars' name(`name') `keeporiginal'

	//restore
	
	if "`xvars'" != "" {
		nwload, keepuser
	}
end



capture program drop _nwimpdl_comma
program _nwimpdl_comma
	// c_local <first word> = the remaining words (quotes respected) separated by commas, with the blanks and
	// apostrophes of the words (written as placeholders by nwimp_dlline()) put back
	mata: nwimp_dljoin(st_local("0"))
end

capture program drop _nwimpdl_nodelist1
program _nwimpdl_nodelist1
	syntax, filehandler(string) nodes(int) [undirected directed rankedlist edgelist netlabs(string) labs(string asis) labelsembedded collabsembedded rowlabsembedded]

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
	local __nwi_hasval = ("`rankedlist'" != "")
	file read `filehandler' line
	
	if "`collabsembedded'" != "" {
		mata: st_local("labs", nwimp_dlline(st_local("line")))
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
			local labs `"`labs' `onelab'"'
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
					local __nwi_hasval 1
				}
			}
			capture _insert_edge, from("`sender'") to("`receiver'") value(`value')
		}
		file read `filehandler' line
	}
	file close `filehandler'
	capture drop if _fromid == .
	capture drop if _fromid == ""
	capture confirm string variable _fromid _toid
	if _rc == 0 mata: nwimp_cleanvars("_fromid _toid")
	// nodes given by number (labels in the header): numeric ids, so that
	// node i gets the i-th label
	if "`labelsembedded'" == "" {
		qui destring _fromid _toid, replace
	}
	// the labels go to nwfromedge separated by commas (a label may hold a blank)
	_nwimpdl_comma __nwi_clabs `labs'
	// a list without tie values (edgelist1 with two columns) is binary
	_nwimport_loops _fromid _toid _value
	nwfromedge _all, name(`netlabs') labs(`__nwi_clabs') `directed' `undirected' `xvars' `=cond(`__nwi_hasval', "valued", "unvalued")' `__nwi_loop'
	restore
end



capture program drop _nwimpdl_fullmatrix
program _nwimpdl_fullmatrix
	syntax, filehandler(string) nodes(int) nets(int) [directed netlabs(string) labs(string asis)  diagonal(string) rowlabsembedded collabsembedded]

	mata: __nwimport_onenet = J(`nodes', `nodes', 0)
	
	file read `filehandler' line	
	local lc = 1
	local x = 1
	local y = 0
	local twc = 0
	local netcounter 1
	
	if "`collabsembedded'" != "" {
		mata: st_local("labs", nwimp_dlline(st_local("line")))
		file read `filehandler' line
	}	
		
	while r(eof)==0 {
		
		if "`rowlabsembedded'" != "" {
			mata: st_local("line", nwimp_dlline(st_local("line")))
		}
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
				local newlabs `"`newlabs' `oneword'"'
			}	
			else {
				local y = `y' + 1 
				if `y' > `nodes' {
					local y = 1
					local x = `x' + 1
				}
				if "`oneword'" != "0" {
					mata: __nwimport_onenet[`x', `y'] = `oneword'
				}
				// one network complete
				if `y' == `nodes' & `x' == `nodes' {
					local onename : word `netcounter' of `netlabs'
					mata: st_numscalar("r(issymmetric)", issymmetric(__nwimport_onenet))
					local symmetric = `r(issymmetric)'
					if `"`labs'"' == "" local labs `"`newlabs'"'
					_nwimpdl_comma __nwi_clabs `labs'
					mata: st_local("__nwi_loop", any(diagonal(__nwimport_onenet) :!= 0 :& diagonal(__nwimport_onenet) :< .) ? "selfloop" : "")
					nwset, name(`onename') labs(`__nwi_clabs') mat(__nwimport_onenet) `__nwi_loop'
					if "`symmetric'" == "1" & "`directed'" == "" {
						nwsym `onename'
					}
					
					mata: __nwimport_onenet = J(`nodes', `nodes', 0)
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
	syntax, filehandler(string) nodes(int) nets(int) [ directed netlabs(string) labs(string asis)  diagonal(string) rowlabsembedded collabsembedded]

	mata: __nwimport_onenet = J(`nodes', `nodes', 0)
	
	file read `filehandler' line	
	local lc = 1
	local twc = 0
	local netcounter 1
	local y = 1
	local x = 0
	local ab = 0
	
	if "`collabsembedded'" != "" {
		mata: st_local("labs", nwimp_dlline(st_local("line")))
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
						
			mata: __nwimport_onenet[`x',`y'] = `oneword'
			mata: __nwimport_onenet[`y',`x'] = `oneword'
		
			if (`y' == `nodes' & `x' == `nodes' - `ab') {
				local onename : word `netcounter' of `netlabs'
				_nwimpdl_comma __nwi_clabs `labs'
				mata: st_local("__nwi_loop", any(diagonal(__nwimport_onenet) :!= 0 :& diagonal(__nwimport_onenet) :< .) ? "selfloop" : "")
				nwset, name(`onename') labs(`__nwi_clabs') mat(__nwimport_onenet) `__nwi_loop'
				mata: __nwimport_onenet = J(`nodes', `nodes', 0)
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
	unw_defs

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
	local importfile "nwimpdl_fh"
	capture file close `importfile'
	// tabs separate words in a DL file like blanks: the readers below split at blanks, so a copy without tabs is read
	local __nwi_dlin = trim(`"`anything'"')
	if substr(`"`__nwi_dlin'"', 1, 1) == char(34) local __nwi_dlin = substr(`"`__nwi_dlin'"', 2, length(`"`__nwi_dlin'"') - 2)
	capture confirm file `"`__nwi_dlin'"'
	if _rc == 0 {
		tempfile __nwi_notab
		mata: nwimp_notabs(st_local("__nwi_dlin"), st_local("__nwi_notab"))
		local anything `""`__nwi_notab'""'
	}
	
	// parse header of .dl file
	file open `importfile' using `anything', read
	
	file read `importfile' line
	// words are separated by blanks, commas, semicolons and =, except inside double quotes
	mata: st_local("line", nwimp_dlline(st_local("line")))
	local firstword : word 1 of `line'
	local firstword = trim(lower("`firstword'"))

	// check for .dl format
	if "`firstword'" != "dl" {
		// Error-code coherence pass: an unsupported/unrecognized file
		// format, not a "network already exists" collision (the `6099'
		// this line had drifted onto by coincidence) - `errFormatUnsupported'
		// (6705, unw_defs.ado) already names this exact situation for
		// this same file's own "format not supported" check elsewhere.
		noi di "{err}No valid {bf:.dl} file"
		exit `errFormatUnsupported'
	}
	
	set more off
	// parse header until data part
	while  ("`firstword'" != "data:") {
		if r(eof) != 0 {
			noi di "{err}No valid {bf:.dl} file: no {bf:data:} line"
			exit `errFormatUnsupported'
		}
		
		// parse word by word
		local lc : word count `line'
		forvalues i = 1/ `lc' {
			local oneword : word `i' of `line'
			
			local keywords = "level matrix n nm nr nc format data: labels: diagonal"
			local oneword_low = lower("`oneword'")
			local key : list oneword_low  & keywords
			
			if `labels_on' == 1 & `netlabels_on' == 0 & "`key'" == "" {
				local labs `"`labs' `oneword'"'
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
				if inlist(lower("`secondword'"), "embedded", "embedded:") {
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
					if inlist(lower("`thirdword'"), "embedded", "embedded:") {
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
		mata: st_local("line", nwimp_dlline(st_local("line")))
		local firstword : word 1 of `line'
		local firstword = lower("`firstword'")
	}

	// "labels embedded" of a full matrix: the first line of the data and the first word of every line are names
	if "`format'" == "fullmatrix" & "`labels_embedded'" != "" & "`rowlab_embedded'`collab_embedded'" == "" {
		local rowlab_embedded "rowlabsembedded"
		local collab_embedded "collabsembedded"
	}
	
	if "`rows'" != "`cols'" | ("`rows'" != "" & "`cols'" != "") {
		// a rectangular matrix (nr= and nc= given, also when both are equal) is a two-mode network: rows are the first
		// mode, columns the second
		file close `importfile'
		_nwimpdl_rect `anything', rows(`rows') cols(`cols')
		mata: st_global("r(nameoff)", "")
		exit
	}
	
	local labscount : word count `labs'
	if `labscount' > `nodes' {
		local newlabs ""
		forvalues i = 1/`nodes' {
			local onelab : word `i' of `labs'
			local newlabs `"`newlabs' `onelab'"'
		}
		local labs `"`newlabs'"'
	}
	
	local format = lower("`format'")
	
	if "`netlistonly'" == "" {
		if lower("`format'") == "fullmatrix" {
			di "full"
			_nwimpdl_fullmatrix, filehandler(`importfile') labs(`labs') netlabs(`netlabs') nodes(`nodes') nets(`nets') diagonal(`diagonal') `rowlab_embedded' `collab_embedded'
		}
		if lower("`format'") == "nodelist1" {
			qui _nwimpdl_nodelist1, filehandler(`importfile') labs(`labs') netlabs(`netlabs') nodes(`nodes') `labels_embedded' `rowlab_embedded' `collab_embedded'
		}
		if lower("`format'") == "rankedlist1" {
			qui _nwimpdl_nodelist1, rankedlist filehandler(`importfile') labs(`labs') netlabs(`netlabs') nodes(`nodes') `labels_embedded' `rowlab_embedded' `collab_embedded'
		}
		if lower("`format'") == "edgelist1" {
			qui _nwimpdl_nodelist1, edgelist filehandler(`importfile') labs(`labs') netlabs(`netlabs') nodes(`nodes') `labels_embedded' `rowlab_embedded' `collab_embedded'
		}
		if lower("`format'") == "lowerhalf" {
			// BUGFIX: this checked a local named `rowlabsembedded' (no
			// underscore before "embedded"), but the local this
			// program's own header actually populates when the DL
			// file's header says "row labels embedded" is
			// `rowlab_embedded' (WITH the underscore, set a few dozen
			// lines above) - a plain naming mismatch, confirmed
			// directly (`rowlabsembedded' is never assigned anywhere in
			// this program's scope). The guard below could therefore
			// never fire regardless of the actual DL file content, so a
			// row-labels-embedded lowerhalf file silently went through
			// the `else' branch's own import attempt (`_nwimpdl_lowerhalf'
			// does not itself understand embedded row labels for this
			// format, so that import would produce a wrong/garbled
			// result rather than the intended clear rejection). Fixed
			// to check the actual local, and (separately, the second
			// bug found alongside it) to actually raise an error rather
			// than only printing - see this file's own header comment
			// convention for that class of fix.
			if "`rowlab_embedded'" != "" {
				noi di "{err}Ucinet {bf:row labels embedded} not supported together with format {bf:lowerhalf}"
				exit `errFormatUnsupported'
			}
			else {
				_nwimpdl_lowerhalf, filehandler(`importfile') labs(`labs') netlabs(`netlabs') nodes(`nodes') nets(`nets') diagonal(`diagonal') `rowlab_embedded' `collab_embedded'
			}
		}
	}
	mata: st_global("r(netlabs)", "`netlabs'")

	capture file close `importfile'
	// BUGFIX: "rankedlist1" is a real, handled format (the dispatch
	// block just above explicitly imports it via
	// "_nwimpdl_nodelist1, rankedlist ..."), but was missing from this
	// list entirely - so every successful rankedlist1 import used to
	// ALSO spuriously print "Ucinet format = rankedlist1 not supported"
	// right after succeeding (harmless only because the message below
	// used to have no `error' call either - see that bugfix note).
	// Added here so a genuine rankedlist1 import is no longer
	// misreported as unsupported.
	local sformat "fullmatrix nodelist1 rankedlist1 edgelist1 lowerhalf"
	local f : list format & sformat

	if "`f'" == "" {
		// BUGFIX: this used to print the message and fall straight
		// through with no error and no import actually performed - the
		// command returned rc==0 as if nothing were wrong (same
		// disguised-silent-failure class already fixed elsewhere in
		// this package, see nwevcent.ado's own header comment).
		noi di "{err}Ucinet format = {bf:`format'} not supported."
		exit `errFormatUnsupported'
	}
	mata: st_global("r(nameoff)","`nameoff'")
end

	
	






	
capture mata: mata drop nwimp_maskapos()
capture mata: mata drop nwimp_uniquestr()
capture mata: mata drop nwimp_uniquelist()
capture mata: mata drop nwimp_cleanstr()
capture mata: mata drop nwimp_cleanvars()
capture mata: mata drop nwimp_dlline()
capture mata: mata drop nwimp_dlrect()
capture mata: mata drop nwimp_pajeklines()
capture mata: mata drop nwimp_nobom()
capture mata: mata drop nwimp_lines()
capture mata: mata drop nwimp_pajekline()
capture mata: mata drop nwimp_notabs()
capture mata: mata drop nwimp_squareblankdiag()
capture mata: mata drop nwimp_dlrename()
capture mata: mata drop nwimp_dljoin()
capture mata: mata drop nwimp_isnum()
capture mata: mata drop nwimp_samenames()
capture mata: mata drop nwimp_matrix()
mata:
// 1 when the file fn holds a double quote followed by an apostrophe; then the file out is written with that
// apostrophe as __nwapos__. 0 otherwise (also when fn cannot be read as a local file: the reader reports it).
real scalar nwimp_maskapos(string scalar fn, string scalar out)
{
	real scalar fh, i, found, n
	string colvector L

	if (!fileexists(fn)) return(0)
	L = cat(fn)
	n = rows(L)
	if (n == 0) return(0)
	found = any(strpos(L, char(34) + char(39)))
	if (!found) return(0)
	(void) _unlink(out)
	fh = fopen(out, "w")
	for (i = 1; i <= n; i++) fput(fh, subinstr(L[i], char(34) + char(39), char(34) + "__nwapos__"))
	fclose(fh)
	return(1)
}

// the lines of a text that ends with a line break; empty lines are left out
string rowvector nwimp_lines(string scalar text)
{
	transmorphic t

	t = tokeninit(char(10), "", "")
	tokenset(t, text)
	return(tokengetall(t))
}

// a line without a UTF-8 byte-order mark
string scalar nwimp_nobom(string scalar c)
{
	if (substr(c, 1, 3) == char((239, 187, 191))) return(substr(c, 4, .))
	return(c)
}

// node names that the library can hold: no comma (the lists of names are comma separated), no double quote and no
// left quote (they end up in Stata macros)
string matrix nwimp_cleanstr(string matrix s)
{
	string matrix r
	real scalar i, j

	r = s
	for (i = 1; i <= rows(r); i++) {
		for (j = 1; j <= cols(r); j++) {
			if (strpos(r[i,j], ",") | strpos(r[i,j], char(34)) | strpos(r[i,j], char(96))) {
				r[i,j] = subinstr(subinstr(r[i,j], char(34), "'"), char(96), "'")
				r[i,j] = strtrim(stritrim(subinstr(r[i,j], ",", " ")))
				if (r[i,j] == "") r[i,j] = "_"
			}
		}
	}
	return(r)
}

// a name that is in the list already gets the suffix _2, _3, ...
string colvector nwimp_uniquestr(string colvector s)
{
	transmorphic A
	string colvector r
	real scalar i, k

	A = asarray_create()
	r = s
	for (i = 1; i <= rows(r); i++) {
		if (asarray_contains(A, r[i])) {
			k = 2
			while (asarray_contains(A, r[i] + "_" + strofreal(k))) k++
			r[i] = r[i] + "_" + strofreal(k)
		}
		asarray(A, r[i], 1)
	}
	return(r)
}

string scalar nwimp_uniquelist(string scalar s)
{
	string rowvector t

	t = tokens(s, ",")
	t = select(t, t :!= ",")
	if (cols(t) == 0) return(s)
	return(invtokens(nwimp_uniquestr(t')', ",") + ",")
}

// cleans the node names in the string variables among vars, the same way in all of them
void nwimp_cleanvars(string scalar vars)
{
	string rowvector v
	string colvector x, u, c, y
	transmorphic A, B
	real scalar i, j, k, n

	v = tokens(vars)
	u = J(0, 1, "")
	for (i = 1; i <= cols(v); i++) {
		if (st_isstrvar(v[i]) & st_nobs() > 0) u = u \ st_sdata(., v[i])
	}
	if (rows(u) == 0) return
	u = uniqrows(u)
	c = nwimp_cleanstr(u)
	if (all(c :== u)) return
	// A: names in use; B: old name -> new name
	A = asarray_create()
	B = asarray_create()
	for (i = 1; i <= rows(u); i++) if (c[i] == u[i]) asarray(A, u[i], 1)
	for (i = 1; i <= rows(u); i++) {
		if (c[i] != u[i]) {
			y = c[i]
			k = 2
			while (asarray_contains(A, y[1])) {
				y = c[i] + "_" + strofreal(k)
				k++
			}
			asarray(A, y[1], 1)
			asarray(B, u[i], y[1])
		}
	}
	n = st_nobs()
	for (i = 1; i <= cols(v); i++) {
		if (!st_isstrvar(v[i])) continue
		x = st_sdata(., v[i])
		for (j = 1; j <= n; j++) {
			if (asarray_contains(B, x[j])) x[j] = asarray(B, x[j])
		}
		st_sstore(., v[i], x)
	}
	st_global("NWIMPORT_relabel", "1")
}


// Reads the labels and the matrix of a rectangular DL file; the ties go into _fromid, _toid, _value as stand-ins
// z<1000000 + node number> (rows first). Returns the node names; labels may be quoted and are separated by blanks,
// tabs or commas. Commas inside a name become blanks (node names cannot hold them); equal names get _2, _3, ...
string rowvector nwimp_dlrect(string scalar fn, real scalar nr, real scalar nc)
{
	string colvector f, t
	string rowvector rl, cl, tok, names
	string scalar l, part, w, base
	real matrix E
	real scalar i, j, r, c, v, k, n, m
	transmorphic scalar tk
	transmorphic A

	f = cat(fn)
	rl = J(1, 0, "")
	cl = J(1, 0, "")
	part = ""
	r = 0
	m = 0
	E = J(1024, 3, .)
	tk = tokeninit(" " + char(9), ",", char(34) + char(34))
	for (i = 1; i <= rows(f); i++) {
		l = strlower(strtrim(f[i]))
		if (substr(l, 1, 10) == "row labels") part = "row"
		else if (substr(l, 1, 10) == "col labels" | substr(l, 1, 13) == "column labels") part = "col"
		else if (l == "data:") part = "data"
		else if (part == "row" | part == "col") {
			tokenset(tk, f[i])
			tok = tokengetall(tk)
			for (j = 1; j <= cols(tok); j++) {
				w = tok[j]
				if (w == ",") continue
				if (substr(w, 1, 1) == char(34)) w = substr(w, 2, strlen(w) - 2)
				w = strtrim(subinstr(w, ",", " "))
				if (part == "row") rl = (rl, w)
				else cl = (cl, w)
			}
		}
		else if (part == "data" & l != "") {
			r++
			tok = tokens(subinstr(l, ",", " "))
			for (c = 1; c <= cols(tok); c++) {
				v = strtoreal(tok[c])
				if (v == 0 | v >= .) continue
				if (r > nr | c > nc) continue
				if (++m > rows(E)) E = E \ J(rows(E), 3, .)
				E[m, .] = (r, nr + c, v)
			}
		}
	}
	names = J(1, nr + nc, "")
	A = asarray_create()
	for (k = 1; k <= nr + nc; k++) {
		if (k <= nr) w = (k <= cols(rl) ? rl[k] : "r" + strofreal(k))
		else w = (k - nr <= cols(cl) ? cl[k - nr] : "c" + strofreal(k - nr))
		base = w
		n = 1
		while (asarray_contains(A, w)) w = base + "_" + strofreal(++n)
		asarray(A, w, 1)
		names[k] = w
	}
	if (m == 0) return(names)
	st_addobs(m)
	t = "z" :+ strofreal(1000000 :+ E[|1, 1 \ m, 1|], "%7.0f")
	st_sstore(., "_fromid", t)
	t = "z" :+ strofreal(1000000 :+ E[|1, 2 \ m, 2|], "%7.0f")
	st_sstore(., "_toid", t)
	st_store(., "_value", E[|1, 3 \ m, 3|])
	return(names)
}

// a copy of a UCINET DL file for the readers: tabs replaced by blanks, no byte-order mark, no blank lines
void nwimp_notabs(string scalar from, string scalar to)
{
	real scalar fi, fo, i, k, last
	string scalar buf, c
	string matrix piece
	string rowvector L

	fi = fopen(from, "r")
	fo = fopen(to, "rw")
	buf = ""
	last = 0
	while (!last) {
		piece = fread(fi, 65536)
		last = (piece == J(0, 0, ""))
		if (!last) buf = buf + subinstr(piece, char(13), char(10))
		else buf = buf + char(10)
		// the complete lines are split in one step (cutting them off one by one copies the rest of the chunk each time)
		k = strrpos(buf, char(10))
		if (k == 0) continue
		L = nwimp_lines(substr(buf, 1, k))
		buf = substr(buf, k + 1, .)
		for (i = 1; i <= cols(L); i++) {
			c = nwimp_nobom(subinstr(L[i], char(9), " "))
			if (strtrim(c) != "") fput(fo, c)
		}
	}
	fclose(fi)
	fclose(fo)
}

void nwimp_pajekline(real scalar fo, string scalar c)
{
	string scalar t
	string rowvector l

	// the reader splits lines at blanks: tabs become blanks (a tie list with tabs would otherwise be read as no ties); a
	// byte-order mark in front of the first line is removed
	c = nwimp_nobom(subinstr(c, char(9), " "))
	t = strtrim(c)
	if (t == "") return
	if (substr(t, 1, 1) == "%") {
		l = tokens(t)
		if (cols(l) < 4) return
		if (l[2] != "nwcommands" | l[3] != "level" | l[4] != "labels") return
	}
	fput(fo, c)
}

// copies a Pajek file without blank lines and comment lines (%); the comment with the level labels of a two-mode
// network, written by nwexport, is kept. Lines of any length.
void nwimp_pajeklines(string scalar from, string scalar to)
{
	real scalar fi, fo, i, k, last
	string scalar buf
	string matrix piece
	string rowvector L

	fi = fopen(from, "r")
	fo = fopen(to, "rw")
	buf = ""
	last = 0
	while (!last) {
		piece = fread(fi, 65536)
		last = (piece == J(0, 0, ""))
		if (!last) buf = buf + subinstr(piece, char(13), char(10))
		else buf = buf + char(10)
		// the complete lines are split in one step (cutting them off one by one copies the rest of the chunk each time)
		k = strrpos(buf, char(10))
		if (k == 0) continue
		L = nwimp_lines(substr(buf, 1, k))
		buf = substr(buf, k + 1, .)
		for (i = 1; i <= cols(L); i++) {
			nwimp_pajekline(fo, L[i])
		}
	}
	fclose(fi)
	fclose(fo)
}

// the stand-ins of the nodes of p are replaced by their names
void nwimp_dlrename(pointer(class nw_def scalar) scalar p, string rowvector names)
{
	string rowvector old, res
	real scalar i

	old = p->get_nodenames()
	res = old
	for (i = 1; i <= cols(old); i++) res[i] = names[strtoreal(substr(old[i], 2, .)) - 1000000]
	p->set_nodenames(res)
}

// a line of a UCINET DL file as a list of words: separated by blanks, tabs, commas, semicolons and =, except inside
// double quotes (a quote ends a quoted word only before a separator or at the end of the line). The words are
// returned separated by blanks; a blank inside a word is written as __nwblank__ and an apostrophe as __nwapos__ (a
// quote next to an apostrophe ends a compound quote); nwimp_dljoin() puts them back.
string scalar nwimp_dlline(string scalar line)
{
	string scalar sep, ch, w, out
	real scalar i, j, n

	sep = " " + char(9) + char(13) + ",;="
	out = ""
	n = strlen(line)
	i = 1
	while (i <= n) {
		ch = substr(line, i, 1)
		if (strpos(sep, ch)) {
			i++
			continue
		}
		if (ch == char(34)) {
			j = i + 1
			while (j <= n) {
				if (substr(line, j, 1) == char(34)) {
					if (j == n) break
					if (strpos(sep, substr(line, j + 1, 1))) break
				}
				j++
			}
			w = substr(line, i + 1, j - i - 1)
			i = j + 1
		}
		else {
			j = i
			while (j <= n) {
				if (strpos(sep, substr(line, j, 1))) break
				j++
			}
			w = substr(line, i, j - i)
			i = j
		}
		if (nwimp_cleanstr(w) != w) {
			w = nwimp_cleanstr(w)
			st_global("NWIMPORT_relabel", "1")
		}
		w = subinstr(subinstr(w, " ", "__nwblank__"), char(39), "__nwapos__")
		out = out + (out == "" ? "" : " ") + w
	}
	return(out)
}

void nwimp_dljoin(string scalar s)
{
	string rowvector t
	string scalar target, out
	real scalar i

	t = tokens(s)
	target = t[1]
	out = ""
	for (i = 2; i <= cols(t); i++) {
		out = out + (i > 2 ? "," : "") + subinstr(subinstr(t[i], "__nwblank__", " "), "__nwapos__", char(39))
	}
	stata("c_local " + target + " " + char(96) + char(34) + out + char(34) + char(39))
}

// cells that stand for a number (a blank, . and NA are a missing value)
real matrix nwimp_isnum(string matrix s)
{
	return((strtoreal(s) :!= .) :| (s :== "") :| (s :== ".") :| (strupper(s) :== "NA") :| (strupper(s) :== "NAN"))
}

// 1 when the cells 2..R of the first row and of the first column hold the same distinct, non-blank names
real scalar nwimp_samenames(string matrix S)
{
	string colvector h, c

	if (rows(S) < 2 | cols(S) < rows(S)) return(0)
	h = S[|1, 2 \ 1, rows(S)|]'
	c = S[|2, 1 \ rows(S), 1|]
	if (any(h :!= c) | any(c :== "")) return(0)
	return(rows(uniqrows(c)) == rows(c))
}

// 1 for a square table that holds numbers and empty cells only, with the whole diagonal empty
real scalar nwimp_squareblankdiag(string matrix S)
{
	real scalar i

	if (rows(S) != cols(S) | rows(S) < 2) return(0)
	for (i = 1; i <= rows(S); i++) if (S[i,i] != "") return(0)
	if (!any(S :!= "")) return(0)
	return(all(nwimp_isnum(S) :| (S :== "")))
}

// The data in memory are the cells (all strings) of a file with an adjacency matrix. Finds the row and the column of
// node names and replaces the data by the matrix columns (numeric), the node attributes (the columns after the first
// N, N = number of rows of the matrix) and, if the file holds node names, a variable with these names.
void nwimp_matrix(real scalar decimalcomma, real scalar optrow, real scalar optcol)
{
	string matrix S
	string colvector names, hn, cells, vn, an
	string rowvector head
	real matrix M, num
	real colvector keep, col
	real scalar R, C, i, j, hdr, idc, i0, j0, n, nc, k, blankdiag, last
	string scalar corner, name, labvar
	transmorphic used

	st_local("__nwimp_error", "")
	st_local("__nwimp_vars", "")
	st_local("__nwimp_attr", "")
	st_local("__nwimp_labvar", "")
	S = J(st_nobs(), st_nvar(), "")
	for (j = 1; j <= st_nvar(); j++) S[., j] = strtrim(st_sdata(., j))
	// empty rows, and empty columns at the left and right edge, are not part of the matrix
	keep = J(rows(S), 1, 0)
	for (i = 1; i <= rows(S); i++) keep[i] = any(S[i, .] :!= "")
	if (!any(keep)) {
		st_local("__nwimp_error", "the file is empty")
		return
	}
	// not in a square table of numbers whose diagonal is empty: there an empty line or column is a node without ties
	if (!nwimp_squareblankdiag(S)) {
		S = select(S, keep)
		last = cols(S)
		while (all(S[., last] :== "")) last--
		j = 1
		while (all(S[., j] :== "")) j++
		S = S[., (j..last)]
	}
	if (decimalcomma) {
		for (i = 1; i <= rows(S); i++) {
			for (j = 1; j <= cols(S); j++) {
				if (regexm(S[i,j], "^[-+]?[0-9]*,[0-9]+([eE][-+]?[0-9]+)?$")) S[i,j] = subinstr(S[i,j], ",", ".")
			}
		}
	}
	R = rows(S)
	C = cols(S)
	num = nwimp_isnum(S)
	corner = S[1,1]

	// a column of names: text below the first row; a row of names: text in the cells of the first row that would
	// belong to the matrix
	idc = 0
	if (R >= 2 & C >= 2) idc = !all(num[|2, 1 \ R, 1|])
	hdr = 0
	if (C >= 2 & 1 + idc <= min((C, R + idc))) hdr = !all(num[|1, 1 + idc \ 1, min((C, R + idc))|])
	// numeric names: an empty (or text) corner and the same names in the first row and the first column
	if (!idc & nwimp_samenames(S)) {
		if (corner == "") {
			// a matrix with an empty diagonal has an empty corner too
			blankdiag = 1
			for (i = 2; i <= R; i++) if (S[i,i] != "") blankdiag = 0
			// (with an empty diagonal, numbers in the first row and column are ties unless the options say names)
			if (!blankdiag | optrow | optcol) {
				hdr = 1
				idc = 1
			}
		}
		else if (!num[1,1]) {
			hdr = 1
			idc = 1
		}
	}
	// a header line over a column of numeric names
	if (hdr & !idc & C >= 2) {
		if (corner == "" | (C == R & anyof(("id", "name", "names", "node", "nodes", "label"), strlower(corner)))) idc = 1
	}
	// numbers as names in the first row only: one line more than columns
	if (!hdr & !idc & R == C + 1) {
		hn = S[1, .]'
		if (all(hn :!= "") & rows(uniqrows(hn)) == C & !all((hn :== "0") :| (hn :== "1"))) hdr = 1
	}
	// the options say what the cells themselves do not show
	if (optrow & !idc & C >= 2) {
		if ((!hdr & C - 1 >= R) | (hdr & C == R)) idc = 1
	}
	if (optcol & !hdr & R >= 2) {
		if (R - 1 == C - idc) hdr = 1
	}

	i0 = 1 + hdr
	j0 = 1 + idc
	n = R - hdr
	nc = C - idc
	if (n < 1 | nc < 1) {
		st_local("__nwimp_error", "the file holds names but no matrix")
		return
	}
	if (nc < n) {
		st_local("__nwimp_error", sprintf("the matrix has %g rows but only %g columns; it must be square (further columns are node attributes)", n, nc))
		return
	}
	for (i = i0; i <= R; i++) {
		for (j = j0; j <= j0 + n - 1; j++) {
			if (!num[i,j]) {
				st_local("__nwimp_error", sprintf("the cell in line %g, column %g is not a number: ", i, j) + subinstr(subinstr(substr(S[i,j], 1, 40), char(34), "'"), char(96), "'"))
				return
			}
		}
	}
	M = strtoreal(S[|i0, j0 \ R, j0 + n - 1|])

	names = J(0, 1, "")
	hn = J(0, 1, "")
	if (hdr) hn = S[|1, j0 \ 1, j0 + n - 1|]'
	if (idc) {
		names = S[|i0, 1 \ R, 1|]
		if (hdr) {
			if (any(hn :!= names) & all(sort(hn, 1) :== sort(names, 1))) {
				st_local("__nwimp_error", "the names in the first row and in the first column are the same but in a different order")
				return
			}
		}
	}
	else if (hdr) names = hn
	if (rows(names) > 0) {
		for (i = 1; i <= n; i++) if (names[i] == "") names[i] = "n" + strofreal(i)
		cells = nwimp_cleanstr(names)
		if (any(cells :!= names)) {
			st_global("NWIMPORT_relabel", "1")
			cells = nwimp_uniquestr(cells)
		}
		names = cells
		if (rows(uniqrows(names)) < n) {
			st_local("__nwimp_error", "the node names are not unique")
			return
		}
	}

	// variable names: from the header line where they can be Stata names, otherwise v and the column number
	used = asarray_create()
	vn = J(C, 1, "")
	for (j = j0; j <= C; j++) {
		name = ""
		if (hdr) name = strlower(S[1, j])
		if (!st_isname(name) | substr(name, 1, 3) == "_nw" | asarray_contains(used, name)) name = "v" + strofreal(j)
		k = 2
		while (asarray_contains(used, name)) {
			name = "v" + strofreal(j) + "_" + strofreal(k)
			k++
		}
		asarray(used, name, 1)
		vn[j] = name
	}

	stata("drop _all")
	st_addobs(n)
	for (j = j0; j <= j0 + n - 1; j++) {
		(void) st_addvar("double", vn[j])
		st_store(., vn[j], M[., j - j0 + 1])
	}
	st_local("__nwimp_vars", invtokens(vn[|j0 \ j0 + n - 1|]'))
	an = J(0, 1, "")
	for (j = j0 + n; j <= C; j++) {
		cells = S[|i0, j \ R, j|]
		(void) st_addvar(max((1, max(strlen(cells)))) > 2045 ? "strL" : "str" + strofreal(max((1, max(strlen(cells))))), vn[j])
		st_sstore(., vn[j], cells)
		an = an \ vn[j]
	}
	if (rows(an) > 0) st_local("__nwimp_attr", invtokens(an'))
	if (rows(names) > 0) {
		labvar = "__nwimp_lab"
		(void) st_addvar("strL", labvar)
		st_sstore(., labvar, names)
		st_local("__nwimp_labvar", labvar)
	}
}
end

*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
