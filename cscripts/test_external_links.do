cscript

/*
	Dedicated external-link health check - NOT part of the ordinary
	"0 errors" bar the rest of cscripts/ is held to. This project's own
	established convention (see docs/CERTIFICATION.md) treats a dead
	third-party host as an "accepted environmental failure", not a code
	defect - the same distinction applies here. What this file exists
	to do is different: surface link rot BEFORE a user reports it (the
	exact gap that let vlado.fmf.uni-lj.si sit dead, unnoticed, until a
	user hit it directly - see docs/CERTIFICATION.md's own "Dead host
	(2026-09-01)" entry for the full account), by checking every
	external URL this package's own live .ado/.sthlp/.md files reference
	in one place, on demand, rather than never.

	Two categories, checked and reported separately:
	(1) FUNCTIONAL - URLs a real command actually fetches from
	    ($nwwebpath, nwinstall's own net-install host). A dead one here
	    breaks a real command for every user, same severity as the
	    UCINET bug this file exists because of.
	(2) DOCUMENTATION - URLs only ever shown to a human reading help
	    text (citations, format-spec references, download pages, the
	    project's own about-page links). A dead one here is a stale
	    link, not a broken command - worth fixing, lower urgency.

	Deliberately excludes: `old/`/`deprecated/` (archived, not part of
	the live package - already known to reference the dead
	nwcommands.org host, disclosed and out of scope, see
	docs/LEGACY_FILES.md), and http://www.zzz.edu/users/~sue
	(nwwebuse.sthlp's own illustrative placeholder for `nwwebuse set`,
	never a real link).

	Run manually/periodically (e.g. before a release), not as part of
	the routine full-suite sweep - every check here is a real network
	round-trip to a third party, and a single slow/rate-limiting host
	would otherwise make the ordinary fast sweep flaky for a reason
	that has nothing to do with this package's own code.
*/

tempname results
tempfile resultsfile
postfile `results' str20 category str60 label str200 url long rc using `resultsfile', replace

// Stata program bodies do not inherit the caller's local macros, so
// `post' inside _check_and_post below cannot see `results' directly -
// stash the expanded tempname in a global instead. (An earlier version
// of this file threaded the handle through as an extra positional
// argument to a wrapper program, and got the argument positions
// shifted by one, silently mislabeling every row - caught directly by
// running it, not assumed correct. Simpler to just use a global.)
global nwlinkposthandle "`results'"

capture program drop _check_and_post
program _check_and_post
	args category label url
	tempfile dest
	capture copy `"`url'"' `"`dest'"', replace
	local rc = _rc
	capture erase `"`dest'"'
	if `rc' == 0 {
		di as result "  OK   [`category'] `label': `url'"
	}
	else {
		di as error  "  DEAD [`category'] `label': `url' (rc=`rc')"
	}
	post $nwlinkposthandle (`"`category'"') (`"`label'"') (`"`url'"') (`rc')
end

di ""
di "=== FUNCTIONAL: URLs real commands fetch from ==="
_check_and_post "functional" "nwwebuse/nwuse default host (\$nwwebpath)" "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data/florentine.nwdta"
* NOTE: nwinstall's own net-install host is this same raw.githubusercontent.com
* /.../master tree, checked above via florentine.nwdta - a bare directory
* prefix (no filename) isn't itself a fetchable target, `copy` against it
* always returns rc=1 regardless of whether the host is healthy, so it isn't
* a meaningful separate check (an earlier version of this file included it
* and it showed up as a false-positive "dead functional link").

di ""
di "=== DOCUMENTATION: citations, format specs, about-page links ==="
_check_and_post "doc" "nw_intro: project GitHub" "https://github.com/thomas-u-grund/nwcommands"
_check_and_post "doc" "nw_intro: mailing list" "http://groups.google.com/forum/#!forum/nwcommands/join"
_check_and_post "doc" "nwmovie/nwplot: ImageMagick home" "https://imagemagick.org/"
_check_and_post "doc" "nwmovie: ImageMagick download page" "https://imagemagick.org/script/download.php"
_check_and_post "doc" "nwimport: Ucinet manual" "https://pages.uoregon.edu/vburris/hc431/Ucinet_Guide.pdf"
_check_and_post "doc" "nwimport: Gephi GML format spec" "https://docs.gephi.org/desktop/User_Manual/Import/GML_File_Format/"
_check_and_post "doc" "nwimport: Gephi Pajek format spec" "https://docs.gephi.org/desktop/User_Manual/Import/Pajek_NET_Format/"
_check_and_post "doc" "nwimport: Gephi Ucinet DL format spec" "https://docs.gephi.org/desktop/User_Manual/Import/UCINET_DL_Format/"
_check_and_post "doc" "netexample: usair citation (OpenFlights)" "https://openflights.org/data.php"
_check_and_post "doc" "netexample: s50 citation (RSiena)" "https://www.stats.ox.ac.uk/~snijders/siena/"
_check_and_post "doc" "netexample: s50 citation (RSiena GitHub)" "https://github.com/stocnet/rsiena"
_check_and_post "doc" "netexample: lazega/kapferer/mesa/sampson source (ergm on CRAN)" "https://cran.r-project.org/package=ergm"

postclose `results'
macro drop nwlinkposthandle

use `resultsfile', clear
di ""
di "=== SUMMARY ==="
count if rc != 0
local ndead = r(N)
count
local ntotal = r(N)
di "`ntotal' URLs checked, `ndead' dead"
if `ndead' > 0 {
	di ""
	di as error "Dead links found - not treated as a hard test failure (see this" _n "file's own header comment), but worth triaging:"
	list category label url rc if rc != 0, sep(0) noobs
	count if rc != 0 & category == "functional"
	if r(N) > 0 {
		di as error ""
		di as error "*** `=r(N)' FUNCTIONAL link(s) dead - this breaks a real command for every user, treat as urgent ***"
	}
}
else {
	di "All external links resolved cleanly."
}
