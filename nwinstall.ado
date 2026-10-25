capture program drop nwinstall
program nwinstall
	syntax [, update menu(string) usermenu gui permanently dialog remove downloadoff help ado ext all path(string) LOCALcopy from(string) dest(string) MODELs EVERYthing MODELPkg(string) RELease(string) MODELSFrom(string)]
	
	// supported Stata versions: 17 and 18 (the Mata libraries are built with Stata 17); older versions are untested, not blocked
	if c(stata_version) < 17 {
		di as text "nwcommands is tested with Stata 17 and 18; your Stata is version " c(stata_version)
	}

	// everything = the core (exactly what all installs) plus the four model packages (what models installs), as one consistent set
	if "`everything'" != "" {
		local all "all"
		local models "models"
		if "`modelpkg'" != "" {
			di as err "everything installs all four model packages; it cannot be combined with modelpkg()"
			exit 198
		}
	}

	// gui is the documented name of the option that installs the "Network Analysis" menu and dialogs permanently; permanently remains accepted as the older name
	if "`gui'" != "" local permanently "permanently"

	// the model packages nwsaom, nwergm, nwdynam, nwrem are separate GPL-3 packages (nwinstall_models.ado)
	local __nw_models = ("`models'" != "" | "`modelpkg'" != "")
	if `__nw_models' & "`update'`usermenu'`permanently'`dialog'`downloadoff'`help'`ado'`ext'`all'`localcopy'" == "" {
		nwinstall_models, pkgs(`modelpkg') release(`release') from(`modelsfrom') `remove'
		exit
	}
	if "`usermenu'" != "" | "`downloadoff'" != "" {
		window menu clear
		qui nwinstall_menu, menu("`menu'")
		exit
	}
	
	if "`update'" != "" {
		window menu clear
		nwinstall, help usermenu menu("`menu'")
		// ADD NEW PACKAGES HERE	
	}
	
	if "`path'" == "" {
		local path "`c(pwd)'"
	}
	// source of the core package files: GitHub, or from() (a local folder or URL; used by tools/smoke_fresh_install.sh)
	local __nw_src = cond(`"`from'"' == "", "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main", `"`from'"')
	
	tempname fh1 fh2

	// everything: before touching anything, make sure every model repository is reachable and that no model needs a newer core than the one about to be installed
	if "`everything'" != "" & "`remove'" == "" & "`localcopy'" == "" {
		nwinstall_corever, src(`"`__nw_src'"')
		nwinstall_models, release(`release') from(`modelsfrom') preflight corever(`r(ver)')
	}
	
	if "`all'" != "" {
		local help = "help"
		local dialog = "dialog"
		local permanently = "permanently"
	}

	// Offline install path (see the "Computers without internet access
	// or admin rights" section of nwinstall.sthlp): for machines that
	// cannot reach GitHub or cannot write anywhere but their own
	// PERSONAL ado directory. Copies files directly from an already-
	// obtained full nwcommands source folder (`from()', default: the
	// current directory) into a local ado directory (`dest()', default:
	// c(sysdir_personal) - already on Stata's default adopath, so
	// nothing further needs to be set for the default case) instead of
	// running `net install' against the GitHub repo.
	if "`localcopy'" != "" {
		if "`from'" == "" {
			local from "`c(pwd)'"
		}
		if "`dest'" == "" {
			local dest : sysdir PERSONAL
		}
		capture mkdir "`dest'"
		if "`ado'" != "" | "`all'" != "" {
			nwinstall_copymanifest, manifest("_pkg_ado.txt") from("`from'") dest("`dest'")
		}
		if "`help'" != "" | "`all'" != "" {
			nwinstall_copymanifest, manifest("_pkg_hlp.txt") from("`from'") dest("`dest'")
		}
		if "`dialog'" != "" | "`all'" != "" {
			nwinstall_copydialogs, from("`from'") dest("`dest'")
		}
		di as result _n "Copied nwcommands files from `from' into `dest'."
		if `"`dest'"' != `"`: sysdir PERSONAL'"' {
			di as result "This is not your PERSONAL ado directory - add it to your ado path in every session, e.g. with:"
			di as text `"    adopath ++ "`dest'""'
			di as text "(add that same line to your profile.do to make it permanent - see {help nwinstall##offline:help nwinstall} for the exact steps)."
		}
	}

	// Stata's own .pkg format has a hard, previously-undiscovered line
	// limit ("package file too long" - confirmed empirically, see
	// _nwdeploy.ado's own comment on nwdeploy_writepkgchunks) that this
	// package's core command count and help-file count both exceed, so
	// _nwdeploy.ado now ships each as several numbered packages
	// (nwcommands-ado1.pkg, nwcommands-ado2.pkg, ...) instead of one.
	// Installing them all means trying chunk numbers upward until one
	// genuinely doesn't exist - `capture' turns that expected stop into
	// a silent, clean loop exit rather than a surfaced error, matching
	// how many chunks stata.toc happens to list right now without this
	// command needing to hardcode that count.
	if ("`ado'" != "" | "`all'" != "") & "`localcopy'" == "" {
		capture ado uninstall "nwcommands-ado"
		net from "`__nw_src'"
		local i = 1
		local keepgoing = 1
		while `keepgoing' {
			capture net install "nwcommands-ado`i'", all replace
			if _rc != 0 {
				local keepgoing = 0
			}
			local i = `i' + 1
		}
		// The loop's own natural exit is an EXPECTED, captured failure
		// (chunk `i' genuinely doesn't exist) - without this, that
		// leaves a misleading nonzero `_rc' standing even when every
		// real chunk installed successfully (the same `_rc'-staleness
		// bug class fixed elsewhere this session, e.g. nwsync.ado).
		capture confirm number 1
	}

	if "`help'" != "" & "`localcopy'" == "" {
		capture ado uninstall "nwcommands-hlp"
		net from "`__nw_src'"
		local i = 1
		local keepgoing = 1
		while `keepgoing' {
			capture net install "nwcommands-hlp`i'", all replace
			if _rc != 0 {
				local keepgoing = 0
			}
			local i = `i' + 1
		}
		capture confirm number 1
	}

	if "`localcopy'" == "" {
		// REMOVED (2026-09-02): nwcommands-ext.pkg (nwdissimilar/
		// nwhierarchy/nwdendrogram) used to be its own separately
		// net-installed package, requested via the `ext' option. It
		// turned out to be 100% redundant - all three commands'
		// .ado/.sthlp files were ALREADY listed in _pkg_ado.txt/
		// _pkg_hlp.txt too, so they already ship as part of the
		// ordinary `ado'/`help' install above; there was never a real
		// reason to call them out as a separate "Extension" distinct
		// from every other command in the package. The `ext' option
		// itself stays accepted (a harmless no-op) for any saved
		// script that still passes it. What remains genuinely needed
		// here is migration: a user who installed under the old
		// "nwcommands-ext" name (or the transient, never-published
		// "nwcommands-ext1" this fix briefly used mid-development)
		// would otherwise be left with a stale duplicate registered
		// after upgrading - uninstall both (each `capture'd, since
		// neither may exist for a given user) unconditionally, not
		// gated on `ext', so it always runs once on every update.
		capture ado uninstall "nwcommands-ext"
		capture ado uninstall "nwcommands-ext1"
	}


	if "`dialog'" != "" & "`localcopy'" == "" {
		capture ado uninstall "nwcommands-dlg"
		net from "`__nw_src'"
		// BUGFIX: was a single `net install "nwcommands-dlg", all' -
		// the dialog rebuild grew the .dlg count past Stata's
		// per-package line limit (see _nwdeploy.ado's own comment on
		// nwdeploy_writepkgchunks), so nwcommands-dlg.pkg is now
		// shipped chunked (nwcommands-dlg1.pkg, -dlg2.pkg, ...) just
		// like -ado/-hlp already were; this loop matches those.
		local i = 1
		local keepgoing = 1
		while `keepgoing' {
			capture net install "nwcommands-dlg`i'", all replace
			if _rc != 0 {
				local keepgoing = 0
			}
			local i = `i' + 1
		}
		capture confirm number 1
	}
	
	
	if "`remove'" == "" & ("`ado'" != "" | "`all'" != "") {
		capture mata: mata mlib index   // the core library lnwcommands.mlib has just been installed; harmless if it fails
	}
	if `__nw_models' {
		nwinstall_models, pkgs(`modelpkg') release(`release') from(`modelsfrom') `remove' `=cond("`everything'" != "" & "`remove'" == "", "stop", "")'
	}

	set more off
	
	if "`remove'" != "" {
		window menu clear
		window menu refresh
		capture ado uninstall "nwcommands-dlg"
		capture ado uninstall "nwcommands-ado"
		capture ado uninstall "nwcommands-hlp"
		capture ado uninstall "nwcommands-ext"
		capture ado uninstall "nwcommands-ext1"
		local permanently "permanently"
	}
	else {
		qui nwinstall_menu, menu("`menu'")
	}
		
		
	if "`permanently'" != "" {
		// BUGFIX (3.1.1): the profile.do edit no longer uses `shell' (mv/rename) at all.
		// The old Mac/Unix code built  shell export PATH="...`c(adopath)'..."; mv ...
		// and c(adopath) contains compound-quoted entries (`"dir"') whenever a directory
		// was added with `adopath ++ "dir"'. That unbalanced the shell quote, so mv never ran,
		// while the original profile.do had already been erased: silent loss of the user's
		// profile.do. Now the new content goes to a temp file, is verified, and replaces the
		// original with Stata's own copy (no shell, no quoting issue, same on every OS); the
		// original is never erased, and any failure leaves it untouched (or restores it).
		capture findfile "profile.do", path(`"`path'"')
		if _rc == 0 {
			local existingProfile `"`r(fn)'"'
			if "`remove'" != "" {
				nwinstall_rewriteprofile, file(`"`existingProfile'"') tmp(`"`path'/profile_nwinstall.tmp"') action(remove)
			}
			else {
				nwinstall_rewriteprofile, file(`"`existingProfile'"') tmp(`"`path'/profile_nwinstall.tmp"') action(add)
			}
		}
		else if "`remove'" == "" {
			// no profile.do yet: create it
			capture file open `fh2' using `"`path'/profile.do"', write text
			if _rc != 0 {
				di as error `"nwinstall: could not create `path'/profile.do (rc = `=_rc')"'
			}
			else {
				file write `fh2' `"nwinstall, usermenu"' _n
				file close `fh2'
			}
		}
	}	

	if "`everything'" != "" & "`remove'" == "" {
		// the versions of the whole set, as nwversion shows them (the model packages are indexed by the Mata call above)
		capture program drop nwversion
		nwversion
	}
	else if "`all'" != "" & !`__nw_models' & "`remove'" == "" {
		di as text _n "To also install the model packages type: nwinstall, models   (or nwinstall, everything)"
	}
