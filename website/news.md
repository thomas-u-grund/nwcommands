---
title: "Releases and news"
nav_order: 12
description: "Dated list of releases of nwcommands, nwsaom, nwergm, nwdynam and nwrem, and changes to this site."
permalink: /news/
---

# Releases and news
{: .no_toc }

Newest first. Announcements also go to the [nwcommands mailing list](https://groups.google.com/g/nwcommands). The full change history of each package is in its `CHANGELOG`, and every release has notes on GitHub.

All releases: [nwcommands](https://github.com/thomas-u-grund/nwcommands/releases), [nwsaom](https://github.com/thomas-u-grund/nwsaom/releases), [nwergm](https://github.com/thomas-u-grund/nwergm/releases), [nwdynam](https://github.com/thomas-u-grund/nwdynam/releases), [nwrem](https://github.com/thomas-u-grund/nwrem/releases).

## 25 October 2026

**nwsaom 1.0.3** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.3)). Dialog boxes for every option and effect (`db nwsaom`, `db nwsaom_multinet`, `db nwsaom_bayes`, `db nwsaom_meta`, `db nwsaom_describe`, `db nwsaom_estat`). A co-evolution fit whose behavior rate grows without bound (for example with the `behrate` effects `avexposure` or `avtinexposuredist2` on unsuitable data) now stops with return code 498 and a message, as RSiena does, instead of running for hours. The version is shown at the bottom of each help file. The manual is updated.

**nwergm 1.1.1** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.1.1)). Dialog boxes for every term and option (`db nwergm`, `db nwergm_simulate`, `db nwergm_estat`; nine tabs, with a section selector inside the crowded tabs). Four fixes: `estat gof` with `b1degree`/`b2degree` after a two-mode fit; `obsconstraints(b1degrees)` and `(b2degrees)` no longer crash Stata; `constraints(observed)` and `obsconstraints(observed)` follow R; `mcmletermination(none)` no longer fails for some seeds. The version is shown at the bottom of each help file.

## 24 October 2026

**nwcommands 3.1.1** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.1.1)). `nwinstall` no longer deletes a user's `profile.do` when the edit fails (Mac and Linux); help text for the `s50` example data corrected.

**nwcommands 3.1.0** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.1.0)). The core is now free software under the GNU General Public License, version 3. `nwinstall, gui` installs the "Network Analysis" menu. Neighbor lists are returned in sorted order, independent of earlier session state. The release branch is `main`; `master` is kept as a copy.

**nwsaom 1.0.2** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.2)). Behavior centring with missing behavior data now follows RSiena (mean of the wave means of the observed values). The convergence message states RSiena's two criteria on separate lines.

**nwergm 1.1.0** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.1.0)). The operator terms of ergm (`operators()`), the term `balance`, curved two-mode terms and `altkstar` with an estimated decay; `seed()` is reproducible across sessions. 125 of the 139 terms of ergm 4.12.0.

**Site.** New sections for [nwsaom](../nwsaom/), [nwergm](../nwergm/), [nwdynam](../nwdynam/) and [nwrem](../nwrem/), each with an install page, tutorials, a comparison with the R package and a citation page; pages for [choosing a package](../which-package/), [citing and licenses](../citing/) and [getting help](../help/).

**nwcommands 3.0.0** ([release notes](https://github.com/thomas-u-grund/nwcommands/releases/tag/v3.0.0), [all releases](https://github.com/thomas-u-grund/nwcommands/releases)). The core now contains only the core. The model commands `nwsaom`, `nwergm`, `nwdynam` and `nwrem` moved to packages of their own; install them with `nwinstall, models`. Scripts that call these commands need the model packages installed, so this is a breaking change. New: `nwinstall, models` and `nwversion`, which shows the version of the core and of the installed model packages.

**nwsaom 1.0.1** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.1), [all releases](https://github.com/thomas-u-grund/nwsaom/releases)). The help file documents `nwsaom version` and the stored results that report the version.

**nwsaom 1.0.0** ([release notes](https://github.com/thomas-u-grund/nwsaom/releases/tag/v1.0.0)). First release of nwsaom as a package of its own: stochastic actor-oriented models with method of moments, maximum likelihood and Bayesian estimation, compared with RSiena and multiSiena.

**nwergm 1.0.1** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.0.1), [all releases](https://github.com/thomas-u-grund/nwergm/releases)). The help file documents `nwergm version` and the stored results that report the version.

**nwergm 1.0.0** ([release notes](https://github.com/thomas-u-grund/nwergm/releases/tag/v1.0.0)). First release of nwergm as a package of its own: exponential random graph models for directed, undirected and bipartite networks, about 110 of the 139 ergm terms, maximum pseudolikelihood and Monte Carlo maximum likelihood.

**nwdynam 1.0.1** ([release notes](https://github.com/thomas-u-grund/nwdynam/releases/tag/v1.0.1), [all releases](https://github.com/thomas-u-grund/nwdynam/releases)). The help file documents `nwdynam version` and the stored results that report the version.

**nwdynam 1.0.0** ([release notes](https://github.com/thomas-u-grund/nwdynam/releases/tag/v1.0.0)). First release of nwdynam as a package of its own: dynamic network actor models with rate and choice submodels for event data, compared with goldfish.

**nwrem 1.0.1** ([release notes](https://github.com/thomas-u-grund/nwrem/releases/tag/v1.0.1), [all releases](https://github.com/thomas-u-grund/nwrem/releases)). The help file documents `nwrem version` and the stored results that report the version.

**nwrem 1.0.0** ([release notes](https://github.com/thomas-u-grund/nwrem/releases/tag/v1.0.0)). First release of nwrem as a package of its own: relational event models for event data, estimated by partial likelihood and compared with relevent.

## Earlier

nwcommands 2.0.0 (25 August 2026) was the last release with the four model families inside the core. The original releases, 1.x, date from 2014 and 2015.
