---
title: "Tutorial 12: Conditional and unconditional estimation, threads and speed"
parent: "nwsaom (SAOM)"
nav_order: 13
description: "What conditional and unconditional estimation mean in nwsaom, how to restart an unconditional fit, how threads (cores) and the number of simulations (k0, k3) affect speed and precision."
---

# Tutorial 12: Conditional and unconditional estimation, threads and speed

**Goal.** Understand the choices in the "engine room": the two ways in which the rate of change can be handled, how to
restart a fit, how many threads the program uses, and how to lengthen the estimation when you want more precision.

**Data.** The Glasgow friendship data. The commands were run with `nwsaom` 1.1.1 and the core 3.10.0 in Stata 18, and
checked in Stata 17. The timings are those of one computer and only show the order of magnitude. The complete script and log are in [example.do](example.do) and
[example.log](example.log).

## Conditional and unconditional estimation

Between two waves the network changes through many small steps. How many steps there were is the **rate**. There are two ways to
handle it in the estimation.

- **Conditional** estimation takes the amount of change that was *observed* as given: a simulated period ends as soon as the simulated
  network is as far from the starting network as the observed one is. The rate is then not estimated by the main algorithm; it is computed afterwards as the average time the
  simulation needed. This is RSiena's default for one network, and `nwsaom`'s.
- **Unconditional** estimation lets the simulation run for a fixed time and estimates the rate together with the other
  parameters, as a further parameter.

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.854856   .1400576   -20.38   0.000    -3.129364   -2.580348
 reciprocity |   2.578892   .2021555    12.76   0.000     2.182674    2.975109
   gwesp_.69 |   1.617413    .164666     9.82   0.000     1.294673    1.940152
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    6.5511     5.2412 
          se |    1.0627     0.8944 
Overall maximum convergence ratio: 0.095 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The header says "conditional". The stored rates are in `e(rates)`, and `e(conditional)` is 1:

```stata
. display e(conditional)
1
. matrix list e(rates)

e(rates)[1,2]
        period1    period2
rate  6.5511083  5.2412283
```

Now the unconditional version, with the option `unconditional`:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) unconditional seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, unconditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.810665   .1386126   -20.28   0.000     -3.08234   -2.538989
 reciprocity |   2.525851    .190443    13.26   0.000      2.15259    2.899112
   gwesp_.69 |   1.586733   .1643596     9.65   0.000     1.264594    1.908872
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    6.5512     5.2774 
          se |    1.1503     0.9639 
Overall maximum convergence ratio: 0.117 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The coefficients are nearly the same (-2.81, 2.53 and 1.59 against -2.85, 2.58 and 1.62), the rates agree (6.55 and 5.28 against 6.55 and 5.24), and the standard errors of the rates are
a little larger. The two should agree on the same data, and here they do; the conditional version is RSiena's default for a single network and therefore also the default of `nwsaom`.
Some models **must** be unconditional because the amount of change cannot be fixed beforehand: models with
a co-evolving behavior, with composition change ([Tutorial 7](../tutorial-7-composition-missing/)), and with more than one dependent network. `nwsaom` switches
by itself; `e(conditional)` is 0 for them:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt seed(4)
----------------------------------------------------------------------------------------------------
SAOM co-evolution (Method of Moments), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
Behavior: alcohol1 alcohol2 alcohol3
----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
glasgow1_to~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
    outdegree |  -2.814302   .1305773   -21.55   0.000    -3.070229   -2.558375
  reciprocity |   2.508239   .1940713    12.92   0.000     2.127866    2.888611
    gwesp_.69 |   1.598756   .1545302    10.35   0.000     1.295882    1.901629
   beh_linear |    .433306   .2458313     1.76   0.078    -.0485145    .9151264
beh_quadratic |  -.5378829   .3190152    -1.69   0.092    -1.163141    .0873755
    beh_avalt |   1.314275   .9087988     1.45   0.148    -.4669378    3.095488
