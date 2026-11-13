---
title: "Tutorial 13: Combining several groups with a meta-analysis"
parent: "nwsaom (SAOM)"
nav_order: 14
description: "Fit the same stochastic actor-oriented model to several school classes and combine the estimates with nwsaom meta, the counterpart of RSiena's siena08."
---

# Tutorial 13: Combining several groups with a meta-analysis

**Goal.** Many studies have *several* independent networks of the same kind: school classes, teams, villages. A model fitted to one
class tells you about that class. `nwsaom meta` combines the fits of all classes into one answer: what is the typical effect, and how much do the classes differ?

**Data.** Four school classes from a Dutch study of adolescent friendship and delinquency, directed networks of
emotional support among 45, 37, 33 and 36 pupils, each observed twice (collected under the direction of
Chris Baerveldt; Houtzager and Baerveldt 1999; Snijders and Baerveldt 2003). They are the data that RSiena ships as `N3401`, `N3403`, `N3404` and `N3406` (first wave) and
`HN3401`, `HN3403`, `HN3404` and `HN3406` (second wave), and the Siena project distributes them as part of the larger Dutch social behavior data set
([www.stats.ox.ac.uk/~snijders/siena/BaerveldtData.html](https://www.stats.ox.ac.uk/~snijders/siena/BaerveldtData.html)). The data have no licence
statement of their own that we know of; no licence is asserted here: they are facts (who named whom), redistributed with citation of the source, and the terms of use on the
Siena page apply to anyone who reuses them. They are not part of the `nwwebuse` data sets; the eight comma-separated files are on this website, next to this tutorial
(`school1_wave1.csv`, `school1_wave2.csv`, ..., `school4_wave2.csv`; download them into the folder in which you run the script). The classes are numbered 1 to 4 here (they are
schools 1, 3, 4 and 6 of the original study). The commands were run with `nwsaom` 1.6.0 and the core 3.22.0 in Stata 17. The complete script and log
are in [example.do](example.do) and [example.log](example.log).

## The idea

If every class were fitted separately, we would get four sets of estimates. They would differ for two reasons: chance (each class has only a few dozen pupils), and
real differences (the classes may be run differently, or the pupils may behave differently). The meta-analysis, which follows
Snijders and Baerveldt (2003) and RSiena's `siena08`, treats each coefficient as a random draw from a normal distribution across classes. It estimates the **mean** of that distribution
(the typical effect), the **standard deviation between classes**, and tests whether the classes differ more than chance allows. The requirements are that all classes are fitted
with exactly the same model (same effects, same order) and that every fit is reasonably well converged.

## Reading the data and fitting each class

The script reads the matrices of each class from the csv files, makes them into networks with `nwset`, describes each class, fits the model `outdegree reciprocity transtrip`, and stores the
result with `estimates store`. We show the part for class 1 in detail:

```stata
Network data                        Number of actors  =        45
Directed                            Number of waves   =         2

------------------------------------------------------------------
        Wave |       Ties     Density   Avg. degree
-------------+----------------------------------------------------
           1 |        104      0.0525         2.311
           2 |        142      0.0717         3.156
------------------------------------------------------------------

------------------------------------------------------------------
      Period |    Kept   Created  Dissolved   Jaccard   Hamming
-------------+----------------------------------------------------
        1->2 |      64        78         40     0.352       118
------------------------------------------------------------------
```

Class 1 has 45 pupils and 104 ties at the first wave, 142 at the second. The other classes (the log shows them) are of similar size, but class 2 has a Jaccard index of only 0.24 (see the note
that `nwsaom describe` prints): fewer of its ties are stable. The fit for class 1:

```stata
School 1

SAOM (Method of Moments, conditional), waves: school1_w1 school1_w2
Actors: 45                             Periods: 1

------------------------------------------------------------------------------
school1_w1~2 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.273976   .1219228   -18.65   0.000    -2.512941   -2.035012
 reciprocity |   1.571259   .2381785     6.60   0.000     1.104438     2.03808
   transtrip |   .4693016   .0662087     7.09   0.000      .339535    .5990683
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

-------------------------
             |   period1
-------------+-----------
        rate |    7.1200
          se |    1.1922
-------------------------
Overall maximum convergence ratio: 0.103 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The estimates of all four classes are:

| class | pupils | outdegree | reciprocity | transtrip | rate |
|---|---|---|---|---|---|
| 1 | 45 | -2.27 | 1.57 | 0.47 | 7.12 |
| 2 | 37 | -2.34 | 2.61 | 1.13 | 3.66 |
| 3 | 33 | -3.33 | 2.27 | 1.04 | 3.10 |
| 4 | 36 | -2.01 | 1.55 | 0.49 | 6.27 |

Reciprocity and closure are positive in every class, but they differ in size: classes 1 and 4 look alike (reciprocity about 1.6, closure about 0.5, rates about 7 and 6), as do classes 2 and 3
(reciprocity 2.3 to 2.6, closure about 1.1, rates 3.7 and 3.1). Is this chance or a real difference?

## Combining the classes

```stata
. nwsaom meta school1 school2 school3 school4

Meta-analysis of separate fits                  Number of fits    =         4

Estimates with a standard error of 10 or more are excluded;
tests of the means use a t distribution with N-1 d.f.

IWLS estimates (Snijders and Baerveldt 2003)
------------------------------------------------------------------------------
      Effect |  N      Mean Std. err.        t   P>|t|      SD       Q     P>Q
-------------+----------------------------------------------------------------
   outdegree |  4   -2.3922    0.2552    -9.37   0.003  0.5104    9.44   0.024
 reciprocity |  4    1.8994    0.2698     7.04   0.006  0.5397    6.51   0.089
   transtrip |  4    0.6963    0.1711     4.07   0.027  0.3422    8.53   0.036
------------------------------------------------------------------------------

Maximum likelihood under normality: mean of the parameter
------------------------------------------------------------------------------
      Effect |           Mean      Std. err.              [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |        -2.2584         0.1071          -2.8379          -1.9836
 reciprocity |         1.8673         0.2259           1.3384           2.5535
   transtrip |         0.5202         0.0547           0.3965           1.0588
------------------------------------------------------------------------------

Maximum likelihood under normality: standard deviation between groups
------------------------------------------------------------------------------
      Effect |             SD              [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |         0.1163           0.0000           0.8546
 reciprocity |         0.2797           0.0000           1.0987
   transtrip |         0.0001           0.0000           0.6287
------------------------------------------------------------------------------

Fisher's combination of one-sided tests (chi-squared, 2N d.f.)
------------------------------------------------------------------------------
             |                     Right-sided                      Left-sided
      Effect |            chi2     Prob > chi2            chi2     Prob > chi2
-------------+----------------------------------------------------------------
   outdegree |           0.000           1.000         759.535           0.000
 reciprocity |         148.298           0.000           0.001           1.000
   transtrip |         118.941           0.000           0.000           1.000
------------------------------------------------------------------------------
Correlations of estimates and standard errors are in r(meta).

```

Read the output in four tables: the IWLS estimates, the two maximum likelihood tables (means, and standard deviations between classes) and Fisher's combination of tests.

**IWLS estimates** (the robust estimate of Snijders and Baerveldt). For every effect: the number of classes used (`n`), the estimated mean across classes and its standard error, a t test of the mean
(`t` and `P>|t|`, with *n* - 1 = 3 degrees of freedom), `SD`, the estimated standard deviation of the effect *between* classes, and `Q`, a test of heterogeneity with its p-value `P>Q`.

- The typical **reciprocity** effect is 1.90 (se 0.27, p = 0.006), the typical **closure** effect 0.70 (se 0.17, p = 0.027), and the typical **outdegree** effect -2.39 (se 0.26).
- The classes differ in the outdegree and in the closure effects (P>Q = 0.024 and 0.036) but there is no clear evidence of difference for reciprocity (P>Q = 0.089). The estimated
  standard deviations between classes are 0.51, 0.54 and 0.34. A small P>Q means: more variation than the standard errors of the single fits can account for.

**Maximum likelihood** under normality gives the mean and the between-class standard deviation again, with profile-likelihood confidence intervals. The ML means (-2.26, 1.87 and 0.52) are
close to the IWLS ones, and the intervals for the standard deviations are wide (for example 0 to 1.10 for reciprocity): with only four classes the size of the differences
between classes cannot be pinned down. Treat all the standard deviations as rough.

**Fisher's combination of one-sided tests** asks whether the effect has the same *sign* in all classes: the "right-sided" columns test for a positive effect, the "left-sided" for a negative one. Here positive
reciprocity and closure (right-tailed p < 0.001) and a negative outdegree effect (left-tailed p < 0.001) hold in the combination of the classes.

The last line points to the correlation between estimates and standard errors in `r(meta)`; a strong correlation would suggest that the estimates are biased.

## The results in r()

`nwsaom meta` leaves the effects-by-24 matrix `r(meta)` (all the numbers above, and more), the matrix of the group estimates `r(theta)` and their standard errors `r(se)`, one row per class:

```stata
. nwsaom meta school1 school2 school3 school4, notable
```

```stata
. matrix list r(theta), format(%7.3f)

r(theta)[4,3]
           outdegree  reciprocity    transtrip
school1       -2.274        1.571        0.469
school2       -2.343        2.611        1.133
school3       -3.331        2.266        1.043
school4       -2.011        1.554        0.494
```

## Meta-analysis or one joint model?

The meta-analysis fits every class on its own and asks how much the classes differ. The other way to use several groups is to fit **one model to all
classes at once**, with the option `groups()`: the classes then share the same effect parameters (and have rates of their own), and the estimates and standard errors
use the information of all classes together. [Tutorial 14](../tutorial-14-several-groups/) does this with the same four classes and compares the two: when the classes are small, or you believe they follow the same
process, the joint model is the better choice; when the question is how much the classes differ, as here, the meta-analysis is. The heterogeneity tests above
(p(Q) = 0.024 for outdegree and 0.036 for closure) are a reason for caution with a joint model of these four classes.

## Some cautions

- Four groups are very few for estimating a standard deviation. Meta-analysis is more informative with more groups; the numbers above show the method, not conclusions about Dutch classes.
- A fit with a standard error of 10 or more is dropped from the combination (`bound(10)` is the default; it is the signal of a fit that did not work, such as a class with almost no change).
- Combine the effects and look at the rates of the groups separately, as in the table above.
- Differences between groups can be explained, not only described: a covariate of the *group* (class size, a teacher's style) can be related to the single-group estimates.

## Things to try

- Add `gwesp(.69)` or `indegpopularity` to all four fits and combine again.
- Leave out one class (`nwsaom meta school1 school2 school4`) and see what changes.
- Change the level of the intervals: `nwsaom meta school1 school2 school3 school4, alpha(0.1)`.

## References

Houtzager, B. and Baerveldt, C. (1999). Just like normal: a social network study of the relation between petty crime and the intimacy of adolescent friendships.
*Social Behavior and Personality* 27: 177-192.

Snijders, T.A.B. and Baerveldt, C. (2003). A multilevel network study of the effects of delinquent behavior on friendship evolution.
*Journal of Mathematical Sociology* 27: 123-151.

## Where next

[Tutorial 14](../tutorial-14-several-groups/) estimates one model for all groups at once and compares it with this meta-analysis. The reference page of [`nwsaom`](../../reference/nwsaom) lists all commands and options; the page [nwsaom and RSiena](../rsiena/) lists what is different from RSiena.
