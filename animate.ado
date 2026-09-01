capture program drop animate
program animate
	syntax anything, graphs(string) [imagickpath(string) delay(string) noloop showcommand keepeps mag(integer 100)]

	if "`imagickpath'" != "" {
		local ipend = substr("`imagickpath'",-1,.)
		if "`ipend'" != "/" & "`ipend'" != "\" {
			local imagickpath "`imagickpath'/"
		}
	}
	if trim("`loop'") == "noloop"{
		local dloop = 1
	}
	else {
		local dloop = 0
	}
	// Version-pinned installer URLs (cactuslab.com Mac build, imagemagick.org
	// binaries/ Windows builds) rot as soon as that version is superseded -
	// confirmed dead (404) 2026-09-01, see cscripts/test_external_links.do.
	// Point at ImageMagick's own current download page instead, which stays
	// valid across version bumps.
	local download = "https://imagemagick.org/script/download.php"

	di `"{err}command requires {net "https://imagemagick.org/":ImageMagick} to be installed on your computer; {net "`download'":download it here}"'
	
	if "`delay'" == "" {
		local delay "50"
	}
	local epslist ""
	local numgraphs : word count `graphs'
	local i = 1
	qui if "`graphs'" == "_all" {
		graph dir
		local graphs `r(list)'
	}
	foreach g in `graphs' {
		local gl = length("`g'") - 4
		
		if (substr("`g'", -4, .) == ".gph") {
			graph use `g'
			local geps = substr("`g'",1, `gl')
		}
		else {
			graph display `g'
			local geps `g'
		}
		
		graph export `geps'.eps, replace 
		//mag(`mag')
		local epslist "`epslist' `geps'.eps"
	
		if `i' == `numgraphs' {
			local last "`geps'.eps"
		}
		local i = `i' + 1
	}
	
	local lastname : word `numgraphs' of `graphs'
	local lastdelay = `delay'
	local shellcmd "`imagickpath'convert -delay `delay' `epslist' -delay `lastdelay' `last'.eps -loop `dloop' `anything'.gif"
	shell `shellcmd'
	
	if "`showcommand'" != "" {
		di "`shellcmd'"
	}
	if "`keepeps'" == "" {
		if c(os) == "MacOSX" {
			shell rm `epslist'
		}
		else {
			shell del `epslist'
		}
	}
end



*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
