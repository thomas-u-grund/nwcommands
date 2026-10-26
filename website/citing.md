---
title: "Citing and licenses"
nav_order: 9
permalink: /citing/
description: "How to cite nwcommands, nwsaom, nwergm, nwdynam and nwrem, the license of each package, and where the releases are."
---

# Citing and licenses
{: .no_toc }

## How to cite

Cite the packages you used and report their versions. `nwversion` prints the version of the core and
lists the installed model packages; each model package prints its own version with `<name> version`, for
example `nwsaom version`.

**nwcommands (core).** The core has no DOI. Cite the repository and the version:

> Grund, T. U. (2026). *nwcommands: Network Analysis in Stata* (version 3.9.2) [Computer software]. [https://github.com/thomas-u-grund/nwcommands](https://github.com/thomas-u-grund/nwcommands)

**nwsaom.** Cite the manual. It has a DOI:

> Grund, T. U. (2026). *nwsaom: Stochastic actor-oriented models in Stata. Manual for version 1.1.* Zenodo. [https://doi.org/10.5281/zenodo.23623807](https://doi.org/10.5281/zenodo.23623807)

The DOI is the one of all versions of the manual; the label "1.1" is the series and holds for all versions 1.1.x. Report the exact version that produced your results as printed by `nwsaom version` (for example "nwsaom 1.1.0").

**nwergm, nwdynam and nwrem.** These have no DOI. Cite the repository and the version:

> Grund, T. U. (2026). *nwergm: a Stata package for exponential random graph models* (version 1.2.4) [Computer software]. [https://github.com/thomas-u-grund/nwergm](https://github.com/thomas-u-grund/nwergm)

> Grund, T. U. (2026). *nwdynam: a Stata package for dynamic network actor models* (version 1.1.4) [Computer software]. [https://github.com/thomas-u-grund/nwdynam](https://github.com/thomas-u-grund/nwdynam)

> Grund, T. U. (2026). *nwrem: a Stata package for relational event models* (version 1.0.9) [Computer software]. [https://github.com/thomas-u-grund/nwrem](https://github.com/thomas-u-grund/nwrem)

Each repository contains a `CITATION.cff` file, which GitHub shows as "Cite this repository".

The model packages follow established R packages and methods papers, which you should cite as well.
Each section lists them: [nwsaom](../nwsaom/citation/), [nwdynam](../nwdynam/citation/),
[nwrem](../nwrem/citation/) and [nwergm](../nwergm/).

## Licenses

| Package | License |
|---|---|
| nwcommands (core) | GNU General Public License, version 3 |
| nwsaom | GNU General Public License, version 3 |
| nwergm | GNU General Public License, version 3 |
| nwdynam | GNU General Public License, version 3 |
| nwrem | GNU General Public License, version 3 |

All five packages are free software. The full license text is the `LICENSE` file in each repository.
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

To install a particular release of a model package, put its tag in the URL of `net install`, for
example `net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/v1.1.0/) replace`.
See [Installation & Setup](../tutorials/01-installation-setup/).

## Acknowledgments

The model packages follow the work of others: the Siena project (Snijders and colleagues) for nwsaom,
the statnet team for nwergm, the goldfish team (Stadtfeld, Hollway, Block and colleagues) for nwdynam and
Butts and the relevent package for nwrem. They are not affiliated with these projects and do not endorse
the Stata packages; errors in the Stata packages are the author's. The derivation of each package is
described in its own section.
