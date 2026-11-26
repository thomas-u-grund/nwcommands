---
title: "Tutorial 2: Effects and interpretation"
parent: "nwrem: relational events"
nav_order: 2
description: "Add actor covariates, a pair covariate and recency effects to a relational event model with nwrem, and read what each one says."
---

# Tutorial 2: Covariates, pairs and recency

**Goal.** Extend the model of [Tutorial 1](../tutorial-1-first-rem/) with the level of an employee in the reporting hierarchy (an attribute of one actor),
whether two employees have the same supervisor (an attribute of a pair), and with recency instead of frequency.

**Data.** The same e-mails as in Tutorial 1 (the first five days of the manufacturing company data: 631 e-mails among 144 employees; Michalski, R.
(2020), Harvard Dataverse, [doi:10.7910/DVN/6Z3CGX](https://doi.org/10.7910/DVN/6Z3CGX), CC0 1.0; Nurek, M. and Michalski, R. (2020), *Applied Sciences*
10(5), 1699), plus the attributes of the employees from the second file, `manufacturing_nodes`: the direct supervisor, the `level` (steps to the CEO; 0 to 5) and the division. Both files are loaded
with `nwwebuse` and described on the [data sets page](../../datasets/). You need the core `nwcommands` and `nwrem` (see [Install](../install/)); the commands were run with `nwrem`
1.1.2 and the core 3.25.1. Script and log: [example.do](example.do), [example.log](example.log).

## Where the covariates come from

The three kinds of covariate effects read their data from different places:

| Option | What it is | Where it is read from |
|---|---|---|
| `covsnd(var)` | an attribute of the sender | a variable with one row per actor |
| `covrec(var)` | an attribute of the receiver | a variable with one row per actor |
| `covint(var)` | the same attribute of sender and receiver, one shared coefficient | a variable with one row per actor |
| `covevent(net)` | a value for each ordered pair | another network with the same actors |

For the first three, `nwload mail, xvars` gives a dataset with one row per actor, in the actor order of the network (variable `_nwnode`); we merge the attributes into
it by the employee label, restore the order, and check the result:

```stata
. nwload mail, xvars
. gen str4 label = _nwnode
. gen long row = _n
. merge m:1 label using `staff', keep(master match) nogenerate
. sort row
. list _nwnode level supervisor division in 1/4
...
```

For `covevent()` we make a second network, `samesup`, with a tie from `i` to `j` if the two have the same direct supervisor. Mata builds
the matrix and `nwset` declares it:

```stata
. mata:
: V = st_sdata(., "supervisor")
: n = rows(V)
: S = J(n, n, 0)
: for (i = 1; i <= n; i++) {
>     for (j = 1; j <= n; j++) S[i, j] = (i != j) & (V[i] != "") & (V[i] == V[j])
> }
: end
. nwset, mat(S) name(samesup) directed
. nwset
(2 networks)
--------------------
      mail
      samesup
```

The pair covariate is read as given: an ordered pair has the value in its own cell, and nothing is symmetrised. Here
the relation is symmetric, so the matrix is as well.

## Actor covariates

Start from the model of the pair's history and add the level of the sender and of the receiver:

```stata
. nwrem mail, frpsndsnd frrecsnd
. estimates store hist
. nwrem mail, frpsndsnd frrecsnd covsnd(level) covrec(level)
. estimates store levels
...
Events: 631                            Log likelihood: -5.71e+03
...
   frpsndsnd |   3.114008   .2134949    14.59   0.000     2.695566     3.53245
    frrecsnd |   3.462617   .2013362    17.20   0.000     3.068005    3.857229
covsnd_level |  -.2328669    .040124    -5.80   0.000    -.3115084   -.1542254
covrec_level |  -.1210011   .0397191    -3.05   0.002    -.1988492    -.043153
```

Both coefficients are negative and clear: for each step further from the CEO, a person's odds of being the sender fall by a factor of
`exp(-0.23)`, about 0.79, and the odds of being the receiver by `exp(-0.12)`, about 0.89. People higher up in the hierarchy
send more e-mails and receive more of them. The effects of the pair's history hardly change (inertia 3.17 to 3.11, reciprocity of receipt 3.48 to 3.46).

## A pair covariate

```stata
. nwrem mail, frpsndsnd frrecsnd covevent(samesup)
...
covevent_same~p |   .3651419   .1365699     2.67   0.008     .0974698    .6328141
```

Having the same supervisor *raises* the odds that a given pair makes an e-mail by `exp(0.37)`, about 1.44, once the history of the pair is
in the model. A plausible reading is that colleagues who report to the same person work together; the model
only says that this is the pattern in these days of data. The effect is modest: the log likelihood improves by only 3.3 units over the history model.

## Recency instead of frequency

`frpsndsnd` and `frrecsnd` ask how large a *share* of the sender's contacts went to or came from this person.
`rsndsnd` and `rrecsnd` ask how *recently*: they are the reciprocal of the rank of this person among the sender's earlier
partners (most recent partner = rank 1, never contacted = 0). Only the order counts, not how often.

```stata
. nwrem mail, rsndsnd rrecsnd
. estimates store recent
. nwrem mail, frpsndsnd frrecsnd rsndsnd rrecsnd
. estimates store both
```

## Putting the models side by side

```stata
. estimates table hist levels samesuper recent both, b(%9.3f) stats(ll N)

--------------------------------------------------------------------------
    Variable |   hist       levels     samesuper    recent       both     
-------------+------------------------------------------------------------
   frpsndsnd |     3.166       3.114       3.114                  -0.044  
    frrecsnd |     3.480       3.463       3.394                  -0.446  
covsnd_level |                -0.233                                      
covrec_level |                -0.121                                      
covevent_s~p |                             0.365                          
     rsndsnd |                                         2.449       2.482  
     rrecsnd |                                         3.548       3.792  
-------------+------------------------------------------------------------
          ll | -5733.442   -5709.705   -5730.093   -5389.231   -5386.947  
           N |       631         631         631         631         631  
--------------------------------------------------------------------------

. lrtest levels hist
 LR chi2(2) = 47.47
Prob > chi2 = 0.0000
. lrtest both hist
 LR chi2(2) = 692.99
Prob > chi2 = 0.0000
```

Reading across the log likelihoods (higher, i.e. less negative, is better):

- Adding the levels improves on the history model by 24 log-likelihood units (LR test 47.5 on 2 degrees of freedom).
- Recency (-5389.2) fits clearly better than frequency (-5733.4) with the same number of parameters. Whom you wrote to *last* tells more than whom
  you wrote to most.
- Using both gives the best fit (-5386.9), but only 2.3 units better than recency alone: with the recency effects in the model, the
  frequency effects fall to zero or below (-0.04 and -0.45, the second with a p-value of 0.07), while the recency effects keep their size (2.45 to 2.48 and 3.55 to 3.79).
  Recency does all the work.

The `lrtest` between nested models is the formal comparison; between the frequency and the recency model, which are not nested, only the
log likelihoods can be compared.

## Things to try

- Use `covint(level)` in place of `covsnd` and `covrec`: it forces one coefficient for both roles.
- Build `samesup` with another attribute, such as `division`, and use it in `covevent()`.
- Fit `rsndsnd` and `rrecsnd` together with `covevent(samesup)`.

## Next

[Tutorial 3](../tutorial-3-comparing/) compares specifications more systematically and looks at the limits of the package.
Back to the [overview of nwrem](../).