-------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
network_rate |    6.5594     5.3153 
          se |    1.0927     0.9757 
behavior_r~e |    1.2354     1.6715 
          se |    0.3484     0.4157 
Overall maximum convergence ratio: 0.138 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

## Restarting a fit

If a fit has not converged (see [Tutorial 2](../tutorial-2-convergence/)), you start a new fit from the estimates. For an unconditional fit
you pass the coefficients with `theta0()` as before and also the rates with `rate0()`, one per period:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) unconditional theta0(`=b[1,1]' `=b[1,2]' `=b[1,3]') rate0(`=r[1,1]' `=r[1,2]') seed(5)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, unconditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.815351   .1309199   -21.50   0.000     -3.07195   -2.558753
 reciprocity |   2.533411   .1892364    13.39   0.000     2.162514    2.904307
   gwesp_.69 |   1.588418   .1657104     9.59   0.000     1.263631    1.913204
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    6.5886     5.3371 
          se |    1.0602     0.8057 
Overall maximum convergence ratio: 0.064 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The restarted fit has a smaller overall convergence ratio (0.064 against 0.117).

## Threads and speed

The simulations, which take nearly all the time, run in a compiled plugin and in parallel. `e(engine)` says `native` when the plugin was used.
`cores(#)` sets the number of threads: the default `0` uses all physical cores, `cores(1)` runs on one. Each simulation uses its own
random stream, which is derived from the seed and the simulation's number, so the results do **not** depend on the number of threads. We time a five-effect model:

```stata
. display e(engine)
native
```

```stata
. display "largest difference between the two sets of estimates: " mreldif(b1, b2)
largest difference between the two sets of estimates: 0
```

```stata
. timer list
   1:      1.33 /        1 =       1.3290
   2:      0.68 /        1 =       0.6830
```

On the computer that produced this log, one thread needed 1.3 seconds and all cores 0.7 seconds, and the estimates of the two runs are identical
(the largest relative difference is 0). Larger networks and models with behavior profit more from the extra cores. Use `cores(1)` if you share
a computer, or want a log that does not depend on the machine.

## Longer simulations

`k0()` is the number of simulations in phase 1 (which estimates how the statistics respond to the parameters) and `k3()` the number in
phase 3 (the final run at the estimates, which gives the standard errors and the convergence t-ratios). The defaults are 50 and 1,000. More
simulations take longer and reduce the Monte Carlo noise:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) seed(4) k0(100) k3(3000) detail
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.853009   .1314381   -21.71   0.000    -3.110623   -2.595395
 reciprocity |   2.573407   .1911977    13.46   0.000     2.198666    2.948147
   gwesp_.69 |   1.611978   .1587291    10.16   0.000     1.300875    1.923082
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    6.5956     5.2375 
          se |    1.1635     0.8800 
(conditional: rate = mean time to reach the observed distance, se = its SD)
RSiena effect names:
  gwesp_.69                     GWESP I -> K -> J (69)
Convergence t-ratios (criterion: every |t| below 0.1; the overall maximum ratio below 0.25 is a separate criterion):
  outdegree                 -0.052      reciprocity               -0.047
  gwesp_.69                 -0.077
Overall maximum convergence ratio:  0.090
```

The overall convergence ratio is 0.09, the t-ratios of the parameters are all below 0.08 in absolute value, and the estimates are close to the shorter runs. Use
longer runs for the model that you report; use the defaults while you are exploring.

## Things to try

- Compare `unconditional` and the default on your own model, with several seeds.
- Run a model on `cores(2)` and `cores(1)` and compare `timer` and the estimates.
- Add `seed(#)` to all models you report, and state the seed.
- Open the dialog with `db nwsaom`: every option of this tutorial is in it.

## Where next

[Tutorial 13](../tutorial-13-meta-analysis/) combines the fits of several groups.
