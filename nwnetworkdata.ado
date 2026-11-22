*! Date        : 22nov2026
*! Version     : 1.2.0
*! Author      : Thomas Grund (nwcommands)
*! Purpose     : import the networks of David Schoch's R package networkdata (MIT licence) into nwcommands
*
* nwnetworkdata ships NO network data. It downloads the original .rda file of a data set from the GitHub repository
* schochastics/networkdata when it is asked for it, keeps it in a cache folder of the user, reads it on the user's computer with
* Stata alone (nwnetworkdata_rda.ado: no R needed) into csv tables, and builds the network with nwfromedge. Option withr converts with R
* and the R package igraph instead (nwnetworkdata_convert.R), which is also the fallback when the reader without R meets an object
* it does not handle (then a note says so; it never guesses). The only file that comes with this package besides code is
* nwnetworkdata_catalogue.csv: the names, type and size of the networks (metadata, to list and to check what is requested).
* Please cite: David Schoch (2022) networkdata: Repository of Network Datasets. https://doi.org/10.5281/zenodo.7189928
* and the original source of the data set (see help nwnetworkdata; every data set is documented on https://nwcommands.org/datasets/schoch/).
*
* Safety: the name of a data set is checked against the catalogue (and may only contain letters, digits, _ and .) before anything is
* downloaded or read; from() / nwnetworkdata source accept only the official repository (https) or an existing local folder. The reader
* without R starts no program and executes nothing: it checks every length against the data that are left, caps the sizes and the
* nesting depth, and verifies the checksum of the compressed file. For the conversion with R, every path that is handed to the shell is
* checked for characters that a shell or batch file would interpret; the R script is fixed text (it is not built from data) and only
* loads the .rda file into a fresh environment and reads it.

capture program drop nwnetworkdata
program nwnetworkdata, rclass
	version 14
	gettoken sub rest : 0, parse(" ,")
	local rest = strtrim(`"`rest'"')
	if inlist("`sub'", "list", "describe", "load", "edges", "nodes", "tables", "cache") {
		_nwnd_`sub' `rest'
		return add
	}
	else if "`sub'" == "source" {
		_nwnd_srcpub `rest'
		return add
	}
	else if "`sub'" == "" | substr("`sub'", 1, 1) == "," {
		di as err "subcommand or network name required; see {help nwnetworkdata}"
		exit 198
	}
	else {
		// nwnetworkdata karate [, options]  ==  nwnetworkdata load karate [, options]
		_nwnd_load `0'
		return add
	}
end

// ---------------------------------------------------------------------------------------------------------------
// input checks: nothing the user types reaches a download or a shell command before it has passed one of these
// ---------------------------------------------------------------------------------------------------------------
capture program drop _nwnd_checkname
program _nwnd_checkname
	// _nwnd_checkname value: a data set or network name (or part of one) consists of letters, digits, _ and . only
	gettoken v rest : 0
	local ok = (`"`v'"' != "") & (`"`rest'"' == "") & (strlen(`"`v'"') <= 80)
	if `ok' {
		mata: st_local("ok", strofreal(nwnd_nameok(st_local("v"))))
	}
	if !`ok' {
		di as err `"{p 0 0 2}invalid name: a networkdata name has at most 80 characters: letters, digits, {bf:_} and {bf:.} (see {bf:nwnetworkdata list}){p_end}"'
		exit 198
	}
end

capture program drop _nwnd_checkpath
program _nwnd_checkpath
	// _nwnd_checkpath what path: a path that may be handed to the shell must not contain characters that a shell or batch file interprets
	gettoken what 0 : 0
	gettoken p rest : 0
	local win = (c(os) == "Windows")
	mata: st_local("ok", strofreal(nwnd_pathok(st_local("p"), `win')))
	if `"`rest'"' != "" local ok 0
	if !`ok' {
		di as err `"{p 0 0 2}the `what' contains a character that is not allowed in a path that is passed to R (a double quote, back quote, dollar sign, %, ^, &, |, <, >, a line break, or on Unix a backslash). Use another folder.{p_end}"'
		exit 198
	}
end

capture program drop _nwnd_checksrc
program _nwnd_checksrc
	// _nwnd_checksrc source: only the official repository (https) or an existing local folder is accepted
	gettoken src rest : 0
	if `"`rest'"' != "" {
		di as err "{p 0 0 2}invalid source{p_end}"
		exit 198
	}
	local official "https://raw.githubusercontent.com/schochastics/networkdata/"
	local isurl = regexm(lower(`"`src'"'), "^[a-z][a-z0-9+.-]*://")
	if `isurl' {
		if substr(`"`src'"', 1, strlen("`official'")) != "`official'" | strpos(`"`src'"', "..") > 0 {
			di as err `"{p 0 0 2}from() / the source must be a local folder or an address in the official repository, {bf:`official'...}; other addresses are not accepted{p_end}"'
			exit 198
		}
		_nwnd_checkpath "source address" `"`src'"'
		if strpos(`"`src'"', " ") > 0 {
			di as err "{p 0 0 2}the source address must not contain blanks{p_end}"
			exit 198
		}
	}
	else {
		_nwnd_checkpath "source folder" `"`src'"'
		mata: st_local("ok", strofreal(direxists(st_local("src"))))
		if !`ok' {
			di as err `"{p 0 0 2}the local folder {bf:`src'} does not exist; check {bf:from()} or {bf:nwnetworkdata source}{p_end}"'
			exit 601
		}
	}
end

