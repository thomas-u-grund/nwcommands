* Tutorial 21: Reading networks in Mata with the nwapi functions
* Requires the core nwcommands 3.24 or later.

* 1. What is in memory
nwwebuse florentine, nwclear
mata: nwapi_version()
mata: nwapi_count()
mata: nwapi_names()'
mata: nwapi_current()
mata: nwapi_exists("flomarriage"), nwapi_exists("nonet")
mata: nwapi_nodes("flomarriage"), nwapi_ties("flomarriage")
mata: nwapi_directed("flomarriage"), nwapi_valued("flomarriage"), nwapi_twomode("flomarriage")
mata: nwapi_nodes(), nwapi_ties()
mata: lab = nwapi_nodelabels("flomarriage")
mata: lab[1..5]'

* 2. Reading the ties
mata: A = nwapi_matrix("flomarriage")
mata: rows(A), cols(A)
mata: A[1..4, 1..4]
mata: hasmissing(A)
mata: A = nwapi_matrix("flomarriage")
mata: A[2,1] = 7
mata: B = nwapi_matrix("flomarriage")
mata: A[1..3, 1..3], B[1..3, 1..3]
mata: mata drop A B

mata: E = nwapi_edgelist("flomarriage")
mata: rows(E), cols(E)
mata: E[1..5, .]
mata: nwapi_outdegree("flomarriage")'
mata: nwapi_outdegree("flomarriage") == nwapi_indegree("flomarriage")
mata: id = nwapi_nodeid("flomarriage", "medici")
mata: id
mata: nb = nwapi_neighbors("flomarriage", id)
mata: nb'
mata: lab[nb]'
mata: lab[nwapi_neighbors("flomarriage", "medici")]'
mata: mata drop E id nb lab

* directed networks: out- and in-neighbors
nwwebuse glasgow, nwclear
mata: nwapi_directed("glasgow1"), nwapi_nodes("glasgow1"), nwapi_ties("glasgow1")
mata: nwapi_neighbors("glasgow1", 1)'
mata: nwapi_inneighbors("glasgow1", 1)'
mata: nwapi_outdegree("glasgow1")'[1..10]
mata: nwapi_indegree("glasgow1")'[1..10]

* valued networks: the matrix holds the values, the degrees count the ties
nwwebuse sampson, nwclear
mata: nwapi_valued("samplike")
mata: A = nwapi_matrix("samplike")
mata: max(A)
mata: sum(A :> 0)
mata: nwapi_ties("samplike")
nwtomata samplike, mat(S)
mata: sum(S :> 0)
mata: mata drop A S

* 3. Looping over the networks in memory
nwwebuse glasgow, nwclear
set seed 2111
nwrandom 30, prob(.1) undirected name(random30)
mata:
void nwt_table()
{
    real scalar i, n, m, dens
    string colvector names
    string scalar nm

    names = nwapi_names()
    printf("{txt}%-14s %6s %6s  %-10s %7s\n", "network", "nodes", "ties", "type", "density")
    for (i = 1; i <= rows(names); i++) {
        nm = names[i]
        n = nwapi_nodes(nm)
        m = nwapi_ties(nm)
        dens = m / (nwapi_directed(nm) ? n*(n-1) : n*(n-1)/2)
        printf("{res}%-14s %6.0f %6.0f  %-10s %7.3f\n", nm, n, m,
            nwapi_directed(nm) ? "directed" : "undirected", dens)
    }
}
end
mata: nwt_table()

* 4. A measure of your own
mata:
// how many other nodes are reached in at most two steps (matrix version)
real colvector nwt_reach2(string scalar net)
{
    real matrix A, R

    A = nwapi_matrix(net)
    R = ((A + A*A) :> 0)
    _diag(R, 0)
    return(rowsum(R))
}
// the mean of x over the neighbors of every node; missing for an isolate (works for large networks)
real colvector nwt_nbrmean(string scalar net, real colvector x)
{
    real scalar i, n
    real colvector out, nb

    n = nwapi_nodes(net)
    out = J(n, 1, .)
    for (i = 1; i <= n; i++) {
        nb = nwapi_neighbors(net, i)
        if (rows(nb) > 0) out[i] = mean(x[nb])
    }
    return(out)
}
end
nwwebuse florentine, nwclear
mata: nwt_reach2("flomarriage")'
mata: x = st_data(., "wealth")
mata: nwt_nbrmean("flomarriage", x)'

* 5. Back to Stata: variables, matrices, a new network
mata: st_store(., st_addvar("double", "reach2"), nwt_reach2("flomarriage"))
mata: st_store(., st_addvar("double", "nbrwealth"), nwt_nbrmean("flomarriage", x))
list _nwnode wealth reach2 nbrwealth in 1/6
mata: st_matrix("R", nwt_reach2("flomarriage"))
matrix list R
mata: st_numscalar("meanreach", mean(nwt_reach2("flomarriage")))
display meanreach
mata:
P = nwapi_matrix("flomarriage")
P = P*P
_diag(P, 0)
end
mata: st_local("labs", invtokens(nwapi_nodelabels("flomarriage")', ","))
nwset, mat(P) name(paths2) labs(`labs') undirected
nwsummarize paths2
mata: mata drop P x

* 6. A reusable command
capture program drop nwnbrwealth
program nwnbrwealth
    syntax [anything(name=netname)], GENerate(name) VARiable(varname numeric)
    _nwsyntax `netname'
    _nwdatasync `netname'
    confirm new variable `generate'
    quietly generate double `generate' = .
    mata: st_store(., "`generate'", nwt_nbrmean(st_local("netname"), st_data(., "`variable'")))
end
nwwebuse florentine, nwclear
nwnbrwealth flomar, generate(nw1) variable(wealth)
nwnbrwealth flomarriage, generate(nw2) variable(wealth)
list _nwnode wealth nw1 nw2 in 1/4

* 7. Guarding against old versions and errors
capture mata: nwapi_version()
display _rc
mata: assert(nwapi_version() >= 1)
capture noisily mata: nwapi_nodes("friends")
display _rc
capture noisily mata: nwapi_neighbors("flomarriage", "nobody")
display _rc
capture noisily mata: nwapi_neighbors("flomarriage", 99)
display _rc
capture noisily mata: nwapi_neighbors("flomarriage", 1.5)
display _rc

* 8. Large networks
clear
quietly set obs 25000
generate long a = _n
generate long b = mod(_n, 25000) + 1
nwset a b, edgelist name(ring) undirected
mata: nwapi_nodes("ring"), nwapi_ties("ring")
mata: E = nwapi_edgelist("ring")
mata: E[1..3, .]
mata: E[rows(E), .]
mata: d = nwapi_outdegree("ring")
mata: min(d), max(d)
mata: nwapi_neighbors("ring", 1)'
capture noisily mata: A = nwapi_matrix("ring")
display _rc
mata: mata drop E d
