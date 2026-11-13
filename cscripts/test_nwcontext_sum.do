* test_nwcontext_sum: stat(sum) gives the neighbor sum and prints nothing
cscript

do unw_core.do

nwclear
nwset, mat((0,1,0,0,0,1\1,0,1,0,0,0\0,1,0,1,0,0\0,0,1,0,1,0\0,0,0,1,0,1\1,0,0,0,1,0)) name(r) undirected
generate byte a = inlist(_n, 1, 2)
log using "test_nwcontext_sum.txt", text replace name(tns)
nwcontext r, attribute(a) stat(sum) generate(s)
log close tns
* ring 1-2-3-4-5-6-1: neighbors of 1 are 2,6 -> 1; of 2: 1,3 -> 1; of 3: 2,4 -> 1; of 6: 5,1 -> 1; of 4, 5 -> 0
assert s == cond(inlist(_n, 4, 5), 0, 1)
tempname fh
file open `fh' using "test_nwcontext_sum.txt", read text
local n = 0
file read `fh' line
while r(eof) == 0 {
    * a printed Mata matrix has a frame of "+---" and rows with " | "
    if strpos(`"`line'"', "+---") | strpos(`"`line'"', " | ") local ++n
    file read `fh' line
}
file close `fh'
erase "test_nwcontext_sum.txt"
assert `n' == 0
display "test_nwcontext_sum: all passed"
