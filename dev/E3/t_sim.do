clear all
set more off
adopath ++ "."
adopath ++ "lib/plugins/macos"
quietly do unw_core.do
quietly do unw_ergm.do
qui nwergm simulate 30, edges structural(m2star) directed theta(-2.5 -0.05) nsim(2) mcmcburnin(2000) mcmcinterval(50) generate(ssim) seed(5)
nwsummarize ssim_1
nwergm ssim_1, edges structural(m2star) seed(3)
estat gof, nsim(5)
