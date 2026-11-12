// nwfromedge: a name() already in use is refused before the data are changed (string ids took a route that dropped the data first)
clear all
nwclear
// network "net" exists
nwrandom 5, prob(.5) name(net)
// a string edge list
clear
input str5 a str5 b
"x" "y"
"y" "z"
"z" "w"
end
tempfile el
save `el'
// string ids, name in use, no replace: error 483 and the edge list is still there
capture nwfromedge a b, name(net)
assert _rc == 483
assert _N == 3
confirm string variable a b
assert a[1] == "x" & b[3] == "w"
// numeric ids: same
clear
input a b
1 2
2 3
end
capture nwfromedge a b, name(net)
assert _rc == 483
assert _N == 2
// with replace it works and the network has the new nodes
use `el', clear
nwfromedge a b, name(net) replace
nwsummarize net
assert r(nodes) == 4
// two-mode: replace is passed on
clear
input a b
1 1
2 1
end
nwfromedge a b, name(tm) twomode
clear
input a b
1 1
2 2
end
capture nwfromedge a b, name(tm) twomode
assert _rc == 483
assert _N == 2
nwfromedge a b, name(tm) twomode replace
di "ALL PASS"
