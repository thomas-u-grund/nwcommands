* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Appendix: When things go wrong
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.32.1,
* nwergm 1.11.1, nwsaom 1.9.1, nwrem 1.6.0, nwdynam 1.10.0, nwalaam 1.3.1,
* nwlsm 1.0.3 and nwsbm 1.0.2, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Category 1: an unknown or missing network
* ============================================================
nwwebuse florentine, nwclear
capture noisily nwsummarize doesnotexist
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
* Installing and updating in detail
* ============================================================
* (installation; run once by hand, see Getting started) net install nwsaom, from("https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/")
* (installation; run once by hand, see Getting started) net install nwsaom, from("https://raw.githubusercontent.com/thomas-u-grund/nwsaom/v1.5.0/") replace
