* --------------------------------------------------------------------------
* Network Analysis with Stata (Stata Press)
* Chapter 11: Ego networks
*
* All commands of the chapter, in the order in which the book prints them.
* Requires Stata 17 or later and nwcommands (see Getting started:
*     net install nwcommands, from(https://nwcommands.org/net/)
*     nwinstall, everything
* ). The data sets are loaded from the internet with nwwebuse.
* The do-file runs from top to bottom. It was checked against nwcommands 3.29.0,
* nwergm 1.11.0, nwsaom 1.9.0, nwrem 1.6.0, nwdynam 1.10.0, nwalaam 1.3.0,
* nwlsm 1.0.0 and nwsbm 1.0.0, the versions the book was printed with.
* Lines marked "setup" are not printed in the book but are needed to run it.
* Commands that the book shows failing on purpose are run with capture noisily.
* Do-files for all chapters: https://nwcommands.org/book/dofiles/
* --------------------------------------------------------------------------

clear all
set more off

* ============================================================
* Size and density
* ============================================================
nwwebuse lazega, nwclear
quietly nwdegree lazega_adv, generate(adv_out adv_in)
nwego lazega_adv, sizevar(egosize) densvar(egodens)
correlate egosize adv_out adv_in
tabstat egosize egodens, by(partner) statistics(mean sd n)

list _nwnode egosize egodens if inlist(_nwnode, "n62", "n70"), noobs
nwegoplot lazega_adv, ego(n62) label(_nwnode) color(partner) ///
    arrowfactor(0) scheme(s1network)
nwegoplot lazega_adv, ego(n70) label(_nwnode) color(partner) ///
    arrowfactor(0) scheme(s1network)

* ============================================================
* Composition: who the alters are
* ============================================================
nwaltergen pshare = proportion(alter.partner==1), net(lazega_adv)
nwaltergen sh1 = proportion(alter.officenum==1), net(lazega_adv)
nwaltergen sh2 = proportion(alter.officenum==2), net(lazega_adv)
nwaltergen sh3 = proportion(alter.officenum==3), net(lazega_adv)
generate sameoff = cond(officenum==1, sh1, cond(officenum==2, sh2, sh3))
nwaltergen odiv = diversity(alter.officenum), net(lazega_adv)
tabstat pshare, by(partner) statistics(mean sd n)
tabstat sameoff odiv, by(office) statistics(mean n)
tabulate office if odiv == 0

clear
input resp alter kin knows
1 1 1 2
1 2 1 2
1 3 0 2
1 4 0 0
2 1 1 1
2 2 0 1
3 1 1 0
end
collapse (count) size=alter (mean) kinshare=kin (sum) knows, by(resp)
generate density = knows / (size * (size - 1))
list, clean noobs

* ============================================================
* Exposure: what the alters do
* ============================================================
nwwebuse glasgow, nwclear
generate byte smoker1 = (smoke1 > 1)
nwaltergen frsmoke = proportion(alter.smoker1==1), net(glasgow1)
nwaltergen frsmoke2 = proportion(alter.smoker1==1), net(glasgow1) hop(2)
summarize frsmoke frsmoke2
tabstat frsmoke frsmoke2, by(smoker1) statistics(mean n)

* ============================================================
* Exposure as a covariate
* ============================================================
generate byte smoker2 = (smoke2 > 1)
regress smoker2 frsmoke smoker1
