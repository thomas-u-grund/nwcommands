* cross_validate_native.do
* Loads every data set of Schoch's networkdata collection with nwnetworkdata (the reader without R) and writes one line per
* network to a tab-separated file, so that the result can be compared between computers (Mac, Windows, Linux).
* Stata only. Needs nwcommands (the version with the reader without R) installed or on the adopath, and an internet connection
* (every data set is downloaded from the collection's repository when it is needed, and removed from the cache after use).
*
* Usage:   do cross_validate_native.do [start [end [outfile]]]
*   start, end   first and last data set of the catalogue (numbered 1 ... 990 in alphabetical order); default: all
*   outfile      default: xval_<start>_<end>.tsv in the temporary folder of Stata (c(tmpdir))
* The program resumes where it stopped: data sets that already have a line in outfile are skipped. Nothing is skipped
* silently: a data set that fails gets a line with the Stata error code r() (columns 3 ff. are empty).
* Columns: object, network (index in the data set), name, nodes, ties, directed, valued, twomode, hash_edges, hash_nodes, seconds
* hash_edges: hash of the lines "from|to|weight" of the edge list sorted by from, to, weight, the weight as hexadecimal text (%21x)
* hash_nodes: hash of the node names, one per line, in the order of the nodes. The hash is a polynomial hash mod 4294967291
* of the characters (no platform-specific function). Compare the columns 1 to 10 between machines (the seconds differ).
version 17
args start end outfile
capture program drop nwinstall

capture mata: mata drop xv_hash()
mata:
real scalar xv_hash(string matrix S0)
{
	string colvector S
	real scalar h, i, n, j, k
	real rowvector a
	string scalar blk
	S = colshape(S0, 1)
	h = 1
	n = rows(S)
	for (i = 1; i <= n; i = i + 500) {
		k = min((i + 499, n))
		blk = invtokens(S[|i \ k|]', char(10)) + char(10)
		a = ascii(blk)
		for (j = 1; j <= cols(a); j++) h = mod(h * 257 + a[j], 4294967291)
	}
	return(h)
}
end

preserve
quietly nwnetworkdata list, clear
quietly keep obj
quietly duplicates drop
sort obj
local nobj = _N
if "`start'" == "" local start 1
if "`end'" == "" local end `nobj'
if `end' > `nobj' local end `nobj'
if `"`outfile'"' == "" local outfile "`c(tmpdir)'/xval_`start'_`end'.tsv"
forvalues i = `start'/`end' {
	local o`i' = obj[`i']
}
* the cache folder is private to this range of data sets, so that parallel runs do not disturb each other
local cachedir "`c(tmpdir)'/nwnd_xval_cache_`start'_`end'"
global nwnd_cache "`cachedir'"
capture mkdir "`cachedir'"

* what is done already
local done " "
capture confirm file `"`outfile'"'
if _rc == 0 {
	tempname fh
	file open `fh' using `"`outfile'"', read text
	file read `fh' line
	while r(eof) == 0 {
		gettoken first : line, parse("`=char(9)'")
		if substr(`"`line'"', 1, 1) != "#" local done `"`done'`first' "'
		file read `fh' line
	}
	file close `fh'
}
else {
	tempname fo0
	file open `fo0' using `"`outfile'"', write text
	file write `fo0' "# object" _tab "network" _tab "name" _tab "nodes" _tab "ties" _tab "directed" _tab "valued" _tab "twomode" _tab "hash_edges" _tab "hash_nodes" _tab "seconds" _n
	file close `fo0'
}
di as txt "cross_validate_native: data sets `start' to `end' of `nobj' -> `outfile'"
timer clear 99
timer on 99
tempname fo
forvalues i = `start'/`end' {
	local obj `o`i''
	if strpos(`"`done'"', " `obj' ") > 0 continue
	timer clear 98
	timer on 98
	capture nwnetworkdata `obj', nwclear
	local rc = _rc
	timer off 98
	quietly timer list 98
	local sec = r(t98)
	file open `fo' using `"`outfile'"', write text append
	if `rc' {
		file write `fo' "`obj'" _tab "." _tab "r(`rc')" _tab _tab _tab _tab _tab _tab _tab _tab %9.2f (`sec') _n
	}
	else {
		local nets `r(nets)'
		local k 0
		foreach net of local nets {
			local ++k
			capture {
				_nwsyntax `net'
				mata: __xv_E = sort(`netobj'->edgelist(), (1, 2, 3))
				mata: __xv_B = J(rows(__xv_E), 1, "|")
				mata: if (rows(__xv_E) > 0) __xv_L = strofreal(__xv_E[., 1], "%12.0f") + __xv_B + strofreal(__xv_E[., 2], "%12.0f") + __xv_B + strofreal(__xv_E[., 3], "%21x"); else __xv_L = J(1, 1, "")
				mata: st_local("hE", strofreal(xv_hash(__xv_L), "%12.0f"))
				mata: st_local("hN", strofreal(xv_hash(`netobj'->get_nodenames()), "%12.0f"))
				mata: st_local("nt", strofreal(rows(__xv_E), "%12.0f"))
				mata: mata drop __xv_E __xv_L __xv_B
			}
			if _rc {
				file write `fo' "`obj'" _tab "`k'" _tab "`net'" _tab "r(`=_rc')" _tab _tab _tab _tab _tab _tab _tab %9.2f (`sec') _n
			}
			else {
				file write `fo' "`obj'" _tab "`k'" _tab "`net'" _tab "`nodes'" _tab "`nt'" _tab "`directed'" _tab "`valued'" _tab "`is2mode'" _tab "`hE'" _tab "`hN'" _tab %9.2f (`sec') _n
			}
		}
	}
	file close `fo'
	quietly capture nwnetworkdata cache clear
	capture quietly nwclear
}
timer off 99
quietly timer list 99
di as txt "cross_validate_native: done in " %9.1f r(t99) " seconds; result: `outfile'"
