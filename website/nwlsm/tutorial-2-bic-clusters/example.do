* nwlsm tutorial 2: how many latent clusters? BIC for Sampson's monks
* Requires the core nwcommands and the package nwlsm. The data (Sampson 1969) are loaded from the nwcommands website.
set linesize 80

nwwebuse sampson, nwclear
nwsummarize samplk3

* --- the network of the choices at the third time point, without the ranks ---
nwgen choice3 = samplk3 > 0
nwsummarize choice3

* --- one model without clusters, and its BIC ---
nwlsm choice3, dim(2) seed(12)
estat bic

* --- the BIC for 0, 2, 3 and 4 clusters; refit keeps the best model ---
nwlsmselect choice3, clusters(0 2 3 4) seed(12) refit
matrix list r(table), format(%9.2f)
display "best number of clusters: " r(best)

* --- do the clusters agree with the factions that Sampson observed? ---
estat clusters, generate(grp) nolist
tabulate grp_class faction

* --- the monks in the latent space, coloured by cluster ---
nwlsmplot, clusters label(_nwnode) title("Sampson's monks in the latent space")
graph export "monks_clusters.png", width(900) replace
summarize grp_p1 grp_p2 grp_p3
generate pmax = max(grp_p1, grp_p2, grp_p3)
summarize pmax
count if pmax < 0.8

* --- the same comparison with random sender and receiver effects ---
nwlsmselect choice3, clusters(0 2 3 4) sender receiver seed(12)
nwlsm choice3, dim(2) clusters(3) sender receiver seed(12)
estat bic
display "starting points of the minimum Kullback-Leibler fit: " e(mklstarts)

* --- a single starting point instead of the default four ---
nwlsm choice3, dim(2) clusters(3) sender receiver seed(12) mklstarts(1)
estat bic

* --- the effective number of observations: ties (56), dyads or actors (18) ---
estat bic, effobs(dyads)
estat bic, effobs(actors)

* --- goodness of fit of the binary model with three clusters ---
nwlsm choice3, dim(2) clusters(3) seed(12)
estat gof, gof(odegree distance) nsim(100) seed(1)

* --- a valued network: how much each monk likes the others, 0 to 3 ---
nwsummarize samplike
nwlsm samplike, family(binomial) trials(3) dim(2) clusters(3) seed(12)
estat gof, gof(distance values) nsim(100) seed(1)
estat gof, gof(distance) nsim(100) seed(1) cutoff(1)
