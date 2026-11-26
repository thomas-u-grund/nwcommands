* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 6: Describing networks
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.39.0,
* nwergm 1.16.1, nwsaom 1.9.2, nwrem 1.7.2, nwdynam 1.11.2, nwalaam 1.4.0,
* nwlsm 1.0.6 and nwsbm 1.1.0, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it; lines marked "run" are fits that the text summarizes.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Size and density: what the numbers tell us
* ============================================================
nwwebuse lazega, nwclear
nwsummarize lazega_adv

* ============================================================
* Dyad census and reciprocity
* ============================================================
nwdyads lazega_adv, plot
nwdyads lazega_fr

* ============================================================
* Triples: transitivity and the triad census
* ============================================================
nwwebuse lazega, nwclear
nwtriads lazega_adv, plot expected title("") scheme(s1network)

foreach r in adv cow fr {
    quietly nwtriads lazega_`r'
    display "`r': transitivity = " %5.3f r(transitivity)
}

* ============================================================
* Assortativity and mixing
* ============================================================
nwwebuse lazega, nwclear
nwmixing lazega_adv, attribute(status)
nwmixing lazega_fr, attribute(status)

nwmixing lazega_adv, attribute(office)
nwmixing lazega_fr, attribute(office)

display "status: " (35*34 + 36*35) / (71*70)
display "office: " (48*47 + 19*18 + 4*3) / (71*70)

nwwebuse gang, nwclear
nwmixing gang, attribute(Birthplace)

tab Birthplace

nwwebuse lazega, nwclear
nwassortativity lazega_adv, sym
nwassortativity lazega_adv, attribute(age) sym
nwassortativity lazega_fr, attribute(age) sym

nwdegree lazega_adv, generate(adv_out adv_in) silent
xtile asks = adv_out, nquantiles(3)
label define asks 1 "few" 2 "middle" 3 "many"
label values asks asks
set seed 12345
nwmixing lazega_adv, attribute(asks)

nwwebuse glasgow, nwclear
nwassortativity glasgow1, sym
nwassortativity glasgow1, attribute(sport1) sym
