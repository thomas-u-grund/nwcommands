* nwsbm tutorial 2: covariates with standard errors, the exact ICL with the greedy search,
* the degree-corrected two-mode model, block variances and ordered blocks.
* Requires the core nwcommands and the package nwsbm. The data are loaded from the nwcommands website:
* Lazega (2001), lawyers of a law firm; Davis, Gardner and Gardner (1941), Southern women.
set linesize 80

nwwebuse lazega, nwclear
nwsummarize lazega_fr

* --- friendship among the lawyers, blocks without covariates ---
nwsbm lazega_fr, maxblocks(6) seed(20261120) generate(b0) replace nodisplay
estat icl
display "ICL without covariates: " %9.2f e(ICL) " with " e(Q) " blocks"
nwsbmplot, type(expected) sort export(nwsbm2_expected.png)
nwsbmplot, type(matrix) sort export(nwsbm2_matrix.png)

* --- the same network with covariates: same office, same practice, same gender, seniority difference ---
nwsbm lazega_fr, maxblocks(4) seed(20261120) same(office practice gender) absdiff(seniority) generate(b1) replace
estat blocks

* --- coefficients, standard errors and the variance matrix are stored ---
matrix list e(beta)
matrix list e(se_beta)
matrix list e(V_beta)
display "z of same_office: " %6.2f el(e(beta), 1, 2) / el(e(se_beta), 1, 2)
display "odds ratio of same_office: " %6.2f exp(el(e(beta), 1, 2))

* --- exact ICL, without and with the greedy search ---
nwsbm lazega_fr, maxblocks(6) seed(20261120) icl(exact) generate(e1) replace nodisplay
estat icl
display "exact ICL: " %9.2f e(ICL) "   criterion of blockmodels at the same fit: " %9.2f e(ICLbm)
nwsbmplot, type(icl) export(nwsbm2_icl_exact.png)
nwsbm lazega_fr, maxblocks(6) seed(20261120) icl(exact) greedy generate(e2) replace nodisplay
estat icl
display "exact ICL with greedy: " %9.2f e(ICL) " with " e(Q) " blocks"
tabulate e1 e2

* --- a two-mode network: the Southern women and their events ---
nwwebuse davis, nwclear
nwsummarize davis
nwsbm davis, maxblocks(4 4) seed(20261120) generate(d0) replace nodisplay
estat icl
display "Bernoulli, ICL of blockmodels: " %8.2f e(ICL) ", blocks " e(Q1) " x " e(Q2)
nwsbmplot, type(matrix) export(nwsbm2_davis_matrix.png)
nwsbmplot, type(icl) export(nwsbm2_davis_icl.png)

* --- degree-corrected Poisson latent block model, exact ICL ---
nwsbm davis, maxblocks(4 4) seed(20261120) model(poisson) degreecorrected icl(exact) generate(d1) replace nodisplay
display "degree-corrected, exact ICL: " %8.2f e(ICL) ", blocks " e(Q1) " x " e(Q2)
estat icl

* --- two blocks on each side, without and with the greedy search ---
nwsbm davis, blocks(2 2) seed(20261120) model(poisson) degreecorrected icl(exact) generate(d2) replace nodisplay
display "2 x 2, exact ICL: " %8.2f e(ICL)
nwsbm davis, blocks(2 2) seed(20261120) model(poisson) degreecorrected icl(exact) greedy orderblocks generate(d3) replace
estat blocks
tabulate d3 title if _nwmode == "1"

* --- Gaussian ties with one variance and with a variance for every pair of blocks ---
nwwebuse lazega, nwclear
nwgenerate ties3 = lazega_adv + lazega_cow + lazega_fr
nwsummarize ties3
nwsbm ties3, model(gaussian) maxblocks(5) seed(20261120) generate(g1) replace nodisplay
display "one variance: ICL " %9.2f e(ICL) ", " e(Q) " blocks, variance " %6.3f e(sigma2)
estat blocks
nwsbm ties3, model(gaussian) blockvar maxblocks(5) seed(20261120) orderblocks generate(g2) replace
matrix list e(sigma2_block)
display "pooled residual variance: " %6.3f e(sigma2)
tabulate g1 g2
