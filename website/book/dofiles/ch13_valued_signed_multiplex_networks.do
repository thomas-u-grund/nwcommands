* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 13: Valued, signed, and multiplex networks
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
* Multiplexity: overlap between relations
* ============================================================
nwwebuse lazega, nwclear
nwsummarize lazega_fr
nwsummarize lazega_cow
nwtabulate lazega_adv lazega_fr

nwgen nrel = lazega_adv + lazega_cow + lazega_fr
nwtabulate nrel
nwcorrelate lazega_adv lazega_fr
nwcorrelate lazega_adv lazega_cow
nwcorrelate lazega_cow lazega_fr

* ============================================================
* Tie strength and the choice to dichotomize
* ============================================================
nwwebuse gang, nwclear
nwsummarize gang_valued
nwtabulate gang_valued

nwrecode gang_valued (1 2 = 1) (3/4 = 2), generate(intensity)
nwsummarize intensity
nwtabulate intensity

nwbetween gang_valued, binary generate(_between_binary)
nwbetween gang_valued, generate(_between_weighted)
correlate _between_binary _between_weighted
gsort -_between_binary
list _nwnode _between_binary _between_weighted in 1/8, clean

nwwebuse chesapeake, nwclear
nwsummarize chesapeake
summarize Biomass
quietly nwdegree chesapeake, binary generate(_outcount _incount)
summarize _outcount _incount

quietly nwdegree chesapeake, generate(_outflow _inflow)
summarize _outflow _inflow
gsort -_outflow
list _nwnode Biomass _outflow _inflow in 1/5, clean

* ============================================================
* Signed ties and structural balance
* ============================================================
nwwebuse gahuku, nwclear
nwsummarize gahuku
nwbalance gahuku

nwrecode gahuku (-1 = 0) (1 = 1), generate(gpos)
nwrecode gahuku (1 = 0) (-1 = 1), generate(gneg)
nwbalance gneg

nwdegree gpos, generate(pos) silent
nwdegree gneg, generate(neg) silent
generate net = pos - neg
gsort -net _nwnode
list _nwnode pos neg net, clean

set seed 42
nwplot gahuku, label(_nwnode) scheme(s1network) edgefactor(1.6) ///
    labelopt(mlabsize(small)) xsize(6) ysize(5)

nwwebuse senate114, nwclear
nwbalance senate114
generate byte republican = (party == "R")
nwrecode senate114 (-1 = 0) (1 = 1), generate(spos)
nwrecode senate114 (1 = 0) (-1 = 1), generate(sneg)
nwtabulate spos, attribute(republican)
nwtabulate sneg, attribute(republican)
nwbalance sneg

nwwebuse senate93, nwclear
nwbalance senate93
generate byte republican = (party == "R")
nwrecode senate93 (-1 = 0) (1 = 1), generate(spos)
nwrecode senate93 (1 = 0) (-1 = 1), generate(sneg)
nwtabulate spos, attribute(republican)
nwtabulate sneg, attribute(republican)
nwbalance sneg

capture program drop randbal
program randbal, rclass
    args tie n p
    capture nwdrop _u _s
    quietly nwrandom `n', density(`p') undirected name(_u)
    quietly nwgen _s = `tie' * (2 * _u - 1)
    quietly nwbalance _s
    return scalar balance = r(balance)
end
capture program drop signnull
program signnull
    args net reps seed
    quietly nwbalance `net'
    local obs = r(balance)
    capture nwdrop _pos _tie
    quietly nwrecode `net' (-1 = 0) (1 = 1), generate(_pos)
    quietly nwrecode `net' (-1 = 1) (1 = 1), generate(_tie)
    quietly nwsummarize _pos
    local npos = r(edges)
    local n = r(nodes)
    quietly nwsummarize _tie
    local p = `npos' / r(edges)
    local cmd randbal _tie `n' `p'
    local opt reps(`reps') seed(`seed') nodots
    preserve
    quietly simulate bal = r(balance), `opt': `cmd'
    quietly summarize bal
    local mean = r(mean)
    local sd = r(sd)
    quietly count if bal >= `obs'
    local k = r(N)
    local formula = (1 + (2 * `p' - 1)^3) / 2
    display "share of ties that are positive:  " %5.3f `p'
    display "share balanced, observed:         " %5.3f `obs'
    display "share balanced, random signs:     " %5.3f `mean'
    display "  standard deviation over draws:  " %5.3f `sd'
    display "  draws at least as balanced:     " `k' " of `reps'"
    display "share expected by the formula:    " %5.3f `formula'
    restore
end

nwwebuse gahuku, nwclear
signnull gahuku 500 1
nwwebuse senate114, nwclear
signnull senate114 500 1
nwwebuse senate93, nwclear
signnull senate93 500 1
