* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 16: Generating networks from attributes and tie probabilities
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.34.0,
* nwergm 1.12.0, nwsaom 1.9.1, nwrem 1.7.0, nwdynam 1.11.0, nwalaam 1.3.1,
* nwlsm 1.0.5 and nwsbm 1.0.2, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Tie probabilities for every pair
* ============================================================
nwwebuse lazega, nwclear
nwexpand practice, name(samepractice)
nwgen blockprob = .01 + .07 * samepractice
set seed 12345
nwdyadprob blockprob, name(blocks)
quietly nwsummarize blocks, detail
display "arcs " r(arcs) ", density " %5.3f r(density)
quietly nwmixing blocks, attribute(practice) permutations(1)
display "E-I index by practice: " %6.3f r(EI_index)
nwplot blocks, color(practice) symbol(practice) legendopt(off)

* ============================================================
* Homophily networks
* ============================================================
set seed 12345
quietly nwhomophily practice, density(.05) homophily(3) name(plus3)
set seed 12345
quietly nwhomophily practice, density(.05) homophily(-3) name(minus3)
quietly nwmixing plus3, attribute(practice) permutations(1)
display "homophily(3):   E-I index = " %6.3f r(EI_index)
quietly nwmixing minus3, attribute(practice) permutations(1)
display "homophily(-3):  E-I index = " %6.3f r(EI_index)
nwplot plus3, color(practice) title("homophily(3)") legendopt(off) ///
    name(hplus, replace)
nwplot minus3, color(practice) title("homophily(-3)") legendopt(off) ///
    name(hminus, replace)
graph combine hplus hminus, cols(2) scheme(s1network) xsize(8) ysize(4)

* ============================================================
* Does the measure recover what was built in?
* ============================================================
frame create rec homophily ei
set seed 12345
foreach h in 0 .5 1 2 3 {
    forvalues k = 1/20 {
        quietly nwhomophily practice, density(.179) homophily(`h') name(tmp)
        quietly nwmixing tmp, attribute(practice) permutations(1)
        frame post rec (`h') (r(EI_index))
        nwdrop tmp
    }
}
frame rec: collapse (mean) mean=ei (min) min=ei (max) max=ei, by(homophily)
frame rec: format mean min max %6.3f
frame rec: list, noobs

* ============================================================
* All the attributes at once
* ============================================================
nwexpand office, name(sameoffice)
nwexpand partner, mode(sender) name(frompartner)
nwexpand partner, mode(receiver) name(topartner)
nwexpand seniority, mode(absdist) name(senioritygap)
preserve
nwtoedge lazega_adv samepractice sameoffice frompartner topartner senioritygap
drop if _ego == _alter
logit lazega_adv samepractice sameoffice frompartner topartner ///
    senioritygap, nolog
predict p
nwfromedge _ego _alter p, name(attrprob)
restore

frame create attr reciprocity transitivity ei_office ei_practice
set seed 12345
forvalues r = 1/20 {
    quietly nwdyadprob attrprob, name(attrdraw)
    quietly nwsummarize attrdraw, detail
    local rec = r(reciprocity)
    local tra = r(transitivity)
    quietly nwmixing attrdraw, attribute(office) permutations(1)
    local eio = r(EI_index)
    quietly nwmixing attrdraw, attribute(practice) permutations(1)
    frame post attr (`rec') (`tra') (`eio') (r(EI_index))
    nwdrop attrdraw
}
frame attr: summarize
