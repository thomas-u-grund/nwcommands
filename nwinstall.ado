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
		local permanently "permanently'"
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
				file open `fh2' using "`path'\profile_temp.do", write replace
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
				if c(os) == "MacOSX" {
					shell export PATH="$PATH:`:environ PATH':`c(pwd)':`path':`c(adopath)':/usr/local/bin:/usr/bin:/opt/local/bin:/opt/ImageMagick/bin/:`imagick'/";mv `c(sysdir_stata)'profile_temp.do `existingProfile'
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
	
	window menu append submenu "Network Analysis" "Generate Network"	
	window menu append item "Generate Network" "Random Network" "db nwrandom"
	window menu append item "Generate Network" "Small-World Network" "db nwsmall"
	window menu append item "Generate Network" "Ring-Lattice Network" "db nwring"
	window menu append item "Generate Network" "Lattice Network" "db nwlattice"
	window menu append item "Generate Network" "Preferential Attachment Network" "db nwpref"
	window menu append item "Generate Network" "Homophily  Network" "db nwhomophily"
	window menu append item "Generate Network" "Tie Probabilities Network" "db nwdyadprob"
	
	window menu append separator "Generate Network"	
	window menu append item "Generate Network" "Expand From Variable" "db nwexpand"
	window menu append item "Generate Network" "Duplicate Network" "db nwduplicate"

	window menu append separator "Network Analysis"
	window menu append item "Network Analysis" "Example Networks" "help netexample"
	
	window menu append separator "Network Analysis"
	window menu append item "Network Analysis" "Declare Network Data" "db nwset"
	window menu append item "Network Analysis" "Open Networks" "db nwuse"
	window menu append item "Network Analysis" "Save Networks As..." "db nwsave"
	window menu append separator "Network Analysis"
	window menu append item "Network Analysis" "Import Networks" "db nwimport"
	window menu append item "Network Analysis" "Export Networks" "db nwexport"

	window menu append submenu "Network Analysis" "Convert To/From Edgelist"
	window menu append item "Convert To/From Edgelist" "Convert To Edgelist" "db nwfromedge"
	window menu append item "Convert To/From Edgelist"  "Convert From Edgelist" "db nwfromedge"	
	
	window menu append separator "Network Analysis"
	window menu append submenu "Network Analysis" "Network Manipulation"
	window menu append item "Network Manipulation" "Drop or Keep Nodes" "db nwdrop"	
	window menu append item "Network Manipulation" "Drop or Keep Networks" "db nwdrop"
	window menu append item "Network Manipulation" "Add Nodes" "db nwaddnodes"
	
	window menu append separator "Network Manipulation"
	window menu append item "Network Manipulation" "Subset Network" "db nwsubset"	
	window menu append item "Network Manipulation" "Permute Network" "db nwpermute"		
	window menu append item "Network Manipulation" "Transpose Network" "db nwtranspose"	
	window menu append item "Network Manipulation" "Replace With Matrix" "db nwreplacemat"	
	
	window menu append separator "Network Manipulation"
	window menu append item "Network Manipulation" "Rename Network" "db nwrename"
	window menu append item "Network Manipulation" "Symmetrize Network" "db nwsym"
	window menu append item "Network Manipulation" "Unsymmetrize Network" "db nwunsym"
		
	window menu append separator "Network Manipulation"
	window menu append item "Network Manipulation" "Replace Networks" "help nwreplace"
	window menu append item "Network Manipulation" "Recode Tie Values" "db nwrecode"	
	window menu append item "Network Manipulation" "Synchronize Network With Variables" "db nwsync"	

	window menu append submenu "Network Analysis" "Network Utilities"
	window menu append item "Network Utilities" "Clear All Networks" "nwclear"	
	window menu append item "Network Utilities" "Load Network As Stata Variables" "db nwload"
	window menu append item "Network Utilities" "Synchronize Network With Variables" "db nwsync"		
	window menu append item "Network Utilities" "Order Networks" "db nworder"
	
	window menu append separator "Network Analysis"
	window menu append submenu "Network Analysis" "Summarize Networks"
	window menu append item "Summarize Networks" "List Networks" "db nwds"
	window menu append item "Summarize Networks" "Summarize" "db nwsummarize"
	window menu append item "Summarize Networks" "Dyad/Triad Census" "db nwcensus"

	window menu append submenu "Network Analysis" "Paths Between Nodes"
	window menu append item "Paths Between Nodes" "All Shortest Paths" "db nwgeodesic"	
	window menu append item "Paths Between Nodes" "Paths Between Two Nodes" "db nwpath"
	window menu append item "Paths Between Nodes" "Reachability" "db nwreach"
	window menu append separator "Network Analysis"
		
	window menu append submenu "Network Analysis" "Node-Level Characteristics"
	window menu append item "Node-Level Characteristics" "Node Centrality Coefficients" "db nwcentrality"
	window menu append item "Node-Level Characteristics" "Components and Membership" "db nwcomponents"
	window menu append item "Node-Level Characteristics" "Clustering Coefficient" "db nwclustering"	
	window menu append item "Network Analysis" "Generate Context Variable" "db nwcontext"	
	window menu append separator "Network Analysis"
	
	window menu append submenu "Network Analysis" "Tabulate Networks"
	window menu append item "Tabulate Networks" "Oneway-Tabulate Network" "db nwtabulate1"	
	window menu append item "Tabulate Networks" "Twoway-Tabulate Networks" "db nwtabulate2net"	
	window menu append item "Tabulate Networks" "Twoway-Tabulate Network and Variable" "db nwtabulate2var"

	window menu append submenu "Network Analysis" "Correlate Networks"
	window menu append item "Correlate Networks" "Correlate Two Networks" "db nwcorrelate"	
	window menu append item "Correlate Networks" "Correlate Network and Variable" "db nwcorrelate_attr"	
	
	window menu append item "Network Analysis" "Quadratic Assignment Procedure" "help nwqap"
	window menu append item "Network Analysis" "Exponential Random Graph Model" "help nwergm"
	window menu append separator "Network Analysis"
	
	window menu append submenu "Network Analysis" "Visualize Networks"
	window menu append item "Visualize Networks" "Plot" "db nwplot"	
	window menu append item "Visualize Networks" "Plot As Matrix" "db nwplotmatrix"		
	window menu append item "Visualize Networks" "Make Network Movie" "db nwmovie"
	window menu append separator "Network Analysis"
	
	window menu append separator "Network Analysis"
	window menu append item "Network Analysis" "Help NWCOMMANDS" "help nwcommands"	
	window menu refresh


end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
