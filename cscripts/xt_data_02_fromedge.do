* xt_data_02_fromedge.do
* Extended tests of nwfromedge and nwset ..., edgelist: numeric and string ids must give the same network,
* duplicate rows, isolates (row with a missing other id), rows with both ids missing, self-ties, tie values
* (negative, zero, non-integer, missing), direction detection and the direction options, if, labs() and
* labprefix(), noclear, ids that are negative, non-integer, mixed numeric/string, padded with blanks or
* non-ASCII, order of the rows, name() in use (data and networks unchanged), 2,000-node edge lists.
* All expected numbers are derived by hand; no number comes from a run.
clear all
set more off
run cscripts/xt_data_00_helpers.do
xt_init xt_data_02_fromedge
set seed 20261112
nwclear

* --- A. numeric and string ids give the same network; isolate rows; both-missing rows ignored
clear
input a b
1 2
2 3
3 1
4 .
. .
end
nwfromedge a b, name(num)
clear
input str5 a str5 b
"a" "b"
"b" "c"
"c" "a"
"d" ""
"" ""
end
nwfromedge a b, name(str)
quietly nwname num
xt_chk `=(r(nodes) == 4)' "numeric ids: isolate row gives a 4th node, both-missing row ignored (got `r(nodes)')"
quietly nwname str
xt_chk `=(r(nodes) == 4)' "string ids: isolate row gives a 4th node, both-missing row ignored (got `r(nodes)')"
xt_chk `=("`r(labs)'" == "a,b,c,d")' "string ids: labels a,b,c,d (got `r(labs)')"
xt_mat num __xt_A
xt_mat str __xt_B
mata: st_local("ok", strofreal(__xt_A == __xt_B))
xt_chk `ok' "numeric and string ids: same matrix"
mata: st_local("s", strofreal(sum(__xt_A)))
xt_chk `=("`s'" == "3")' "3-cycle: 3 arcs (got `s')"
di "PASS A ids"

* --- B. duplicate rows: numeric and string ids must agree on which value is kept
clear
input a b v
1 2 5
1 2 3
end
nwfromedge a b v, name(dupn)
clear
input str1 a str1 b v
"x" "y" 5
"x" "y" 3
end
nwfromedge a b v, name(dups)
nwtomata dupn, mat(__xt_A)
nwtomata dups, mat(__xt_B)
mata: st_local("vn", strofreal(__xt_A[1,2])); st_local("vs", strofreal(__xt_B[1,2]))
di as txt "  duplicate (1,2): numeric ids keep `vn', string ids keep `vs'"
xt_chk `=("`vn'" == "`vs'")' "duplicate rows: numeric ids (last row wins) and string ids (collapse max) keep the same value (got `vn' and `vs')" // was bug S6 (fixed)
di "PASS B duplicates"

* --- C. tie values: negative, zero, non-integer, missing
clear
input a b v
1 2 -2
2 3 0
3 1 .5
1 3 .
end
nwfromedge a b v, name(vals)
quietly nwname vals
xt_chk `=(r(nodes) == 3 & "`r(valued)'" == "true")' "value variable: 3 nodes, valued"
nwtomata vals, mat(__xt_V)
mata: st_local("ok", strofreal(__xt_V[1,2] == -2 & __xt_V[3,1] == .5 & __xt_V[2,3] == 0))
xt_chk `ok' "negative and non-integer values kept, a 0 row is no tie"
mata: st_local("m13", strofreal(__xt_V[1,3]))
xt_chk `=("`m13'" == ".")' "[policy] a row with a missing value gives a missing cell, not 0 or 1 (got `m13')"
clear
input a b v
1 2 1
2 1 1
end
nwfromedge a b v, name(allone)
quietly nwname allone
xt_chk `=("`r(valued)'" == "true")' "value variable with all values 1: valued (help)"
clear
input a b v
1 2 4
2 1 4
end
nwfromedge a b v, name(unv) unvalued
quietly nwname unv
xt_chk `=("`r(valued)'" == "false")' "unvalued: binary flag although a value variable is given"
di "PASS C values"

