* nwalaam tutorial 2: smoking in the Glasgow friendship network
* Requires the core nwcommands and the package nwalaam. The data (Teenage Friends and Lifestyle Study) are loaded from the nwcommands website.
set linesize 80

* --- the outcome: occasional or regular smoker, wave 1; the network: who names whom as a friend ---
nwwebuse glasgow, nwclear
generate byte smoker1 = (smoke1 > 1)
tabulate smoker1

* --- contagion alone: the pseudo-likelihood is a logit on the number of ties to smokers ---
nwalaam smoker1 glasgow1, effects(density contagion) mple

* --- the maximum likelihood estimate, with activity effects of the senders and receivers of ties ---
nwalaam smoker1 glasgow1, effects(density contagion sender receiver) seed(20261118)

* --- covariates: the command does not centre them, so centre them first ---
quietly summarize alcohol1
generate double alc_c = alcohol1 - r(mean)
quietly summarize sport1
generate double sport_c = sport1 - r(mean)
nwalaam smoker1 glasgow1, effects(density contagion sender receiver ego(alc_c) ego(sport_c)) seed(20261118)

* --- does the model reproduce statistics that are not in it? ---
estat gof, nsim(1000) seed(7)

* --- simulate outcome vectors from the fitted model ---
nwalaam simulate, nsim(100) generate(sim) seed(2)
egen simsmoke = rowtotal(sim1-sim100)
summarize simsmoke

* --- a different quantity: the exposure regression on the share of friends who smoke ---
nwaltergen frsmoke = proportion(alter.smoker1==1), net(glasgow1)
logit smoker1 frsmoke
