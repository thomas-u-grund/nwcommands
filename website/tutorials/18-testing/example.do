* nwcommands tutorial 13: testing hypotheses about networks
* Requires the core nwcommands.

* 1. Is a statistic unusual for a network of this size and density? (CUG test)
nwwebuse florentine, nwclear
nwsummarize flomarriage
nwcug flomarriage, stat(nwtriads) rname(transitivity) reps(500) seed(12345)
nwcug flomarriage, stat(nwcomponents, generate(cc) replace silent) rname(components) reps(500) seed(12345)

* 2. Is one network related to another? (QAP correlation)
nwwebuse glasgow, nwclear
nwcorrelate glasgow1 glasgow2
nwcorrelate glasgow1 glasgow2, permutations(500)

* 3. Does a covariate explain ties? (QAP regression)
nwqap glasgow2 glasgow1 smoke1 sport1

* 4. The CUG test again, holding every family's number of marriages fixed
nwwebuse florentine, nwclear
nwcug flomarriage, stat(nwtriads) rname(transitivity) condition(degrees) reps(500) seed(12345)
