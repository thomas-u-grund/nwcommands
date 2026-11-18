* nwalaam tutorial 1: a first autologistic actor attribute model on the karate club
* Requires the core nwcommands and the package nwalaam. The data (Zachary 1977) are loaded from the nwcommands website.
set linesize 80

nwalaam version

* --- the network and the outcome: which of the 34 members joined the officer's side of the split? ---
nwwebuse zachary, nwclear
tabulate group
generate byte faction = (group == 2)
nwsummarize zachary_bin

* --- the pseudo-likelihood estimate: a logit of the outcome on the change statistics ---
* In the karate club the outcome is perfectly separated by these statistics, so this estimate does not exist.
capture noisily nwalaam faction zachary_bin, effects(density activity contagion) mple
display "return code: " _rc

* --- the default: stochastic approximation (maximum likelihood) ---
nwalaam faction zachary_bin, effects(density activity contagion) seed(20261118)

* --- the update of ALAAMEE (equilibrium expectation), 40 runs ---
nwalaam faction zachary_bin, effects(density activity contagion) method(ee) runs(40) iterations(100000) seed(20261118)
