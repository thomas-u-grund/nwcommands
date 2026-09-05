capture program drop _nwdeploy
program _nwdeploy
	syntax , version(string) [author(string) email(string) other(string)]

	_write_nwcommands, version(`version')
	tempname versionlog
	file open `versionlog' using versionlog.sh, replace write
	
	set more off
	local d = lower(subinstr(c(current_date)," ","",.))
	// BUGFIX: a monolithic nwcommands-ado.pkg (117 f-lines, ~122 lines
	// total with its own header) silently fails "net install" with
	// "package file too long" - a real, previously-undiscovered Stata
	// .pkg format limit, confirmed empirically via a binary search on a
	// local install (103 total lines installs fine, 104 does not; this
	// package's own actual header is 5 lines, so kept a generous 80-line
	// safety margin below that rather than the exact measured boundary).
	// Never surfaced before this harmonisation unit because the tool
	// itself never ran to completion until now. Fixed by chunking into
	// multiple numbered packages (nwcommands-ado1.pkg, -ado2.pkg, ...)
	// - see nwdeploy_writepkgchunks below - rather than shipping a
	// single package nobody could actually install.
	nwdeploy_writepkgchunks, manifest(_pkg_ado.txt) base(nwcommands-ado) desc("nwcommands-ado. Social Network Analysis Using Stata") email(thomas.u.grund@gmail.com) date(`d')
	local nadochunks = r(chunks)

	local adofiles : dir "`c(pwd)'" files "*.ado"
	local sthlpfiles : dir "`c(pwd)'" files "*.sthlp"
	// `: dir' returns files in filesystem order, not alphabetical - left
	// that way for years despite nwalphabetical.sthlp's own name/stated
	// purpose (confirmed directly: a from-scratch _nwdeploy run, only
	// possible for the first time after the quote-parsing fixes above,
	// produced a genuinely non-alphabetical "alphabetical" list). Sorted
	// explicitly via Mata rather than trusting directory-listing order.
	mata: st_local("adofiles", invtokens(sort(tokens(st_local("adofiles"))', 1)'))
	mata: st_local("sthlpfiles", invtokens(sort(tokens(st_local("sthlpfiles"))', 1)'))

	// generate topical glossary help
	tempname memhold
	tempfile topics
	postfile `memhold' str30 cmdname str60 link str80 topic using `topics'
	foreach file in `sthlpfiles' {
		// add sthlp meta info
		//di "sthlp: `file'"
		//qui _addmeta_hlp `file', date(`d') version(`version')

		local cmdname = substr("`file'", 1, `=(length("`file'") - 6)')
		// Leading-underscore files are internal-only helpers (see
		// nwinternals.sthlp), even when (like _nwdatasync/_nwtomata)
		// they have their own .sthlp for programmers - never listed
		// in the general topical index.
		if substr("`cmdname'", 1, 1) == "_" {
			continue
		}
		getcmdtopic `cmdname'
		if "`r(cmdtopic)'" != "" {
			post `memhold' ("`cmdname'") ("`r(topiclink)'") ("`r(cmdtopic)'")
		}
		if "`r(cmdtopic2)'" != "" {
			post `memhold' ("`cmdname'") ("`r(topiclink2)'") ("`r(cmdtopic2)'")
		}
	}	
	postclose `memhold'

	preserve
	use `topics', clear

	sort topic cmdname
	
	tempname topical
	file open `topical' using nwtopical.sthlp, replace write
	file write `topical' "{smcl}" _n ///	
			"{* *! version `version' `d'}{...}"  _n ///
		    "{phang}" _n ///
			"{help nwcommands:NW-2 topical} {hline 2} " _n ///
			"{hline 2} Topical list of network commands" _n ///
			"" _n ///
			"{title:Contents}" _n ///	
			"" _n ///
			"{col 14}Section{col 31}Description" _n ///
			"{col 14}{hline 46}" _n ///
"{help nwtopical##concept:{col 14}{bf:[NW-2.1]}{...}{col 31}{bf:Concepts}}" _n ///
	"" _n ///
"{help nwtopical##import:{col 14}{bf:[NW-2.2]}{...}{col 31}{bf:Import/Export}}" _n ///
	"" _n ///
"{help nwtopical##generator:{col 14}{bf:[NW-2.3]}{...}{col 31}{bf:Generators}}" _n ///
	"" _n ///
"{help nwtopical##information:{col 14}{bf:[NW-2.4]}{...}{col 31}{bf:Information}}" _n ///
	"" _n ///
"{help nwtopical##manipulation:{col 14}{bf:[NW-2.5]}{...}{col 31}{bf:Manipulation}}" _n ///
	"" _n ///
"{help nwtopical##analysis:{col 14}{bf:[NW-2.6]}{...}{col 31}{bf:Analysis}}" _n ///
	"" _n ///
"{help nwtopical##utilities:{col 14}{bf:[NW-2.7]}{...}{col 31}{bf:Utilities}}" _n ///
	"" _n ///
"{help nwtopical##visualization:{col 14}{bf:[NW-2.8]}{...}{col 31}{bf:Visualization}}" _n ///
	"" _n ///
"{help nwtopical##programming:{col 14}{bf:[NW-2.9]}{...}{col 31}{bf:Programming}}" _n _n

	set more off
	// Was a hardcoded `substr(link, 13, .)`, tuned for the old
	// "nw_topical##" prefix (12 chars) - silently started stripping one
	// character too few after the nw_topical -> nwtopical rename shortened
	// the prefix to "nwtopical##" (11 chars), truncating every single
	// marker name by its own first character (e.g. "concept" -> "oncept")
	// without erroring, since Stata's help viewer resolves anchors by
	// exact string match, not by validating they're real words. Found via
	// a from-scratch website-reference regeneration (see GOTCHA.md).
	// Fixed to derive the offset from the actual "##" delimiter instead
	// of a hardcoded length, so a future rename can't reintroduce this.
	gen topicmarker = substr(link, strpos(link, "##") + 2, .)

	local wrote_analysis_marker = 0
	forvalues i = 1/`=_N' {
		local t = topicmarker[`i']
		local t_lag = topicmarker[`=`i'-1']
		if "`t'" != "`t_lag'" {
			// The hardcoded TOC block above links {help nwtopical##analysis:...}
			// for the "Analysis" row, but no {marker analysis} was ever emitted
			// anywhere in the generated file - a dangling anchor since the TOC
			// was first written (pre-dates the rename bugs above). Emit it once,
			// right before the first analysis_* subsection reached in sort
			// order - guarded by a flag rather than "did the previous group
			// start with analysis_", since the "analysis_utility"/nwds group
			// sorts away from its analysis_* siblings (its own topic string,
			// "[NW-2.7] Utility Commands", sorts after the unrelated
			// "[NW-2.7] Utilities" section), which would otherwise emit this
			// marker a second time.
			if substr("`t'", 1, 9) == "analysis_" & `wrote_analysis_marker' == 0 {
				file write `topical' "{marker analysis}{...}" _n
				local wrote_analysis_marker = 1
			}
			local tm = topicmarker[`i']
			// Was a hardcoded `substr(topic[`i'],10,.)`, tuned for a
			// single-level section number like "[NW-2.1] " (9 chars
			// through the space) - silently dropped the closing bracket
			// and space for a two-level number like "[NW-2.6.6] " (11
			// chars), leaving the banner title starting with a stray "]"
			// (e.g. "] Statistical Estimation..." instead of "Statistical
			// Estimation..."). Derive the cut point from the actual "] "
			// delimiter instead of a hardcoded length. See GOTCHA.md.
			local tpos = strpos(topic[`i'], "] ")
			local tc = substr(topic[`i'], `tpos' + 2, .)
			file write `topical' "{marker `tm'}{...}" _n ///
					"" _n ///
					"{col 8}   {c TLC}{hline 24}{c TRC}" _n ///
					"{col 8}{hline 3}{c RT}       {it:`tc'}{col 36}{c LT}{hline}" _n ///
					"{col 8}   {c BLC}{hline 24}{c BRC}" _n ///
					"{p2colset 12 35 36 2}" _n ///
					""
		}
		local cn = cmdname[`i']
		capture getcmddesc `cn'
		if _rc == 0 {
			file write `topical' "{p2col:    {bf:{help `cn' }}}`r(cmddesc)'{p_end}" _n		
		}
	}
	
	local tc = "Uncategorized"
	file write `topical' "{marker uncategorized}{...}" _n ///
					"" _n ///
					"{col 8}   {c TLC}{hline 24}{c TRC}" _n ///
					"{col 8}{hline 3}{c RT}       {it:`tc'}{col 36}{c LT}{hline}" _n ///
					"{col 8}   {c BLC}{hline 24}{c BRC}" _n ///
					"{p2colset 12 35 36 2}" _n ///
					""
					
	foreach file in `adofiles' {
		local cmdname = substr("`file'", 1, `=(length("`file'") - 4)')
		getcmddesc `cmdname'
		// Leading-underscore files are internal-only helpers (see
		// nwinternals.sthlp) - never meant to be called by name
		// directly, so they don't belong in the general topical index
		// even as an "Uncategorized" catch-all entry.
		if "`r(cmddesc)'" == "{err}no help file yet{txt}" & substr("`cmdname'", 1, 1) != "_" {
			file write `topical' "{p2col:{bf:{help `cmdname' }}}`r(cmddesc)'{p_end}" _n
		}
		file write `versionlog' `"echo "*! v`version' __ `c(current_date)' __ `c(current_time)'" >> `file'"'  _n
	}
	
	file close `topical'
	restore
	
	// generate alphabetical glossary help
	tempname alphabetical
	file open `alphabetical' using nwalphabetical.sthlp, replace write
	file write `alphabetical' "{smcl}" _n ///	
			"{* *! version 1.0.0  3sept2014}{...}"  _n ///
			"{phang}" _n ///
			"{help nwcommands:NW-3 alphabetical} {hline 2} Alphabetical list of network programs" _n ///
			" "_n ///
			"{col 5}{hline}" _n ///
			"{p2colset 5 32 34 2}" 
	set more off
	
	foreach file in `adofiles' {

		// add meta to dofiles
		// di "ado: `file'"
		//qui _addmeta_do `file', date(`d') author(`author') email(`email') version(`version') other(`other')

		local cmdname = substr("`file'", 1, `=(length("`file'") - 4)')
		// Leading-underscore files are internal-only helpers (see
		// nwinternals.sthlp) - not listed in the general alphabetical
		// index, same reasoning as the topical index above.
		if substr("`cmdname'", 1, 1) == "_" {
			continue
		}
		getcmddesc `cmdname'
		file write `alphabetical' "{p2col:{bf:{help `cmdname' }}}`r(cmddesc)'{p_end}" _n
	}

	file close `alphabetical'

	// Same "package file too long" fix as nwcommands-ado above -
	// nwcommands-hlp.pkg (119 f-lines) is even larger.
	nwdeploy_writepkgchunks, manifest(_pkg_hlp.txt) base(nwcommands-hlp) desc("nwcommands-hlp. Social Network Analysis Using Stata - Help Files") email(thomas.u.grund@gmail.com) date(`d')
	local nhlpchunks = r(chunks)

	// Tiny, permanent bootstrap package: a brand-new user has no way to
	// know they need to type an internal chunk name like
	// "nwcommands-ado1" as their very first command - there was no
	// plain "nwcommands" package at all. This one is deliberately
	// small and hand-curated (not chunked from the full ado/hlp
	// manifests) so it always fits Stata's own package-file line limit
	// trivially and its name never needs to change as the real ado/hlp
	// chunk count grows. Contains just enough to bootstrap the rest:
	// nwinstall.ado itself (no Mata dependency - confirmed directly,
	// zero `mata:' calls in the file - so the compiled .mlib is not
	// needed here) plus the landing/orientation help topics, so `help
	// nwcommands' works immediately even before `nwinstall, all' pulls
	// in everything else. The intended flow is exactly two commands:
	// `net install nwcommands' then `nwinstall, all'.
	file open deploy_boot using nwcommands.pkg, replace write
	file write deploy_boot "v 3" _n
	file write deploy_boot "d nwcommands. Start here - installs nwinstall and the landing help topics; run nwinstall, all next" _n
	file write deploy_boot "d Thomas U. Grund, University College Dublin, www.grund.co.uk" _n
	file write deploy_boot "d email: thomas.u.grund@gmail.com" _n
	file write deploy_boot "d Distribution-Date: `d'" _n

	file open _pkg_boot1 using _pkg_boot.txt, read
	file read _pkg_boot1 _pkg_boot1_line
	while "`_pkg_boot1_line'" != "" {
		file write deploy_boot "`_pkg_boot1_line'" _n
		file read _pkg_boot1 _pkg_boot1_line
	}
	file close _pkg_boot1
	file close deploy_boot

	// REMOVED (2026-09-02): nwcommands-ext.pkg (nwdissimilar/nwhierarchy/
	// nwdendrogram) used to be written here as its own separate package,
	// but all three commands' .ado/.sthlp files turned out to ALREADY be
	// listed in _pkg_ado.txt/_pkg_hlp.txt as well - nwcommands-ext.pkg
	// was 100% redundant with nwcommands-ado1.pkg/nwcommands-hlp1.pkg,
	// not a genuinely separate "extension" (there was never a real
	// reason for these three commands to be called out as an
	// "Extension" distinct from every other command in the package -
	// confirmed directly, not merely renamed/relabeled). Erase any
	// leftover copy from before this fix (a transient
	// nwcommands-ext1.pkg existed only locally, briefly, mid-fix, and
	// was never published) so a checkout carrying either old name
	// doesn't leave a stale duplicate package lying around; the actual
	// UNINSTALL of a previously-published "nwcommands-ext" is
	// nwinstall.ado's own job, since that's what runs on an existing
	// user's machine.
	capture erase nwcommands-ext.pkg
	capture erase nwcommands-ext1.pkg

	// BUGFIX: same "package file too long" limit as nwcommands-ado/-hlp
	// above, just discovered later - the dialog rebuild grew the .dlg
	// count from ~60 to 122+, pushing a single nwcommands-dlg.pkg past
	// Stata's per-package line limit (confirmed empirically: a real
	// `net install "nwcommands-dlg", all' now fails with "package file
	// too long" / r(640), which a genuine colleague-install test caught
	// - see nwinstall.ado's own dialog-install loop, updated to match).
	// Chunked via the same nwdeploy_writepkgchunks helper as ado/hlp,
	// via a temp manifest file since dlg/idlg have no _pkg_dlg.txt of
	// their own (built by globbing, same as the old single-file code
	// this replaces did).
	tempfile _pkg_dlg_tmp
	tempname dlgmanifest
	file open `dlgmanifest' using "`_pkg_dlg_tmp'", replace write
	local dlgfiles : dir "`c(pwd)'" files "*.dlg"
	foreach file in `dlgfiles' {
		file write `dlgmanifest' "f `file'" _n
	}
	local idlgfiles : dir "`c(pwd)'" files "*.idlg"
	foreach file in `idlgfiles' {
		file write `dlgmanifest' "f `file'" _n
	}
	file close `dlgmanifest'
	nwdeploy_writepkgchunks, manifest(`"`_pkg_dlg_tmp'"') base(nwcommands-dlg) desc("nwcommands-dlg. Social Network Analysis Using Stata - Dialog Boxes") email(thomas.u.grund@gmail.com) date(`d')
	local ndlgchunks = r(chunks)
	capture erase nwcommands-dlg.pkg
	file close `versionlog'

	// stata.toc drives `net from'/`net install' discovery - generated
	// here (rather than hand-maintained) so the chunk counts above
	// always match what actually got written, even as the package
	// grows past whatever chunk boundary is currently in force.
	tempname toc
	file open `toc' using stata.toc, replace write
	file write `toc' "v 3" _n
	file write `toc' "d nwcommands: Network Analysis for Stata" _n
	file write `toc' _n "p nwcommands" _n "d nwcommands. Start here - net install this first, then run nwinstall, all" _n
	forvalues i = 1/`nadochunks' {
		file write `toc' _n "p nwcommands-ado`i'" _n "d nwcommands-ado. Social Network Analysis Using Stata (part `i' of `nadochunks')" _n
	}
	forvalues i = 1/`nhlpchunks' {
		file write `toc' _n "p nwcommands-hlp`i'" _n "d nwcommands-hlp. Social Network Analysis Using Stata - Help Files (part `i' of `nhlpchunks')" _n
	}
	forvalues i = 1/`ndlgchunks' {
		file write `toc' _n "p nwcommands-dlg`i'" _n "d nwcommands-dlg. Social Network Analysis Using Stata - Dialog Boxes (part `i' of `ndlgchunks')" _n
	}
	file close `toc'
end

capture program drop nwdeploy_writepkgchunks
program nwdeploy_writepkgchunks, rclass
	// Writes `manifest' (a flat file of "f filename" lines) out as one
	// or more numbered .pkg files (`base'1.pkg, `base'2.pkg, ...),
	// never exceeding `chunksize' f-lines per file - see the "package
	// file too long" comment at this program's own call sites for why.
	// Returns the number of chunks written (r(chunks)) so the caller
	// can both loop over them and regenerate stata.toc to match.
	syntax , manifest(string) base(string) desc(string) email(string) date(string) [chunksize(integer 80)]
	tempname fh mh
	file open `mh' using `manifest', read
	file read `mh' line
	local chunknum = 0
	local linecount = `chunksize'
	while "`line'" != "" {
		if `linecount' >= `chunksize' {
			if `chunknum' > 0 {
				file close `fh'
			}
			local chunknum = `chunknum' + 1
			file open `fh' using `base'`chunknum'.pkg, replace write
			file write `fh' "v 3" _n
			file write `fh' "d `desc' (part `chunknum')" _n
			file write `fh' "d Thomas U. Grund, University College Dublin, www.grund.co.uk" _n
			file write `fh' "d email: `email'" _n
			file write `fh' "d Distribution-Date: `date'" _n
			local linecount = 0
		}
		file write `fh' "`line'" _n
		local linecount = `linecount' + 1
		file read `mh' line
	}
	if `chunknum' > 0 {
		file close `fh'
	}
	file close `mh'
	return scalar chunks = `chunknum'