end


capture program drop nwinstall_corever
program nwinstall_corever, rclass
	// version of the core package at the install source (its nwcommands.pkg, line "d Version: X.Y.Z"); empty if unreadable
	syntax , src(string)
	tempfile pk
	local ver ""
	capture copy `"`src'/nwcommands.pkg"' `"`pk'"', replace
	if _rc == 0 {
		tempname fh
		file open `fh' using `"`pk'"', read text
		file read `fh' line
		while r(eof) == 0 {
			if substr(`"`line'"', 1, 11) == "d Version: " & "`ver'" == "" local ver = strtrim(substr(`"`line'"', 12, .))
			file read `fh' line
		}
		file close `fh'
	}
	return local ver "`ver'"
end


capture program drop nwinstall_countlines
program nwinstall_countlines, rclass
	// number of lines of a text file; r(rc) != 0 if it cannot be read
	syntax , file(string)
	tempname fh
	return scalar n = 0
	capture file open `fh' using `"`file'"', read text
	if _rc != 0 {
		return scalar rc = _rc
		exit
	}
	local n = 0
	capture {
		file read `fh' line
		while r(eof) == 0 {
			local ++n
			file read `fh' line
		}
	}
	local rc = _rc
	capture file close `fh'
	return scalar rc = `rc'
	return scalar n = `n'
end


capture program drop nwinstall_rewriteprofile
program nwinstall_rewriteprofile
	// Adds (action(add)) or removes (action(remove)) the line "nwinstall, usermenu"
	// ("nwinstall, downloadoff", written by older versions, counts as the same line) in profile.do.
	// Safe edit: new content -> tmp file, verified by line count, backup of the original, replace
	// via -copy- (no shell), verify again, restore the backup on any failure. The original is
	// never erased; if anything fails it is left as it was and a message is printed.
	syntax , file(string) tmp(string) action(string)
	tempname fin fout
	capture erase `"`tmp'"'
	capture file open `fin' using `"`file'"', read text
	if _rc != 0 {
		di as error `"nwinstall: cannot read `file' (rc = `=_rc'); profile.do left unchanged"'
		exit
	}
	capture file open `fout' using `"`tmp'"', write text replace
	if _rc != 0 {
		local rc = _rc
		capture file close `fin'
		di as error `"nwinstall: cannot write the temporary file `tmp' (rc = `rc'); profile.do left unchanged"'
		exit
	}
	local found = 0
	local nout = 0
	capture {
		file read `fin' line
		while r(eof) == 0 {
			local t = strtrim(`"`line'"')
			if `"`t'"' == "nwinstall, usermenu" | `"`t'"' == "nwinstall, downloadoff" {
				local found = 1
				if "`action'" == "add" {
					file write `fout' `"`line'"' _n
					local ++nout
				}
			}
			else {
				file write `fout' `"`line'"' _n
				local ++nout
			}
			file read `fin' line
		}
		if "`action'" == "add" & `found' == 0 {
			file write `fout' `"nwinstall, usermenu"' _n
			local ++nout
		}
	}
	local rc = _rc
	capture file close `fin'
	capture file close `fout'
	if `rc' != 0 {
		capture erase `"`tmp'"'
		di as error `"nwinstall: editing profile.do failed (rc = `rc'); profile.do left unchanged"'
		exit
	}
	// nothing to change
	if (`found' == 1 & "`action'" == "add") | (`found' == 0 & "`action'" == "remove") {
		capture erase `"`tmp'"'
		exit
	}
	nwinstall_countlines, file(`"`tmp'"')
	if r(rc) != 0 | r(n) != `nout' {
		capture erase `"`tmp'"'
		di as error "nwinstall: the edited copy of profile.do could not be verified; profile.do left unchanged"
		exit
	}
	local bak `"`file'.nwinstall_bak"'
	capture copy `"`file'"' `"`bak'"', replace
	if _rc != 0 {
		capture erase `"`tmp'"'
		di as error "nwinstall: could not make a backup of profile.do; profile.do left unchanged"
		exit
	}
	capture copy `"`tmp'"' `"`file'"', replace
	local rc = _rc
	nwinstall_countlines, file(`"`file'"')
	if `rc' != 0 | r(rc) != 0 | r(n) != `nout' {
		capture copy `"`bak'"' `"`file'"', replace
		if _rc != 0 {
			di as error `"nwinstall: writing profile.do failed and it could not be restored automatically; your original is saved as `bak'"'
		}
		else {
			capture erase `"`bak'"'
			di as error "nwinstall: writing profile.do failed; the original was restored"
		}
		capture erase `"`tmp'"'
		exit
	}
	capture erase `"`tmp'"'
	capture erase `"`bak'"'
