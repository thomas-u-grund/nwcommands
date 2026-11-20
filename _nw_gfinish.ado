*! _nw_gfinish 1.0.0  20nov2026  shared graph helper of the nw plot commands: check, title, blk, save, version (api 1)
* Copyright (C) 2026 Thomas U. Grund; part of nwcommands, free software under the GNU General Public License, version 3 (file LICENSE).
*
* One program, dispatched on the first word (verbs):
*   _nw_gfinish version                      r(api) = 1 (raised only when the interface changes)
*   _nw_gfinish check [, PLOT(..) NAME(..) SAVing(..) EXPort(..) GOPTS(..) DEFault(..) ALWAYS CMD(..)]
*                                            validation and normalisation, called first (before any computation)
*   _nw_gfinish title "text" [, GOPTS(..) SIZE(..) SUBtitle XTITLE YTITLE]
*                                            r(t) = title("text", size(..) color(black)) unless the user gave title(..)
*   _nw_gfinish blk "text" [, KIND(..) SIZE(..) GOPTS(..)]
*                                            the same for any title option kind (title, subtitle, xtitle, ytitle, ...)
*   _nw_gfinish save, NAME(..) [SAVing(..) EXPort(..) GRAPHS(..) ALWAYS]
*                                            graph save / graph export of the drawn graph(s)
* The text of the error for options without plot is the same in every nw package.
capture program drop _nw_gfinish
program define _nw_gfinish, rclass
	version 14
	gettoken verb 0 : 0, parse(" ,")
	local verb = lower(`"`verb'"')

	if `"`verb'"' == "version" {
		return scalar api = 1
		exit
	}

	// ---------------------------------------------------------------- check
	if `"`verb'"' == "check" {
		syntax [, PLOT(string) NAME(string asis) SAVing(string asis) EXPort(string asis) GOPTS(string asis) ///
			DEFault(string) ALWAYS CMD(string) NAMEOK SVVER(real -1)]
		if strpos(`"`gopts'"', char(96) + char(34)) == 1 gettoken gopts : gopts
		local pfx ""
		if `"`cmd'"' != "" local pfx `"`cmd': "'
		// nameok: name() without plot stays accepted (commands in which it existed before the convention)
		local anyopt = (`"`saving'`export'`gopts'"' != "")
		if "`nameok'" == "" & `"`name'"' != "" local anyopt 1
		if "`plot'" == "" & "`always'" == "" & `anyopt' {
			di as err `"{p 0 0 2}`pfx'name(), saving(), export() and graph options need {bf:plot}.{p_end}"'
			exit 198
		}
		// name(): a trailing ", replace" is accepted and ignored (replace is always applied)
		gettoken nm0 nmrest : name, parse(",")
		local nm0 = trim(`"`nm0'"')
		local nmrest = trim(substr(`"`nmrest'"', 2, .))
		if `"`nmrest'"' != "" & `"`nmrest'"' != "replace" {
			di as err `"{p 0 0 2}`pfx'name(): only {bf:replace} is allowed after the comma.{p_end}"'
			exit 198
		}
		if `"`nm0'"' == "" local nm0 `"`default'"'
		if `"`nm0'"' != "" & ("`plot'" != "" | "`always'" != "" | "`nameok'" == "") {
			capture confirm name `nm0'
			if _rc | wordcount(`"`nm0'"') != 1 | length(`"`nm0'"') > 32 {
				di as err `"{p 0 0 2}`pfx'name(): {bf:`nm0'} is not a valid graph name.{p_end}"'
				exit 198
			}
		}
		// saving(): a trailing ", replace" is accepted and ignored
		gettoken sv0 svrest : saving, parse(",")
		local sv0 = trim(`"`sv0'"')
		forvalues __i = 1/3 {
			if inlist(substr(`"`sv0'"', 1, 1), char(34), char(96)) gettoken sv0 : sv0
		}
		local svrest = trim(substr(`"`svrest'"', 2, .))
		if `"`svrest'"' != "" & `"`svrest'"' != "replace" {
			di as err `"{p 0 0 2}`pfx'saving(): only {bf:replace} is allowed after the comma.{p_end}"'
			exit 198
		}
		_nw_gfinish_unquote `"`export'"'
		local export `"`r(s)'"'
		if "`plot'" != "" | "`always'" != "" {
			if `"`sv0'"' != "" _nw_gfinish_file `"`sv0'"', pfx(`"`pfx'"') what(saving) svver(`svver')
			gettoken ex0 : export, parse(",")
			forvalues __i = 1/3 {
			if inlist(substr(`"`ex0'"', 1, 1), char(34), char(96)) gettoken ex0 : ex0
		}
			if `"`ex0'"' != "" {
				_nw_gfinish_file `"`ex0'"', pfx(`"`pfx'"') what(export) svver(`svver')
			}
		}
		local hastitle = regexm(lower(`"`gopts'"'), "(^|[ ,])title[ ]*\(")
		return local name `"`nm0'"'
		return local nameopt `"name(`nm0', replace)"'
		return local saving `"`sv0'"'
		return local export `"`export'"'
		return local gopts `"`gopts'"'
		return scalar hastitle = `hastitle'
		return scalar draw = ("`plot'" != "" | "`always'" != "")
		exit
	}

	// ---------------------------------------------------------- title / blk
	if inlist(`"`verb'"', "title", "blk") {
		syntax [anything(name=txt)] [, GOPTS(string asis) SIZE(string) SUBtitle XTITLE YTITLE KIND(string) NOBLACK]
		if strpos(`"`gopts'"', char(96) + char(34)) == 1 gettoken gopts : gopts
		local k "title"
		if `"`kind'"' != "" local k = lower(`"`kind'"')
		if "`subtitle'" != "" local k "subtitle"
		if "`xtitle'" != "" local k "xtitle"
		if "`ytitle'" != "" local k "ytitle"
		gettoken t1 : txt
		if `"`t1'"' == "" {
			return local t ""
			exit
		}
		// the user's own option of this kind wins (title("") suppresses the default: nothing is returned)
		if regexm(lower(`"`gopts'"'), "(^|[ ,])`k'[ ]*\(") {
			return local t ""
			exit
		}
		local q = char(34)
		local out `"`k'(`q'`t1'`q'"'
		// noblack: the plain title as the command always drew it (released plots keep their look)
		if "`noblack'" == "" & `"`size'"' == "" & "`k'" == "title" & `"`verb'"' == "title" local size "medium"
		if `"`size'"' != "" local out `"`out', size(`size')"'
		if "`noblack'" != "" local out `"`out')"'
		else if `"`size'"' != "" local out `"`out' color(black))"'
		else local out `"`out', color(black))"'
		return local t `"`out'"'
		exit
	}

	// ----------------------------------------------------------------- save
	if `"`verb'"' == "save" {
		syntax [, NAME(string) SAVing(string asis) EXPort(string asis) GRAPHS(string) ALWAYS SVVER(real -1)]
		local glist `"`graphs'"'
		if `"`glist'"' == "" local glist `"`name'"'
		// "name, replace" is accepted
		if `"`graphs'"' == "" {
			gettoken glist : glist, parse(",")
			local glist = trim(`"`glist'"')
		}
		if `"`glist'"' == "" {
			di as err "_nw_gfinish save: name() or graphs() is required"
			exit 198
		}
		gettoken sv0 : saving, parse(",")
		local sv0 = trim(`"`sv0'"')
		forvalues __i = 1/3 {
			if inlist(substr(`"`sv0'"', 1, 1), char(34), char(96)) gettoken sv0 : sv0
		}
		_nw_gfinish_unquote `"`export'"'
		local export `"`r(s)'"'
		gettoken ex0 exrest : export, parse(",")
		local ex0 = trim(`"`ex0'"')
		forvalues __i = 1/3 {
			if inlist(substr(`"`ex0'"', 1, 1), char(34), char(96)) gettoken ex0 : ex0
		}
		local exrest = trim(substr(`"`exrest'"', 2, .))
		if `"`sv0'"' != "" _nw_gfinish_file `"`sv0'"', what(saving) svver(`svver')
		if `"`ex0'"' != "" _nw_gfinish_file `"`ex0'"', what(export) svver(`svver')
		local ng : word count `glist'
		local sfx_on = (`ng' > 1 | "`always'" != "")
		local saved ""
		local exported ""
		foreach g of local glist {
			local sfx ""
			if `sfx_on' local sfx "_`g'"
			if `"`sv0'"' != "" {
				_nw_gfinish_fnsuffix `"`sv0'"', suffix(`"`sfx'"') ext(.gph)
				local f `"`r(file)'"'
				quietly graph save `g' `"`f'"', replace
				local saved `"`saved' `"`f'"'"'
			}
			if `"`ex0'"' != "" {
				_nw_gfinish_fnsuffix `"`ex0'"', suffix(`"`sfx'"')
				local f `"`r(file)'"'
				// graph export needs the graph to be the current one in headless batch runs (r(693) "could not find Graph window"
				// for an older graph); graph display makes it current and leaves a machine with a display unchanged
				capture quietly graph display `g'
				quietly graph export `"`f'"', name(`g') replace `exrest'
				local exported `"`exported' `"`f'"'"'
			}
		}
		return local saved `"`=trim(`"`saved'"')'"'
		return local exported `"`=trim(`"`exported'"')'"'
		exit
	}

	di as err `"_nw_gfinish: unknown verb {bf:`verb'}"'
	exit 198
end

// callers may hand over the export string wrapped in one more compound-quote layer (export(`"`__ex'"') with __ex = "f.png", width(900)):
// strip such outer `" "' layers so that file name and graph export options parse the same as in the literal form
capture program drop _nw_gfinish_unquote
program define _nw_gfinish_unquote, rclass
	args s
	local s = trim(`"`s'"')
	local n = 0
	while substr(`"`s'"', 1, 2) == (char(96) + char(34)) & substr(`"`s'"', -2, 2) == (char(34) + char(39)) & `n' < 5 {
		local s = substr(`"`s'"', 3, length(`"`s'"') - 4)
		local s = trim(`"`s'"')
		local ++n
	}
	return local s `"`s'"'
end

// the file name with a suffix put before the extension; ext() is added when the name has no extension
capture program drop _nw_gfinish_fnsuffix
program define _nw_gfinish_fnsuffix, rclass
	syntax anything(name=fn) [, SUFfix(string) EXT(string)]
	local fn = trim(`"`fn'"')
	gettoken fn : fn
	if substr(`"`fn'"', 1, 1) == char(34) gettoken fn : fn
	local dot = strrpos(`"`fn'"', ".")
	local slash = max(strrpos(`"`fn'"', "/"), strrpos(`"`fn'"', "\"))
	if `dot' > `slash' & `dot' > 0 {
		return local file `"`=substr(`"`fn'"', 1, `dot' - 1)'`suffix'`=substr(`"`fn'"', `dot', .)'"'
	}
	else return local file `"`fn'`suffix'`ext'"'
end

// the file can be written: SVG needs Stata 16, the directory must exist (a message instead of a raw Stata error)
capture program drop _nw_gfinish_file
program define _nw_gfinish_file
	syntax anything(name=fn) [, PFX(string) WHAT(string) SVVER(real -1)]
	local fn = trim(`"`fn'"')
	gettoken fn : fn
	if substr(`"`fn'"', 1, 1) == char(34) gettoken fn : fn
	local sv = cond(`svver' > 0, `svver', c(stata_version))
	if "`what'" == "export" & substr(lower(`"`fn'"'), -4, .) == ".svg" & `sv' < 16 {
		di as err `"{p 0 0 2}`pfx'SVG export requires Stata 16 or later (this is Stata `sv'). Export to a different format (png/pdf/eps/...), or upgrade Stata.{p_end}"'
		exit 198
	}
	local slash = max(strrpos(`"`fn'"', "/"), strrpos(`"`fn'"', "\"))
	if `slash' > 0 {
		local dir = substr(`"`fn'"', 1, `slash')
		local ok = 0
		mata: st_local("ok", strofreal(direxists(st_local("dir"))))
		if `ok' != 1 {
			di as err `"{p 0 0 2}`pfx'`what'(): the directory {bf:`dir'} of the file does not exist.{p_end}"'
			exit 603
		}
	}
end