capture mata: mata drop nwnd_nameok()
capture mata: mata drop nwnd_pathok()
mata:
real scalar nwnd_nameok(string scalar s)
{
	real rowvector a
	a = ascii(s)
	return(cols(a) > 0 & all((a :>= 48 :& a :<= 57) :| (a :>= 65 :& a :<= 90) :| (a :>= 97 :& a :<= 122) :| a :== 95 :| a :== 46))
}

real scalar nwnd_pathok(string scalar s, real scalar win)
{
	real rowvector a, bad
	real scalar i
	a = ascii(s)
	if (cols(a) == 0) return(0)
	// " ` $ % ^ & | < > LF CR NUL (and the backslash, which is an escape character in a Unix shell)
	bad = (34, 96, 36, 37, 94, 38, 124, 60, 62, 10, 13, 0)
	if (!win) bad = (bad, 92)
	for (i = 1; i <= cols(bad); i++) {
		if (any(a :== bad[i])) return(0)
	}
	return(1)
}
end

// ---------------------------------------------------------------------------------------------------------------
// source, cache, R
// ---------------------------------------------------------------------------------------------------------------
capture program drop _nwnd_defaults
program _nwnd_defaults
	// the one place where the location of the original data is defined: the GitHub repository of Schoch's package
	c_local nwnd_default "https://raw.githubusercontent.com/schochastics/networkdata/main/data"
	local cache "`c(sysdir_plus)'nwnd"
	if `"$nwnd_cache"' != "" local cache `"$nwnd_cache"'
	c_local nwnd_cache `"`cache'"'
end

capture program drop _nwnd_source
program _nwnd_source
	// _nwnd_source [from]  ->  locals nwnd_src (URL or local folder with the .rda files, no trailing slash) and nwnd_cache
	args from
	_nwnd_defaults
	local src `"`from'"'
	if `"`src'"' == "" local src `"$nwnd_source"'
	if `"`src'"' == "" local src `"`nwnd_default'"'
	while inlist(substr(`"`src'"', -1, 1), "/", "\") {
		local src = substr(`"`src'"', 1, strlen(`"`src'"') - 1)
	}
	_nwnd_checksrc `"`src'"'
	_nwnd_checkpath "cache folder" `"`nwnd_cache'"'
	c_local nwnd_src `"`src'"'
	c_local nwnd_cache `"`nwnd_cache'"'
end

