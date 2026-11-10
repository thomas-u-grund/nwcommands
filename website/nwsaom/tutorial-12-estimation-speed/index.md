---
title: "Tutorial 12: Conditional and unconditional estimation, threads and speed"
parent: "nwsaom (SAOM)"
nav_order: 13
description: "What conditional and unconditional estimation mean in nwsaom, how to restart an unconditional fit, how threads (cores) and the number of simulations (k0, k3) affect speed and precision."
---

# Tutorial 12: Conditional and unconditional estimation, threads and speed

**Goal.** Understand the choices in the "engine room": the two ways in which the rate of change can be handled, how to
restart a fit, how many threads the program uses, and how to lengthen the estimation when you want more precision.

**Data.** The Glasgow friendship data. The commands were run with `nwsaom` 1.5.13 and the core 3.17.2 in Stata 18, and
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

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.844922   .1303038   -21.83   0.000    -3.100313   -2.589531
 reciprocity |   2.559735   .1971215    12.99   0.000     2.173384    2.946086
   gwesp_.69 |   1.616059   .1531276    10.55   0.000     1.315935    1.916184
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

-----------------------------------
             |   period1    period2
-------------+---------------------
        rate |    6.5485     5.2031
          se |    1.0853     0.8963
-----------------------------------
Overall maximum convergence ratio: 0.108 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The header says "conditional". The stored rates are in `e(rates)`, and `e(conditional)` is 1:

```stata
. display e(conditional)
1

. matrix list e(rates)

e(rates)[1,2]
        period1    period2
rate  6.5484738  5.2031139
```

Now the unconditional version, with the option `unconditional`:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) unconditional seed(4)

SAOM (Method of Moments, unconditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |   -2.82048   .1366677   -20.64   0.000    -3.088344   -2.552617
 reciprocity |    2.53188    .196902    12.86   0.000     2.145959    2.917801
   gwesp_.69 |    1.59617   .1603044     9.96   0.000     1.281979    1.910361
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

-----------------------------------
             |   period1    period2
-------------+---------------------
        rate |    6.6348     5.3113
          se |    1.1334     0.7821
-----------------------------------
Overall maximum convergence ratio: 0.088 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The coefficients are nearly the same (-2.82, 2.53 and 1.60 against -2.84, 2.56 and 1.62), the rates agree (6.63 and 5.31 against 6.55 and 5.20), and so do the standard errors of
the rates. The two should agree on the same data, and here they do; the conditional version is RSiena's default for a single network and therefore also the default of `nwsaom`.
Some models **must** be unconditional because the amount of change cannot be fixed beforehand: models with
a co-evolving behavior, with composition change ([Tutorial 7](../tutorial-7-composition-missing/)), and with more than one dependent network. `nwsaom` switches
by itself; `e(conditional)` is 0 for them:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behavior(alcohol1 alcohol2 alcohol3) linear
>  quadratic avalt seed(4)

SAOM co-evolution (Method of Moments), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
Behavior: alcohol1 alcohol2 alcohol3

-------------------------------------------------------------------------------
glasgow1_to~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
    outdegree |  -2.820048   .1279268   -22.04   0.000     -3.07078   -2.569316
  reciprocity |   2.523647   .1904382    13.25   0.000     2.150395    2.896899
    gwesp_.69 |   1.604899   .1439355    11.15   0.000      1.32279    1.887007
   beh_linear |    .433305   .2463416     1.76   0.079    -.0495157    .9161257
beh_quadratic |  -.5425325   .3410789    -1.59   0.112    -1.211035    .1259698
    beh_avalt |   1.320896   .9158013     1.44   0.149    -.4740417    3.115834
-------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

-----------------------------------
             |   period1    period2
-------------+---------------------
network_rate |    6.5571     5.2518
          se |    1.0985     0.8951
behavior_r~e |    1.2407     1.6903
          se |    0.3276     0.4687
-----------------------------------
Overall maximum convergence ratio: 0.134 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

## Restarting a fit

If a fit has not converged (see [Tutorial 2](../tutorial-2-convergence/)), you start a new fit from the estimates with `nwsaom refit`.
For an unconditional fit it passes the coefficients with `theta0()` and also the rates with `rate0()`, one per period. By hand you
would give both options yourself. Here we restart the unconditional fit from above:

```stata
. quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) unconditional seed(4)

. nwsaom refit, seed(5)

------------------------------------------------------------------------------
nwsaom refit, run 1: starting from the last estimates (overall ratio 0.088)
------------------------------------------------------------------------------

SAOM (Method of Moments, unconditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.811847    .121935   -23.06   0.000    -3.050835   -2.572858
 reciprocity |   2.509225   .1793096    13.99   0.000     2.157785    2.860666
   gwesp_.69 |     1.6014   .1455336    11.00   0.000     1.316159    1.886641
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

-----------------------------------
             |   period1    period2
-------------+---------------------
        rate |    6.5959     5.2954
          se |    1.0474     0.8531
-----------------------------------
Overall maximum convergence ratio: 0.143 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met

nwsaom refit: 1 run; largest |t| 0.059, overall ratio 0.143 (converged)
```

The first fit had already converged (overall ratio 0.088), so the restart is only a demonstration: the estimates hardly
change, and the new overall ratio (0.143) differs only by Monte Carlo noise.

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
   1:      0.77 /        1 =       0.7690
   2:      0.49 /        1 =       0.4890
```

On the computer that produced this log, one thread needed 0.8 seconds and all cores 0.5 seconds, and the estimates of the two runs are identical
(the largest relative difference is 0). Larger networks and models with behavior profit more from the extra cores. Use `cores(1)` if you share
a computer, or want a log that does not depend on the machine.

## Longer simulations

`k0()` is the number of simulations in phase 1 (which estimates how the statistics respond to the parameters) and `k3()` the number in
phase 3 (the final run at the estimates, which gives the standard errors and the convergence t-ratios). The defaults are 50 and 1,000. More
simulations take longer and reduce the Monte Carlo noise:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) seed(4) k0(100) k3(3000) detail

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.842345   .1305741   -21.77   0.000    -3.098266   -2.586425
 reciprocity |   2.552154    .194464    13.12   0.000     2.171012    2.933297
   gwesp_.69 |   1.625141   .1563559    10.39   0.000     1.318689    1.931593
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

-----------------------------------
             |   period1    period2
-------------+---------------------
        rate |    6.5355     5.2215
          se |    1.1206     0.8820
-----------------------------------
(conditional: rate = mean time to reach the observed distance, se = its SD)
RSiena effect names:
  gwesp_.69                     GWESP I -> K -> J (69)
Convergence t-ratios (criterion: every |t| below 0.1; the overall maximum ratio below 0.25 is a separate criterion):
  outdegree                  0.067      reciprocity                0.024
  gwesp_.69                  0.050
Overall maximum convergence ratio:  0.117
```

The overall convergence ratio is 0.117, the t-ratios of the parameters are all below 0.07 in absolute value, and the estimates are close to the shorter runs. Use
longer runs for the model that you report; use the defaults while you are exploring.

## Things to try

- Compare `unconditional` and the default on your own model, with several seeds.
- Run a model on `cores(2)` and `cores(1)` and compare `timer` and the estimates.
- Add `seed(#)` to all models you report, and state the seed.
- Open the dialog with `db nwsaom`: every option of this tutorial is in it.

## Where next

[Tutorial 13](../tutorial-13-meta-analysis/) combines the fits of several groups.
