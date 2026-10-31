---
title: "Tutorial 8: Time-varying and dyadic covariates"
parent: "nwsaom (SAOM)"
nav_order: 9
description: "Covariates that change between waves (tvcov) and covariates defined for pairs of actors (dyadcov, dyadcovrecip) in nwsaom, shown on a Dutch school class observed four times."
---

# Tutorial 8: Time-varying and dyadic covariates

**Goal.** Add two kinds of explanatory variables that [Tutorial 1](../tutorial-1-first-saom/) did not need:
a variable of the *pupils* that changes from wave to wave (here: delinquency), and a variable of *pairs* of pupils
(here: whether they went to the same primary school).

**Data.** A school class of 26 pupils in their first year of Dutch secondary school, observed four times, three
months apart (the data of Andrea Knecht, 2003-2004; see [Data sets](../../datasets/) for the source). They
come with the core package: `nwwebuse klas12b`. The commands were run with `nwsaom` 1.1.1 and the core
3.10.0 in Stata 18, and checked in Stata 17. The complete script and log are in [example.do](example.do) and
[example.log](example.log).

## Look at the data

```stata
. nwsaom describe, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4)

Network data: 4 waves, 26 actors, directed
-----------------------------------------------------
        wave |     ties     density   avg. degree
-------------+---------------------------------------
           1 |       91      0.1400         3.500
           2 |      117      0.1800         4.500
           3 |      133      0.2046         5.115
           4 |      119      0.1831         4.577
-----------------------------------------------------

----------------------------------------------------------------------
      period |    kept   created  dissolved   Jaccard   Hamming
-------------+--------------------------------------------------------
        1->2 |      60        57         31     0.405        88
        2->3 |      70        63         47     0.389       110
        3->4 |      75        44         58     0.424       102
----------------------------------------------------------------------
```

Four waves give three periods. The class gets denser (from 0.14 to 0.20 at wave 3) and the Jaccard index is around
0.4 in all periods, so there is enough stability and enough change to model. The pupil variables are:

```stata
. summarize delinq1 delinq2 delinq3 delinq4 sex age

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
     delinq1 |         26    1.384615     .803837          0          4
     delinq2 |         26    1.461538    .7060181          0          3
     delinq3 |         26    1.769231    1.031802          0          3
     delinq4 |         26    1.884615    1.142871          0          5
         sex |         26    1.346154    .4851645          1          2
-------------+---------------------------------------------------------
         age |         26    12.07692    .4835764         11         13
```

`delinq1` to `delinq4` measure delinquent behavior at the four waves (in these data with values from
0 to 5); `sex` is 1 for the 17 girls and 2 for the 9 boys. `age`, `ethnicity` and `religion`
do not change. Delinquency does change: its average rises from 1.4 to 1.9.

## Constant and changing covariates

A *constant* covariate such as `sex` has one value per pupil for the whole study, and you use it with
`samex(sex)` (a preference for same-sex friends), `egox(sex)` and `altx(sex)`, as with smoking in Tutorial 1. A *changing*
covariate has one value per pupil **and wave**, and the model should use the value that is valid during each period.
First a model with the constant covariate only:

```stata
. nwsaom, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4) outdegree reciprocity transtrip samex(sex)  seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4
Actors: 26                             Periods: 3
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
klas12b_wa~4 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -1.903829   .1079266   -17.64   0.000    -2.115361   -1.692296
 reciprocity |   .8776045   .1267133     6.93   0.000      .629251    1.125958
   samex_sex |   .5659666   .1088162     5.20   0.000     .3526907    .7792425
   transtrip |   .1888613    .022552     8.37   0.000     .1446601    .2330624
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2    period3 
-------------+--------------------------------
        rate |    7.3926     9.4096     7.8039 
          se |    1.2521     1.5709     1.1306 
Overall maximum convergence ratio: 0.081 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Girls and boys prefer same-sex friends (`samex_sex` 0.57, z = 5.2); reciprocity and transitive closure are positive,
and smaller than in the Glasgow data (reciprocity 0.88, against about 2.5 in Tutorial 1).

### tvcov(): one variable per period

`tvcov()` takes the covariate's variables in wave order, one per period: `tvcov(delinq1 delinq2 delinq3)`.
Period 1 uses `delinq1`, period 2 uses `delinq2`, period 3 uses `delinq3`; the value at the last wave is not used,
because it describes the end, not the beginning, of the last period. In the effects the covariate is called by its
**stem**, the name without the number, here `delinq`:

```stata
. nwsaom, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4) outdegree reciprocity transtrip samex(sex) tvcov(delinq1 delinq2 delinq3) egox(delinq) altx(delinq) simx(delinq) seed(4) detail
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4
Actors: 26                             Periods: 3
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
klas12b_wa~4 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -1.910138   .1117195   -17.10   0.000    -2.129104   -1.691172
 reciprocity |   .8535759   .1337072     6.38   0.000     .5915146    1.115637
 altx_delinq |   .0214465   .0681657     0.31   0.753    -.1121558    .1550489
 egox_delinq |  -.0715577   .0677006    -1.06   0.291    -.2042484    .0611331
 simx_delinq |   .6681287   .2780009     2.40   0.016      .123257       1.213
   samex_sex |   .5573662    .111187     5.01   0.000     .3394436    .7752887
   transtrip |   .1925975   .0229775     8.38   0.000     .1475623    .2376327
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2    period3 
-------------+--------------------------------
        rate |    7.0775     9.2410     8.1198 
          se |    1.1714     1.5460     1.2751 
(conditional: rate = mean time to reach the observed distance, se = its SD)
RSiena effect names:
  altx_delinq                   delinq alter
  egox_delinq                   delinq ego
  simx_delinq                   delinq similarity
  samex_sex                     same sex
