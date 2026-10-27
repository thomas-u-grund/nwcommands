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
study. The four csv files (`s50g_actors.csv`, `s50g_wave1.csv` to `s50g_wave3.csv`) are also here. Download all the files into the folder in which you run the script. The commands were run with `nwsaom` 1.2.0 and the core 3.10.0 in Stata 18, and checked in Stata 17
(identical numbers). Joint estimation needs `nwsaom` 1.2 or later. The complete script and log are in [example.do](example.do) and [example.log](example.log).

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

Network data: 2 waves, 151 actors, directed
----------------------------------------------------------
wave          ties     density   avg. degree
1              246      0.0109         1.629
2              335      0.0148         2.219
----------------------------------------------------------
period      kept  created dissolved  Jaccard   Hamming
1->2         139      196       107    0.314       303
----------------------------------------------------------
```

The density looks very low (0.01) because the empty blocks between the classes are counted: all ties are within a class, and pairs of pupils from different classes cannot be friends in the model either
(`nwsaom` only lets a pupil choose among the pupils of the same class).

## A first joint model

The model of the earlier tutorials, `outdegree reciprocity transtrip`, for the four classes at once. The only new option is `groups(class)`:

```stata
. nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip seed(5)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: w1 w2
Actors: 151                            Periods: 4
Groups: 4 (variable class), actors per group: 45, 37, 33, 36; waves per group: 2, 2, 2, 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
    w1_to_w2 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.247226   .0808946   -27.78   0.000    -2.405776   -2.088675
 reciprocity |    1.86988   .1595137    11.72   0.000     1.557239    2.182522
   transtrip |   .4650632   .0590168     7.88   0.000     .3493924    .5807339
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period3    period5    period7 
-------------+-------------------------------------------
        rate |    6.4599     5.3856     2.2902     8.1389 
          se |    1.0048     1.3792     0.5385     1.9861 
Overall maximum convergence ratio: 0.067 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

**The header** says there are four groups, how many pupils are in each, and how many waves each has. **The coefficient table** is one table for all 151 pupils: friendships are reciprocated
(1.87) and closed (0.47) beyond what density alone gives. **The rates** come as four numbers, one for each class (each class has one period here). Pupils in the fourth class had about three and a half times as many opportunities to change a tie between
the waves as pupils in the third class (8.1 against 2.3); classes 1 and 2 are in between (6.5 and 5.4).

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
   outdegree |  -2.269    -2.328    -3.340    -2.006  
             |   0.116     0.206     0.451     0.137  
 reciprocity |   1.561     2.589     2.230     1.541  
             |   0.254     0.399     0.750     0.287  
   transtrip |   0.468     1.133     1.067     0.494  
             |   0.061     0.306     0.288     0.109  
------------------------------------------------------
                                          Legend: b/se
```

```stata
. nwsaom meta school1 school2 school3 school4

IWLS estimates (Snijders & Baerveldt 2003)
--------------------------------------------------------------------------------
      effect |   n      mean     s.e.       t       p       sd        Q    p(Q)
-------------+------------------------------------------------------------------
   outdegree |   4   -2.3772   0.2535   -9.38   0.003   0.5069     9.05   0.029
 reciprocity |   4    1.8653   0.2664    7.00   0.006   0.5328     5.91   0.116
   transtrip |   4    0.6958   0.1734    4.01   0.028   0.3468     8.39   0.039
--------------------------------------------------------------------------------
```

(The rest of the meta-analysis output is in the log.) Next to each other, the simple average of the four class estimates, the mean of the meta-analysis and the estimate of the joint model:

```stata
. matrix list cmp, format(%7.3f)

cmp[3,3]
            outdegree  reciprocity    transtrip
avg_classes    -2.486        1.980        0.791
  meta_IWLS    -2.377        1.865        0.696
      joint    -2.247        1.870        0.465
```

The three agree on the picture: the density effect is negative, reciprocity is strong, closure is positive. They differ in the details, and above all in the **standard errors**. The joint model's are small (0.08, 0.16, 0.06), those of the mean in the meta-analysis
are three times as large (0.25, 0.27, 0.17), because the joint model *assumes* that all classes have the same parameters, while the meta-analysis treats the parameters as varying between classes (estimated between-class standard deviations
of 0.51, 0.53 and 0.35) and does not take the sameness for granted. The heterogeneity test says that the classes do differ in the outdegree and the closure effects (p(Q) = 0.029 and 0.039). When such a test is clearly significant,
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
                   outdegree |  -2.239454   .0868974   -25.77   0.000     -2.40977   -2.069138
                 reciprocity |   1.885847    .163172    11.56   0.000     1.566036    2.205659
                     egox_c2 |   .1364565   .1939773     0.70   0.482    -.2437321    .5166451
                   transtrip |   .4965696   .0615531     8.07   0.000     .3759277    .6172114
interact_egox_c2_reciprocity |   1.119204   .3962136     2.82   0.005     .3426394    1.895768
----------------------------------------------------------------------------------------------
```

The interaction coefficient (1.12, z = 2.8) is the difference of the reciprocity effect between class 2 and the other classes: pupils in class 2 reciprocate more. (`egox_c2`, the main effect of the indicator,
is the difference in the tendency to send ties.) This is how RSiena's manual recommends letting parameters differ between groups, too.

## A behavior in several groups

A behavior is declared as in [Tutorial 4](../tutorial-4-selection-influence/): `behavior()` with its effects. In a joint model its effects are shared by all groups and its **rate is estimated for every period of every group**, like the rate of the
network. The 50 pupils of the second data set, cut into three groups, with alcohol use (1 to 5) at the three waves (`alc1 alc2 alc3`):

