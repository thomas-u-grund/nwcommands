* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 17: Network structure and diffusion
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.35.0,
* nwergm 1.13.0, nwsaom 1.9.1, nwrem 1.7.0, nwdynam 1.11.0, nwalaam 1.4.0,
* nwlsm 1.0.6 and nwsbm 1.0.2, the versions the book was printed with.
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
generate byte group = inlist(_n, 1, 2)
nwcontext sw, attribute(group) stat(sum) generate(exposed)
tabulate exposed if !group

generate byte adopted = group
replace adopted = 1 if exposed >= 1
count if adopted
drop adopted exposed

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
    local i = runiformint(1, _N)
    quietly generate byte first = _n == `i'
    quietly nwcontext g, attribute(first) stat(max) generate(near)
    quietly generate double u = runiform() if near == 1
    quietly egen pick = rank(u), unique
    quietly generate byte group = first | pick == 1
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

* ============================================================
* What a simulated diffusion establishes
* ============================================================
nwwebuse lazega, nwclear
nwsym lazega_adv, mode(max) generate(advsym)
quietly nwdegree advsym, generate(deg)
egen rankdeg = rank(-deg), unique
generate byte hubs = rankdeg <= 3
frame create lawyers str6 seeds half reached
set seed 12345
forvalues k = 1/20 {
    quietly diffuse advsym, start(hubs) threshold(3) prob(.5)
    frame post lawyers ("hubs") (r(half)) (r(share) >= .5)
    generate double u = runiform()
    quietly egen rnd_rank = rank(u), unique
    generate byte rnd = rnd_rank <= 3
    quietly diffuse advsym, start(rnd) threshold(3) prob(.5)
    frame post lawyers ("random") (r(half)) (r(share) >= .5)
    drop u rnd_rank rnd
}
frame lawyers: tabstat half reached, by(seeds) statistics(mean) format(%4.2f)
