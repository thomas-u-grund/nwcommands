* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 16: Generating networks from attributes and tie probabilities
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
* Tie probabilities from group membership
* ============================================================
nwwebuse lazega, nwclear
rename practice practice_str
encode practice_str, generate(practice)
nwexpand practice, name(samepractice)
preserve
nwtoedge lazega_adv samepractice, full
drop if _ego == _alter
tabulate samepractice, summarize(lazega_adv) means
restore

nwgen blockprob = .115 + .128 * samepractice
set seed 12345
nwdyadprob blockprob, name(blocks)
nwsummarize blocks, detail
quietly nwmixing blocks, attribute(practice) permutations(1)
display "E-I index by practice, block draw:  " %6.3f r(EI_index)
quietly nwmixing lazega_adv, attribute(practice) permutations(1)
display "E-I index by practice, observed:    " %6.3f r(EI_index)
nwplot blocks, color(practice) symbol(practice) legendopt(off)

* ============================================================
* Homophily networks
* ============================================================
set seed 12345
quietly nwhomophily practice, density(.179) homophily(3) name(plus3)
set seed 12345
quietly nwhomophily practice, density(.179) homophily(-3) name(minus3)
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
capture program drop sweep
program sweep
    args h reps
    tempname S
    matrix `S' = J(`reps', 1, .)
    forvalues r = 1/`reps' {
        capture nwdrop tmp
        quietly nwhomophily practice, density(.179) homophily(`h') name(tmp)
        quietly nwmixing tmp, attribute(practice) permutations(1)
        matrix `S'[`r', 1] = r(EI_index)
    }
    preserve
    clear
    quietly svmat `S'
    quietly summarize `S'1
    display "homophily(`h'): mean E-I = " %6.3f r(mean) "  min " %6.3f ///
        r(min) "  max " %6.3f r(max)
    restore
end
set seed 12345
foreach h in 0 .5 1 2 3 {
    sweep `h' 20
}

* ============================================================
* Sorting without sorters
* ============================================================
rename office office_str
encode office_str, generate(office)
foreach var in practice office {
    set seed 12345
    quietly nwhomophily `var', density(.179) homophily(0) name(zero_`var')
    quietly nwmixing zero_`var', attribute(`var') permutations(1)
    display "`var', homophily(0):  E-I index = " %6.3f r(EI_index)
    quietly nwmixing lazega_adv, attribute(`var') permutations(1)
    display "`var', observed advice network:  E-I index = " %6.3f r(EI_index)
}
tabulate office