* --- D. self-ties
clear
input a b
1 1
1 2
end
nwfromedge a b, name(loop)
nwtomata loop, mat(__xt_L)
quietly nwname loop
local sl "`r(selfloop)'"
mata: st_local("d11", strofreal(__xt_L[1,1]))
xt_chk `=("`d11'" != "1" | "`sl'" == "true")' "a self-tie row is dropped or the network is marked selfloop (cell `d11', selfloop `sl')"
di "PASS D self-ties"

* --- E. direction: detection and options
clear
input a b
1 2
2 1
2 3
3 2
end
tempfile elsym
save `elsym'
nwfromedge a b, name(det)
quietly nwname det
xt_chk `=("`r(directed)'" == "false")' "both directions listed: detected as undirected"
use `elsym', clear
nwfromedge a b, name(fd) directed
quietly nwname fd
xt_chk `=("`r(directed)'" == "true")' "option directed sticks on a symmetric list"
clear
input a b v
1 2 1
2 1 3
end
nwfromedge a b v, name(umax) undirected
xt_mat umax __xt_A
mata: st_local("ok", strofreal(__xt_A[1,2] == 3 & __xt_A[2,1] == 3))
xt_chk `ok' "undirected with two different values: the larger value is kept (help)"
clear
input a b v
1 2 -1
end
nwfromedge a b v, name(uneg) undirected
xt_mat uneg __xt_A
mata: st_local("ok", strofreal(__xt_A[1,2] == -1 & __xt_A[2,1] == -1))
xt_chk `ok' "undirected, a negative tie listed once keeps its sign (help)"
use `elsym', clear
xt_snap e1
capture noisily nwfromedge a b, name(both) directed undirected
xt_chk `=(_rc == 198)' "[policy] directed and undirected together refused with 198 (got `=_rc')"
if _rc == 0 {
	xt_hasnet both
	if `has' nwdrop both
	use `elsym', clear
}
use `elsym', clear
capture noisily nwfromedge a b, name(both2) forcedirected forceundirected
xt_chk `=(_rc == 198)' "[policy] forcedirected and forceundirected together refused with 198 (got `=_rc')"
if _rc == 0 {
	xt_hasnet both2
	if `has' nwdrop both2
	use `elsym', clear
}
use `elsym', clear
capture noisily nwfromedge a b, name(tmdir) twomode directed
xt_chk `=(_rc == 198)' "twomode with directed refused with 198 (got `=_rc')"
xt_same e1 "twomode with directed"
di "PASS E direction"

* --- F. if, and name() in use: data and networks unchanged
clear
input a b k
1 2 1
2 3 1
3 4 0
end
tempfile elif
save `elif'
nwfromedge a b if k == 1, name(sub)
quietly nwname sub
xt_chk `=(r(nodes) == 3)' "if: nodes only from the rows kept (3, got `r(nodes)')"
clear
input str6 a str6 b v
"Anna" "Bob" 2
"Bob" "Carl" -1
end
tempfile elstr
save `elstr'
xt_snap f1
capture noisily nwfromedge a b v if v > 0, name(sub)
xt_chk `=(_rc == 483)' "string ids, value and if, name() in use: r(483) (got `=_rc')"
xt_same f1 "string ids, value and if, name() in use"
use `elif', clear
xt_snap f2
capture noisily nwfromedge a b if k == 1, name(sub)
xt_chk `=(_rc == 483)' "numeric ids with if, name() in use: r(483) (got `=_rc')"
xt_same f2 "numeric ids with if, name() in use"
use `elif', clear
nwfromedge a b if k == 1, name(sub) replace
quietly nwname sub
xt_chk `=(r(nodes) == 3)' "replace: the network is rebuilt"
* default name: the value variable, then v_1
use `elstr', clear
nwfromedge a b v
xt_hasnet v
xt_chk `has' "no name(): the network is named after the value variable"
use `elstr', clear
nwfromedge a b v
xt_hasnet v_1
xt_chk `has' "no name(), v in use: v_1"
di "PASS F if and names"

* --- G. labs() and labprefix()
clear
input a b
1 2
2 3
end
tempfile el3
save `el3'
nwfromedge a b, name(lb1) labs(x,y,z)
quietly nwname lb1
xt_chk `=("`r(labs)'" == "x,y,z")' "labs(x,y,z)"
use `el3', clear
nwfromedge a b, name(lb2) labs(x y z)
quietly nwname lb2
xt_chk `=("`r(labs)'" == "x,y,z")' "labs(x y z) as the help writes it (lab1 lab2 ...) gives x,y,z (got `r(labs)')" // was bug S8 (help and code disagree) (fixed)
use `el3', clear
nwfromedge a b, name(lb3) labprefix(p)
quietly nwname lb3
xt_chk `=("`r(labs)'" == "p1,p2,p3")' "labprefix(p): p1,p2,p3 (got `r(labs)')"
use `el3', clear
capture noisily nwset a b, edgelist keeporiginal name(ko)
xt_chk `=(_rc == 0)' "nwset ..., edgelist keeporiginal is accepted (nwfromedge does not declare keeporiginal; got `=_rc')" // was bug S5 (fixed)
capture confirm numeric variable _nodeoriginal, exact
xt_chk `=(_rc == 0)' "keeporiginal: numeric _nodeoriginal created"
if _rc == 0 {
	quietly count if _nodeoriginal == real(substr(_nwnode, 2, .)) & _nwnode != ""
	xt_chk `=(r(N) == 3)' "keeporiginal: _nodeoriginal holds the original id of each node (`r(N)' of 3)"
}
* selfloop keeps the ties of a node with itself
clear
input a b
1 1
1 2
end
nwfromedge a b, name(sl) selfloop
nwtomata sl, mat(__xt_A)
mata: st_local("ok", strofreal(__xt_A[1,1] == 1))
xt_chk `ok' "nwfromedge, selfloop: the diagonal tie is kept"
di "PASS G labels"

* --- H. noclear keeps the data as they were
clear
input a b z
10 20 7
20 30 8
end
nwfromedge a b, name(nc) noclear
quietly summarize a
local sa = r(sum)
quietly summarize b
local sb = r(sum)
quietly summarize z
local sz = r(sum)
xt_chk `=(`sz' == 15)' "noclear: the other variable is kept (sum 15, got `sz')"
xt_chk `=(`sa' == 30 & `sb' == 50)' "noclear: the id variables are not overwritten (sums 30 and 50, got `sa' and `sb')" // was bug S7 (fixed)
quietly nwname nc
xt_chk `=(r(nodes) == 3)' "noclear: network of 3 nodes"
di "PASS H noclear"

