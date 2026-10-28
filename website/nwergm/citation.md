---
title: "How to cite"
parent: "nwergm (ERGM)"
nav_order: 9
permalink: /nwergm/citation/
description: "How to cite nwergm, and the statnet and ergm papers it builds on."
---

# How to cite

**nwergm.** Cite the package by repository and report the version that produced your results, as printed by
`nwergm version` (for example "nwergm 1.3.3"). Cite the manual, which has a DOI:

> Grund, T. U. (2026). *nwergm: Exponential random graph models in Stata. Manual for version 1.3.* Zenodo. [https://doi.org/10.5281/zenodo.23661331](https://doi.org/10.5281/zenodo.23661331)

The label "1.3" is the series of the manual and holds for all versions 1.3.x. Source code and releases are at [https://github.com/thomas-u-grund/nwergm](https://github.com/thomas-u-grund/nwergm).

Give the version printed by `nwergm version`: the operator terms and some other additions need version 1.1.0 or later.

**The model and the software it follows.** `nwergm` implements the ERGM framework and follows R's
`ergm` of the statnet project, so please also cite:

- Hunter, D.R., Handcock, M.S., Butts, C.T., Goodreau, S.M., Morris, M. (2008). ergm: A package to fit,
  simulate and diagnose exponential-family models for networks. *Journal of Statistical Software* 24(3), 1-29.
- Handcock, M.S., Hunter, D.R., Butts, C.T., Goodreau, S.M., Morris, M. (2008). statnet: Software tools
  for the representation, visualization, analysis and simulation of network data. *Journal of Statistical Software* 24(1), 1-11.

Depending on what you used, also cite the papers behind the method: Hunter and Handcock (2006) for the
curved exponential family and the pseudolikelihood, Hunter (2007) for the geometrically weighted terms,
Morris, Handcock and Hunter (2008) for the model terms and the TNT proposal, Hummel, Hunter and Handcock (2012)
for the Monte Carlo maximum likelihood algorithm, and Handcock and Gile (2010) if your network has missing
dyads. The references are listed in `help nwergm`.

**The core.** `nwergm` runs on the nwcommands core package; cite it as described in the documentation of the core (`help nwcommands`).