```stata
. nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip ///
>     behavior(alc1 alc2 alc3) linear quadratic avalt behegox behaltx seed(1)
----------------------------------------------------------------------------------------------------
SAOM co-evolution (Method of Moments), waves: g1 g2 g3
Actors: 50                             Periods: 6
Behavior: alc1 alc2 alc3
Groups: 3 (variable group), actors per group: 15, 20, 15; waves per group: 3, 3, 3
----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
     g1_to_g3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
    outdegree |  -2.979649   .2695164   -11.06   0.000    -3.507892   -2.451407
  reciprocity |    2.93249   .3884028     7.55   0.000     2.171235    3.693746
    transtrip |   .6542929   .1518174     4.31   0.000     .3567362    .9518496
      behegox |   .0223577   .1753387     0.13   0.899    -.3212998    .3660153
      behaltx |   .0115348   .1772157     0.07   0.948    -.3358017    .3588713
   beh_linear |   .3858774   .1753668     2.20   0.028     .0421649      .72959
beh_quadratic |  -.2719056    .139211    -1.95   0.051    -.5447541    .0009429
    beh_avalt |   .5038188   .3862251     1.30   0.192    -.2531685    1.260806
-------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2    period4    period5    period7    period8 
-------------+-----------------------------------------------------------------
network_rate |    3.6297     1.9451     5.7289     2.3628     1.1390     2.3669 
          se |    1.3939     0.9042     1.8273     0.6066     0.5659     1.0102 
behavior_r~e |    1.2869     1.4586     1.8702     2.0337     0.6656     1.4133 
          se |    0.5556     0.7007     0.6802     0.8578     0.3447     0.6553 
Overall maximum convergence ratio: 0.200 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Three groups with three waves each give six periods, with six network rates and six behavior rates (groups 1, 2 and 3 have the periods 1-2, 4-5 and 7-8). The effects are shared. In these small groups the estimated influence of the friends'
alcohol use (`beh_avalt` 0.50, z = 1.3) and the selection effects (`behegox`, `behaltx`) are not distinguishable from zero.

## Groups with different waves

The groups need not have been observed at the same occasions. Suppose group 1 was observed at all three waves, group 2 only at the first two and group 3 only at the last two. `gwaves()` gives the waves of each group by their position in `waves()`:

```stata
. nwsaom, waves(g1 g2 g3) groups(group) gwaves(2: 1 2 | 3: 2 3) outdegree reciprocity transtrip seed(1)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: g1 g2 g3
Actors: 50                             Periods: 4
Groups: 3 (variable group), actors per group: 15, 20, 15; waves per group: 3, 2, 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
    g1_to_g3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.682548   .2634191   -10.18   0.000     -3.19884   -2.166256
 reciprocity |   2.623762   .3910328     6.71   0.000     1.857352    3.390172
   transtrip |    .554422   .1317472     4.21   0.000     .2962022    .8126417
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2    period4    period6 
-------------+-------------------------------------------
        rate |    3.1495     1.5944     5.2404     2.0249 
          se |    1.0063     0.6410     1.3535     0.7708 
Overall maximum convergence ratio: 0.038 (criterion: below 0.25; met)
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

Test of time heterogeneity (score-type test; RSiena's sienaTimeTest)
----------------------------------------------------------------------
Joint test of all period-specific deviations:  c =   36.3357   d.f. = 25   p-value = 0.0667

Test of each effect (is its parameter the same in all periods?)
effect                           c  d.f.   p-value
outdegree                    3.080     5    0.6876
reciprocity                  2.672     5    0.7503
altx_alc                    10.794     5    0.0556
egox_alc                     8.384     5    0.1363
transtrip                   11.680     5    0.0394

Test of each group (are the parameters of the periods of the group the same as in the other groups?)
group                            c  d.f.   p-value
Group 1                      2.320     5    0.8033
Group 2                     13.036    10    0.2217
Group 3                     21.967    10    0.0153

Test of each period (all effects)
period                           c  d.f.   p-value
Period 1                     2.320     5    0.8033
Period 2                     6.085     5    0.2980
Period 3                     8.021     5    0.1551
Period 4                     7.133     5    0.2109
Period 5                    18.300     5    0.0026
Period 6                     4.452     5    0.4864
```

(The table of the period-specific deviations follows in the log.) The joint test is borderline (p = 0.067). The closure effect varies most across periods; group 3 is the group that differs from the others (p = 0.015), and period 5, the first
period of group 3 (the periods are numbered 1 to 6 here, not with RSiena's numbers of the rates), is where the model fits worst (p = 0.003). The test per group follows RSiena; in RSiena 1.6.14 the test that it calls the *group test* is the test per period. The matrices
`r(group)` and `r(period)` hold the numbers.

The score test asks whether effects that were left out are needed. Fit the model with the two alcohol effects held fixed at zero (`fix()`), then test them:

```stata
. estat score

Generalised score-type test of the model restricted by:
  (1)  altx_alc                 =    0.0000
  (2)  egox_alc                 =    0.0000
------------------------------------------------------------
Joint test:  c =    0.1870   d.f. = 2   p-value = 0.9107
  (1) altx_alc separately: c =   0.0405  d.f. = 1  p-value = 0.8404   one-sided:  -0.2014
  (2) egox_alc separately: c =   0.1719  d.f. = 1  p-value = 0.6785   one-sided:  -0.4146
```

The alcohol effects are not needed in the network model (p = 0.91). In the fit of the restricted model `nwsaom` says that the convergence criteria are not met for the two fixed effects: their t-ratios are exactly the
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