* --- I. unusual ids
clear
input a b
1.5 2.5
end
nwfromedge a b, name(frac)
quietly nwname frac
xt_chk `=(r(nodes) == 2)' "non-integer ids: 2 nodes"
clear
input a b
-1 0
0 1
end
nwfromedge a b, name(neg)
quietly nwname neg
xt_chk `=(r(nodes) == 3 & "`r(labs)'" == "n-1,n0,n1")' "negative ids: 3 nodes n-1,n0,n1 (got `r(labs)')"
clear
input a str3 b
1 "x"
2 "y"
end
nwfromedge a b, name(mix)
quietly nwname mix
mata: st_local("ok", strofreal(xt_sorteq(st_global("r(labs)"), "1,2,x,y")))
xt_chk `=(r(nodes) == 4 & "`ok'" == "1")' "numeric ego, string alter: nodes 1,2,x,y (got `r(labs)')"
clear
input str4 a str4 b
" a" "b"
"a " "b"
end
nwfromedge a b, name(blank)
quietly nwname blank
xt_chk `=(r(nodes) == 2)' "ids with leading/trailing blanks are trimmed: 2 nodes (got `r(nodes)')"
clear
input str12 a str12 b
"Anna Maria" "Zoë"
"Zoë" "Ünal"
end
nwfromedge a b, name(uni)
quietly nwname uni
mata: st_local("ok", strofreal(xt_sorteq(st_global("r(labs)"), "Anna Maria,Zoë,Ünal")))
xt_chk `ok' "labels with a blank and non-ASCII letters kept (got `r(labs)')"
di "PASS I ids"

* --- J. the order of the rows does not matter
nwclear
nwrandom 15, prob(.3) name(src)
nwtoedge src, compress
keep if src < . & src != 0
drop src
tempfile ord
save `ord'
nwfromedge _ego _alter, name(o1) directed
use `ord', clear
gen double __u = runiform()
sort __u
drop __u
nwfromedge _ego _alter, name(o2) directed
quietly nwname o1
local l1 `"`r(labs)'"'
quietly nwname o2
xt_chk `=(`"`r(labs)'"' == `"`l1'"')' "shuffled rows: same labels in the same order"
xt_mat o1 __xt_A
xt_mat o2 __xt_B
mata: st_local("ok", strofreal(__xt_A == __xt_B))
xt_chk `ok' "shuffled rows: same matrix"
di "PASS J order"

* --- K. 2,000-node edge lists, numeric and string ids
nwclear
set obs 2000
gen long a = _n
gen long b = mod(_n, 2000) + 1
nwfromedge a b, name(bign)
quietly nwname bign
xt_chk `=(r(nodes) == 2000 & "`r(directed)'" == "true")' "2,000-node cycle, numeric ids: 2,000 nodes, directed"
xt_mat bign __xt_A
mata: st_local("s", strofreal(sum(__xt_A)))
xt_chk `=("`s'" == "2000")' "2,000-node cycle: 2,000 arcs (got `s')"
clear
set obs 2000
gen str8 a = "v" + string(_n)
gen str8 b = "v" + string(mod(_n, 2000) + 1)
nwfromedge a b, name(bigs)
quietly nwname bigs
xt_chk `=(r(nodes) == 2000)' "2,000-node cycle, string ids: 2,000 nodes"
xt_mat bigs __xt_B
mata: st_local("s", strofreal(sum(__xt_B)))
xt_chk `=("`s'" == "2000")' "2,000-node cycle, string ids: 2,000 arcs (got `s')"
mata: st_local("ok", strofreal(sort(rowsum(__xt_A), 1) == sort(rowsum(__xt_B), 1) & sort(colsum(__xt_A)', 1) == sort(colsum(__xt_B)', 1)))
xt_chk `ok' "numeric and string ids: same degree sequences"
di "PASS K big"

capture mata: mata drop __xt_A __xt_B __xt_V __xt_L
xt_end
di "ALL PASS"
