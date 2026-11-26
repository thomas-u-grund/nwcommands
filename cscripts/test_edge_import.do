* nwimport / nwexport edge cases: the data and networks after failed imports, matrix and edge list headers,
* UCINET labels, self-loops, declared direction, labels with commas and quotes, Pajek *Matrix, round trips.
* (all found in 3.37.1). Run from the repository root (see RELEASING.md C0).
clear all
set more off
set seed 1

local dir "`c(tmpdir)'/nwedgeimp"
capture mkdir "`dir'"
global EI_DIR "`dir'"

* ei_file name "line" "line" ...: writes a text file
capture program drop ei_file
program ei_file
	gettoken fn 0 : 0
	tempname fh
	file open `fh' using "$EI_DIR/`fn'", write replace text
	foreach l of local 0 {
		file write `fh' `"`l'"' _n
	}
	file close `fh'
end

* ei_net net nodes directed "matrix" ["labels"]: the network has these ties (and labels, in this order)
capture program drop ei_net
program ei_net
	args net n directed mat labs
	qui nwname `net'
	assert r(nodes) == `n'
	assert "`r(directed)'" == "`directed'"
	if `"`labs'"' != "" {
		local have `"`r(labs)'"'
		assert `"`have'"' == `"`labs'"'
	}
	qui nwtomata `net', mat(__ei_M)
	mata: __ei_E = `mat'
	mata: _editmissing(__ei_M, 0)
	mata: _editmissing(__ei_E, 0)
	mata: assert(__ei_M == __ei_E)
	mata: mata drop __ei_M __ei_E
end

* ---- files used below
ei_file lab.csv ",ann,bob,cid" "ann,0,1,0" "bob,1,0,1" "cid,0,1,0"
ei_file el.csv "from,to" "ann,bob" "bob,cid"
ei_file comp.txt "peter,thomas,mathilde,tim" "thomas,susan" "susan" "geoff,john,michael"
ei_file good.net "*Vertices 3" `"1 "a""' `"2 "b""' `"3 "c""' "*Arcs" "1 2" "2 3"
ei_file bad.csv "a,b,c" "0,1,x" "1,0,1" "0,1,0"
ei_file rect.csv "0,1" "1,0" "0,1"
ei_file bad.net "*Vertices 3" "*Matrix" "0 1 0" "0 0"
ei_file bad.gml "this is not a network"
ei_file bad.dl "hello"
ei_file nodata.dl "dl n=3" "format = fullmatrix"
ei_file badval.dl "dl n=2 nm=2" "data:" "0 1" "1 0" "0 x_y" "1 0"
ei_file four.txt "a b 1 2" "b c 1 2"

* ---- 1  a failed import leaves the data (also unsaved), the networks and the current network as they were
capture program drop ei_state
program ei_state
	qui datasignature
	global EI_sig "`r(datasignature)'"
	global EI_N = _N
	global EI_k = c(k)
	global EI_changed = c(changed)
	global EI_nets ""
	global EI_cur ""
	capture qui nwset
	if _rc == 0 global EI_nets "`r(nets)'"
	if "$EI_nets" != "" {
		mata: st_global("EI_cur", __nw.nws.get_current_name())
	}
end
capture program drop ei_same
program ei_same
	qui datasignature
	assert "`r(datasignature)'" == "$EI_sig"
	assert _N == $EI_N & c(k) == $EI_k & c(changed) == $EI_changed
	local nets ""
	capture qui nwset
	if _rc == 0 local nets "`r(nets)'"
	assert "`nets'" == "$EI_nets"
	if "`nets'" != "" {
		mata: assert(__nw.nws.get_current_name() == st_global("EI_cur"))
	}
end

