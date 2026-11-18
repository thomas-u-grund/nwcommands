---
title: "Tutorial 1: A first ALAAM on the karate club"
parent: "nwalaam (ALAAM)"
nav_order: 2
description: "Fit a first autologistic actor attribute model with nwalaam to the karate club: the outcome and the network, the estimators side by side, and the exact maximum likelihood answer."
---

# Tutorial 1: A first ALAAM on the karate club

**Goal.** Fit an autologistic actor attribute model (ALAAM) with `nwalaam`, read the coefficients, and see what the two estimators of the package do on a network small enough that the exact answer is known.

**Data.** Zachary's karate club: 34 members of a university karate club and 78 friendship ties (undirected). The club split in two after a conflict; the
outcome is which side a member joined. Source: Zachary, W. W. (1977), *Journal of Anthropological Research* 33, 452-473; loaded from the website with `nwwebuse zachary`
(see the [data sets page](../../datasets/)). You need the core `nwcommands` and the `nwalaam` package (see [Install](../install/)); the commands were run with `nwalaam` 1.0.0.
The complete script and log are in [example.do](example.do) and [example.log](example.log).

## What an ALAAM does, in four sentences

A network is observed, and every actor has a yes/no outcome (here: which side of the split). An ALAAM asks which configurations of the outcome on the network are
common: do the actors with the outcome tend to be tied to each other (`contagion`), do they tend to have many ties (`activity`), and how many of them are there
(`density`, which plays the role of the intercept). The log odds that one actor has the outcome, given the outcomes of all others, is the sum of the
coefficients times the change in each statistic when this actor switches from no to yes. The probability of a whole outcome vector has a normalizing constant that no computer can sum
over for a realistic network, so the model is estimated by simulating outcome vectors.

## The network and the outcome

```stata
. nwwebuse zachary, nwclear
. tabulate group
      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |         16       47.06       47.06
          2 |         18       52.94      100.00
------------+-----------------------------------
      Total |         34      100.00

. generate byte faction = (group == 2)
```

The outcome is a 0/1 variable with one row per actor, here 18 members with the value 1. The network is `zachary_bin`.

## The pseudo-likelihood estimate

The quickest estimate treats each actor's log odds as if the others' outcomes were fixed, which is an ordinary logit of the outcome on the change statistics.
It is useful for starting values and a quick look, but its standard errors are too small, and it does not always exist:

```stata
. capture noisily nwalaam faction zachary_bin, effects(density activity contagion) mple
the pseudo-likelihood estimate does not exist (perfect prediction or collinear
effects).
convergence not achieved
. display "return code: " _rc
return code: 430
```

In the karate club the three change statistics separate the two sides perfectly, so the logit has no finite solution. The fit by simulation below does not have this problem.

## The default: stochastic approximation

```stata
. nwalaam faction zachary_bin, effects(density activity contagion) seed(20261118)
----------------------------------------------------------------------
Autologistic actor attribute model (stochastic approximation)
Outcome: faction (18 of 34)                    Network: zachary_bin
SA repetitions: 2 (converged: yes)             Proposals per iteration: 1000
----------------------------------------------------------------------
-----------------------------------------------------
     faction | Coefficient  Std. err.      z    P>|z|
-------------+---------------------------------------
     density |   .5395213   .9510325     0.57   0.571
    activity |  -.8397623   .3038426    -2.76   0.006
   contagion |   1.476303   .4046748     3.65   0.000
-----------------------------------------------------
All convergence t-ratios are within .1 in absolute value.
```

Stochastic approximation moves the coefficients until the simulated statistics have, on average, the values observed in the data, which is the maximum likelihood condition,
and it repeats until the convergence t-ratios are small (here after two repetitions). `seed()` makes the run reproducible.
The reading: after taking the number of ties of each member into account, members of the same side are tied to each other more often than
chance would give (`contagion` 1.48, z = 3.65), and members with many ties hold this side less often than the other effects explain (`activity` -0.84). The density coefficient is the intercept and has no substantive reading here.
Because a cross-sectional ALAAM only describes how the outcome is spread over the given network, "contagion" is a name for the statistic, not a finding that members influenced one another.

## The update of ALAAMEE

The reference implementation, ALAAMEE, estimates by an equilibrium-expectation (EE) update. `method(ee)` does the same, from independent runs:

```stata
. nwalaam faction zachary_bin, effects(density activity contagion) method(ee) runs(40) iterations(100000) seed(20261118)
----------------------------------------------------------------------
Autologistic actor attribute model (equilibrium expectation)
Outcome: faction (18 of 34)                    Network: zachary_bin
EE runs used: 40 of 40                         Acceptance rate: 0.234
----------------------------------------------------------------------
-----------------------------------------------------
     faction | Coefficient  Std. err.      z    P>|z|
-------------+---------------------------------------
     density |  -.0286145   .9728923    -0.03   0.977
    activity |  -.7477119   .2535431    -2.95   0.003
   contagion |   1.530625   .3592791     4.26   0.000
-----------------------------------------------------
All convergence t-ratios are within .3 in absolute value.
```

## Which one is right?

For 34 actors the question has an exact answer: there are 2^34 = 17,179,869,184 possible outcome vectors, and a program can run through all of them once, collect the three statistics of every
one, and find the maximum likelihood estimate and its standard errors without any simulation. (This was done once for this page; it is not a command of the package, and it
takes about ten seconds on a computer with sixteen cores.) The estimates side by side:

| | Density | Activity | Contagion |
|---|---|---|---|
| Exact maximum likelihood | 0.535 (0.941) | -0.832 (0.295) | 1.461 (0.394) |
| `nwalaam`, stochastic approximation (default) | 0.540 (0.951) | -0.840 (0.304) | 1.476 (0.405) |
| `nwalaam`, `method(ee)` | -0.029 (0.973) | -0.748 (0.254) | 1.531 (0.359) |
| ALAAMEE (Python), mean of 8 runs of 30,000 iterations | -0.033 | -0.742 | 1.600 |
| MPNet, as published with ALAAMEE | 0.381 (0.906) | -0.798 (0.292) | 1.452 (0.400) |

Standard errors in parentheses. Stochastic approximation lands on the exact maximum likelihood estimates, in all three coefficients and in the standard errors. The equilibrium-expectation update
of ALAAMEE, in `nwalaam` and in ALAAMEE's own Python program alike, stops at slightly different values; the largest difference is in `density`, 0.6 standard errors from the exact value.
The same pattern appears on a random network of 16 actors, where all 2^16 outcome vectors can also be enumerated, and on a simulated network of 500 actors, where the standard errors of the update
are too small for `density` and `activity` compared with a parametric bootstrap. We do not know the reason for the difference. The scale of it is small next to the standard errors, so for the
karate club the substantive conclusions do not change; but a result that is to be compared with ALAAMEE should be fitted with `method(ee)`, and one that is meant as the maximum likelihood estimate
with the default.

## Things to try

- Fit `effects(density contagion)` alone and compare it with the three-effect model.
- Add `saiter(2000)` to the default fit and compare the table with the one above: longer phases give a steadier result.
- Fit `method(ee)` with other seeds and see how much the EE estimates move from run to run.

## Next

[Tutorial 2](../tutorial-2-glasgow/) fits contagion and covariate effects for smoking in a school friendship network and checks the fit.
Back to the [overview of nwalaam](../).