capture program drop _nwnd_srcpub
program _nwnd_srcpub, rclass
	// nwnetworkdata source [set url_or_folder | default]
	args a b
	_nwnd_defaults
	if "`a'" == "set" & `"`b'"' != "" {
		_nwnd_checksrc `"`b'"'
		global nwnd_source `"`b'"'
		di as txt `"(source set to {bf:`b'} for this session)"'
	}
	else if "`a'" == "default" | "`a'" == "set" {
		global nwnd_source ""
		di as txt `"(source reset to the default)"'
	}
	_nwnd_source
	di as txt `"source : {res:`nwnd_src'}"'
	di as txt `"cache  : {res:`nwnd_cache'}"'
	return local source `"`nwnd_src'"'
	return local cache `"`nwnd_cache'"'
end

capture program drop _nwnd_cache
program _nwnd_cache, rclass
	args what
	_nwnd_defaults
	if "`what'" == "clear" {
		local n 0
		foreach d in rda conv typed {
			local files : dir `"`nwnd_cache'/`d'"' files "*"
			foreach f of local files {
				capture quietly erase `"`nwnd_cache'/`d'/`f'"'
				local ++n
			}
		}
		di as txt `"(cache {bf:`nwnd_cache'} cleared; `n' files removed)"'
	}
	local files : dir `"`nwnd_cache'/rda"' files "*.rda"
	local n : word count `files'
	di as txt `"cache folder           : {res:`nwnd_cache'}"'
	di as txt "downloaded data sets : {res:`n'}"
	return local cache `"`nwnd_cache'"'
	return scalar rda = `n'
end

capture program drop _nwnd_rscript
program _nwnd_rscript
	// location of Rscript: global nwnd_rscript (must exist), else the newest R in the usual places on Windows, else the PATH
	// (Unix: the directories of the PATH of this Stata session, then the usual places, because a Stata started from the
	// desktop has a short PATH), else the bare name Rscript
	local rs `"$nwnd_rscript"'
	if `"`rs'"' != "" {
		capture confirm file `"`rs'"'
		if _rc {
			di as err `"{p 0 0 2}{bf:global nwnd_rscript} points to {bf:`rs'}, which does not exist{p_end}"'
			exit 601
		}
	}
	if `"`rs'"' == "" & c(os) == "Windows" {
		foreach base in "C:/Program Files/R" "C:/Program Files (x86)/R" {
			local dirs : dir `"`base'"' dirs "R-*"
			local dirs : list sort dirs
			foreach d of local dirs {
				capture confirm file `"`base'/`d'/bin/Rscript.exe"'
				if !_rc local rs `"`base'/`d'/bin/Rscript.exe"'
			}
			if `"`rs'"' != "" continue, break
		}
	}
	if `"`rs'"' == "" & c(os) != "Windows" {
		local pth : environment PATH
		local pth = subinstr(`"`pth'"', ":", " ", .)
		local cand
		foreach d of local pth {
			local cand `"`cand' `"`d'/Rscript"'"'
		}
		local cand `"`cand' "/usr/local/bin/Rscript" "/opt/homebrew/bin/Rscript" "/usr/bin/Rscript" "/Library/Frameworks/R.framework/Resources/bin/Rscript" "/usr/lib/R/bin/Rscript""'
		foreach f of local cand {
			capture confirm file `"`f'"'
			if !_rc {
				local rs `"`f'"'
				continue, break
			}
		}
	}
	if `"`rs'"' == "" local rs "Rscript"
	_nwnd_checkpath "Rscript location" `"`rs'"'
	c_local nwnd_rs `"`rs'"'
end

capture program drop _nwnd_prepare
program _nwnd_prepare
	// _nwnd_prepare obj, src() cache() [refresh withr]: download <obj>.rda, read it (without R: nwnetworkdata_rda; with R: withr, or when
	// the built-in reader meets something it does not handle); local nwnd_conv = folder with the csv files, nwnd_origin = how the data were obtained
	syntax anything(name=obj), SRC(string) CACHE(string) [REFresh WITHR]
	// whitelist (callers take obj from the catalogue; checked again here because it is part of file names and shell commands)
	_nwnd_checkname `obj'
	_nwnd_checksrc `"`src'"'
	_nwnd_checkpath "cache folder" `"`cache'"'
	local conv `"`cache'/conv"'
	// how the csv tables of this data set were made (kept in <obj>.how next to them): "without R" or "with R"
	local how ""
	capture confirm file `"`conv'/`obj'.how"'
	if !_rc {
		tempname fhh
		file open `fhh' using `"`conv'/`obj'.how"', read text
		file read `fhh' line
		file close `fhh'
		if inlist(`"`line'"', "without R", "with R") local how `"`line'"'
	}
	capture confirm file `"`conv'/`obj'_index.csv"'
	if !_rc & "`refresh'" == "" & "`withr'" == "" {
		c_local nwnd_conv `"`conv'"'
		// how the data were obtained, reported by the loader (no silent source): the download date is kept in <obj>.date next to the file
		if substr(`"`src'"', 1, 8) == "https://" {
			local odate "(download date not recorded)"
			capture confirm file `"`cache'/rda/`obj'.date"'
			if !_rc {
				tempname fh
				file open `fh' using `"`cache'/rda/`obj'.date"', read text
				file read `fh' line
				file close `fh'
				local odate "downloaded `line'"
			}
			c_local nwnd_origin `"from cache (`odate'`=cond("`how'" != "", "; read " + "`how'", "")')"'
		}
		else c_local nwnd_origin `"from the local folder `src'`=cond("`how'" != "", "; read " + "`how'", "")'"'
		exit
	}
	// 1. the original file
	if substr(`"`src'"', 1, 8) == "https://" {
		capture mkdir `"`c(sysdir_plus)'"'
		capture mkdir `"`cache'"'
		capture mkdir `"`cache'/rda"'
		local rda `"`cache'/rda/`obj'.rda"'
		capture confirm file `"`rda'"'
		if _rc | "`refresh'" != "" {
			capture copy `"`src'/`obj'.rda"' `"`rda'"', replace
			if _rc {
				local rc = _rc
				capture quietly erase `"`rda'"'
				di as err `"{p 0 0 2}could not download {bf:`src'/`obj'.rda} (r(`rc')).{p_end}"'
				di as err `"{p 0 0 2}Are you offline? Data sets that were loaded before are kept in {bf:`cache'} and work without a connection. Otherwise download {bf:`obj'.rda} from https://github.com/schochastics/networkdata/tree/main/data to a folder and use {bf:from(}{it:folder}{bf:)}.{p_end}"'
				exit 677
			}
			tempname fhd
			capture file open `fhd' using `"`cache'/rda/`obj'.date"', write text replace
			if !_rc {
				file write `fhd' `"`c(current_date)'"' _n
				file close `fhd'
			}
			local got `"downloaded now from `src'/`obj'.rda"'
		}
		else {
			local odate "(download date not recorded)"
			capture confirm file `"`cache'/rda/`obj'.date"'
			if !_rc {
				tempname fh
				file open `fh' using `"`cache'/rda/`obj'.date"', read text
				file read `fh' line
				file close `fh'
				local odate "downloaded `line'"
			}
			local got `"from cache (`odate')"'
		}
	}
	else {
		local got `"from the local folder `src'"'
		local rda `"`src'/`obj'.rda"'
		capture confirm file `"`rda'"'
		if _rc {
			di as err `"{p 0 0 2}file {bf:`obj'.rda} not found in {bf:`src'}; check {bf:from()} or {bf:nwnetworkdata source}{p_end}"'
			exit 601
		}
	}
	_nwnd_checkpath "data file" `"`rda'"'
	_nwnd_checkpath "output folder" `"`conv'"'
	capture mkdir `"`cache'"'
	capture mkdir `"`conv'"'
	capture quietly erase `"`conv'/`obj'_index.csv"'
	capture quietly erase `"`conv'/`obj'.how"'
	// 2. the conversion into csv tables: with Stata only (nwnetworkdata_rda), or with R and igraph
	if "`withr'" == "" {
		global NWND_MSG ""
		capture which nwnetworkdata_rda
		if _rc {
			local rc 9001
			global NWND_MSG "the file nwnetworkdata_rda.ado was not found; reinstall nwcommands"
		}
		else {
			capture nwnetworkdata_rda `"`rda'"' `"`conv'"'
			local rc = _rc
			if `rc' != 0 & !inlist(`rc', 9001, 9002) {
				global NWND_MSG "unexpected error r(`rc') in the reader"
				local rc 9001
			}
		}
		if `rc' == 0 {
			_nwnd_how `"`conv'/`obj'.how"' "without R"
			c_local nwnd_conv `"`conv'"'
			c_local nwnd_reconv 1
			c_local nwnd_origin `"`got'; read without R"'
			exit
		}
		if `rc' == 9002 {
			di as err `"{p 0 0 2}{bf:`obj'.rda} could not be read: $NWND_MSG. If the file in the cache is damaged, use {bf:refresh} to download it again.{p_end}"'
			exit 610
		}
		// 9001: a valid file with something that the reader without R does not handle: R is used, if there is one
		di as txt `"{p 0 0 2}(the reader without R cannot handle {bf:`obj'}: $NWND_MSG; trying R){p_end}"'
	}
	_nwnd_withr `obj', rda(`"`rda'"') conv(`"`conv'"') cache(`"`cache'"')
	_nwnd_how `"`conv'/`obj'.how"' "with R"
	c_local nwnd_conv `"`conv'"'
	c_local nwnd_reconv 1
	c_local nwnd_origin `"`got'; converted now with R"'
end

capture program drop _nwnd_how
program _nwnd_how
	args f text
	tempname fhw
	capture file open `fhw' using `"`f'"', write text replace
	if !_rc {
		file write `fhw' `"`text'"' _n
		file close `fhw'
	}
end

capture program drop _nwnd_withr
program _nwnd_withr
	// the conversion with R and the package igraph (nwnetworkdata_convert.R, run with Rscript on this computer)
	syntax anything(name=obj), RDA(string) CONV(string) CACHE(string)
	local rda `"`rda'"'
	local conv `"`conv'"'
	local script `"$nwnd_converter"'
	if `"`script'"' == "" {
		local script `"`cache'/_nwnd_convert.R"'
		_nwnd_locate nwnetworkdata_convert `"`script'"'
	}
	_nwnd_rscript
	tempfile rlog
	// every path that is handed to the shell (R, script, data file, output folder, log) has passed the character check
	_nwnd_checkpath "R script" `"`script'"'
	_nwnd_checkpath "data file" `"`rda'"'
	_nwnd_checkpath "output folder" `"`conv'"'
	_nwnd_checkpath "temporary file" `"`rlog'"'
	if c(os) == "Windows" {
		// a batch file avoids the quoting problems of cmd.exe with paths that contain blanks
		local bat `"`conv'/_nwnd_run.bat"'
		local rsw = subinstr(`"`nwnd_rs'"', "/", "\", .)
		local scw = subinstr(`"`script'"', "/", "\", .)
		local rdw = subinstr(`"`rda'"', "/", "\", .)
		local cvw = subinstr(`"`conv'"', "/", "\", .)
		local lgw = subinstr(`"`rlog'"', "/", "\", .)
		qui file open __nwnd_fh using `"`bat'"', write text replace
		file write __nwnd_fh `"@echo off"' _n
		file write __nwnd_fh `""`rsw'" "`scw'" "`rdw'" "`cvw'" > "`lgw'" 2>&1"' _n
		file close __nwnd_fh
		qui shell "`bat'"
		capture quietly erase `"`bat'"'
	}
	else {
		qui shell "`nwnd_rs'" "`script'" "`rda'" "`conv'" > "`rlog'" 2>&1
	}
	capture confirm file `"`conv'/`obj'_index.csv"'
	if _rc {
		di as err `"{p 0 0 2}the conversion of {bf:`obj'.rda} with R failed. R with the package igraph is needed for this (https://www.r-project.org). R used: {bf:`nwnd_rs'} (set another with {bf:global nwnd_rscript "path/to/Rscript"}).{p_end}"'
		capture {
			file open __nwnd_fh using `"`rlog'"', read text
			file read __nwnd_fh line
			local k 0
			while r(eof) == 0 & `k' < 8 {
				di as err `"   `line'"'
				file read __nwnd_fh line
				local ++k
			}
			file close __nwnd_fh
		}
		exit 601
	}
end

// ---------------------------------------------------------------------------------------------------------------
// readers
// ---------------------------------------------------------------------------------------------------------------
capture program drop _nwnd_locate
program _nwnd_locate
	// _nwnd_locate name outfile: the text payload of the installed file name.ado (between a line "/*" and a line "*/") is written
	// to outfile. (net install installs only files with Stata extensions; the converter script and the catalogue travel as .ado files.)
	args name outfile
	capture findfile `name'.ado
	if _rc {
		di as err "{p 0 0 2}`name'.ado was not found; reinstall the package ({bf:net install nwnetworkdata, replace}){p_end}"
		exit 601
	}
	local fn `"`r(fn)'"'
	// done in Mata: the payload contains $ and other characters that macro expansion would change
	mata: nwnd_extract(st_local("fn"), st_local("outfile"))
end

capture mata: mata drop nwnd_extract()
mata:
void nwnd_extract(string scalar fn, string scalar outfile)
{
	real scalar fh, fo, inside
	string scalar line

	fh = fopen(fn, "r")
	(void) _unlink(outfile)
	fo = fopen(outfile, "w")
	inside = 0
	while ((line = fget(fh)) != J(0, 0, "")) {
		if (line == "*/") inside = 0
		if (inside) fput(fo, line)
		if (line == "/*") inside = 1
	}
	fclose(fh)
	fclose(fo)
}
end

capture program drop _nwnd_csv
program _nwnd_csv
	// a csv with every column as text (types are restored from the attrs file where it matters)
	args path
	qui import delimited using `"`path'"', varnames(1) stringcols(_all) bindquote(strict) encoding("utf-8") case(preserve) clear
end

capture program drop _nwnd_catalogue
program _nwnd_catalogue
	// the catalogue of names and properties that comes with the package, in memory (callers preserve first)
	local f `"$nwnd_catalogue"'
	if `"`f'"' == "" {
		tempfile catf
		local f `"`catf'.csv"'
		_nwnd_locate nwnetworkdata_catalogue `"`f'"'
	}
	_nwnd_csv `"`f'"'
	foreach v in element nelem n m_igraph directed twomode n1 n2 weighted multi loops nloops npairs npairs_incl_loops nisolates nvattr neattr named temporal {
		qui destring `v', replace
	}
end

capture program drop _nwnd_typed
program _nwnd_typed
	// destring the numeric/logical attribute columns of the data in memory, as recorded in the attrs file
	syntax anything(name=obj), SCOPE(string) ATTRs(string)
	preserve
	_nwnd_csv `"`attrs'"'
	qui keep if obj == "`obj'" & scope == "`scope'" & rtype != "character"
	local nums
	forvalues i = 1/`=_N' {
		local nums `nums' `=stata[`i']'
	}
	restore
	foreach v of local nums {
		capture confirm variable `v'
		if !_rc {
			// into a double: destring would store e.g. 1105.95 in a float and lose precision
			qui gen double __nwnd_t = real(`v')
			qui drop `v'
			qui rename __nwnd_t `v'
		}
	}