local cases `" "nosuch.csv matrix" "nosuch.txt edgelist" "nosuch.txt compressed" "nosuch.net pajek" "nosuch.gml gml" "nosuch.dl ucinet" "bad.csv matrix" "rect.csv matrix" "four.txt edgelist" "bad.net pajek" "bad.gml gml" "bad.dl ucinet" "nodata.dl ucinet" "badval.dl ucinet" "'
foreach withnets in 0 1 {
	foreach c of local cases {
		gettoken f t : c
		local t = trim("`t'")
		nwclear
		clear
		set obs 20
		gen income = _n * 100
		if `withnets' {
			qui nwrandom 5, prob(.5) name(keep1)
			qui nwrandom 4, prob(.5) name(keep2)
			qui nwload keep1, labelonly
		}
		ei_state
		* without options (refused with networks in memory), with nwappend, with nwclear and with clear
		foreach opt in "" "nwappend" "nwclear" "clear" {
			capture nwimport "`dir'/`f'", type(`t') `opt'
			if _rc == 0 {
				di as err "no error: `f' type(`t') `opt'"
				exit 9
			}
			if "`opt'" == "" & `withnets' assert _rc == 999
			ei_same
		}
	}
}
* a failed Pajek import does not leave its file open
nwclear
clear
capture nwimport "`dir'/bad.net", type(pajek)
assert _rc == 6705
nwimport "`dir'/good.net", type(pajek)
ei_net good 3 true "(0,1,0 \ 0,0,1 \ 0,0,0)" "a,b,c"
nwimport "`dir'/good.net", type(pajek) nwappend name(again)
di "PASS 1a failed imports"

