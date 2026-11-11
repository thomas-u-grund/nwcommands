* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 4: Working with networks in Stata
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
* Declaring network data: nwset
* ============================================================
nwclear
nwset, mat((0,1,0,0\0,0,1,0\1,0,0,1\0,0,0,0)) directed name(toy) ///
    labs(Anna, Sophie, Gwen, Leh)
nwdegree toy, generate(_outdegree _indegree)

* ============================================================
* Importing from external formats
* ============================================================
nwclear
nwimport "$nwwebpath/edgelist_example.txt", type(edgelist) name(tiny)
nwsummarize tiny
list _nwnode

* ============================================================
* Building an edge list from raw survey data
* ============================================================
clear
input str6 id str6 friend1 str6 friend2 str6 friend3
"anna" "sophie" "gwen" ""
"sophie" "anna" "" ""
"gwen" "anna" "leh" "fion"
"leh" "" "" ""
"fion" "gwen" "sophie" ""
end
list, clean

reshape long friend, i(id) j(nomination)
list, clean sepby(id)
drop if missing(friend)
list, clean

nwfromedge id friend, name(friends) undirected
nwsummarize friends

* ============================================================
* Multiple networks, one dataset
* ============================================================
nwwebuse lazega, nwclear
nwset
describe, short

nwsummarize lazega_*
quietly nwdegree *_adv, generate(adv_out adv_in)
summarize adv_out adv_in

nwwebuse glasgow, nwclear
nwset

* ============================================================
* Saving, using, and loading
* ============================================================
nwclear
set seed 12345
nwrandom 20, ntimes(5) prob(.2)
nwsave mynets, replace
nwclear
nwuse mynets, nwclear
nwset
erase mynets.nwdta

nwwebuse florentine, nwclear
drop _all
nwload flomarriage
describe, short
list _nwnode medici pazzi peruzzi in 1/5

* ============================================================
* Meta-information: nwname
* ============================================================
nwwebuse lazega, nwclear
nwname lazega_adv
return list

* ============================================================
* Generate and replace
* ============================================================
nwwebuse lazega, nwclear
capture noisily nwgenerate lazega_fr = lazega_adv * lazega_fr
nwgenerate both = lazega_adv * lazega_fr
nwsummarize both
nwgenerate both = lazega_adv * lazega_fr, replace
nwreplace both[2,1] = 0

* ============================================================
* Changing a network: subsets, copies, transposes and symmetrizing
* ============================================================
nwwebuse lazega, nwclear
nwsubset lazega_adv if office == "Boston", name(adv_boston)
nwsummarize adv_boston
nwkeepnodes lazega_adv, nodes(1/10) generate(adv_first10)
nwsymmetrize lazega_fr, mode(max) generate(fr_or)
nwsymmetrize lazega_fr, mode(min) generate(fr_and)
nwsummarize fr_or fr_and
nwtranspose lazega_adv, generate(adv_asked_by)
nwduplicate lazega_adv, name(adv_copy)
nwset