end

capture program drop _nwnd_unknown
program _nwnd_unknown
	syntax anything(name=name)
	preserve
	_nwnd_catalogue
	local low = lower("`name'")
	qui keep if strpos(lower(obj), "`low'") > 0
	if _N > 0 {
		qui levelsof obj, local(cand) clean
		di as err "{p 0 0 2}{bf:`name'} is not a networkdata data set or network name. Did you mean: `cand'?{p_end}"
	}
	else di as err "{p 0 0 2}{bf:`name'} is not a networkdata data set or network name; see {bf:nwnetworkdata list}.{p_end}"
	restore
end

// ---------------------------------------------------------------------------------------------------------------
// list
// ---------------------------------------------------------------------------------------------------------------
capture program drop _nwnd_list
program _nwnd_list, rclass
	syntax [anything(name=pattern)] [, NETworks CLEar DIRected UNDIRected TWOmode ONEmode ///
		WEIGHTed MULTiple LOOPs TEMPoral Kind(string)]
	if `"`pattern'"' != "" _nwnd_checkname `pattern'
	preserve
	_nwnd_catalogue
	qui drop if kind == "egor"
	if "`directed'" != "" qui keep if directed == 1 & twomode == 0
	if "`undirected'" != "" qui keep if directed == 0 & twomode == 0
	if "`twomode'" != "" qui keep if twomode == 1
	if "`onemode'" != "" qui keep if twomode == 0
	if "`weighted'" != "" qui keep if weighted == 1
	if "`multiple'" != "" qui keep if multi == 1
	if "`loops'" != "" qui keep if loops == 1
	if "`temporal'" != "" qui keep if temporal == 1
	if `"`kind'"' != "" qui keep if kind == `"`kind'"'
	if `"`pattern'"' != "" {
		local pattern = lower(`"`pattern'"')
		qui keep if strpos(lower(obj), `"`pattern'"') > 0 | strpos(lower(net), `"`pattern'"') > 0
	}
	qui count
	local nnet = r(N)
	qui levelsof obj, local(objs)
	local nobj : word count `objs'
	qui gen str12 type = cond(twomode == 1, "two-mode", cond(directed == 1, "directed", "undirected"))
	qui gen str3 valued = cond(weighted == 1, "yes", "")
	if "`networks'" == "" & _N > 0 {
		// one row per data set; a list of networks shows its number of networks and its range of sizes
		qui bysort obj: egen int nnets = count(n)
		qui bysort obj: egen long nmin = min(n)
		qui bysort obj: egen long nmax = max(n)
		qui bysort obj: keep if _n == 1
		qui gen str21 nodes = cond(nmin == nmax, string(nmin), string(nmin) + "-" + string(nmax))
		sort obj
		format obj %-26s
		list obj nnets nodes type valued, noobs sep(0)
	}
	else if _N > 0 {
		format net %-28s
		list net n m_igraph type valued multi loops nvattr neattr, noobs sep(0)
	}
	di as txt "`nobj' data set(s), `nnet' network(s)"
	return scalar n_objects = `nobj'
	return scalar n_networks = `nnet'
	if "`clear'" != "" {
		keep obj net
		restore, not
	}
	else restore
