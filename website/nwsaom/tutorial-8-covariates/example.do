* nwsaom tutorial 8: time-varying and dyadic covariates
* Requires the core nwcommands and the package nwsaom.

nwwebuse klas12b, nwclear
nwsaom describe, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4)

* Variables on the pupils: sex, age, ethnicity, religion (constant),
* delinquency at four waves (changing)
summarize delinq1 delinq2 delinq3 delinq4 sex age
tabulate sex
tabulate ethnicity

* A model with constant covariates only
nwsaom, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4) outdegree reciprocity transtrip samex(sex)  seed(4)

* A covariate that changes between waves: tvcov() takes one variable per
* period. Period 1 uses delinq1, period 2 delinq2, period 3 delinq3.
* The effects are then called with the stem 'delinq'.
nwsaom, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4) outdegree reciprocity transtrip samex(sex) tvcov(delinq1 delinq2 delinq3) egox(delinq) altx(delinq) simx(delinq) seed(4) detail

* A dyadic covariate: did two pupils go to the same primary school?
* It is a Stata matrix, one row and column per pupil.
nwtomata klas12b_primary, mat(Pmata)
mata: st_matrix("primary", Pmata)
mata: printf("%g pairs of pupils went to the same primary school\n", sum(Pmata :== 1) / 2)
nwsaom, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4) outdegree reciprocity transtrip samex(sex) tvcov(delinq1 delinq2 delinq3) egox(delinq) altx(delinq) simx(delinq) dyadcov(primary) seed(4)

* The same matrix, but counted only when the tie is reciprocated
nwsaom, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4) outdegree reciprocity transtrip samex(sex) dyadcov(primary) dyadcovrecip(primary) seed(4)
