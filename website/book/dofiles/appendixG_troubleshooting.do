* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Appendix: When things go wrong
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
* Reading _rc
* ============================================================
capture noisily nwsummarize doesnotexist
di "_rc = " _rc

* ============================================================
* Category 1: an unknown or missing network
* ============================================================
nwwebuse florentine, nwclear
capture noisily nwsummarize doesnotexist
di "_rc = " _rc

nwclear
capture noisily nwsummarize
di "_rc = " _rc

* ============================================================
* Category 2: overwriting something that already exists
* ============================================================
nwwebuse florentine, nwclear
capture noisily nwdegree flomarriage, generate(wealth)
di "_rc = " _rc

* ============================================================
* Category 3: the wrong network type for the command
* ============================================================
clear
input str8 ego str8 alter
"Anna" "Oxford"
"Sophie" "Oxford"
"Sophie" "LiU"
end
nwset ego alter, edgelist twomode name(bip)
nwclustering bip, generate(_clustering)
capture noisily nwspectral bip, generate(spc)
di "_rc = " _rc

* ============================================================
* Category 4: a structural precondition the command needs
* ============================================================
nwwebuse florentine, nwclear
capture noisily nwconcor flomarriage, generate(_concor)
di "_rc = " _rc

* ============================================================
* Category 5: incompatible dimensions between two networks
* ============================================================
nwwebuse florentine, nwclear
nwrandom 10, prob(.2) undirected name(small10)
capture noisily nwcorrelate flomarriage small10
di "_rc = " _rc

* ============================================================
* Two mistakes that used to pass silently
* ============================================================
capture noisily nwset, mat((0,1,1\1,0,1\1,1,0)) undirected labs(A,A,B)

nwwebuse florentine, nwclear
drop _all
nwload flomarriage
nwload flobusiness

nwwebuse florentine, nwclear
drop _all
set obs 16
generate medici = 1
capture noisily nwload flomarriage

* ============================================================
* SAOM-specific failures: several groups
* ============================================================
nwwebuse glasgow, nwclear
generate byte school = 1 + (_n > 15) + (_n > 35)
mata: g = st_data(., "school"); M = J(rows(g), 1, g') :== g
forvalues w = 1/3 {
    quietly nwtomata glasgow`w', mat(F`w')
    mata: st_matrix("S`w'", F`w' :* M)
    nwset, mat(S`w') directed name(gw`w') nooutput
}
capture noisily nwsaom, waves(glasgow1 glasgow2 glasgow3) groups(school) ///
    outdegree reciprocity
display "_rc = " _rc
capture noisily nwsaom, waves(gw1 gw2 gw3) groups(school) outdegree ///
    reciprocity ml
display "_rc = " _rc
capture noisily nwsaom, waves(gw1 gw2 gw3) groups(school) gwaves(2: 1) ///
    outdegree reciprocity
display "_rc = " _rc

* ============================================================
* Installing and updating in detail
* ============================================================
* (installation; run once by hand, see Getting started) net install nwsaom, from("https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/")
* (installation; run once by hand, see Getting started) net install nwsaom, from("https://raw.githubusercontent.com/thomas-u-grund/nwsaom/v1.5.0/") replace

* ============================================================
* Installation problems
* ============================================================
* (installation; run once by hand, see Getting started) nwinstall, buildplugin(nwsaom)
* (installation; run once by hand, see Getting started) nwinstall, buildplugin(all)

* (installation; run once by hand, see Getting started) nwinstall, buildmata(all)
* (installation; run once by hand, see Getting started) nwinstall, buildmata(nwsaom)
