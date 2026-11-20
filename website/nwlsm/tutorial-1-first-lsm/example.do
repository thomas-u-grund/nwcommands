* nwlsm tutorial 1: a latent space model for the karate club
* Requires the core nwcommands and the package nwlsm. The data (Zachary 1977) are loaded from the nwcommands website.
set linesize 80

nwwebuse zachary, nwclear
nwsummarize zachary_bin

* --- a two-dimensional Euclidean latent space model, two chains of 1,000 draws ---
nwlsm zachary_bin, dim(2) nsample(2000) burnin(5000) interval(10) chains(2) seed(20261120)

* --- did the chains converge? ---
estat mcmcdiag

* --- the positions of the actors ---
estat positions

* --- the network drawn in the latent space ---
nwlsmplot, title("The karate club in the latent space")
graph export "karate_positions.png", width(900) replace

* --- the uncertainty of the positions: 100 posterior draws as a faint cloud ---
nwlsmplot, draws(100) title("The karate club with 100 posterior draws of the positions")
graph export "karate_draws.png", width(900) replace

* --- does the fitted model reproduce the degrees and distances of the network? ---
estat gof
