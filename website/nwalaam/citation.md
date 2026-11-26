---
title: "How to cite"
parent: "nwalaam (ALAAM)"
nav_order: 9
permalink: /nwalaam/citation/
description: "How to cite nwalaam, and the papers and software it builds on."
---

# How to cite

**nwalaam.** Cite the package by its repository and report the version that produced your results, as printed by
`nwalaam version` (for example "nwalaam 1.4.0"). To cite the software:

> Grund, T. U. (2026). *nwalaam: a Stata package for autologistic actor attribute models (version 1.4.0).* GitHub. [https://github.com/thomas-u-grund/nwalaam](https://github.com/thomas-u-grund/nwalaam)

Cite the manual, which has a DOI:

> Grund, T. U. (2026). *nwalaam: Autologistic actor attribute models in Stata. Manual.* Zenodo. [https://doi.org/10.5281/zenodo.24397901](https://doi.org/10.5281/zenodo.24397901)

The DOI is the one of all versions of the manual, so it always leads to the latest manual.

Please also cite the core package, nwcommands.

**The model and ALAAMEE.** `nwalaam` implements the model and the equilibrium-expectation estimator that ALAAMEE implements, so please also cite them:

- Stivala, A., Wang, P. and Lomi, A. (2024). ALAAMEE: Open-source software for fitting autologistic actor attribute models. *PLOS Complex Systems* 1(4), e0000021. ALAAMEE is on [GitHub](https://github.com/stivalaa/ALAAMEE) (MIT licence).
- Borisenko, A., Byshkin, M. and Lomi, A. (2019). A simple algorithm for scalable Monte Carlo inference. *arXiv:1901.00533*.
- Robins, G., Pattison, P. and Elliott, P. (2001). Network models for social influence processes. *Psychometrika* 66(2), 161-189.
- Daraganova, G. and Robins, G. (2013). Autologistic actor attribute models. In Lusher, D., Koskinen, J. and Robins, G. (eds), *Exponential Random Graph Models for Social Networks*, 102-114. Cambridge University Press.

MPNet (Wang, Robins and Pattison) is the other reference implementation of the model; the default estimator of `nwalaam`, stochastic approximation, is the one of MPNet.