Covariates centred by their means, as RSiena's coCovar(centered = TRUE):
  delinq                            1.538
Convergence t-ratios (criterion: every |t| below 0.1; the overall maximum ratio below 0.25 is a separate criterion):
  outdegree                  0.007      reciprocity               -0.011
  altx_delinq               -0.002      egox_delinq                0.071
  simx_delinq                0.027      samex_sex                 -0.013
  transtrip                  0.024
Overall maximum convergence ratio:  0.120
```

- `simx_delinq` is 0.67 (z = 2.4): pupils prefer friends whose delinquency is *similar* to their own at the time.
  This is a selection effect, and with a changing covariate it is evaluated with each period's own values.
- `egox_delinq` (do pupils who are more delinquent name more friends?) and `altx_delinq` (are they named more?) are
  both close to zero.
- The line "Covariates centred by their means" (the program's own spelling) gives the mean used for centering (1.538). As in RSiena, covariates are
  centred, so the coefficient of `outdegree` changes a little when covariates are added, but the covariate coefficients
  do not.

(Delinquency can also be modeled as a *behavior* that changes with the network, as in
[Tutorial 4](../tutorial-4-selection-influence/). Use `tvcov()` when you want to treat it as given from outside, or
when the variable is not something that the network can influence.)

## A dyadic covariate: dyadcov()

Some explanatory variables belong to a *pair* of actors, not to a single one: kinship, distance, working in the same
unit, or a tie in another network. In this class the network `klas12b_primary` says whether two pupils attended the same
primary school. `dyadcov()` wants such a variable as a Stata **matrix**, with one row and one column per pupil, in the order of
the nodes of the waves. We copy the network into a Stata matrix called `primary` (`nwtomata` makes a Mata matrix, and
`st_matrix()` turns it into a Stata matrix):

```stata
. nwtomata klas12b_primary, mat(Pmata)
. mata: st_matrix("primary", Pmata)
```

```stata
. mata: printf("%g pairs of pupils went to the same primary school\n", sum(Pmata :== 1) / 2)
43 pairs of pupils went to the same primary school
```

The matrix is symmetric (a pair either shares a primary school or not): 43 pairs of pupils do. Adding it to the model:

```stata
. nwsaom, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4) outdegree reciprocity transtrip samex(sex) tvcov(delinq1 delinq2 delinq3) egox(delinq) altx(delinq) simx(delinq) dyadcov(primary) seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4
Actors: 26                             Periods: 3
----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------
klas12b_wave1~4 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
      outdegree |   -1.94283   .1093013   -17.77   0.000    -2.157056   -1.728603
    reciprocity |   .7683781    .127647     6.02   0.000     .5181945    1.018562
    altx_delinq |   .0191458   .0632189     0.30   0.762    -.1047609    .1430525
    egox_delinq |  -.0718817   .0651537    -1.10   0.270    -.1995807    .0558172
    simx_delinq |   .7131749    .271064     2.63   0.009     .1818992    1.244451
      samex_sex |   .5930596   .1130971     5.24   0.000     .3713933    .8147259
dyadcov_primary |   .4756035   .1284435     3.70   0.000      .223859     .727348
      transtrip |   .1907559   .0230929     8.26   0.000     .1454947     .236017
---------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2    period3 
-------------+--------------------------------
        rate |    7.7320     9.8524     8.5058 
          se |    1.3395     1.6763     1.3248 
Overall maximum convergence ratio: 0.112 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

`dyadcov_primary` is 0.48 (z = 3.7): a tie to a former primary-school classmate is more attractive, net of the other effects in the model.
Like all covariates, the matrix is centered by its mean.

### Counting only reciprocated ties: dyadcovrecip()

`dyadcovrecip()` uses the same matrix but counts the covariate for a tie **only if the tie is reciprocated**: does the
shared background matter more for mutual friendships?

```stata
. nwsaom, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4) outdegree reciprocity transtrip samex(sex) dyadcov(primary) dyadcovrecip(primary) seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4
Actors: 26                             Periods: 3
----------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
klas12b_wave1_to_k~4 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
---------------------+----------------------------------------------------------------
           outdegree |  -1.946985    .114067   -17.07   0.000    -2.170552   -1.723418
         reciprocity |   .7909601   .1360846     5.81   0.000     .5242391    1.057681
           samex_sex |   .6087187   .1157367     5.26   0.000     .3818789    .8355584
     dyadcov_primary |   .4258563    .179244     2.38   0.018     .0745446     .777168
dyadcovrecip_primary |   .0582198   .2974511     0.20   0.845    -.5247737    .6412134
           transtrip |   .1883312   .0218229     8.63   0.000     .1455592    .2311032
--------------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2    period3 
-------------+--------------------------------
        rate |    8.1016    10.1252     8.1203 
          se |    1.4618     1.7495     1.3012 
Overall maximum convergence ratio: 0.101 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The effect is 0.06 with a standard error of 0.30, so there is no sign that shared primary schooling matters *more* for
mutual friends: it makes any tie more likely (0.43 in this model, z = 2.4), not particularly the reciprocated ones.

## Things to try

- Use `tvcov(delinq1 delinq2 delinq3)` with `simx(delinq)` only, and see whether the other effects change.
- Add `samex(ethnicity)` or `absdiffx(age)`.
- A dyadic covariate that changes over time is `tvdyadcov()` (matrices called `stem1`, `stem2`, ...; see `help nwsaom`).
- `nwsaom` has many more effects of covariates (interactions of a covariate with triads, with degree, ...). The overview is on
  the [effects page](../effects/).

## Where next

[Tutorial 9](../tutorial-9-undirected-twomode/) leaves the directed one-mode network: undirected networks and two-mode networks.
