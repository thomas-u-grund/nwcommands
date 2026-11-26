* edge round 4: Pajek files with tabs or a byte-order mark, UCINET DL with a byte-order mark and blank lines, nwspectral
* with missing ties, the note of nwfromedge on trimmed identifiers, nwset not dropping unsaved variables
clear all
do unw_core.do

* writes a file; "|" is a line break, "~" a tab
capture program drop _write
program _write
	args fn text bom
	mata: __w(st_local("fn"), st_local("text"), st_local("bom"))
end
mata:
void __w(string scalar fn, string scalar text, string scalar bom)
{
	real scalar fh
	(void) _unlink(fn)
	fh = fopen(fn, "w")
	if (bom == "bom") fwrite(fh, char((239, 187, 191)))
	fwrite(fh, subinstr(subinstr(text, "|", char(10)), "~", char(9)))
	fclose(fh)
}
end
capture program drop _check
program _check
	args net nodes total
	nwsummarize `net'
	assert r(nodes) == `nodes'
	tempname M
	nwtomata `net', mat(`M')
	mata: assert(sum(editmissing(`M', 0)) == `total')
	mata: mata drop `M'
end

tempfile base
local pj `"*Vertices 4|1 "a"|2 "b"|3 "c"|4 "d"|*Edges|1 2 1|2 3 2|3 4 3|"'
local pjtab `"*Vertices 4|1~"a"|2~"b"|3~"c"|4~"d"|*Edges|1~2~1|2~3~2|3~4~3|"'
foreach v in plain tab bom tabbom {
	local t = cond(strpos("`v'", "tab"), `"`pjtab'"', `"`pj'"')
	local b = cond(strpos("`v'", "bom"), "bom", "")
	_write "`base'_`v'.net" `"`t'"' "`b'"
	nwimport "`base'_`v'.net", type(pajek) name(p_`v') nwclear
	_check p_`v' 4 12
}

local dl "dl n=4 format=fullmatrix|labels:|a,b,c,d|data:|0 1 0 0|1 0 2 0|0 2 0 3|0 0 3 0|"
local dlblank "dl n=4 format=fullmatrix||labels:|a,b,c,d||data:||0 1 0 0|1 0 2 0||0 2 0 3|0 0 3 0||"
foreach v in plain bom blank blankbom {
	local t = cond(strpos("`v'", "blank"), "`dlblank'", "`dl'")
	local b = cond(strpos("`v'", "bom"), "bom", "")
	_write "`base'_`v'.dl" "`t'" "`b'"
	nwimport "`base'_`v'.dl", type(ucinet) name(d_`v') nwclear
	_check d_`v' 4 12
}

* nwspectral: a missing tie counts as 0
nwclear
mata: M = (0,1,1,0 \ 1,0,1,0 \ 1,1,0,1 \ 0,0,1,0)
nwset, mat(M) name(full) undirected
mata: M[1,4] = . ; M[4,1] = .
nwset, mat(M) name(miss) undirected
foreach meas in binary valued {
	nwspectral full, generate(a) measure(`meas') replace
	local c = r(components)
	local l = r(algebraic_connectivity)
	nwspectral miss, generate(b) measure(`meas') replace
	assert r(components) == `c' & `c' == 1
	assert reldif(r(algebraic_connectivity), `l') < 1e-8
	assert !missing(b) in 1/4
}

* nwfromedge: identifiers that differ only in blanks are merged, with a note
capture program drop _log
program _log, rclass
	args cmd want
	tempfile lf
	quietly log using "`lf'", text replace name(r4)
	`cmd'
	quietly log close r4
	mata: st_local("found", strofreal(sum(strpos(cat(st_local("lf")), st_local("want")) :> 0)))
	return scalar found = `found'
end
nwclear
clear
input str6 a str6 b
" Bob" "Ann"
"Bob " "Cid"
end
_log "nwfromedge a b, name(t) undirected" "Warning: blanks"
assert r(found) > 0
nwsummarize t
assert r(nodes) == 3
nwclear
clear
input str6 a str6 b
" Bob" "Ann"
" Bob" "Cid"
end
_log "nwfromedge a b, name(t) undirected" "Warning: blanks"
assert r(found) == 0
* rows left out by if do not count
nwclear
clear
input str6 a str6 b byte k
" Bob" "Ann" 1
"Bob " "Cid" 0
end
_log "nwfromedge a b if k == 1, name(t) undirected" "Warning: blanks"
assert r(found) == 0

* nwset: unsaved variables that are not part of the edge list are not dropped silently
foreach form in "edgelist" "time(t)" "interval(t u)" "eventtime(t)" "twomode" {
	nwclear
	clear
	input str3 a str3 b t u extra
	"x" "p" 1 2 7
	"y" "q" 1 3 8
	end
	if "`form'" == "edgelist" | "`form'" == "twomode" drop t u
	capture noisily nwset a b, `form' name(n)
	assert _rc == 4
	* nothing changed
	assert _N == 2 & extra[2] == 8 & a[1] == "x"
	capture nwsummarize n
	assert _rc != 0
	nwset a b, `form' name(n) dropvars
	nwsummarize n
}
* only variables of the edge list: no stop
nwclear
clear
input str3 a str3 b w t
"x" "y" 2 1
"y" "z" 3 2
end
nwset a b w, time(t) name(n) directed
nwsummarize n
assert r(nodes) == 3
* saved data: no stop
nwclear
clear
input str3 a str3 b extra
"x" "y" 7
"y" "z" 8
end
tempfile saved
save "`saved'"
nwset a b, edgelist name(n)
nwsummarize n
assert r(nodes) == 3
* an edge list file with times is imported as before
nwclear
_write "`base'.csv" "ego,alter,time|x,y,1|y,z,2|" ""
clear
set obs 3
gen mine = _n
nwimport "`base'.csv", type(edgelist, time directed)

display "PASS test_edge_round4_serious"
