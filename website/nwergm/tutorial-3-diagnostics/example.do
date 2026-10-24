* nwergm tutorial 3: MCMC diagnostics and goodness of fit
* Requires the core nwcommands and the package nwergm.

nwwebuse lazega, nwclear
encode practice, generate(prac)

* default MCMC settings
nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(0.5) seed(1)
estat mcmcdiag

* a longer interval between draws and a longer burn-in
nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(0.5) seed(1) mcmcinterval(1000) mcmcburnin(20000)
estat mcmcdiag

* goodness of fit
estat gof, nsim(50) seed(2)

* a model that cannot be fitted: triangles in the Kapferer tailor shop network
nwwebuse kapferer, nwclear
capture noisily nwergm kapferer_t2, edges triangle seed(1) mcmcsamplesize(1000)
display "return code: " _rc

* the geometrically weighted version
nwergm kapferer_t2, edges gwesp(0.5) seed(1)
estat gof, nsim(50) seed(2)
