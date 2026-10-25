cscript

do unw_core.do

* No Stata housekeeping message or formatting artefact may leak into the
* output of a core command: "(N real changes made)", "(N missing values
* generated)", "variable x was str5 now str7", "a double colon, a stray leading "." and floating point artefacts such as
* .5690000000000001.  Each command below runs with its output captured in a
* log and the log is scanned line by line.

tempfile lk
capture log close leak

program define _leakscan
	args file
	tempname fh
	local bad 0
	file open `fh' using `"`file'"', read text
	file read `fh' line
	while r(eof) == 0 {
		local l = strtrim(`"`macval(line)'"')
		* skip the echoed command lines of this log
		if substr(`"`l'"', 1, 2) == ". " & !regexm(`"`l'"', "^\.[ ]+\(") {
			file read `fh' line
			continue
		}
		local hit 0
		if regexm(`"`l'"', "^\([0-9,]+ (real change|missing value|observation)") local hit 1
		if regexm(`"`l'"', "^\(.*real changes? made") local hit 1
		if regexm(`"`l'"', "^variable .* (was|now) ") local hit 1
		if regexm(`"`l'"', "[A-Za-z]::") local hit 1
		if regexm(`"`l'"', "^\.[ ]+\(") local hit 1
		if regexm(`"`l'"', "[0-9]0000000[0-9]") local hit 1
		if regexm(`"`l'"', "[0-9]9999999") local hit 1
		if `hit' {
			di as err "leaked line: `l'"
			local bad = `bad' + 1
		}
		file read `fh' line
	}
	file close `fh'
	assert `bad' == 0
end

program define _leakrun
	* _leakrun <dataset> : runs the commands in a captured log, then scans it
	args ds
	nwclear
	nwuse data/`ds', nwclear
end

* ---- undirected: gang
_leakrun gang
log using `"`lk'"', text replace name(leak)
nwdegree, generate(d1)
nwevcent, generate(ev1)
nwpagerank, generate(pr1)
nwfactions, generate(fc1)
nwclustering, generate(cc1)
nwsummarize
nwmixing, attribute(Birthplace)
nwtabulate, attribute(Birthplace)
nwneighbor, ego(g1) generate(nb1)
nwmaxflow, source(g1) sink(g5) generate(mf1)
nwcorrelate gang gang_valued, permutations(10)
nwtoedge gang
log close leak
_leakscan `"`lk'"'

_leakrun gang
log using `"`lk'"', text replace name(leak)
nwcollapse (max) gang, by(Birthplace)
log close leak
_leakscan `"`lk'"'

* (nwrecode reports "(N changes made to net)" on purpose, like Stata's recode)
_leakrun gang
log using `"`lk'"', text replace name(leak)
nwrecode gang(1=2), generate(grc)
log close leak
_leakscan `"`lk'"'

* ---- directed: glasgow
_leakrun glasgow
log using `"`lk'"', text replace name(leak)
nwdegree, generate(dg1 dg2)
nwturnover glasgow2 glasgow3, generate(tv1)
nwmixing, attribute(smoke3)
nwtoedge glasgow1
nwsummarize
nwclustering, generate(cg1) symmetrize
nwevcent, generate(egv)
log close leak
_leakscan `"`lk'"'

* ---- florentine
_leakrun florentine
log using `"`lk'"', text replace name(leak)
nwmixing, attribute(seat)
nwqap flomarriage flobusiness, permutations(10) predict(pq1)
nwcorrelate flomarriage flobusiness
nwhomophily wealth, homophily(.8) density(.2) name(hm4)
log close leak
_leakscan `"`lk'"'

* ---- temporal and two-mode
nwclear
clear
input str10 ego str10 alter wave
"A" "B" 1
"B" "C" 2
"A" "C" 3
"C" "D" 3
"A" "D" 3
end
nwset ego alter, time(wave) name(snapnet) undirected
log using `"`lk'"', text replace name(leak)
nwattime snapnet, at(3) name(w3)
local rties = r(ties)
log close leak
_leakscan `"`lk'"'
* the printed tie count is the number of ties, r(ties) keeps counting triplet rows
assert `rties' == 6

nwclear
clear
input str10 ego str10 alter value
"P1" "I1" 1
"P2" "I1" 7
"P1" "I2" 3
"P2" "I2" 5
"P3" "I2" 1
"P3" "I3" 1
end
nw2fromedge ego alter value, name(tm)
log using `"`lk'"', text replace name(leak)
nwsummarize tm
nw2degree tm, generate(d2)
nwtoedge tm
log close leak
_leakscan `"`lk'"'

* ---- the scanner itself catches what it should
file open fh using `"`lk'"', write text replace
file write fh "(54 real changes made)" _n
file close fh
capture _leakscan `"`lk'"'
assert _rc != 0

* ---- return values keep full precision while the display is rounded
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) undirected name(wave1)
nwset, mat((0,1,0\1,0,1\0,1,0)) undirected name(wave2)
nwturnover wave1 wave2, generate(_tov)
assert reldif(r(persistence), 1/2) < 1e-12

display "test_no_leaked_lines: PASS"
