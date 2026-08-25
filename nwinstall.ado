capture program drop nwinstall
program nwinstall
	syntax [, update menu(string) usermenu permanently dialog remove downloadoff help ado ext all path(string)]
	
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
		local ext = "ext"
		local dialog = "dialog"
		local permanently = "permanently"
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
	if "`ado'" != "" | "`all'" != "" {
		capture ado uninstall "nwcommands-ado"
		net from "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop"
		local i = 1
		local keepgoing = 1
		while `keepgoing' {
			capture net install "nwcommands-ado`i'", all
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

	if "`help'" != "" {
		capture ado uninstall "nwcommands-hlp"
		net from "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop"
		local i = 1
		local keepgoing = 1
		while `keepgoing' {
			capture net install "nwcommands-hlp`i'", all
			if _rc != 0 {
				local keepgoing = 0
			}
			local i = `i' + 1
		}
		capture confirm number 1
	}

	if "`ext'" != "" {
		capture ado uninstall "nwcommands-ext"
		net from "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop"
		net install "nwcommands-ext", all
	}


	if "`dialog'" != "" {
		capture ado uninstall "nwcommands-dlg"
		net from "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/develop"
		net install "nwcommands-dlg", all
	}
	
	
	set more off
	
	if "`remove'" != "" {
		window menu clear
		window menu refresh
		capture ado uninstall "nwcommands-dlg"
		capture ado uninstall "nwcommands-ado"
		capture ado uninstall "nwcommands-hlp"
		capture ado uninstall "nwcommands-ext"
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
	window menu append submenu "Network Analysis" "Paths && Ego Networks"
	window menu append item "Paths && Ego Networks" "Generate a variable from alter/neighbor attributes" "db nwaltergen"
	window menu append item "Paths && Ego Networks" "Ego-network size and density" "db nwego"
	window menu append item "Paths && Ego Networks" "Calculate shortest paths between nodes" "db nwgeodesic"
	window menu append item "Paths && Ego Networks" "Extract the network neighbors of a node" "db nwneighbor"
	window menu append item "Paths && Ego Networks" "Calculate paths between nodes" "db nwpath"
	window menu append item "Paths && Ego Networks" "Calculate reachability network" "db nwreach"

	window menu append submenu "Network Analysis" "Centrality"
	window menu append item "Centrality" "Two-mode (bipartite) degree centrality" "db nw2degree"
	window menu append item "Centrality" "Calculate betweenness centrality" "db nwbetween"
	window menu append item "Centrality" "Calculate closeness centrality" "db nwcloseness"
	window menu append item "Centrality" "Degree centrality and distribution" "db nwdegree"
	window menu append item "Centrality" "Calculate eigenvector centrality" "db nwevcent"
	window menu append item "Centrality" "Calculate a Katz-inspired distance-decay centrality" "db nwkatz"

	window menu append submenu "Network Analysis" "Cohesion && Subgroups"
	window menu append item "Cohesion && Subgroups" "Calculate bridges" "db nwbridges"
	window menu append item "Cohesion && Subgroups" "Maximal clique enumeration" "db nwclique"
	window menu append item "Cohesion && Subgroups" "Calculate network components / largest component" "db nwcomponents"
	window menu append item "Cohesion && Subgroups" "Maximal k-component enumeration" "db nwkcomponents"
	window menu append item "Cohesion && Subgroups" "k-core decomposition" "db nwkcore"
	window menu append item "Cohesion && Subgroups" "Maximal k-plex enumeration" "db nwkplex"
	window menu append item "Cohesion && Subgroups" "Maximal n-clan enumeration" "db nwnclan"
	window menu append item "Cohesion && Subgroups" "Maximal n-clique enumeration" "db nwnclique"
	window menu append item "Cohesion && Subgroups" "Calculate Simmelian ties" "db nwsimmelian"

	window menu append submenu "Network Analysis" "Community && Spectral"
	window menu append item "Community && Spectral" "Detect communities via the Louvain method or label..." "db nwcommunity"
	window menu append item "Community && Spectral" "Score an existing node partition using Newman's modularity" "db nwmodularity"
	window menu append item "Community && Spectral" "Graph Laplacian spectral analysis" "db nwspectral"

	window menu append submenu "Network Analysis" "Positions && Equivalence"
	window menu append item "Positions && Equivalence" "Clustering coefficient (transitivity) of a two-mode network" "db nw2clustering"
	window menu append item "Positions && Equivalence" "Newman's assortativity coefficient" "db nwassortativity"
	window menu append item "Positions && Equivalence" "Structural balance of a signed network" "db nwbalance"
	window menu append item "Positions && Equivalence" "Gould-Fernandez brokerage roles" "db nwbrokerage"
	window menu append item "Positions && Equivalence" "Calculate Burt structural hole measures" "db nwburt"
	window menu append item "Positions && Equivalence" "Clustering coefficient (transitivity) of a network" "db nwclustering"
	window menu append item "Positions && Equivalence" "CONCOR structural-equivalence blockmodel" "db nwconcor"
	window menu append item "Positions && Equivalence" "Calculate Burt's constraint" "db nwconstraint"
	window menu append item "Positions && Equivalence" "Discrete core-periphery detection" "db nwcoreperiphery"
	window menu append item "Positions && Equivalence" "Generate node dissimilarities" "db nwdissimilar"
	window menu append item "Positions && Equivalence" "Hierarchical clustering of nodes (role/position analysis)" "db nwhierarchy"
	window menu append item "Positions && Equivalence" "E-I index and mixing table for a categorical node attribute" "db nwmixing"
	window menu append item "Positions && Equivalence" "Calculate number of shared neighbors between nodes and..." "db nwshared"
	window menu append item "Positions && Equivalence" "Generate node similarities" "db nwsimilar"
	window menu append item "Positions && Equivalence" "Common-neighbor similarity indices between all node pairs" "db nwsimindex"

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

	window menu append submenu "Network Analysis" "Import && Export"
	window menu append item "Import && Export" "Import two-mode network data from edgelist" "db nw2fromedge"
	window menu append item "Import && Export" "Declare data to be two-mode network data" "db nw2set"
	window menu append item "Import && Export" "Convert two-mode network to edgelist" "db nw2toedge"
	window menu append item "Import && Export" "Append network dataset" "db nwappend"
	window menu append item "Import && Export" "Export network as Pajek or Ucinet file" "db nwexport"
	window menu append item "Import && Export" "Imports network data from edgelist" "db nwfromedge"
	window menu append item "Import && Export" "Import network" "db nwimport"
	window menu append item "Import && Export" "Save network data in file" "db nwsave"
	window menu append item "Import && Export" "Declare data to be network data" "db nwset"
	window menu append item "Import && Export" "Convert network to edgelist" "db nwtoedge"
	window menu append item "Import && Export" "Load Stata network dataset" "db nwuse"
	window menu append item "Import && Export" "Load network data over the web" "db nwwebuse"

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

*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