end


capture program drop nwinstall_menu
program nwinstall_menu
	syntax [, menu(string)]
	if "`menu'" == "" {
		local menu "stUser"
	}
	window menu append submenu "`menu'" "Network Analysis"

	window menu append item "Network Analysis" "Example Networks" "help netexample"
	window menu append item "Network Analysis" "Getting Started" "help nwstart"
	window menu append separator "Network Analysis"
	window menu append submenu "Network Analysis" "Paths and Ego Networks"
	window menu append item "Paths and Ego Networks" "Generate a variable from alter/neighbor attributes" "db nwaltergen"
	window menu append item "Paths and Ego Networks" "Ego-network size and density" "db nwego"
	window menu append item "Paths and Ego Networks" "Calculate shortest paths between nodes" "db nwgeodesic"
	window menu append item "Paths and Ego Networks" "Extract the network neighbors of a node" "db nwneighbor"
	window menu append item "Paths and Ego Networks" "Calculate paths between nodes" "db nwpath"
	window menu append item "Paths and Ego Networks" "Calculate reachability network" "db nwreach"

	window menu append submenu "Network Analysis" "Centrality"
	window menu append item "Centrality" "Two-mode (bipartite) degree centrality" "db nw2degree"
	window menu append item "Centrality" "Calculate betweenness centrality" "db nwbetween"
	window menu append item "Centrality" "Calculate closeness centrality" "db nwcloseness"
	window menu append item "Centrality" "Degree centrality and distribution" "db nwdegree"
	window menu append item "Centrality" "Calculate eigenvector centrality" "db nwevcent"
	window menu append item "Centrality" "Calculate a Katz-inspired distance-decay centrality" "db nwkatz"
	window menu append item "Centrality" "PageRank centrality" "db nwpagerank"

	window menu append submenu "Network Analysis" "Cohesion and Subgroups"
	window menu append item "Cohesion and Subgroups" "Nestedness (NODF, C-score) of a two-mode network" "db nw2nested"
	window menu append item "Cohesion and Subgroups" "Calculate bridges" "db nwbridges"
	window menu append item "Cohesion and Subgroups" "Maximal clique enumeration" "db nwclique"
	window menu append item "Cohesion and Subgroups" "Calculate network components / largest component" "db nwcomponents"
	window menu append item "Cohesion and Subgroups" "Maximal k-component enumeration" "db nwkcomponents"
	window menu append item "Cohesion and Subgroups" "k-core decomposition" "db nwkcore"
	window menu append item "Cohesion and Subgroups" "Maximal k-plex enumeration" "db nwkplex"
	window menu append item "Cohesion and Subgroups" "Maximal n-clan enumeration" "db nwnclan"
	window menu append item "Cohesion and Subgroups" "Maximal n-clique enumeration" "db nwnclique"
	window menu append item "Cohesion and Subgroups" "Calculate Simmelian ties" "db nwsimmelian"

	window menu append submenu "Network Analysis" "Community and Spectral"
	window menu append item "Community and Spectral" "Detect communities via the Louvain method or label..." "db nwcommunity"
	window menu append item "Community and Spectral" "Score an existing node partition using Newman's modularity" "db nwmodularity"
	window menu append item "Community and Spectral" "Graph Laplacian spectral analysis" "db nwspectral"

	window menu append submenu "Network Analysis" "Positions and Equivalence"
	window menu append item "Positions and Equivalence" "Clustering coefficient (transitivity) of a two-mode network" "db nw2clustering"
	window menu append item "Positions and Equivalence" "Newman's assortativity coefficient" "db nwassortativity"
	window menu append item "Positions and Equivalence" "Structural balance of a signed network" "db nwbalance"
	window menu append item "Positions and Equivalence" "Gould-Fernandez brokerage roles" "db nwbrokerage"
	window menu append item "Positions and Equivalence" "Calculate Burt structural hole measures" "db nwburt"
	window menu append item "Positions and Equivalence" "Clustering coefficient (transitivity) of a network" "db nwclustering"
	window menu append item "Positions and Equivalence" "CONCOR structural-equivalence blockmodel" "db nwconcor"
	window menu append item "Positions and Equivalence" "Calculate Burt's constraint" "db nwconstraint"
	window menu append item "Positions and Equivalence" "Discrete core-periphery detection" "db nwcoreperiphery"
	window menu append item "Positions and Equivalence" "Generate node dissimilarities" "db nwdissimilar"
	window menu append item "Positions and Equivalence" "Hierarchical clustering of nodes (role/position analysis)" "db nwhierarchy"
	window menu append item "Positions and Equivalence" "E-I index and mixing table for a categorical node attribute" "db nwmixing"
	window menu append item "Positions and Equivalence" "Calculate number of shared neighbors between nodes and..." "db nwshared"
	window menu append item "Positions and Equivalence" "Generate node similarities" "db nwsimilar"
	window menu append item "Positions and Equivalence" "Common-neighbor similarity indices between all node pairs" "db nwsimindex"

	window menu append submenu "Network Analysis" "Statistical Models"
	window menu append item "Statistical Models" "Correlate networks and variables" "db nwcorrelate"
	window menu append item "Statistical Models" "Conditional Uniform Graph (CUG) test" "db nwcug"
	window menu append item "Statistical Models" "Multivariate QAP regression" "db nwqap"
	window menu append item "Statistical Models" "Calculate utility scores according to Jackson and Wollinsky..." "db nwutility"

	// Dialogs of the separate model packages: listed only when the package's dialog file is installed
	// (nwsaom and nwergm have dialogs; nwdynam and nwrem have none)
	local __nwmodeldlg ""
	local __nwmodeldlg `"`__nwmodeldlg' "nwsaom|Stochastic actor-oriented model (nwsaom)""'
	local __nwmodeldlg `"`__nwmodeldlg' "nwsaom_multinet|nwsaom: two networks that change together (multinet)""'
	local __nwmodeldlg `"`__nwmodeldlg' "nwsaom_multiplex|nwsaom: multiplex networks""'
	local __nwmodeldlg `"`__nwmodeldlg' "nwsaom_bayes|nwsaom: Bayesian estimation""'
	local __nwmodeldlg `"`__nwmodeldlg' "nwsaom_meta|nwsaom: combine estimates from several groups (meta)""'
	local __nwmodeldlg `"`__nwmodeldlg' "nwsaom_describe|nwsaom: describe the data""'
	local __nwmodeldlg `"`__nwmodeldlg' "nwsaom_estat|nwsaom: postestimation statistics""'
	local __nwmodeldlg `"`__nwmodeldlg' "nwergm|Exponential random graph model (nwergm)""'
	local __nwmodeldlg `"`__nwmodeldlg' "nwergm_simulate|nwergm: simulate networks""'
	local __nwmodeldlg `"`__nwmodeldlg' "nwergm_estat|nwergm: postestimation and goodness of fit""'
	local __nwfirst = 1
	foreach __nwd of local __nwmodeldlg {
		gettoken __nwdn __nwdl : __nwd, parse("|")
		local __nwdl = substr(`"`__nwdl'"', 2, .)
		capture findfile `__nwdn'.dlg
		if _rc == 0 {
			if `__nwfirst' window menu append separator "Statistical Models"
			local __nwfirst = 0
			window menu append item "Statistical Models" `"`__nwdl'"' "db `__nwdn'"
		}
	}

	window menu append submenu "Network Analysis" "Other Analysis"
	window menu append item "Other Analysis" "Create a context variable" "db nwcontext"
	window menu append item "Other Analysis" "Network extensions to generate" "db nwgenerate"
	window menu append item "Other Analysis" "Checks if node exists in a network" "db nwnode"
	window menu append item "Other Analysis" "Tie turnover/stability between two waves of the same network" "db nwturnover"
	window menu append item "Other Analysis" "Returns a tie value" "db nwvalue"

	window menu append submenu "Network Analysis" "Import and Export"
	window menu append item "Import and Export" "Import two-mode network data from edgelist" "db nw2fromedge"
	window menu append item "Import and Export" "Declare data to be two-mode network data" "db nw2set"
	window menu append item "Import and Export" "Convert two-mode network to edgelist" "db nw2toedge"
	window menu append item "Import and Export" "Append network dataset" "db nwappend"
	window menu append item "Import and Export" "Export network as Pajek or Ucinet file" "db nwexport"
	window menu append item "Import and Export" "Imports network data from edgelist" "db nwfromedge"
	window menu append item "Import and Export" "Import network" "db nwimport"
	window menu append item "Import and Export" "Save network data in file" "db nwsave"
	window menu append item "Import and Export" "Declare data to be network data" "db nwset"
	window menu append item "Import and Export" "Convert network to edgelist" "db nwtoedge"
	window menu append item "Import and Export" "Load Stata network dataset" "db nwuse"
	window menu append item "Import and Export" "Load network data over the web" "db nwwebuse"

	window menu append submenu "Network Analysis" "Manipulate Networks"
	window menu append item "Manipulate Networks" "One-mode projection of a two-mode network" "db nw2project"
	window menu append item "Manipulate Networks" "Add nodes to network" "db nwaddnodes"
	window menu append item "Manipulate Networks" "Static graph view of a temporal network at a given time" "db nwattime"
	window menu append item "Manipulate Networks" "Collapse a network" "db nwcollapse"
	window menu append item "Manipulate Networks" "Drop networks or network nodes" "db nwdrop"
	window menu append item "Manipulate Networks" "Drop nodes from a network" "db nwdropnodes"
	window menu append item "Manipulate Networks" "Keep a network (or only certain nodes)" "db nwkeep"
	window menu append item "Manipulate Networks" "Keep nodes of a network" "db nwkeepnodes"
	window menu append item "Manipulate Networks" "Obtain and change meta-information of a network" "db nwname"
	window menu append item "Manipulate Networks" "Rename a single node in a network" "db nwnoderename"
	window menu append item "Manipulate Networks" "Preserve and restore network data" "db nwpreserve"
	window menu append item "Manipulate Networks" "Recode network" "db nwrecode"
	window menu append item "Manipulate Networks" "Rename a network" "db nwrename"
	window menu append item "Manipulate Networks" "Replace network" "db nwreplace"
	window menu append item "Manipulate Networks" "Replace network with Stata or Mata matrix" "db nwreplacemat"
	window menu append item "Manipulate Networks" "Restore network data previously preserved" "db nwrestore"
	window menu append item "Manipulate Networks" "Subset the nodes of a network" "db nwsubset"
	window menu append item "Manipulate Networks" "Symmetrize network" "db nwsym"
	window menu append item "Manipulate Networks" "Transpose a network" "db nwtranspose"

	window menu append submenu "Network Analysis" "Generate Networks"
	window menu append item "Generate Networks" "Duplicate a network" "db nwduplicate"
	window menu append item "Generate Networks" "Generate a network based on tie probabilities" "db nwdyadprob"
	window menu append item "Generate Networks" "Expand variable to network" "db nwexpand"
	window menu append item "Generate Networks" "Generate a homophily network" "db nwhomophily"
	window menu append item "Generate Networks" "Generate a lattice network" "db nwlattice"
	window menu append item "Generate Networks" "Generate permutation of a network" "db nwpermute"
	window menu append item "Generate Networks" "Generate a preferential-attachment network" "db nwpref"
	window menu append item "Generate Networks" "Generate a random network" "db nwrandom"
	window menu append item "Generate Networks" "Generate a ring-lattice network" "db nwring"
	window menu append item "Generate Networks" "Generate a small-world network" "db nwsmall"

	window menu append submenu "Network Analysis" "Network Information"
	window menu append item "Network Information" "Report and set current network" "db nwcurrent"
	window menu append item "Network Information" "Dyad census" "db nwdyads"
	window menu append item "Network Information" "Check if network is symmetric" "db nwissymmetric"
	window menu append item "Network Information" "Summarize a network" "db nwsummarize"
	window menu append item "Network Information" "One-way table of dyads" "db nwtabulate"
	window menu append item "Network Information" "Triad census of the network" "db nwtriads"

	window menu append submenu "Network Analysis" "Utilities"
	window menu append item "Utilities" "Clear all networks and variables from memory" "db nwclear"
	window menu append item "Utilities" "List loaded networks, in the style of Stata's own" "db nwds"
	window menu append item "Utilities" "Install Stata menu/dialogs" "db nwinstall"
	window menu append item "Utilities" "Load a network as Stata variables" "db nwload"
	window menu append item "Utilities" "Reorder networks in dataset" "db nworder"
	window menu append item "Utilities" "Sync network with Stata variables" "db nwsync"
	window menu append item "Utilities" "Return adjacency matrix of network" "db nwtomata"
	window menu append item "Utilities" "Return link to adjacency matrix of network" "db nwtomatafast"
	window menu append item "Utilities" "Copy a Mata matrix into Stata variables" "db nwtostata"
	window menu append item "Utilities" "Unabbreviate network list" "db nwunab"
	window menu append item "Utilities" "Validate network name" "db nwvalidate"
	window menu append item "Utilities" "Validate Stata variables for network" "db nwvalidvars"

	window menu append submenu "Network Analysis" "Visualize Networks"
	window menu append item "Visualize Networks" "Plot a wheel dendrogram" "db nwdendrogram"
	window menu append item "Visualize Networks" "Animate a sequence of networks" "db nwmovie"
	window menu append item "Visualize Networks" "Plot a network" "db nwplot"
	window menu append item "Visualize Networks" "Plot a network as sociomatrix" "db nwplotmatrix"

	window menu append separator "Network Analysis"
	window menu append item "Network Analysis" "Help NWCOMMANDS" "help nwcommands"
	window menu refresh
