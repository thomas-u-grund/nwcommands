cscript

clear mata
do unw_core.do
set more off


nwclear
set obs 4
gen v1 = 0
gen v2 = (_n == 3)
gen v3 = (_n < 3)
gen v4 = 0
gen v5 = (_n < 3)

nwset v*, name(netfromvar)
nwneighbor netfromvar, ego(v3)

assert `"`r(ego)'"'         == `"v3"'

assert         r(num_neighbors) == 1
assert         r(egoid)         == 3

mat T_neighbors=                  2
matrix C_neighbors = r(neighbors)
assert mreldif( C_neighbors , T_neighbors ) < 1E-8
_assert_streq `"`: rowfullnames C_neighbors'"' `"r1"'
_assert_streq `"`: colfullnames C_neighbors'"' `"c1"'
mat drop C_neighbors T_neighbors


nwneighbor netfromvar, ego(v3) mode(either)
assert `"`r(ego)'"' == `"v3"'

assert         r(num_neighbors) == 2
assert         r(egoid)         == 3

qui {
mat T_neighbors = J(2,1,0)
mat T_neighbors[1,1] =                  1
mat T_neighbors[2,1] =                  2
}
matrix C_neighbors = r(neighbors)
assert mreldif( C_neighbors , T_neighbors ) < 1E-8
_assert_streq `"`: rowfullnames C_neighbors'"' `"r1 r2"'
_assert_streq `"`: colfullnames C_neighbors'"' `"c1"'
mat drop C_neighbors T_neighbors

nwneighbor netfromvar, ego(v3) mode(either) generate(x)
assert x[1] == 1


* mode(incoming): sparse-migration bugfix regression coverage. The prior
* dense-matrix implementation had a stray unbalanced paren in this exact
* branch - a genuine Mata syntax error, so "incoming" could never have
* actually run before. Directed: A->B, A->C, B->C (A=1,B=2,C=3).
nwclear
nwset, mat((0,1,1\0,0,1\0,0,0)) name(dirnet) directed labs(A,B,C)

* outgoing(A) = {B,C}
nwneighbor dirnet, ego(A)
assert r(num_neighbors) == 2
mat T_out = J(2,1,0)
mat T_out[1,1] = 2
mat T_out[2,1] = 3
matrix C_out = r(neighbors)
assert mreldif(C_out, T_out) < 1E-8
mat drop C_out T_out

* incoming(C) = {A,B} (both A and B point to C)
nwneighbor dirnet, ego(C) mode(incoming)
assert r(num_neighbors) == 2
mat T_in = J(2,1,0)
mat T_in[1,1] = 1
mat T_in[2,1] = 2
matrix C_in = r(neighbors)
assert mreldif(C_in, T_in) < 1E-8
mat drop C_in T_in

* incoming(A) = {} (nobody points to A)
nwneighbor dirnet, ego(A) mode(incoming)
assert r(num_neighbors) == 0

* either(B): outgoing {C}, incoming {A} -> union {A,C}
nwneighbor dirnet, ego(B) mode(either)
assert r(num_neighbors) == 2
mat T_eith = J(2,1,0)
mat T_eith[1,1] = 1
mat T_eith[2,1] = 3
matrix C_eith = r(neighbors)
assert mreldif(C_eith, T_eith) < 1E-8
mat drop C_eith T_eith

* generate() indicator variable, incoming mode
nwneighbor dirnet, ego(C) mode(incoming) generate(inc)
assert inc[1] == 1
assert inc[2] == 1
assert inc[3] == 0




