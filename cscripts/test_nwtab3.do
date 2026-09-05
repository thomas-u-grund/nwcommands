cscript

do unw_core.do

nwclear
nwrandom 5, prob(1) name(net1)
nwreplace net1[1,2] = 0

gen x = (_n > 2)

nwtabulate net1, attribute(x)

assert         r(EI_pvalue) == 0
assert reldif( r(EI_index)   , .2631579041481018 ) <  1E-8
assert         r(c)         == 2
assert         r(r)         == 2
assert         r(N)         == 19

qui {
mat T_row = J(2,1,0)
mat T_row[2,1] =                  1
}
matrix C_row = r(row)
assert mreldif( C_row , T_row ) < 1E-8
_assert_streq `"`: rowfullnames C_row'"' `"r1 r2"'
_assert_streq `"`: colfullnames C_row'"' `"c1"'
mat drop C_row T_row

qui {
mat T_col = J(1,2,0)
mat T_col[1,2] =                  1
}
matrix C_col = r(col)
assert mreldif( C_col , T_col ) < 1E-8
_assert_streq `"`: rowfullnames C_col'"' `"r1"'
_assert_streq `"`: colfullnames C_col'"' `"c1 c2"'
mat drop C_col T_col

qui {
mat T_table = J(2,2,0)
mat T_table[1,1] =                  1
mat T_table[1,2] =                  6
mat T_table[2,1] =                  6
mat T_table[2,2] =                  6
}
matrix C_table = r(table)
assert mreldif( C_table , T_table ) < 1E-8
_assert_streq `"`: rowfullnames C_table'"' `"r1 r2"'
_assert_streq `"`: colfullnames C_table'"' `"c1 c2"'
mat drop C_table T_table

* moderate-severity pass, information_census group: r(netname1)/
* r(netname2) were copy-pasted from nwtab2 (the network+network branch)
* but nwtab3 (this, the network+attribute branch) never defines net1'/
* net2' in its own scope - both always came back missing. Replaced with
* this program's own r(netname)/r(attribute).
nwclear
nwrandom 5, prob(1) name(net1)
nwreplace net1[1,2] = 0
gen x = (_n > 2)
nwtabulate net1, attribute(x)
assert `"`r(netname)'"' == "net1"
assert `"`r(attribute)'"' == "x"
di "=== r(netname)/r(attribute) REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own error 482, before nwtabulate ever looks at
* attribute() - reached through the public nwtabulate() dispatcher
* (nwtab3 is a companion program inside nwtabulate.ado, not
* independently callable - see test_nwtab1.do's own note on this).
* (attribute() itself has no separately reachable "required" failure
* via the public interface: an empty attribute() is valid Stata syntax,
* treated as "not given", not rejected - and nwtabulate's own dispatch
* logic only ever calls nwtab3 once a real attribute() value is
* already confirmed present, so nwtab3's own required-option guard is
* unreachable from outside, the same as nwtab2's inner min/max check.)
capture noisily nwtabulate nonexistent, attribute(x)
assert _rc == 482
