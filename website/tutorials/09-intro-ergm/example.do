* Tutorial 9: Intro to ERGM in Stata
* Run from a directory with nwcommands net-installed (not a dev checkout).

nwwebuse florentine, nwclear

* The simplest possible ERGM: just an edges term, equivalent to a
* single intercept - the model says every potential tie is equally
* likely, with no structure or covariates at all
nwergm flomarriage, edges

* Adding a covariate: does wealth make a marriage tie more likely
* between wealthier families?
nwergm flomarriage, edges nodecov(wealth)
