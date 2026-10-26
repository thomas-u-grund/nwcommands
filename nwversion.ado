*! version 3.7.0  26oct2026  nwversion: version of the nwcommands core and of the installed model packages
capture program drop nwversion
program define nwversion, rclass
	version 14
	local nwv "3.7.0"
	local nwd "26oct2026"
	di as text _n "nwcommands " as res "`nwv'" as text " (`nwd'), core package; Stata " as res c(stata_version) as text ", " as res c(os)
	if c(stata_version) < 17 {
		di as text "nwcommands is tested with Stata 17 and 18; your Stata is version " c(stata_version)
	}
	di as text "Model packages (separate, GPL-3; install with {stata nwinstall, models}):"
	foreach p in nwsaom nwergm nwdynam nwrem {
		capture findfile `p'.ado
		if _rc {
			di as text "  " %-8s "`p'" "not installed"
			continue
		}
		local fn "`r(fn)'"
		local pv ""
		tempname fh
		file open `fh' using `"`fn'"', read text
		forvalues k = 1/6 {
			file read `fh' line
			if r(eof) continue, break
			if "`pv'" == "" & strpos(`"`line'"', "*! version") == 1 {
				local pv : word 3 of `line'
				local pd : word 4 of `line'
			}
		}
		file close `fh'
		di as text "  " %-8s "`p'" as res cond("`pv'" == "", "installed", "`pv'  (`pd')")
	}
	return local version "`nwv'"
	return local date "`nwd'"
end
