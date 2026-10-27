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
schools 1, 3, 4 and 6 of the original study). The commands were run with `nwsaom` 1.1.1 and the core 3.10.0 in Stata 18, and checked in Stata 17. The complete script and log
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
Network data: 2 waves, 45 actors, directed
----------------------------------------------------------
wave          ties     density   avg. degree
1              104      0.0525         2.311
2              142      0.0717         3.156
----------------------------------------------------------
period      kept  created dissolved  Jaccard   Hamming
1->2          64       78        40    0.352       118
----------------------------------------------------------
```

Class 1 has 45 pupils and 104 ties at the first wave, 142 at the second. The other classes (the log shows them) are of similar size, but class 2 has a Jaccard index of only 0.24 (see the note
that `nwsaom describe` prints): fewer of its ties are stable. The fit for class 1:

```stata
School 1
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: school1_w1 -> school1_w2
Actors: 45                             Estimated rate:  7.134 (1.231)
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
school1_w1~2 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.269302   .1159112   -19.58   0.000    -2.496483    -2.04212
 reciprocity |    1.56099   .2544959     6.13   0.000     1.062187    2.059793
   transtrip |   .4678417   .0606097     7.72   0.000     .3490489    .5866345
------------------------------------------------------------------------------
Overall maximum convergence ratio: 0.101 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The estimates of all four classes are:

| class | pupils | outdegree | reciprocity | transtrip | rate |
|---|---|---|---|---|---|
| 1 | 45 | -2.27 | 1.56 | 0.47 | 7.13 |
| 2 | 37 | -2.33 | 2.59 | 1.13 | 3.64 |
| 3 | 33 | -3.34 | 2.23 | 1.07 | 3.10 |
| 4 | 36 | -2.01 | 1.54 | 0.49 | 6.19 |

Reciprocity and closure are positive in every class, but they differ in size: classes 1 and 4 look alike (reciprocity about 1.5, closure about 0.5, rates about 7 and 6), as do classes 2 and 3
(reciprocity 2.2 to 2.6, closure about 1.1, rates 3.6 and 3.1). Is this chance or a real difference?

## Combining the classes

```stata
. nwsaom meta school1 school2 school3 school4

Meta-analysis of 4 fits (RSiena siena08): estimates with a standard error of at least 10 are excluded
Tests of mean parameters use a t distribution with n-1 d.f. (n = number of included groups).

IWLS estimates (Snijders & Baerveldt 2003)
--------------------------------------------------------------------------------
      effect |   n      mean     s.e.       t       p       sd        Q    p(Q)
-------------+------------------------------------------------------------------
   outdegree |   4   -2.3772   0.2535   -9.38   0.003   0.5069     9.05   0.029
 reciprocity |   4    1.8653   0.2664    7.00   0.006   0.5328     5.91   0.116
   transtrip |   4    0.6958   0.1734    4.01   0.028   0.3468     8.39   0.039
--------------------------------------------------------------------------------

Maximum likelihood under normality with  95% profile-likelihood intervals
----------------------------------------------------------------------------------------------
      effect |     mean     s.e.     lower    upper        sd    lower    upper
-------------+--------------------------------------------------------------------------------
   outdegree |  -2.2339   0.0940   -2.7705  -2.0006    0.0829   0.0000   0.7810
 reciprocity |   1.8256   0.2162    1.3163   2.5174    0.2423   0.0000   1.0805
   transtrip |   0.5115   0.0514    0.4104   1.0354    0.0001   0.0000   0.6001
----------------------------------------------------------------------------------------------

Fisher's combination of one-sided tests (chi-squared, 2n d.f.)
----------------------------------------------------------
      effect |     right       p      left       p
-------------+--------------------------------------------
   outdegree |     0.000   1.000   807.018   0.000
 reciprocity |   138.037   0.000     0.003   1.000
   transtrip |   127.633   0.000     0.000   1.000
----------------------------------------------------------
Correlation of estimates and standard errors (Spearman, t approximation for p): see r(meta) columns corr, corr_p.
```

Read the output in three parts.

**IWLS estimates** (the robust estimate of Snijders and Baerveldt). For every effect: the number of classes used (`n`), the estimated mean across classes and its standard error, a t test of the mean
(with *n* - 1 = 3 degrees of freedom), `sd`, the estimated standard deviation of the effect *between* classes, and `Q`, a test of heterogeneity with its p-value `p(Q)`.

- The typical **reciprocity** effect is 1.87 (se 0.27, p = 0.006), the typical **closure** effect 0.70 (se 0.17, p = 0.028), and the typical **outdegree** effect -2.38 (se 0.25).
- The classes differ in the outdegree and in the closure effects (p(Q) = 0.029 and 0.039) but there is no clear evidence of difference for reciprocity (p(Q) = 0.116). The estimated
  standard deviations between classes are 0.51, 0.53 and 0.35. A small p(Q) means: more variation than the standard errors of the single fits can account for.

**Maximum likelihood** under normality gives the mean and the between-class standard deviation again, with profile-likelihood confidence intervals. The ML means (-2.23, 1.83 and 0.51) are
close to the IWLS ones, and the intervals for the standard deviations are wide (for example 0 to 1.08 for reciprocity): with only four classes the size of the differences
between classes cannot be pinned down. Treat all the standard deviations as rough.

**Fisher's combination of one-sided tests** asks whether the effect has the same *sign* in all classes: the "right" column tests for a positive effect, the "left" for a negative one. Here positive
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
y1       -2.269        1.561        0.468
y1       -2.328        2.589        1.133
y1       -3.340        2.230        1.067
y1       -2.006        1.541        0.494
```

## Meta-analysis or one joint model?

The meta-analysis fits every class on its own and asks how much the classes differ. The other way to use several groups is to fit **one model to all
classes at once**, with the option `groups()`: the classes then share the same effect parameters (and have rates of their own), and the estimates and standard errors
use the information of all classes together. [Tutorial 14](../tutorial-14-several-groups/) does this with the same four classes and compares the two: when the classes are small, or you believe they follow the same
process, the joint model is the better choice; when the question is how much the classes differ, as here, the meta-analysis is. The heterogeneity tests above
(p(Q) = 0.029 for outdegree and 0.039 for closure) are a reason for caution with a joint model of these four classes.

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
