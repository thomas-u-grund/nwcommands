capture program drop _nwdeploy
program _nwdeploy
	syntax , version(string) [author(string) email(string) other(string)]

	set more off
	local d = lower(subinstr(c(current_date)," ","",.))
	// the release version and date come from the file VERSION (see RELEASING.md); without it the package files carry no Version line.
	// When VERSION exists it wins over the version() argument, so the .pkg files and stata.toc show the same release.
	global NW_VERSION ""
	capture file open __nwvf using "VERSION", read text
	if _rc == 0 {
		file read __nwvf __nwv1
		file read __nwvf __nwv2
		file close __nwvf
		global NW_VERSION "`__nwv1'"
		if "`__nwv2'" != "" local d "`__nwv2'"
	}
	if "$NW_VERSION" != "" local version "$NW_VERSION"
	// long date for the visible version line, e.g. 24 October 2026
	local longdate = string(date("`d'", "DMY"), "%tdDD_Month_CCYY")
	if substr("`longdate'", 1, 1) == "0" local longdate = substr("`longdate'", 2, .)
	if "`longdate'" == "" | "`longdate'" == "." local longdate "`d'"

	// nwcommands.sthlp is maintained by hand; nwtopical.sthlp and nwalphabetical.sthlp are written by tools/make_help_index.py
	tempname versionlog
	file open `versionlog' using versionlog.sh, replace write

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

	// the version line appended to every .ado (versionlog.sh)
	foreach file in `adofiles' {
		file write `versionlog' `"echo "*! v`version' __ `c(current_date)' __ `c(current_time)'" >> `file'"'  _n
	}

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
	file write deploy_boot "d nwcommands. Start here - installs nwinstall and the landing help topics; run nwinstall, everything next" _n
	file write deploy_boot "d Thomas U. Grund, RWTH Aachen University, www.grund.co.uk" _n
	file write deploy_boot "d email: thomas.u.grund@gmail.com" _n
	file write deploy_boot "d Distribution-Date: `d'" _n
	if "$NW_VERSION" != "" file write deploy_boot "d Version: $NW_VERSION" _n

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
	file write `toc' "d nwcommands: Network Analysis for Stata`=cond("$NW_VERSION" != "", " (version $NW_VERSION, `d')", "")'" _n
	file write `toc' _n "p nwcommands" _n "d nwcommands. Start here - net install this first, then run nwinstall, everything" _n
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
			file write `fh' "d Thomas U. Grund, RWTH Aachen University, www.grund.co.uk" _n
			file write `fh' "d email: `email'" _n
			file write `fh' "d Distribution-Date: `date'" _n
			if "$NW_VERSION" != "" file write `fh' "d Version: $NW_VERSION" _n
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

