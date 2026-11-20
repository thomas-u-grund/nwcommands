* nwlsm tutorial 2: how many latent clusters? BIC for the Lazega lawyers
* Requires the core nwcommands and the package nwlsm. The data (Lazega 2001) are loaded from the nwcommands website.
set linesize 80

nwwebuse lazega, nwclear
nwsummarize lazega_fr

* --- one model without clusters, and its BIC ---
nwlsm lazega_fr, dim(2) seed(12)
estat bic

* --- the BIC for 0, 2, 3 and 4 clusters ---
nwlsmselect lazega_fr, clusters(0 2 3 4) seed(12)
matrix list r(table), format(%9.2f)
display "best number of clusters: " r(best)

* --- the same comparison with random sender and receiver effects; refit keeps the best model ---
nwlsmselect lazega_fr, clusters(0 2 3 4) sender receiver seed(12) refit
estat bic
display "starting points of the minimum Kullback-Leibler fit: " e(mklstarts)

* --- the effective number of observations changes only the part for the ties ---
estat bic, effobs(actors)

* --- how clear are the clusters of the chosen model? ---
estat clusters, generate(grp) nolist
tabulate grp_class
summarize grp_p1 grp_p2

* --- a single starting point instead of the default four ---
nwlsm lazega_fr, dim(2) clusters(2) sender receiver seed(12) mklstarts(1)
estat bic

* --- goodness of fit of a binary directed network ---
nwlsm lazega_fr, dim(2) clusters(2) sender receiver seed(12)
estat gof, gof(distance) nsim(100) seed(1)

* --- a valued network: the number of the three relations (advice, co-work, friendship) of a pair, 0 to 3 ---
nwgen lazega_all = lazega_fr + lazega_adv + lazega_cow
nwsummarize lazega_all
nwlsm lazega_all, family(binomial) trials(3) dim(2) sender receiver seed(12)
estat gof, gof(distance values) nsim(100) seed(1)
estat gof, gof(distance) nsim(100) seed(1) cutoff(1)
