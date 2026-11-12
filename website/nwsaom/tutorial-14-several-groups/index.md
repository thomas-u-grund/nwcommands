---
title: "Tutorial 14: Several groups at once"
parent: "nwsaom (SAOM)"
nav_order: 15
description: "Estimate one stochastic actor-oriented model for several groups jointly with nwsaom's groups() option: the data layout, the rate of every group, a behavior in several groups, groups with different waves, tests after the fit, and when to prefer the meta-analysis."
---

# Tutorial 14: Several groups at once

**Goal.** [Tutorial 13](../tutorial-13-meta-analysis/) fitted each school class on its own and combined the estimates. Here you fit **one model to all
classes at once**. This is what RSiena does with `sienaGroupCreate()` and `siena07()`, and in `nwsaom` it is the option `groups()`. You learn how to arrange the data, how to read the
rates of the groups, how to add a behavior, what to do when the groups were not observed at the same occasions, and how to choose between the joint model and the meta-analysis.

**Data.** Two data sets, both distributed with RSiena. (1) The four Dutch school classes of Tutorial 13 (directed networks of emotional support among 45, 37, 33 and 36 pupils, two waves; collected under the direction of
Chris Baerveldt; Houtzager and Baerveldt 1999; Snijders and Baerveldt 2003; RSiena `N3401`, `N3403`, `N3404`, `N3406` and `HN3401`, ...). The data have no licence statement of their own that we know of; no licence is asserted here: they are facts,
redistributed with citation of the source, and the terms of use on the [Siena page](https://www.stats.ox.ac.uk/~snijders/siena/BaerveldtData.html) apply to anyone who reuses them. They are not part of `nwwebuse`; the eight csv
files are on this website next to this tutorial (`school1_wave1.csv`, ..., `school4_wave2.csv`). (2) The 50 pupils of the Teenage Friends and Lifestyle Study (RSiena `s50`, three waves, with alcohol use; Michell and Amos 1997; Pearson and West 2003, see
[Data sets](../../datasets/)), which for the demonstration in the second half of the tutorial are **cut into three artificial groups** of 15, 20 and 15 pupils (pupils 1-15, 16-35 and 36-50; ties between the groups removed). This is a stand-in for three classes, not a real multi-group
study. The four csv files (`s50g_actors.csv`, `s50g_wave1.csv` to `s50g_wave3.csv`) are also here. Download all the files into the folder in which you run the script. The commands were run with `nwsaom` 1.6.0 and the core 3.22.0 in Stata 17. Joint estimation needs `nwsaom` 1.2 or later. The complete script and log are in [example.do](example.do) and [example.log](example.log).

## The idea

In a joint analysis the classes share **one set of effect parameters**: the model assumes that the pupils in every class choose their friends by the same rules, with the same weight for reciprocity,
for closing triangles, and so on. What is **not** shared is the speed of change. Every class, and every period of every class, has a **rate of its own**: classes differ in how much they change between two waves, and the waves need not be
equally far apart. Two consequences:

- Small classes, each too small for a model on its own, can be analyzed together; the standard errors use the information of all classes.
- The joint model does not tell you how much the classes differ. If that is your question, use the meta-analysis of Tutorial 13, or let selected effects differ by group (see below).

## The data layout

The classes are stacked in one data set. The rows are the **pupils of all classes**, a variable (here `class`) says which class a pupil is in, and each wave of the network is one network on all 151 pupils that has **no ties between
classes** (a block-diagonal adjacency matrix: one block per class). A covariate is an ordinary variable of the data set. If there is a tie between two classes, `nwsaom` stops and says how many.

The first part of the script reads the csv files, removes the (few) ties of a pupil to itself, makes a pair of networks for each class (used for the separate fits later) and adds the matrices to two block-diagonal
matrices, which then become the networks `w1` and `w2` of all classes together:

```stata
. tabulate class

      class |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |         45       29.80       29.80
          2 |         37       24.50       54.30
          3 |         33       21.85       76.16
          4 |         36       23.84      100.00
------------+-----------------------------------
      Total |        151      100.00

. nwsaom describe, waves(w1 w2)

Network data                        Number of actors  =       151
Directed                            Number of waves   =         2

------------------------------------------------------------------
        Wave |       Ties     Density   Avg. degree
-------------+----------------------------------------------------
           1 |        246      0.0109         1.629
           2 |        335      0.0148         2.219
------------------------------------------------------------------

------------------------------------------------------------------
      Period |    Kept   Created  Dissolved   Jaccard   Hamming
-------------+----------------------------------------------------
        1->2 |     139       196        107     0.314       303
------------------------------------------------------------------
```

The density looks very low (0.01) because the empty blocks between the classes are counted: all ties are within a class, and pairs of pupils from different classes cannot be friends in the model either
(`nwsaom` only lets a pupil choose among the pupils of the same class).

## A first joint model

The model of the earlier tutorials, `outdegree reciprocity transtrip`, for the four classes at once. The only new option is `groups(class)`:

```stata
. nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip seed(5)

SAOM (Method of Moments, conditional), waves: w1 w2
Actors: 151                            Periods: 4
Groups: 4 (variable class), actors per group: 45, 37, 33, 36; waves per group: 2, 2, 2, 2

------------------------------------------------------------------------------
    w1_to_w2 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.246167   .0820687   -27.37   0.000    -2.407018   -2.085315
 reciprocity |   1.862864   .1569308    11.87   0.000     1.555285    2.170443
   transtrip |   .4655751   .0541992     8.59   0.000     .3593466    .5718035
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

----------------------------------------------------------
             |   period1    period3    period5    period7 
-------------+--------------------------------------------
        rate |    6.4989     5.3821     2.2893     8.2490
          se |    0.9714     1.4169     0.5299     2.1306
----------------------------------------------------------
Overall maximum convergence ratio: 0.017 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

**The header** says there are four groups, how many pupils are in each, and how many waves each has. **The coefficient table** is one table for all 151 pupils: friendships are reciprocated
(1.86) and closed (0.47) beyond what density alone gives. **The rates** come as four numbers, one for each class (each class has one period here). Pupils in the fourth class had about three and a half times as many opportunities to change a tie between
the waves as pupils in the third class (8.2 against 2.3); classes 1 and 2 are in between (6.5 and 5.4).

**Why are the rates called `period1`, `period3`, `period5`, `period7`?** RSiena numbers the periods of the combined series, and the step from the last wave of one class to the first wave of the next class is not a period (nothing happens
there). With two waves per class the periods are 1, 3, 5 and 7, and the numbers 2, 4 and 6 are those switches. `nwsaom` uses the same numbers so that its rate rows can be matched to RSiena's output. Three groups with three waves each have the periods
`period1 period2 period4 period5 period7 period8`. The matrices that the fit stores tell you which column is which:

```stata
. matrix list e(groupn)

e(groupn)[1,4]
    c1  c2  c3  c4
r1  45  37  33  36

. matrix list e(rates_group)

e(rates_group)[1,4]
    period1  period3  period5  period7
r1        1        2        3        4

. matrix list e(rates_period)

e(rates_period)[1,4]
    period1  period3  period5  period7
r1        1        3        5        7
```

`e(groupn)` is the number of pupils of each group, `e(rates_group)` the group of each rate and `e(rates_period)` RSiena's period number. `e(ngroups)`, `e(groupwaves)` and `e(groupvar)` hold the number of groups, the number of waves
of each group and the name of the group variable.

## Joint model or meta-analysis?

Fit the same four classes one by one and combine the fits, as in Tutorial 13:

```stata
. estimates table school1 school2 school3 school4, b(%7.3f) se(%7.3f)

------------------------------------------------------
    Variable | school1   school2   school3   school4  
-------------+----------------------------------------
   outdegree |  -2.274    -2.343    -3.331    -2.011
             |   0.122     0.214     0.428     0.141
 reciprocity |   1.571     2.611     2.266     1.554
             |   0.238     0.385     0.675     0.302
   transtrip |   0.469     1.133     1.043     0.494
             |   0.066     0.284     0.291     0.110
------------------------------------------------------
                                          Legend: b/se
```

```stata
. nwsaom meta school1 school2 school3 school4

IWLS estimates (Snijders and Baerveldt 2003)
------------------------------------------------------------------------------
      Effect |  N      Mean Std. err.        t   P>|t|      SD       Q     P>Q
-------------+----------------------------------------------------------------
   outdegree |  4   -2.3922    0.2552    -9.37   0.003  0.5104    9.44   0.024
 reciprocity |  4    1.8994    0.2698     7.04   0.006  0.5397    6.51   0.089
   transtrip |  4    0.6963    0.1711     4.07   0.027  0.3422    8.53   0.036
------------------------------------------------------------------------------
```

(The rest of the meta-analysis output is in the log.) Next to each other, the simple average of the four class estimates, the mean of the meta-analysis and the estimate of the joint model:

```stata
. matrix list cmp, format(%7.3f)

cmp[3,3]
               outdegree  reciprocity    transtrip
avg_classes       -2.490        2.001        0.785
  meta_IWLS       -2.392        1.899        0.696
      joint       -2.246        1.863        0.466
```

The three agree on the picture: the density effect is negative, reciprocity is strong, closure is positive. They differ in the details, and above all in the **standard errors**. The joint model's are small (0.08, 0.16, 0.05), those of the mean in the meta-analysis
are three times as large (0.26, 0.27, 0.17), because the joint model *assumes* that all classes have the same parameters, while the meta-analysis treats the parameters as varying between classes (estimated between-class standard deviations
of 0.51, 0.54 and 0.34) and does not take the sameness for granted. The heterogeneity test says that the classes do differ in the outdegree and the closure effects (p(Q) = 0.024 and 0.036). When such a test is clearly significant,
the joint model's standard errors are too optimistic.

**When to use which.**

- Use the **joint model** when you believe that the groups follow the same process, when each group is too small to be fitted alone, when you want one estimate with one standard error, or when you want a model that goes beyond the effects
  of single groups (a behavior co-evolving in all groups, below).
- Use the **meta-analysis** when the question is how much the groups differ, when you want to describe a population of groups (a mean effect and a between-group standard deviation), or when you do not want to assume that the groups share their
  parameters. Each group must be large enough for its own fit to converge.
- You can use both: the joint model first, the heterogeneity test of the meta-analysis as a check, and then a joint model in which some effects may differ between groups.

**Letting an effect differ between groups.** Add an indicator of the group and its interaction with the effect. Here reciprocity may differ for class 2:

```stata
. generate byte c2 = (class == 2)
. nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip egox(c2) interact(egox_c2#reciprocity) seed(5)
----------------------------------------------------------------------------------------------
                    w1_to_w2 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-----------------------------+----------------------------------------------------------------
                   outdegree |  -2.235427   .0821592   -27.21   0.000    -2.396456   -2.074398
                 reciprocity |   1.864939   .1691134    11.03   0.000     1.533482    2.196395
                     egox_c2 |   .1400424   .1937284     0.72   0.470    -.2396584    .5197431
                   transtrip |   .4968187    .057962     8.57   0.000     .3832153    .6104222
interact_egox_c2_reciprocity |   1.100587   .4208535     2.62   0.009     .2757298    1.925445
----------------------------------------------------------------------------------------------
```

The interaction coefficient (1.10, z = 2.6) is the difference of the reciprocity effect between class 2 and the other classes: pupils in class 2 reciprocate more. (`egox_c2`, the main effect of the indicator,
is the difference in the tendency to send ties.) This is how RSiena's manual recommends letting parameters differ between groups, too.

## A behavior in several groups

A behavior is declared as in [Tutorial 4](../tutorial-4-selection-influence/): `behavior()` with its effects. In a joint model its effects are shared by all groups and its **rate is estimated for every period of every group**, like the rate of the
network. The 50 pupils of the second data set, cut into three groups, with alcohol use (1 to 5) at the three waves (`alc1 alc2 alc3`):

```stata
. nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip ///
>     behavior(alc1 alc2 alc3) linear quadratic avalt behegox behaltx seed(1)

SAOM co-evolution (Method of Moments), waves: g1 g2 g3
Actors: 50                             Periods: 6
Behavior: alc1 alc2 alc3
Groups: 3 (variable group), actors per group: 15, 20, 15; waves per group: 3, 3, 3

-------------------------------------------------------------------------------
     g1_to_g3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
    outdegree |   -2.97652   .2708628   -10.99   0.000    -3.507401   -2.445639
  reciprocity |   2.932225   .4010968     7.31   0.000      2.14609     3.71836
    transtrip |   .6524343   .1433909     4.55   0.000     .3713933    .9334754
      behegox |   .0226293   .1657629     0.14   0.891      -.30226    .3475187
      behaltx |   .0072251   .1742447     0.04   0.967    -.3342883    .3487385
   beh_linear |   .3868227    .177321     2.18   0.029     .0392798    .7343655
beh_quadratic |  -.2763856   .1344151    -2.06   0.040    -.5398343   -.0129369
    beh_avalt |   .5175959   .3764368     1.37   0.169    -.2202067    1.255399
-------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

--------------------------------------------------------------------------------
             |   period1    period2    period4    period5    period7    period8 
-------------+------------------------------------------------------------------
network_rate |    3.6424     1.9581     5.6745     2.3518     1.1541     2.3119
          se |    1.2967     0.9412     1.6757     0.6873     0.4610     1.0138
behavior_r~e |    1.2842     1.4431     1.8853     2.0285     0.6628     1.4247
          se |    0.7216     0.6579     0.6827     0.8332     0.3364     0.6035
--------------------------------------------------------------------------------
Overall maximum convergence ratio: 0.211 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): not met for
  rate_period2 (0.101)
Convergence is good only if both criteria are met.
To refit starting from these estimates, type nwsaom refit.
```

Three groups with three waves each give six periods, with six network rates and six behavior rates (groups 1, 2 and 3 have the periods 1-2, 4-5 and 7-8). The effects are shared. In these small groups the estimated influence of the friends'
alcohol use (`beh_avalt` 0.52, z = 1.4) and the selection effects (`behegox`, `behaltx`) are not distinguishable from zero.
(The t-ratio of one rate is 0.101 in this run, at the edge of the criterion; refit before reporting.)

## Groups with different waves

The groups need not have been observed at the same occasions. Suppose group 1 was observed at all three waves, group 2 only at the first two and group 3 only at the last two. `gwaves()` gives the waves of each group by their position in `waves()`:

```stata
. nwsaom, waves(g1 g2 g3) groups(group) gwaves(2: 1 2 | 3: 2 3) outdegree reciprocity transtrip seed(1)

SAOM (Method of Moments, conditional), waves: g1 g2 g3
Actors: 50                             Periods: 4
Groups: 3 (variable group), actors per group: 15, 20, 15; waves per group: 3, 2, 2

------------------------------------------------------------------------------
    g1_to_g3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.676822   .2586404   -10.35   0.000    -3.183748   -2.169896
 reciprocity |   2.617165   .4142432     6.32   0.000     1.805263    3.429067
   transtrip |   .5477705   .1367602     4.01   0.000     .2797255    .8158156
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

----------------------------------------------------------
             |   period1    period2    period4    period6 
-------------+--------------------------------------------
        rate |    3.1403     1.6238     5.2689     1.9980
          se |    1.0861     0.6607     1.3756     0.7814
----------------------------------------------------------
Overall maximum convergence ratio: 0.064 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Four periods remain: two in group 1 and one each in groups 2 and 3. They keep the numbers of the combined series (1, 2, 4 and 6): period 3 is the switch from group 1 to group 2 and period 5 the switch from group 2 to group 3.
Group 3's first wave is not used, so its values do not matter.

## After the fit: time heterogeneity and score tests

Two postestimation commands work after a joint fit: `estat timetest` and `estat score` (Tutorial 5 explains both). After a fit with groups the periods are the periods of all groups, so the test of time heterogeneity answers two questions at once: are
the effects the same in all periods, and are they the same in all groups. It prints two more tables than for a single group, one for each group and one for each period. Here an unconditional fit with the covariate effects of alcohol use
(the tests use the simulated statistics of the fit):

```stata
. estat timetest, fixrates

Test of time heterogeneity (score-type test)
H0: the parameter of each effect is the same in all periods

---------------------------------------------------------
      Effect |          chi2        df        Prob > chi2
-------------+-------------------------------------------
   outdegree |         3.081         5             0.6875
 reciprocity |         2.857         5             0.7220
    altx_alc |        10.791         5             0.0557
    egox_alc |         8.193         5             0.1459
   transtrip |        10.335         5             0.0663
-------------+-------------------------------------------
       Joint |        36.338        25             0.0666
---------------------------------------------------------

H0: the parameters of the periods of a group are the same as in the other groups
---------------------------------------------------------
       Group |          chi2        df        Prob > chi2
-------------+-------------------------------------------
           1 |         2.512         5             0.7747
           2 |        14.204        10             0.1639
           3 |        19.699        10             0.0322
---------------------------------------------------------

Test of each period (all effects)
---------------------------------------------------------
      Period |          chi2        df        Prob > chi2
-------------+-------------------------------------------
           1 |         2.512         5             0.7747
           2 |         6.014         5             0.3049
           3 |         9.393         5             0.0944
           4 |         6.753         5             0.2397
           5 |        16.287         5             0.0061
           6 |         4.428         5             0.4896
---------------------------------------------------------

Period-specific deviations (one-step estimates) and separate tests
---------------------------------------------------------
      Effect |  Period   Deviation      chi2  Prob > chi2
-------------+-------------------------------------------
   outdegree |       2      0.3635     0.253       0.6151
   outdegree |       3      1.8492     0.481       0.4879
   outdegree |       4     -0.6176     1.355       0.2444
   outdegree |       5     -1.2576     0.156       0.6924
   outdegree |       6      1.6724     1.730       0.1884
 reciprocity |       2     -1.1435     0.138       0.7100
 reciprocity |       3     -2.2154     2.115       0.1458
 reciprocity |       4      0.5027     0.040       0.8412
 reciprocity |       5      0.1703     0.779       0.3775
 reciprocity |       6     -1.1711     0.672       0.4125
    altx_alc |       2      0.7122     4.756       0.0292
    altx_alc |       3      0.1672     0.069       0.7929
    altx_alc |       4     -0.1277     0.753       0.3856
    altx_alc |       5     -0.4399     5.822       0.0158
    altx_alc |       6      0.2905     0.070       0.7918
    egox_alc |       2     -0.1191     2.661       0.1028
    egox_alc |       3     -0.4459     0.014       0.9064
    egox_alc |       4     -0.4985     0.674       0.4117
    egox_alc |       5     -0.5893     5.185       0.0228
    egox_alc |       6     -0.1623     0.009       0.9225
   transtrip |       2     -0.0263     2.010       0.1563
   transtrip |       3     -0.7608     3.342       0.0675
   transtrip |       4     -0.1186     0.058       0.8102
   transtrip |       5      1.2466     7.742       0.0054
   transtrip |       6     -0.5735     0.002       0.9689
---------------------------------------------------------
```

(The table of the period-specific deviations follows in the log.) The joint test is borderline (p = 0.067). The alcohol-alter and the closure effects vary most across periods (p = 0.056 and 0.066); group 3 is the group that differs from the others (p = 0.032), and period 5, the first
period of group 3 (the periods are numbered 1 to 6 here, not with RSiena's numbers of the rates), is where the model fits worst (p = 0.006). The test per group follows RSiena; in RSiena 1.6.14 the test that it calls the *group test* is the test per period. The matrices
`r(group)` and `r(period)` hold the numbers.

The score test asks whether effects that were left out are needed. Fit the model with the two alcohol effects held fixed at zero (`fix()`), then test them:

```stata
. estat score

Score-type test of fixed effects
H0: each effect below equals its fixed value

-----------------------------------------------------------------
      Effect |  Fixed at      chi2   df  Prob > chi2  One-sided z
-------------+---------------------------------------------------
    altx_alc |    0.0000     0.023    1       0.8782       -0.153
    egox_alc |    0.0000     0.131    1       0.7178       -0.361
-------------+---------------------------------------------------
       Joint |               0.156    2       0.9248
-----------------------------------------------------------------

One-step estimates (restricted estimates plus the one-step correction)
-----------------------------------------------------------------
      Effect |    Estimate
-------------+---------------------------------------------------
   outdegree |     -2.9623
 reciprocity |      2.9244
    altx_alc |      0.0114
    egox_alc |     -0.0532
   transtrip |      0.6418
       rate1 |      3.6149
       rate2 |      1.9008
       rate3 |      5.7916
       rate4 |      2.3324
       rate5 |      1.1042
       rate6 |      2.3262
-----------------------------------------------------------------
```

The alcohol effects are not needed in the network model (p = 0.92). In the fit of the restricted model `nwsaom` says that the convergence criteria are not met for the two fixed effects: their t-ratios are exactly the
quantity the score test examines, not a failure of the estimation.

## Does it agree with RSiena?

The same models were fitted in RSiena 1.6.14 (R 4.6.0) with `sienaGroupCreate()` and `siena07()`, ten runs of each program (seeds 1 to 10). The means over the ten runs:

| model | parameter | nwsaom | RSiena |
|---|---|---|---|
| four classes | outdegree | -2.247 | -2.248 |
| | reciprocity | 1.868 | 1.870 |
| | transitive triplets | 0.465 | 0.464 |
| | rates (periods 1, 3, 5, 7) | 6.50, 5.38, 2.31, 8.17 | 6.51, 5.38, 2.31, 8.16 |
| three groups with alcohol use | reciprocity | 2.933 | 2.936 |
| | transitive triplets | 0.656 | 0.657 |
| | alcohol linear shape | 0.388 | 0.384 |
| | alcohol quadratic shape | -0.276 | -0.273 |
| | alcohol average alter | 0.521 | 0.512 |
| groups with waves 3, 2, 2 | outdegree | -2.680 | -2.677 |
| | reciprocity | 2.618 | 2.615 |
| | transitive triplets | 0.558 | 0.556 |
| time test, joint (25 d.f.) | chi-squared | 37.9 | 38.7 |
| score test, two effects (2 d.f.) | chi-squared | 0.17 | 0.18 |

The two programs agree to within the simulation error of a single run (the estimates vary by about 0.005 to 0.02 from seed to seed), and so do the standard errors, the rates and the tests of the individual effects and periods. In RSiena the first model reads:

```r
library(RSiena)
rd  <- function(f) { m <- as.matrix(read.csv(f, header = FALSE)); diag(m) <- 0; m }
mk  <- function(s) sienaDataCreate(sienaDependent(array(c(rd(sprintf("school%d_wave1.csv", s)), rd(sprintf("school%d_wave2.csv", s))),
                                    dim = c(nrow(rd(sprintf("school%d_wave1.csv", s))), nrow(rd(sprintf("school%d_wave1.csv", s))), 2))))
gd  <- sienaGroupCreate(lapply(1:4, mk))
eff <- includeEffects(getEffects(gd), recip, transTrip)
siena07(sienaAlgorithmCreate(projname = NULL, seed = 5), data = gd, effects = eff)
```

RSiena 1.6.14 stops with an error for groups with *different* numbers of waves, although its manual allows them; for that model the comparison above uses the equivalent object in which the first group is split into two groups of the same pupils (waves 1-2 and waves 2-3).

## What is not (yet) available with groups

`groups()` stops with a message when it is combined with maximum likelihood (`ml`) or Bayesian estimation (`nwsaom bayes`), two-mode or undirected networks, `nwsaom multinet`, several behaviors, `structural()`, `joinat()`/`leaveat()` (`present()` works),
`behrate()`, or with the effects that use a constant of the whole data set (the centered degree effects `inpopc`, `outpopc`, `outactc`, `inactc`, `degplus`, `degplusc`, and `avdeg`, `transtriads`, structural equivalence). After a fit with groups, `estat gof`, `estat simulate`
and `estat importance` are not available (`estat timetest` and `estat score` are). With missing behavior values together with the selection effects `behegox` and `behaltx`, `nwsaom` and RSiena give different estimates in groups (in a single group they agree), so
treat that combination with caution.

## Some cautions

- The groups must be separate actor sets with the same variables and the same kind of network; a group needs at least three actors.
- A joint model assumes that the groups share their parameters. Check that with the heterogeneity test of the meta-analysis, with `estat timetest` after the fit, or by letting an effect differ with an interaction.
- Larger and more active groups carry more information and weigh more in the joint estimates; look at the sizes of your groups.
- Rates are never shared, so a joint model has as many rate parameters as there are periods in all groups together.

## Things to try

- Add `gwesp(.69)` or `indegpopularity` to the joint model of the classes and compare with the meta-analysis of the same model.
- Let the reciprocity effect differ for each class: make an indicator for every class but one and interact each with `reciprocity`.
- Add `unconditional` to the joint model of the four classes and compare the rates.
- Run `estat timetest` after a joint fit of the four classes (it needs three waves: use the 50 pupils).

## References

Houtzager, B. and Baerveldt, C. (1999). Just like normal: a social network study of the relation between petty crime and the intimacy of adolescent friendships.
*Social Behavior and Personality* 27: 177-192.

Michell, L. and Amos, A. (1997). Girls, pecking order and smoking. *Social Science & Medicine* 44: 1861-1869.

Pearson, M. and West, P. (2003). Drifting smoke rings: social network analysis and Markov processes in a longitudinal study of friendship groups and risk-taking.
*Connections* 25(2): 59-76.

Snijders, T.A.B. and Baerveldt, C. (2003). A multilevel network study of the effects of delinquent behavior on friendship evolution.
*Journal of Mathematical Sociology* 27: 123-151.

## Where next

[Tutorial 13](../tutorial-13-meta-analysis/) is the meta-analysis. The reference page of [`nwsaom`](../../reference/nwsaom) lists all commands and options; the page [nwsaom and RSiena](../rsiena/) lists what is different from RSiena.
