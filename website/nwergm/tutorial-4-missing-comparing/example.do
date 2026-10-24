* nwergm tutorial 4: missing data and comparing models
* Requires the core nwcommands and the package nwergm.

* ---- missing dyads: blank out three marriages of the Florentine families
nwwebuse florentine, nwclear
nwtomata flomarriage, mat(A)
mata: A[1,2] = A[2,1] = .
mata: A[3,5] = A[5,3] = .
mata: A[4,9] = A[9,4] = .
mata: st_matrix("Am", A)
tempfile nodes
save `nodes'
nwset, mat(Am) undirected name(flomiss)
use `nodes', clear

nwergm flomarriage, edges nodecov(wealth)
nwergm flomiss, edges nodecov(wealth)
display "missing dyads: " e(nmissing) "   informative dyads: " e(N)
nwergm flomiss, edges nodecov(wealth) gwesp(0.5) seed(1)
display "missing dyads: " e(nmissing) "   informative dyads: " e(N)

* ---- comparing models for the Lazega friendship network
nwwebuse lazega, nwclear
encode practice, generate(prac)
nwergm lazega_fr, edges mutual nodematch(prac) seed(1) mcmcinterval(1000) mcmcburnin(20000)
estimates store m1
nwergm lazega_fr, edges mutual nodematch(prac) gwesp(0.5) seed(1) mcmcinterval(1000) mcmcburnin(20000)
estimates store m2
estat ic
estimates stats m1 m2
lrtest m2 m1

* ---- predicted tie probabilities
predict, frame(pp) pr
frame pp: summarize p
frame pp: list in 1/5
