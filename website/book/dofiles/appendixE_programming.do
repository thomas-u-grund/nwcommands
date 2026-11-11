* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Appendix: Programming with network objects
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom; it was checked against nwcommands 3.18.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Worked example 1: a node-level statistic
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

* ============================================================
* Worked example 2: a command that produces a new network
* ============================================================
program myinverse
    syntax [anything(name=netname)] , [ name(string)]
    _nwsyntax `netname'
    nwtomata `netname', mat(net)
    local name = cond("`name'"=="", "_myinverse", "`name'")
    mata: inverse = (net :== 0)
    nwset, mat(inverse) name("`name'") undirected
    mata: mata drop net inverse
end
nwwebuse florentine, nwclear
myinverse flomarriage, name(flomarriage_inverse)
nwsummarize flomarriage_inverse

* ============================================================
* Worked example 3: a network-level statistic with stored results
* ============================================================
program mydensity2, rclass
    syntax [anything(name=netname)]
    _nwsyntax `netname'
    nwtomata `netname', mat(net)
    mata: st_numscalar("r_edges", sum(net :!= 0 :& net :< .) / 2)
    local e = r_edges
    local n = `nodes'
    local dens2 = `e' / (`n' * (`n' - 1) / 2)
    return scalar edges = `e'
    return scalar nodes = `n'
    return scalar density = `dens2'
end
nwwebuse florentine, nwclear
mydensity2 flomarriage
return list
