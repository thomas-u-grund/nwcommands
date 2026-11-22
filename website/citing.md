---
title: "Citing and licenses"
nav_order: 9
permalink: /citing/
description: "How to cite nwcommands, nwsaom, nwergm, nwdynam, nwrem, nwalaam, nwlsm and nwsbm, the license of each package, and where the releases are."
---

# Citing and licenses
{: .no_toc }

## How to cite

Cite the packages you used and report their versions. `nwversion` prints the version of the core and
lists the installed model packages; each model package prints its own version with `<name> version`, for
example `nwsaom version`.

The DOIs of the manuals below are the ones of all versions of the manual: each always leads to the latest manual, which describes the current release series of the package. Report the exact version that produced your results as printed by `nwversion` or `<package> version` (for example "nwsaom 1.9.1").

**nwcommands (core).** The core has no DOI. Cite the repository and the version:

> Grund, T. U. (2026). *nwcommands: Network Analysis in Stata* (version 3.35.0) [Computer software]. [https://github.com/thomas-u-grund/nwcommands](https://github.com/thomas-u-grund/nwcommands)

**nwsaom.** Cite the manual. It has a DOI:

> Grund, T. U. (2026). *nwsaom: Stochastic actor-oriented models in Stata. Manual.* Zenodo. [https://doi.org/10.5281/zenodo.23623807](https://doi.org/10.5281/zenodo.23623807)

**nwergm.** Cite the manual. It has a DOI:

> Grund, T. U. (2026). *nwergm: Exponential random graph models in Stata. Manual.* Zenodo. [https://doi.org/10.5281/zenodo.23661331](https://doi.org/10.5281/zenodo.23661331)

**nwdynam, nwrem, nwalaam, nwlsm and nwsbm.** Cite the manual of the package. Each has a DOI:

> Grund, T. U. (2026). *nwalaam: Autologistic actor attribute models in Stata. Manual.* Zenodo. [https://doi.org/10.5281/zenodo.24397901](https://doi.org/10.5281/zenodo.24397901)

> Grund, T. U. (2026). *nwdynam: Dynamic network actor models in Stata. Manual.* Zenodo. [https://doi.org/10.5281/zenodo.24398099](https://doi.org/10.5281/zenodo.24398099)

> Grund, T. U. (2026). *nwrem: Relational event models in Stata. Manual.* Zenodo. [https://doi.org/10.5281/zenodo.24398012](https://doi.org/10.5281/zenodo.24398012)

> Grund, T. U. (2026). *nwlsm: Latent space models for networks in Stata. Manual.* Zenodo. [https://doi.org/10.5281/zenodo.24398243](https://doi.org/10.5281/zenodo.24398243)

> Grund, T. U. (2026). *nwsbm: Stochastic block models for networks in Stata. Manual.* Zenodo. [https://doi.org/10.5281/zenodo.24398296](https://doi.org/10.5281/zenodo.24398296)

Each repository contains a `CITATION.cff` file, which GitHub shows as "Cite this repository".

The model packages follow established programs (R packages, and for nwalaam the Python program ALAAMEE) and methods papers, which you should cite as well.
Each section lists them: [nwsaom](../nwsaom/citation/), [nwdynam](../nwdynam/citation/),
[nwrem](../nwrem/citation/), [nwergm](../nwergm/citation/), [nwalaam](../nwalaam/citation/), [nwlsm](../nwlsm/citation/) and [nwsbm](../nwsbm/citation/).

## Licenses

| Package | License |
|---|---|
| nwcommands (core) | GNU General Public License, version 3 |
| nwsaom | GNU General Public License, version 3 |
| nwergm | GNU General Public License, version 3 |
| nwdynam | GNU General Public License, version 3 |
| nwrem | GNU General Public License, version 3 |
| nwalaam | GNU General Public License, version 3 |
| nwlsm | GNU General Public License, version 3 |
| nwsbm | GNU General Public License, version 3 |

All eight packages are free software. The full license text is the `LICENSE` file in each repository.
The model packages are separate from the core and need it to run; they contain none of its code.

## Releases

Each package has its own releases on GitHub:

| Package | Releases |
|---|---|
| nwcommands (core) | [github.com/thomas-u-grund/nwcommands/releases](https://github.com/thomas-u-grund/nwcommands/releases) |
| nwsaom | [github.com/thomas-u-grund/nwsaom/releases](https://github.com/thomas-u-grund/nwsaom/releases) |
| nwergm | [github.com/thomas-u-grund/nwergm/releases](https://github.com/thomas-u-grund/nwergm/releases) |
| nwdynam | [github.com/thomas-u-grund/nwdynam/releases](https://github.com/thomas-u-grund/nwdynam/releases) |
| nwrem | [github.com/thomas-u-grund/nwrem/releases](https://github.com/thomas-u-grund/nwrem/releases) |
| nwalaam | [github.com/thomas-u-grund/nwalaam/releases](https://github.com/thomas-u-grund/nwalaam/releases) |
| nwlsm | [github.com/thomas-u-grund/nwlsm/releases](https://github.com/thomas-u-grund/nwlsm/releases) |
| nwsbm | [github.com/thomas-u-grund/nwsbm/releases](https://github.com/thomas-u-grund/nwsbm/releases) |

To install a particular release of a model package, put its tag in the URL of `net install`, for
example `net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/v1.9.1/) replace`.
See [Installation & Setup](../tutorials/01-installation-setup/).

## Acknowledgments

The model packages follow the work of others: the Siena project (Snijders and colleagues) for nwsaom,
the statnet team for nwergm, the goldfish team (Stadtfeld, Hollway, Block and colleagues) for nwdynam and
Butts and the relevent package for nwrem. They are not affiliated with these projects and do not endorse
the Stata packages; errors in the Stata packages are the author's. The derivation of each package is
described in its own section.
