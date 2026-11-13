* xt_data_06_exportimport.do
* nwexport -> nwimport round trips for every format nwexport writes (pajek, ucinet, gml, edgelist) on a
* directed binary network with isolates, an undirected valued network (negative and non-integer values) and a
* network whose labels have blanks and non-ASCII letters; a two-mode network through pajek and edgelist;
* error paths of both commands (unknown type, file exists, missing file, networks in memory) with data and
* networks unchanged; nwimport type(edgelist) with delimiter(); no stray r().
* What a format cannot hold (e.g. isolates in a plain edge list) is checked as [policy] only.
clear all
set more off
run cscripts/xt_data_00_helpers.do
xt_init xt_data_06_exportimport
set seed 20261112
tempfile tf
local base = `"`tf'"' + "_xtio"

* xt_ie src type ext [importopts]: export src, import it as __xt_imp, compare
capture program drop xt_ie
program xt_ie
	args src type ext importopts
	local base `"$XT_BASE"'
	quietly nwname `src'
	local labs0 `"`r(labs)'"'
	local dir0 "`r(directed)'"
	local val0 "`r(valued)'"
	local n0 = r(nodes)
	local m20 "`r(mode2)'"
	xt_mat `src' __xt_ie0
	capture noisily nwexport `src', type(`type') fname(`base'_`src') replace
	xt_chk `=(_rc == 0)' "`src' `type': exported (got `=_rc')"
	capture noisily nwimport `"`base'_`src'.`ext'"', type(`type') name(__xt_imp) nwappend `importopts'
	local rc = _rc
	xt_chk `=(`rc' == 0)' "`src' `type': imported (got `rc')"
	if `rc' != 0 exit
	xt_hasnet __xt_imp
	xt_chk `has' "`src' `type': the network is named by name()"
	if !`has' exit
	quietly nwname __xt_imp
	local labs1 `"`r(labs)'"'
	local tag "`src' `type'"
	local pol ""
	if "`type'" == "edgelist" local pol "[policy] "
	xt_chk `=(r(nodes) == `n0')' "`pol'`tag': `n0' nodes (isolates kept; got `r(nodes)')"
	xt_chk `=("`r(directed)'" == "`dir0'")' "`pol'`tag': directed flag kept (`dir0', got `r(directed)')"
	* nwexport writes a binary network without tie values and nwimport reads a file without tie values as binary
	* (owner's decision on N9; before, a binary network came back valued)
	xt_chk `=("`r(valued)'" == "`val0'")' "`tag': valued flag kept (`val0', got `r(valued)')"
	xt_chk `=("`r(mode2)'" == "`m20'")' "`tag': two-mode flag kept (`m20', got `r(mode2)')"
	mata: st_local("same", strofreal(xt_sorteq(st_local("labs0"), st_local("labs1"))))
	* UCINET: the label line a,b,c used to be read as one label (was bug N7, fixed); labels with blanks are quoted
	xt_chk `=("`same'" == "1")' "`pol'`tag': same labels" // was bug N7 for type ucinet (fixed)
	if "`same'" == "1" {
		xt_mat __xt_imp __xt_ie1
		mata: st_local("eq", strofreal(xt_reorder(__xt_ie1, st_local("labs1"), st_local("labs0")) == __xt_ie0))
		xt_chk `=("`eq'" == "1")' "`pol'`tag': same ties and values"
		capture mata: mata drop __xt_ie1
	}
	capture mata: mata drop __xt_ie0
	nwdrop __xt_imp
end
global XT_BASE `"`base'"'

* --- A. the networks
nwclear
mata: __xt_D = (runiform(8, 8) :< .3), J(8, 2, 0) \ J(2, 10, 0)
mata: _diag(__xt_D, 0)
nwset, mat(__xt_D) name(dir)
nwset, mat((0,-2,.5,0\-2,0,1.25,3\.5,1.25,0,0\0,3,0,0)) name(uval) undirected
nwset, mat((0,1,0,0\0,0,1,0\0,0,0,1\1,0,0,0)) name(lab) labs(Anna Maria,Zoë,Bob Smith,Ünal)
preserve
clear
input str8 person str8 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Tim" "LiU"
end
nwset person org, twomode name(aff)
restore

* --- B. round trips
foreach t in pajek ucinet gml edgelist {
	if "`t'" == "pajek" local e "net"
	if "`t'" == "ucinet" local e "dl"
	if "`t'" == "gml" local e "gml"
	if "`t'" == "edgelist" local e "txt"
	foreach net in dir uval lab {
		xt_ie `net' `t' `e'
	}
}
foreach t in pajek edgelist {
	if "`t'" == "pajek" local e "net"
	if "`t'" == "edgelist" local e "txt"
	xt_ie aff `t' `e'
}
* an undirected edge list read back with forceundirected
xt_ie uval edgelist txt forceundirected
di "PASS B round trips"

* --- C. error paths
nwclear
nwset, mat((0,1\1,0)) name(io)
gen keepme = _n
xt_snap c1
* nwexport moves _nwinclude behind the user's variables (values unchanged, the variable order changes)
quietly nwexport io, type(pajek) fname(`base'_io) replace
xt_same c1 "nwexport changes nothing in the data" // was bug N6 (variable order) (fixed)
xt_snap c1
capture noisily nwexport io, type(csv) fname(`base'_io) replace
xt_chk `=(_rc == 6556)' "nwexport type(csv): r(6556) (got `=_rc')"
xt_same c1 "nwexport unknown type"
foreach t in pajek ucinet gml edgelist {
	quietly nwexport io, type(`t') fname(`base'_io) replace
	capture noisily nwexport io, type(`t') fname(`base'_io)
	xt_chk `=(_rc == 602)' "nwexport `t' onto an existing file without replace: r(602) (got `=_rc')"
	xt_same c1 "nwexport `t' without replace"
}
capture noisily nwimport `"`base'_io.net"', type(pajek) name(x)
xt_chk `=(_rc == 999)' "nwimport with a network in memory and neither nwclear nor nwappend: r(999) (got `=_rc')"
xt_same c1 "nwimport refused (999)"
capture noisily nwimport `"`base'_io.net"', type(pajekk) name(x) nwappend
xt_chk `=(_rc == 6556)' "nwimport type(pajekk): r(6556) (got `=_rc')"
xt_same c1 "nwimport unknown type"
foreach t in pajek ucinet gml edgelist {
	capture noisily nwimport `"`base'_nosuch.xyz"', type(`t') name(x) nwappend
	xt_chk `=(_rc != 0)' "nwimport `t' of a missing file fails (got `=_rc')"
	xt_same c1 "nwimport `t' of a missing file with nwappend" // was bug N8 for type edgelist (the data are cleared) (fixed)
}
* rebuild what N8 cleared
nwclear
nwset, mat((0,1\1,0)) name(io)
gen keepme = _n
quietly nwexport io, type(pajek) fname(`base'_io) replace
xt_snap c1
* N8 also on success: nwimport type(edgelist), nwappend replaces the data in memory
quietly nwexport io, type(edgelist) fname(`base'_io) replace
nwimport `"`base'_io.txt"', type(edgelist) name(io2) nwappend
capture confirm variable keepme
xt_chk `=(_rc == 0)' "nwimport type(edgelist), nwappend keeps the variables in memory" // was bug N8 (fixed)
nwclear
nwset, mat((0,1\1,0)) name(io)
gen keepme = _n
quietly nwexport io, type(pajek) fname(`base'_io) replace
xt_snap c1
capture noisily nwimport `"`base'_io.net"', type(pajek) name(io) nwappend
if _rc == 0 {
	quietly nwset
	xt_chk `=(r(networks) == 2)' "[policy] nwimport name() in use with nwappend: refused with 483, or a new name (now `r(nets)')"
}
else {
	xt_chk `=(_rc == 483)' "nwimport name() in use: r(483) (got `=_rc')"
	xt_same c1 "nwimport name() in use"
}
di "PASS C errors"

* --- D. nwimport type(edgelist) with delimiter()
nwclear
clear
input str4 a str4 b v
"x" "y" 2
"y" "z" 3
end
export delimited using `"`base'_semi.txt"', delimiter(";") novarnames replace
capture noisily nwimport `"`base'_semi.txt"', type(edgelist) delimiter(;) name(semi) nwclear
xt_chk `=(_rc == 0)' "nwimport type(edgelist) delimiter(;) reads a non-Excel file (got `=_rc')" // was bug S23 (fixed)
if _rc == 0 {
	quietly nwname semi
	xt_chk `=(r(nodes) == 3)' "delimiter(;): 3 nodes"
}
di "PASS D delimiter"

* --- E. no stray r()
nwclear
nwset, mat((0,1\1,0)) name(io)
xt_rmark
nwexport io, type(pajek) fname(`base'_io) replace
xt_nostray "nwexport"
xt_rmark
nwimport `"`base'_io.net"', type(pajek) name(io2) nwappend
xt_nostray "nwimport"
di "PASS E r()"

foreach f in dir uval lab aff io semi {
	foreach e in net dl gml txt {
		capture erase `"`base'_`f'.`e'"'
	}
}
capture mata: mata drop __xt_D
xt_end
di "ALL PASS"
