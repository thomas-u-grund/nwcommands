* Tutorial 20: Programming with Mata: from Stata networks to Mata and back
* Requires the core nwcommands.

* 1. A network as a Mata matrix
nwwebuse florentine
nwtomata flomarriage, mat(A)
return list
mata: rows(A), cols(A)
mata: rowsum(A)'
mata: A[1..4, 1..4]

* A copy: changing it does not change the network
mata: A[2,1] = 7
nwtomata flomarriage, mat(B)
mata: A[1..3, 1..3], B[1..3, 1..3]
mata: mata drop A B

* 2. A measure of our own, as a small Mata function
mata:
real colvector nw_reach2(real matrix A)
{
    real matrix B
    B = A
    _diag(B, 0)                // no self-ties; the diagonal arrives as missing
    B = ((B + B*B) :> 0)       // tie, or a common partner
    _diag(B, 0)
    return(rowsum(B))          // how many others are within two steps
}
real colvector nw_nbrmean(real matrix A, real colvector x)
{
    real matrix B
    B = A
    _diag(B, 0)
    return((B*x) :/ rowsum(B))  // mean of x over the neighbours (. for an isolate)
}
end

nwtomata flomarriage, mat(A)
mata: nw_reach2(A)'
mata: x = st_data(., "wealth")
mata: nw_nbrmean(A, x)'

* 3. Back to Stata: a node variable, a matrix, a new network
mata: st_store(., st_addvar("double", "reach2"), nw_reach2(A))
mata: st_store(., st_addvar("double", "nbrwealth"), nw_nbrmean(A, x))
list _nwnode wealth reach2 nbrwealth in 1/6
mata: st_matrix("R", nw_reach2(A))
matrix list R

mata: _diag(A, 0)
mata: P = A*A
mata: _diag(P, 0)
_nwsyntax flomarriage
nwset, mat(P) name(paths2) labs(`labs') undirected
nwsummarize paths2
nwtomata flomarriage, mat(A)
mata: _diag(A, 0)
mata: R2 = ((A + A*A) :> 0)
mata: _diag(R2, 0)
nwset, mat(R2) name(floreach2) undirected
nwsummarize floreach2
mata: mata drop A P R2 x

* 4. A reusable command
capture program drop nwreach2
program nwreach2, rclass
    syntax [anything(name=netname)], GENerate(name) [NETwork(name)]
    _nwsyntax `netname'
    _nwdatasync `netname'
    confirm new variable `generate'
    tempname A
    nwtomata `netname', mat(`A')
    quietly generate double `generate' = .
    mata: st_store((1::`nodes'), "`generate'", nw_reach2(`A'))
    if "`network'" != "" {
        mata: _diag(`A', 0)
        mata: `A' = ((`A' + `A'*`A') :> 0)
        mata: _diag(`A', 0)
        local undirected = cond("`directed'" == "false", "undirected", "")
        nwset, mat(`A') name(`network') labs(`labs') `undirected'
    }
    mata: mata drop `A'
    quietly summarize `generate'
    return scalar mean = r(mean)
    return local netname "`netname'"
end

drop reach2
nwreach2 flomarriage, generate(reach2) network(floreach2b)
return list
nwsummarize floreach2b

* 5. Loop over the waves of a longitudinal network
nwwebuse glasgow, nwclear
matrix W = J(3, 1, .)
local i 0
foreach w in glasgow1 glasgow2 glasgow3 {
    local ++i
    nwreach2 `w', generate(reach_`w')
    matrix W[`i', 1] = r(mean)
}
matrix rownames W = glasgow1 glasgow2 glasgow3
matrix colnames W = mean_reach2
matrix list W
summarize reach_*

* 6. Pitfalls
* node order: the dataset is put back in node order by _nwdatasync
nwwebuse florentine, nwclear
sort wealth
list _nwnode wealth in 1/3
_nwdatasync flomarriage
list _nwnode wealth in 1/3

* directed: a row is a sender, a column a receiver
nwwebuse glasgow, nwclear
nwtomata glasgow1, mat(G)
mata: sum(G :!= G')
_nwsyntax glasgow1
display "directed = `directed', valued = `valued', nodes = `nodes'"

* valued: the matrix holds the values, not 0/1
nwwebuse sampson, nwclear
nwsummarize samplike
nwtomata samplike, mat(S)
mata: max(S)
mata: sum(S :> 0)          // 106, not 88
mata: _diag(S, 0)
mata: sum(S :> 0)
mata: mata drop G S

* the diagonal
nwwebuse florentine, nwclear
nwtomata flomarriage, mat(A)
mata: (A*A)[1, 1..3]
mata: _diag(A, 0)
mata: (A*A)[1, 1..3]

* memory
mata: mata describe
