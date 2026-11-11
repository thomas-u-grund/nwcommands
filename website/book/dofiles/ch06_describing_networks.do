* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 6: Describing networks
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
* Size and density: what the numbers tell us
* ============================================================
nwwebuse lazega, nwclear
foreach r in adv cow fr {
    quietly nwsummarize lazega_`r'
    display "`r': nodes = " r(nodes) "  arcs = " r(arcs) "  density = " ///
        %5.3f r(density) "  mean outdegree = " %5.2f r(arcs)/r(nodes)
}

* ============================================================
* Dyad census and reciprocity
* ============================================================
nwdyads lazega_adv
nwdyads lazega_fr

nwwebuse glasgow, nwclear
nwdyads glasgow1
nwdyads glasgow2
nwdyads glasgow3

* ============================================================
* Triples: transitivity and the triad census
* ============================================================
nwwebuse lazega, nwclear
nwtriads lazega_adv

foreach r in adv cow fr {
    quietly nwtriads lazega_`r'
    display "`r': transitivity = " %5.3f r(transitivity)
}
nwwebuse glasgow, nwclear
foreach w in 1 2 3 {
    quietly nwtriads glasgow`w'
    display "glasgow`w': transitivity = " %5.3f r(transitivity)
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

nwassortativity lazega_adv
nwassortativity lazega_adv, attribute(age)
nwassortativity lazega_fr, attribute(age)

nwwebuse glasgow, nwclear
nwassortativity glasgow1
nwassortativity glasgow1, attribute(sport1)

nwwebuse gang, nwclear
nwmixing gang, attribute(Birthplace)

tab Birthplace