end

// ---------------------------------------------------------------------------------------------------------------
// describe (properties from the catalogue; documentation and references: https://nwcommands.org/datasets/schoch/)
// ---------------------------------------------------------------------------------------------------------------
capture program drop _nwnd_describe
program _nwnd_describe, rclass
	syntax anything(name=name)
	_nwnd_checkname `name'
	preserve
	_nwnd_catalogue
	qui keep if obj == "`name'"
	if _N == 0 {
		restore
		_nwnd_unknown `name'
		exit 111
	}
	local kind = kind[1]
	local nelem = nelem[1]
	di
	di as txt "{bf:`name'}  {hline 2}  data set of the R package networkdata"
	di as txt "{hline 72}"
	if "`kind'" == "egor" {
		di as txt "{p 2 4 2}An {it:egor} object (ego-centered network study: tables ego, alter, aatie), not a network. Use {bf:nwnetworkdata tables `name', table(ego)}.{p_end}"
	}
	else {
		local nshow = min(_N, 12)
		forvalues i = 1/`nshow' {
			local line = net[`i'] + ": " + string(n[`i']) + " nodes, " + string(m_igraph[`i']) + " edges" ///
				+ cond(twomode[`i'], ", two-mode", cond(directed[`i'], ", directed", ", undirected")) ///
				+ cond(weighted[`i'], ", valued", "") + cond(multi[`i'], ", multiple edges", "") ///
				+ cond(loops[`i'], ", loops", "") + cond(temporal[`i'], ", edge times", "")
			di as txt "{p 2 4 2}`line'{p_end}"
			local va = vattrs[`i']
			local ea = eattrs[`i']
			if "`va'" == "" local va "none"
			if "`ea'" == "" local ea "none"
			di as txt "{p 6 8 2}node attributes: `va'; edge attributes: `ea'{p_end}"
		}
		if _N > `nshow' di as txt "{p 2 4 2}... and `=_N - `nshow'' more networks ({bf:nwnetworkdata list `name', networks}){p_end}"
	}
	di as txt `"{p 2 4 2}Description, source and references of the data set: {browse "https://nwcommands.org/datasets/schoch/#`name'":nwcommands.org/datasets/schoch}. Original: https://github.com/schochastics/networkdata{p_end}"'"
	return local obj "`name'"
	return scalar nelem = `nelem'
	restore
end

// ---------------------------------------------------------------------------------------------------------------
// edges / nodes / tables: the plain tables
// ---------------------------------------------------------------------------------------------------------------
capture program drop _nwnd_edges
program _nwnd_edges, rclass
	syntax anything(name=name) [, from(string) Element(integer 0) REFresh WITHR clear]
	_nwnd_table `name', what(edges) from(`"`from'"') element(`element') `refresh' `withr' `clear'
	return add
end

capture program drop _nwnd_nodes
program _nwnd_nodes, rclass
	syntax anything(name=name) [, from(string) Element(integer 0) REFresh WITHR clear]
	_nwnd_table `name', what(nodes) from(`"`from'"') element(`element') `refresh' `withr' `clear'
	return add
end

capture program drop _nwnd_table
program _nwnd_table, rclass
	syntax anything(name=name), WHAT(string) [from(string) Element(integer 0) REFresh WITHR clear]
	_nwnd_checkname `name'
	if _N > 0 & c(changed) & "`clear'" == "" error 4
	preserve
	_nwnd_catalogue
	qui keep if net == "`name'" | obj == "`name'"
	if _N == 0 {
		restore
		_nwnd_unknown `name'
		exit 111
	}
	local obj = obj[1]
	qui count if net == "`name'"
	if r(N) == 1 qui keep if net == "`name'"
	local el = element[1]
	if `element' == 0 & `el' > 0 & "`obj'" != "`name'" local element = `el'
	restore
	_nwnd_source `"`from'"'
	_nwnd_prepare `obj', src(`"`nwnd_src'"') cache(`"`nwnd_cache'"') `refresh' `withr'
	local conv `"`nwnd_conv'"'
	_nwnd_csv `"`conv'/`obj'_`what'.csv"'
	qui destring nd_elem, replace
	if `element' > 0 qui keep if nd_elem == `element'
	if "`what'" == "edges" {
		qui destring nd_from nd_to, replace
		_nwnd_typed `obj', scope(edge) attrs(`"`conv'/`obj'_attrs.csv"')
	}
	else {
		qui destring nd_id nd_order nd_mode, replace
		_nwnd_typed `obj', scope(node) attrs(`"`conv'/`obj'_attrs.csv"')
	}
	di as txt "(`=_N' rows of the `what' of {bf:`obj'}" cond(`element' > 0, ", element `element'", "") ")"
	return scalar N = _N
	return local obj "`obj'"
end

capture program drop _nwnd_tables
program _nwnd_tables, rclass
	syntax anything(name=name) [, from(string) TABle(string) REFresh WITHR clear]
	if _N > 0 & c(changed) & "`clear'" == "" error 4
	if "`table'" == "" local table "ego"
	if !inlist("`table'", "ego", "alter", "aatie") {
		di as err "table() must be ego, alter or aatie"
		exit 198
	}
	_nwnd_checkname `name'
	preserve
	_nwnd_catalogue
	qui keep if obj == "`name'" & kind == "egor"
	local found = _N
	restore
	if !`found' {
		di as err "{p 0 0 2}{bf:`name'} is not an egor object of networkdata (the only egor object is {bf:gss_egor}){p_end}"
		exit 459
	}
	_nwnd_source `"`from'"'
	_nwnd_prepare `name', src(`"`nwnd_src'"') cache(`"`nwnd_cache'"') `refresh' `withr'
	capture confirm file `"`nwnd_conv'/`name'_`table'.csv"'
	if _rc {
		di as err "{p 0 0 2}{bf:`name'} is not an egor object{p_end}"
		exit 459
	}
	qui import delimited using `"`nwnd_conv'/`name'_`table'.csv"', varnames(1) bindquote(strict) encoding("utf-8") case(preserve) clear
	di as txt "(table {bf:`table'} of {bf:`name'}: `=_N' rows)"
	return scalar N = _N
end

// ---------------------------------------------------------------------------------------------------------------
// load
// ---------------------------------------------------------------------------------------------------------------
capture program drop _nwnd_load
program _nwnd_load, rclass
	syntax anything(name=request) [, from(string) NWClear clear REPlace NAme(string) Element(numlist integer >0) ///
		VALUEattr(string) BINary REFresh WITHR NOattrs]
	if _N > 0 & c(changed) & "`clear'" == "" & "`nwclear'" == "" {
		di as err "{p 0 0 2}no; data in memory would be lost (specify {bf:clear} or {bf:nwclear}){p_end}"
		exit 4
	}
	if `: word count `request'' != 1 {
		di as err "one network or data set name expected"
		exit 198
	}
	_nwnd_checkname `request'
	if "`name'" != "" mata: nw_assert_netname("`name'")

	// ---- resolve the request in the catalogue ----
	preserve
	_nwnd_catalogue
	qui keep if net == "`request'" | obj == "`request'"
	if _N == 0 {
		restore
		_nwnd_unknown `request'
		exit 111
	}
	if kind[1] == "egor" {
		restore
		di as err "{p 0 0 2}{bf:`request'} is an egor object (ego-centered data: tables ego, alter, aatie) and cannot be loaded as a network. Use {bf:nwnetworkdata tables `request', table(ego)}.{p_end}"
		exit 459
	}
	// an exact network name wins (animal_1_3 is the 3rd network of the data set animal_1)
	qui count if net == "`request'"
	if r(N) == 1 qui keep if net == "`request'"
	if "`element'" != "" {
		qui gen byte __keep = 0
		foreach e of local element {
			qui replace __keep = 1 if element == `e'
		}
		qui keep if __keep
		if _N == 0 {
			restore
			di as err "{p 0 0 2}element(`element') matches no network of {bf:`request'}{p_end}"
			exit 111
		}
		drop __keep
	}
	local obj = obj[1]
	local nets
	forvalues i = 1/`=_N' {
		local nets `nets' `=net[`i']'
	}
	local nnets : word count `nets'
	restore

	// ---- download and convert (once per data set) ----
	_nwnd_source `"`from'"'
	local src `"`nwnd_src'"'
	local cache `"`nwnd_cache'"'
	_nwnd_prepare `obj', src(`"`src'"') cache(`"`cache'"') `refresh' `withr'
	local conv `"`nwnd_conv'"'
	local nwnd_origin_msg `"`nwnd_origin'"'
	tempfile idx
	preserve
	_nwnd_csv `"`conv'/`obj'_index.csv"'
	foreach v in element n directed twomode weighted multi loops named {
		qui destring `v', replace
	}
	qui save `"`idx'"'
	restore

	// edge and node tables, typed, as .dta files kept in the cache (parsing a large csv once per network of a list would be slow)
	capture mkdir `"`cache'/typed"'
	local edf `"`cache'/typed/`obj'_edges.dta"'
	local ndf `"`cache'/typed/`obj'_nodes.dta"'
	capture confirm file `"`edf'"'
	local need = _rc | ("`refresh'" != "") | ("`withr'" != "") | ("`nwnd_reconv'" != "") | !fileexists(`"`ndf'"')
	if `need' {
		preserve
		_nwnd_csv `"`conv'/`obj'_edges.csv"'
		qui destring nd_elem nd_from nd_to, replace
		_nwnd_typed `obj', scope(edge) attrs(`"`conv'/`obj'_attrs.csv"')
		qui save `"`edf'"', replace
		_nwnd_csv `"`conv'/`obj'_nodes.csv"'
		qui destring nd_elem nd_id nd_order nd_mode, replace
		_nwnd_typed `obj', scope(node) attrs(`"`conv'/`obj'_attrs.csv"')
		qui save `"`ndf'"', replace
		restore
	}

	if "`nwclear'" != "" nwclear
	capture drop _running
	local loaded 0
	local lastnet ""
	local loadednets ""
	foreach net of local nets {
		preserve
		qui use `"`idx'"', clear
		qui keep if net == "`net'"
		if _N != 1 {
			restore
			di as err "{p 0 0 2}network {bf:`net'} is not in the converted data of {bf:`obj'} (the catalogue and the downloaded data set differ){p_end}"
			exit 459
		}
		foreach v in element n directed twomode weighted multi loops named {
			local x_`v' = `v'[1]
		}
		local x_vattrs = subinstr(vattrs[1], ";", " ", .)
		restore
		local target `net'
		if "`name'" != "" {
			if `nnets' == 1 local target `name'
			else local target `name'_`=cond(`x_element' > 0, `x_element', 1)'
		}
		_nwnd_build, edges(`"`edf'"') nodes(`"`ndf'"') net(`net') elem(`=cond(`x_element' > 0, `x_element', 1)') ///
			n(`x_n') directed(`x_directed') twomode(`x_twomode') weighted(`x_weighted') multi(`x_multi') ///
			loops(`x_loops') vattrs(`"`x_vattrs'"') named(`x_named') target(`target') `replace' ///
			valueattr(`"`valueattr'"') `binary' `noattrs'
		local ++loaded
		local lastnet `"`r(net)'"'
		local loadednets `loadednets' `lastnet'
		// one line per loaded network (more than 5 networks: one line for the list, below): what was loaded, from where
		if `nnets' <= 5 {
			_nwsyntax `lastnet'
			// ties: a directed network stores each tie once, an undirected or two-mode network in both directions (a loop once)
			mata: __nwnd_el = `netobj'->edgelist(); st_local("__nm", strofreal(`=cond("`directed'" == "true", "rows(__nwnd_el)", "(rows(__nwnd_el) + sum(__nwnd_el[., 1] :== __nwnd_el[., 2])) / 2")'))
			mata: mata drop __nwnd_el
			di as txt "Loaded from Schoch's networkdata collection: {res:`lastnet'} (`nodes' nodes, `__nm' ties, " ///
				"`=cond("`directed'" == "true", "directed", "undirected")', `=cond("`is2mode'" == "true", "two-mode", "one-mode")', " ///
				"`=cond("`valued'" == "true", "valued", "binary")'); source and citation: {stata nwnetworkdata describe `obj':nwnetworkdata describe `obj'}; " ///
				"collection: Schoch (2022), doi:10.5281/zenodo.7189928"
		}
	}
	if `nnets' > 5 {
		di as txt "Loaded from Schoch's networkdata collection: `loaded' networks `=word("`loadednets'", 1)' ... `=word("`loadednets'", `loaded')' of the data set {res:`obj'}; " ///
			"source and citation: {stata nwnetworkdata describe `obj':nwnetworkdata describe `obj'}; collection: Schoch (2022), doi:10.5281/zenodo.7189928"
	}
	di as txt "(data read `nwnd_origin_msg'; the data are not part of nwcommands: please cite the collection and the original source of the data set)"
	di as txt "(`loaded' network(s) loaded from {bf:`obj'}; current network: {bf:`lastnet'})"
	return scalar n_loaded = `loaded'
	return local net "`lastnet'"
	return local nets "`loadednets'"
	return local obj "`obj'"
