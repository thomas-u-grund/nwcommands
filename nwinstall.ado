capture program drop nwinstall
program nwinstall
	syntax [, update menu(string) usermenu permanently dialog remove downloadoff help ado ext all path(string) LOCALcopy from(string) dest(string)]
	
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
	
	tempname fh1 fh2
	
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
		net from "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop"
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
		net from "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop"
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
		net from "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop"
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
		if "`remove'" != "" {
			capture findfile "profile.do", path("`path'")
			local existingProfile "`r(fn)'"
			if _rc == 0 {
				file open `fh1' using "`r(fn)'", read
				// BUGFIX: was "`path'\profile_temp.do" - a literal
				// backslash is not a path separator on Mac/Linux, so
				// this actually opened a file named "<path's own last
				// component>\profile_temp.do" in path's PARENT
				// directory, not "profile_temp.do" inside path itself.
				// Combined with the erase below (unconditional) and the
				// MacOSX branch's own mv sourcing from the wrong
				// location entirely (c(sysdir_stata), never touched by
				// this file open), the net effect on Mac (and, since no
				// Unix branch existed at all, presumably Linux) was
				// silent, permanent data loss: the original profile.do
				// was deleted and no replacement was ever written in its
				// place, with rc=0 throughout. Fixed to a forward slash,
				// which works correctly on every platform including
				// Windows (Stata's own file-open path handling accepts
				// forward slashes there too).
				file open `fh2' using "`path'/profile_temp.do", write replace
				file read `fh1' line
				while r(eof) == 0 {
					if "`line'" != "nwinstall, usermenu" {
						file write `fh2' `"`line'"' _n
					}
					file read `fh1' line
				}
				file close `fh1'
				file close `fh2'
				erase `existingProfile'
				if c(os) == "MacOSX" | c(os) == "Unix" {
					// BUGFIX: sourced from `c(sysdir_stata)' - a
					// completely different location than where fh2 was
					// actually written just above (`path') - so this mv
					// always failed ("No such file or directory",
					// visible in the log but not surfaced as a Stata
					// error since `shell' does not propagate the
					// underlying command's own exit code to `_rc').
					// Fixed to source from `path', matching the file
					// open above. Also now covers plain "Unix" (Linux),
					// not just "MacOSX" - previously c(os) values other
					// than "MacOSX"/"Windows" silently did nothing after
					// the erase, an equally destructive gap.
					shell export PATH="$PATH:`:environ PATH':`c(pwd)':`path':`c(adopath)':/usr/local/bin:/usr/bin:/opt/local/bin:/opt/ImageMagick/bin/:`imagick'/";mv `path'/profile_temp.do `existingProfile'
				}
				if c(os) == "Windows" {
					di "shell rename `path'/profile_temp.do `existingProfile'"
					shell rename `path'\profile_temp.do `existingProfile'
				}
			}

		}
		
			
		// add to profile
		else  {
			capture findfile "profile.do",  path("`path'")
			if _rc == 0{
				local alreadyInstalled = 0
				file open `fh1' using "`path'/profile.do", read 
				file read `fh1' line
				while r(eof) == 0 {
					if `"`line'"' == "nwinstall, usermenu" {
						local alreadyInstalled = 1
					}
					file read `fh1' line
				}
				file close `fh1'
				
				if `alreadyInstalled' == 0 {
					file open `fh2' using "`path'/profile.do", write append
					file write `fh2' `"nwinstall, downloadoff"' _n
					file close `fh2'
				}	
			}
			// write profile.do
			else {
				file open `fh2' using "`path'/profile.do", write
				file write `fh2' `"nwinstall, usermenu"' _n
				file close `fh2'
			}
		}
	}	
end


capture program drop nwinstall_menu
program nwinstall_menu
	syntax [, menu(string)]
	if "`menu'" == "" {
		local menu "stUser"
	}
	window menu append submenu "`menu'" "Network Analysis"

	window menu append item "Network Analysis" "Example Networks" "help netexample"
	window menu append item "Network Analysis" "Getting Started" "help nw_start"
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

	window menu append submenu "Network Analysis" "Cohesion and Subgroups"
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
	window menu append item "Statistical Models" "Exponential-family random graph model (ERGM) estimation" "db nwergm"
	window menu append item "Statistical Models" "Multivariate QAP regression" "db nwqap"
	window menu append item "Statistical Models" "Calculate utility scores according to Jackson and Wollinsky..." "db nwutility"

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