end


capture program drop nwinstall_copymanifest
program nwinstall_copymanifest
	// Copies every file listed in one of this package's own _pkg_*.txt
	// manifests (the same manifests _nwdeploy.ado reads to build the
	// GitHub .pkg files - see that file) from a local source folder
	// into a local destination ado directory. Files listed under a
	// subdirectory (currently only "lib/lnwcommands.mlib") are
	// flattened into `dest' directly, matching how a real net-installed
	// package ends up as one flat directory - Mata's own library
	// search just needs the .mlib to be somewhere on the ado path, not
	// specifically under a "lib" subfolder.
	syntax , manifest(string) from(string) dest(string)
	capture confirm file "`from'/`manifest'"
	if _rc != 0 {
		di as error "manifest not found: `from'/`manifest' - is `from' a full nwcommands source checkout?"
		exit 601
	}
	tempname fh
	file open `fh' using "`from'/`manifest'", read
	file read `fh' line
	while r(eof) == 0 {
		if substr(`"`line'"', 1, 2) == "f " {
			local relfile = substr(`"`line'"', 3, .)
			local basefile = subinstr("`relfile'", "lib/", "", .)
			capture copy "`from'/`relfile'" "`dest'/`basefile'", replace
		}
		file read `fh' line
	}
	file close `fh'
end


capture program drop nwinstall_copydialogs
program nwinstall_copydialogs
	// Dialog boxes have no fixed manifest (_nwdeploy.ado globs *.dlg/
	// *.idlg fresh at package-build time - see its own comment on why),
	// so this does the same glob directly against the source folder.
	syntax , from(string) dest(string)
	local dlgfiles : dir "`from'" files "*.dlg"
	foreach f of local dlgfiles {
		capture copy "`from'/`f'" "`dest'/`f'", replace
	}
	local idlgfiles : dir "`from'" files "*.idlg"
	foreach f of local idlgfiles {
		capture copy "`from'/`f'" "`dest'/`f'", replace
	}
end


*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
*! v2.1.0 __ added LOCALcopy/from()/dest() offline install path
