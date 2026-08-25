cscript

do unw_core.do

nwclear
nwrandom 5, prob(1) name(net1)
nwrandom 5, prob(0) name(net2)

nwtabulate net1 net2

assert         r(EI_pvalue) == 0
assert         r(EI_index)  == -1
assert         r(c)         == 1
assert         r(r)         == 1
assert         r(N)         == 20

nwreplace net1[1,2] = 0
nwtabulate net1 net2

assert         r(EI_pvalue) == 1
assert reldif( r(EI_index)   , .8999999761581421 ) <  1E-8
assert         r(c)         == 1
assert         r(r)         == 2
assert         r(N)         == 20

qui {
mat T_table = J(2,1,0)
mat T_table[1,1] =                  1
mat T_table[2,1] =                 19
}
matrix C_table = r(table)
assert mreldif( C_table , T_table ) < 1E-8
_assert_streq `"`: rowfullnames C_table'"' `"r1 r2"'
_assert_streq `"`: colfullnames C_table'"' `"c1"'
mat drop C_table T_table