end

capture program drop _nwnd_build
program _nwnd_build, rclass
	syntax , EDGES(string) NODES(string) NET(string) ELEM(integer) N(integer) DIRected(integer) TWOmode(integer) ///
		WEIGHTed(integer) MULTi(integer) LOOPs(integer) TARGET(string) [VATTRs(string) NAMEd(integer 1) REPlace ///
		VALUEattr(string) BINary NOattrs]
	unw_defs
	// ---- labels and modes of the nodes (kept in Mata across the dataset changes below) ----
	preserve
	qui use `"`nodes'"', clear
	qui keep if nd_elem == `elem'
	qui sort nd_order
	capture mata: mata drop __nwnd_lab
	mata: __nwnd_lab = st_sdata(., "nd_label")'
	capture mata: mata drop __nwnd_mode
	mata: __nwnd_mode = st_data(., "nd_mode")'
	local nn = _N
	restore
	// ---- tie list ----
	qui use `"`edges'"', clear
	qui keep if nd_elem == `elem'
	local mm = _N
	local valued = `weighted'
	local valuevar ""
	if "`valueattr'" != "" {
		capture confirm numeric variable `valueattr'
		if _rc {
			di as err "{p 0 0 2}valueattr(`valueattr'): no numeric edge attribute of that name in {bf:`net'}{p_end}"
			exit 111
		}
		local valuevar `valueattr'
		local valued 1
	}
	else if `weighted' local valuevar weight
	if "`binary'" != "" local valued 0
	qui gen double __v = 1
	if `mm' > 0 & "`valuevar'" != "" & "`binary'" == "" qui replace __v = `valuevar'
	qui gen long __a = nd_from
	qui gen long __b = nd_to
	if !`directed' & !`twomode' {
		qui replace __a = min(nd_from, nd_to)
		qui replace __b = max(nd_from, nd_to)
	}
	qui keep __a __b __v
	if `mm' > 0 {
		if "`binary'" != "" {
			qui collapse (max) __v, by(__a __b)
		}
		else {
			// parallel edges are summed (weights) or counted (unweighted: the tie value is their number)
			// summed in the order of the rows of the table, so that the result does not depend on how Stata sorts equal keys
			qui gen long __o = _n
			qui sort __a __b __o
			qui by __a __b: replace __v = sum(__v)
			qui by __a __b: keep if _n == _N
			qui drop __o
			qui count if __v > 1 & !`valued'
			if r(N) > 0 local valued 1
		}
	}
	// one row per node, so that isolates (and the nodes of a network without ties) exist
	local m0 = _N
	qui set obs `=`m0' + `nn''
	qui replace __a = _n - `m0' if _n > `m0'
	qui replace __b = . if _n > `m0'
	qui replace __v = . if _n > `m0'
	local dirflag = cond(`directed' & !`twomode', "forcedirected", "undirected")
	local loopflag = cond(`loops', "selfloop", "")
	local valflag = cond(`valued', "valued", "unvalued")
	nwfromedge __a __b __v, name(`target') `replace' `dirflag' `loopflag' `valflag'
	// the real node labels (nwfromedge names the nodes n1, n2, ...)
	_nwsyntax `target', other(other)
	mata: `othernetobj'->set_nodenames(__nwnd_lab)
	if `twomode' {
		mata: `othernetobj'->set_2mode(1)
		mata: `othernetobj'->set_modes(strofreal(__nwnd_mode))
		mata: `othernetobj'->clean_matrix_2mode()
	}
	qui nwload `target', labelonly overwrite
	mata: mata drop __nwnd_lab
	mata: mata drop __nwnd_mode
	// ---- node attributes into the dataset (same order as the nodes) ----
	if "`noattrs'" == "" {
		tempfile attf
		preserve
		qui use `"`nodes'"', clear
		qui keep if nd_elem == `elem'
		qui sort nd_order
		local keepv nd_label
		if `named' local keepv `keepv' nd_name
		foreach v of local vattrs {
			capture confirm variable `v'
			if !_rc local keepv `keepv' `v'
		}
		qui keep `keepv'
		qui gen long __nwnd_row = _n
		qui save `"`attf'"'
		restore
		qui gen long __nwnd_row = _n if _n <= `nn'
		qui merge 1:1 __nwnd_row using `"`attf'"', nogen keep(master match)
		capture assert `nw_nodename' == nd_label if _n <= `nn'
		if _rc {
			di as err "{p 0 0 2}internal error: node labels of the network and of the attribute table differ for {bf:`net'}{p_end}"
			exit 9
		}
		qui drop nd_label __nwnd_row
		order `nw_nodename'
	}
	return local net "`target'"
	return scalar nodes = `nn'
end