* ---- successful imports keep data that are in memory, unless clear or nwclear is given
foreach c in "lab.csv matrix" "el.csv edgelist" "comp.txt compressed" "good.net pajek" {
	gettoken f t : c
	local t = trim("`t'")
	nwclear
	clear
	set obs 20
	gen income = _n * 100
	ei_state
	nwimport "`dir'/`f'", type(`t')
	qui datasignature
	assert "`r(datasignature)'" == "$EI_sig" & _N == 20 & c(k) == 1 & c(changed) == $EI_changed
	qui nwset
	assert r(networks) == 1
	nwimport "`dir'/`f'", type(`t') nwappend name(second)
	assert _N == 20 & c(k) == 1 & income[20] == 2000
	* clear and nwclear: the data of the user are replaced
	foreach opt in clear nwclear {
		nwimport "`dir'/`f'", type(`t') `opt'
		capture confirm variable income
		assert _rc == 111
		qui nwset
		assert r(networks) == 1
	}
}
* in an empty data set the node names of a list are in memory afterwards
nwclear
clear
nwimport "`dir'/el.csv", type(edgelist)
assert _N == 3
confirm variable _nwnode
* xvars adds variables to the data that are kept
nwclear
clear
set obs 3
gen mine = _n
nwimport "`dir'/lab.csv", type(matrix) xvars
confirm variable mine
confirm variable ann
assert mine[3] == 3
* import into data that have no networks, also in a changed data set without variables
nwclear
clear
set obs 7
nwimport "`dir'/lab.csv", type(matrix)
assert _N == 7 & c(k) == 0
di "PASS 1b data kept"

* ---- 2, 3  matrices: names in the first row and/or column
local L3 "(0,1,0 \ 1,0,1 \ 0,1,0)"
clear
putexcel set "`dir'/hdr.xlsx", replace
putexcel A1="Ann" B1="bob" C1="cid" A2=0 B2=1 C2=0 A3=1 B3=0 C3=1 A4=0 B4=1 C4=0
putexcel set "`dir'/both.xlsx", replace
putexcel B1="ann" C1="bob" D1="cid" A2="ann" B2=0 C2=1.5 D2=0 A3="bob" B3=1.5 C3=0 D3=.125 A4="cid" B4=0 C4=.125 D4=0
foreach opt in "" ", rownames colnames" ", colnames" {
	nwclear
	clear
	nwimport "`dir'/both.xlsx", type(matrix`opt')
	ei_net both 3 false "(0,1.5,0 \ 1.5,0,.125 \ 0,.125,0)" "ann,bob,cid"
}
foreach opt in "" ", colnames" ", rownames" {
	nwclear
	clear
	nwimport "`dir'/hdr.xlsx", type(matrix`opt')
	ei_net hdr 3 false "`L3'" "Ann,bob,cid"
}
nwclear
clear
nwimport "`dir'/lab.csv", type(matrix)
ei_net lab 3 false "`L3'" "ann,bob,cid"
* numbers as node names
ei_file num.csv ",1,2,3" "1,0,1,0" "2,1,0,1" "3,0,1,0"
ei_file numid.csv "id,1,2,3" "1,0,1,0" "2,1,0,1" "3,0,1,0"
ei_file numrow.csv "10,20,30" "0,1,0" "1,0,1" "0,1,0"
foreach f in num numid {
	nwclear
	clear
	nwimport "`dir'/`f'.csv", type(matrix)
	ei_net `f' 3 false "`L3'" "1,2,3"
}
nwclear
clear
nwimport "`dir'/numrow.csv", type(matrix)
ei_net numrow 3 false "`L3'" "10,20,30"
ei_file numcol.csv "7,0,1,0" "8,1,0,1" "9,0,1,0"
nwclear
clear
nwimport "`dir'/numcol.csv", type(matrix, rownames)
ei_net numcol 3 false "`L3'" "7,8,9"
* semicolons with decimal commas; tab and blank separated; no names at all; an empty diagonal
ei_file semi.csv "a;b;c" "0;1,5;0" "1,5;0;2,25" "0;2,25;0"
nwclear
clear
nwimport "`dir'/semi.csv", type(matrix)
ei_net semi 3 false "(0,1.5,0 \ 1.5,0,2.25 \ 0,2.25,0)" "a,b,c"
ei_file plain.txt "0 1 1 0" "1 0 0 0" "0 0 0 1" "0 1 0 0"
nwclear
clear
nwimport "`dir'/plain.txt", type(matrix)
ei_net plain 4 true "(0,1,1,0 \ 1,0,0,0 \ 0,0,0,1 \ 0,1,0,0)"
ei_file blankdiag.csv ",5,7" "5,,9" "7,9,"
nwclear
clear
nwimport "`dir'/blankdiag.csv", type(matrix)
ei_net blankdiag 3 false "(0,5,7 \ 5,0,9 \ 7,9,0)"
* never a silently empty or wrong network: a clear error
foreach f in bad.csv rect.csv {
	nwclear
	clear
	capture nwimport "`dir'/`f'", type(matrix)
	assert _rc == 480
}
ei_file order.csv ",b,a" "a,0,1" "b,0,0"
capture nwimport "`dir'/order.csv", type(matrix)
assert _rc == 480
* node attributes, also text (help Examples)
ei_file sex.csv "thomas,peter,susan,kim, sex" "0,1,1,0, male" "1,0,0,0, male" "0,0,0,1, female" "0,1,0,0, male"
nwclear
clear
nwimport "`dir'/sex.csv", type(matrix)
ei_net sex 4 true "(0,1,1,0 \ 1,0,0,0 \ 0,0,0,1 \ 0,1,0,0)" "thomas,peter,susan,kim"
assert sex[1] == "male" & sex[3] == "female" & _N == 4
ei_file ex2.csv "thomas,peter,susan,kim" "0,1,1,0" "1,0,0,0" "0,0,0,1" "0,1,0,0"
ei_file ex3.csv "thomas,0,1,1,0" "peter,1,0,0,0" "susan,0,0,0,1" "kim,0,1,0,0"
foreach c in "ex2.csv matrix" "ex3.csv matrix, rownames" "ex3.csv matrix" {
	gettoken f t : c
	nwclear
	clear
	nwimport "`dir'/`f'", type(`=trim("`t'")') name(m)
	ei_net m 4 true "(0,1,1,0 \ 1,0,0,0 \ 0,0,0,1 \ 0,1,0,0)" "thomas,peter,susan,kim"
}
di "PASS 2 3 matrices"

* ---- 3  edge lists with a header line
local E2 "(0,1,0 \ 0,0,1 \ 0,0,0)"
nwclear
clear
nwimport "`dir'/el.csv", type(edgelist)
ei_net el 3 true "`E2'" "ann,bob,cid"
ei_file elv.csv "Source,Target,Weight" "ann,bob,2" "bob,cid,3"
ei_file elw.csv "who,whom,strength" "ann,bob,2" "bob,cid,3"
foreach f in elv elw {
	nwclear
	clear
	nwimport "`dir'/`f'.csv", type(edgelist)
	ei_net `f' 3 true "(0,2,0 \ 0,0,3 \ 0,0,0)" "ann,bob,cid"
}
clear
putexcel set "`dir'/elx.xlsx", replace
putexcel A1="from" B1="to" C1="weight" A2="ann" B2="bob" C2=2 A3="bob" B3="cid" C3=3
nwclear
clear
nwimport "`dir'/elx.xlsx", type(edgelist)
ei_net elx 3 true "(0,2,0 \ 0,0,3 \ 0,0,0)" "ann,bob,cid"
* the word is a node when it occurs again, and with noheader
ei_file nodes.csv "from,to" "to,ann"
nwclear
clear
nwimport "`dir'/nodes.csv", type(edgelist)
ei_net nodes 3 true "(0,0,0 \ 0,0,1 \ 1,0,0)" "ann,from,to"
nwclear
clear
nwimport "`dir'/el.csv", type(edgelist, noheader)
qui nwname el
assert r(nodes) == 5
* help Examples of edge lists
ei_file h1.txt "1 2" "1 4" "2 4" "4 3"
ei_file h2.txt "peter,thomas,1" "thomas,susan,4" "susan,thomas,3" "geoff,john,2"
nwclear
clear
nwimport "`dir'/h1.txt", type(edgelist)
ei_net h1 4 true "(0,1,0,1 \ 0,0,0,1 \ 0,0,0,0 \ 0,0,1,0)"
nwimport "`dir'/h2.txt", type(edgelist) nwclear
qui nwsummarize h2
assert r(nodes) == 5 & r(arcs) == 4 & r(maxval) == 4
ei_file h3.txt "AS,MI,NY,TX" "TX,CA" "IL,AL,SD" "AL,MI,CA,NY"
nwimport "`dir'/h3.txt", type(compressed) nwclear
qui nwname h3
assert "`r(selfloop)'" == "false"
nwimport "`dir'/comp.txt", type(compressed) nwclear
qui nwname comp
assert r(nodes) == 8 & "`r(selfloop)'" == "false"
nwimport "data/edgelist_example.txt", type(edgelist) nwclear
di "PASS 3 edge lists"

* ---- 4  UCINET: the help examples
ei_file u1.dl "dl n=4 format=fullmatrix" "data:" "0 1 1 0" "1 0 1 1" "1 1 0 0" "0 1 0 0"
nwimport "`dir'/u1.dl", type(ucinet) nwclear
ei_net u1 4 false "(0,1,1,0 \ 1,0,1,1 \ 1,1,0,0 \ 0,1,0,0)"
ei_file u2.dl "dl n = 4, nm = 2" "labels:" "GroupA,GroupB,GroupC,GroupD" "matrix labels:" "Marriage,Business" "data:" ///
	"0 1 0 1" "1 0 0 0" "0 0 1 0" "1 0 0 1" "" "0 1 1 1" "1 0 0 0" "1 0 0 1" "1 0 1 0"
nwimport "`dir'/u2.dl", type(ucinet) nwclear
qui nwset
assert "`r(nets)'" == " Marriage Business"
qui nwname Business
assert r(nodes) == 4 & "`r(labs)'" == "GroupA,GroupB,GroupC,GroupD"
ei_file u3.dl "dl n = 4" "format = lowerhalf" "labels:" "Sanders,Skvoretz" "S.Smith,T.Smith" "data:" "2" "1 2" "1 1 2" "0 1 0 2"
nwimport "`dir'/u3.dl", type(ucinet) nwclear
ei_net u3 4 false "(2,1,1,0 \ 1,2,1,1 \ 1,1,2,0 \ 0,1,0,2)" "Sanders,Skvoretz,S.Smith,T.Smith"
ei_file u4.dl "DL n=5" "format = edgelist1" "labels:" "george, sally, jim, billy, jane" "data:" "1 2" "1 3" "2 3" "3 1" "4 3"
nwimport "`dir'/u4.dl", type(ucinet) nwclear
qui nwsummarize u4
assert r(nodes) == 5 & r(arcs) == 5
ei_file u5.dl "DL n=5" "format = edgelist1" "labels embedded:" "data:" "george sally" "george jim" "sally jim" "billy george" "jane jim"
nwimport "`dir'/u5.dl", type(ucinet) nwclear
ei_net u5 5 true "(0,1,0,0,0 \ 0,0,0,1,1 \ 0,0,0,1,0 \ 0,0,0,0,0 \ 0,0,0,1,0)" "billy,george,jane,jim,sally"
* a full matrix with embedded labels, and quoted labels with blanks
ei_file u6.dl "dl n=3" "format = fullmatrix" "labels embedded:" "data:" `""ann lee" bob cid"' `""ann lee" 0 1 0"' "bob 1 0 1" "cid 0 1 0"
nwimport "`dir'/u6.dl", type(ucinet) nwclear
ei_net u6 3 false "(0,1,0 \ 1,0,1 \ 0,1,0)" "ann lee,bob,cid"
di "PASS 4 ucinet"

* ---- round trips: directed valued with self-loop, directed with symmetric ties, undirected with self-loop
capture program drop ei_trip
program ei_trip
	args type opt
	local e = cond("`type'" == "pajek", "net", cond("`type'" == "ucinet", "dl", cond("`type'" == "gml", "gml", "txt")))
	qui nwexport src, type(`type') fname("$EI_DIR/rt_`type'") replace
	nwdrop src
	nwimport "$EI_DIR/rt_`type'.`e'", type(`type') name(src) nwclear `opt'
end
foreach t in pajek gml ucinet edgelist {
	* UCINET DL and an edge list do not say whether a network is directed
	local needd = cond(inlist("`t'", "ucinet", "edgelist"), "forcedirected", "")
	local needu = cond("`t'" == "edgelist", "forceundirected", "")
	* directed, valued, with a self-loop
	nwclear
	clear
	mata: R = (2,3,0 \ 0,0,-1.5 \ 1,0,0)
	nwset, mat(R) name(src) directed selfloop labs(a,b,c)
	ei_trip `t'
	ei_net src 3 true "(2,3,0 \ 0,0,-1.5 \ 1,0,0)" "a,b,c"
	qui nwname src
	assert "`r(selfloop)'" == "true" & "`r(valued)'" == "true"
	* directed, every tie reciprocated
	nwclear
	clear
	mata: R = (1,1,0 \ 1,0,0 \ 0,0,0)
	nwset, mat(R) name(src) directed selfloop labs(a,b,c)
	ei_trip `t' `needd'
	local n = cond("`t'" == "edgelist", 2, 3)
	ei_net src `n' true "(1,1,0 \ 1,0,0 \ 0,0,0)[|1,1 \ `n',`n'|]"
	qui nwname src
	assert "`r(selfloop)'" == "true" & "`r(valued)'" == "false"
	* undirected
	nwclear
	clear
	mata: R = (1,1,0 \ 1,0,1 \ 0,1,0)
	nwset, mat(R) name(src) undirected selfloop labs(a,b,c)
	ei_trip `t' `needu'
	ei_net src 3 false "(1,1,0 \ 1,0,1 \ 0,1,0)" "a,b,c"
	* a missing tie value is not written: no tie after the import
	nwclear
	clear
	mata: R = (0,.,1 \ 0,0,1 \ 1,0,0)
	nwset, mat(R) name(src) directed labs(a,b,c)
	ei_trip `t'
	ei_net src 3 true "(0,0,1 \ 0,0,1 \ 1,0,0)" "a,b,c"
	* labels with blanks, apostrophes, semicolons, commas and double quotes
	nwclear
	clear
	mata: R = (0,1,0 \ 0,0,1 \ 1,0,0)
	nwset, mat(R) name(src) directed
	mata: __nw.nws.pdefs[1]->set_nodenames(("'t Hart (x)", "x;y, z'", "say " + char(34) + "hi" + char(34)))
	ei_trip `t' forcedirected
	qui nwname src
	assert r(nodes) == 3
	mata: __l = tokens(st_global("r(labs)"), ",")
	mata: __l = select(__l, __l :!= ",")
	mata: assert(sort(__l', 1) == sort(("'t Hart (x)" \ "x;y z'" \ "say 'hi'"), 1))
	qui nwtomata src, mat(__M)
	mata: assert(sum(editmissing(__M, 0)) == 3)
	mata: mata drop __l __M
}
di "PASS 5 6 round trips"

* ---- 5  nodes declared by a row with value 0 stay without a self-loop; a self-loop listed before it is kept
ei_file late.gml "graph [" "directed 1" "edge [ source 1 target 1 ]" "edge [ source 1 target 2 ]" "node [ id 1 ]" "node [ id 2 ]" "]"
nwimport "`dir'/late.gml", type(gml) nwclear
ei_net late 2 true "(1,1 \ 0,0)"
ei_file diag.dl "dl n=2 format=fullmatrix" "data:" "3 1" "0 0"
nwimport "`dir'/diag.dl", type(ucinet) nwclear
ei_net diag 2 true "(3,1 \ 0,0)"
di "PASS 5 self-loops"

* ---- 6  declared direction; the force options
ei_file sym.net "*Vertices 2" "*Arcs" "1 2" "2 1"
ei_file emptyarcs.net "*Vertices 3" "*Arcs" "*Edges" "1 2" "2 3"
ei_file sym.gml "graph [" "directed 1" "node [ id 1 ]" "node [ id 2 ]" "edge [ source 1 target 2 ]" "edge [ source 2 target 1 ]" "]"
ei_file nodir.gml "graph [" "node [ id 1 ]" "node [ id 2 ]" "edge [ source 1 target 2 ]" "edge [ source 2 target 1 ]" "]"
foreach t in "sym.net pajek" "sym.gml gml" {
	gettoken f ty : t
	local ty = trim("`ty'")
	nwimport "`dir'/`f'", type(`ty') nwclear name(s)
	ei_net s 2 true "(0,1 \ 1,0)"
	nwimport "`dir'/`f'", type(`ty') nwclear name(s) forceundirected
	ei_net s 2 false "(0,1 \ 1,0)"
	nwimport "`dir'/`f'", type(`ty') nwclear name(s) forcedirected
	ei_net s 2 true "(0,1 \ 1,0)"
}
nwimport "`dir'/emptyarcs.net", type(pajek) nwclear name(s)
ei_net s 3 false "(0,1,0 \ 1,0,1 \ 0,1,0)"
nwimport "`dir'/nodir.gml", type(gml) nwclear name(s)
ei_net s 2 false "(0,1 \ 1,0)"
di "PASS 6 direction"

* ---- 7  labels with commas: one node per vertex, names stay unique
ei_file c.net "*Vertices 3" `"1 "Smith, John""' `"2 "Doe""' `"3 "Smith John""' "*Edges" "1 2" "2 3"
nwimport "`dir'/c.net", type(pajek) nwclear
ei_net c 3 false "(0,1,0 \ 1,0,1 \ 0,1,0)" "Smith John,Doe,Smith John_2"
ei_file c2.gml "graph [" `"node [ id 1 label "Smith, John" ]"' `"node [ id 2 label "Doe" ]"' "edge [ source 1 target 2 ]" "]"
nwimport "`dir'/c2.gml", type(gml) nwclear
ei_net c2 2 true "(0,1 \ 0,0)" "Smith John,Doe"
ei_file c3.csv `""Smith, John",bob"' `"bob,cid"'
nwimport "`dir'/c3.csv", type(edgelist) nwclear
ei_net c3 3 true "(0,1,0 \ 0,0,1 \ 0,0,0)" "Smith John,bob,cid"
ei_file c4.csv `""Smith, John",Doe"' "0,1" "1,0"
nwimport "`dir'/c4.csv", type(matrix) nwclear
ei_net c4 2 false "(0,1 \ 1,0)" "Smith John,Doe"
* short files with Windows line ends: Stata can take them for UTF-16 (the bytes are written here, so that the test
* is the same on every system; char(246) is the o with two dots in an 8-bit encoding, which is not valid UTF-8)
foreach kind in ascii latin1 {
	local file "`dir'/c5_`kind'.csv"
	capture erase "`file'"
	mata: __nl = char(13) + char(10)
	mata: __o = st_local("kind") == "ascii" ? "o" : char(246)
	mata: __fh = fopen(st_local("file"), "w")
	mata: fwrite(__fh, char(34) + "Sm" + __o + "th, John" + char(34) + ",Doe" + __nl + "0,1" + __nl + "1,0" + __nl)
	mata: fclose(__fh)
	mata: mata drop __nl __o __fh
	local want = cond("`kind'" == "ascii", "Smoth John,Doe", "Sm" + uchar(246) + "th John,Doe")
	nwimport "`file'", type(matrix) nwclear
	ei_net c5_`kind' 2 false "(0,1 \ 1,0)" "`want'"
}
* edge lists in other encodings: a byte-order mark, UTF-16 and an 8-bit encoding (written as bytes)
capture mata: mata drop ei_enc()
mata:
void ei_enc(string scalar fn, string scalar kind, real scalar header)
{
	real scalar fh, i
	string scalar t, out, nl
	real rowvector b

	nl = char((13, 10))
	t = (header ? "ego,alter" + nl : "") + "Zo" + uchar(235) + "," + uchar(220) + "nal" + nl + uchar(220) + "nal," + uchar(197) + "sa" + nl
	if (kind == "bom") out = char((239, 187, 191)) + t
	if (kind == "cp1252") out = ustrto(t, "windows-1252", 1)
	if (kind == "u16le") out = char((255, 254)) + ustrto(t, "UTF-16LE", 1)
	if (kind == "u16be") out = char((254, 255)) + ustrto(t, "UTF-16BE", 1)
	if (fileexists(fn)) unlink(fn)
	fh = fopen(fn, "w")
	fwrite(fh, out)
	fclose(fh)
}
end
foreach kind in bom cp1252 u16le u16be {
	foreach header in 1 0 {
		foreach opt in "" "delimiter(,)" {
			mata: ei_enc(st_local("dir") + "/en_`kind'.csv", "`kind'", `header')
			nwimport "`dir'/en_`kind'.csv", type(edgelist) nwclear `opt'
			qui nwname
			local labs `"`r(labs)'"'
			assert r(nodes) == 3
			foreach w in `=uchar(197) + "sa"' `=uchar(220) + "nal"' `=char(90) + char(111) + uchar(235)' {
				assert strpos(`"`labs'"', "`w'") > 0
			}
			assert ustrlen(`"`labs'"') == 12
			qui nwsummarize
			assert cond(missing(r(arcs)), 0, r(arcs)) + cond(missing(r(edges)), 0, r(edges)) == 2
		}
	}
}

* nwimport.ado can be run again while its Mata functions are in memory
qui findfile nwimport.ado
local ado "`r(fn)'"
qui run "`ado'"
qui run "`ado'"
* an empty or quoted file name is left to insheet (no message from Mata)
mata: assert(nwimp_utf8copy("", "x") == 0)
mata: assert(nwimp_utf8copy(char(34) + "x" + char(34), "x") == 0)
di "PASS 7 commas"

* ---- Pajek *Matrix
ei_file mat.net "*Vertices 3" `"1 "a""' `"2 "b""' `"3 "c""' "*Matrix" "0 1 0" "0 0 2" "1 0 5"
nwimport "`dir'/mat.net", type(pajek) nwclear
ei_net mat 3 true "(0,1,0 \ 0,0,2 \ 1,0,5)" "a,b,c"
ei_file msym.net "*Vertices 3" "*Matrix" "0 1 0" "1 0 1" "0 1 0"
nwimport "`dir'/msym.net", type(pajek) nwclear
ei_net msym 3 false "(0,1,0 \ 1,0,1 \ 0,1,0)"
ei_file mshort.net "*Vertices 3" "*Matrix" "0 1 0" "0 0 1"
capture nwimport "`dir'/mshort.net", type(pajek) nwclear
assert _rc == 6705
ei_net msym 3 false "(0,1,0 \ 1,0,1 \ 0,1,0)"
di "PASS Pajek matrix"

nwclear
clear
di "ALL PASS test_edge_import"
