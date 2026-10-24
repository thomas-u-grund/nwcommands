* Tutorial 9: Intro to ERGM in Stata
* Requires the core nwcommands and the nwergm package:
*   net install nwergm, from(https://raw.githubusercontent.com/thomas-u-grund/nwergm/main/)

nwergm version

nwwebuse florentine, nwclear

* The simplest possible ERGM: just an edges term
nwergm flomarriage, edges

* Adding a covariate: does wealth make a marriage tie more likely?
nwergm flomarriage, edges nodecov(wealth)

* Information criteria and prediction
estat ic

* A dyad-dependent term (triadic closure) is fitted by MCMC
nwergm flomarriage, edges gwesp(.5) seed(1)

* Simulation-based goodness of fit
estat gof
