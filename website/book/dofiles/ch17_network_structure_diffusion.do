* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 17: Network structure and diffusion
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.28.0,
* nwergm 1.10.0, nwsaom 1.8.1, nwrem 1.5.1, nwdynam 1.9.1, nwalaam 1.2.0,
* nwlsm 1.0.0 and nwsbm 1.0.0, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Adoption step by step
* ============================================================
nwclear
set seed 12345
nwsmall 200, k(3) prob(.05) undirected name(sw)
generate byte first = _n == 1
nwcontext sw, attribute(first) stat(max) generate(near)
generate byte group = first | near
nwcontext sw, attribute(group) stat(sum) generate(exposed)
tabulate exposed if !group

program diffuse, rclass
    syntax name(name=net), start(varname) [threshold(integer 1) prob(real 1)]
    if `prob' <= 0 | `prob' > 1 error 198
    capture drop adopted step exposed
    generate byte adopted = `start'
    quietly generate step = 0 if adopted
    local t = 0
    local half = .
    quietly count if adopted
    if r(N) >= _N / 2 local half = 0
    while 1 {
        quietly nwcontext `net', attribute(adopted) stat(sum) ///
            generate(exposed) replace
        quietly count if !adopted & exposed >= `threshold'
        if r(N) == 0 continue, break
        local ++t
        quietly replace step = `t' if !adopted & exposed >= `threshold' ///
            & runiform() < `prob'
        quietly replace adopted = 1 if step == `t'
        quietly count if adopted
        if r(N) >= _N / 2 & `half' == . local half = `t'
    }
    summarize adopted, meanonly
    return scalar share = r(mean)
    return scalar half = `half'
    return scalar steps = `t'
end

* ============================================================
* Simple contagion: one adopting neighbor is enough
* ============================================================
diffuse sw, start(group) threshold(1) prob(.5)
return list
diffuse sw, start(group) threshold(1) prob(1)
return list

* ============================================================
* Complex contagion: adoption needs reinforcement
* ============================================================
diffuse sw, start(group) threshold(2) prob(.5)
return list
diffuse sw, start(group) threshold(3) prob(.5)
return list
diffuse sw, start(first) threshold(2) prob(.5)
return list

* ============================================================
* An experiment across network structures
* ============================================================
program seedgroup
    syntax name(name=net), size(integer) generate(name)
    local i = runiformint(1, _N)
    generate byte `generate' = _n == `i'
    tempvar u near r
    generate double `u' = runiform()
    quietly count if `generate'
    while r(N) < `size' {
        local need = `size' - r(N)
        capture drop `near' `r'
        quietly nwcontext `net', attribute(`generate') stat(max) ///
            generate(`near')
        quietly egen `r' = rank(`u') if `near' == 1 & !`generate', unique
        quietly count if `r' < .
        if r(N) == 0 continue, break
        quietly replace `generate' = 1 if `r' <= `need'
        quietly count if `generate'
    }
end

* setup (not printed in the book):
capture program drop seedgroup
program seedgroup
    syntax name(name=net), size(integer) generate(name) [tries(integer 100)]
    local i = runiformint(1, _N)
    generate byte `generate' = _n == `i'
    tempvar u near r
    generate double `u' = runiform()
    quietly count if `generate'
    while r(N) < `size' {
        local need = `size' - r(N)
        capture drop `near' `r'
        quietly nwcontext `net', attribute(`generate') stat(max) ///
            generate(`near')
        quietly egen `r' = rank(`u') if `near' == 1 & !`generate', unique
        quietly count if `r' < .
        if r(N) == 0 continue, break
        quietly replace `generate' = 1 if `r' <= `need'
        quietly count if `generate'
    }
    quietly count if `generate'
    if r(N) < `size' {
        drop `generate'
        if `tries' == 1 {
            display as error "no starting group of `size' found"
            exit 459
        }
        seedgroup `net', size(`size') generate(`generate') tries(`=`tries' ///
            - 1')
    }
end
program experiment, rclass
    nwclear
    quietly `0' name(g)
    seedgroup g, size(7) generate(group)
    diffuse g, start(group) threshold(1) prob(.5)
    return scalar simple = r(half)
    diffuse g, start(group) threshold(2) prob(.5)
    return scalar complex = r(half)
    return scalar reached = r(share) >= .5
end
frame create results str8 network rewire simple reached complex
set seed 12345
foreach p in 0 .01 .05 .25 1 {
    forvalues r = 1/100 {
        experiment nwsmall 200, k(3) prob(`p') undirected
        frame post results ("nwsmall") (`p') (r(simple)) (r(reached)) ///
            (r(complex))
    }
}
frame change results
collapse (mean) simple reached complex, by(network rewire)
gsort -network rewire
format simple complex %6.1f
format reached %4.2f
list, noobs
