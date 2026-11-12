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
come with the core package: `nwwebuse klas12b`. The commands were run with `nwsaom` 1.6.0 and the core
3.22.0 in Stata 17. The complete script and log are in [example.do](example.do) and
[example.log](example.log).

## Look at the data

```stata
. nwsaom describe, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4)

Network data                        Number of actors  =        26
Directed                            Number of waves   =         4

------------------------------------------------------------------
        Wave |       Ties     Density   Avg. degree
-------------+----------------------------------------------------
           1 |         91      0.1400         3.500
           2 |        117      0.1800         4.500
           3 |        133      0.2046         5.115
           4 |        119      0.1831         4.577
------------------------------------------------------------------

------------------------------------------------------------------
      Period |    Kept   Created  Dissolved   Jaccard   Hamming
-------------+----------------------------------------------------
        1->2 |      60        57         31     0.405        88
        2->3 |      70        63         47     0.389       110
        3->4 |      75        44         58     0.424       102
------------------------------------------------------------------
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

SAOM (Method of Moments, conditional), waves: klas12b_wave1 klas12b_wave2 klas12b_wave3
klas12b_wave4
Actors: 26                             Periods: 3

------------------------------------------------------------------------------
klas12b_wa~4 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -1.908709   .1120223   -17.04   0.000    -2.128268   -1.689149
 reciprocity |   .8676614   .1249379     6.94   0.000     .6227875    1.112535
   samex_sex |   .5715298   .1149133     4.97   0.000     .3463039    .7967558
   transtrip |   .1901893    .021152     8.99   0.000     .1487321    .2316464
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

-----------------------------------------------
             |   period1    period2    period3 
-------------+---------------------------------
        rate |    7.4376     9.3813     7.8094
          se |    1.2613     1.5370     1.2074
-----------------------------------------------
Overall maximum convergence ratio: 0.075 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Girls and boys prefer same-sex friends (`samex_sex` 0.57, z = 5.0); reciprocity and transitive closure are positive,
and smaller than in the Glasgow data (reciprocity 0.87, against about 2.4 in Tutorial 1).

### tvcov(): one variable per period

`tvcov()` takes the covariate's variables in wave order, one per period: `tvcov(delinq1 delinq2 delinq3)`.
Period 1 uses `delinq1`, period 2 uses `delinq2`, period 3 uses `delinq3`; the value at the last wave is not used,
because it describes the end, not the beginning, of the last period. In the effects the covariate is called by its
**stem**, the name without the number, here `delinq`:

```stata
. nwsaom, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4) outdegree reciprocity transtrip samex(sex) tvcov(delinq1 delinq2 delinq3) egox(delinq) altx(delinq) simx(delinq) seed(4) detail

SAOM (Method of Moments, conditional), waves: klas12b_wave1 klas12b_wave2 klas12b_wave3
klas12b_wave4
Actors: 26                             Periods: 3

------------------------------------------------------------------------------
klas12b_wa~4 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -1.909047   .1098346   -17.38   0.000    -2.124319   -1.693775
 reciprocity |   .8595679   .1277293     6.73   0.000     .6092231    1.109913
 altx_delinq |   .0196642   .0645367     0.30   0.761    -.1068255    .1461538
 egox_delinq |  -.0727893   .0619222    -1.18   0.240    -.1941546     .048576
 simx_delinq |   .6756142   .2796635     2.42   0.016     .1274838    1.223745
   samex_sex |   .5527127   .1096979     5.04   0.000     .3377089    .7677166
   transtrip |   .1910667   .0239181     7.99   0.000     .1441881    .2379452
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

-----------------------------------------------
             |   period1    period2    period3 
-------------+---------------------------------
        rate |    7.1865     9.2301     8.1531
          se |    1.2214     1.4621     1.1953
-----------------------------------------------
(conditional: rate = mean time to reach the observed distance, se = its SD)
RSiena effect names:
  altx_delinq                   delinq alter
  egox_delinq                   delinq ego
  simx_delinq                   delinq similarity
  samex_sex                     same sex
Covariates centred by their means, as RSiena's coCovar(centered = TRUE):
  delinq                            1.538
Convergence t-ratios (criterion: every |t| below 0.1; the overall maximum ratio below 0.25 is a
separate criterion):
  outdegree                 -0.034      reciprocity               -0.058
  altx_delinq               -0.019      egox_delinq                0.007
  simx_delinq               -0.012      samex_sex                 -0.039
  transtrip                 -0.049