end

capture program drop getcmddesc
program getcmddesc, rclass
	syntax anything(name=cmd)
	capture findfile `cmd'.sthlp
	if _rc != 0 {
		return local cmddesc = "{err}no help file yet{txt}"
		exit
	}
	else {
		set more off
		tempname cmdsthlp
		file open `cmdsthlp' using `cmd'.sthlp, read		
		file read `cmdsthlp' line
		local found = 0
		while (r(eof)==0 & `found' == 0) {
			// BUGFIX: was strpos("`line'", ...)/substr("`cmddesc'",...) -
			// plain double quotes around a macro whose VALUE is an
			// arbitrary .sthlp source line, which routinely contains its
			// own literal embedded double quotes (e.g. a di "..." line
			// from the command's own doc header) - those embedded quotes
			// prematurely closed the plain "..." literal, leaving a bare
			// trailing token Stata then tried to interpret as a command
			// name ("invalid name", r(198)) - confirmed directly via
			// `set trace on` on the exact nwclustering.ado line that
			// triggered it. Compound quotes handle embedded literal
			// quotes correctly, same fix already used one line below
			// for `line' itself.
			local j = strpos(`"`line'"', "{hline 2}")
			if (`j' >0) {
                local cmddesc = substr(`"`line'"', `=`j' + 10', .)
				// BUGFIX: was substr(`"`cmddesc'"',1,`=length(`"`cmddesc'"')-1')
				// - a literal apostrophe anywhere in the command's own
				// one-line description (e.g. nwmodularity.sthlp's
				// "Newman's modularity") gets misread as the extended
				// macro function's own closing quote when nested this
				// way, dropping the second substr() argument entirely
				// ("too few quotes" / "too many ')' or ']'" - confirmed
				// directly via an isolated repro). Computing the length
				// as its own separate local first avoids the hazard.
				// BUGFIX: this stripped only the trailing "-1" character
				// (just the closing brace of the source line's own
				// "{p_end}" tag), leaving a dangling "{p_end" - but every
				// call site (nwtopical.sthlp's/nwalphabetical.sthlp's
				// own generation, further below) unconditionally appends
				// its own literal "{p_end}" after this returned cmddesc,
				// so the actual output was the malformed
				// "...{p_end{p_end}" - confirmed directly by running
				// _nwdeploy end to end for the first time (only possible
				// after the quote-parsing fixes above let it get this
				// far) and inspecting the regenerated file. Every
				// command's own {p2col:...}Description{p_end} synopsis
				// line ends in the fixed 7-character "{p_end}" tag by
				// convention throughout this package - strip all 7, not 1.
				local cmddesclen = length(`"`cmddesc'"')
				local cmddesc = substr(`"`cmddesc'"', 1, `cmddesclen' - length("{p_end}"))
				local found = 1
            }
			file read `cmdsthlp' line
		}
		return local cmddesc = "`cmddesc'"
	}
	file close `cmdsthlp'
end

capture program drop getcmdtopic
program getcmdtopic, rclass
	syntax anything(name=cmd)
	capture findfile `cmd'.sthlp
	if _rc != 0 {
		return local cmdtopic = "Uncategorized"
		return local topiclink = "nwtopical##uncategorized"
		exit
	}
	else {
		tempname cmdsthlp
		file open `cmdsthlp' using `cmd'.sthlp, read
		//file open `cmdsthlp' using nwergm.sthlp, read		

		file read `cmdsthlp' line
		local found = 0
		while (r(eof)==0) {
			local j = strpos(`"`line'"', "{marker topic}")
			//di `"`line'"'
			if (`j' >0) {
				//local found 0
				file read `cmdsthlp' line
                gettoken topiclink cmdtopic : line, parse(":") 
				// Same apostrophe-in-nested-`=...' hazard as
				// getcmddesc above - fixed the same way.
				local cmdtopiclen = length(`"`cmdtopic'"')
				local cmdtopic= substr(`"`cmdtopic'"', 2, `cmdtopiclen' - 2)
				local topiclink= substr(`"`topiclink'"', 8,.)	
            }
			local k = strpos(`"`line'"', "{marker top2}")
			if (`k' >0) {
				file read `cmdsthlp' line
                gettoken topiclink2 cmdtopic2 : line, parse(":") 
				local cmdtopic2len = length(`"`cmdtopic2'"')
				local cmdtopic2= substr(`"`cmdtopic2'"', 2, `cmdtopic2len' - 2)
				local topiclink2= substr(`"`topiclink2'"', 8,.)	
            }
			file read `cmdsthlp' line
		}			
		return local cmdtopic = "`cmdtopic'"
		return local topiclink = "`topiclink'"
		if "`cmdtopic2'" != "" {
			return local cmdtopic2 = "`cmdtopic2'"
			return local topiclink2 = "`topiclink2'"
		}
	}
	file close `cmdsthlp'
	//shell sh versionlog.sh
end

capture program drop _write_nwcommands
program _write_nwcommands
	syntax , version(string)
	set more off
	tempname nw
	file open `nw' using nwcommands.sthlp, replace write
	file write `nw' "{smcl}" _n ///
"{* *! version 1.0.0  3sept2014}{...}" _n ///
"" _n ///
"{pstd}" _n ///
"New here? If this is all you have installed so far, run {cmd:nwinstall, all} to download everything else" _n ///
"(core commands, help files, dialog boxes) - see {help nwinstall}." _n ///
"{p_end}" _n ///
"" _n ///
"{col 14}Section{col 31}Description" _n ///
"{col 14}{hline 46}" _n ///
"{help nwintro:{col 14}{bf:[NW-1]}{...}{col 31}{bf:Introduction and concepts}}" _n ///
"" _n ///
"{help nwtopical:{col 14}{bf:[NW-2]}{...}{col 31}{bf:Topical list of network commands}}" _n ///
"" _n ///
"{help nwalphabetical:{col 14}{bf:[NW-3]}{...}{col 31}{bf:Alphabetical list of network commands}}" _n ///
"" _n ///
"{help nwstart:{col 14}{bf:[NW-4]}{...}{col 31}{bf:Getting started}}" _n ///
"" _n ///
"{help nwprogramming:{col 14}{bf:[NW-5]}{...}{col 31}{bf:Network programming}}" _n ///
"" _n ///
"{help nwinstall:{col 14}{bf:[NW-6]}{...}{col 31}{bf:Install Stata menus/dialogs}}" _n ///
"" _n ///
"{help nwinternals:{col 14}{bf:[NW-7]}{...}{col 31}{bf:Internal helper files}}" _n ///
"" _n ///
"" _n ///
"		*! Date        : `c(current_date)'" _n ///
"		*! Version     : `version'" _n ///
"		*! Authors     : Thomas U. Grund " _n ///
"		*! Contact     : thomas.u.grund@gmail.com" _n ///
`"		 *! Web         : {browse "https://github.com/thomas-u-grund/nwcommands"}"' _n ///
`"		 *! Bugs        : {browse "mailto:thomas.u.grund@gmail.com"}"'
	file close `nw'
end

/*

capture program drop _addmeta_do
program _addmeta_do
	syntax anything(name=adofile), date(string) [ version(string) author(string) email(string) other(string) ]
	
	tempname meta
	tempname myfile 
	
	file open `meta' using "_metatemp.do", write replace 
	file write `meta' "*! Date      :`date'" _n
	file write `meta' "*! Version   :`version'" _n
	file write `meta' "*! Author    :`author'" _n
	file write `meta' "*! Email     :`email'" _n
	if "`other'" != "" {
		file write `meta' "*! Email     :`email'" _n
	}
	file write `meta' "" _n
	
	file open `myfile' using "`adofile'", read
	file read `myfile' line
	
	local codestarted= 0
	while r(eof)==0 {
		di `"`line'"'
		if ("`=word(`"`line'"',1)'" == "capture"){
			local codestarted = 1
		}
		// copy file
		if `codestarted' == 1 {
			file write `meta' "`line'" _n
		}
		file read `myfile' line	
	}
	file close `myfile'
	file close `meta'
	//erase `adofile'
	//!mv _metatemp.do `adofile'
end


capture program drop _addmeta_hlp
program _addmeta_hlp
	syntax anything(name=hlpfile), date(string) version(string)

	set more off
	tempname meta
	tempname myfile 
	
	file open `meta' using "_metatemp.sthlp", write replace
	file write `meta' "{smcl}" _n
	file write `meta' "{* *! version `version'  `date'}{...}" _n	
	file open `myfile' using "`hlpfile'", read
	file read `myfile' line
	
	local codestarted= 0
	while r(eof)==0 {
		if (`"`line'"' == "{marker topic}"){
			local codestarted = 1
		}
		// copy file
		if `codestarted' == 1 {
			file write `meta' `"`line'"' _n
		}
		file read `myfile' line	
	}
	file close `myfile'
	file close `meta'
	erase `hlpfile'
	!mv _metatemp.sthlp `hlpfile'
end

*/

