* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Appendix: Programming with networks in Mata
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.26.0,
* nwergm 1.8.0, nwsaom 1.8.0, nwrem 1.5.0 and nwdynam 1.9.0, the versions the
* book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* The second way: the nwapi functions
* ============================================================
nwwebuse florentine, nwclear
mata:
    A   = nwapi_matrix("flomarriage")
    n   = nwapi_nodes("flomarriage")
    lab = nwapi_nodelabels("flomarriage")
    nb  = nwapi_neighbors("flomarriage", "medici")
    sum(A) / (n*(n-1))                           // density
    invtokens(lab[nb]')                          // Medici's marriage partners
    trace(A*A*A) / 6                             // triangles
end

* ============================================================
* Writing a command
* ============================================================
program myindegree
    syntax [anything(name=netname)] , [ generate(string)]
    _nwsyntax `netname'
    nwtomata `netname', mat(net)
    local generate = cond("`generate'"=="", "_myindegree", "`generate'")
    mata: indegree = colsum(net)'
    getmata `generate' = indegree, force
    mata: mata drop indegree net
end

nwwebuse florentine, nwclear
myindegree flomarriage, generate(myindegree_flomarriage)
list _nwnode myindegree_flomarriage in 1/5

program myindegree2
    syntax [anything(name=netname)] , [ generate(string)]
    _nwsyntax `netname'
    local generate = cond("`generate'"=="", "_myindegree", "`generate'")
    mata: st_store((1::`nodes'), st_addvar("double", "`generate'"), ///
        nwapi_indegree("`netname'"))
end

program myinverse
    syntax [anything(name=netname)] , [ name(string)]
    _nwsyntax `netname'
    nwtomata `netname', mat(net)
    local name = cond("`name'"=="", "_myinverse", "`name'")
    mata: inverse = (net :== 0)
    nwset, mat(inverse) name("`name'") undirected
    mata: mata drop net inverse
end
myinverse flomarriage, name(flomarriage_inverse)
nwsummarize flomarriage_inverse
