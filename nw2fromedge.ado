
capture program drop nw2fromedge
program nw2fromedge
	syntax varlist(min=2 max=3) [if] [, xvars * ]
	
	local group1 : word 1 of `varlist'
	local group2 : word 2 of `varlist'
	local value : word 3 of `varlist'
	
	// Check if the same numbers are used for the two modes
	capture confirm numeric variable `group1'
	qui if _rc == 0 {
		capture confirm numeric variable `group2'
		if _rc == 0 {
			qui sum `group1'
			local g1min = r(min)
			local g1max = r(max)
			qui sum `group2'
			local g2min = r(min)
			local g2max = r(max)
			if (`g1max' >= `g2min') {
				replace `group2' = `group2' + `g1max'
			}
		}
	}
	
	// Check if the same strings are used for the two modes
	capture confirm string variable `group1'
	qui if _rc == 0 {
		capture confirm string variable `group2'
		tempfile g1 
		tempfile g2
		preserve
		keep `group1'
		rename `group1' id
		save `g1'
		restore
		preserve
		keep `group2'
		rename `group2' id
		merge m:n id using `g1'
		sum _merge
		restore
		
		// Same name used for both mode 1 and mode 2, need to distinguish
		if `r(max)' == 3 {
			replace `group1' = "m1_" + `group1'
			replace `group2' = "m2_" + `group2'
		}
	}
	
	
	preserve
	unw_defs

	tempfile dic1
	tempvar temp
	tempname modes
	tempname group1labels

	// BUGFIX: node modes must be assigned by which of the two edgelist
	// variables (group1 vs group2) a node's label actually came from -
	// not by node *position*. nwfromedge (called below) numbers nodes by
	// sorting the *combined* set of labels from both variables together
	// (see its own use of "stack `fromvar' `tovar' ... sort ... egen
	// _nodeid = group(...)"), so group1's labels and group2's labels end
	// up interleaved in node-index order whenever they don't happen to
	// sort into two separate alphabetical blocks - not a rare edge case,
	// just any dataset where a mode-2 label alphabetically precedes a
	// mode-1 label (e.g. persons "Peter"/"Thomas"/"Tim" and institutions
	// "LiU"/"Oxford" - "LiU" and "Oxford" both sort before "Peter").
	// Confirmed empirically: the old code's "the first `mode1' nodes are
	// group1" assumption silently mislabeled the modes of a plain
	// 3-person/2-institution example this way. Fixed by recording
	// group1's actual distinct label set here (Mata state survives the
	// upcoming preserve/restore, unlike the dataset) and, once the
	// network's own node order is known, assigning each node's mode by
	// direct label lookup instead of by position.
	//
	// Node labels aren't always the raw variable values verbatim: when
	// both edgelist variables are numeric, nwfromedge (below) builds
	// final node labels as "n" + the numeric value (see its own
	// `rawtype' == "numeric" branch) rather than the bare number - the
	// label set collected here must match that exactly, or every
	// membership lookup below would silently fail to match and every
	// node would fall back to the "2" default.
	capture confirm numeric variable `group1'
	local group1numeric = (_rc == 0)
	capture confirm numeric variable `group2'
	local group2numeric = (_rc == 0)

	keep `group1'
	gen `temp' = 1
	collapse (mean) `temp', by(`group1')
	if `group1numeric' & `group2numeric' {
		tempvar group1lab
		gen `group1lab' = "n" + strofreal(`group1')
		mata: `group1labels' = st_sdata(., "`group1lab'")
	}
	else {
		mata: `group1labels' = st_sdata(., "`group1'")
	}
	qui count
	local mode1 = r(N)
	restore

	// A two-mode network is stored as ONE matrix over the nodes of both modes (dense, with the cells inside a mode
	// missing), so the number of nodes is bounded by the dense limit. Say so now: finding out after building the
	// network took 22 s at 30,000 nodes.
	preserve
	keep `group2'
	gen byte `temp' = 1
	collapse (mean) `temp', by(`group2')
	qui count
	local mode2 = r(N)
	restore
	if `mode1' + `mode2' > `nw_max_dense_nodes' {
		di "{err}nw2fromedge: the two modes have `mode1' + `mode2' = `=`mode1'+`mode2'' nodes. A two-mode network is stored as one matrix over the nodes of both modes (`=round((`mode1'+`mode2')^2*8/1e9, .1)' GB here) and is refused above `nw_max_dense_nodes' nodes."
		di "{err}Keep the affiliation as an edge list and work on it directly, or take a sample of the larger mode first."
		exit 484
	}

	qui nwfromedge `group1' `group2' `value' `if', `options' `xvars' undirected
	_nwsyntax

	mata: `modes' = modes_from_labels(`netobj'->get_nodenames(), `group1labels')'
	mata: `netobj'->set_2mode(1)
	mata: `netobj'->set_modes(`modes')
	mata: `netobj'->set_description_mode1("`group1'")
	mata: `netobj'->set_description_mode2("`group2'")
	mata: `netobj'->clean_matrix_2mode()

	_nwsyntax
	_nwdatasync
	capture order `nw_nodename' `nw_mode'
	
end