Overall maximum convergence ratio:  0.082
```

- `simx_delinq` is 0.68 (z = 2.4): pupils prefer friends whose delinquency is *similar* to their own at the time.
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

SAOM (Method of Moments, conditional), waves: klas12b_wave1 klas12b_wave2 klas12b_wave3
klas12b_wave4
Actors: 26                             Periods: 3

---------------------------------------------------------------------------------
klas12b_wave1~4 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
      outdegree |   -1.94886   .1162493   -16.76   0.000    -2.176704   -1.721015
    reciprocity |   .7786656    .135146     5.76   0.000     .5137844    1.043547
    altx_delinq |   .0160516   .0640705     0.25   0.802    -.1095242    .1416274
    egox_delinq |  -.0728846   .0641616    -1.14   0.256    -.1986391    .0528699
    simx_delinq |   .7101842   .2668065     2.66   0.008     .1872531    1.233115
      samex_sex |   .5938003   .1101646     5.39   0.000     .3778816    .8097189
dyadcov_primary |   .4702319   .1246676     3.77   0.000     .2258878     .714576
      transtrip |   .1901288   .0228653     8.32   0.000     .1453136     .234944
---------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

-----------------------------------------------
             |   period1    period2    period3 
-------------+---------------------------------
        rate |    7.7629     9.8091     8.4350
          se |    1.3783     1.6700     1.3559
-----------------------------------------------
Overall maximum convergence ratio: 0.154 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

`dyadcov_primary` is 0.47 (z = 3.8): a tie to a former primary-school classmate is more attractive, net of the other effects in the model.
Like all covariates, the matrix is centered by its mean.

### Counting only reciprocated ties: dyadcovrecip()

`dyadcovrecip()` uses the same matrix but counts the covariate for a tie **only if the tie is reciprocated**: does the
shared background matter more for mutual friendships?

```stata
. nwsaom, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4) outdegree reciprocity transtrip samex(sex) dyadcov(primary) dyadcovrecip(primary) seed(4)

SAOM (Method of Moments, conditional), waves: klas12b_wave1 klas12b_wave2 klas12b_wave3
klas12b_wave4
Actors: 26                             Periods: 3

--------------------------------------------------------------------------------------
klas12b_wave1_to_k~4 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
---------------------+----------------------------------------------------------------
           outdegree |  -1.948317   .1114505   -17.48   0.000    -2.166756   -1.729878
         reciprocity |   .7923934   .1361533     5.82   0.000     .5255379    1.059249
           samex_sex |    .612627    .113804     5.38   0.000     .3895754    .8356787
     dyadcov_primary |   .4284681   .1813008     2.36   0.018      .073125    .7838111
dyadcovrecip_primary |    .052875   .2971519     0.18   0.859     -.529532    .6352819
           transtrip |   .1882054   .0221048     8.51   0.000     .1448808      .23153
--------------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

-----------------------------------------------
             |   period1    period2    period3 
-------------+---------------------------------
        rate |    8.1304     9.9944     8.0419
          se |    1.4786     1.6545     1.2134
-----------------------------------------------
Overall maximum convergence ratio: 0.187 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): not met for
  outdegree (-0.158) reciprocity (-0.131) samex_sex (-0.163)
  transtrip (-0.167)
Convergence is good only if both criteria are met.
To refit starting from these estimates, type nwsaom refit.
```

The effect is 0.05 with a standard error of 0.30, so there is no sign that shared primary schooling matters *more* for
mutual friends: it makes any tie more likely (0.43 in this model, z = 2.4), not particularly the reciprocated ones. (In this run some t-ratios are above 0.1;
before reporting such a model, run `nwsaom refit` as in [Tutorial 2](../tutorial-2-convergence/).)

## Things to try

- Use `tvcov(delinq1 delinq2 delinq3)` with `simx(delinq)` only, and see whether the other effects change.
- Add `samex(ethnicity)` or `absdiffx(age)`.
- A dyadic covariate that changes over time is `tvdyadcov()` (matrices called `stem1`, `stem2`, ...; see `help nwsaom`).
- `nwsaom` has many more effects of covariates (interactions of a covariate with triads, with degree, ...). The overview is on
  the [effects page](../effects/).

## Where next

[Tutorial 9](../tutorial-9-undirected-twomode/) leaves the directed one-mode network: undirected networks and two-mode networks.
